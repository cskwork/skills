# agy-call — Patterns

Five reusable shapes for delegating to `agy`. Pick by intent.

## Pattern 1 — Grounded web research

Use when the user asks for current/live info that needs Google Search.

```bash
agy -p "Research <TOPIC>. Include: 1) summary, 2) 3-5 key sources with URLs, 3) anything contradicted across sources. Cite inline." \
    --print-timeout 5m0s
```

Output: markdown with inline citations. Capture to file if downstream
steps need to re-read it.

## Pattern 2 — Image generation

Use when the user asks for a visual asset. Always specify an absolute
output path in the prompt.

```bash
agy -p "Generate <SUBJECT> with <STYLE>. Save the final PNG to /abs/path/<name>.png" \
    --dangerously-skip-permissions \
    --print-timeout 5m0s

# verify
test -s /abs/path/<name>.png || echo "agy did not save the image" >&2
```

For multiple variants, use parallel fan-out (Pattern 5).

## Pattern 3 — Second-opinion review

Use when the user asks for an independent perspective on a code or
architecture decision. Pass the artifact via stdin or file content in the
prompt.

```bash
CODE=$(cat path/to/file.py)
agy -p "Review this for correctness, security, and design. Be terse and concrete.

\`\`\`python
$CODE
\`\`\`" --print-timeout 3m0s
```

Surface the response verbatim. Do not interpret it as the final verdict
— it's a second opinion, not an arbiter.

## Pattern 4 — Scientific database query

Use only when the user names a domain DB. Example: "what's the gnomAD
allele frequency of <variant>?"

```bash
agy -p "Query <DB> for <QUESTION>. Report exact values, source URL, and access date." \
    --print-timeout 5m0s
```

## Pattern 5 — Parallel fan-out (research + image at once)

```bash
agy -p "Research X..." --print-timeout 5m0s > /tmp/agy-research.md 2>&1 &
P1=$!
agy -p "Generate Y, save to /abs/path/hero.png" --dangerously-skip-permissions --print-timeout 5m0s > /tmp/agy-img.log 2>&1 &
P2=$!
wait "$P1" "$P2"
```

Independent prompts only. Do not chain: don't have one job depend on
another's output mid-stream.

## Anti-patterns

- Running `agy` for a routine code edit or single-file analysis — wasted
  spend; Claude Code does it faster.
- Omitting `--print-timeout` — default may be too short for research.
- Forgetting the absolute output path in image-gen prompts — file lands
  somewhere unpredictable or nowhere.
- Treating `agy` review output as authoritative — it's a second opinion.
