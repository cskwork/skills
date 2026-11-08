---
name: qa
description: Launch parallel QA subagents (5 scenario-based E2E users or 5 data analysts over recent changes) and return verified findings with fix proposals. /qa [e2e|data|all] [target] [--agents N] [--model M] [--effort E] [--since REF]
disable-model-invocation: true
---

# qa

The coordinator (you) fans out N independent QA delegates, then verifies and merges what they find. Delegates **find and propose**; they change nothing. Code edits and data writes happen only after the user approves the report, applied by the coordinator one at a time.

## Arguments

| Arg | Default | Values |
|---|---|---|
| mode | `e2e` | `e2e` (scenario users), `data` (data analysts), `all` (both sets in one launch) |
| target | current repo and its dev environment | URL, repo path, ticket key, feature name |
| `--agents N` | `5` | 1-10 per mode |
| `--model M` | `sonnet` (Sonnet 5.5) | Claude alias `sonnet` `opus` `haiku` `fable` or full id; non-Claude id (e.g. `gpt-6.1-sol`) for `data` only |
| `--effort E` | `medium` | `low` `medium` `high` `xhigh` `max` |
| `--since REF` | merge-base with the default branch; last 7 days when the branch has no own commits | git ref or date |

Arguments given in the request override any model routing in the user's own instructions for this run. Claude models launch through the host's subagent tool with that model and effort (Claude Code: `Agent` `model` + `effort`). A non-Claude model runs through a peer CLI (for Codex, the `call-agent` skill from cskwork/skills), and only in `data` mode: a Codex sandbox cannot launch Playwright Chromium (observed 2026-10), so `e2e` with a non-Claude model stops with that reason. When the host cannot set model or effort, run its default and say so in the report.

## Safety

- Production is out of scope. Before any DB query, confirm the connected host is dev or test (MySQL `SELECT @@hostname`, PostgreSQL `SELECT inet_server_addr()`, or the client's connection info); stop on mismatch.
- Delegates query read-only (SELECT), keep the repo untouched, and post nothing externally (Jira, Slack, PRs).
- Data a scenario must create (a post, a submission) goes through the slice's own test accounts, carries the tag `QA-<run-id>-<n>`, and is listed in the findings for cleanup.
- Tokens and passwords appear in findings as `***`.
- Project skills or scripts for tokens, test accounts, and DB access take precedence over ad-hoc ones.

## 1. Ground the run

Read the repo instructions (`AGENTS.md`, `CLAUDE.md`), then collect:

- **Changes:** `git log --oneline <since>..HEAD` and `git diff --stat <since>...HEAD`. From the diff, list changed endpoints, queries/mappers, tables, and screens with file paths.
- **Environment:** base URL, API base, test accounts per role, DB host.
- **Existing QA assets** to reuse: `browser-qa` scenarios, `release-stability-e2e` domains, `.bughunt.md`, project fixtures.
- **Run dir:** `~/.qa/runs/<yyyymmdd-hhmm>-<slug>/`, outside the repo.

Missing URL, accounts, or DB access needed by the mode: ask the user one question and wait. Otherwise invoking /qa is the go-ahead.

Done when `<run-dir>/plan.md` holds mode, target, environment with verified hostname, model and effort, the change list, and the slice table from step 2.

## 2. Slice

Slices are disjoint: each owns its journey or lens, its accounts, its created data, and its browser session. Derive slices from the change list first; fill the rest from these defaults in order (merge from the bottom when N < 5, split the busiest when N > 5).

**E2E personas** (each walks real journeys through the changed paths):

1. Main changed journey, end to end, primary role.
2. Other roles and permissions on the same journey (e.g. teacher vs student, admin vs user).
3. Edge input: empty, maximum length, special characters, double submit, back or refresh mid-flow.
4. State and interruption: reload, session expiry, second tab, slow network.
5. Regression neighbours: unchanged screens that share the changed APIs or components.

**Data analyst lenses** (each over the changed queries and APIs):

1. API vs DB: call each changed endpoint and compare response fields with the source rows.
2. Query logic: joins, filters, NULL handling, duplicates, pagination, ordering in the changed SQL.
3. Integrity: orphans, missing FK or unique guarantees, status combinations that should not exist in touched tables.
4. Aggregates and time: counts and sums vs raw rows, date boundaries, time zone, period cut-offs.
5. Before vs after: run the pre-change query (from git) and the new one on the same data; explain every differing row.

Done when every changed path in `plan.md` maps to at least one slice or is marked uncovered with the reason.

## 3. Launch

Send every slice in one message so the delegates run in parallel (`all` mode sends both sets together). Claude Code: `Agent` with `subagent_type: general-purpose`, `model`, and `effort` from the arguments. Brief each delegate with this template, filled in:

```
Goal: find real defects in <slice> of <target> as <persona | analyst lens>. Find and propose; change nothing.
Env: <base URL / API base>. DB <host>: check the connected host first and stop unless it is <host>.
Your accounts: <accounts owned by this slice only>.
Changes in scope: <files, endpoints, queries, screens>.
Your slice: <journey or lens with its concrete checks>.
Tools: browser `playwright-cli -s=qa-<run-id>-<n> open <url>` first, then the same `-s=` on every command, `close` when done | DB SELECT-only via <skill or client> | API via curl.
Rules: SELECT only; repo untouched; no commits or external posts; data you create carries tag QA-<run-id>-<n> and is listed; stress data (huge or bulk input) uses the smallest size that proves the point and is deleted right after measuring, since other testers share the data; secrets written as ***.
Stay in your slice: an issue outside it gets one line under "Out of slice" with no further investigation.
Write <run-dir>/findings-<n>.md. Per finding: title, severity (blocker | major | minor), repro steps, expected vs actual, evidence (screenshot path, request/response, query + rows), suspected root cause (file:line), fix proposal (diff or SQL draft, unapplied). End with Coverage: what you exercised, what you could not and why, and the data you created.
Done when every check in your slice is exercised or recorded as blocked with the reason. Report once: the file path and the finding count.
```

Then wait for the completion notifications.

## 4. Verify and merge

Merge findings sharing a root cause into one, keeping every repro and the slices that saw it. Reproduce each merged finding yourself (rerun the steps or the query, one batch script where possible): reproduced is CONFIRMED; otherwise UNVERIFIED with what differed. Delete the data your repros created. Run `playwright-cli list` and close leftover `qa-<run-id>-*` sessions.

Done when every finding has a verdict and `<run-dir>/report.md` is written.

## 5. Report and apply

Reply in the user's language with:

- Counts of CONFIRMED and UNVERIFIED per severity.
- Findings table: severity, finding, evidence path, root cause, fix proposal, verdict.
- Coverage gaps, leftover test data, and the model and effort actually used.
- The question: which fixes to apply.

After approval, apply one fix at a time:

- **Code fix:** apply it, run the project's existing tests, rerun the repro and show it now passes.
- **Data fix:** only on the verified dev host, only the approved statement, with before and after rows shown.

Commits, pushes, and deploys follow the repo's normal flow and need their own approval.
