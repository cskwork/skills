#!/usr/bin/env bash
# codex-async.sh — run a long Codex task in the BACKGROUND and collect the
# result when it finishes, without blocking the host CLI.
#
# Why: `codex exec`/`codex review` are synchronous. For a multi-minute job the
# host (Claude Code / Codex) would block indefinitely. This wrapper turns one
# job into a small "job directory" you can poll, wait on, read, stop, and
# resume — so a hang can never own the session, and cancelling needs only a
# targeted kill (never `pkill -f`).
#
# Subcommands:
#   start        "<PROMPT>" [opts]   launch `codex exec` in background, print JOB_DIR
#   start-review [SCOPE] [opts] [P]  launch `codex review` in background, print JOB_DIR
#   status <JOB_DIR>                 running | stalled idle=<n>s | done rc=<n> | timeout | missing
#   wait   <JOB_DIR> [secs]          block until done, stalled, or secs elapse
#   result <JOB_DIR>                 final message / review markdown (once done)
#   stop   <JOB_DIR>                 terminate a running job (targeted kill, no pkill)
#   id     <JOB_DIR>                 codex thread/session id (exec jobs only)
#   resume <JOB_DIR> "<PROMPT>"      continue the SAME codex session (exec jobs only)
#
# start / start-review options:
#   --cd DIR         working root for codex (default: $PWD)
#   --sandbox MODE   read-only | workspace-write (start only; default read-only)
#                    danger-full-access is refused: a host agent in auto mode is blocked
#                    from launching an unsandboxed agent ("Create Unsafe Agents"). Use
#                    workspace-write + --network + --add-dir instead. A human running this
#                    in a normal terminal may set CODEX_ASYNC_ALLOW_FULL_ACCESS=1.
#   --network        allow outbound network inside workspace-write (DB, HTTP APIs)
#   --add-dir DIR    extra writable dir besides --cd (repeatable; workspace-write)
#   --timeout DUR    hard wall-clock cap, e.g. 5m or 300s (needs `timeout`/`gtimeout`; default OFF)
#   --stall SECS     output-idle limit (positive integer; default 600; CODEX_ASYNC_STALL overrides)
# start-review scope (mutually exclusive, default --uncommitted):
#   --uncommitted | --base BRANCH | --commit SHA
#
# Exit codes: 0 ok (including wait cap), 2 setup/usage error, 3 wait detected a stall.
set -uo pipefail

die() { echo "codex-async: $*" >&2; exit 2; }

# thread id lives in the very first JSONL event: {"type":...,"thread_id":"<uuid>"}
extract_thread_id() {
  python3 - "$1" <<'PY' 2>/dev/null
import sys, json
try:
    with open(sys.argv[1]) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            tid = json.loads(line).get("thread_id")
            if tid:
                print(tid); break
except Exception:
    pass
PY
}

# Stable base dir: macOS reaps per-user $TMPDIR, which would orphan a job polled
# across turns. Override with CODEX_ASYNC_HOME. (Jobs still do not survive a host
# reboot — the detached subshell dies with the session.)
make_job_dir() {
  local base="${CODEX_ASYNC_HOME:-$HOME/.codex/async-jobs}"
  mkdir -p "$base" >/dev/null 2>&1 || return 1
  mktemp -d "$base/job-XXXXXX" 2>/dev/null
}

# Sets global TBIN to (timeout DUR) / (gtimeout DUR) / empty. Empty when no
# duration or no binary; ${TBIN[@]+"${TBIN[@]}"} is the set -u-safe expansion
# (a bare "${TBIN[@]}" is a fatal "unbound variable" on bash 3.2 / macOS).
build_tbin() {
  TBIN=()
  local tmout="${1:-}"
  [ -n "$tmout" ] || return 0
  if   command -v timeout  >/dev/null; then TBIN=(timeout  "$tmout")
  elif command -v gtimeout >/dev/null; then TBIN=(gtimeout "$tmout")
  else echo "codex-async: no timeout binary; running without a cap" >&2; fi
}

preflight() {
  command -v codex >/dev/null || die "codex not installed"
  [ -f "$HOME/.codex/auth.json" ] || die "no codex auth. Run: codex login"
}

# Persist each output's mtime AND size: a same-size rewrite or a write that
# preserves mtime still counts. Polling itself must never refresh liveness.
# Python is already required for thread-id extraction; os.stat works on both
# macOS and Linux without incompatible stat flags.
activity_idle() {
  python3 - "$1" <<'PY'
import json, os, sys, tempfile, time
from pathlib import Path

job = Path(sys.argv[1])
try:
    started = job / "started"
    # Jobs launched before stall tracking have only a pid timestamp.
    start = int(started.read_text()) if started.exists() else (job / "pid").stat().st_mtime
    outputs = {}
    for name in ("err.log", "events.jsonl", "last.txt"):
        try:
            stat = (job / name).stat()
        except FileNotFoundError:
            continue
        outputs[name] = [stat.st_mtime_ns, stat.st_size]
    state = job / "activity.json"
    previous = json.loads(state.read_text()) if state.exists() else {"outputs": {}, "last": start}
    last = max(start, previous["last"], *(value[0] / 1e9 for value in outputs.values()))
    for name, value in outputs.items():
        old = previous["outputs"].get(name)
        if old and value[0] == old[0] and value[1] != old[1]:
            last = time.time()
    current = {"outputs": outputs, "last": last}
    if current != previous or not state.exists():
        fd, temporary = tempfile.mkstemp(prefix=".activity-", dir=job)
        try:
            with os.fdopen(fd, "w") as output:
                json.dump(current, output)
            os.replace(temporary, state)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)
    print(max(0, int(time.time() - last)))
except Exception as error:
    print(f"codex-async: cannot track activity: {error}", file=sys.stderr)
    sys.exit(2)
PY
}

validate_stall() {
  case "$1" in
    ""|*[!0-9]*) die "--stall / CODEX_ASYNC_STALL needs positive integer seconds";;
  esac
  [ "$1" -gt 0 ] 2>/dev/null || die "--stall / CODEX_ASYNC_STALL needs positive integer seconds"
}

init_activity() {
  date +%s > "$1/started" || die "cannot record job start"
  printf '%s\n' "$2" > "$1/stall" || die "cannot record stall limit"
  activity_idle "$1" >/dev/null || die "cannot initialize activity tracking"
}

cmd_start() {
  [ "$#" -ge 1 ] || die "usage: start \"<PROMPT>\" [--cd DIR] [--sandbox MODE] [--network] [--add-dir DIR]... [--timeout DUR] [--stall SECS]"
  local prompt="$1"; shift
  local cdir="$PWD" sandbox="read-only" tmout="" network="" stall=600
  local extra=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --cd)      cdir="${2:?--cd needs a dir}"; shift 2;;
      --sandbox) sandbox="${2:?--sandbox needs a mode}"; shift 2;;
      --network) network=1; shift;;
      --add-dir) [ -d "${2:?--add-dir needs a dir}" ] || die "--add-dir: no such directory: $2"
                 extra+=(--add-dir "$2"); shift 2;;
      --timeout) tmout="${2:?--timeout needs a duration}"; shift 2;;
      --stall) [ "$#" -ge 2 ] || die "--stall needs seconds"
               stall="$2"; shift 2;;
      *) die "unknown option: $1";;
    esac
  done
  stall="${CODEX_ASYNC_STALL-$stall}"
  validate_stall "$stall"
  case "$sandbox" in
    read-only|workspace-write) ;;
    danger-full-access)
      [ "${CODEX_ASYNC_ALLOW_FULL_ACCESS:-}" = 1 ] || die "danger-full-access refused (host auto mode blocks unsandboxed agents). Use: --sandbox workspace-write [--network] [--add-dir DIR]";;
    *) die "--sandbox: unknown mode: $sandbox";;
  esac
  if [ -n "$network" ]; then
    [ "$sandbox" = workspace-write ] || die "--network needs --sandbox workspace-write"
    extra+=(-c sandbox_workspace_write.network_access=true)
  fi
  [ "${#extra[@]}" -eq 0 ] || [ "$sandbox" != read-only ] || die "--add-dir needs --sandbox workspace-write"
  preflight
  [ -d "$cdir" ] || die "--cd: no such directory: $cdir"
  local job; job=$(make_job_dir) && [ -d "$job" ] || die "cannot create job dir"
  printf '%s' "$prompt" > "$job/prompt.txt"
  init_activity "$job" "$stall"
  build_tbin "$tmout"
  # EXIT trap records the exit code UNCONDITIONALLY so `status` can always tell
  # a finished job from one that crashed at launch.
  # The subshell-level `>/dev/null 2>&1` is load-bearing: without it the
  # backgrounded subshell inherits the `$(...)` command-substitution pipe and
  # holds it open, so `JOB=$(... start ...)` would block until codex exits
  # (defeating the whole point). Redirecting the subshell's own fds closes that
  # pipe, so `start` returns the moment the foreground `echo "$job"` runs.
  # `</dev/null` on every codex call is load-bearing too: when stdin is an open
  # pipe, `codex exec` prints "Reading additional input from stdin..." and waits
  # for EOF forever, so the job sits idle doing no work.
  (
    trap 'echo "$?" > "$job/rc"' EXIT
    ${TBIN[@]+"${TBIN[@]}"} codex exec --json --skip-git-repo-check \
      --sandbox "$sandbox" -C "$cdir" ${extra[@]+"${extra[@]}"} \
      -o "$job/last.txt" "$prompt" \
      < /dev/null > "$job/events.jsonl" 2> "$job/err.log"
  ) >/dev/null 2>&1 &
  echo "$!" > "$job/pid"
  echo "$job"
}

cmd_start_review() {
  local cdir="$PWD" tmout="" prompt="" stall=600
  local scope=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --uncommitted) scope=(--uncommitted); shift;;
      --base)        scope=(--base "${2:?--base needs a branch}"); shift 2;;
      --commit)      scope=(--commit "${2:?--commit needs a sha}"); shift 2;;
      --cd)          cdir="${2:?--cd needs a dir}"; shift 2;;
      --timeout)     tmout="${2:?--timeout needs a duration}"; shift 2;;
      --stall)       [ "$#" -ge 2 ] || die "--stall needs seconds"
                     stall="$2"; shift 2;;
      --) shift; prompt="${*:-}"; break;;
      -*) die "unknown option: $1";;
      *) prompt="$*"; break;;   # all remaining words are the prompt (keep flags first)
    esac
  done
  stall="${CODEX_ASYNC_STALL-$stall}"
  validate_stall "$stall"
  preflight
  [ -d "$cdir" ] || die "--cd: no such directory: $cdir"
  # codex 0.135.0: a scope flag and a free-text PROMPT are mutually exclusive.
  # PROMPT alone implies the uncommitted diff; a scope flag alone takes no prompt.
  local rargs=()
  if [ "${#scope[@]}" -gt 0 ] && [ -n "$prompt" ]; then
    die "codex review rejects a scope flag together with a PROMPT — pass one or the other"
  elif [ -n "$prompt" ]; then
    rargs=("$prompt")
  elif [ "${#scope[@]}" -gt 0 ]; then
    rargs=("${scope[@]}")
  else
    rargs=(--uncommitted)
  fi
  local job; job=$(make_job_dir) && [ -d "$job" ] || die "cannot create job dir"
  printf 'review %s' "${rargs[*]}" > "$job/prompt.txt"
  echo review > "$job/kind"
  init_activity "$job" "$stall"
  build_tbin "$tmout"
  # `codex review` has no --json and no -o: it writes markdown to stdout, which
  # we capture to last.txt so `result` can read it. It reads the repo at cwd
  # (no -C flag), so we cd in the subshell.
  # `>/dev/null 2>&1` on the subshell is load-bearing — see cmd_start.
  (
    trap 'echo "$?" > "$job/rc"' EXIT
    cd "$cdir" || exit 3
    ${TBIN[@]+"${TBIN[@]}"} codex review "${rargs[@]}" \
      < /dev/null > "$job/last.txt" 2> "$job/err.log"
  ) >/dev/null 2>&1 &
  echo "$!" > "$job/pid"
  echo "$job"
}

cmd_status() {
  local job="${1:?usage: status <JOB_DIR>}"
  [ -d "$job" ] || { echo "missing"; return 0; }
  if [ -f "$job/rc" ]; then
    local rc; rc=$(cat "$job/rc")
    [ "$rc" = "124" ] && { echo "timeout"; return 0; }   # timeout/gtimeout cap hit
    echo "done rc=$rc"; return 0
  fi
  local pid; pid=$(cat "$job/pid" 2>/dev/null || echo "")
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    local stall=600 idle
    if [ -f "$job/stall" ]; then stall=$(cat "$job/stall") || die "cannot read stall limit"; fi
    validate_stall "$stall"
    idle=$(activity_idle "$job") || return 2
    if [ "$idle" -ge "$stall" ]; then echo "stalled idle=${idle}s"; else echo "running"; fi
  else
    echo "done rc=?"
  fi
}

cmd_wait() {
  local job="${1:?usage: wait <JOB_DIR> [secs]}"
  local cap="${2:-0}" waited=0
  [ -d "$job" ] || die "no such job dir: $job"
  local state
  while :; do
    state=$(cmd_status "$job") || return $?
    case "$state" in
      stalled*) echo "$state"; return 3;;
      running) ;;
      *) echo "$state"; return 0;;
    esac
    if [ "$cap" -gt 0 ] && [ "$waited" -ge "$cap" ]; then
      echo "wait: still running after ${cap}s" >&2; echo "$state"; return 0
    fi
    sleep 2; waited=$((waited + 2))
  done
}

cmd_result() {
  local job="${1:?usage: result <JOB_DIR>}"
  [ -f "$job/rc" ] || die "job not finished yet (status: $(cmd_status "$job"))"
  if [ -s "$job/last.txt" ]; then cat "$job/last.txt"; else
    echo "codex-async: no final message; stderr tail:" >&2
    tail -n 20 "$job/err.log" >&2; return 1
  fi
}

# Kill a process and its descendants by walking `pgrep -P` depth-first. Targeted
# pid kills only — never `pkill -f`, which mass-kills by pattern and trips the
# permission prompts that block a broad sweep.
kill_tree() {
  local pid="$1" child
  if command -v pgrep >/dev/null 2>&1; then
    for child in $(pgrep -P "$pid" 2>/dev/null); do kill_tree "$child"; done
  fi
  kill "$pid" 2>/dev/null
}

cmd_stop() {
  local job="${1:?usage: stop <JOB_DIR>}"
  [ -d "$job" ] || die "no such job dir: $job"
  if [ -f "$job/rc" ]; then echo "already finished ($(cmd_status "$job"))"; return 0; fi
  local pid; pid=$(cat "$job/pid" 2>/dev/null || echo "")
  [ -n "$pid" ] || die "no pid recorded for job"
  kill_tree "$pid"
  sleep 1
  # The subshell's EXIT trap may not fire on SIGTERM; record a synthetic rc so
  # `status` reports a finished job (143 = 128 + SIGTERM).
  [ -f "$job/rc" ] || echo "143" > "$job/rc"
  echo "stopped (rc=$(cat "$job/rc"))"
}

cmd_id() {
  local job="${1:?usage: id <JOB_DIR>}"
  local tid; tid=$(extract_thread_id "$job/events.jsonl")
  [ -n "$tid" ] && echo "$tid" || die "no thread id (exec jobs only; review jobs have none)"
}

cmd_resume() {
  local job="${1:?usage: resume <JOB_DIR> \"<PROMPT>\"}"
  local prompt="${2:?resume needs a prompt}"
  local tid; tid=$(extract_thread_id "$job/events.jsonl")
  [ -n "$tid" ] || die "no thread id; cannot resume"
  # `resume` inherits the original session's sandbox; it rejects --sandbox/-C.
  codex exec resume --skip-git-repo-check \
    -o "$job/resume-last.txt" "$tid" "$prompt" </dev/null >/dev/null 2>"$job/resume-err.log" \
    && cat "$job/resume-last.txt" \
    || { echo "codex-async: resume failed" >&2; tail -n 20 "$job/resume-err.log" >&2; return 1; }
}

main() {
  local sub="${1:-}"; shift || true
  case "$sub" in
    start)        cmd_start        "$@";;
    start-review) cmd_start_review "$@";;
    status)       cmd_status       "$@";;
    wait)         cmd_wait         "$@";;
    result)       cmd_result       "$@";;
    stop)         cmd_stop         "$@";;
    id)           cmd_id           "$@";;
    resume)       cmd_resume       "$@";;
    ""|-h|--help) sed -n '2,/^set -uo pipefail/{ /^set -uo pipefail/d; p; }' "$0";;
    *) die "unknown subcommand: $sub (try --help)";;
  esac
}

main "$@"
