# Invariant oracles

Bind these IDs to real API/schema/UI contracts before executing; use [templates/invariants.yaml](templates/invariants.yaml). Observe independently of action generation. Maintain an append-only event stream with logical tick and wall time, phase ID, actor ID, action/command ID and result.

| ID | Observation and assertion | Failure / false-positive boundary |
|---|---|---|
| `O-1 runtime` | Collect engine/browser/device logs continuously; monitor process exit/crash and runner heartbeat. A supervisor fails a missing final report or timeout. | Nonzero exit or errors fail even if the UI appears healthy. Classify known benign warnings explicitly; never blanket-ignore script errors. |
| `O-2 commands` | Snapshot pre-input eligibility; trace input → controller → submit → result → visible consequence. Each valid emitted command is accepted once, on first attempt. | Failed taps/missing commands also fail after a bounded response deadline. Expected invalid-input rejection must match code and preserve state; explicit idempotent duplicates may be acknowledged without a second effect. |
| `O-3 presentation` | Record phase-open, attached/visible/interactable screen, actual readiness, first bot action, and human timer start. Require bot action ≥ readiness and full contractual human decision time. | `_ready()`/DOM attachment alone does not imply a completed reveal. A fail-safe that releases a gate before readiness is still an oracle failure. Use project-defined screens for off-screen AI, not a global ban on background simulation. |
| `O-4 layout/input` | In one coordinate system measure visible hit regions vs safe-area bounds, pairwise unintended interactive intersection, minimum target dimensions, clipping and modal hit routing. | Decorations may overlap. Intentional modal coverage must intercept input. Exclude off-screen/hidden/disabled targets by contract, not because a check failed. Sample transition frames as well as settled screens. |
| `O-5 state` | Check domain bounds, unique entity/command identities, location/ownership bijections and entity ledger after each mutation. Relate core entities to visible actors/tokens/plates in the current phase. | Currency/HP cannot go negative where the schema forbids it; signed debt/damage values use their documented bounds. Death, merge, sale and elimination explain removals with events; an empty legitimate state is not itself a bug. |
| `O-6 replay` | Hash canonical logical state/event sequence at fixed ticks; replay with the same build/rules, initial state, seeds, inputs and logical timing. Compare first divergent tick, not only final score. | Normalize volatile IDs/timestamps/render-only state through an explicit whitelist. Same seed with different action timing is not equal input. Floating physics may require scoped determinism; do not claim cross-platform bit equality without evidence. |
| `O-7 progress` | Define a progress token (phase/turn/completed action/navigation/result), next promised transition and deadline. An external wall-clock watchdog complements logical tick checks. | Animation, repeated taps or heartbeat alone are not progress. Track elapsed active time for intended pauses plus a separate resume deadline. Slow-player deadlines include the actual timer and allowed transition margin. |
| `O-8 persistence` | Compare canonical eligible state immediately before save and after cold load; inspect error/backup paths; verify first command and visible reconstruction. After deletion/terminal ineligibility, later checkpoints/background/quit must not resurrect Continue. | Compare at the same logical instant or pause first. Legitimate dropped ephemeral state is documented. Validating serialization alone misses controllers, lobby eligibility and rendered representation. |

## Measurements

- Logical state checks run after every dispatched action and drained event, and every simulation tick where available. Transient presentation checks run after layout/render frames with timestamps shared by the event stream.
- External XCUITest/Maestro/Playwright checks sample after steps unless a QA probe supplies frame observations. Record the cadence. A screenshot after the reveal cannot prove that no bot acted before it.
- Use actual hit regions (including custom-drawn board slots), safe insets, viewport transforms and display scale. For iOS use the project's iPhone baseline, normally 44 × 44 pt targets; for web use its documented CSS-pixel requirement. Raw export pixels are not points. [Apple button guidance](https://developer.apple.com/design/human-interface-guidelines/buttons) and [WCAG target-size minimum](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html) define different baselines.
- Record frame/step observation counts per oracle, not only "enabled." Unsupported frame instrumentation stays a declared coverage limit.

## Oracle self-check

Use isolated harness-owned fixtures or feed deliberately invalid observations to each oracle: runtime error, unexpected reject, pre-ready bot event, out-of-safe-area hit rect, duplicate entity, altered replay hash, frozen progress token, and terminal save resurrection. Require the right ID, expected/actual values, persisted evidence and nonzero final status. This demonstrates detection, not product correctness. Retain normal and failing self-check evidence.

## Failure ordering

Capture the first divergence before further actions overwrite it. Log later errors as secondary. Evidence writes must be flushed before quitting; a failed write is itself a runner failure. Keep original and minimized action streams distinct, and retain both wall-time and logical-time information for presentation races.
