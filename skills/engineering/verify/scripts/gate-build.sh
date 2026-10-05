#!/usr/bin/env bash
# verify skill — gate 1, build.
#
# Runs the adapter's build command, captures everything, records the verdict.
#
#   scripts/gate-build.sh
#
# A non-zero exit is a FAIL unless the same command also fails at the diff
# base, in which case it is BLOCKED on a pre-existing break. Pass the base to
# have this script say so:
#
#   scripts/gate-build.sh --base origin/main

set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

BASE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="$2"; shift ;;
    -h|--help) sed -n '2,14p' "$0" | sed 's|^# \{0,1\}||'; exit 0 ;;
    *) vf_die "unknown argument: $1" ;;
  esac
  shift
done

vf_load_adapter
[ -n "${VERIFY_BUILD_CMD:-}" ] || vf_die "VERIFY_BUILD_CMD is not set in the adapter"
[ -n "$VERIFY_RUN_DIR" ] || vf_init_run_dir "build" >/dev/null

LOG="$VERIFY_RUN_DIR/receipts/01-build.log"

vf_log "build: $VERIFY_BUILD_CMD"
vf_log "cwd:   $VERIFY_TARGET_DIR"

{
  echo "=== BUILD ==="
  echo "command: $VERIFY_BUILD_CMD"
  echo "cwd:     $VERIFY_TARGET_DIR"
  echo "at:      $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "--- output ---"
} > "$LOG"

start="$(date +%s)"
( cd "$VERIFY_TARGET_DIR" && eval "$VERIFY_BUILD_CMD" ) < /dev/null >> "$LOG" 2>&1
code=$?
elapsed=$(( $(date +%s) - start ))

{
  echo "--- end output ---"
  echo "exit code: $code"
  echo "duration:  ${elapsed}s"
} >> "$LOG"

if [ "$code" -eq 0 ]; then
  vf_record_verdict "1:build" PASS "exit 0, ${elapsed}s"
  vf_log "receipt: $LOG"
  exit 0
fi

vf_log ""
vf_log "--- last 25 lines of build output ---"
tail -25 "$LOG" >&2
vf_log "--- end ---"

if [ -n "$BASE" ]; then
  vf_log ""
  vf_warn "build failed. Check whether $BASE fails the same way before calling this a regression:"
  vf_warn "  git -C '$VERIFY_TARGET_DIR' stash && git -C '$VERIFY_TARGET_DIR' checkout $BASE"
  vf_warn "  ( cd '$VERIFY_TARGET_DIR' && $VERIFY_BUILD_CMD )"
  vf_warn "A break that predates the diff is BLOCKED on a pre-existing failure, not FAIL."
fi

vf_record_verdict "1:build" FAIL "exit $code, ${elapsed}s"
vf_log "receipt: $LOG"
exit 1
