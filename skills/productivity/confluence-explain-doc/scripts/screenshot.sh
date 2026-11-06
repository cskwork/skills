#!/usr/bin/env bash
# Screenshot every code-capture HTML in <dir> to <dir>/<name>.png at the size of #cap.
# Needs agent-browser (https://github.com/vercel-labs/agent-browser) or adapt to Playwright.
set -euo pipefail
dir=${1:?usage: screenshot.sh <out-dir>}
for f in "$dir"/*.html; do
  n=$(basename "$f" .html)
  agent-browser open "file://$(cd "$(dirname "$f")" && pwd)/$n.html" >/dev/null
  agent-browser set viewport 1240 900 >/dev/null; sleep 1
  wh=$(agent-browser eval "(()=>{const r=document.getElementById('cap').getBoundingClientRect();return Math.ceil(r.width+32)+'x'+Math.ceil(r.height+32)})()" | tail -1 | tr -dc '0-9x')
  agent-browser set viewport "${wh%x*}" "${wh#*x}" >/dev/null; sleep 1
  agent-browser screenshot "$dir/$n.png" >/dev/null && echo "$dir/$n.png ${wh}"
done
agent-browser close >/dev/null 2>&1 || true
