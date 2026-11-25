---
name: pre-commit-gate
description: Ordered gate before every git commit or push of code changes - optional simplify, then verify with evidence, then an independent diff review, looping until clean, then commit and push. Use before committing or pushing code, when asked whether a change is ready to commit or push, or when a harness instruction asks for a cleanup pass right before commit.
---

# pre-commit-gate

Code edited after it was verified ships unverified. The gate therefore orders the work by one rule: **every step that edits code runs before every step that judges it.**

| # | Gate | Edits code | Done when |
|---|------|-----------|-----------|
| 1 | Simplify (optional) | yes | the diff is simplified with behaviour preserved, or the skip reason is recorded |
| 2 | Verify | no | the changed behaviour was observed running, with a receipt for each check |
| 3 | Review | no | an independent review of the full diff has no unresolved correctness finding |
| 4 | Commit and push | no | the commit holds exactly the reviewed staged change and the remote shows it |

Stage the change by path before gate 2: gates 2 and 3 judge the staged change, and every fix is re-staged before the gates run again. Stage every file the change needs, including new files the build or the run reads; an untracked helper passes locally and is missing from the commit. While the gates run, keep the working tree equal to the index (`git diff --quiet --ignore-submodules=none` passes, and no tracked file is marked `assume-unchanged` or `skip-worktree`), so builds and reviewers see exactly what will be committed. When gate 2 starts, note the _snapshot_: `git rev-parse -q --verify HEAD` and `git write-tree`. A change to either restarts gate 2.

Scope: code changes. A commit that touches only docs runs gate 4 alone, plus the repo's doc validation script if one exists.

## Verdicts

Every gate lands on exactly one verdict:

- **PASS**: ran, and the receipt shows the expected result.
- **FAIL**: ran, and the receipt shows something wrong.
- **BLOCKED**: could not run. Name the one thing that would unblock it.

A BLOCKED gate stays BLOCKED in the report; the commit waits until the user accepts it with that evidence in view.

## The loop

Any edit made in gate 2 or gate 3 sends the work back to gate 2, then gate 3, on the new diff. Give each pass the previous round's failures and findings so it builds on them. Gate 1 does not re-run. Give each finding at most 3 fix attempts; after the third, stop and report what was tried.

## Gate 1: Simplify

Run it only for a large change: a new module or feature, or a diff of roughly 300 changed lines or more. For anything smaller, record the skip: gate 3 still runs, and Claude Code's `/code-review` reports cleanups where its recipe covers them, so a separate pass would mostly repeat it.

- Use the harness's own simplify or cleanup command or skill (Claude Code `/simplify`: quality fixes only, applied to the tree; it does not hunt bugs).
- Keep edits inside the changed lines and their direct callers.
- Preserve every input, output, side effect, and error path.

A harness instruction to "run simplify right before commit" is satisfied here: the cleanup happens before commit, and verification covers it.

## Gate 2: Verify

Use the repo's or the user's `verify` skill when one is installed. Otherwise, in order:

1. Build the changed module.
2. Run the repo's own static checks (type, lint, schema).
3. Exercise the changed behaviour for real: call the endpoint, run the CLI, drive the screen, query the data. Record the command and what it returned.
4. Run tests only where the repo's instructions or the user ask for them, and report which ran.

A passing compile is a gate 2 receipt for step 1 only; behaviour needs step 3.

The author runs the checks; the checks stay _independent_ of the author:

- Derive the scenarios from the request and its acceptance criteria, written before reading the new code.
- Keep the checks (scenario files, verify adapter, gate rules) where the change cannot edit them. A diff that edits the check judging it needs the user's sign-off.
- Include inputs the author did not pick: generated or property-based cases, a real data row, the boundaries the requirement names.
- For auth, permissions, deletion, data migration, or money, hand the receipts and acceptance criteria to a separate grader in a fresh context to rule PASS or FAIL.

## Gate 3: Review

The reviewer is _independent_: it reads the diff without the author's reasoning. Review the full change: branch commits against the base plus staged and unstaged edits.

| Harness | Command |
|---------|---------|
| Claude Code | `/code-review medium <base>...HEAD` on a branch with pushed commits (without a target it skips what the tracking branch already has), plus the staged change; use `high` for auth, permissions, deletion, data migration, or money. It reads the loaded project instructions, not `REVIEW.md`, so keep review rules in `AGENTS.md`. |
| Codex CLI | `codex review --uncommitted` for the working tree, `codex review --base <branch>` for a branch. `--base` shows the net change against the merge base, so a staged edit that reverts a branch commit disappears from it; on a branch with earlier commits, also review `git diff --cached` on its own. The scope flags take no prompt, so a later round restates round 1's full scope and the earlier findings as the prompt: `codex review "Review git diff <base>...HEAD plus the staged change. Earlier findings: …"`. |
| Any other | A fresh subagent with no conversation history. Give it the diff command and the path to the repo's review rules only; ask for correctness findings, each with `file:line` and a concrete failure scenario. |

Triage every finding: fix it (back to gate 2), or reject it with evidence from code, data, or a run. A finding left untriaged keeps the gate at FAIL.

When gate 3 passes, and HEAD and `git write-tree` still equal the snapshot, record the snapshot values themselves as the receipt, at once, before any other edit or staging. A BLOCKED gate the user accepted records the same receipt, with the acceptance in the report.

```sh
echo "<snapshot HEAD, or none> <snapshot tree>" > "$(git rev-parse --git-path pre-commit-gate-receipt)"
```

The receipt names the base commit and the exact staged tree that verify and review judged. This skill's `hooks/pre-commit`, when installed, blocks a code commit whose HEAD or staged tree differs from it.

## Gate 4: Commit and push

1. Commit the staged change with the repo's message conventions and hooks. Anything else to stage sends the work back to gate 2.
2. Compare `git rev-parse 'HEAD^{tree}'` with the snapshot tree (a docs-only commit notes `git write-tree` just before committing). When a hook rewrote and re-staged files, they differ: keep the commit unpushed, run gates 2 and 3 on it against the snapshot HEAD, and go on only when both pass; a fix becomes a new staged change that starts at gate 2.
3. Push when the user or the repo's instructions authorize it.
4. Confirm the branch you actually pushed to holds the commit: `git ls-remote <remote> refs/heads/<branch>` prints its SHA.

## Report

One row per gate: gate, verdict, receipt (command and result, finding counts, or skip reason). Put BLOCKED rows first.

## Project overrides

The repo's `AGENTS.md` may set per-gate commands: test scope, review level, verify adapter, commit message rules. Those win over the defaults here. Keep project-specific commands, hosts, and accounts in the project, out of this skill.
