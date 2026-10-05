#!/usr/bin/env python3
"""Run a bounded Claude Code review and render its stream-json result."""

from __future__ import annotations

import json
import os
import select
import signal
import subprocess
import sys
import time
from pathlib import Path
from typing import Any


SYSTEM_PROMPT = """You are a strict, bounded code reviewer. The trusted wrapper has supplied the current git diff. Find correctness, security, and design bugs in that diff or the files it names. Cite file:line and group findings by Critical, Major, and Minor. You may inspect files with Read, Grep, and Glob only. Do not invoke agents, skills, plugins, MCP tools, shells, write-capable tools, external systems, or Git. Review only; do not modify files, commit, push, or deploy. Return a final review after inspection rather than continuing to explore."""
READ_ONLY_TOOLS = "Read Grep Glob"


class ReviewInputError(RuntimeError):
    """The wrapper could not prepare a safe review input."""


def env_int(name: str, default: int, minimum: int) -> int:
    try:
        return max(minimum, int(os.environ.get(name, default)))
    except ValueError:
        return default


def env_float(name: str, default: float, minimum: float) -> float:
    try:
        return max(minimum, float(os.environ.get(name, default)))
    except ValueError:
        return default


def git_diff(workspace: Path, cached: bool) -> bytes:
    command = ["git", "diff"]
    if cached:
        command.append("--cached")
    command.extend(["--no-ext-diff", "--no-textconv", "--no-color"])
    completed = subprocess.run(
        command,
        cwd=workspace,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        detail = completed.stderr.decode("utf-8", errors="replace").strip()
        raise ReviewInputError(detail or "git diff failed")
    return completed.stdout


def capture_diff(workspace: Path, max_bytes: int) -> str:
    sections: list[bytes] = []
    for label, cached in (("staged", True), ("unstaged", False)):
        diff = git_diff(workspace, cached)
        if diff:
            sections.append(f"--- {label} diff ---\n".encode() + diff)

    payload = b"\n\n".join(sections) or b"(No staged or unstaged tracked changes.)\n"
    if len(payload) > max_bytes:
        raise ReviewInputError(
            f"git diff is {len(payload)} bytes, over CLAUDE_REVIEW_MAX_DIFF_BYTES={max_bytes}; narrow the review or raise the explicit cap"
        )
    return payload.decode("utf-8", errors="replace")


def print_progress(event: dict[str, Any]) -> None:
    if event.get("type") != "stream_event":
        return

    stream_event = event.get("event", {})
    if stream_event.get("type") != "content_block_start":
        return

    block = stream_event.get("content_block", {})
    if block.get("type") == "tool_use":
        print(f"[claude-review] tool={block.get('name', 'unknown')}", file=sys.stderr, flush=True)


def parse_event(line: str) -> dict[str, Any] | None:
    try:
        value = json.loads(line)
    except json.JSONDecodeError:
        return None
    return value if isinstance(value, dict) else None


def terminate(process: subprocess.Popen[bytes]) -> None:
    if process.poll() is not None:
        return

    try:
        os.killpg(process.pid, signal.SIGINT)
    except (ProcessLookupError, PermissionError):
        process.send_signal(signal.SIGINT)

    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except (ProcessLookupError, PermissionError):
            process.kill()
        process.wait()


def append_events(buffer: str, final_event: dict[str, Any] | None) -> tuple[str, dict[str, Any] | None]:
    while "\n" in buffer:
        line, buffer = buffer.split("\n", 1)
        event = parse_event(line.strip())
        if event is None:
            continue
        print_progress(event)
        if event.get("type") == "result":
            final_event = event
    return buffer, final_event


def run_review(workspace: Path, instructions: str, diff: str) -> int:
    timeout_seconds = env_int("CLAUDE_REVIEW_TIMEOUT_SECONDS", 180, 1)
    max_budget = env_float("CLAUDE_REVIEW_MAX_BUDGET_USD", 1.0, 0.01)
    prompt = f"""Review instructions:\n{instructions}\n\nTrusted git diff:\n{diff}"""
    command = [
        "claude",
        "-p",
        "--print",
        "--verbose",
        "--safe-mode",
        "--model",
        os.environ.get("CLAUDE_REVIEW_MODEL") or os.environ.get("CLAUDE_MODEL") or "opus",
        "--effort",
        os.environ.get("CLAUDE_REVIEW_EFFORT", "high"),
        "--permission-mode",
        "dontAsk",
        "--strict-mcp-config",
        "--tools",
        "Read,Grep,Glob",
        "--allowedTools",
        READ_ONLY_TOOLS,
        "--max-budget-usd",
        f"{max_budget:.2f}",
        "--output-format",
        "stream-json",
        "--include-partial-messages",
        "--no-session-persistence",
        "--add-dir",
        str(workspace),
        "--append-system-prompt",
        SYSTEM_PROMPT,
        prompt,
    ]
    environment = {key: value for key, value in os.environ.items() if key != "CLAUDECODE"}
    process = subprocess.Popen(
        command,
        cwd=workspace,
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        start_new_session=True,
    )
    assert process.stdout is not None

    buffer = ""
    final_event: dict[str, Any] | None = None
    deadline = time.monotonic() + timeout_seconds
    timed_out = False

    try:
        while True:
            if time.monotonic() >= deadline and process.poll() is None:
                timed_out = True
                print(f"[claude-review] timeout after {timeout_seconds}s", file=sys.stderr, flush=True)
                terminate(process)

            ready, _, _ = select.select([process.stdout], [], [], 0.25)
            if ready:
                chunk = os.read(process.stdout.fileno(), 8192)
                if chunk:
                    buffer += chunk.decode("utf-8", errors="replace")
                    buffer, final_event = append_events(buffer, final_event)

            if process.poll() is not None:
                remainder = process.stdout.read().decode("utf-8", errors="replace")
                buffer, final_event = append_events(buffer + remainder + "\n", final_event)
                break
    finally:
        terminate(process)

    if timed_out:
        return 124
    if process.returncode != 0:
        print(f"[claude-review] Claude exited with status {process.returncode}", file=sys.stderr)
        return 1
    if final_event is None:
        print("[claude-review] no terminal result returned", file=sys.stderr)
        return 1
    if final_event.get("is_error") or final_event.get("subtype") not in (None, "success"):
        errors = final_event.get("errors") or []
        detail = "; ".join(str(error) for error in errors) or str(final_event.get("stop_reason", "unknown failure"))
        print(f"[claude-review] failed: {detail}", file=sys.stderr)
        return 1

    result = final_event.get("result", "")
    if not isinstance(result, str) or not result.strip():
        print("[claude-review] completed without review text", file=sys.stderr)
        return 1

    cost = final_event.get("total_cost_usd")
    session_id = final_event.get("session_id", "")
    if cost is not None:
        try:
            cost_text = f"{float(cost):.4f}"
        except (TypeError, ValueError):
            cost_text = str(cost)
        print(f"[claude-review] cost=${cost_text} session={session_id}", file=sys.stderr)
    print(result)
    return 0


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: claude-review-stream.py <workspace> <review-instructions>", file=sys.stderr)
        return 2

    workspace = Path(sys.argv[1]).resolve()
    max_diff_bytes = env_int("CLAUDE_REVIEW_MAX_DIFF_BYTES", 200_000, 1)
    try:
        diff = capture_diff(workspace, max_diff_bytes)
    except ReviewInputError as error:
        print(f"[claude-review] cannot prepare review: {error}", file=sys.stderr)
        return 2
    return run_review(workspace, sys.argv[2], diff)


if __name__ == "__main__":
    raise SystemExit(main())
