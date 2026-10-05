#!/usr/bin/env bash
# gpt-pro-live.sh - EXPERIMENTAL: drive an already-logged-in ChatGPT Pro tab via
# playwright-cli and capture the reply. Uploads the bundle as a FILE (reliable)
# and types only a short one-line instruction - keystroke entry of large prompts
# truncates and is slow. Fails loudly (exit 2, bundle fallback) when it cannot
# connect; never fakes success.
#
# Prereqs (verified caveats, Chrome 149 / playwright-cli 0.1.x):
#   - Chrome 136+ blocks --remote-debugging-port on the DEFAULT profile, so this
#     uses the Playwright EXTENSION relay: install the Playwright extension from
#     the Chrome Web Store AND enable chrome://inspect/#remote-debugging ->
#     "Allow remote debugging for this browser instance".
#   - You must already be signed into ChatGPT Pro in that browser.
#   - ChatGPT is a heavy SPA; the selectors here can drift.
#
# Usage: gpt-pro-live.sh "<ONE-LINE INSTRUCTION>" --attach <file> [options]
#   --attach <file>   optional file to upload (the bundle's PASTE_THIS.txt/.tar.gz); omit for short Q&A
#   --channel <name>  browser channel (default chrome)
#   --timeout <secs>  max wait for the reply (default 600)
#   --session <name>  playwright-cli session name (default gptpro)
set -uo pipefail
die()  { echo "gpt-pro-live: $*" >&2; echo "  Fallback: gpt-pro-bundle.sh + paste/upload by hand." >&2; exit 2; }
note() { printf '[gpt-pro-live] %s\n' "$*"; }

[ "$#" -ge 1 ] || { sed -n '2,21p' "$0"; exit 2; }
case "$1" in -h|--help) sed -n '2,21p' "$0"; exit 0;; esac
QUESTION="$1"; shift
CHANNEL="chrome"; TIMEOUT=600; SESSION="gptpro"; ATTACH_WAIT=15; ATTACH=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --attach)  ATTACH="${2:?--attach needs a file}"; shift 2;;
    --channel) CHANNEL="${2:?--channel needs a value}"; shift 2;;
    --timeout) TIMEOUT="${2:?--timeout needs seconds}"; shift 2;;
    --session) SESSION="${2:?--session needs a name}"; shift 2;;
    *) die "unknown option: $1";;
  esac
done
if [ -n "$ATTACH" ]; then                       # --attach is optional (omit it for short fileless Q&A)
  [ -f "$ATTACH" ] || die "--attach file not found: $ATTACH"
  ATTACH="$(cd "$(dirname "$ATTACH")" && pwd)/$(basename "$ATTACH")"   # upload needs an absolute path
fi
case "$QUESTION" in *[$'\n']*) die "the instruction must be ONE line (newlines submit early); put detail in --attach";; esac

# Prefer the on-PATH binary - each `npx` call pays node-startup cost, which is
# crippling inside the poll loop.
if command -v playwright-cli >/dev/null 2>&1; then PWBIN="playwright-cli"; else PWBIN="npx --no-install playwright-cli"; fi
PW() { $PWBIN -s="$SESSION" "$@"; }

command -v npx >/dev/null || die "npx not found (need Node + @playwright/cli)"
npx --no-install playwright-cli --version >/dev/null 2>&1 \
  || die "playwright-cli not installed (npm i -g @playwright/cli)"

note "attaching via Playwright extension relay (channel=$CHANNEL; up to ${ATTACH_WAIT}s)..."
# attach blocks until the extension connects - bound it so a missing extension
# fails loud fast instead of hanging.
TO=()
if   command -v timeout  >/dev/null; then TO=(timeout  "$ATTACH_WAIT")
elif command -v gtimeout >/dev/null; then TO=(gtimeout "$ATTACH_WAIT"); fi
${TO[@]+"${TO[@]}"} npx --no-install playwright-cli attach --extension="$CHANNEL" -s="$SESSION" >/dev/null 2>&1 || true
if ! npx --no-install playwright-cli list 2>/dev/null | grep -q "$SESSION"; then
  die "could not attach (no Playwright extension connected within ${ATTACH_WAIT}s). Install the Playwright extension from the Chrome Web Store, enable chrome://inspect/#remote-debugging 'Allow remote debugging', then retry."
fi

note "opening ChatGPT..."
PW tab-new "https://chatgpt.com/" >/dev/null 2>&1 || PW goto "https://chatgpt.com/" >/dev/null 2>&1 \
  || die "navigation to chatgpt.com failed"
PW snapshot >/dev/null 2>&1 || die "snapshot failed (not logged in? sign into chatgpt.com first)"

# Attach the bundle as a real file - reliable, unlike keystroke entry of a large
# prompt. The composer keeps a hidden input[type=file]; `upload` sets it.
if [ -n "$ATTACH" ]; then
  note "uploading $(basename "$ATTACH")..."
  PW upload "$ATTACH" >/dev/null 2>&1 \
    || die "file upload failed (ChatGPT may reject this type; try --attach <bundle>/PASTE_THIS.txt)"
  base=$(basename "$ATTACH"); ok=0
  for _ in $(seq 1 20); do
    sleep 2
    [ "$(PW --raw eval "(() => document.body.innerText.includes('$base') ? 1 : 0)()" 2>/dev/null || echo 0)" = "1" ] && { ok=1; break; }
  done
  [ "$ok" = "1" ] || die "attachment did not register (ChatGPT did not bind the upload) - sending without it would yield a useless answer. Attach the file by hand in the ChatGPT tab, or use the bundle handoff."
  note "attachment registered"
fi

# Type the short, single-line instruction and submit.
PW click "#prompt-textarea" >/dev/null 2>&1 || die "composer not found (DOM changed or not logged in)"
PW type "$QUESTION" >/dev/null 2>&1 || die "could not enter the instruction"
PW press Enter >/dev/null 2>&1 || die "could not submit"

# Completion detection: done only when generation has STOPPED (no stop-button)
# AND a non-empty answer is stable - avoids capturing interim "thinking" text.
note "waiting for completion (up to ${TIMEOUT}s; Pro reasoning can take minutes)..."
# One eval per poll (streaming flag + answer in a single call) and a wall-clock
# deadline - per-call node startup makes a multi-eval loop miscount time badly.
prev=""; stable=0; got=""; deadline=$((SECONDS + TIMEOUT))
while [ "$SECONDS" -lt "$deadline" ]; do
  sleep 4
  out=$(PW --raw eval '(() => { const gen = document.querySelector("button[data-testid=\"stop-button\"], button[aria-label*=\"Stop\" i]") ? 1 : 0; const m = document.querySelectorAll("[data-message-author-role=\"assistant\"]"); return gen + (m.length ? m[m.length-1].innerText : ""); })()' 2>/dev/null || true)
  [ -n "$out" ] || continue
  streaming="${out:0:1}"; ans="${out:1}"
  if [ "$streaming" = "0" ] && [ -n "$ans" ] && [ "$ans" = "$prev" ]; then
    stable=$((stable + 1)); [ "$stable" -ge 2 ] && { got="$ans"; break; }
  else
    stable=0
  fi
  prev="$ans"
done
[ -n "$got" ] || got="$prev"
[ -n "$got" ] || die "no response captured (Pro may still be generating; raise --timeout or use the bundle handoff)"

printf '%s\n' "$got"
note "captured ${#prev} chars (verify fidelity; markdown/code blocks may be lossy)"
exit 0
