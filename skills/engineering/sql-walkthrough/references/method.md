# Finding a sample and running the block (read-only environment)

Placeholders: `SEL` = the table the selection condition reads (e.g. an access list with `ENTITY_ID, DAY`);
`SRC` = the table the value comes from (e.g. a time log with `ENTITY_ID, BEGIN_DT, END_DT`).
Confirm the host first (`SELECT @@hostname`). Never run on production.

## 1. Entity with records on both sides of the input — shows whether a range cut exists

```sql
SELECT LEFT(s.ENTITY_ID, 8) AS id8, s.ENTITY_ID, sel.DAY,
       COUNT(*)                                                      AS rows_total,
       SUM(s.BEGIN_DT <  STR_TO_DATE(sel.DAY, '%Y%m%d') + INTERVAL 1 DAY) AS rows_upto,
       SUM(s.BEGIN_DT >= STR_TO_DATE(sel.DAY, '%Y%m%d') + INTERVAL 1 DAY) AS rows_after
FROM SEL sel
JOIN SRC s ON s.ENTITY_ID = sel.ENTITY_ID AND s.BEGIN_DT < s.END_DT
WHERE sel.DAY >= '20260801'
GROUP BY s.ENTITY_ID, sel.DAY
HAVING rows_upto > 0 AND rows_after > 0
ORDER BY rows_total ASC
LIMIT 5;
```

Take one with `rows_total <= 5`. For another source table swap `SRC` and its date column.

## 2. Entity present under both inputs — shows "different input, same value"

```sql
SELECT a.ENTITY_ID, COUNT(*) n
FROM SEL a JOIN SEL b ON b.ENTITY_ID = a.ENTITY_ID AND b.DAY = '<inputB>'
WHERE a.DAY = '<inputA>'
GROUP BY a.ENTITY_ID;
```

## 3. Raw rows, as-is

```sql
SELECT ENTITY_ID, DAY FROM SEL WHERE ENTITY_ID LIKE '<id8>%' ORDER BY DAY;

SELECT ENTITY_ID, BEGIN_DT, END_DT,
       TIMESTAMPDIFF(SECOND, BEGIN_DT, END_DT)            AS sec,
       ROUND(TIMESTAMPDIFF(SECOND, BEGIN_DT, END_DT)/60, 1) AS min_each,
       BEGIN_DT < END_DT                                   AS ok
FROM SRC WHERE ENTITY_ID LIKE '<id8>%' ORDER BY BEGIN_DT;
```

## 4. Run the block three times

Take `extract_block.py … <cte> --sql` output and:
- replace `#{param}` with `'<inputA>'`
- append `AND <alias>.ENTITY_ID LIKE '<id8>%'` to WHERE (sample filter — say it is not in production)
- third run only: add one hypothetical line, e.g. `AND s.BEGIN_DT < '<inputA + 1 day>'`

## 5. Whole-population diff (not just one entity)

Run the statement's SELECT part (strip `INSERT`/`ON DUPLICATE`) for two inputs; compare every column for keys present under both. Key = the target table's full primary key.

## 6. Write test (needs explicit approval)

Snapshot target rows into memory/JSON → run the real upsert → diff: value changes / `CHG_DT` changes / rows lost / rows added / total row count. Do not `CREATE TABLE` for the snapshot; read-only runners usually block DDL. If an automated permission gate blocks the write, leave the script and let the user run it.
