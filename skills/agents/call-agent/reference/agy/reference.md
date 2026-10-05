# agy-call — Reference

Verified against `agy --help` v1.0.2.

## Flags used

| Flag | Purpose | Notes |
|---|---|---|
| `-p`, `--print`, `--prompt` | Single non-interactive prompt | Always set |
| `--print-timeout DUR` | Wait limit for `-p` | Default 5m. Use `3m0s` / `5m0s` / `10m0s` |
| `--dangerously-skip-permissions` | Auto-approve tool calls | Required for image-gen file writes |
| `--add-dir PATH` | Workspace dir (repeatable) | Use for cross-repo context |
| `-c`, `--continue` | Resume most recent conversation | Pair with `-p` |
| `--conversation ID` | Resume specific conversation | |
| `--sandbox` | Terminal-restricted sandbox | Defensive; rarely needed |
| `--log-file PATH` | Override CLI log path | For debugging |

## Output shape

- Plain stdout text (no JSON mode).
- No structured artifact dir — image gen writes wherever the prompt
  instructs.
- Errors go to stderr; combine with `2>&1` if capturing.

## Subcommands (not used by this skill)

`install`, `update`, `plugin`, `changelog`, `help`. The skill never
shells into these — leave config to the user.

## Auth

Handled by `agy install` and Google sign-in. No env vars needed in
prompts. If `agy -p "ping"` fails with an auth error, surface the message
verbatim and tell the user to run `agy install` and re-authenticate.

## Cost / model

`agy` uses Gemini under the hood; pricing/quota is on the user's Google
account. There is no model-selection flag at the CLI level for v1.0.x.

## Capabilities NOT used by this skill

Per design, the following reference-repo triggers are excluded:

- Deep multi-file codebase analysis (Claude Code does this)
- Long-running refactors that exhaust context (Claude Code compaction
  handles this)
- Many-sequential-tool-call workflows (Claude Code does this)
