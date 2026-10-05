#!/usr/bin/env bash
# claude-review.sh — delegate a bounded, read-only code review to Claude Code.
# Usage: claude-review.sh "<REVIEW INSTRUCTIONS>"
# Returns: review markdown on stdout, progress/cost/session on stderr.
set -uo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 '<REVIEW INSTRUCTIONS>'" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/preflight-auth.sh" >/dev/null || exit 2

PROMPT="$*"
exec python3 "$SCRIPT_DIR/claude-review-stream.py" "$PWD" "$PROMPT"
