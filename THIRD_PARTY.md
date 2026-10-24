# Third-party and source notices

Every vendored skill keeps its upstream license file in its own folder. Copies were taken on 2026-10-05 from these commits, unless the row says otherwise.

| Folder | Upstream | Commit | License |
| --- | --- | --- | --- |
| `skills/engineering/improve-codebase-architecture` | [mattpocock/skills](https://github.com/mattpocock/skills) | `4588b32` | MIT, © 2026 Matt Pocock |
| `skills/engineering/prototype` | [mattpocock/skills](https://github.com/mattpocock/skills) | `4588b32` | MIT, © 2026 Matt Pocock |
| `skills/engineering/retro` | [mattpocock/skills](https://github.com/mattpocock/skills) | `4588b32` | MIT, © 2026 Matt Pocock |
| `skills/engineering/grill-with-docs` | [mattpocock/skills](https://github.com/mattpocock/skills) (copied 2026-10-16; modified: model-invocable by default) | `49dd158` | MIT, © 2026 Matt Pocock |
| `skills/engineering/domain-modeling` | [mattpocock/skills](https://github.com/mattpocock/skills) (copied 2026-10-16) | `49dd158` | MIT, © 2026 Matt Pocock |
| `skills/engineering/research` | [mattpocock/skills](https://github.com/mattpocock/skills) (copied 2026-10-16) | `49dd158` | MIT, © 2026 Matt Pocock |
| `skills/productivity/grilling` | [mattpocock/skills](https://github.com/mattpocock/skills) (copied 2026-10-16) | `49dd158` | MIT, © 2026 Matt Pocock |
| `skills/productivity/handoff` | [mattpocock/skills](https://github.com/mattpocock/skills) (copied 2026-10-12; modified: verified absolute saved-path reporting) | `49dd158` | MIT, © 2026 Matt Pocock |
| `skills/productivity/writing-for-agents` | [mattpocock/skills](https://github.com/mattpocock/skills) | `4588b32` | MIT, © 2026 Matt Pocock |
| `skills/productivity/caveman` | [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) (`skills/caveman/`, copied 2026-10-22; modified: default reply-style discovery) | `bad48a0e1df55e05e3f52249afa35ecc1909ee76` | Apache-2.0; upstream LICENSE included |
| `skills/productivity/attention-kind` | [alexgreensh/attention-span](https://github.com/alexgreensh/attention-span) (`skills/attention-kind/`, v0.8, copied 2026-10-16; modified: model-invocable by default) | `f5b6e80` | AGPL-3.0, © 2026 alexgreensh |
| `skills/productivity/ponytail` | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) (copied 2026-10-12) | `9b58c1f` | MIT, © 2026 DietrichGebert |
| `skills/design/impeccable` | [pbakaus/impeccable](https://github.com/pbakaus/impeccable) (`plugin/skills/impeccable`, v4.5.2+, copied 2026-10-12) | `c63b8dd` | Apache-2.0, see `NOTICE.md` |
| `skills/design/diagram-design` | [cathrynlavery/diagram-design](https://github.com/cathrynlavery/diagram-design) (`skills/diagram-design/`, v2.6.74, copied 2026-10-12) | `7a2e221` | MIT, © 2025 Cathryn Lavery |
| `skills/design/gpt-image-2` | [agentspace-so/agent-skills](https://github.com/agentspace-so/agent-skills) (`gpt-image-2/`), modified: feature flag enabled only when off, saved-image fallback, model-agnostic triggers, thread-id-scoped session reads for parallel runs, image-tool result extraction, no silent prompt softening (refusal and quota exit codes), batch.py | `18d6100` | MIT, © 2026 agentspace-so |
| `skills/engineering/jk` | [avivsinai/jenkins-cli](https://github.com/avivsinai/jenkins-cli) (copied 2026-10-12) | `e854f07` | MIT, © 2025 Aviv Sinai and contributors |
| `skills/engineering/swiftui-pro` | [twostraws/SwiftUI-Agent-Skill](https://github.com/twostraws/SwiftUI-Agent-Skill) (`swiftui-pro/`, v2.0.0, copied 2026-10-09; Claude plugin wrapper `skills/` and `.claude-plugin/` left out) | `f980071` | MIT, © 2026 Paul Hudson |
| `skills/engineering/simless` | [abacusai/simless](https://github.com/abacusai/simless) (`Templates/SKILL.md`, v0.1.2, copied 2026-10-11), modified: default-testing policy (simulator only for the final pass) and one-time Mac setup in §0 | `676b089` | MIT-0, © 2026 Abacus.AI, Inc. (the CLI itself is Apache-2.0 and is not vendored) |

My own skills, copied from their home repositories:

| Folder | Upstream | Commit |
| --- | --- | --- |
| `skills/engineering/sdlc-kit` | [cskwork/sdlc-kit](https://github.com/cskwork/sdlc-kit) | synced daily by `sync-vendored.yml` |
| `skills/agents/call-agent` | [cskwork/call-agent](https://github.com/cskwork/call-agent) | synced daily by `sync-vendored.yml` |
| `skills/design/motion-graphics` | [cskwork/motion-graphics-skill](https://github.com/cskwork/motion-graphics-skill) | synced daily by `sync-vendored.yml` |
| `skills/engineering/db-intelligence` | [cskwork/pi-setup-public](https://github.com/cskwork/pi-setup-public) | `d678ccd` |
| `skills/engineering/sql-walkthrough` | [cskwork/sql-walkthrough](https://github.com/cskwork/sql-walkthrough) | `10ac9c7` |
| `system-prompt/AGENTS.md` | [cskwork/THE-SYSTEM-PROMPT](https://github.com/cskwork/THE-SYSTEM-PROMPT) | `b7a8645` |

`skills/engineering/verify-app` is written in this repository.

`skills/design/image-first-ui` is written in this repository. Its `scripts/gen.sh`, `scripts/extract_image.py`, and `scripts/batch.py` are copied from `skills/design/gpt-image-2` (MIT, © 2026 agentspace-so); see its `NOTICE.md`.

Upstream repositories stay the source of truth. To refresh a copy, re-copy the folder from the upstream's latest commit and update this table.
