---
name: bughunt
description: Find and fix interaction bugs in games, CRUD apps, AI chat and media apps with seeded self-playing personas, per-step invariant oracles, reproducible failure bundles, and regression replay. Use before a release candidate, after major features, or for an owner's "only happens when I do X" report. Supports Godot, native iOS, and web.
license: MIT
---

# bughunt

Exercise the product through its real controller and input paths, capture the first broken invariant, minimize it, fix the root cause, and replay the corpus. A persona is an action policy; an oracle is an independently observed condition that must hold.

## Scope and setup

1. Read repository instructions, release/build recipes, existing QA plumbing, and root `.bughunt.md`. Use [templates/project.bughunt.md](templates/project.bughunt.md) for a missing override; record chosen defaults before running. In a documentation-only run, record the chosen values in the report instead of writing the file.
2. Establish permitted edits and runs, build identity, supported platforms, isolated test storage/accounts, and concurrency constraints. A skill-only request ends with documentation validation: **do not build, launch, or modify the reference app**. An owner's postponed run remains postponed. Keep production data, purchases, publication, and other people's builds/devices outside the harness.
3. Select the adapter: [Godot](adapters/godot.md), [native iOS](adapters/ios-native.md), or [web](adapters/web.md). Extend existing project runners; do not add a testing framework merely to follow this skill. Use [references/sources.md](references/sources.md) when choosing a technique or checking platform support.
4. Select the app profile and read it before planning: [game](references/game.md), [crud-app](references/crud-app.md) (records, forms, accounts), [ai-chat](references/ai-chat.md) (model conversations, streaming), or [media](references/media.md) (record, play, camera). A product that mixes types loads every profile it ships, e.g. a game with accounts loads `game` and `crud-app`; a product matching none takes the nearest and records the unmapped flows as coverage gaps. The profile renames personas, binds oracles to the product, adds cases and fixtures; the core files stay the single source for everything it leaves unsaid.
5. Identify every shipped phase/screen and boundary: fresh launch, navigation, save, quit, cold launch, resume, interruptions, terminal states, and migration/error paths already supported. Map each to an observable oracle and a reachable test fixture. An unreachable required boundary is a coverage gap. Where a profile or oracle names a documented contract (draft kept or discarded, conflict rule, what sign-out clears) and the product documents none, report `contract absent` as a finding for the owner and assert the observable minimum: no silent data loss, no crash, a visible outcome.

Done: a recorded run matrix has concrete commands/artifacts, profile(s), fixture reset, seeds, personas, phase coverage, enabled oracles, platform layers, time/disk limits, and permitted side effects.

## 1. Prepare the shipped target

Build or reuse a provenance-checked artifact using the project's release recipe: exported Godot game, native simulator/device build, or production web bundle served locally. Record commit, dirty diff if present, artifact hash/build number, tool versions, launch flags, and settings. Editor/core tests support diagnosis; they do not prove exported input, rendering, lifecycle, or packaging behavior.

QA instrumentation must be off in normal launches. If probes require a separate QA artifact, record its exact difference from the shipped configuration and the parity checks still required. Keep assertions effective in release configurations; use explicit failure reporting rather than debug-only assertions.

Use separate test profiles, save locations, browser contexts, and devices. Reset only harness-owned fixtures before each case. Never clear the owner's profile to obtain a "new player." Stop only processes this run started.

## 2. Run seeded personas

Read [personas.md](personas.md) and adapt [templates/persona.yaml](templates/persona.yaml). Run all applicable policies, under the names and stresses the app profile gives them, plus the profile's extra cases:

| Persona | Required stress |
|---|---|
| `new-player` | Fresh onboarding, first valid actions, navigation and recovery. |
| `masher` | Rapid presses, double taps, repeated drags, modals over active controls. |
| `save-resume` | Save → quit → cold launch → Continue at every persisted phase, including terminal boundaries. |
| `interruptions` | Background/foreground, focus changes, interruptions during transitions and saves. |
| `resize` | Small/large sizes, safe insets, supported rotation and size classes during interaction. |
| `slow-player` | Wait through deadlines, idle prompts, auto-selection and timeout recovery. |
| `speed-changer` | Change supported speeds around phase changes, timers and resume. |
| `monkey` | Seeded random taps/drags/back/navigation, including invalid and outside targets. |
| `localization` | English/Korean where shipped, live switching if supported, long text and saved locale. |
| `low-power-motion` | Low power/quality and Reduce Motion modes, animation-independent readiness. |

Use a dedicated seeded policy RNG separate from product RNG. Persist explicit seed lists for both streams, initial fixture, action timestamps/ticks, delays, and environment changes. A seed alone cannot reproduce OS scheduling or network input; record those inputs too. Combine high-risk policies (resume × masher, draft × speed, locale × small size) without claiming an unrun Cartesian product.

Defaults if no project budget exists: 20 seeds per persona per required layer, two full clean passes, 60 minutes total, 250 MB of artifacts, a 30 s active-progress deadline, and 180 s per case. Adapt deadlines to real phase timers before running. These are starting budgets, not a release guarantee. Never truncate a required phase to make a case pass; budget exhaustion means `incomplete`.

## 3. Observe invariant oracles

Read [oracles.md](oracles.md); bind [templates/invariants.yaml](templates/invariants.yaml) to the project's contracts, using the app profile's bindings. A profile's extra oracles (O-9 and up) are enabled alongside O-1..O-8 and need the same controlled self-check. Check logical invariants after every action/event/tick; check presentation at each rendered frame and lifecycle boundary where instrumentation permits. External drivers must disclose their sampling interval and any unobserved frame-level checks.

| ID | Condition |
|---|---|
| `O-1` | No script/runtime errors, uncaught exceptions, crashes, or missing failure reports. |
| `O-2` | A valid enabled player command is accepted on its first attempt; invalid inputs follow their recorded rejection contract without corrupting state. |
| `O-3` | No AI/bot action for a presented phase precedes that screen's actual ready signal; human time windows survive transitions. |
| `O-4` | Active controls fit the safe area, keep required hit sizes, and have no unintended interactive overlap or modal input leakage. |
| `O-5` | Currency/HP and identity/ownership/counts satisfy domain bounds; no unexplained duplicates or vanished entities. |
| `O-6` | Same fixture, seed, logical action/timing stream, build and rules yield the same canonical logical replay. |
| `O-7` | A promised action/phase makes meaningful progress within its deadline; expected waiting and pause end correctly. |
| `O-8` | Save/load round-trips eligible logical state and rebuilds its visible representation; deleted/ineligible saves stay unavailable. |

Snapshot action eligibility **before** input and correlate the resulting command/event. Keep observations independent of the driver: setting a ready flag, submitting directly to core, or checking only a successful tap would conceal controller/presentation bugs.

Validate every enabled oracle once with a controlled failing fixture or injected observation in harness-owned test data. Verify the runner reports the failure, writes its bundle, and exits nonzero. This is a harness check, not permission to mutate the owner's game or shipped rules.

## 4. Capture, minimize, fix

On first failure, flush the seed manifest and append-only action/event log; capture screenshot, pre/post state dumps, serialized save, runtime/crash logs, expected/actual values, and build/environment identity. Use [templates/failure-report.md](templates/failure-report.md). Headless failures explicitly mark screenshot unavailable and retain logical evidence for a permitted rendered replay.

Replay from the same isolated fixture. Remove action chunks, then shorten timing/inputs while preserving the same oracle failure and required preconditions. Keep the original bundle. If unstable, record reproduction frequency and timing; do not call it minimized or deterministic without proof.

Add a regression at the lowest layer that reproduces the cause **and** an integration check through the user path that missed it. Prove the regression fails before the fix and passes after it in an isolated checkout if authorized. Never replace an enabled-command rejection with retries, reset a sequence in the core to please a controller, remove a failing seed, or weaken an invariant.

Fix within authorized scope. If the cause requires unapproved rules/API/security/migration changes, preserve the bundle and report that boundary. For transition misses (resume, screen open, end of life), read [examples/transition-misses.md](examples/transition-misses.md).

## 5. Replay and deliver

After each fix, run focused existing checks, all recorded failures, and the entire seed/persona/phase matrix. A change to build, fixture, policy, oracle, rules, or corpus resets the two-pass count.

Stop at `clean` only when the exact N-seed × applicable-persona matrix completes twice on the final build, every required phase and layer is covered, all enabled oracles ran, and failure counts are zero. A headless-clean run is only evidence for its logical layer. Skipped/unsupported checks require reasons and remain disclosed; incomplete required parity prevents an overall `clean` verdict.

Stop at the budget, a protected boundary, or an external blocker with a checkpoint: completed cells, next seed/action, failures and artifacts. Release/publish/merge authority is separate from a clean run.

Report:

```text
Verdict: clean | failed | incomplete | blocked | documentation-only
Target: commit, artifact/build hash, platform, tool versions, QA differences
Matrix: personas, explicit seeds, phases/settings/layers, pass 1 + pass 2 counts
Runs: commands, exit codes, cases/matches, steps, elapsed time, oracle counts
Bugs: expected/actual, minimal repro, root cause, regression, fix commit
Evidence: run manifest, logs, screenshots, state/save dumps, replay hashes
Limits: skipped/unsupported/unobserved checks and remaining parity/failures
Cleanup: owned processes stopped, retained artifacts and bytes
```

For documentation-only delivery, report the skill files, validation, sources and installation; list app runs as `not run`.
