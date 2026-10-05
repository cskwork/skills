#!/usr/bin/env bash
# Shared MCP permission discovery for the Claude wrapper scripts.

CLAUDE_ALLOWED_TOOLS_ARGS=()

normalize_claude_mcp_server_name() {
  python3 -c '
import sys
allowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"
name = sys.stdin.buffer.read().decode("utf-8")
sys.stdout.write("".join(char if char in allowed else "_" for char in name))
'
}

load_claude_allowed_tools() {
  local output line server normalized
  local tools=("$@")

  CLAUDE_ALLOWED_TOOLS_ARGS=()
  if output=$(claude mcp list 2>/dev/null); then
    while IFS= read -r line; do
      case "$line" in
        *": "*" - "*)
          server=${line%%: *}
          normalized=$(printf '%s' "$server" | normalize_claude_mcp_server_name 2>/dev/null)
          [ -n "$normalized" ] && tools+=("mcp__$normalized")
          ;;
      esac
    done <<<"$output"
  fi

  if [ "${#tools[@]}" -gt 0 ]; then
    CLAUDE_ALLOWED_TOOLS_ARGS=(--allowedTools "${tools[*]}")
  fi
}
