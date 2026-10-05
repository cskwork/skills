# MySQL

## Connect (credential-safe)

Credentials come from a `.env` that **`scripts/config.py` locates itself** —
never hardcode a path. Resolution order: `$DB_INTELLIGENCE_ENV` →
`$DB_INTELLIGENCE_HOME/.env` → `<skill>/.env` → known agent hubs
(`~/.pi/agent/skills`, `~/.agents/skills`, `~/.claude/skills`,
`~/.codex/skills` × `db-intelligence`, `mysql-intelligence`). The two env vars
are explicit input: if set and missing they raise `EnvFileNotFound` rather
than silently connecting to another environment's database.

Validate — prints connections, never secrets:

```bash
SKILL="$(dirname "$(dirname "$0")")"      # or the skill dir from the loader message
python3 "$SKILL/scripts/config.py"
```

Connection names come from `DB*_NAME`, not index — always select by name.
Project-specific names and routing live in `reference/domain/*.md`.

Only `config.py` is bundled. The heavier executors (`db_connector.py`,
`query_executor.py`, `schema_extractor.py`, visualizers) live in the upstream
`mysql-intelligence` toolkit when it is installed; locate it rather than
assuming a path:

```bash
MI=$(find ~/.agents/skills ~/.pi/agent/skills ~/.claude/skills -maxdepth 2 \
        -type d -name mysql-intelligence 2>/dev/null | head -1)
[ -n "$MI" ] && python3 "$MI/scripts/db_connector.py"      # test connections
[ -n "$MI" ] && python3 "$MI/scripts/schema_extractor.py"  # → schema_metadata.json
```

Multi-DB (named connections) via Python import:

```python
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(MI)))      # MI = located toolkit dir
from scripts.db_connector import MySQLConnector
from scripts.query_executor import QueryExecutor
from scripts.config import get_all_configs
configs = get_all_configs()                    # dict keyed by DB*_NAME from .env
executor = QueryExecutor(MySQLConnector(config=configs['<name>']).get_connection())
success, result = executor.execute_with_retry(sql, max_retries=3)
```

Fallback raw CLI (credentials loaded by the shell, never printed — note the
`.env` path comes from the loader, not a literal):

```bash
ENV_FILE=$(python3 -c "import sys;sys.path.insert(0,'$SKILL/scripts');import config;print(config.find_env_file())")
set -a; source "$ENV_FILE"; set +a
mysql -h "$DB4_HOST" -P "$DB4_PORT" -u "$DB4_USER" -p"$DB4_PASSWORD" "$DB4_DATABASE" -e "<SQL>"
```

## Multi-DB routing

When a project spans several logical MySQL databases, route by table prefix /
naming convention. The mapping (prefix → DB → connection name) and the `.env`
location are **project knowledge**: look for a project-local router skill
(e.g. `sql-check` in the project's `.agents/skills/`) and obey its environment
rules — typically dev/audit only, **never prod**.

## Schema extraction

```sql
SELECT TABLE_NAME, TABLE_COMMENT FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE();
SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_COMMENT
FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE();
-- FK edges
SELECT TABLE_NAME AS child, COLUMN_NAME, REFERENCED_TABLE_NAME AS parent, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE REFERENCED_TABLE_NAME IS NOT NULL AND TABLE_SCHEMA = DATABASE();
SHOW CREATE TABLE <t>;                         -- full DDL incl. indexes
```

Legacy schemas often have **no declared FKs** — infer entity-graph edges from
`*_id`/`*_no` column naming plus join patterns in the app's MyBatis XML / ORM code.

## Engine-specific care

- Column comments are the ubiquitous language in Korean enterprise schemas —
  always select `COLUMN_COMMENT`.
- `_YN` flags: check actual distinct values; 'Y'/'N' assumptions fail on NULL.
- Scalar subqueries that can return >1 row (`Subquery returns more than 1 row`)
  are a classic legacy-schema failure class — check cardinality with COUNT first.
- Performance: `EXPLAIN` / `EXPLAIN ANALYZE` (8.0.18+); watch `filesort`,
  `temporary`, full scans on large tables.
- Charset: utf8mb4 vs utf8 mismatches corrupt emoji/Hanja comparisons.
