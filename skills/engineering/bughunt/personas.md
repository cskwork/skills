# Seeded personas

Translate each policy into the project's action vocabulary. Every persona has a reset fixture, seeded selection/delay rules, phase coverage, expected outcomes, and a terminal condition. Definition format: [templates/persona.yaml](templates/persona.yaml).

| ID | Action policy | Boundary coverage / evidence |
|---|---|---|
| `new-player` | Start with a harness-owned fresh profile; follow onboarding using visible controls, then perform the first purchase/place/equip/submit equivalents. Back out and re-enter a screen. | First launch → notice/tutorial → usable screen; onboarding overlay cannot steal or leak input; initial and terminal screenshots. |
| `masher` | Seed bursts of 2–5 taps at 0–100 ms gaps, double-taps, repeated drags and open/close. Repeat near phase changes and behind modals. | Command/result correlation, duplicate IDs, first enabled command after navigation/resume, unchanged state for consumed/invalid presses. |
| `save-resume` | At each eligible phase save through UI, quit, cold launch, Continue, then perform the first valid command. Also pause during a save and visit elimination/results. | Before-save → loaded-state hashes; entity/visible actor identities; eligibility of Continue after terminal events and later checkpoints. |
| `interruptions` | Background/foreground or focus loss/gain before/after an action, during presentation, save, deadline and modal. Use a separate run for real OS interruptions. | Correct pause policy, no lost/duplicated action, atomic saves, same first actionable state on foreground. Injection alone is not OS proof. |
| `resize` | Visit supported smallest/largest viewport and scale classes; rotate during drag, modal, keyboard and transition where rotation is shipped. | Safe-area and hit bounds, clipping, modal input interception, camera/board usability. Unsupported rotations are skipped with a reason. |
| `slow-player` | Wait before onboarding/choices; let each supported timer expire without input, then attempt the next enabled action. | Timeout/autopick events occur once; no softlock, shortened human window, stale enabled control, or hidden required action. |
| `speed-changer` | Cycle shipped rates, e.g. 1x/2x/3x, before/during/after playback, draft and resume. Keep real-time deadlines separate from playback ticks. | Simulation results stable for equal logical actions; presentation readiness, pause and player time budgets remain correct. |
| `monkey` | Seed bounded taps/drags/back commands across valid controls, disabled controls, blank areas and modal borders. Allocate some actions to navigation so it does not remain on one screen. | Log coordinates, target ID/eligibility, timings and result; invalid input is safe, valid command does not silently reject; replay exact stream. |
| `localization` | Run EN and KR where shipped; open longest labels/details, change language through Settings when supported, resume with saved preference. | No raw keys, unwanted truncation/overlap or missing actions at both sizes; text fits controls and supported Korean word wrapping. Other shipped locales remain in the project matrix. |
| `low-power-motion` | Toggle project low-quality/power and Reduce Motion settings where available; repeat transition/resume with animation reduced. | Ready/completion signals work without tweens; state, commands and timers agree; record OS mode vs app-emulated mode separately. |

## Scheduling

- Use stable ordering: persona → explicit seed → fixture/phase → settings/layer. Record policy version and RNG algorithm; avoid wall-clock randomness in selection.
- A corpus is the full set of cases, not just a seed count. Enumerate phase fixtures, locale, size, board/render style, and lifecycle paths in the manifest. Record how many cells actually ran.
- Keep mandatory scenarios even if random actions never reach them. Use deterministic prefixes (reach draft, save, resume) followed by seeded exploration.
- Add paired boundary cases: resume then rapid Ready; background at checkpoint then Continue; slow draft at each playback speed; EN/KR at smallest size with a modal; terminal event followed by another save attempt.
- Reset persistent data between cases; retain it only within a save-resume case. Run the second pass from the same initial fixtures, not pass 1's leftovers.
- Skip a persona only when the feature is absent or execution is disallowed; record the reason and affected evidence. Missing tooling for a shipped feature is `blocked`, not proof of correctness.

## Input expectations

For each action record: phase, target, visible/enabled/hittable state, rules eligibility, modal ownership, expected command count/result, payload, and the observed command/result. Read this snapshot immediately before dispatch; do not reclassify a rejected command as invalid afterward.

Examples: the first tap on an enabled Ready must be accepted; a second tap after Ready disabled may emit no command; a seeded tap on a disabled purchase must have no economic effect. If a phase changes between snapshot and dispatch, retain ordering evidence and apply the project's explicit race contract. Unexpected `RATE_LIMITED` for an ordinary enabled player action is a failure, including after Continue.
