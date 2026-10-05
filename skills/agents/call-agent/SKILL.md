---
name: call-agent
description: Delegate a bounded task to a user-named peer CLI, or to fill a capability the host lacks. Supports Codex, Claude, Antigravity, Kiro, NotebookLM, and ChatGPT Pro.
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
  - Glob
---

# call-agent - delegate to a peer AI CLI

Router. You (the host CLI) hand ONE task to a peer agentic CLI when the peer does it
better, then report the result back. Load exactly one
`reference/<target>/call.md` - the one you routed to.

## Rule zero - never call yourself

Whichever CLI is reading this is the *host*. Routing a task to the host is a no-op (you
would just do it yourself). Delegate to a DIFFERENT CLI when explicitly requested or when its capability is missing from the host. Inside Claude Code, never route to `claude`; inside Codex, never route to `codex`.

## Trigger policy (conservative - external CLIs spend separate credits)

Fire on TWO conditions only:

1. **Explicit name** - the user names a target tool.
2. **Capability gap** - the user asks for something the host cannot do natively.

Generic review, planning, refactoring, debugging, and implementation stay with the
host - it is presumed capable. When no peer was requested and the capability gap is unclear, keep the task with the host.

## Route (match the request to ONE target, then load its call.md)

| Signal in the request | Target | Needs binary | Load |
|---|---|---|---|
| "codex"; image generation; one-shot `codex review` | codex | `codex` | `reference/codex/call.md` |
| "agy" / "antigravity" / "gemini cli"; Google-grounded web search; image gen; science DB (gnomAD/UniProt/PubMed/ChEMBL) | agy | `agy` | `reference/agy/call.md` |
| "kiro" / "kiro-cli"; natural-language -> shell `translate`; MCP cross-register; AWS Bedrock peer opinion | kiro | `kiro-cli` | `reference/kiro/call.md` |
| "claude" / "claude code"; implementation; 1M-context planning; deep review | claude | `claude` | `reference/claude/call.md` |
| "notebooklm" / "nblm"; RAG / audio / mind-map over a PDF/URL/YouTube corpus | notebooklm | `notebooklm` | `reference/notebooklm/call.md` |
| "gpt-pro" / "chatgpt pro" / "gpt5 pro"; deep-reasoning second opinion packaged for ChatGPT Pro (web, flat-fee subscription) | gpt-pro | none (`tar`/`pbcopy`) | `reference/gpt-pro/call.md` |

Tie-breakers: an explicit tool name always wins over a capability guess. Image
generation is offered by both `codex` (gpt-image-2, ChatGPT-auth, highest quality) and
`agy` - prefer `codex` when installed, fall back to `agy`.

## Preflight (every route)

Each `call.md` defines its preflight. Run it before sending the task. Claude
implementation requires both auth and shell-capability preflights. If the host blocks
the target, report the normal-terminal fallback instead of retrying with weaker safety.

## Reference map (load only what the routed target needs)

| Load | When |
|---|---|
| `reference/<target>/call.md` | you routed to <target> (always) |
| `reference/agy/patterns.md`, `reference/codex/patterns.md` | need orchestration recipes (parallel fan-out, async jobs) |
| `reference/<target>/reference.md` | need the full flag table / gotchas (agy, codex, kiro, notebooklm) |
| `reference/agy/templates.md` | need copy-paste agy prompt scaffolds |
| `reference/<target>/scripts/*.sh` | the routed call.md tells you to run a wrapper script |

**Done =** target named; route-specific preflight passed; peer output reported, plus
cost/session id when the target emits one; every generated file confirmed on disk. A
blocked target ends with an actionable fallback, never a success claim.
