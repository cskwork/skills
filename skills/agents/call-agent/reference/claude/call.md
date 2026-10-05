# call-agent -> claude (Claude Code)

Loaded by the `call-agent` router when delegating to `claude`. Lets the
host CLI shell out to Claude Code (`claude -p`) for implementation, large-context
planning, or deep review.

## When to route here

1. **Explicit name** — user says "claude" or "claude code".
2. **Feature gap** — user asks for:
   - An implementation pass from Claude Code
   - Planning over a very large codebase that benefits from Claude's
     1M-token context window
   - A plan-mode (guaranteed read-only) architecture pass
   - A deep code review (`--effort high`) for a second opinion

Route implementation only when the user explicitly asks for Claude; otherwise the host
handles routine edits.

## Preflight

```bash
./scripts/preflight-auth.sh
```

Verifies `claude` is on PATH and either Claude-Max OAuth is active or
`ANTHROPIC_API_KEY` is set.

Implementation also runs a minimal shell probe before sharing the real task:

```bash
./scripts/preflight-shell.sh
```

The probe asks Claude to run `pwd`. It catches hosts where Claude is authenticated but
cannot initialize its Bash session. It uses a small model call and may incur a small cost.

## Implementation (workspace edits)

```bash
./scripts/claude-implement.sh "<TASK DESCRIPTION>"
```

The wrapper runs both preflights, then gives Claude normal `acceptEdits` permissions in
the current workspace. It does not commit, push, or deploy unless the task explicitly
requests that action.

## MCP permissions

Planning and implementation discover configured servers with `claude mcp list` before
the delegated call. Each server name is decoded explicitly as UTF-8 and normalized to
Claude's ASCII tool-name format; this keeps discovery stable even when the wrapper runs
in the `C` locale.

The wrappers enumerate server prefixes because the approved legacy compatibility target
does not support one MCP wildcard rule. They do not use `bypassPermissions`, which would
also disable unrelated safety prompts. If server discovery fails, no MCP rules are added
and the original Claude call continues with its existing permissions.

Review deliberately does not discover or allow MCP servers. It runs in strict MCP mode
with only Claude's built-in read-only file tools, so a configured server cannot broaden a
review into an external read or write.

### Host-policy boundary

The skill cannot weaken the host platform's sandbox or approval policy. When the shell
probe is blocked, stop the delegated run and tell the user to open a normal terminal,
change to the workspace, and rerun `claude-implement.sh` with the same task. Keep Claude's
standard permission checks enabled.

## Planning (read-only)

```bash
./scripts/claude-plan.sh "<TASK DESCRIPTION>"
```

Underlying call:

```bash
claude -p --print \
  --model opus --effort high \
  --permission-mode dontAsk \
  --tools Read,Grep,Glob \
  "${CLAUDE_ALLOWED_TOOLS_ARGS[@]+"${CLAUDE_ALLOWED_TOOLS_ARGS[@]}"}" \
  --output-format json \
  --no-session-persistence \
  --add-dir "$PWD" \
  --append-system-prompt "You are a planner. Produce an actionable plan with numbered steps, risks, and acceptance criteria. Do not modify files." \
  "$PROMPT"
```

Parse `.result` for the plan text; `.total_cost_usd` and `.session_id`
for accounting.

## Code review (read-only, diff-aware, bounded)

```bash
./scripts/claude-review.sh "<PROMPT, e.g. 'Review staged changes for security'>"
```

The wrapper captures staged and unstaged diffs with fixed, non-ext-diff Git options. It
then streams Claude's review, prints read-only tool progress to stderr, and returns a
timeout diagnostic rather than waiting silently. Claude receives no MCP, shell, or
write-capable tools.

Underlying call:

```bash
claude -p --print \
  --verbose --safe-mode \
  --model opus --effort high \
  --permission-mode dontAsk \
  --strict-mcp-config \
  --tools Read,Grep,Glob \
  --allowedTools "Read Grep Glob" \
  --max-budget-usd 1.00 \
  --output-format stream-json --include-partial-messages \
  --no-session-persistence \
  --add-dir "$PWD" \
  --append-system-prompt "You are a strict code reviewer. Find correctness, security, and design bugs in the diff. Cite file:line." \
  "$PROMPT"
```

Tune a slow review without changing its permission scope with
`CLAUDE_REVIEW_TIMEOUT_SECONDS`, `CLAUDE_REVIEW_MAX_BUDGET_USD`, or
`CLAUDE_REVIEW_MAX_DIFF_BYTES`. The last setting rejects an oversized diff instead of
silently truncating it.

## Output handling

The wrapper parses newline-delimited `stream-json` output. Its terminal `result` event
contains the review text, session ID, and cost:

```json
{
  "type": "result",
  "subtype": "success",
  "result": "...the actual response markdown...",
  "session_id": "...",
  "total_cost_usd": 0.0123
}
```

The runner surfaces `.result` as Markdown on stdout and logs the session ID and cost on
stderr. Intermediate JSONL remains internal except for concise tool-progress messages.

## Model selection

All claude wrappers default to `--model opus`. Set `CLAUDE_MODEL` to any alias
(`sonnet`, `haiku`, `fable`, `opus`) or a full model name to override plan and
implement. Review resolves `CLAUDE_REVIEW_MODEL` first, then `CLAUDE_MODEL`,
then `opus`. The shell preflight probe pins a cheap model; override with
`CLAUDE_PROBE_MODEL` if the `haiku` alias ever changes.

## Auth fallbacks

- Preferred: Claude Max / Pro OAuth (stored at `~/.claude/auth.json`)
- Fallback: `ANTHROPIC_API_KEY` env var
- Long-lived token: `claude setup-token`

If the preflight reports neither, surface this verbatim:

> Run `claude auth login` (Max/Pro) or `export ANTHROPIC_API_KEY=sk-ant-...`

## See also

- [`scripts/preflight-auth.sh`](scripts/preflight-auth.sh)
- [`scripts/preflight-shell.sh`](scripts/preflight-shell.sh)
- [`scripts/claude-implement.sh`](scripts/claude-implement.sh)
- [`scripts/claude-plan.sh`](scripts/claude-plan.sh)
- [`scripts/claude-review.sh`](scripts/claude-review.sh)
- [`scripts/claude-review-stream.py`](scripts/claude-review-stream.py)
