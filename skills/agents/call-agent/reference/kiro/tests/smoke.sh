#!/usr/bin/env bash
# kiro-call smoke test — targets kiro-cli (the AWS agentic terminal).
set -u

SKILL=kiro-call
FAIL=0
note() { printf '[%s] %s\n' "$SKILL" "$*"; }
fail() { printf '[%s] FAIL: %s\n' "$SKILL" "$*" >&2; FAIL=1; }

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# L0 — binary present and is the CLI (not the IDE launcher)
if command -v kiro-cli >/dev/null 2>&1; then
  V=$(kiro-cli --version 2>&1 | head -1)
  case "$V" in
    *Kiro*0.12*)
      fail "L0: 'kiro-cli' on PATH points to the IDE, not the CLI"
      exit "$FAIL"
      ;;
  esac
  note "L0 ok: kiro-cli $V"
else
  note "L0 skip: kiro-cli not on PATH (install Kiro CLI from https://kiro.dev)"
  exit 3
fi

# L1 — helps work, scripts syntax-valid
for help in '--help' '--help-all' 'chat --help' 'translate --help' 'mcp --help'; do
  if kiro-cli $help >/dev/null 2>&1; then
    note "L1a ok: kiro-cli $help"
  else
    fail "L1a: kiro-cli $help failed"
  fi
done
for s in scripts/kiro-preflight.sh scripts/kiro-chat.sh scripts/kiro-translate.sh; do
  if bash -n "$SCRIPT_DIR/$s"; then
    note "L1b ok: $s syntax"
  else
    fail "L1b: $s syntax error"
  fi
done

# L1c — preflight (may exit 2 if not logged in)
if "$SCRIPT_DIR/scripts/kiro-preflight.sh" >/dev/null 2>&1; then
  note "L1c ok: preflight passed (auth present)"
  HAVE_AUTH=1
else
  note "L1c warn: preflight reports no auth — run \`kiro-cli login\`"
  HAVE_AUTH=0
fi

# L2 — headless round-trip
if [ "${RUN_L2:-0}" = "1" ] && [ "$HAVE_AUTH" = "1" ]; then
  OUT=$("$SCRIPT_DIR/scripts/kiro-chat.sh" "Reply with exactly: OK" 2>&1 | tr -d '[:space:]')
  if echo "$OUT" | grep -qi 'ok'; then
    note "L2 ok: round-trip"
  else
    fail "L2: unexpected response: $(echo "$OUT" | head -c 200)"
  fi
fi

# L3 — translate
if [ "${RUN_L3:-0}" = "1" ] && [ "$HAVE_AUTH" = "1" ]; then
  T=$("$SCRIPT_DIR/scripts/kiro-translate.sh" "list files in current directory" 2>&1 | head -20)
  if echo "$T" | grep -qE '\bls\b|ls -'; then
    note "L3 ok: translate produced an ls command"
  else
    fail "L3: translate output did not include 'ls': $T"
  fi
fi

exit "$FAIL"
