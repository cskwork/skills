#!/usr/bin/env bash
# kiro-preflight.sh — verify kiro-cli is installed and authenticated.
# Exit codes: 0 ok, 2 setup needed.
set -uo pipefail

note() { printf '[kiro-preflight] %s\n' "$*"; }
fail() { printf '[kiro-preflight] FAIL: %s\n' "$*" >&2; }

if ! command -v kiro-cli >/dev/null; then
  fail "kiro-cli not on PATH"
  echo "  Install Kiro CLI from https://kiro.dev (provides ~/.local/bin/kiro-cli)" >&2
  exit 2
fi
note "kiro-cli: $(command -v kiro-cli)"

# Reject the IDE binary if someone aliased `kiro-cli` to it
V=$(kiro-cli --version 2>&1 | head -1)
case "$V" in
  *Kiro*0.12*)
    fail "PATH 'kiro-cli' resolves to the IDE binary, not the CLI"
    echo "  Expected: '/Applications/Kiro CLI.app/Contents/MacOS/kiro-cli'" >&2
    exit 2
    ;;
esac
note "version: $V"

# Auth check via whoami
WHO=$(kiro-cli whoami 2>&1 || true)
if echo "$WHO" | grep -qiE 'not (logged|signed) in|unauthen|error'; then
  fail "kiro-cli not logged in"
  echo "  Run: kiro-cli login" >&2
  exit 2
fi
note "whoami: $(echo "$WHO" | head -1)"

note "preflight passed"
exit 0
