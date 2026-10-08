# Native iOS adapter

Use the project's existing XCUITest or Maestro suite and release-like simulator build. Record scheme, configuration, build number/hash, OS/device, locale, appearance, text size, launch arguments and instrumentation differences. Use an isolated app container/test account and an owned simulator; resets affect only test data.

## XCUITest

- Choose controls by stable accessibility identifiers; inspect `exists`, `isEnabled`, `isHittable` and frame before an action. Use gestures for tap, double tap, drag and modal interception. A successful `tap()` call does not prove a command was accepted.
- Pass deterministic fixture/seed parameters via `XCUIApplication.launchArguments` or `launchEnvironment` to a QA-only entry point. Record the actual initial state and generated actions; XCUITest is not a seeded monkey by itself.
- For cold resume, save through UI, `terminate()`, relaunch without clearing the container, Continue, then assert the first command result and visible state. `activate()` foregrounds an existing app; it does not stand in for a cold launch. [Apple app lifecycle API](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication).
- Background using the existing device/home workflow, then activate; interrupt at save/transition/timer boundaries. Simulated handlers and actual OS delivery have separate case IDs.
- Check frames in points against app-reported safe bounds and project target sizes; include smallest device, supported rotation/size class, EN/KR, Dynamic Type where shipped, and modal/keyboard paths.
- Attach `XCTAttachment` screenshots/state artifacts and retain `.xcresult`, application logs and crash evidence. Treat runner timeout/missing assertions as a failure, not a clean empty run.

QA probes may expose read-only command outcomes, canonical state and readiness/event timestamps through the project's existing test interface. Gate them off in ordinary launches. Accessibility text alone rarely proves per-frame, economy or sequence invariants; state what remains unobserved.

## Maestro

Prefer when the app exposes usable accessibility selectors and the project already uses flows. Parameterize fixture/seed inputs and a pre-generated action manifest; keep pseudorandom generation reproducible outside the flow or pin/log its RNG. [Maestro flows](https://docs.maestro.dev/maestro-flows), [iOS support](https://docs.maestro.dev/get-started/supported-platform/ios).

Use launch arguments to enable QA-only fixtures if already supported; seed values are custom app inputs, not built-in replay guarantees. Assertions and screenshots must check the resulting app state, with bounded waits. Use the installed version's stop/background/relaunch commands; keep persistence during save-resume cases and clear state only between independent cases.

Maestro works through the accessibility tree. Custom canvas/game controls may need an in-game adapter instead; do not force coordinate-only flows to pretend they observe core invariants. [Maestro architecture](https://docs.maestro.dev/get-started/how-maestro-works).

## Platform limits and completion

Low Power Mode, true system interruptions, physical haptics and some device states may not be controllable in the chosen simulator/driver. Exercise app-specific equivalents if useful, label them emulated, and retain missing physical evidence. Reduce Motion must not prevent ready/completion signals. Do not modify the owner's system settings for test coverage.

After a fix run existing unit/integration checks and the full recorded UI corpus twice. Keep exported-build evidence separate from test-host runs. Required unsupported OS checks produce a scoped `blocked`/`incomplete` verdict. Simulator success alone does not establish device performance or App Store release readiness.
