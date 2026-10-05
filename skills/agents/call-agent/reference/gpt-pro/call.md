# call-agent -> gpt-pro (ChatGPT Pro deep reasoning)

Loaded by the `call-agent` router when delegating to **ChatGPT Pro** - the
deep-reasoning "Pro" tier - for a heavy second opinion the host (or a codex
subscription) cannot match cheaply. The Pro model is effectively web-only
(its API tier is priced at ~$30/$180 per 1M tokens), so this target's job is to
get a high-signal **context bundle** in front of ChatGPT Pro using the user's
existing flat-fee subscription.

Unlike other targets there is **no `gpt-pro` CLI**. The reliable path packages a
sanitized bundle and hands off to the human (paste + upload + read back). An
optional, experimental live path drives a logged-in browser tab.

## When to route here

1. **Explicit name** - user says "gpt-pro", "gpt pro", "chatgpt pro", "gpt5 pro",
   "o-series pro", or "ask ChatGPT Pro / get a second opinion from GPT".
2. **Capability gap** - user wants a slow, maximal-reasoning review/answer the
   host model cannot give, and wants to spend their ChatGPT Pro subscription
   rather than API credits.

Do NOT route here for routine review/plan/refactor - the host is presumed capable.

## Preflight

```bash
./scripts/gpt-pro-preflight.sh
```

Checks `tar` (+ `pbcopy`) for the bundle path and notes optional live-drive deps.
It cannot verify the ChatGPT Pro subscription - that is the user's to have.

## Primary path - context bundle (reliable)

```bash
./scripts/gpt-pro-bundle.sh "<QUESTION>" --files <paths/globs> [--role "<persona>"]
```

Run it from the project root so the git file-tree/log get included. It:

- collects `--files` under `source/` (preserving structure) + a repo tree/log,
- **fail-fast secret scan** - refuses to package if it finds keys/tokens/passwords
  (override with `--allow-secrets`; see below),
- writes `PROMPT.md` (Role + Context + Question + What-to-examine + Output format),
- emits `PASTE_THIS.txt` for small bundles (single paste, no upload),
- tars the dir and copies the prompt to the clipboard.

Output goes to `${GPT_PRO_OUT:-~/Documents/GPT Pro Analysis}/<date>-<slug>/`
(override per call with `--out <dir>`).

Then the **human handoff** (report these steps back verbatim):
1. Open https://chatgpt.com/ and pick the Pro / deep-reasoning model.
2. Cmd+V (prompt is already on the clipboard).
3. Upload the printed `*.tar.gz` (or paste `PASTE_THIS.txt` instead).
4. Send; paste Pro's answer back into the host so it can act on it.

## Sanitization

The scan blocks private keys, `sk-`/`ghp_`/`gho_` tokens, `AKIA…`, Slack `xox…`,
bearer tokens, and `api_key=/secret=/password=` assignments. On a hit it prints
`file:line`, deletes the half-built bundle, and exits 2 - nothing leaves disk.
Exclude the offending files or pass `--allow-secrets` only when you are certain.

## Experimental - live browser drive (best-effort, fail-loud)

```bash
# Build the bundle first, then upload it as a FILE and type a one-line instruction:
./scripts/gpt-pro-live.sh "<ONE-LINE INSTRUCTION>" --attach <bundle>/PASTE_THIS.txt
```

Drives an already-logged-in ChatGPT tab via `playwright-cli`: it **uploads the
bundle as a file** (keystroke entry of a large prompt truncates and is slow) and
types only a short single-line instruction, then captures the reply. It is gated
by real, verified constraints and fails loudly (exit 2, bundle fallback) rather
than faking success:

- Chrome **136+** blocks `--remote-debugging-port` on the **default profile**, so
  the live path uses the **Playwright extension relay**: install the Playwright
  extension from the Chrome Web Store and enable
  `chrome://inspect/#remote-debugging` -> "Allow remote debugging for this
  browser instance".
- You must already be signed into ChatGPT Pro in that browser.
- ChatGPT is a heavy SPA; the composer/upload/response selectors can drift, and
  **attachment binding is itself flaky to automate** - if the upload does not
  register, the script stops (it will not submit a fileless, useless prompt).
  For file-heavy reviews the reliable route is the bundle + attaching by hand.

## How results come back

- **Bundle**: the human pastes Pro's answer back; the host treats that as the
  peer output (no automated capture).
- **Live**: the assistant's final message is printed to stdout (verify fidelity -
  markdown/code can be lossy).

## See also

- [`scripts/gpt-pro-bundle.sh`](scripts/gpt-pro-bundle.sh) - the reliable path
- [`scripts/gpt-pro-preflight.sh`](scripts/gpt-pro-preflight.sh)
- [`scripts/gpt-pro-live.sh`](scripts/gpt-pro-live.sh) - experimental live drive
