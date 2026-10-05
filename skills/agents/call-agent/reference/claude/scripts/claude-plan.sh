#!/usr/bin/env bash
# claude-plan.sh — delegate a planning task to Claude Code.
# Usage: claude-plan.sh "<TASK DESCRIPTION>"
# Returns: the plan markdown on stdout, cost on stderr.
set -uo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 '<TASK DESCRIPTION>'" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/preflight-auth.sh" >/dev/null || exit 2
source "$SCRIPT_DIR/claude-mcp-tools.sh"
load_claude_allowed_tools

PROMPT="$*"
SYS="You are a planner. Produce an actionable plan with numbered steps, risks, and acceptance criteria. Do not modify any files. Output as markdown."

OUT_JSON=$(claude -p --print \
  --model "${CLAUDE_MODEL:-opus}" \
  --effort high \
  --permission-mode dontAsk \
  --tools Read,Grep,Glob \
  "${CLAUDE_ALLOWED_TOOLS_ARGS[@]+"${CLAUDE_ALLOWED_TOOLS_ARGS[@]}"}" \
  --output-format json \
  --no-session-persistence \
  --add-dir "$PWD" \
  --append-system-prompt "$SYS" \
  "$PROMPT")

echo "$OUT_JSON" | python3 -c '
import sys, json
d = json.load(sys.stdin)
if isinstance(d, list):
    d = next((x for x in d if isinstance(x, dict) and x.get("type") == "result"), {})
print(d.get("result", ""))
cost = d.get("total_cost_usd")
sid = d.get("session_id", "")
if cost is not None:
    print(f"[claude-plan] cost=${cost:.4f} session={sid}", file=sys.stderr)
'
