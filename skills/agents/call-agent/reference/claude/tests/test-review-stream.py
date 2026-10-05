#!/usr/bin/env python3
"""Offline regression tests for the bounded Claude review runner."""

from __future__ import annotations

import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path


RUNNER = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else None
sys.argv = [sys.argv[0]]


class ClaudeReviewStreamTest(unittest.TestCase):
    def invoke(self, mode: str, *, max_diff_bytes: int = 10_000, timeout_seconds: int = 3, extra_env: dict[str, str] | None = None) -> tuple[subprocess.CompletedProcess[str], Path]:
        self.assertIsNotNone(RUNNER)
        temp_dir = Path(tempfile.mkdtemp(prefix="claude-review-test."))
        self.addCleanup(lambda: shutil.rmtree(temp_dir, ignore_errors=True))
        workspace = temp_dir / "workspace"
        workspace.mkdir()
        bin_dir = temp_dir / "bin"
        bin_dir.mkdir()
        args_file = temp_dir / "claude-args.json"
        git_log = temp_dir / "git-args.txt"

        (bin_dir / "git").write_text(
            "#!/bin/sh\nprintf '%s\\n' \"$*\" >> \"$CLAUDE_REVIEW_TEST_GIT_LOG\"\nprintf '%s\\n' 'diff --git a/example.txt b/example.txt'\nprintf '%s\\n' '+changed'\n",
            encoding="utf-8",
        )
        (bin_dir / "claude").write_text(
            textwrap.dedent(
                """\
                #!/usr/bin/env python3
                import json
                import os
                import sys
                import time

                with open(os.environ["CLAUDE_REVIEW_TEST_CLAUDE_ARGS"], "w", encoding="utf-8") as output:
                    json.dump(sys.argv[1:], output)
                if os.environ["CLAUDE_REVIEW_TEST_MODE"] == "hang":
                    time.sleep(30)
                print(json.dumps({"type": "stream_event", "event": {"type": "content_block_start", "content_block": {"type": "tool_use", "name": "Read"}}}))
                print(json.dumps({"type": "result", "subtype": "success", "result": "## Review\\nNo issue", "session_id": "test-session", "total_cost_usd": 0.01}))
                """
            ),
            encoding="utf-8",
        )
        for executable in (bin_dir / "git", bin_dir / "claude"):
            executable.chmod(executable.stat().st_mode | stat.S_IXUSR)

        environment = os.environ.copy()
        environment.update(
            {
                "PATH": f"{bin_dir}{os.pathsep}{environment['PATH']}",
                "CLAUDE_REVIEW_TEST_CLAUDE_ARGS": str(args_file),
                "CLAUDE_REVIEW_TEST_GIT_LOG": str(git_log),
                "CLAUDE_REVIEW_TEST_MODE": mode,
                "CLAUDE_REVIEW_MAX_DIFF_BYTES": str(max_diff_bytes),
                "CLAUDE_REVIEW_TIMEOUT_SECONDS": str(timeout_seconds),
                "CLAUDE_REVIEW_MAX_BUDGET_USD": "0.10",
            }
        )
        if extra_env:
            environment.update(extra_env)
        completed = subprocess.run(
            [sys.executable, str(RUNNER), str(workspace), "Review this change"],
            capture_output=True,
            text=True,
            env=environment,
            timeout=15,
        )
        return completed, temp_dir

    def test_streams_tool_progress_and_prints_final_result_once(self) -> None:
        completed, temp_dir = self.invoke("success")

        self.assertEqual(0, completed.returncode, completed.stderr)
        self.assertEqual("## Review\nNo issue\n", completed.stdout)
        self.assertIn("[claude-review] tool=Read", completed.stderr)
        self.assertIn("cost=$0.0100 session=test-session", completed.stderr)

        args = json.loads((temp_dir / "claude-args.json").read_text(encoding="utf-8"))
        self.assertIn("--safe-mode", args)
        self.assertIn("--strict-mcp-config", args)
        self.assertNotIn("--mcp-config", args)
        self.assertEqual("Read,Grep,Glob", args[args.index("--tools") + 1])
        self.assertEqual("Read Grep Glob", args[args.index("--allowedTools") + 1])
        self.assertNotIn("--max-turns", args)

        git_calls = (temp_dir / "git-args.txt").read_text(encoding="utf-8").splitlines()
        self.assertEqual(2, len(git_calls))
        self.assertTrue(all("diff" in call and "--no-ext-diff" in call and "--no-textconv" in call for call in git_calls))

    def test_times_out_without_returning_partial_success(self) -> None:
        completed, _ = self.invoke("hang", timeout_seconds=1)

        self.assertEqual(124, completed.returncode)
        self.assertEqual("", completed.stdout)
        self.assertIn("timeout after 1s", completed.stderr)

    def test_rejects_a_diff_over_the_explicit_cap_before_calling_claude(self) -> None:
        completed, temp_dir = self.invoke("success", max_diff_bytes=1)

        self.assertEqual(2, completed.returncode)
        self.assertIn("CLAUDE_REVIEW_MAX_DIFF_BYTES=1", completed.stderr)
        self.assertFalse((temp_dir / "claude-args.json").exists())

    def test_model_env_precedence_review_model_then_claude_model_then_default(self) -> None:
        for env, expected in (
            ({"CLAUDE_REVIEW_MODEL": "sonnet", "CLAUDE_MODEL": "haiku"}, "sonnet"),
            ({"CLAUDE_MODEL": "haiku"}, "haiku"),
            ({"CLAUDE_REVIEW_MODEL": "", "CLAUDE_MODEL": "fable"}, "fable"),
            ({}, "opus"),
        ):
            with self.subTest(env=env or "unset"):
                _, temp_dir = self.invoke("success", extra_env=env)
                args = json.loads((temp_dir / "claude-args.json").read_text(encoding="utf-8"))
                self.assertEqual(expected, args[args.index("--model") + 1])


if __name__ == "__main__":
    unittest.main()
