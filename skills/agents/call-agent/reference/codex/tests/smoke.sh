#!/usr/bin/env bash
# codex-call smoke test
set -u

SKILL=codex-call
FAIL=0
note() { printf '[%s] %s\n' "$SKILL" "$*"; }
fail() { printf '[%s] FAIL: %s\n' "$SKILL" "$*" >&2; FAIL=1; }

# L0 — binary present
if command -v codex >/dev/null 2>&1; then
  V=$(codex --version 2>&1 | head -1)
  note "L0 ok: codex $V"
else
  note "L0 skip: codex not on PATH — install to test"
  exit 3
fi

# L1 — help works + auth detected + scripts syntax-valid
if codex --help >/dev/null 2>&1 && codex exec --help >/dev/null 2>&1 && codex review --help >/dev/null 2>&1; then
  note "L1a ok: codex / exec / review --help"
else
  fail "L1a: codex help subcommands failed"
fi

if [ -f "$HOME/.codex/auth.json" ]; then
  note "L1b ok: ChatGPT auth file present"
else
  note "L1b warn: no ~/.codex/auth.json — run \`codex login\`"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
for s in scripts/codex-imagegen.sh scripts/codex-review.sh scripts/codex-async.sh; do
  if bash -n "$SCRIPT_DIR/$s"; then
    note "L1c ok: $s syntax"
  else
    fail "L1c: $s syntax error"
  fi
done

# L2 — non-interactive round-trip
if [ "${RUN_L2:-0}" = "1" ]; then
  OUTFILE=$(mktemp -t codex-smoke-XXXXXX)
  if codex exec --sandbox read-only --skip-git-repo-check \
       -o "$OUTFILE" "Reply with exactly: OK" >/dev/null 2>&1; then
    if grep -qi 'ok' "$OUTFILE"; then
      note "L2 ok: round-trip"
    else
      fail "L2: unexpected response in $OUTFILE: $(head -c 200 "$OUTFILE")"
    fi
  else
    fail "L2: codex exec failed"
  fi
  rm -f "$OUTFILE"
fi

# L3 — actual image gen via wrapper
if [ "${RUN_L3:-0}" = "1" ]; then
  IMG=$(mktemp -u -t codex-smoke-img-XXXXXX).png
  if "$SCRIPT_DIR/scripts/codex-imagegen.sh" \
       "A small 64x64 solid red square. Minimal, no detail." \
       "$IMG" >/dev/null 2>&1 && [ -s "$IMG" ]; then
    note "L3 ok: image at $IMG"
    rm -f "$IMG"
  else
    fail "L3: no image at $IMG"
  fi
fi

# L4 — long-running async job on the DEFAULT (no --timeout) path: this is the
# one that crashes on bash 3.2 if the empty-array expansion regresses, so we
# capture start's stderr and assert no shell crash, then poll to done.
if [ "${RUN_L4:-0}" = "1" ]; then
  ASYNC="$SCRIPT_DIR/scripts/codex-async.sh"
  AERR=$(mktemp -t codex-l4-err-XXXXXX)
  JOB=$("$ASYNC" start \
        "Reply on the final line with exactly: L4-ASYNC-OK" \
        --sandbox read-only 2>"$AERR")
  if grep -qi 'unbound variable' "$AERR"; then
    fail "L4: codex-async.sh start crashed: $(cat "$AERR")"
  elif [ -n "$JOB" ] && [ -d "$JOB" ]; then
    "$ASYNC" wait "$JOB" 240 >/dev/null 2>&1
    ST=$("$ASYNC" status "$JOB")
    if [ "$ST" = "done rc=0" ] && "$ASYNC" result "$JOB" 2>/dev/null | grep -q 'L4-ASYNC-OK'; then
      note "L4 ok: async (no-timeout) start/poll/result round-trip"
    else
      fail "L4: async did not finish cleanly (status: $ST)"
    fi
    rm -rf "$JOB"
  else
    fail "L4: codex-async.sh start did not return a job dir"
  fi
  rm -f "$AERR"
fi

# L6 — start-review must be NON-BLOCKING: `$(...)` has to return while the job is
# still running (regression for the command-substitution pipe-hold bug — without
# the subshell's `>/dev/null 2>&1` redirect, start blocks until codex exits).
# Uses a little credit, then stops the job. SECONDS is a bash builtin (no Date).
if [ "${RUN_L4:-0}" = "1" ]; then
  ASYNC="$SCRIPT_DIR/scripts/codex-async.sh"
  SECONDS=0
  JOB=$("$ASYNC" start-review --uncommitted 2>/dev/null)
  EL=$SECONDS
  ST=$("$ASYNC" status "$JOB" 2>/dev/null)
  if [ -n "$JOB" ] && [ "$EL" -lt 15 ] && { [ "$ST" = "running" ] || [ "$ST" = "done rc=0" ]; }; then
    note "L6 ok: start-review returned in ${EL}s (status: $ST) — non-blocking/detached"
  else
    fail "L6: start-review blocked (${EL}s) or unexpected status ($ST)"
  fi
  "$ASYNC" stop "$JOB" >/dev/null 2>&1
  rm -rf "$JOB"
fi

# L5 — `stop` terminates a tracked job by pid (no codex / no credit). Simulates a
# running job with a backgrounded sleep, then asserts stop kills it AND records
# an rc so `status` reports finished. Guards the "no pkill needed" cancel path.
ASYNC="$SCRIPT_DIR/scripts/codex-async.sh"
TMPJOB=$(mktemp -d -t codex-stop-XXXXXX)
( sleep 60 ) & echo "$!" > "$TMPJOB/pid"
SLEEP_PID=$(cat "$TMPJOB/pid")
"$ASYNC" stop "$TMPJOB" >/dev/null 2>&1
sleep 1
if kill -0 "$SLEEP_PID" 2>/dev/null; then
  fail "L5: stop did not kill tracked pid $SLEEP_PID"; kill "$SLEEP_PID" 2>/dev/null
elif [ -f "$TMPJOB/rc" ]; then
  note "L5 ok: stop killed job + recorded rc=$(cat "$TMPJOB/rc")"
else
  fail "L5: stop killed pid but wrote no rc"
fi
rm -rf "$TMPJOB"

exit "$FAIL"
