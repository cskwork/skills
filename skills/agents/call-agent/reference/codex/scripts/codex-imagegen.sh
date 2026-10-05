#!/usr/bin/env bash
# codex-imagegen.sh — generate an image via Codex's built-in image_gen tool.
# Usage: codex-imagegen.sh "<PROMPT>" "<ABS_OUTPUT_PATH.png>" [extra notes]
#
# Path A: no OPENAI_API_KEY needed, uses ChatGPT auth in ~/.codex/auth.json.
set -uo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: $0 '<PROMPT>' '<ABS_OUTPUT_PATH.png>' [extra]" >&2
  exit 2
fi

PROMPT="$1"
OUT="$2"
EXTRA="${3:-}"

if ! command -v codex >/dev/null; then
  echo "codex not installed" >&2; exit 2
fi
if [ ! -f "$HOME/.codex/auth.json" ]; then
  echo "no codex auth. Run: codex login" >&2; exit 2
fi
case "$OUT" in
  /*) ;;
   *) echo "output path must be absolute: $OUT" >&2; exit 2;;
esac

OUTDIR=$(dirname "$OUT")
mkdir -p "$OUTDIR"

INSTRUCTION="Use the image_gen tool to generate the following image:

$PROMPT
$EXTRA

Save the final PNG to $OUT. Do not return a base64 preview; just confirm the file path after saving."

codex exec \
  --sandbox workspace-write \
  --dangerously-bypass-approvals-and-sandbox \
  --skip-git-repo-check \
  -C "$OUTDIR" \
  "$INSTRUCTION"

if [ ! -s "$OUT" ]; then
  echo "codex-imagegen: no image written at $OUT" >&2
  exit 1
fi
echo "codex-imagegen: wrote $OUT"
