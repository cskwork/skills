# kiro-call — Reference

Verified against `kiro-cli --help-all` v0.x and `kiro-cli chat --help`.

## Two distinct kiro binaries

| Path | Role |
|---|---|
| `/usr/local/bin/kiro` | Kiro **IDE** launcher (`Kiro 0.12.x`). GUI only. Not used by this skill. |
| `~/.local/bin/kiro-cli` → `/Applications/Kiro CLI.app/...` | Kiro **CLI** — the headless agentic terminal. This skill targets only this. |

## Top-level subcommands (used)

| Subcommand | Purpose |
|---|---|
| `chat` | AI assistant in terminal (headline) |
| `agent` | Manage agent profiles |
| `mcp` | Add/list/remove MCP servers |
| `translate` | NL → shell command |
| `whoami` / `profile` | Auth/account |
| `doctor` | Diagnostics |
| `inline` | Shell completion engine |

Subcommands NOT used by this skill: `debug`, `settings`, `setup`,
`update`, `dashboard`, `integrations`, `login`, `logout`, `launch`,
`quit`, `restart`, `acp`, `issue`, `theme`.

## `kiro-cli chat` flags

| Flag | Purpose |
|---|---|
| `[INPUT]` | First question (positional) |
| `--no-interactive` | Print final response and exit |
| `-a, --trust-all-tools` | Auto-approve every tool call |
| `--trust-tools <names>` | Trust only listed tools (comma-separated). Empty = trust none. |
| `--agent <NAME>` | Use a named agent profile |
| `--model <NAME>` | Override model |
| `-r, --resume` | Resume most recent conversation in CWD |
| `--resume-id <ID>` | Resume specific session |
| `--resume-picker` | Interactive picker |
| `-l, --list-sessions` | List saved sessions |
| `--list-models` | List available models |
| `-f, --format plain\|json\|json-pretty` | Output format for list cmds |
| `-d, --delete-session <ID>` | Delete a session |
| `-w, --wrap always\|never\|auto` | Line wrap behavior |
| `--require-mcp-startup` | Fail if MCP servers can't start (exit 3) |
| `--tui` | New TUI mode |
| `--legacy-ui` / `--classic` | Legacy harness |

## Agent profiles

Configs live in `~/.kiro/agents/<name>.json`. Schema (from upstream
`agent_config.json.example`):

```json
{
  "name": "example",
  "description": "...",
  "prompt": null,
  "mcpServers": {},
  "tools": ["read","write","shell","aws","report","introspect",
            "knowledge","thinking","todo","delegate","grep","glob"],
  "toolAliases": {},
  "allowedTools": [],
  "resources": [],
  "hooks": {},
  "toolsSettings": {},
  "includeMcpJson": true,
  "model": null
}
```

`agent_config.json.example` (with `.example` extension) is NOT loaded;
rename to `<name>.json` to activate.

## State paths

| Path | Contents |
|---|---|
| `~/.kiro/sessions/cli/{id}.json` | Session metadata |
| `~/.kiro/sessions/cli/{id}.jsonl` | Turn-by-turn transcript |
| `~/.kiro/sessions/cli/{id}.lock` | Active-session lock |
| `~/.kiro/agents/` | Agent profile JSONs |
| `~/.kiro/skills/` | Kiro-side skills (user can install ours here) |
| `~/.kiro/steering/` | Steering files (system prompts) |
| `~/.kiro/powers/registries/` | Power (tool) registries |
| `~/.kiro/settings/` | UI / model defaults |
| `~/.kiro/.cli_bash_history` | REPL history (readline) |

## `kiro-cli mcp`

| Verb | Use |
|---|---|
| `mcp list` | List configured MCP servers |
| `mcp add <name> --command <cmd> --args "<arg1> <arg2>"` | Add server |
| `mcp remove <name>` | Remove server |
| `mcp import <file>` | Bulk import from JSON |

Bridge from Claude Code: read `~/.claude.json` (or per-project
`.claude/settings.json`) `mcpServers` keys and re-emit via `mcp add`.

## `kiro-cli translate`

```bash
kiro-cli translate "<natural-language request>"
```

Returns the proposed shell command for the user to review/run.

## Auth

| Command | Effect |
|---|---|
| `kiro-cli login` | Browser OAuth |
| `kiro-cli whoami` | Show current identity |
| `kiro-cli logout` | Clear creds |
| `kiro-cli profile` | Show idc user profile |

## Exit codes

`0` ok, `3` MCP startup failure (when `--require-mcp-startup`), nonzero
otherwise on error.

## Why this skill does NOT use `kiro chat` (the IDE)

`/usr/local/bin/kiro chat <prompt>` opens the **IDE chat panel**. It
takes a `-m` MODE flag (ask/edit/agent), not a message, and has no
stdout. The user's pre-existing `~/.kiro/skills/kiro-review/SKILL.md`
mistakenly uses `kiro chat -m "<message>"` — that interprets the
message as the mode value and fails silently. This skill targets
`kiro-cli chat ...` to avoid that pitfall.
