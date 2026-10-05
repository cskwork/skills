# cskwork/skills

The agent skills, system prompt, and CLI toolkit I use every day with Claude Code, Codex, and other coding agents.

**Landing page:** https://cskwork.github.io/skills/ · 한국어 요약은 [아래](#한국어-요약)에 있습니다.

## Install

Pick the skills you want, and which agents to install them on:

```bash
npx skills@latest add cskwork/skills
```

List them without installing:

```bash
npx skills@latest add cskwork/skills --list
```

Install the system prompt (back up your existing `~/.agents/AGENTS.md` first):

```bash
mkdir -p ~/.agents ~/.claude ~/.codex
curl -fsSL https://raw.githubusercontent.com/cskwork/skills/main/system-prompt/AGENTS.md -o ~/.agents/AGENTS.md
ln -sfn ~/.agents/AGENTS.md ~/.claude/CLAUDE.md
ln -sfn ~/.agents/AGENTS.md ~/.codex/AGENTS.md
```

## System prompt

[`system-prompt/AGENTS.md`](system-prompt/AGENTS.md) is the operating contract I give every coding agent: agree on outcome and scope, ground decisions in evidence, verify, and report plainly. Source of truth: [cskwork/THE-SYSTEM-PROMPT](https://github.com/cskwork/THE-SYSTEM-PROMPT).

## Skills

### Engineering

| Skill | What it does | Source |
| --- | --- | --- |
| [sdlc-kit](skills/engineering/sdlc-kit) | Gated SDLC loop (intent → spec → plan → build → ship → maintain) with human approvals. | [cskwork/sdlc-kit](https://github.com/cskwork/sdlc-kit) |
| [db-intelligence](skills/engineering/db-intelligence) | One skill for PostgreSQL, MySQL, SQLite, and MongoDB: detect the engine, connect credential-safe, read schema, read before writing, never write to prod. | [cskwork/pi-setup-public](https://github.com/cskwork/pi-setup-public) |
| [improve-codebase-architecture](skills/engineering/improve-codebase-architecture) | Find deepening opportunities, show them as an HTML report, then grill through the one you pick. | [mattpocock/skills](https://github.com/mattpocock/skills) |
| [prototype](skills/engineering/prototype) | Build a throwaway prototype to answer a design question. | [mattpocock/skills](https://github.com/mattpocock/skills) |
| [retro](skills/engineering/retro) | Run a retrospective on a coding session. | [mattpocock/skills](https://github.com/mattpocock/skills) |
| [jk](skills/engineering/jk) | Drive Jenkins from the terminal with the `jk` CLI: jobs, runs, logs, artifacts, credentials. | [avivsinai/jenkins-cli](https://github.com/avivsinai/jenkins-cli) |

### Productivity

| Skill | What it does | Source |
| --- | --- | --- |
| [wait-what](skills/productivity/wait-what) | "That last message did not land: re-pitch it." | [mattpocock/skills](https://github.com/mattpocock/skills) |
| [handoff](skills/productivity/handoff) | Compact the conversation into a handoff document for another agent. | [mattpocock/skills](https://github.com/mattpocock/skills) |
| [writing-for-agents](skills/productivity/writing-for-agents) | How to write skills, AGENTS.md, and CLAUDE.md for agents. | [mattpocock/skills](https://github.com/mattpocock/skills) |
| [ponytail](skills/productivity/ponytail) | Lazy-senior-dev mode: the simplest, shortest solution that actually works. | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) |

### Design

| Skill | What it does | Source |
| --- | --- | --- |
| [impeccable](skills/design/impeccable) | Design, critique, audit, and polish frontend interfaces. | [pbakaus/impeccable](https://github.com/pbakaus/impeccable) |
| [archify](skills/design/archify) | Architecture, sequence, data-flow, and state diagrams as explorable standalone HTML. | [tt-a1i/archify](https://github.com/tt-a1i/archify) |

### Agents

| Skill | What it does | Source |
| --- | --- | --- |
| [call-agent](skills/agents/call-agent) | Delegate a bounded task to a peer CLI: Codex, Claude, Antigravity, Kiro, NotebookLM, ChatGPT Pro. | [cskwork/call-agent](https://github.com/cskwork/call-agent) |

### Installed from their own home

These skills ship with a tool or a machine setup, so get them from their own home instead of copying them here.

| Skill | What it does | Install |
| --- | --- | --- |
| [verify](skills/engineering/verify) | Claude Code's own `/verify`: builds and runs your app to confirm a change does what it should. | Comes with Claude Code (v2.1.200+). Type `/verify`. |
| ego-browser | Browser for agents that shares your logged-in sessions ([ego-lite](https://github.com/citrolabs/ego-lite)). | Install the ego lite app, or `npx skills add citrolabs/ego-lite` |
| hindsight | Shared long-term memory for Claude Code, Codex, and Hermes ([hindsight-agent-setup](https://github.com/cskwork/hindsight-agent-setup)). | `curl -fsSL https://raw.githubusercontent.com/cskwork/hindsight-agent-setup/main/bootstrap.sh \| bash` |

## Toolkit

The CLIs around the agents: account switching, status line, Google Workspace, Firebase, Jenkins, and agent runtimes. See [`toolkit/README.md`](toolkit/README.md).

## Licenses

My own files are MIT ([LICENSE](LICENSE)). Vendored skills keep their own license file in their folder; see [THIRD_PARTY.md](THIRD_PARTY.md) for sources and the exact commits copied.

## 한국어 요약

매일 쓰는 에이전트 스킬, 시스템 프롬프트(AGENTS.md), CLI 도구 모음입니다. `npx skills@latest add cskwork/skills`로 원하는 스킬만 골라 설치합니다. 다른 사람이 만든 스킬은 원본 라이선스와 출처를 그대로 유지합니다.
