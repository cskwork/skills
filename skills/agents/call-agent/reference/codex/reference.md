# codex-call — Reference

Verified against `codex --help` v0.133.0 and `codex exec --help`.

## `codex exec` — relevant flags

| Flag | Notes |
|---|---|
| `-c key=value` | Override config (`-c model="gpt-5.5"`) |
| `-m, --model NAME` | Model override (default `gpt-5.5`, 1M ctx) |
| `-s, --sandbox` | `read-only` \| `workspace-write` \| `danger-full-access` (host auto mode denies launching it; see call.md "Sandbox for delegated work") |
| `--dangerously-bypass-approvals-and-sandbox` | Unattended runs (no approval prompts) |
| `--dangerously-bypass-hook-trust` | Skip hook trust prompts |
| `-C, --cd DIR` | Working root |
| `--add-dir DIR` | Extra writable dir |
| `-c sandbox_workspace_write.network_access=true` | Network inside `workspace-write` (verified 0.161.0) |
| `--skip-git-repo-check` | Run outside a git repo |
| `-o, --output-last-message FILE` | Persist only the final message |
| `--json` | JSONL event stream on stdout |
| `--output-schema FILE` | JSON Schema constrains final response |
| `--ephemeral` | No session rollout written |
| `-i, --image FILE` | Attach image input (vision) |

**stdin:** if stdin is piped, `codex exec` appends it to the prompt as a
`<stdin>` block and blocks until EOF (`Reading additional input from stdin...`).
Pass `</dev/null` unless you mean to pipe input. In zsh, a pipe plus
`</dev/null` merges both inputs (MULTIOS), so it still blocks. Verified on
codex-cli 0.160.1.

## `codex review`

```
codex review [PROMPT] [SCOPE] [OPTS]
```

Scope (mutually exclusive):

| Flag | Purpose |
|---|---|
| `--uncommitted` | staged + unstaged + untracked |
| `--base BRANCH` | diff vs branch |
| `--commit SHA` | one commit |
| `--title TITLE` | label for the review |

No `--json` flag here — output is markdown (printed to stdout; no `-o`).

**codex 0.135.0:** a scope flag (`--uncommitted`/`--base`/`--commit`) and a
free-text `[PROMPT]` are MUTUALLY EXCLUSIVE — passing both errors with
`the argument '--<scope>' cannot be used with '[PROMPT]'`. A bare prompt
reviews the uncommitted diff by default. `scripts/codex-review.sh` enforces
this (pass one or the other).

## Image generation (built-in)

- Tool name surfaced to the agent: `image_gen`
- Skill spec: `~/.codex/skills/.system/imagegen/SKILL.md`
- Default sink: `~/.codex/generated_images/<uuid>/ig_*.png`
- Agent moves/copies to the user-named save path per skill save-path
  policy
- Auth: `~/.codex/auth.json` (ChatGPT OAuth); no `OPENAI_API_KEY` needed

## Image generation (Path B helper)

- Script: `~/.codex/skills/.system/imagegen/scripts/image_gen.py`
- Subcommands: `generate`, `edit`, `generate-batch` (`--concurrency N`)
- Models: `gpt-image-2` (highest quality, no transparency),
  `gpt-image-1.5 --background transparent` (true alpha)
- `--dry-run` to skip API call (cost-free CI)
- Sister script: `remove_chroma_key.py` for chroma-key cleanup

## Auth detection

```bash
test -f "$HOME/.codex/auth.json" && note "ChatGPT auth ok"
[ -n "${OPENAI_API_KEY:-}" ]    && note "API key set (Path B available)"
```

## Subcommands NOT used

`login`, `logout`, `mcp`, `plugin`, `mcp-server`, `app`, `completion`,
`update`, `app-server`, `remote-control`. User-side or
infrastructure-level concerns; never scripted from this skill.
