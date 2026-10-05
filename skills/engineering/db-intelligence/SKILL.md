---
name: db-intelligence
description: "Unified database intelligence for PostgreSQL, MySQL, SQLite, and MongoDB in one skill: detect the engine, connect credential-safe, extract schema, build an entity-relationship graph, and run read-first queries. Use BEFORE coding to establish domain language, domain data shapes, and real data evidence (specify/explore stage); use during hardening/QA for read-only data verification of selects, updates, and deletions. Triggers: database, DB, schema, domain data, data shapes, ER diagram, PostgreSQL, MySQL, SQLite, MongoDB, mongosh, psql, sqlite3, 'check the data', 'what does the table look like', 'verify in DB'."
license: MIT
metadata:
  author: cskwork
  version: "1.0.0"
  consolidates: postgres-intelligence, mysql-intelligence, mongodb-intelligence, sql-check
---

# db-intelligence

One skill, four engines. Contract: **schema before SQL, evidence before claims,
reads before writes.** The output of this skill is not just query results — it is
a *domain evidence artifact* other agents (specifier, coder, QA) can consume.

## Step 1 — Detect the engine

| Signal | Engine | Reference |
|---|---|---|
| `psql`, port 5432, `pg_catalog`, DATABASE_URL `postgres://` | PostgreSQL | `reference/postgres.md` |
| `mysql`, port 3306, JDBC `mysql:`, MyBatis/JPA against MySQL | MySQL | `reference/mysql.md` |
| a `.db`/`.sqlite`/`.sqlite3` file, `better-sqlite3`, embedded/local store | SQLite | `reference/sqlite.md` |
| `mongodb://` URI, collections, aggregation, `mongosh` | MongoDB | `reference/mongodb.md` |

Can't tell? Look at the repo: ORM config (`application.yml`, `mybatis`,
`prisma/schema.prisma`, `knexfile`, `mongoose`), docker-compose services, and
`.env*` keys name the engine. Multiple engines in one task are normal — open
each engine's reference and keep one evidence artifact.

Project-specific routing (which logical DB owns which table prefix, which
environments are allowed) lives in **domain packs**: check
`reference/domain/*.md` in this skill (local-only, never synced publicly) and
any `sql-check`-style router in the project's `.agents/skills/` — obey them
first.

## Hard rules (all engines)

1. **Never open or print `.env` / credential files.** Scripts and CLIs load
   credentials at runtime; you see results, never passwords. Never echo a
   connection string containing a password.
2. **Read-first.** `SELECT` / `find` / `EXPLAIN` run freely. Any
   `UPDATE`/`DELETE`/`INSERT`/DDL/`updateMany`/`deleteMany`: show the exact
   statement + expected row count to the user, get approval, then run, then
   re-`SELECT` to verify the effect. Writes to prod are forbidden.
3. **`WHERE`-less UPDATE/DELETE is always a bug.** Refuse and ask.
4. **Schema before SQL.** Never guess table, column, or field names. Extract or
   load schema metadata first; RAG over it to pick tables.
5. **LIMIT by default** (≤1000) on exploratory reads. Prefer explicit columns
   over `SELECT *`.
6. **Max 3 retry refinements** on query errors, then report the blocker.
7. **Evidence, not bulk.** Quote the executed statement, row count, and the
   deciding rows in your report. Large dumps go to scratch files, get read,
   get deleted.
8. **Code is the oracle for code claims.** When explaining why a production
   query/CTE/ORM call behaves a certain way, first quote the actual SQL from
   the repo (mapper XML, migration, ORM output) and evaluate ONLY the
   conditions that text contains. Never evaluate conditions inferred from
   requirements prose or column names — a plausible invented condition is the
   classic false root cause. If you cannot locate the real query, say so
   instead of reconstructing it.

## Step 2 — Schema → entity graph (the domain model)

This is what makes the data *domain knowledge* rather than rows:

1. Extract schema (per-engine command in its reference file).
   **Staleness check first**: if a `schema_metadata.json` (or cached DDL dump)
   already exists, compare its mtime against the repo's migration/DDL files
   (`migration*/`, `db/`, `*.sql`, `prisma/`, Flyway/Liquibase dirs) — older
   than the newest migration means re-extract before trusting it. MongoDB has
   no migrations: re-sample when the metadata is older than the feature you
   are specifying, or on any field-shape surprise.
2. Build the **entity-relationship graph**: nodes = tables/collections, edges =
   FKs / embedded refs / join-table links. For engines without declared FKs
   (MongoDB, legacy MySQL), infer edges from `*_id` naming and sampled values.
3. Record the **ubiquitous language**: table/column comments, enum/code values
   and their meanings, status-flag semantics (`_YN`, `del_yn`, soft deletes).
4. Note **data-shape gotchas**: nullable columns that are "never null in
   practice", JSON columns, date encodings, charset/collation, multi-tenancy
   keys.

Output shape (write it to the path the task names, else `db-evidence.md`):

```markdown
# DB evidence — <task/feature>
## Engines & connections   (names + source environment e.g. dev/audit — never credentials; non-prod data is never prod truth)
## Entity graph            (mermaid erDiagram or adjacency list, relevant slice only)
## Ubiquitous language     (term → table.column → meaning, code values decoded)
## Data shapes             (types, nullability-in-practice, gotchas)
## Queries run             (statement → row count → deciding rows)
## Open questions          (what the data could not answer)
```

Keep the graph to the **relevant slice** — the 5–15 entities the task touches,
not the whole schema.

**Cache the stable part in the domain pack.** Entity-graph edges and
ubiquitous language change rarely; data shapes and row realities drift.
When a `reference/domain/<project>.md` pack exists, read its cached graph
slice first and only re-verify the *data* (shapes, counts, code values)
against the live DB. After a session that mapped new entities or decoded new
terms, append them to the domain pack (dated) so the next run starts warm.
No pack, recurring project → offer to create one.

## Step 3 — Query

Natural language → statement, using the schema metadata (never guesses).
Per-engine syntax, executors, retry-error taxonomy, and performance analysis
live in the reference files. Multi-step analysis: prefer one statement that
answers the question over N round trips.

## Step 4 — Present

Three formats when useful, at minimum the first: **data table** (≤20 rows shown,
note total), **analysis** (direct answer + notable pattern/outlier), and
optionally a **chart** via the legacy visualizer scripts.

## Reference map

| File | When |
|---|---|
| `reference/postgres.md` | psql, information_schema/pg_catalog, EXPLAIN ANALYZE, existing postgres-intelligence scripts |
| `reference/mysql.md` | mysql CLI, multi-DB routing, existing mysql-intelligence scripts |
| `reference/sqlite.md` | sqlite3 CLI, file discovery, PRAGMA schema/introspection, WAL/locking gotchas |
| `reference/mongodb.md` | mongosh, sample-based schema inference, aggregation pipelines, existing mongodb-intelligence scripts |
| `reference/domain/*.md` | local-only domain packs: per-project DB routing, environments, known failure classes (gitignored — may be absent on a fresh install) |

**Done =** engine stated · schema loaded before any statement · entity-graph
slice + language recorded in the evidence artifact · every claim backed by a
quoted statement + row count · no credential ever printed · writes only with
explicit user approval and post-verification.
