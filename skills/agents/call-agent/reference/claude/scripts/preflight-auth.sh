#!/usr/bin/env bash
# preflight-auth.sh — verify claude CLI is callable.
# Exit codes: 0 ok, 2 setup needed.
set -uo pipefail

note() { printf '[claude-preflight] %s\n' "$*"; }
fail() { printf '[claude-preflight] FAIL: %s\n' "$*" >&2; }

if ! command -v claude >/dev/null; then
  fail "claude not on PATH"
  echo "  Install: https://claude.com/claude-code" >&2
  exit 2
fi
note "claude: $(command -v claude)"

# Method 1: claude auth status (JSON by default in current versions)
STATUS_JSON=$(claude auth status 2>/dev/null || true)
if [ -n "$STATUS_JSON" ] && echo "$STATUS_JSON" | python3 -c '
import sys, json
try:
    d = json.loads(sys.stdin.read())
except Exception:
    sys.exit(2)
sys.exit(0 if d.get("loggedIn") else 2)' 2>/dev/null; then
  METHOD=$(echo "$STATUS_JSON" | python3 -c 'import sys,json; print(json.loads(sys.stdin.read()).get("authMethod","?"))')
  note "auth ok ($METHOD)"
  exit 0
fi

# Method 2: API key env var
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  note "auth ok (ANTHROPIC_API_KEY)"
  exit 0
fi

fail "no claude auth detected"
echo "  Run: claude auth login   (Max/Pro)" >&2
echo "  or:  export ANTHROPIC_API_KEY=sk-ant-..." >&2
exit 2
