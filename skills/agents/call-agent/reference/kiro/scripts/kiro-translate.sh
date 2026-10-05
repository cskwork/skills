#!/usr/bin/env bash
# kiro-translate.sh — natural-language → shell command via kiro-cli.
# Usage: kiro-translate.sh "<natural-language task>"
set -uo pipefail

if ! command -v kiro-cli >/dev/null; then
  echo "kiro-cli not installed" >&2; exit 2
fi
if [ "$#" -lt 1 ]; then
  echo "usage: $0 '<natural-language task>'" >&2; exit 2
fi

kiro-cli translate "$*"
