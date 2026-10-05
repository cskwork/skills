#!/usr/bin/env bash
# kiro-chat.sh — headless one-shot call to kiro-cli chat.
# Usage: kiro-chat.sh [--agent NAME] [--model NAME] [--trust-tools LIST] "<PROMPT>"
#        echo "<PROMPT>" | kiro-chat.sh -
set -uo pipefail

if ! command -v kiro-cli >/dev/null; then
  echo "kiro-cli not installed" >&2; exit 2
fi

AGENT=""
MODEL=""
TRUST="--trust-all-tools"
while [ "$#" -gt 1 ]; do
  case "$1" in
    --agent) AGENT="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --trust-tools) TRUST="--trust-tools=$2"; shift 2 ;;
    --) shift; break ;;
    *) break ;;
  esac
done

if [ "$#" -lt 1 ]; then
  echo "usage: $0 [--agent NAME] [--model NAME] [--trust-tools LIST] '<PROMPT>'" >&2
  exit 2
fi

if [ "$1" = "-" ]; then
  PROMPT=$(cat)
else
  PROMPT="$*"
fi

ARGS=(chat --no-interactive $TRUST)
[ -n "$AGENT" ] && ARGS+=(--agent "$AGENT")
[ -n "$MODEL" ] && ARGS+=(--model "$MODEL")

kiro-cli "${ARGS[@]}" "$PROMPT"
