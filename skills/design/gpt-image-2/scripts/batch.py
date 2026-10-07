#!/usr/bin/env python3
"""Run many gen.sh calls in parallel.

Usage: batch.py <jobs.jsonl> [--workers N]

Each line: {"prompt": "...", "out": "/abs/out.png", "refs": ["/abs/ref.png"]}
("refs" optional). Existing outputs are skipped, so a stopped batch resumes.
Stops starting new jobs after a quota/rate-limit hit (gen.sh exit 9).
Exit codes: 0 all done, 1 some jobs failed, 9 stopped on quota.
"""
import argparse
import json
import pathlib
import subprocess
import sys
import threading
from concurrent.futures import ThreadPoolExecutor

GEN = pathlib.Path(__file__).resolve().parent / "gen.sh"
QUOTA_EXIT = 9
quota_hit = threading.Event()


def run(job: dict) -> int:
    if quota_hit.is_set():
        return QUOTA_EXIT
    cmd = ["bash", str(GEN), "--prompt", job["prompt"], "--out", job["out"]]
    for ref in job.get("refs", []):
        cmd += ["--ref", ref]
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode == QUOTA_EXIT:
        quota_hit.set()
    print(f"exit={p.returncode} {job['out']}", flush=True)
    if p.returncode != 0:
        print(p.stderr.strip()[-600:], file=sys.stderr, flush=True)
    return p.returncode


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("jobs")
    ap.add_argument("--workers", type=int, default=3)
    a = ap.parse_args()
    with open(a.jobs, encoding="utf-8") as f:
        jobs = [json.loads(line) for line in f if line.strip()]
    todo = [j for j in jobs if not pathlib.Path(j["out"]).exists()]
    print(f"{len(todo)} to run, {len(jobs) - len(todo)} skipped (output exists)", flush=True)
    with ThreadPoolExecutor(max_workers=a.workers) as pool:
        codes = list(pool.map(run, todo))
    if quota_hit.is_set():
        print("Stopped: ChatGPT/Codex usage limit or rate limit reached.", file=sys.stderr)
        return QUOTA_EXIT
    return 0 if all(c == 0 for c in codes) else 1


if __name__ == "__main__":
    sys.exit(main())
