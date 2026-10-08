# Bughunt failure: <ID / short symptom>

Verdict: failed | incomplete | blocked
Oracle: <O-ID, contract source>
Expected: <condition/value before the action>
Actual: <value, code, first divergent tick/frame>

## Identity and replay

- Target: <repo commit, dirty diff, artifact hash/build, rules/content version>
- Harness: <policy/oracle version, tools, command, flags, exit code>
- Environment: <platform/OS/device/browser, size/scale/safe area, locale, speed, motion/power>
- Fixture/reset: <owned storage/account, fixture hash, game and policy RNG algorithm/state>
- Seeds: <game seed, policy seed, explicit corpus file>
- Phase: <phase ID, actor, controller seq, screen readiness>
- Action: <input/target eligibility, command ID/payload, expected result, actual result>
- Timing: <logical tick, wall timestamps, delays, network/lifecycle inputs>
- Replay: <exact permitted command + action manifest, frequency reproduced>

## Evidence bundle

| Artifact | Path / hash / availability |
|---|---|
| Manifest and explicit seed list | <path> |
| Original actions/events JSONL | <path; flushed at failure> |
| Screenshot / transition frames | <path or unavailable: headless> |
| Pre/post state and serialized save | <paths; owned test data only> |
| Runtime, supervisor, crash logs / trace | <paths> |
| Canonical replay hashes | <path; first mismatch> |
| Minimal action stream | <path or not minimized; reason> |

## Cause and correction

Who/when/where: <reporter, observation time, build/environment; unknown if not recorded>
Root cause: <verified code/data chain and source lines/commit; unknown if not proven>
As-is → to-be: <relevant code, line explanation, observed row/state substitution, counterexample>
Regression: <existing runner/test, pre-fix failure, post-fix result; not run if deferred>
Fix: <scope and commit or protected boundary>
Full replay: <matrix cells/pass counts, commands/exit codes; incomplete cells>
Remaining: <unresolved failures, unsupported/unobserved oracles, platform parity>
Cleanup/checkpoint: <owned processes/artifacts/bytes, next case if incomplete>
