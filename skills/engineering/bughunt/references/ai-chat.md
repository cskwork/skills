# Profile: ai-chat

Use when the product's core is a conversation with a language model: chat, Q&A, AI assistants, anything that streams generated text.

## Vocabulary

| Core term | Here |
|---|---|
| phase | conversation state: idle, sending, streaming, done, stopped, error |
| command | send, stop, regenerate, edit-and-resend, delete conversation |
| entity | message and conversation |
| bot | the model's streamed reply |

## Model stub

Run the matrix against a scripted model stub: fixed chunks and delays, errors (429, 500, timeout), refusals, empty replies, very long replies, and markdown with links, tables and code. The stub makes runs replayable and costs nothing. Add one pass per run against the real model, labeled `live` and reported separately: judged only by the structural oracles below, outside the two-pass count, its text never compared or hashed.

## Personas

| Core ID | Runs as | Stress |
|---|---|---|
| `new-player` | `new-user` | First question from the empty state, suggested prompts, required notices shown before the first answer. |
| `masher` | as written | Send twice, Enter plus click, send during streaming, stop then send, regenerate bursts. |
| `save-resume` | as written | Reload or cold launch mid-stream. History returns; the partial reply is marked incomplete or resumed by contract; the next send works. |
| `interruptions` | as written | Network drop mid-stream, app or tab backgrounded mid-stream, 429/500/timeout from the model, session expiry. |
| `resize` | as written | Long messages, wide code blocks and tables, soft keyboard over the input. A user scrolled up stays where they are while tokens arrive. |
| `slow-player` | as written | Idle, then send; a stub streaming 1 token per second. |
| `speed-changer` | `stream-rate` | Stub chunks fast, slow and bursty. |
| `monkey` | as written | Switch or delete conversations during a stream; copy, share and feedback buttons mid-stream. |
| `localization` | as written | Korean IME Enter during composition; long Korean input; mixed-language replies wrap. |
| `low-power-motion` | as written | Typing indicators and streaming render with Reduce Motion. |

Extra cases: input at the length limit and one past it, empty or whitespace send, conversation or quota limit reached.

## Oracle bindings

| ID | Holds here when |
|---|---|
| O-2 | One send makes one request and one user message. Send is disabled or queued by contract while streaming. Stop aborts the request, shown in network evidence. |
| O-3 | Streamed chunks render only into the conversation that sent them; switching conversations never shows another conversation's tokens. The input accepts text once the screen is ready. |
| O-5 | Message order and count match the server. Every assistant reply pairs with one user message; regenerate replaces or versions it by contract. Nothing is duplicated or lost. |
| O-6 | Replay uses the stub only; `live` runs stay out of replay hashes. |
| O-7 | Every stream ends in done, stopped or error within its deadline. No typing indicator outlives its stream; an error offers retry and keeps the user's text. |
| O-8 | History survives reload and cold launch; a deleted conversation stays deleted; a partial reply stays flagged. |
| O-9 safe-render | Model output is untrusted input: scripts never run, raw HTML is escaped, links open safely. |
| O-10 request-budget | Requests per user action stay within contract: no retry loops or duplicate streams. |
