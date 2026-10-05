#!/usr/bin/env bash
# smoke.sh - gpt-pro target smoke test (L0/L1; no API, no credit).
set -u
SKILL="gpt-pro"
DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$DIR/scripts"
FAIL=0
note() { printf '[%s] %s\n' "$SKILL" "$*"; }
fail() { printf '[%s] FAIL: %s\n' "$SKILL" "$*" >&2; FAIL=1; }

# L0 - host tools (bundle path needs tar; pbcopy is optional)
if command -v tar >/dev/null 2>&1; then
  note "L0 ok: tar present"
else
  note "L0 skip: tar not on PATH"
  exit 3
fi

# L1a - script syntax
for s in gpt-pro-preflight.sh gpt-pro-bundle.sh gpt-pro-live.sh; do
  if bash -n "$SCRIPTS/$s"; then note "L1a ok: $s syntax"; else fail "L1a: $s syntax"; fi
done

# L1b - preflight exits clean
if bash "$SCRIPTS/gpt-pro-preflight.sh" >/dev/null 2>&1; then
  note "L1b ok: preflight exit 0"
else
  fail "L1b: preflight nonzero"
fi

# L1c - bundle help
if bash "$SCRIPTS/gpt-pro-bundle.sh" --help >/dev/null 2>&1; then
  note "L1c ok: bundle --help"
else
  fail "L1c: bundle --help"
fi

TMP=$(mktemp -d -t gptpro-smoke-XXXXXX)

# L1d - functional bundle of a benign file
echo "hello world, nothing secret here" > "$TMP/sample.txt"
if bash "$SCRIPTS/gpt-pro-bundle.sh" "Smoke review this" \
      --files "$TMP/sample.txt" --out "$TMP/out" --no-clip >/dev/null 2>&1; then
  d=$(find "$TMP/out" -maxdepth 1 -type d -name '*-smoke-review-this' | head -1)
  if [ -n "$d" ] && [ -f "$d/PROMPT.md" ] && [ -f "$d.tar.gz" ]; then
    note "L1d ok: bundle produced PROMPT.md + tar.gz"
  else
    fail "L1d: bundle missing PROMPT.md or tar.gz"
  fi
else
  fail "L1d: bundle run failed"
fi

# L1e - sanitizer fail-fast on a planted secret
echo "api_key = sk-abcdefghijklmnop""0123456789" > "$TMP/leak.txt"
if bash "$SCRIPTS/gpt-pro-bundle.sh" "Smoke secret" \
      --files "$TMP/leak.txt" --out "$TMP/out2" --no-clip >/dev/null 2>&1; then
  fail "L1e: sanitizer did NOT block a planted secret"
else
  if [ -z "$(find "$TMP/out2" -maxdepth 1 -type d -name '*-smoke-secret' 2>/dev/null)" ]; then
    note "L1e ok: sanitizer blocked and cleaned up"
  else
    fail "L1e: bundle left on disk after secret block"
  fi
fi

rm -rf "$TMP"
exit "$FAIL"
