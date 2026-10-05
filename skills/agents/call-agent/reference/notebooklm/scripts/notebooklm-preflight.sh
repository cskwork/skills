#!/usr/bin/env bash
# notebooklm-preflight.sh — verify notebooklm-py is installed and authed.
# Exit codes: 0 ok, 2 setup needed, 1 unexpected error.
set -uo pipefail

note() { printf '[nblm-preflight] %s\n' "$*"; }
fail() { printf '[nblm-preflight] FAIL: %s\n' "$*" >&2; }

# 1. binary
if ! command -v notebooklm >/dev/null; then
  fail "notebooklm not on PATH"
  echo "  Install: pip install 'notebooklm-py[browser]'" >&2
  exit 2
fi
note "notebooklm: $(command -v notebooklm)"

# 2. notebooklm CLI version (warn-only — both 0.3.x and 0.5.x usable)
VER=$(notebooklm --version 2>&1 | awk '{print $NF}')
note "version: ${VER:-unknown}"

# 3. storage state exists (path differs across versions)
HOME_DIR="${NOTEBOOKLM_HOME:-$HOME/.notebooklm}"
STORAGE=""
for candidate in \
  "$HOME_DIR/storage_state.json" \
  "$HOME_DIR/profiles/default/storage_state.json" \
  "$HOME_DIR/profiles/$(ls "$HOME_DIR/profiles" 2>/dev/null | head -1)/storage_state.json"; do
  [ -s "$candidate" ] && { STORAGE="$candidate"; break; }
done
if [ -z "$STORAGE" ]; then
  fail "no storage_state.json found under $HOME_DIR"
  echo "  Run: notebooklm login" >&2
  exit 2
fi
note "storage: $STORAGE"

# 4. auth check — verify BOTH status:ok AND token_fetch:true
AUTH_JSON=$(notebooklm auth check --test --json 2>/dev/null || true)
if [ -z "$AUTH_JSON" ]; then
  fail "notebooklm auth check returned nothing"
  echo "  Run: notebooklm login" >&2
  exit 2
fi

if echo "$AUTH_JSON" | python3 -c '
import sys, json
try:
    d = json.loads(sys.stdin.read())
except Exception:
    sys.exit(2)
ok = d.get("status") == "ok" and d.get("checks", {}).get("token_fetch") is True
sys.exit(0 if ok else 2)'; then
  note "auth ok"
else
  TOKEN_FETCH=$(echo "$AUTH_JSON" | python3 -c 'import sys,json; print(json.loads(sys.stdin.read()).get("checks",{}).get("token_fetch"))' 2>/dev/null)
  fail "auth not valid (token_fetch=$TOKEN_FETCH — session likely expired)"
  echo "  Run: notebooklm login" >&2
  exit 2
fi

note "preflight passed"
exit 0
