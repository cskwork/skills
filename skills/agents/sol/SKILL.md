---
name: sol
description: Orchestrate application work through GPT-6.1 Sol subagents (high reasoning, fast tier). Use for /sol, "use sol", or handing build, fix, backend, browser or QA slices to Sol workers.
---

# sol

You are the **orchestrator**: slice, brief, launch Sol workers, integrate, verify. Workers own the slices; you own the whole.

Explicit `/sol` sends **every** slice to Sol, UI/frontend and docs included; it overrides model routing in `rules.md`.

## Steps

1. **Native check.** Host already runs `gpt-6.1-sol` at high reasoning (Codex)? Use its own subagents and skip step 5's shell call. Otherwise launch workers with `codex exec`. Never use a Claude/Opus subagent as a Sol stand-in.
2. **Preflight** (once):

   ```bash
   command -v codex && test -f ~/.codex/auth.json
   codex exec -m gpt-6.1-sol -c model_reasoning_effort=low --ephemeral --skip-git-repo-check \
     -C "${TMPDIR:-/tmp}" "Reply with exactly: ok" < /dev/null   # proves auth, provider/proxy, model
   # </dev/null matters: with an open stdin, codex waits for it even when a prompt is given
   grep -Eq '^approvals_reviewer *= *"auto_review"' ~/.codex/config.toml
   ```

   First two fail: report `codex login` / install / provider error, stop. Third fails: workers cannot escalate (see Sandbox), so slices that write outside the repo or use system services will fail; brief them around it (`--add-dir`, in-repo output paths) or report it.
3. **Collect the rules a worker won't see.** Codex loads `AGENTS.md` only from the git root of `-C` down. When the repo sits inside a larger workspace, find the parent `AGENTS.md`/`CLAUDE.md` and project docs that govern it and list them in each brief's `Read first`.
4. **Slice.** Slices that share no files, state or ordering run in parallel; dependent slices run in sequence. Size each slice to finish well under 2 h. Write one brief per slice to `<scratch>/<slice>.brief.md`:

   ```markdown
   Objective: <one outcome>
   Read first: <parent AGENTS.md/CLAUDE.md and docs the worker would not load itself>
   Skills to load: <skills that fit the stack: testing, UI/design, platform, QA>
   Owned paths: <only files/dirs this worker may change>
   Interfaces to honor: <APIs, types, contracts that must not change>
   Constraints: <repo rules, no git push/merge, no store uploads>
   Acceptance: <exact commands/checks that must pass, plus the default acceptance below>
   Known facts: <verified findings, file:line>
   Report once at the end: changed files, checks run with results, evidence paths, open problems. No progress messages.
   ```

   **Default acceptance** (add to every brief, adapt to the stack):
   - Existing build, lint and tests for the touched area pass.
   - Changed behavior has evidence: a test, a command transcript, or for UI a capture at the smallest and largest supported viewport plus one empty/error state.
   - The result is recorded where the project records verification (readiness file, decision log, changelog), if it has one.
   - Every process, server, device, emulator or simulator the worker started is stopped and removed.

5. **Isolate, then launch.** Parallel slices in one git repo each get their own worktree, so diffs stay attributable and path-keyed build caches don't collide:

   ```bash
   git -C "<repo>" worktree add "<scratch>/wt/<slice>" -b "sol/<slice>"
   ```

   Not a git repo: run its slices in sequence with `-C "<repo>"`. Launch each slice as a background task with the host's **maximum** timeout (Claude Code Bash: `timeout: 7200000`); the default (30 min in Claude Code) kills workers mid-build:

   ```bash
   codex exec --json -m gpt-6.1-sol -c model_reasoning_effort=high -c service_tier=fast \
     -s workspace-write --skip-git-repo-check -C "<scratch>/wt/<slice>" \
     -o "<scratch>/<slice>.out.md" - < "<scratch>/<slice>.brief.md" > "<scratch>/<slice>.jsonl"
   ```

   Block on completion notifications; never short-poll.
6. **Integrate.** Read each `.out.md`, confirm `git -C "<scratch>/wt/<slice>" diff --stat <base>...` touches only owned paths, merge the slice branches into the working branch, then run the acceptance checks yourself on the merged result. Remove the worktrees when done.
7. **Retry once, with context.** A failed slice resumes its own session instead of a cold re-brief. Take `thread_id` from the first line of `<slice>.jsonl` (`{"type":"thread.started","thread_id":...}`), write the failure evidence to `<scratch>/<slice>.fix.md`, and run from the slice directory:

   ```bash
   codex exec resume --skip-git-repo-check "<thread_id>" -o "<scratch>/<slice>.out.md" - < "<scratch>/<slice>.fix.md"
   ```

   A second failure is reported, not retried.

## Sandbox

`-s workspace-write` allows writes only in `-C`, `--add-dir` dirs and temp. It denies writes to user caches and toolchain dirs (e.g. `~/Library/Developer/Xcode/DerivedData`, `~/.gradle`, package-manager caches) and blocks IPC to system services (e.g. `xcrun simctl` cannot reach CoreSimulatorService). Workers get past this only by requesting escalation, which `codex exec` approves through `approvals_reviewer = "auto_review"` in `~/.codex/config.toml`. Without it, pass known cache dirs with `--add-dir` or point build output inside the repo. Don't add `--approve-for-me`: codex-cli 0.164.0 rejects it with a usage error (exit 2).

## Rules

- Keep `-s workspace-write`; never `--dangerously-bypass-approvals-and-sandbox`.
- Workers never commit to `main`, push, merge or publish; the orchestrator does that, only when authorized.
- Don't pass `--ephemeral` to workers; it drops the session step 7 resumes.

**Done =** every slice's acceptance checks pass under your own run, or the failing slice is reported with its evidence and what remains.
