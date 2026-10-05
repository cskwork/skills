# verify — an agent skill that refuses to call a green build "verified"

[![Skill](https://img.shields.io/badge/Claude_Code-Skill-6b5bd6)](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

A green build proves the compiler was satisfied. It does not prove the endpoint accepts the real payload, that the query returns the right rows, or that the change did not break the caller.

`verify` closes that gap with **receipts**: files another person can re-run to reach the same verdict. No receipt, no pass.

> **한국어 소개:** https://cskwork.github.io/verify-skill/

## What it does

Five gates over your recent changes, in order. Each ends on an artifact written to disk.

| # | Gate | Question | Receipt |
|---|------|----------|---------|
| 1 | Build | Does the changed code assemble? | command, exit code, output tail |
| 2 | Static | Does it pass this repo's own type, lint, and schema checks? | per-tool exit code and finding counts |
| 3 | Clean code | Is this diff code you would approve? | one finding row per changed file |
| 4 | Scenario | Does each touched API behave live, across payload variants? | raw request and response per variant |
| 5 | Report | Would a colleague understand what you proved? | a one-page `report.md` |

Three verdicts, and the third is the point: **PASS**, **FAIL**, and **BLOCKED**. A gate that could not run reports `BLOCKED` and names the one thing that would unblock it. A skipped gate rendered as green is the failure this skill exists to prevent.

## Install

```sh
git clone https://github.com/cskwork/verify-skill ~/.claude/skills/verify
```

Then say `verify my recent work`, or `/verify`.

Works with any agent harness that reads `SKILL.md` — Claude Code, Codex, Cursor, Gemini CLI, OpenCode.

Needs `curl`, `jq`, and `bash`. Written for bash 3.2 so it runs on a stock macOS shell, and verified there. Not yet run on Linux — `scripts/selftest.sh` will tell you in about 20 seconds.

## Try it in 30 seconds

```sh
cd ~/.claude/skills/verify
scripts/selftest.sh
```

That runs all five gates against a throwaway server and then checks the harness itself: that the token cached, that a wrong expected status produces a `FAIL`, that a variant with no stated expectation does not pass, and that the credential never reached a receipt.

```
self-test: 22/22 checks passed
```

Those checks are not decoration. Writing them found three real defects in this harness: an unloaded adapter, a background process holding a pipe open, and a `sed` redaction rule that leaked the tail of an opaque token on BSD `sed`. Each is now a regression check.

## Point it at your stack

Gates are stack-agnostic. One adapter file holds the six facts they cannot guess.

```sh
cp adapters/_template.env /path/to/your/repo/.verify/adapter.env
$EDITOR /path/to/your/repo/.verify/adapter.env
```

| Fact | Key |
|------|-----|
| How to compile | `VERIFY_BUILD_CMD` |
| Which checks to run | `VERIFY_STATIC_CMDS` |
| How to start it | `VERIFY_RUN_CMD`, `VERIFY_BASE_URL` |
| How to know it is up | `VERIFY_HEALTH_PATH` |
| How to get a token | `VERIFY_TOKEN_MODE` and friends |
| How to make a test account | `VERIFY_ACCOUNT_HOWTO` |

[`adapters/_template.md`](adapters/_template.md) says where to find each one in a repository. [`adapters/spring-mybatis.md`](adapters/spring-mybatis.md) is a filled-in example, generalized from running this skill against a real Spring Boot 3 and MyBatis service — with the seven traps that produced a *wrong verdict* rather than an obvious error.

## The reusable token module

Protected endpoints need a credential, and getting one is where API verification usually stalls.

```sh
TOKEN=$(scripts/token.sh)        # cached when fresh, acquired when not
scripts/token.sh --header        # "Authorization: Bearer <token>"
scripts/token.sh --refresh       # force a new one, after a 401
scripts/token.sh --status        # cache state, acquires nothing
```

Five modes cover most stacks: `static`, `http_get`, `http_post_json`, `http_post_form`, and `command`. The last one is the escape hatch — a browser login script, an OAuth device flow, `aws sts`, a local signing script. Anything that prints a token.

It caches per identity, so a thirty-variant suite costs one login, and switching from an admin to a member does not silently reuse the admin's token. Credentials are redacted out of every receipt on the way to disk.

Details in [`references/token-module.md`](references/token-module.md).

## Payload variants

One call proves almost nothing. The floor is three per endpoint.

| Variant | Proves |
|---------|--------|
| `happy` | The documented contract holds for a real payload. |
| `boundary` | Empty, maximum, null, and unicode inputs behave. |
| `negative` | Bad input is refused with a 4xx, not a 500. |

Plus `regression` on a bug fix, and `authz` on a permission change.

Scenarios are JSON, so a suite re-runs in seconds:

```json
{
  "endpoint": "GET /api/items",
  "auth": "required",
  "variants": [
    {
      "name": "happy",
      "path": "/api/items",
      "query": { "limit": 3 },
      "expect": { "status": 200, "jq": [".data.total == 3"] },
      "source": "db-row"
    }
  ]
}
```

Payloads are sourced in order — user-supplied, saved fixture, a real database row, then synthesized — and the report says which rung it reached. A synthesized payload tests your imagination, not the contract, so the report must not blur that.

More in [`references/scenario-design.md`](references/scenario-design.md).

## The report

Gate 5 is the deliverable, and a correct verification described badly still leaves the reader guessing.

The style comes from [`wait-what`](https://github.com/mattpocock/skills/tree/main/skills/productivity/wait-what) by Matt Pocock: assume the reader lost the thread, give back the context they are missing, and say less. One idea per sentence, active voice, ASD-STE100 Simplified Technical English, and your project's own vocabulary from `CONTEXT.md`.

Verdict first. Then what you proved. Then — the most valuable section — what you did not.

```markdown
## What I did not verify
1. The admin view. I had no admin account that had any data.
```

Full rules in [`references/report-style.md`](references/report-style.md).

## Layout

```
SKILL.md                        five gates, three verdicts, red flags
references/
  report-style.md               wait-what report rules and template
  clean-code-gate.md            seven blocking findings, reading order
  scenario-design.md            variant matrix, payload sourcing, assertions
  token-module.md               token module reference
adapters/
  _template.env  _template.md   fill-in for your stack
  spring-mybatis.env / .md      worked example, Spring Boot + MyBatis
  selftest.env                  shortest complete adapter
scripts/
  lib.sh                        logging, redaction, verdicts
  token.sh                      the token module
  call.sh                       one recorded API call
  run-scenarios.sh              a scenario suite
  gate-build.sh  gate-static.sh gates 1 and 2
  selftest.sh                   proves the harness works
```

## Credits

- The report style adapts [`wait-what`](https://github.com/mattpocock/skills/tree/main/skills/productivity/wait-what), and the skill's own structure follows [`writing-great-skills`](https://github.com/mattpocock/skills/tree/main/skills/productivity/writing-great-skills) — both by [Matt Pocock](https://www.aihero.dev/skills-wait-what).
- Built for the [Agent Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) spec.

MIT. See [LICENSE](LICENSE).
