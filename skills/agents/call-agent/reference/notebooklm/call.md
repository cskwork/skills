# call-agent -> notebooklm (Google NotebookLM)

Loaded by the `call-agent` router when delegating to `notebooklm`. Wrap the
`notebooklm` CLI (https://github.com/teng-lin/notebooklm-py) for document
RAG, audio/video overviews, mind maps, and research over a user-defined
corpus.

> ⚠️ **Unofficial library.** notebooklm-py uses undocumented Google APIs
> and your own browser session cookies. Endpoints can change without
> notice and heavy usage MAY get a Google account flagged. Do not use
> for production-critical pipelines.

## When to route here

1. **Explicit name** — user says "notebooklm" or "nblm".
2. **Feature gap** — user asks for RAG / audio-overview / video-overview
   / mind-map over a document collection. No host CLI does this natively.

Do NOT fire for: general Q&A, code analysis, or web research that does
not involve a curated document corpus.

## Preflight — run this FIRST every session

```bash
./scripts/notebooklm-preflight.sh
```

It checks:
- `notebooklm` is on PATH
- Python ≥ 3.10
- `playwright` chromium installed
- Auth cookies valid via `notebooklm auth check --test --json` (parsing
  BOTH `status:ok` AND `checks.token_fetch:true` — bare `--json` is a
  known false-positive trap)

If auth is missing, surface this verbatim:

> Run once: `notebooklm login` (opens Chromium for Google sign-in)

## Concurrency-safe call pattern

`notebooklm use <id>` mutates a per-profile active-notebook context file.
**Never** rely on it in scripted multi-agent runs. Always pass the
notebook ID explicitly with `-n` / `--notebook`:

```bash
notebooklm ask -n "$NB_ID" "<QUESTION>"                      # 0.3.x and 0.5.x
notebooklm generate audio -n "$NB_ID" --out audio.mp3
notebooklm download audio -n "$NB_ID" --out a.mp3
```

Partial IDs are accepted: `notebooklm delete -n abc -y` matches `abc123...`.

For truly parallel agents, also isolate state:

```bash
NOTEBOOKLM_HOME=/tmp/nblm-agent-A notebooklm ask --notebook "$NB_ID" "Q1" &
NOTEBOOKLM_HOME=/tmp/nblm-agent-B notebooklm ask --notebook "$NB_ID" "Q2" &
wait
```

## Common operations

| Need | Command (0.3.x; 0.5.x adds richer flags) |
|---|---|
| Create notebook | `notebooklm create "<TITLE>" --json` (→ `{"notebook":{"id":...}}`) |
| List | `notebooklm list` |
| Add a source | `notebooklm source add -n <ID> <PATH-or-URL>` |
| Ask | `notebooklm ask -n <ID> "<Q>"` (add `--json` for citations, `--save-as-note` for persistence) |
| Audio overview | `notebooklm generate audio -n <ID> --out a.mp3` |
| Mind map | `notebooklm generate mind-map -n <ID> --out map.json` |
| Delete | `notebooklm delete -n <ID> -y` |

## Output

The CLI prints either plain text (for `ask`) or a path/ID (for
`generate`, `source add`, `create`). Use `--json` on commands that
support it for parseable output, and verify the file exists after any
`download` or `generate --out`.

## See also

- [`reference.md`](reference.md) — all verbs, env vars, gotchas
- [`scripts/notebooklm-preflight.sh`](scripts/notebooklm-preflight.sh)
- Upstream docs: https://github.com/teng-lin/notebooklm-py
