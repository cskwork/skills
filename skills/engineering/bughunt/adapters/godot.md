# Godot adapter

Use when the permitted target is a Godot game. Read its UI/core contract, `ui/debug/`, existing `tests/ui/` and export recipes first. This file specifies an adapter to implement in a target project **only when authorized**; it does not supply or install a game harness.

## Integration contract

Add or extend a QA-only Node, launched from the app root after parsing `OS.get_cmdline_user_args()`. The runner owns reset fixtures, a separate policy RNG, seed manifest, action queue, observations, failure artifacts and a final nonzero exit on failure. Default launches leave it inactive. Use a QA-specific profile/save directory or application identity; check the actual resolved `user://` before writing.

Proposed flags (not built-in Godot options; adapt names to the project's existing QA flags):

```text
--bughunt=new-player,save-resume   selected validated persona IDs
--seeds=20                       count per persona; emit the explicit list
--seed-start=1000                fixed policy seed range
--bughunt-out=<absolute-dir>     unique harness-owned output directory
--bughunt-replay=<manifest>      exact fixture/actions/environment replay
```

Reject unknown personas, malformed counts and conflicting replay/generation options. Record game seed as well as policy seed. Keep suite pass iteration, platform launch and timeout/crash supervision outside the game process, so a game softlock cannot freeze its own watchdog.

| Hook | Required observable behavior |
|---|---|
| Reset / start | Owned save/profile reset, explicit game seed and initial settings; launch real lobby/onboarding/Continue. |
| Observe | Snapshot real phase/view, controller sequence, visible targets, domain events and command results without mutating state or stealing the UI's event drain. |
| Act | Use game's existing controller/command API with phase IDs and payloads; log emitted command/result. |
| Input | Inject press/release/drag through the viewport for navigation, hit testing, modal interception, double taps and custom-drawn controls. |
| Persist / resume | Use real save-and-quit and cold Continue path; compare state and visible representation, then issue first valid command. |
| Finish / fail | Flush JSON summary, JSONL actions/events, state/save dump, logs and screenshot when rendered; explicit exit status. |

Calling `core.submit` directly bypasses sequence restoration, control eligibility and screen wiring. Use controller paths for volume and UI input paths for boundary coverage. Retain a rendered UI case for every command/path that volume bypasses.

For touch input, use `InputEventScreenTouch` press and release and `InputEventScreenDrag` for movement with consistent touch indices. `Input.parse_input_event` feeds input handling; convert local control coordinates with the viewport's actual transform. For mouse projects use mouse events. `Input.action_press` or emitting `pressed` alone does not exercise GUI hit routing. Wait for the resulting event/view, with a deadline, rather than assuming two frames means success. [Godot input API](https://docs.godotengine.org/en/stable/classes/class_input.html).

## Observation and clocks

- Readiness must come from the presented screen after reveal/transition, not the autoplayer. Subscribe read-only to command results/events at the session boundary; preserve normal event processing order.
- Record core ticks, real frame delta, speed multiplier and holds separately. Never accelerate draft reveals, human deadlines or interruption cases just to finish the corpus.
- Continuous checks inspect runtime logs, sequence/result correlation, state ledger, phase progression and replay hashes. Rendered checks inspect actual visible actors/plates and hit regions; no dummy-renderer screenshots count as visual evidence.
- Observe `NOTIFICATION_APPLICATION_PAUSED`/`RESUMED` and focus behavior through the app's real routing. Injected notifications test handlers; simulator/device OS backgrounding tests delivery. Record which was exercised.
- Keep ordinary error checks effective in exported release-like builds. Godot `assert` behavior differs by build; explicitly record failure and return nonzero.

## Run layers

1. **Headless desktop volume:** a permitted exported desktop build with the same content/rules, or the existing project test runner where export support is absent. Report project-script runs separately from exported runs. Rendering, audio, OS lifecycle and packaging parity remain unproven.
2. **Rendered desktop:** actual UI input, layout/safe area, EN/KR, small/large dimensions and render styles; retain transition-frame evidence.
3. **Exported iOS simulator:** follow the project's simulator export recipe, preserve release settings except documented QA hooks, use a separately authorized owned simulator/profile, and run a smaller recorded corpus twice. A simulator is not physical-device power, thermal, haptic or lifecycle proof.

Illustrative invocation **after implementing these custom flags and obtaining run authority**:

```sh
./build/game --headless -- --bughunt=save-resume,masher --seeds=20 --seed-start=1000 --bughunt-out=/tmp/bughunt-owned-run
```

Custom args follow `--`; export templates support fewer switches than editor binaries. Verify the pinned version's help/docs and the local export recipe before selecting commands. [Godot CLI](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html).

## Regression runner

Keep the existing runner. Standalone `SceneTree` UI tests can drive the real app root without adopting another framework. If the project already uses **gdUnit4**, use its scene runner and pinned `GdUnitCmdTool.gd` CLI; if it uses **GUT**, keep its fixtures/input helpers and `gut_cmdln.gd`. Read the version-matched docs before choosing flags. GUT's CLI can return success with pending tests: count pending/skipped required cases in the coverage verdict. Sources: [gdUnit4 CLI](https://github.com/godot-gdunit-labs/gdUnit4/blob/master/documentation/doc/_advanced_testing/cmd.md), [GUT CLI](https://gut.readthedocs.io/en/latest/Command-Line.html).

For concrete controller, presentation and save-lifecycle misses, read [worked examples](../examples/transition-misses.md). Reuse a project's existing QA drivers only if they do not mutate state the persona depends on (e.g. a playtest script that resets preferences, deletes outputs or forces an unpaused session cannot be used unchanged for interruption or owner-profile testing).
