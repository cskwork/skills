#!/usr/bin/env python3
"""Offline async job regressions; never calls a real model."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest


ASYNC = Path(__file__).resolve().parents[1] / "scripts/codex-async.sh"
REVIEW = ASYNC.with_name("codex-review.sh")


class CodexAsyncTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp(prefix="codex-async-test."))
        self.addCleanup(shutil.rmtree, self.root)
        self.env = os.environ.copy()
        self.env.pop("CODEX_ASYNC_STALL", None)
        self.env.pop("BASH_ENV", None)
        self.env.update(HOME=str(self.root), CODEX_ASYNC_HOME=str(self.root / "jobs"))
        (self.root / ".codex").mkdir()
        (self.root / ".codex/auth.json").write_text("{}")
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        fake = bin_dir / "codex"
        fake.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, sys, time\n"
            "from pathlib import Path\n"
            "if os.environ.get('ASYNC_TEST_MODE') == 'done':\n"
            "    if '-o' in sys.argv:\n"
            "        Path(sys.argv[sys.argv.index('-o') + 1]).write_text('OK')\n"
            "    else:\n"
            "        print('OK', flush=True)\n"
            "    sys.exit(0)\n"
            "time.sleep(60)\n"
        )
        fake.chmod(0o755)
        self.env["PATH"] = str(bin_dir) + os.pathsep + self.env["PATH"]
        self.process = subprocess.Popen(["sleep", "60"])
        self.addCleanup(self.reap)
        self.job = self.root / "job"
        self.job.mkdir()
        (self.job / "pid").write_text(str(self.process.pid))
        self.old = int(time.time()) - 1200
        (self.job / "started").write_text(str(self.old))
        (self.job / "stall").write_text("600")
        for name in ("events.jsonl", "err.log", "last.txt"):
            path = self.job / name
            path.write_text("")
            os.utime(path, (self.old, self.old))
        os.utime(self.job / "pid", (self.old, self.old))

    def reap(self):
        self.process.terminate()
        self.process.wait(timeout=5)

    def invoke(self, *args, env=None, timeout=15):
        return subprocess.run(
            ["bash", str(ASYNC), *map(str, args)], env=env or self.env,
            text=True, capture_output=True, timeout=timeout,
        )

    def status(self):
        completed = self.invoke("status", self.job)
        self.assertEqual(0, completed.returncode, completed.stderr)
        return completed.stdout.strip()

    def start(self, sub="start", *options):
        args = [sub] + (["test"] if sub == "start" else []) + list(options)
        completed = self.invoke(*args)
        self.assertEqual(0, completed.returncode, completed.stderr)
        job = Path(completed.stdout.strip())
        self.addCleanup(lambda: self.invoke("stop", job))
        return job

    def test_stalled_status_does_not_refresh_itself(self):
        self.assertRegex(self.status(), r"^stalled idle=1[2-9][0-9]{2}s$")
        self.assertRegex(self.status(), r"^stalled idle=1[2-9][0-9]{2}s$")
        self.assertTrue(self.process.poll() is None)

    def test_wait_exits_three_on_stall_before_cap(self):
        completed = self.invoke("wait", self.job, 2)
        self.assertEqual(3, completed.returncode, completed.stderr)
        self.assertRegex(completed.stdout, r"^stalled idle=\d+s\n$")

    def test_each_output_file_restores_liveness(self):
        for name in ("err.log", "events.jsonl", "last.txt"):
            with self.subTest(name=name):
                path = self.job / name
                path.write_text("progress")
                self.assertEqual("running", self.status())
                path.write_text("")
                os.utime(path, (self.old, self.old))
                (self.job / "activity.json").unlink()

    def test_size_change_with_preserved_mtime_counts_as_activity(self):
        self.status()
        path = self.job / "err.log"
        path.write_text("progress")
        os.utime(path, (self.old, self.old))
        self.assertEqual("running", self.status())
        self.assertEqual("running", self.status())

    def test_same_size_mtime_change_counts_as_activity(self):
        self.status()
        os.utime(self.job / "events.jsonl", None)
        self.assertEqual("running", self.status())

    def test_start_time_covers_no_output_yet(self):
        for name in ("err.log", "events.jsonl", "last.txt"):
            (self.job / name).unlink()
        self.assertTrue(self.status().startswith("stalled idle="))
        (self.job / "activity.json").unlink()
        (self.job / "started").write_text(str(int(time.time())))
        self.assertEqual("running", self.status())

    def test_legacy_job_uses_pid_mtime(self):
        (self.job / "started").unlink()
        (self.job / "stall").unlink()
        self.assertTrue(self.status().startswith("stalled idle="))

    def test_completion_and_timeout_take_precedence_over_stall(self):
        for rc, expected in ((0, "done rc=0"), (1, "done rc=1"), (124, "timeout")):
            with self.subTest(rc=rc):
                (self.job / "rc").write_text(str(rc))
                self.assertEqual(expected, self.status())
                result = self.invoke("wait", self.job, 30)
                self.assertEqual(0, result.returncode)
                self.assertEqual(expected, result.stdout.strip())

    def test_missing_and_dead_jobs_do_not_wait_forever(self):
        self.assertEqual("missing", self.invoke("status", self.root / "absent").stdout.strip())
        (self.job / "pid").unlink()
        result = self.invoke("wait", self.job, 30)
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("done rc=?", result.stdout.strip())
        self.process.terminate()
        self.process.wait(timeout=5)
        (self.job / "pid").write_text(str(self.process.pid))
        self.assertEqual("done rc=?", self.status())

    def test_start_and_review_record_start_and_stall_limit(self):
        for sub in ("start", "start-review"):
            with self.subTest(sub=sub):
                before = int(time.time())
                job = self.start(sub)
                self.assertGreaterEqual(int((job / "started").read_text()), before)
                self.assertEqual("600", (job / "stall").read_text().strip())
                self.assertEqual("running", self.invoke("status", job).stdout.strip())

    def test_cli_stall_limit_and_environment_override(self):
        for sub in ("start", "start-review"):
            with self.subTest(sub=sub):
                job = self.start(sub, "--stall", "20")
                self.assertEqual("20", (job / "stall").read_text().strip())
                self.env["CODEX_ASYNC_STALL"] = "40"
                job = self.start(sub, "--stall", "20")
                self.assertEqual("40", (job / "stall").read_text().strip())
                self.env.pop("CODEX_ASYNC_STALL")

    def test_invalid_stall_values_fail_explicitly(self):
        for value in ("0", "-1", "1.5", "nope", ""):
            with self.subTest(value=value):
                result = self.invoke("start", "test", "--stall", value)
                self.assertEqual(2, result.returncode)
                self.assertIn("stall", result.stderr)

    def test_corrupt_activity_state_fails_explicitly(self):
        (self.job / "activity.json").write_text("broken")
        result = self.invoke("status", self.job)
        self.assertEqual(2, result.returncode)
        self.assertIn("activity", result.stderr)

    def test_wait_detects_a_job_that_stalls_while_waiting(self):
        (self.job / "started").write_text(str(int(time.time())))
        (self.job / "stall").write_text("1")
        result = self.invoke("wait", self.job, 30)
        self.assertEqual(3, result.returncode, result.stderr)
        self.assertTrue(result.stdout.startswith("stalled idle="))

    def test_wait_cap_does_not_kill_active_job(self):
        (self.job / "started").write_text(str(int(time.time())))
        result = self.invoke("wait", self.job, 1)
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("running", result.stdout.strip())
        self.assertIn("still running", result.stderr)
        self.assertIsNone(self.process.poll())

    def test_successful_fake_codex_result_is_unchanged(self):
        self.env["ASYNC_TEST_MODE"] = "done"
        job = self.start()
        result = self.invoke("wait", job, 10)
        self.assertEqual(0, result.returncode)
        self.assertEqual("done rc=0", result.stdout.strip())
        self.assertEqual("OK", self.invoke("result", job).stdout)

    def test_review_wrapper_propagates_stalled_exit_code(self):
        self.env["CODEX_ASYNC_STALL"] = "1"
        result = subprocess.run(
            ["bash", str(REVIEW), "--wait", "30"], env=self.env,
            text=True, capture_output=True, timeout=15,
        )
        for job in (self.root / "jobs").glob("job-*"):
            self.addCleanup(lambda job=job: self.invoke("stop", job))
        self.assertEqual(3, result.returncode, result.stderr)
        self.assertIn("stalled idle=", result.stderr)


if __name__ == "__main__":
    unittest.main()
