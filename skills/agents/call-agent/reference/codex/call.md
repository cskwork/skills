# call-agent -> codex (OpenAI Codex CLI)

Loaded by the `call-agent` router when delegating to `codex`. Shell out to
OpenAI Codex CLI (`codex`) for things the host CLI does not do natively —
primarily **image generation**, secondarily one-shot **code review** with
diff scoping.

## When to route here

1. **Explicit name** — user mentions "codex".
2. **Feature gap** — user asks for image generation (the host cannot
   do this; Codex has the best built-in option).

Do NOT route here for routine code work — the host CLI handles those.

## Preflight

```bash
command -v codex >/dev/null || { echo "codex not installed" >&2; exit 2; }
codex --version
test -f "$HOME/.codex/auth.json" || { echo "Run: codex login" >&2; exit 2; }
```

## Image generation (the headline use)

Two paths. **Prefer Path A** — uses Codex's ChatGPT subscription auth and
needs no API key.

### Path A — built-in `image_gen` tool via `codex exec`

```bash
./scripts/codex-imagegen.sh "<PROMPT>" "<ABS_OUTPUT_PATH.png>"
```

The wrapper script runs:

```bash
codex exec \
  --sandbox workspace-write \
  --dangerously-bypass-approvals-and-sandbox \
  --skip-git-repo-check \
  -C "$(dirname "$OUT")" \
  "Use the image_gen tool to generate: $PROMPT. Save the final PNG to $OUT"
```

After the call, verify `[ -s "$OUT" ]`.

### Path B — direct CLI helper (needs `OPENAI_API_KEY`)

Reserve for batch jobs or true alpha-transparency requirements.

```bash
export OPENAI_API_KEY=sk-...
python "$HOME/.codex/skills/.system/imagegen/scripts/image_gen.py" generate \
  --prompt "<PROMPT>" \
  --model gpt-image-2 \
  --quality high \
  --size 2048x1152 \
  --out "<ABS_PATH>"
```

`gpt-image-1.5 --background transparent` for native PNG alpha; gpt-image-2
cannot.

## Code review

```bash
./scripts/codex-review.sh                            # review uncommitted
./scripts/codex-review.sh --base main                # diff vs branch
./scripts/codex-review.sh --commit <SHA>             # one commit
./scripts/codex-review.sh "Focus on security"        # uncommitted + custom instructions
./scripts/codex-review.sh --wait 300 --base main     # block at most 300s
./scripts/codex-review.sh --timeout 30m              # hard-kill codex after 30m
```

Note: codex 0.135.0 forbids a scope flag together with a free-text prompt —
pass one or the other (a bare prompt reviews the uncommitted diff).

Underlying: `codex review` (mutually exclusive scope flags) is launched as a
**detached async job** (`codex-async.sh start-review`); the call then blocks up
to `--wait` seconds (default 540) for the result. A review that outlasts the cap
keeps running detached — you poll/stop it instead of the call hanging forever:

```bash
./scripts/codex-async.sh status "$JOB"   # running | done rc=0 | timeout
./scripts/codex-async.sh result "$JOB"   # the review markdown, once done
./scripts/codex-async.sh stop   "$JOB"   # cancel (targeted kill, never pkill)
```

`--timeout` (hard codex-process kill) is OFF by default so long, legitimate
reviews are not cut short; set it only as a safety net. The host Bash tool caps
one call at 10m, so keep `--wait` under 600 and re-issue `wait` for longer runs.

## One-shot non-interactive prompt

```bash
codex exec \
  --sandbox read-only \
  --skip-git-repo-check \
  -o /tmp/codex-out.txt \
  "<PROMPT>"
```

Output flags:
- `-o, --output-last-message FILE` — final message only (cleanest)
- `--json` — JSONL event stream
- `--output-schema FILE` — JSON Schema constrains final response

## Long-running / async jobs (don't block the host)

`codex exec` is synchronous — a multi-minute task blocks Claude Code until
it returns. For a long job you want to start now and collect later, use the
async wrapper:

```bash
JOB=$(./scripts/codex-async.sh start "<LONG TASK>" --sandbox read-only --timeout 10m)
./scripts/codex-async.sh status "$JOB"     # running | done rc=0 | timeout
./scripts/codex-async.sh wait   "$JOB" 600 # block until done (cap 600s)
./scripts/codex-async.sh result "$JOB"     # final message once finished
./scripts/codex-async.sh stop   "$JOB"     # cancel a runaway job (targeted kill)
./scripts/codex-async.sh resume "$JOB" "<FOLLOW-UP>"  # continue same session
```

`start-review` is the same machinery for `codex review` (see Code review above).
`stop` terminates by the recorded pid + its children — never `pkill -f`, so it
does not trip the broad-kill permission prompt.

The job is a temp dir; poll it from any later turn. See `patterns.md`
Pattern 6 for the full recipe.

## See also

- [`patterns.md`](patterns.md)
- [`reference.md`](reference.md)
- [`scripts/codex-imagegen.sh`](scripts/codex-imagegen.sh)
- [`scripts/codex-review.sh`](scripts/codex-review.sh)
- [`scripts/codex-async.sh`](scripts/codex-async.sh)
