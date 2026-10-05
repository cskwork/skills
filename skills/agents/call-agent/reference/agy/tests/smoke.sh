#!/usr/bin/env bash
# agy-call smoke test
# L0+L1 always; L2 needs RUN_L2=1; L3 needs RUN_L3=1
set -u

SKILL=agy-call
FAIL=0
note() { printf '[%s] %s\n' "$SKILL" "$*"; }
fail() { printf '[%s] FAIL: %s\n' "$SKILL" "$*" >&2; FAIL=1; }

# L0 — binary present
if command -v agy >/dev/null 2>&1; then
  V=$(agy --version 2>&1 | head -1)
  note "L0 ok: agy $V"
else
  note "L0 skip: agy not on PATH (install from https://antigravity.google/cli)"
  exit 3
fi

# L1 — help works
if agy --help >/dev/null 2>&1; then
  note "L1 ok: agy --help"
else
  fail "L1: agy --help failed"
fi

# L2 — round-trip
if [ "${RUN_L2:-0}" = "1" ]; then
  OUT=$(agy -p "Reply with exactly: OK" --print-timeout 1m0s 2>&1 | tr -d '[:space:]')
  if echo "$OUT" | grep -qi 'ok'; then
    note "L2 ok: round-trip"
  else
    fail "L2: unexpected response: $OUT"
  fi
fi

# L3 — image gen
if [ "${RUN_L3:-0}" = "1" ]; then
  IMG=$(mktemp -u -t agy-smoke-XXXXXX).png
  agy -p "Generate a 64x64 solid red square PNG. Save it to $IMG. Do not return base64." \
      --dangerously-skip-permissions --print-timeout 3m0s >/dev/null 2>&1
  if [ -s "$IMG" ]; then
    note "L3 ok: image generated at $IMG"
    rm -f "$IMG"
  else
    fail "L3: no image at $IMG"
  fi
fi

exit "$FAIL"
