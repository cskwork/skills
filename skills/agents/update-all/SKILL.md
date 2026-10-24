---
name: update-all
description: 'Update all coding agent harnesses (Codex, Claude Code, pi, Antigravity CLI) in one run with before/after version reporting. Use for /update-all, "update all", "update harnesses", "update codex claude pi agy", "하네스 업데이트".'
---

# update-all

Update every installed coding agent harness in one run, then print one before/after version table.

| Harness | Binary | Version check | Update command |
|---|---|---|---|
| Codex | `codex` | `codex --version` | `codex update` |
| Claude Code | `claude` | `claude --version` | `claude update` |
| pi | `pi` | `pi --version` | `pi update` |
| Antigravity CLI | `agy` | `agy --version` | `agy update` |

Run every command under the host's ordinary tool execution policy (approvals, sandbox). Do not bypass it.

## 1. Detect and snapshot (before)

For each binary, run `command -v <cli>`.

- Found: run `<cli> --version`. Record the trimmed output as **Before**.
- Version command exits nonzero: record Before as `error (exit N)` and keep its exact stderr for the report.
- Not found: mark the harness `not installed`. Skip it in steps 2 and 3.

Never guess, infer, or invent a version.

## 2. Update installed harnesses

Run the update command for each installed harness, sequentially or in parallel:

- `codex update`
- `claude update`
- `pi update`
- `agy update`

Use `pi update --all` instead of `pi update` only when the user explicitly asks to include pi extensions or packages.

For each command, keep the exact exit code and stderr, plus stdout when it explains the result.

- One failure never aborts the run. Continue with the remaining harnesses.
- Do not install missing harnesses.
- Do not elevate privileges (`sudo`), and do not retry with an alternative installer (npm, brew, curl scripts).

## 3. Verify and report (after)

Rerun `<cli> --version` for every harness that was installed in step 1, including harnesses whose update failed. Record **After** the same way as Before.

Assign one status per harness:

| Status | When |
|---|---|
| `updated` | Updater exit 0, both version reads succeeded, After differs from Before. |
| `unchanged` | Updater exit 0, both version reads succeeded, After equals Before. |
| `failed (exit N)` | Updater exited nonzero (N = updater exit code). Stays failed even if After differs from Before. Also used when the updater succeeded but a version read failed (N = that version command's exit code). |
| `not installed` | `command -v` found nothing. Nothing was run. |

Compare versions only when the updater and both version reads succeeded. No failed command gets a success status.

Print exactly one Markdown table, one row per harness, in this shape:

```markdown
| Harness | Command | Before | After | Status |
|---|---|---|---|---|
| Codex | `codex update` | <before> | <after> | updated |
| Antigravity CLI | — | — | — | not installed |
```

Use `—` for cells with no value (commands and versions of missing harnesses). Show the command actually run, for example `pi update --all` when the user opted in.

Below the table, add one fenced block per failure with the exact stderr. Name the harness and phase (`before --version`, `update`, `after --version`) and the exit code:

**pi, update, exit 1**

```text
<exact stderr>
```

If stderr is empty, write `(stderr empty)` and include stdout when it explains the failure.

## Done when

- Every installed harness had its update attempted, or its failure is reported with exact stderr.
- One full before/after table is printed.
