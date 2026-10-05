#!/usr/bin/env bash
# codex-review.sh — async-backed `codex review`.
#
# The review is launched as a DETACHED background job (via codex-async.sh) so it
# can never own the host session forever. The caller then BLOCKS up to a bounded
# WAIT cap for the result. If the review outlasts the cap, the job keeps running
# detached and you poll / stop it via codex-async.sh — no `pkill` needed.
#
# codex 0.135.0: a scope flag and a free-text PROMPT are MUTUALLY EXCLUSIVE.
# Give one or the other — a bare PROMPT reviews the uncommitted diff by default.
#
# Usage:
#   codex-review.sh                          # review uncommitted changes
#   codex-review.sh --uncommitted
#   codex-review.sh --base main
#   codex-review.sh --commit <SHA>
#   codex-review.sh "Focus on security"      # uncommitted diff, custom instructions
#   codex-review.sh --wait 300 --base main   # block at most 300s for the result
#   codex-review.sh --timeout 30m            # hard-kill the codex process after 30m
#
# Caller-side knobs:
#   --wait SECS     how long to BLOCK for the result (default 540; env CODEX_REVIEW_WAIT).
#                   The host Bash tool caps a single call at 10m, so keep this <600
#                   and re-run wait/result for longer reviews.
#   --timeout DUR   hard wall-clock cap that KILLS codex (default OFF — long reviews
#                   are fine; set e.g. 30m only if you want a safety net).
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ASYNC="$HERE/codex-async.sh"

WAIT_CAP="${CODEX_REVIEW_WAIT:-540}"   # caller block cap (seconds); the job outlives it
HARD_TIMEOUT=""                        # codex-process kill cap; default OFF
SCOPE=()
SCOPE_SET=0
PROMPT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --uncommitted) SCOPE=(--uncommitted); SCOPE_SET=1; shift;;
    --base)        SCOPE=(--base "${2:?missing branch for --base}"); SCOPE_SET=1; shift 2;;
    --commit)      SCOPE=(--commit "${2:?missing sha for --commit}"); SCOPE_SET=1; shift 2;;
    --wait)        WAIT_CAP="${2:?--wait needs seconds}"; shift 2;;
    --timeout)     HARD_TIMEOUT="${2:?--timeout needs a duration}"; shift 2;;
    --) shift; PROMPT="${*:-}"; break;;
    -*) echo "unknown option: $1" >&2; exit 2;;
    *) PROMPT="$*"; break;;   # all remaining words are the prompt (keep flags first)
  esac
done

command -v codex >/dev/null || { echo "codex not installed" >&2; exit 2; }
git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "must run inside a git repo" >&2; exit 2; }

if [ "$SCOPE_SET" = 1 ] && [ -n "$PROMPT" ]; then
  echo "codex-review: pass a scope flag OR a prompt, not both (codex review forbids the combo)" >&2
  exit 2
fi

start_args=(start-review)
[ -n "$HARD_TIMEOUT" ] && start_args+=(--timeout "$HARD_TIMEOUT")
# `--`/PROMPT must come LAST: cmd_start_review treats everything after `--` as
# the prompt, so any flag placed after it would be swallowed.
if [ -n "$PROMPT" ]; then
  start_args+=(-- "$PROMPT")            # prompt alone → uncommitted diff + instructions
elif [ "$SCOPE_SET" = 1 ]; then
  start_args+=("${SCOPE[@]}")
else
  start_args+=(--uncommitted)
fi

JOB=$("$ASYNC" "${start_args[@]}") || exit $?
echo "codex-review: job $JOB (blocking up to ${WAIT_CAP}s; it keeps running if it outlasts that)" >&2

"$ASYNC" wait "$JOB" "$WAIT_CAP" >/dev/null 2>&1
ST=$("$ASYNC" status "$JOB")
case "$ST" in
  "done rc=0")
    "$ASYNC" result "$JOB"
    ;;
  timeout)
    echo "codex-review: hit hard --timeout; partial output (if any) below" >&2
    "$ASYNC" result "$JOB" 2>/dev/null || true
    exit 124
    ;;
  "done rc="*)
    echo "codex-review: review exited ${ST#done }" >&2
    "$ASYNC" result "$JOB" 2>/dev/null || true
    exit 1
    ;;
  running)
    cat >&2 <<EOF
codex-review: still running after ${WAIT_CAP}s — job is detached, NOT killed.
  result: $ASYNC result $JOB
  wait:   $ASYNC wait   $JOB <secs>
  stop:   $ASYNC stop   $JOB
EOF
    exit 0
    ;;
  *)
    echo "codex-review: unexpected status: $ST" >&2
    exit 1
    ;;
esac
