#!/usr/bin/env python3
"""
Configuration Loader for db-intelligence.
Loads database credentials from a .env file; callers see connections, never
secrets.

Portable by design: nothing here hardcodes a machine, agent, or hub path.
Resolution order (first hit wins):

  1. $DB_INTELLIGENCE_ENV   - explicit file path. If set but missing, FAIL
                              LOUDLY. An explicit path must never silently
                              fall back to another environment's database.
  2. $DB_INTELLIGENCE_HOME  - explicit skill dir; uses <dir>/.env, same
                              fail-loudly rule.
  3. <skill root>/.env      - the .env beside this skill (scripts/../.env).
  4. Known agent skill hubs - ~/.pi/agent/skills, ~/.agents/skills,
                              ~/.claude/skills, ~/.codex/skills, each under
                              db-intelligence/ then mysql-intelligence/.

Step 3 is deliberately a single level, not an upward walk: walking parents
meant a skill dropped inside a project repo could silently load that repo's
.env and query the wrong database.
"""

import os
from pathlib import Path
from typing import Dict, List, Optional

SKILL_ROOT = Path(__file__).resolve().parent.parent

_HUB_CANDIDATES = (
    Path.home() / ".pi" / "agent" / "skills",
    Path.home() / ".agents" / "skills",
    Path.home() / ".claude" / "skills",
    Path.home() / ".codex" / "skills",
)
_SKILL_DIRNAMES = ("db-intelligence", "mysql-intelligence")


class EnvFileNotFound(RuntimeError):
    """An explicitly configured .env path does not exist."""


def find_env_file() -> Optional[Path]:
    """Resolve the .env path. Explicit settings fail loudly; discovery is quiet."""
    explicit_file = os.environ.get("DB_INTELLIGENCE_ENV")
    if explicit_file:
        path = Path(explicit_file).expanduser()
        if not path.is_file():
            raise EnvFileNotFound(
                f"DB_INTELLIGENCE_ENV points to {path}, which does not exist. "
                "Refusing to fall back - an explicit path must not silently "
                "connect to a different database."
            )
        return path

    explicit_home = os.environ.get("DB_INTELLIGENCE_HOME")
    if explicit_home:
        path = Path(explicit_home).expanduser() / ".env"
        if not path.is_file():
            raise EnvFileNotFound(
                f"DB_INTELLIGENCE_HOME is {explicit_home}, but {path} does not "
                "exist. Refusing to fall back."
            )
        return path

    local = SKILL_ROOT / ".env"
    if local.is_file():
        return local

    for hub in _HUB_CANDIDATES:
        for dirname in _SKILL_DIRNAMES:
            candidate = hub / dirname / ".env"
            if candidate.is_file():
                return candidate

    return None

# Load environment variables from .env file
def load_env_file():
    """Load .env file if it exists."""
    env_path = find_env_file()

    if env_path is None:
        return

    with open(env_path, 'r') as f:
        for line in f:
            line = line.strip()
            # Skip comments and empty lines
            if not line or line.startswith('#'):
                continue

            # Parse KEY=VALUE
            if '=' in line:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip()

                # Remove quotes if present
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]
                elif value.startswith("'") and value.endswith("'"):
                    value = value[1:-1]

                os.environ[key] = value

# Load .env at import time
load_env_file()

class DatabaseConfig:
    """Database connection configuration."""

    def __init__(self, host: str, user: str, password: str,
                 database: Optional[str] = None, port: int = 3306,
                 name: str = "default"):
        self.host = host
        self.user = user
        self.password = password
        self.database = database
        self.port = port
        self.name = name

    def to_dict(self) -> Dict:
        """Convert to dictionary for mysql-connector."""
        config = {
            "host": self.host,
            "user": self.user,
            "password": self.password,
            "port": self.port
        }
        if self.database:
            config["database"] = self.database
        return config

    def __repr__(self):
        # Don't show password in repr
        return f"DatabaseConfig(name={self.name}, host={self.host}, user={self.user}, database={self.database})"

def load_database_configs() -> List[DatabaseConfig]:
    """
    Load all database configurations from environment variables.
    Returns list of DatabaseConfig objects (up to 10).
    """
    configs = []

    # Try to load DB1..DB10
    for i in range(1, 11):
        prefix = f"DB{i}_"

        host = os.environ.get(f"{prefix}HOST")
        user = os.environ.get(f"{prefix}USER")
        password = os.environ.get(f"{prefix}PASSWORD")

        # If host, user, password are all present, create config
        if host and user and password:
            database = os.environ.get(f"{prefix}DATABASE", None)
            port = int(os.environ.get(f"{prefix}PORT", 3306))
            name = os.environ.get(f"{prefix}NAME", f"db{i}")

            config = DatabaseConfig(
                host=host,
                user=user,
                password=password,
                database=database,
                port=port,
                name=name
            )
            configs.append(config)

    if not configs:
        raise ValueError(
            "No database configurations found in .env file. "
            "Please create a .env file based on .env.example"
        )

    return configs

def get_primary_config() -> DatabaseConfig:
    """Get the primary database configuration (DB1)."""
    configs = load_database_configs()
    return configs[0]

def get_all_configs() -> Dict[str, DatabaseConfig]:
    """Get all database configurations as a dictionary keyed by name."""
    configs = load_database_configs()
    return {config.name: config for config in configs}

# Auto-load configs at import time for validation
try:
    _configs = load_database_configs()
    DB_CONFIGS = {config.name: config for config in _configs}
    PRIMARY_CONFIG = _configs[0]
except ValueError:
    # .env file not found or empty - will be handled by scripts
    DB_CONFIGS = {}
    PRIMARY_CONFIG = None

if __name__ == "__main__":
    # Test configuration loading
    print("=== MySQL Intelligence Configuration ===\n")

    try:
        configs = load_database_configs()
        print(f"✅ Found {len(configs)} database configuration(s):\n")

        for i, config in enumerate(configs, 1):
            print(f"{i}. {config.name}")
            print(f"   Host: {config.host}:{config.port}")
            print(f"   User: {config.user}")
            print(f"   Database: {config.database or '(no default database)'}")
            print()

        print("✅ Configuration loaded successfully!")
        print("\nNote: Passwords are loaded but not displayed for security.")

    except ValueError as e:
        print(f"❌ Error: {e}")
        print("\nPlease create a .env file based on .env.example")
        exit(1)
