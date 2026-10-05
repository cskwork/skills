# PostgreSQL

## Connect (credential-safe)

Preferred: the proven `postgres-intelligence` toolkit if present in the project
(`.agents/skills/postgres-intelligence/` or `~/.agents/skills/postgres-intelligence/`):

```bash
python scripts/config.py                 # validate .env without printing secrets
python scripts/db_connector.py           # test all DB1..DB10 connections
python scripts/schema_extractor.py       # → schema_metadata.json
python scripts/query_executor.py --json-only "SELECT now();"
python scripts/query_executor.py --db <name> "SELECT ...;"      # named connection
python scripts/query_executor.py --allow-write "UPDATE ...;"    # user-approved only
python scripts/query_executor.py --allow-ddl   "CREATE INDEX ...;"
```

Fallback: `psql` with env vars the *user* exports (never you):

```bash
psql "$DATABASE_URL" -X -c "SELECT ...;"          # -X skips ~/.psqlrc
PGPASSWORD stays in the environment; never echo it.
```

## Schema extraction

```sql
-- tables + comments
SELECT table_schema, table_name, obj_description(format('%I.%I',table_schema,table_name)::regclass)
FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog','information_schema');

-- columns
SELECT table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns WHERE table_schema = 'public' ORDER BY table_name, ordinal_position;

-- FK edges for the entity graph
SELECT tc.table_name AS child, kcu.column_name, ccu.table_name AS parent, ccu.column_name AS parent_col
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY';
```

`\d+ <table>` in psql shows indexes, checks, and comments in one shot.

## Engine-specific care

- Performance: `EXPLAIN (ANALYZE, BUFFERS)`; verify index use before/after.
- Large prod indexes: `CREATE INDEX CONCURRENTLY` (needs `--allow-ddl` + approval).
- JSONB containment/full-text → GIN index; append-only time series → BRIN.
- After bulk changes: `ANALYZE`.
- Identifier case: unquoted identifiers fold to lowercase — quote only when the
  schema really has mixed case.
- `sqlstate` in error JSON drives the retry taxonomy (42P01 missing table,
  42703 missing column, 42601 syntax).
