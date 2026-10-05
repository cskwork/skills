#!/usr/bin/env bash
# preflight-shell.sh — verify Claude can initialize Bash in this host.
# Exit codes: 0 ready, 2 setup needed, 3 host blocked.
set -uo pipefail

note() { printf '[claude-preflight] %s\n' "$*"; }
fail() { printf '[claude-preflight] FAIL: %s\n' "$*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/preflight-auth.sh" >/dev/null || exit 2

ERR_FILE="$(mktemp "${TMPDIR:-/tmp}/claude-shell-preflight.XXXXXX")"
trap 'rm -f "$ERR_FILE"' EXIT

OUT_JSON=$(claude -p --print \
  --safe-mode \
  --model "${CLAUDE_PROBE_MODEL:-haiku}" \
  --effort low \
  --permission-mode acceptEdits \
  --tools Bash \
  --allowedTools "Bash(pwd)" \
  --max-turns 4 \
  --max-budget-usd 0.05 \
  --output-format json \
  --no-session-persistence \
  --add-dir "$PWD" \
  --system-prompt "Use Bash only as requested. After it succeeds, reply exactly SHELL_OK." \
  "Run pwd with Bash." 2>"$ERR_FILE")
STATUS=$?

if [ "$STATUS" -ne 0 ]; then
  fail "Claude could not start its shell in this host."
  sed -n '1,8p' "$ERR_FILE" >&2
  echo "  Open a normal terminal, change to this workspace, and rerun the Claude task." >&2
  exit 3
fi

if ! printf '%s' "$OUT_JSON" | python3 -c '
import json, sys
data = json.load(sys.stdin)
if isinstance(data, list):
    data = next((item for item in data if isinstance(item, dict) and item.get("type") == "result"), {})
result = data.get("result", "")
denials = data.get("permission_denials") or []
if "SHELL_OK" in result and not denials:
    raise SystemExit(0)
detail = result or "; ".join(data.get("errors") or []) or data.get("subtype", "unknown failure")
print("  Claude: " + detail[:800].replace("\n", " "), file=sys.stderr)
raise SystemExit(3)
'; then
  fail "Claude responded, but Bash access was not proven."
  echo "  Open a normal terminal, change to this workspace, and rerun the Claude task." >&2
  exit 3
fi

note "shell ok"
