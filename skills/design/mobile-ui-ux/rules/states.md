# Empty, loading, error, and limit states

Every screen and every list has these states designed, not just the happy path.

## Rules

**S-1 Empty state.** Says what will appear here, why it is empty, and offers the one action that fills it ("No tasks yet. Add your first task."). Text meets C-1. Uses the same layout frame as the filled state so nothing jumps.

**S-2 Loading.** Under ~300 ms show nothing extra. 300 ms to ~2 s: skeleton or inline spinner in place of the content. Over ~2 s: progress with context. Over ~10 s: determinate progress or a way to continue elsewhere. `[NNG-Response]`

**S-3 No layout shift.** Loading placeholders reserve the final size. Content arriving late does not push what the user is about to tap. `[CWV]`

**S-4 Error.** States what happened, what the user can do, and offers a retry. No raw codes as the only message. Preserve the user's work.

**S-5 Offline.** If the app needs network, say so in place and keep cached content visible. Queue actions when possible.

**S-6 Limit reached.** When a limit blocks an action (slots full, inventory full, quota), show it at the moment of the attempt: flash the limiting element, snap the item back, and show a short message with the numbers ("Item slots full (3/3)"). `[Field]`

**S-7 Success.** Confirm completed actions briefly (inline check, toast, haptic success) without blocking the next action.

**S-8 Partial and stale data.** Mark stale or partial data ("Updated 5 min ago") rather than presenting it as current.

**S-9 First run.** First-run screens teach by doing (one action at a time) and can be skipped. Do not front-load more than 3 explanation screens. `[HIG-Games]` `[LawsUX-ActiveUser]`

**S-10 Capture every state.** Each state above that applies is captured as a screenshot during review (see SKILL.md step 6).
