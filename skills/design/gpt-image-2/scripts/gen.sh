#!/usr/bin/env bash
# Generate an image via Codex CLI's imagegen tool, reusing the user's
# ChatGPT subscription session. Supports text-to-image and image-to-image.
#
# Implementation note: the generated image is embedded as base64 inside the
# session rollout jsonl under ~/.codex/sessions/YYYY/MM/DD/. `codex exec --json`
# prints this run's thread id; only rollout-*<thread_id>.jsonl is read, so
# concurrent invocations (and other Codex sessions) never mix. `--ephemeral`
# is intentionally NOT passed so the session is persisted and can be read back.
#
# Usage:
#   gen.sh --prompt "<text>" --out <path.png> [--ref <image>]... [--timeout-sec N]
#
# Exit codes:
#   0 success (path printed on stdout)
#   2 bad args
#   3 required CLI missing (codex / python3)
#   4 reference image not found
#   5 codex exec failed
#   6 no session rollout found for this run
#   7 image payload not found in session file (imagegen likely did not run)
#   8 refused by the image tool's content policy (prompt not softened)
#   9 ChatGPT/Codex usage limit, quota or rate limit hit

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PROMPT=""
OUT=""
REF_IMAGES=()
TIMEOUT_SEC=300

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt)      PROMPT="$2"; shift 2 ;;
    --out)         OUT="$2"; shift 2 ;;
    --ref)         REF_IMAGES+=("$2"); shift 2 ;;
    --timeout-sec) TIMEOUT_SEC="$2"; shift 2 ;;
    -h|--help)     sed -n '2,23p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -z "$PROMPT" ]] && { echo "Missing --prompt" >&2; exit 2; }
[[ -z "$OUT" ]]    && { echo "Missing --out" >&2; exit 2; }

command -v codex >/dev/null 2>&1 || {
  echo "codex CLI not found. Install Codex CLI and run 'codex login' first." >&2
  exit 3
}
command -v python3 >/dev/null 2>&1 || { echo "python3 not found" >&2; exit 3; }

stdout_log="$(mktemp)"; stderr_log="$(mktemp)"; request_file="$(mktemp)"
trap 'rm -f "$stdout_log" "$stderr_log" "$request_file"' EXIT
printf '%s' "$PROMPT" > "$request_file"

# Intentionally NOT using --ephemeral: we need the session rollout on disk.
# --json makes stdout a JSONL event stream that carries the thread id.
args=(exec --skip-git-repo-check --sandbox read-only --color never --json)

# Enable image_generation only while this Codex still gates it. It is on by
# default since it went stable, and codex refuses an --enable for a flag it no
# longer knows, so passing it unconditionally would break on a future CLI.
ig_state="$(codex features list 2>/dev/null | awk '$1=="image_generation"{print $NF}')"
if [[ "$ig_state" == "false" ]]; then
  args+=(--enable image_generation)
fi
if [[ ${#REF_IMAGES[@]} -gt 0 ]]; then
  for img in "${REF_IMAGES[@]}"; do
    [[ -f "$img" ]] || { echo "Reference image not found: $img" >&2; exit 4; }
    args+=(-i "$img")
  done
fi

instruction="Use the imagegen tool to generate the image for the following request."
if [[ ${#REF_IMAGES[@]} -gt 0 ]]; then
  instruction+=" Use the attached image(s) as visual reference / input for image-to-image."
fi
instruction+=$'\nRequirements: generate the image directly, return only the image, no explanation.'
# Without this, Codex silently retries a refused prompt with its own softened
# rewrite and the caller gets a different image than requested.
instruction+=$'\nPass the request to the image tool as written. If the image tool refuses, do NOT soften or rewrite the prompt and do NOT retry; just stop.'
instruction+=$'\n\nRequest:\n'"$PROMPT"

# `-i` is a variadic flag (<FILE>...), so passing the prompt as the trailing
# positional would be consumed as another image file. Feed the prompt via
# stdin instead (codex exec reads from stdin when no prompt positional is
# given).

TO=""
if   command -v timeout  >/dev/null 2>&1; then TO="timeout"
elif command -v gtimeout >/dev/null 2>&1; then TO="gtimeout"
fi

set +e
if [[ -n "$TO" ]]; then
  printf '%s' "$instruction" | "$TO" "$TIMEOUT_SEC" codex "${args[@]}" >"$stdout_log" 2>"$stderr_log"
else
  printf '%s' "$instruction" | codex "${args[@]}" >"$stdout_log" 2>"$stderr_log"
fi
rc=$?
set -e

# Quota/rate limits show up on stderr or as error / turn.failed events.
quota_hit() {
  { cat "$stderr_log"; grep -E '"type":"(error|turn\.failed)"' "$stdout_log"; } 2>/dev/null \
    | grep -qiE 'usage limit|rate limit|quota|429|too many requests|try again at'
}

if [[ $rc -ne 0 ]]; then
  if quota_hit; then
    echo "ChatGPT/Codex usage limit or rate limit reached. stderr tail:" >&2
    tail -n 20 "$stderr_log" >&2 || true
    exit 9
  fi
  echo "codex exec failed (exit=$rc). stderr tail:" >&2
  tail -n 40 "$stderr_log" >&2 || true
  exit 5
fi

thread_id="$(python3 -c '
import json, sys
for line in open(sys.argv[1], errors="replace"):
    try:
        ev = json.loads(line)
    except ValueError:
        continue
    if isinstance(ev, dict) and ev.get("type") == "thread.started":
        print(ev.get("thread_id", "")); break
' "$stdout_log")"
if [[ -z "$thread_id" ]]; then
  echo "No thread id in codex --json output; cannot locate this run's session" >&2
  tail -n 40 "$stderr_log" >&2 || true
  exit 6
fi

# Extraction logic lives in scripts/extract_image.py.
set +e
python3 "$SCRIPT_DIR/extract_image.py" "$OUT" "$thread_id" "$request_file"
py_rc=$?
set -e

case $py_rc in
  0) ;;
  2) exit 2 ;;
  3) echo "Refused by the image tool's content policy; prompt was not softened." >&2; exit 8 ;;
  4) echo "No session rollout for thread $thread_id under ~/.codex/sessions" >&2; exit 6 ;;
  *)
    if quota_hit; then
      echo "ChatGPT/Codex usage limit or rate limit reached." >&2
      exit 9
    fi
    echo "Image payload not found in this run's session file" >&2
    echo "(imagegen likely did not run; stderr tail:)" >&2
    tail -n 30 "$stderr_log" >&2 || true
    exit 7 ;;
esac
