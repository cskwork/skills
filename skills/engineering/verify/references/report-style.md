# Report style — wait-what

Gate 5's deliverable. Adapted from the [`wait-what`](https://github.com/mattpocock/skills/tree/main/skills/productivity/wait-what) skill by Matt Pocock, which exists for the moment a message does not land.

The premise: the reader lost the thread. They did not read your diff. They do not remember the ticket. They are deciding one thing — ship it or not.

So the report does two jobs at once. It gives back the context the reader is missing. And it says less.

## Rule 1 — Re-pitch, do not recap

A recap lists what you did. A re-pitch tells the reader why it matters to them.

| Recap | Re-pitch |
|-------|----------|
| "Ran 12 curl calls against 4 endpoints." | "All 4 changed endpoints answer correctly. The write also lands in the database." |
| "Gate 2 exit code 0." | "The linter found nothing new. The 3 warnings it prints were already there before this change." |

Lead with the verdict. The evidence follows it.

## Rule 2 — Simplified Technical English

Write to ASD-STE100. The parts that matter here:

- One idea per sentence.
- Short sentences. Twenty words is long.
- Active voice. "The endpoint returns 400", not "a 400 is returned".
- One word, one meaning. Pick a term for a thing and keep it for the whole report.
- Say the noun. "The token expired", not "it expired".
- No jargon you did not define. No idiom. No "basically", "essentially", "simply".
- Present tense for behaviour. Past tense for what you ran.

Two rewrites:

> Having been unable to get the local instance up due to Redis not being available, verification was performed against dev instead.

becomes

> The local service did not start. Redis was not reachable. I ran the checks against the dev environment instead.

> The fix appears to resolve the issue and things look good across the board.

becomes

> The endpoint now returns the correct total. I checked 3 payloads. All 3 match the expected value.

## Rule 3 — Use the project's own words

Read `CONTEXT.md`, the glossary, or the ADRs in the target repo. Use the headword the team uses.

When the code and the glossary disagree on a term, say so in the report. That disagreement is a finding.

When the project has no glossary, use the words that appear in the code and the ticket. Do not introduce a synonym.

For a Korean-language team: write the report in Korean. Keep code identifiers, paths, commands, endpoints, SQL, and exact error strings unchanged. The Simplified Technical English rules still apply — short sentences, one idea each, active voice.

## Rule 4 — Name what you did not verify

The gap is the most valuable line in the report. A reader who trusts a report that hid a gap stops trusting reports.

State it plainly:

> I did not verify the admin view. That needs an admin account that has data, and I did not have one.

## Structure

Fill this. Drop a section only when it is genuinely empty.

```markdown
# verify — <what changed>

**Verdict:** <PASS | FAIL | PASS WITH GAPS> — <one sentence a reader can act on>

## Context
Two or three sentences. What the change was for. Which base you compared against.
Written for someone who has not seen the diff.

## Gates
| Gate | Verdict | Evidence |
|------|---------|----------|
| 1 Build | PASS | `receipts/01-build.log`, exit 0 |
| 2 Static | PASS | `receipts/02-static.log`, 0 new findings, 3 pre-existing |
| 3 Clean code | PASS | 1 note, 0 blocking |
| 4 Scenario | PASS | 12 receipts under `receipts/04-scenario/` |
| 5 Report | — | this file |

## What I proved
Numbered. Behaviour, not file names. One idea per item.
1. `GET /path` returns the corrected total for a real account. Before the fix it returned 0.
2. A request with an unknown id returns 400. It does not return 500.

## What I did not verify
Numbered. Say why, and say what would unblock it.
1. The admin view. I had no admin account that had any data.

## Findings
| Severity | File | Finding |
|----------|------|---------|
Write `none` when there are none.

## Next
The one action the reader must take. Or the one question that changes their decision.
```

## Length

One page. A reader who scrolls stops reading.

Push the raw exchanges into the receipt files and link them. The report carries the verdict and the shape of the evidence, not the evidence itself.
