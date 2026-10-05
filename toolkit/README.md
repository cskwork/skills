# Toolkit

The command-line tools I run alongside coding agents. Install commands are copied from each project's README; check upstream before running them.

| Tool | What it does | Install |
| --- | --- | --- |
| [claude-hud](https://github.com/jarrodwatts/claude-hud) | Claude Code status line: context usage, active tools, running agents, todos. | `claude plugin marketplace add jarrodwatts/claude-hud` then `claude plugin install claude-hud@claude-hud` |
| [blast-radius](https://github.com/cskwork/claude-code-mods/tree/main/blast-radius) | Claude Code mod that dry-runs risky Bash commands (recursive `rm`, destructive git, `kubectl delete`, SQL wipes) and asks Proceed or Cancel first. | `/plugin marketplace add cskwork/claude-code-mods` then `/plugin install blast-radius@claude-code-mods` |
| [claude-swap](https://github.com/realiti4/claude-swap) | Switch between Claude Code accounts, with rate-limit rotation and a usage dashboard. | `uv tool install claude-swap` |
| [codex-auth](https://github.com/Loongphy/codex-auth) | Switch and manage Codex CLI accounts. | `npm install -g @loongphy/codex-auth` |
| [firebase](https://github.com/firebase/firebase-tools) | Firebase command-line tools: deploy, emulators, project config. | `npm install -g firebase-tools` |
| [gws](https://github.com/googleworkspace/cli) | Google Workspace CLI for Drive, Gmail, Calendar, Sheets, Docs, Chat, Admin. | `brew install googleworkspace-cli` or `npm install -g @googleworkspace/cli` |
| [herdr](https://github.com/herdrdev/herdr) | Terminal workspace manager and runtime for coding agents. | `curl -fsSL https://herdr.dev/install.sh \| sh` |
| [hermes](https://github.com/NousResearch/hermes-agent) | Nous Research's self-improving agent with skills, memory, and a gateway. | `curl -fsSL https://hermes-agent.nousresearch.com/install.sh \| bash` |
| [jk](https://github.com/avivsinai/jenkins-cli) | GitHub-style CLI for Jenkins: contexts, runs, logs, admin. Pairs with the [`jk` skill](../skills/engineering/jk). | `brew install avivsinai/tap/jk` |
