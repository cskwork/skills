# Web adapter

Use the existing Playwright project, production build served locally, and isolated test data. Record commit/bundle hash, browser version, viewport/device scale, locale, service-worker/cache state, network fixtures and QA-hook differences. Keep each independent case in a fresh browser context; preserve its storage only within a save-resume flow.

## Driver and observations

- Use stable roles/test IDs for semantic actions. Snapshot visibility, enabled state, hit bounds and modal ownership before dispatch; correlate the resulting request/domain command and visible consequence.
- Playwright waits for actionability. That is useful for ordinary paths but can mask a transient disabled/covered control or change masher timing. Record actual dispatch times. Use explicitly timed pointer events for adversarial input; never globally `force` clicks to bypass an eligibility failure. [Actionability](https://playwright.dev/docs/actionability).
- Seed a dedicated persona PRNG and store generated actions/delays. Playwright scheduling does not automatically reproduce timing. Control network replies and app logical clocks only where the project supports it; preserve at least one real-clock UI path.
- Register console/page-error/crash and rejected-request listeners before navigation; inspect status codes and application error payloads too. Record intentional offline/abort expectations; do not ignore all failed requests.
- Subscribe to a QA-only read-only state/event probe if available for command IDs/results, entity ledger, readiness and persistence. Avoid calling mutations through `page.evaluate` for user-path tests.
- Check geometry in CSS pixels with device scale recorded: safe inset probes, scroll containers, hit targets, unwanted overlaps and overlay click interception. Sample animation via existing frame probes where required; after-step assertions alone cannot establish per-frame invariants.

## Persistence and boundaries

Save through UI → close page/context → reopen with explicitly restored test storage, IndexedDB/service-worker state where used → Continue → first valid action. Playwright `storageState` is not a full browser-disk snapshot; inspect the pinned version's IndexedDB support and account for sessionStorage/service workers separately. A reload is a separate warm-resume scenario. [Authentication/storage state](https://playwright.dev/docs/auth).

Run new-player, masher and bounded monkey exploration; deterministic prefixes ensure navigation reaches every required screen. Combine slow/timeout with fixture-controlled latency, speed changes where shipped, EN/KR and smallest/largest viewport. Emulate supported Reduce Motion with `reducedMotion: 'reduce'`; viewport/mobile emulation does not reproduce mobile OS backgrounding, real Low Power Mode, or the soft keyboard (keyboard-overlap checks need a mobile browser on a simulator or device, or stay a declared limit). With no project sizes, use 320 × 568 and 1440 × 900 CSS px. [Emulation](https://playwright.dev/docs/emulation).

Use actual tab/page lifecycle mechanisms for background paths where the driver supports them; invoking `visibilitychange` by hand exercises only a handler. Record browser-specific limits. Browser tests of a wrapped app do not establish native OS parity.

## Evidence and replay

Keep Playwright traces with screenshots/snapshots, action JSONL, console/network logs, seed/fixture manifest, first-failure state and canonical replay hashes. Set retries to zero for the oracle run, or treat any first-attempt failure as failed even if a diagnostic retry passes. A retry is evidence about reproducibility, never a clean pass. [Trace viewer](https://playwright.dev/docs/trace-viewer).

Replay the same action/timing/network manifest, minimize only while preserving the same failure, add a focused regression and a user-path check, then run the corpus twice on the final bundle. Report browser/lifecycle coverage and unobserved frame oracles explicitly.
