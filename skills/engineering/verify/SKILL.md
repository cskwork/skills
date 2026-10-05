---
name: verify
description: Verify changed service behavior with replayable build, static-analysis, review, and HTTP scenario receipts. Use for endpoint verification or a merge-readiness report.
---

# verify

A green build is not proof. It proves the compiler was satisfied. It does not prove the endpoint accepts the real payload, that the query returns the right rows, or that the change did not break the caller.

This skill trades that gap for **receipts**: recorded artifacts another person can re-run and reach the same verdict. No receipt, no pass.

Five gates, in order. Each gate ends on a receipt written to disk.

| # | Gate | Question it answers | Receipt |
|---|------|--------------------|---------|
| 1 | Build | Does the changed code assemble? | command, exit code, tail of output |
| 2 | Static | Does it pass this repo's own syntax, type, lint, and schema checks? | per-tool exit code and finding counts |
| 3 | Clean code | Is this diff code you would approve? | finding per changed file, or explicit `none` |
| 4 | Scenario | Does each touched API behave live, across payload variants? | raw request and response per variant |
| 5 | Report | Would a colleague understand what you proved? | `report.md` |

## The three verdicts

Every gate lands on exactly one:

- **PASS** — ran, and the receipt shows the expected result.
- **FAIL** — ran, and the receipt shows something wrong.
- **BLOCKED** — could not run. Missing credential, unreachable dependency, no local runtime.

`BLOCKED` is never `PASS`. Report it as `BLOCKED` and name the one thing that would unblock it. A skipped gate that reads as green is the failure this skill exists to prevent.

Also separate **pre-existing** failures from **regressions**. A lint error that already fails on the base commit is pre-existing; say so and move on. A lint error the diff introduced is a regression and blocks gate 2.

## Phase 0 — Scope

A gate needs a subject. Establish it before running anything.

1. **Find the diff base.** Use the base the user named. Otherwise use the merge-base with the repo's main or release branch. State which base you used and why.
2. **Inventory the change.** `git diff --stat <base>..HEAD` plus uncommitted work. List every changed file.
3. **Derive the API target list.** For each changed file, trace up to the HTTP endpoints that reach it. For jobs, events, or other non-HTTP entrypoints, name the actual boundary and the evidence needed; do not invent an endpoint.
4. **Load the adapter.** The adapter is a shell file of `VERIFY_*` assignments — build command, static checks, run command, health URL, token acquisition, account creation. `scripts/lib.sh` resolves `$VERIFY_ADAPTER_FILE`, then `<target-repo>/.verify/adapter.env`, then `adapters/<name>.env` under `VERIFY_ADAPTER=<name>`. No adapter for this stack yet? Copy `adapters/_template.env`, fill it in by reading the repo with `adapters/_template.md` as the field guide and `adapters/spring-mybatis.md` as a worked example, and save it as `<target-repo>/.verify/adapter.env` — the next run finds it on its own.
5. **Open the run directory.** Export `VERIFY_TARGET_DIR=<target-repo>` before any script runs; it defaults to the current directory, so an agent working from the skill folder writes receipts into the skill. The run is then `.verify/<YYYYMMDD-HHMM>-<slug>/` in the target repo, and all receipts land there.

**Completion criterion:** a written target list where every changed file is either mapped to at least one endpoint or explicitly marked as having none, and an adapter loaded or authored.

State the target environment and scenario matrix. Continue checks already authorized; ask only before a live action whose target or data mutation is not covered by the user’s instruction. Account creation is a write and follows the same boundary.

### The environment ladder

Gate 4 calls a real service, so name the target environment in the plan and hold to this ladder:

| Environment | Reads | Writes |
|-------------|-------|--------|
| local, dev | default | allowed within an explicitly authorized endpoint/data scope |
| staging, audit, pre-production | when the user authorizes this target | only for explicitly authorized endpoints and data |
| production | never from this skill | never |

Production stays off the ladder. A read there still costs a token in a real session, a rate-limit slot, and an audit-log entry, and one mistyped variant writes. Set `VERIFY_FORBIDDEN_HOSTS` in the adapter to the production hostnames, and `scripts/lib.sh` refuses them before curl runs. When a change can only be proved in production, stop and hand the user the exact command instead of running it.

Check the target repository's own rules first — many teams write this policy down, and their wording wins over this table.

**"Local" is not automatically safe.** A dev profile usually points at a shared development database, so a local process writes shared data. Confirm where the datasource actually points before any write variant.

## Gate 1 — Build

Run `scripts/gate-build.sh --base <base>`. It runs the adapter's build command, captures stdout and stderr to `receipts/01-build.log`, and records the verdict.

A non-zero exit prints the commands to re-run the same build at the base: a build already broken at the base is `BLOCKED` on a pre-existing break, not a `FAIL` on this diff.

**Completion criterion:** `receipts/01-build.log` exists, and the report quotes the command, the exit code, and the final error line if any. A build claim with no log is not a claim.

`FAIL` here stops the run. Gates 2 to 4 have nothing to measure.

## Gate 2 — Static

Run `scripts/gate-static.sh`. It walks the adapter's `VERIFY_STATIC_CMDS` one line at a time, writes each tool's output and exit code to `receipts/02-static.log`, and records a tool it cannot execute as `BLOCKED` rather than `PASS`.

The adapter lists only checks the repo already owns: type check, linter, formatter in check mode, schema and config parsers, dependency audit. Scope every tool to the changed files where the tool supports it. Whole-repo mode buries this diff's one new warning under two hundred old ones.

Two checks earn their own attention because compilers miss them:

- **Serialization contract** — a changed request or response type must still parse the real payload shape. Fixture files or a round-trip test, not inspection.
- **Data-layer syntax** — externalized queries such as SQL mapper XML, migrations, or GraphQL documents parse at build time in some stacks and only at first call in others. When the stack defers it, that check belongs to gate 4.

**Completion criterion:** every tool the adapter lists has a line in `receipts/02-static.log` with its name, exit code, and finding count, split into pre-existing and new.

## Gate 3 — Clean code

Read `references/clean-code-gate.md` before you open the diff. It sets the reading order — one pass per question — and the severity bar that decides whether a finding blocks.

Judge only the diff. Unrelated cleanups belong to a different task.

**Completion criterion:** one row per changed file in the findings table, with `none` written out where you found nothing. An empty table is ambiguous between "clean" and "not looked at".

Findings at **blocking** severity fail this gate. Everything else records as a note and the gate passes.

## Gate 4 — Scenario

The gate that produces real proof. It calls the running service.

### 4a — Bring the service up, and prove it is *your* code

Start it per the adapter, then poll the health URL until it answers. Record the health response as the first receipt. A scenario suite run against a dead port produces connection errors that look like application bugs.

Then answer the question health cannot: **is the process serving the diff?**

A service is often already listening on that port — started by an IDE, left over from this morning, or a container from last week. It answers health perfectly and runs code that predates your change. Every variant then passes, and the report certifies a fix that is not deployed.

Check it, do not assume it:

- Compare the process start time against the commit time of the change. A process older than the commit cannot contain it.
- Or read a build identifier the service exposes, such as a build-info endpoint or a version banner in its log.
- Or restart it yourself, so the question does not arise.

Found a foreign process on the port? Do not kill it — it may be someone's debugger session. Start a second instance on another port instead, and remember that most stacks need **two** ports moved, the application port and the management port.

**Completion criterion:** the receipt names the process you called and the evidence that it contains the change.

### 4b — Get a token

Protected endpoints need a credential. Use `scripts/token.sh`, which the adapter configures:

```bash
export VERIFY_ADAPTER=<stack>          # selects adapters/<stack>.env
TOKEN=$(scripts/token.sh)              # prints token to stdout, caches it
scripts/token.sh --refresh             # forces a new one after a 401
```

The script caches to `.verify/.token-cache/` and refreshes on expiry, so a suite of thirty calls costs one login. It prints the token to stdout only and never writes it into a receipt — `scripts/lib.sh` redacts credentials before anything reaches disk.

Read `references/token-module.md` to wire a new stack into it.

### 4c — Get an account

A token needs a subject that exists. When the adapter's token call needs a user, group, or tenant that is absent, create one before retrying. The adapter names the mechanism and its inputs.

Prefer the fixture the adapter already documents over a hand-built row. A synthesized account that skips a required relation produces a token that authenticates and then fails every business rule, which reads as an application bug.

**One real account per role in scope.** When the change touches endpoints that several roles use, each role needs a real account of that role and a call to its own endpoints. Flipping the role claim on an existing token proves the guard refuses it — it proves nothing about whether that role's endpoints work. Read `references/scenario-design.md` for why this is the easiest gap to miss and still feel finished.

Record what you created, so it can be cleaned up or reused.

**Completion criterion:** every role in scope has either a real account of that role recorded, or a `BLOCKED` line naming the role and the account that would unblock it.

### 4d — Run the variants

Per endpoint, build a payload matrix. Read `references/scenario-design.md` for how to source realistic payloads and what each variant proves.

The floor is three variants per endpoint:

| Variant | Proves |
|---------|--------|
| `happy` | The documented contract holds for a real, valid payload. |
| `boundary` | Empty, maximum, null, and unicode inputs behave. |
| `negative` | Bad input is rejected with the right status, not a 500. |

Add `regression` when the work fixes a bug: the payload that reproduced it must now pass. Add `authz` when the change touches permissions: the same call as the wrong role must be refused.

Source payloads in this order, stopping at the first that works: user-supplied case, saved fixture from an earlier run, a real row from the database with identifiers redacted, then synthesized. Say which you used. A synthesized payload proves less than a real one and the report must not blur that.

Write one JSON file per endpoint into `<run>/scenarios/`, then run `scripts/run-scenarios.sh`. It fires every variant through `scripts/call.sh`, so each raw exchange lands in `receipts/04-scenario/<endpoint>.<variant>.txt` and the suite re-runs from the files instead of from memory. Use `scripts/call.sh` directly for a single ad-hoc call.

**Completion criterion:** every endpoint in the phase 0 target list has one receipt per planned variant, and each receipt carries the request, the response status, the response body, and the assertion outcome. Copy results into the report verbatim. Paraphrasing a response is how a wrong field slips through.

### 4e — Check the side effects

A 200 is not the whole answer. When the call writes, read the write back: query the row, check the emitted event, confirm the file. When the call was supposed to fix a wrong value, show the value before and after.

**Completion criterion:** each writing endpoint has a before and after observation in its receipt.

## Gate 5 — Report

Write `.verify/<run>/report.md`, then give the verdict, material limitations, and report path in chat.

Write it in the **wait-what** style: assume the reader lost the thread, give back the context they are missing, one idea per sentence, and use this project's own vocabulary. Read `references/report-style.md` — this is the deliverable, and a correct verification described badly still leaves the reader guessing.

**Completion criterion:** the report carries a verdict line, a gate table with all five verdicts, the receipt paths, an explicit list of what stayed unverified, and the next action for the user.

## Red flags

Each of these means a gate did not really run. Go back.

- "Build passed" with no exit code quoted.
- A scenario table with no response bodies.
- A gate marked `PASS` whose receipt file does not exist.
- One variant per endpoint, all of them `happy`.
- A role called "verified" when only its `authz` refusal was tested.
- A gate 4 that ran against production, or against staging with no instruction to.
- A `200` accepted as proof for a write, with no read-back.
- Findings phrased as "looks good" or "seems fine".
- A `BLOCKED` gate summarized as "verified".

## Iteration

A `FAIL` hands back a **delta**, not "it broke". Name the endpoint, the variant, the expected result, the observed result, and the most likely source line. Then fix the delta and re-run only the gates the fix could have changed.

Continue a scoped repair while new evidence supports a different next step and the user authorized fixing failures. Stop when the same blocker repeats without a new discriminator, or the next action needs new scope or access. Report the receipts and the specific missing input.
