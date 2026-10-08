# .bughunt.md

Copy to the target project root and replace sample values with its recorded recipes/contracts. This file configures the target's existing or newly authorized harness; it is not a runner.

## Scope

- Target / adapter: <artifact and godot | ios-native | web>
- Allowed edits/runs: <paths, platforms, time window; or documentation-only>
- Concurrent/protected resources: <builds, simulators, owner profile, production accounts>
- Fix boundary: <UI/controller permitted; rules/API/migration changes require separate scope>
- Build and launch recipes: <existing file/command, QA differences, release parity required>
- Owned fixture/reset/save path: <resolved location; reset only between independent cases>

## Personas and coverage

- Include: new-player, masher, save-resume, interruptions, resize, slow-player, speed-changer, monkey, localization, low-power-motion.
- Skip with reason: <persona/feature absent or postponed; required unsupported coverage stays blocked>
- Persisted phases and terminal boundaries: <every actual phase, elimination/results, checkpoints>
- Settings: <small/large devices and safe insets, supported rotation, EN/KR/shipped locales, speeds, render styles, motion/power>
- Required layers: <exported volume, rendered input/layout, simulator/device/OS parity>
- Paired risks: <resume × masher, transition × speed, locale × small size, save × interruption>

## Budgets and completion

- Seeds per persona per required layer: 20; explicit policy seeds 1000–1019.
- Game seeds / fixtures: <explicit mapping, pinned RNG and initial data>
- Clean passes: 2 on identical final build/corpus, isolated fixture reset each case.
- Total time: 60 min; case timeout: 180 s; artifact cap: 250 MB.
- Active-progress deadline: 30 s; phase-specific overrides: <actual timers + margin and pause/resume policy>.
- Budget exhaustion: incomplete; record completed cells and next case. Do not silently reduce N.
- Artifacts: <unique owned directory; retain failures, manifest, counters and replay evidence within cap>.
- Required phase/settings combinations: <explicit manifest cells; a random seed does not imply coverage>.

## Oracles

- Enable: O-1 runtime, O-2 commands, O-3 readiness, O-4 layout/input, O-5 state, O-6 replay, O-7 progress, O-8 persistence.
- Contract bindings / observation hooks: <source/API for each ID; cadence; minimum target units>
- Expected invalid input and duplicate semantics: <conditions + exact result, defined before action>
- Canonical state projection: <fields, volatile-field exclusions with reason, hash scheme>
- Extra invariants: <ID, contract, observation, predicate, cadence, controlled self-check>
- Unsupported/unobserved oracles: <reason, affected layer; never a silent pass>

## Evidence and delivery

- Failure bundle: seed + action/event JSONL + screenshot + state/save dump + logs + build/fixture identity.
- Regression runner / user-path check: <existing suite and integration entry point>.
- Summary: completed matrix and both pass counts, oracle observations, skips, failures, fixes, cleanup.
- Commit/push/release authority: <explicit current scope; clean runs confer none>.
