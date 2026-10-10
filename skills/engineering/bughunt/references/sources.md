# Sources and design rationale

Reviewed 2026-10-09. Primary documentation and practitioner research informed the techniques below. Pin each target's tool version; a current documentation page does not prove support in an older installed binary. This skill provides an execution method, not a shipped harness.

## Seeded exploration, invariants, replay

- [Android Developers: UI/Application Exerciser Monkey](https://developer.android.com/studio/test/other-testing-tools/monkey): pseudorandom event stress and repeatable seeds. Adopt the method across platforms; Android Monkey itself is not an iOS/Godot runner.
- [Hypothesis: stateful tests](https://hypothesis.readthedocs.io/en/latest/stateful.html): sequences of state-dependent actions, preconditions and invariants after steps; shrinking turns long sequences into small reproductions. Use the existing framework or these ideas; adding Hypothesis is optional.
- [Hypothesis: replaying failures](https://hypothesis.readthedocs.io/en/latest/tutorial/replaying-failures.html): retain concrete failing inputs as durable regression examples. Seeds are useful exploration metadata, not a substitute for the exact failure stream and tool identity.
- [EA SEED: technical challenges deploying RL agents for game testing, CoG 2023](https://www.ea.com/seed/news/cog23-challenges-deploying-rl-agents-game-testing): learned exploration can augment scripted bots but introduces integration/coverage challenges. Start with bounded scripted personas; no ML service/training is required here.
- [Glenn Fiedler: Deterministic Lockstep](https://gafferongames.com/post/deterministic_lockstep/): deterministic simulation requires equal starting conditions and inputs, with floating-point/platform caveats. Record logical timing and canonical state; do not promise universal cross-platform determinism.

## Godot

- [Stable command-line tutorial](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html): headless/export modes, editor vs export-template flag availability, custom arguments after `--`.
- [Input API](https://docs.godotengine.org/en/stable/classes/class_input.html): synthetic input via `parse_input_event`; action state and GUI input are different observation paths.
- [OS API](https://docs.godotengine.org/en/stable/classes/class_os.html): `get_cmdline_user_args()` for QA-specific flags.
- [gdUnit4 command-line documentation](https://github.com/godot-gdunit-labs/gdUnit4/blob/master/documentation/doc/_advanced_testing/cmd.md): project test-suite CLI; use the target's pinned version.
- [GUT command-line documentation](https://gut.readthedocs.io/en/latest/Command-Line.html): runner/config/result export; pending tests do not affect exit status, so coverage must be counted separately.

## Native iOS and web

- [Apple: XCUIApplication](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication): lifecycle control and launch configuration. [activate](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/activate()) foregrounds an existing instance, unlike a cold relaunch.
- [Apple: buttons](https://developer.apple.com/design/human-interface-guidelines/buttons), [accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility): physical point-based touch/accessibility guidance. [WCAG 2.2 target-size minimum](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html): CSS-pixel baseline and exceptions for web. Bind the correct platform units.
- [Maestro: iOS](https://docs.maestro.dev/get-started/supported-platform/ios), [flows](https://docs.maestro.dev/maestro-flows), [how it works](https://docs.maestro.dev/get-started/how-maestro-works): UI flows and accessibility-tree observation; canvas controls need other hooks.
- [Playwright: actionability](https://playwright.dev/docs/actionability): built-in waiting checks can change adversarial input timing.
- [Playwright: traces](https://playwright.dev/docs/trace-viewer): action timeline, screenshots and snapshots for failure evidence.
- [Playwright: authentication/storage](https://playwright.dev/docs/auth), [emulation](https://playwright.dev/docs/emulation): isolated contexts, persistence fixtures and emulated viewport/locale/motion; these do not establish native OS parity.

## App profiles

Reviewed 2026-10-10.

- [Playwright: mock APIs](https://playwright.dev/docs/mock): route and HAR replay for the `crud-app` and `ai-chat` network fixtures and model stub.
- [Stripe: idempotent requests](https://docs.stripe.com/api/idempotent_requests): the request-ID pattern behind "one Save, one mutation" in `crud-app` O-2.
- [MDN: KeyboardEvent.isComposing](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/isComposing): Enter during IME composition, the Korean half-composed submit case.
- [OWASP: improper output handling (LLM05)](https://genai.owasp.org/llmrisk/llm052025-improper-output-handling/), [XSS prevention cheat sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html): model output as untrusted input, `ai-chat` O-9.
- [WebRTC: testing](https://webrtc.org/getting-started/testing): Chromium fake media devices and `--use-file-for-fake-audio-capture` for `media` fixtures.
- [Apple: handling audio interruptions](https://developer.apple.com/documentation/avfaudio/handling-audio-interruptions): the interruption and resume contract behind `media` O-10.
