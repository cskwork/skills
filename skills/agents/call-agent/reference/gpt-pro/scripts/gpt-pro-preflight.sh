#!/usr/bin/env bash
# gpt-pro-preflight.sh - verify the gpt-pro context-bundle path is ready.
# This target has NO dedicated CLI; it packages a bundle for ChatGPT Pro (web).
# Exit codes: 0 ok, 2 setup needed.
set -uo pipefail
note() { printf '[gpt-pro-preflight] %s\n' "$*"; }
fail() { printf '[gpt-pro-preflight] FAIL: %s\n' "$*" >&2; }

# Required for the bundle path.
if ! command -v tar >/dev/null; then
  fail "tar not on PATH"
  echo "  Install tar (coreutils)." >&2
  exit 2
fi
note "archive: tar ok"

if command -v pbcopy >/dev/null; then
  note "clipboard: pbcopy"
else
  note "clipboard: pbcopy not found - bundle still works; copy PROMPT.md by hand or use --no-clip"
fi

# Cannot be verified programmatically - just remind.
note "reminder: the manual handoff needs a ChatGPT Pro subscription at chatgpt.com"

# Optional live-drive deps - never fail the preflight on these.
if command -v node >/dev/null && command -v npx >/dev/null; then
  if V=$(npx --no-install playwright-cli --version 2>/dev/null); then
    note "live-drive: playwright-cli $V available (experimental)"
  else
    note "live-drive: playwright-cli not installed (npm i -g @playwright/cli) - optional"
  fi
else
  note "live-drive: node/npx not found - optional, bundle path unaffected"
fi

note "preflight passed (bundle path ready)"
exit 0
