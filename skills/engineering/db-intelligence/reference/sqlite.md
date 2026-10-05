# SQLite

No server, no credentials — the **file is the database**. Risk shifts from
credential leaks to *file safety*: locking, backups, and writing the wrong copy.

## Locate the database

```bash
find . -maxdepth 4 \( -name "*.db" -o -name "*.sqlite" -o -name "*.sqlite3" \) -not -path "*/node_modules/*" 2>/dev/null
file <candidate>                     # "SQLite 3.x database"
```

App config also names it: `better-sqlite3`/`sqlite3` in package.json,
`jdbc:sqlite:`, Django `NAME`, `DATABASE_URL=file:...`.

## Hard rules

- **Copy before write probes**: `cp app.db /tmp/probe.db` and experiment on the
  copy. Only touch the live file with user approval.
- A live app may hold the write lock. Read safely without blocking writers:
  `sqlite3 "file:app.db?mode=ro" "SELECT ...;"`. If WAL journaling is on
  (`PRAGMA journal_mode;` → `wal`), concurrent reads are safe; with legacy
  journal mode, expect `database is locked` — retry, don't force.
- Never delete `-wal`/`-shm` sidecar files; they contain unflushed commits.

## Schema extraction

```bash
sqlite3 app.db ".tables"
sqlite3 app.db ".schema <table>"                       # full DDL
sqlite3 app.db "SELECT name, sql FROM sqlite_master WHERE type='table';"
sqlite3 app.db "PRAGMA table_info(<table>);"           # columns, types, notnull, pk
sqlite3 app.db "PRAGMA foreign_key_list(<table>);"     # FK edges for entity graph
sqlite3 app.db "PRAGMA index_list(<table>);"
```

## Query

```bash
sqlite3 -header -column app.db "SELECT ... LIMIT 100;"   # human table
sqlite3 -json app.db "SELECT ...;"                       # agent parsing
```

## Engine-specific care

- **Type affinity, not types**: any column can hold any value. Check reality:
  `SELECT typeof(col), COUNT(*) FROM t GROUP BY 1;`
- FKs are **off by default** — `PRAGMA foreign_keys;`. If 0, orphan rows are
  likely; a hardening probe should count them.
- Dates are TEXT/INTEGER by convention; check the actual format before
  filtering (`strftime` vs unix epoch vs ISO strings).
- Performance: `EXPLAIN QUERY PLAN SELECT ...;` — look for `SCAN` on big tables.
- Backup a live DB with `sqlite3 app.db ".backup /tmp/snap.db"` (consistent),
  never `cp` while the app writes.
