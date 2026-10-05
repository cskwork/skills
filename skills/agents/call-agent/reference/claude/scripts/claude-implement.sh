#!/usr/bin/env bash
# claude-implement.sh — delegate workspace implementation to Claude Code.
# Usage: claude-implement.sh "<TASK DESCRIPTION>"
# Returns: Claude's report on stdout, cost on stderr.
set -uo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 '<TASK DESCRIPTION>'" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/preflight-auth.sh" >/dev/null || exit 2
"$SCRIPT_DIR/preflight-shell.sh" >/dev/null || exit $?
source "$SCRIPT_DIR/claude-mcp-tools.sh"
load_claude_allowed_tools Read Grep Glob Edit Write Bash

PROMPT="$*"
SYS="Implement the requested task in the current workspace. Inspect before editing, keep changes scoped, and run relevant verification. Do not commit, push, or deploy unless explicitly requested. Report changed files and verification evidence."

OUT_JSON=$(claude -p --print \
  --model "${CLAUDE_MODEL:-opus}" \
  --effort high \
  --permission-mode acceptEdits \
  "${CLAUDE_ALLOWED_TOOLS_ARGS[@]+"${CLAUDE_ALLOWED_TOOLS_ARGS[@]}"}" \
  --output-format json \
  --no-session-persistence \
  --add-dir "$PWD" \
  --append-system-prompt "$SYS" \
  "$PROMPT")

printf '%s' "$OUT_JSON" | python3 -c '
import json, sys
data = json.load(sys.stdin)
if isinstance(data, list):
    data = next((item for item in data if isinstance(item, dict) and item.get("type") == "result"), {})
print(data.get("result", ""))
cost = data.get("total_cost_usd")
session_id = data.get("session_id", "")
if cost is not None:
    print(f"[claude-implement] cost=${cost:.4f} session={session_id}", file=sys.stderr)
'
