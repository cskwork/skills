---
name: sql-walkthrough
description: "Explain batch/SQL/aggregation logic to a non-expert who asks 'why this value / is it safe / does it overwrite?'. Answer with numbered source lines + the real rows those lines read + per-line ①②③ arithmetic on those rows + a results table where only the input changes + a counter-example (the condition that is NOT there). Use this shape from the first reply instead of prose."
---

# sql-walkthrough

Show the logic as one bundle: **code → the real rows it reads → per-line arithmetic → results → counter-example**.
This is mandatory when the evidence is a *negative* ("there is no date cut"). Prose does not land; the counter-example value next to the real value does.

## When

- "If I run this batch for an old date, does it overwrite today's values?"
- "Why is this number 154?" / "Where is the SUM?" / "What is the condition?" / "What is the proof query?" asked back-to-back
- Any MyBatis / batch SQL upsert or aggregation that a non-developer must trust

## Output shape (keep this order and layout)

```
<code block: real line numbers + the deployed source text, line breaks and comments intact>

**Real data: entity B (read-only env, id prefix xxxxxxxx)**

<table 1: the table the selection condition reads>   (table name, line N alias)  ← tie each table to a code line
<table 2: the table the value comes from>             (table name, line N alias)

**① line N `expr` — where the "value" is made**
- arithmetic on those rows: 3,000 + 3,083 + 3,140 = 9,223 s → ÷60 → 154 min

**② line N WHERE — where the "range" is decided**
- one condition at a time: which table's column, what it removes, whether it cuts by date

**③ line N JOIN — where the input does and does not travel**

**Results (lines N–M executed as-is on the read-only env)**
| input | result | meaning |
| A     | 154    | …       |
| B     | 154    | same value with a different input |
| A + hypothetical `AND <the dangerous condition>` | 50 | what you would get if that condition existed |

**Summary**
① … → one line
② … → one line
③ … → one line
```

Rules:
- Numbers come from **real rows**. A made-up example (60+40+50) is only a warm-up; replace it with real rows immediately.
- Pick a sample entity with **≤ 5 rows** so the raw rows fit in a table.
- Show anonymised ids as an 8-char prefix only.
- The counter-example adds **exactly one hypothetical line** to the production SQL and runs it. Put "if it existed" next to the real value.
- Sentences: short, one fact each, active voice (ASD-STE100 style). Vocabulary: the repo's `CONTEXT.md` / ubiquitous language.
- Conclusion first, then code. No hedging ("it can be seen that…").

## Procedure

1. **Extract the code with real line numbers** from the deployed ref.
   `python3 scripts/extract_block.py <repo> <git-ref> <mapper.xml> <statement-id> [cte-name]`
   Output lines look like `1738  lrn_time AS (...`. With a CTE name you get just that block; without, the whole statement.
2. **Enumerate every date/range condition**: same script with `--scan` lists lines matching `_DT|startDate|NOW|INTERVAL|BETWEEN|<=|>=` with line numbers. Classify each as *selection* / *state* / *range*. "Range conditions: 0" is itself the evidence.
3. **Find a sample entity**: satisfies the selection, has records on both sides of the chosen input (e.g. before and after the date), few rows. Patterns in `references/method.md`. Read-only environment only.
4. **Print the raw rows** of the selection table and the source table, separately, as-is.
5. **Run the block three times**, text unchanged: (a) input A, (b) input B, (c) A + one hypothetical line. Mark the sample filter (`AND x.ID LIKE 'xxxxxxxx%'`) as a line that is *not* in production.
6. **Write it up**: in an evidence doc put a `> **Evidence**` quote box under each claim with file, line numbers, query, result. In a ticket comment: bullet conclusions + code block + two tables (raw rows / results). Attach the full queries as a text file.

## Pitfalls

- `WHERE a.x < a.y` compares **two columns of the same row**. That is a quality filter, not a range cut. Only "compared with a specific date value" is a range cut.
- A selection condition (`sel.date = …`) *is* a filter, but it filters **which entities** are computed. It does not trim an entity's **records**. Say both halves.
- `IFNULL`, `ROUND`, `TIMESTAMPDIFF` inside `SUM(...)` are not filters. Only WHERE decides what enters the sum.
- Line numbers move between releases (a comment-only commit shifted a block by 2 lines). Always state the ref the numbers belong to.
- If a write-test is needed (run the real upsert and diff before/after), snapshot in memory/JSON, not with `CREATE TABLE`; many read-only runners block DDL. Ask before writing to a shared environment.

## Worked example (anonymised)

Upsert `INSERT … ON DUPLICATE KEY UPDATE` recomputes per-entity totals. Input date selects entities from an access list; the SUM over a time-log table has no date predicate.
Entity `a1b2c3d4`: 8/6 3,000 s + 8/7 3,083 s + 8/7 3,140 s = 154 min. Input 8/6 → 154, input 8/7 → 154, 8/6 + hypothetical `AND log.BEGIN_DT < '2026-08-07'` → 50.
Real write-test on the read-only-by-policy environment: 629 rows rewritten (CHG_DT changed), 0 value changes, 0 rows lost, 0 rows added.
