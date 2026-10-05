#!/usr/bin/env bash
# kiro-add-mcp.sh — register an MCP server into Kiro's user profile.
# Usage: kiro-add-mcp.sh '<JSON>'
#        echo '<JSON>' | kiro-add-mcp.sh -
#
# JSON shape: {"name":"...", "command":"...", "args":[...], "env":{...}}
set -uo pipefail

if ! command -v kiro >/dev/null; then
  echo "kiro not installed (https://kiro.dev)" >&2; exit 2
fi

if [ "$#" -lt 1 ]; then
  echo "usage: $0 '<JSON>'  |  echo '<JSON>' | $0 -" >&2; exit 2
fi

if [ "$1" = "-" ]; then
  JSON=$(cat)
else
  JSON="$1"
fi

# validate JSON shape: require name + command
if ! echo "$JSON" | python3 -c '
import sys, json
try:
    d = json.loads(sys.stdin.read())
except Exception as e:
    print(f"invalid JSON: {e}", file=sys.stderr); sys.exit(2)
if not isinstance(d, dict):
    print("MCP spec must be a JSON object", file=sys.stderr); sys.exit(2)
miss = [k for k in ("name","command") if not d.get(k)]
if miss:
    print(f"missing required keys: {miss}", file=sys.stderr); sys.exit(2)
'; then
  exit 2
fi

kiro --add-mcp "$JSON"
echo "kiro-add-mcp: registered" >&2
