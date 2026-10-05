# notebooklm-call — Reference

Verified against notebooklm-py 0.5.0 (PyPI, 2026-05).

## Install

```bash
python3 --version          # need ≥ 3.10 (3.13+ ok, but skip [cookies] extra)
pip install "notebooklm-py[browser]"
playwright install chromium    # ~170 MB, 30-90s, no progress bar
notebooklm login               # one-time, opens browser for Google sign-in
notebooklm auth check --test --json
```

## CLI verb set

`login, auth, list, create, use, delete, source, ask, generate, download,
history, artifact, research, share, profile, language, skill, agent,
metadata, status, doctor`

## Env vars

| Var | Purpose |
|---|---|
| `NOTEBOOKLM_HOME` | Override state root (default `~/.notebooklm`) |
| `NOTEBOOKLM_PROFILE` | Pick profile (default `default`) |
| `NOTEBOOKLM_AUTH_JSON` | Inline auth JSON (CI / non-disk usage) |

## State files

Path differs by CLI version:

| Version | Storage path |
|---|---|
| **0.3.x** | `~/.notebooklm/storage_state.json` (no `profiles/` dir) |
| **0.5.x+** | `~/.notebooklm/profiles/<profile>/storage_state.json` |

Other files (both versions): `context.json` (active notebook — do NOT
trust in parallel agents), `browser_profile/` (Playwright user data dir
for the persistent Chromium login session).

## Auth detection (the right way)

`notebooklm auth check --json` can return `status:ok` while the cookie
session is silently broken. Always also check `checks.token_fetch:true`:

```bash
notebooklm auth check --test --json | \
  python3 -c '
import sys, json
d = json.load(sys.stdin)
ok = d.get("status") == "ok" and d.get("checks", {}).get("token_fetch") is True
sys.exit(0 if ok else 2)'
```

## Concurrency rules

- Always pass `--notebook <ID>` explicitly.
- For parallel agents on the same profile, also isolate `NOTEBOOKLM_HOME`
  per agent.
- Cookie keepalive runs every ~600s in-process; `notebooklm auth refresh`
  is cron-friendly for unattended hosts.

## What this skill does NOT do

- Programmatic browser login automation — `notebooklm login` is a manual
  one-time step.
- Direct `httpx` calls to Google endpoints — let the library handle the
  wire format; it changes often.
- Sharing public notebook links — sensitive op; user-driven only.

## Rate limits

Undocumented Google-side throttling. The skill caller is responsible for
backoff; the library does not retry on quota errors.

## Known caveats

- Python 3.13+: do NOT install the `[cookies]` extra (`rookiepy` fails
  to build).
- `notebooklm use` is per-profile state — unsafe in parallel.
- The library is Beta; minor version bumps can change CLI output shape.
- Audio overview generation is slow (~minutes); use long timeouts.

## License & legal posture

MIT-licensed library; uses YOUR Google account session. Not affiliated
with Google. Treat as personal-use tooling.
