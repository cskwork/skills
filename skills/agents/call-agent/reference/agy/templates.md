# agy-call — Prompt Templates

Copy-paste scaffolds. Replace `<UPPERCASE>` placeholders.

## T1 — Web research with citations

```
Research <TOPIC> using Google Search grounding.

Deliverable:
1. 3-paragraph summary
2. 5 key sources (URL + 1-line takeaway each)
3. Any contradictions or outdated info you found

Cite inline as [n].
```

## T2 — Image generation

```
Generate an image of <SUBJECT>.

Style: <STYLE>
Aspect: <16:9|1:1|9:16>
Background: <COLOR or transparent>

Save the final PNG to <ABS_PATH>. Do not return a base64 preview;
only confirm the file path.
```

## T3 — Second-opinion code review

```
Below is <LANGUAGE> code from a <CONTEXT> codebase.
Review for: correctness, security, design. Be terse and concrete —
cite file:line if a path is mentioned in comments.

```<LANGUAGE>
<CODE>
```

Output format: bullet list grouped by severity (Critical / Major /
Minor). No prose preamble.
```

## T4 — Architecture second opinion

```
We are considering <DECISION A> vs <DECISION B> for <CONTEXT>.

Constraints: <CONSTRAINTS>
Out of scope: <NON-GOALS>

Pick one and defend it in 200 words or less. State the strongest
counter-argument and why it doesn't win.
```

## T5 — Scientific DB query

```
Query <DB_NAME> for: <QUESTION>.

Return:
- Exact value(s) with units
- Source URL
- Access date
- Caveats if the DB has multiple matching entries
```

## T6 — Follow-up on prior conversation

```bash
agy -c -p "<FOLLOW-UP QUESTION>" --print-timeout 3m0s
```

Use `-c` only when the prior turn is materially needed. Otherwise start
fresh — `agy` has no chat-cost optimization for context reuse.
