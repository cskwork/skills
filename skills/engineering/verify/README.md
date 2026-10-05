# verify (built into Claude Code)

I use Claude Code's bundled `/verify`. It builds and runs your app to confirm a code change does what it should, without falling back to tests or type checks.

- **Get it:** it ships with Claude Code v2.1.200 and later. Type `/verify` in a session. Nothing to install.
- **Docs:** [Run and verify your app](https://code.claude.com/docs/en/skills#run-and-verify-your-app)

## Codex and other agents

Codex has no built-in verify. Use [`verify-app`](../verify-app), which does the same job under a different name, so it never replaces Claude Code's `/verify`.

## Why this folder has no SKILL.md

- **It would replace the real one.** Claude Code lets a personal or project skill with the same name replace a bundled skill. A `verify/SKILL.md` installed from here would shadow the built-in `/verify`.
- **It is not mine to copy.** The bundled skill is part of Claude Code (© Anthropic PBC, all rights reserved), so this repo links to it instead of copying it.

## Teach it your project

`/verify` infers how to launch your app. For projects that need more (a database, an env file, a multi-step build), run `/run-skill-generator` once per project, or let `/verify` record its own recipe at `.claude/skills/verify/SKILL.md` in that repo. A recipe recorded at the repo root replaces the bundled `/verify` for that project only.
