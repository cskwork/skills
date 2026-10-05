#!/usr/bin/env bash
# verify skill — gate 2, static checks.
#
# Runs every check the adapter lists, one at a time, and records each result
# separately. One tool failing does not stop the others: a full picture is
# worth more than a fast exit.
#
#   scripts/gate-static.sh
#
# The adapter sets VERIFY_STATIC_CMDS to newline-separated "label|command"
# lines. A tool that is not installed records as BLOCKED, never as PASS.

set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

vf_load_adapter
[ -n "${VERIFY_STATIC_CMDS:-}" ] || vf_die "VERIFY_STATIC_CMDS is not set in the adapter"
[ -n "$VERIFY_RUN_DIR" ] || vf_init_run_dir "static" >/dev/null

LOG="$VERIFY_RUN_DIR/receipts/02-static.log"

{
  echo "=== STATIC CHECKS ==="
  echo "cwd: $VERIFY_TARGET_DIR"
  echo "at:  $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
} > "$LOG"

ran=0
failed=0
blocked=0

while IFS= read -r line; do
  [ -n "$line" ] || continue
  case "$line" in \#*) continue ;; esac

  label="${line%%|*}"
  cmd="${line#*|}"
  [ "$label" != "$line" ] || vf_die "malformed VERIFY_STATIC_CMDS line, expected 'label|command': $line"

  ran=$((ran + 1))
  vf_log "[2:$label] running: $cmd"
  { echo "--- $label ---"; echo "command: $cmd"; echo; } >> "$LOG"

  tmp="$(mktemp)"
  # stdin comes from /dev/null on purpose. The loop below reads the command
  # list from stdin, and a tool that reads stdin itself — gradle, mvn, npm,
  # anything on a JVM — swallows the remaining lines. The checks after the
  # first then vanish, and the gate reports PASS on work it never did.
  ( cd "$VERIFY_TARGET_DIR" && eval "$cmd" ) < /dev/null > "$tmp" 2>&1
  code=$?

  cat "$tmp" >> "$LOG"
  echo "exit code: $code" >> "$LOG"
  echo >> "$LOG"

  # A missing tool is BLOCKED, never PASS and never FAIL. The shell reports it
  # as 127, which is exact — guessing from the command text misfires on env-var
  # prefixes, pipelines, and loops.
  if [ "$code" -eq 127 ] || [ "$code" -eq 126 ]; then
    blocked=$((blocked + 1))
    echo "BLOCKED: command not found or not executable (exit $code)" >> "$LOG"
    vf_log "[2:$label] BLOCKED - command not found or not executable"
  elif [ "$code" -eq 0 ]; then
    vf_log "[2:$label] PASS"
  else
    failed=$((failed + 1))
    vf_log "[2:$label] FAIL (exit $code)"
    vf_log "  last 10 lines:"
    tail -10 "$tmp" | sed 's|^|    |' >&2
  fi
  rm -f "$tmp"
done <<EOF
$VERIFY_STATIC_CMDS
EOF

{
  echo "=== SUMMARY ==="
  echo "checks:  $ran"
  echo "failed:  $failed"
  echo "blocked: $blocked"
} >> "$LOG"

vf_log ""
vf_log "static: $ran checks, $failed failed, $blocked blocked"
vf_log "receipt: $LOG"
vf_log ""
vf_log "Now split the findings into pre-existing and new. Run the same checks at"
vf_log "the diff base to tell them apart. Only new findings block this gate."

if [ "$failed" -gt 0 ]; then
  vf_record_verdict "2:static" FAIL "$failed of $ran checks failed, $blocked blocked"
  exit 1
elif [ "$blocked" -gt 0 ]; then
  vf_record_verdict "2:static" BLOCKED "$blocked of $ran tools missing"
  exit 2
fi

vf_record_verdict "2:static" PASS "$ran checks clean"
