#!/usr/bin/env bash
# notebooklm-call smoke test
set -u

SKILL=notebooklm-call
FAIL=0
note() { printf '[%s] %s\n' "$SKILL" "$*"; }
fail() { printf '[%s] FAIL: %s\n' "$SKILL" "$*" >&2; FAIL=1; }

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# L0 — binary present (warn-only, since it's pip-installed)
if command -v notebooklm >/dev/null 2>&1; then
  V=$(notebooklm --version 2>&1 | head -1)
  note "L0 ok: notebooklm $V"
  HAVE_NB=1
else
  note "L0 warn: notebooklm not installed — pip install 'notebooklm-py[browser]'"
  HAVE_NB=0
fi

# L1 — preflight script syntax + help
if bash -n "$SCRIPT_DIR/scripts/notebooklm-preflight.sh"; then
  note "L1a ok: preflight syntax"
else
  fail "L1a: preflight syntax error"
fi
if [ "$HAVE_NB" = "1" ]; then
  if notebooklm --help >/dev/null 2>&1; then
    note "L1b ok: notebooklm --help"
  else
    fail "L1b: notebooklm --help failed"
  fi
fi

# L2 — auth check (uses local cookies; no Google quota)
if [ "${RUN_L2:-0}" = "1" ] && [ "$HAVE_NB" = "1" ]; then
  if "$SCRIPT_DIR/scripts/notebooklm-preflight.sh" >/dev/null 2>&1; then
    note "L2 ok: preflight passed"
  else
    note "L2 warn: preflight failed (likely no auth — run 'notebooklm login')"
  fi
fi

# L3 — create + list + delete round-trip (no AI quota cost; verifies real API)
if [ "${RUN_L3:-0}" = "1" ] && [ "$HAVE_NB" = "1" ]; then
  NB_TITLE="call-agent-smoke-$$"
  CREATE_OUT=$(notebooklm create "$NB_TITLE" --json 2>/dev/null)
  # CLI versions differ: 0.3.x wraps in {"notebook": {"id": ...}}, newer may not
  NB_ID=$(echo "$CREATE_OUT" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
nb = d.get("notebook", d) if isinstance(d, dict) else {}
print(nb.get("id", "") if isinstance(nb, dict) else "")
' 2>/dev/null)

  if [ -z "$NB_ID" ]; then
    fail "L3: could not create notebook (got: $(echo "$CREATE_OUT" | head -c 200))"
  else
    if notebooklm list 2>/dev/null | grep -q "$(echo "$NB_ID" | head -c 8)"; then
      note "L3a ok: notebook $(echo "$NB_ID" | head -c 8)… created and listed"
    else
      fail "L3a: created notebook not in list"
    fi
    if notebooklm delete -n "$NB_ID" -y >/dev/null 2>&1; then
      note "L3b ok: deleted"
    else
      fail "L3b: delete failed (orphan notebook ID: $NB_ID)"
    fi
  fi
fi

# Real failure wins; otherwise report SKIP (exit 3) when the CLI is absent.
if [ "$FAIL" != "0" ]; then
  exit "$FAIL"
elif [ "$HAVE_NB" != "1" ]; then
  note "L0 skip: notebooklm not installed — pip install 'notebooklm-py[browser]'"
  exit 3
fi
exit 0
