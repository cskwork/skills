# codex-call — Patterns

## Pattern 1 — Single image (Path A, no API key)

```bash
./scripts/codex-imagegen.sh \
  "Polished hero shot of a matte ceramic mug on a wood desk, soft window light" \
  "/abs/path/hero.png"
```

The wrapper handles sandbox/approval flags and verifies the output file.

## Pattern 2 — Multiple variants in parallel

```bash
./scripts/codex-imagegen.sh "<PROMPT v1>" /abs/path/v1.png &
./scripts/codex-imagegen.sh "<PROMPT v2>" /abs/path/v2.png &
./scripts/codex-imagegen.sh "<PROMPT v3>" /abs/path/v3.png &
wait
```

Independent prompts only — these do not share state. Concurrency 3 is a
safe default; higher risks rate-limit responses.

## Pattern 3 — Batch (Path B, needs `OPENAI_API_KEY`)

For 10+ images, prefer the bundled batch helper:

```bash
cat > /tmp/jobs.jsonl <<'JSONL'
{"prompt":"...", "out":"/abs/path/01.png", "size":"1024x1024"}
{"prompt":"...", "out":"/abs/path/02.png", "size":"1024x1024"}
JSONL

python "$HOME/.codex/skills/.system/imagegen/scripts/image_gen.py" generate-batch \
  --input /tmp/jobs.jsonl --concurrency 4
```

## Pattern 4 — `codex review` for diff scoping (async-backed)

```bash
# Review only uncommitted changes
./scripts/codex-review.sh --uncommitted

# Review vs a base branch (PR-style)
./scripts/codex-review.sh --base main

# Review a single commit
./scripts/codex-review.sh --commit abc1234

# Bound how long the caller blocks (job keeps running if it outlasts this)
./scripts/codex-review.sh --wait 300 --base main
```

Use this when you want a fresh model's read on the same diff Claude just
produced. The script runs `codex review` as a detached async job and blocks
only up to `--wait` seconds — a slow review never turns into an indefinite
hang. If it outlasts the cap, poll/stop it:

```bash
./scripts/codex-async.sh result "$JOB"   # the review markdown, once done
./scripts/codex-async.sh stop   "$JOB"   # cancel — targeted kill, no pkill
```

## Pattern 5 — Structured output (planning artifacts)

```bash
cat > /tmp/plan.schema.json <<'JSON'
{ "type":"object", "required":["steps","risks"],
  "properties":{
    "steps":{"type":"array","items":{"type":"string"}},
    "risks":{"type":"array","items":{"type":"string"}}}}
JSON

codex exec --sandbox read-only --skip-git-repo-check \
  --output-schema /tmp/plan.schema.json \
  -o /tmp/plan.json \
  "Plan migration from X to Y; respond per schema." </dev/null
```

## Pattern 6 — Long-running / async job (don't block the host)

`codex exec` is synchronous: a multi-minute job blocks the host CLI until
it returns. When you want to **fire a long task, keep working, and collect
the answer once it finishes**, use the async wrapper instead of inlining
`codex exec ... &`.

```bash
A=./scripts/codex-async.sh

# 1. Start — returns a JOB_DIR immediately, runs codex in the background
JOB=$("$A" start "Audit this repo for N+1 queries and write findings" \
        --cd "$PWD" --sandbox read-only --timeout 30m --stall 600)

# 2. Do other work here... then poll (non-blocking) or block with a cap
"$A" status "$JOB"        # running | stalled idle=<sec>s | done rc=0 | timeout | missing
"$A" wait   "$JOB" 540    # done/cap: exit 0; stalled: exit 3 (handle under set -e)

# 3. Collect the final assistant message once finished
"$A" result "$JOB"

# 4. Cancel a runaway job (targeted pid kill + its children; never pkill -f)
"$A" stop   "$JOB"

```

`--stall SECS` is a positive integer output-idle limit, default **600 seconds**.
`CODEX_ASYNC_STALL`, when set, overrides the option; the selected limit is saved
in the job. Start time and each output file's mtime/size track liveness, including
a job that never emits its first event. A live PID with unchanged output becomes
`stalled idle=<sec>s`; `wait` prints that state and returns **3** before its cap.
Stall detection leaves the process running until the host calls `stop`.

**Monitor (copy-paste, Bash):** the host's own loop must exit after **10 minutes
with unchanged output**, then stop and report. A PID check alone is insufficient.
This loop exits on `done|timeout|stalled|missing` and independently checks all three
output files even when the wrapper's stall threshold is longer than 10 minutes.

```bash
A=./scripts/codex-async.sh
# JOB must be the job directory returned by start/start-review.
previous=""
changed=$(date +%s)
until
  state=$("$A" status "$JOB") || exit $?
  case "$state" in
    "done rc="*|timeout|stalled*|missing) true ;;
    running) false ;;
    *) printf 'Unexpected job state: %s\n' "$state" >&2; exit 2 ;;
  esac
do
  snapshot=$(python3 - "$JOB" <<'PY'
import sys
from pathlib import Path
for name in ("err.log", "events.jsonl", "last.txt"):
    try:
        stat = (Path(sys.argv[1]) / name).stat()
        print(name, stat.st_mtime_ns, stat.st_size)
    except FileNotFoundError:
        print(name, "missing")
PY
  ) || exit $?
  now=$(date +%s)
  if [ "$snapshot" != "$previous" ]; then
    previous="$snapshot"
    changed="$now"
  fi
  if [ "$((now - changed))" -ge 600 ]; then
    state="stalled idle=$((now - changed))s"
    break
  fi
  sleep 30
done
printf '%s\n' "$state"
case "$state" in
  "done rc=0") "$A" result "$JOB" ;;
  stalled*)
    "$A" stop "$JOB" || exit $?
    printf 'Job stalled; stopped. Report the blocker and log paths: %s\n' "$JOB" >&2
    exit 3 ;;
  *) printf 'Job ended without success; report: %s (%s)\n' "$state" "$JOB" >&2; exit 1 ;;
esac
```

**Recovery: stop + one resume.** After stopping and reporting, an exec job with
a recorded thread ID can resume the same session **once**. Check `id` first;
if startup never emitted an ID, or this is a review job, report that resume is
unavailable. Resume is synchronous, so bound it too (`timeout` is required below;
on macOS use `gtimeout` if that is the installed binary):

```bash
"$A" stop "$JOB" || exit $?
"$A" id "$JOB" || exit $?  # no ID means no resume
timeout 10m "$A" resume "$JOB" "Continue once; report the startup blocker first"
```

If that attempt fails or reaches its 10-minute cap, stop and report. Do not
repeat resume or widen the sandbox. The original job's status describes the
original run; resumed output is in `resume-last.txt` / `resume-err.log`.

Why a wrapper and not a bare `&`: it captures the codex `thread_id` (for
`resume`), records the real exit code so `status` never guesses, writes
the final message to a file you can read later, applies an optional hard
`--timeout` (codex has no native one), detects output stalls, and exposes a `stop` that kills by
recorded pid instead of a broad `pkill -f` pattern sweep (the kind that
hits a permission prompt). Jobs live under `~/.codex/async-jobs/` (override
with `CODEX_ASYNC_HOME`) so you can poll them from any later turn; they do
not survive a host reboot.

`start-review` runs `codex review` through this same machinery (Pattern 4).

## Anti-patterns

- Using Codex for image gen when the user did NOT ask for an image —
  unnecessary cost.
- Using Path B when Path A would work — Path A is free under the ChatGPT
  subscription; Path B is metered.
- Forgetting `--skip-git-repo-check` for ad-hoc image jobs outside a
  repo.
- Running long agentic loops in `codex exec` — that defeats the "Codex
  for capability gap" framing. Use Claude Code for the loop, Codex for
  the one capability.
