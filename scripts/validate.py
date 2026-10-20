#!/usr/bin/env python3
"""Validate skill frontmatter and the landing page's toolkit count (PyYAML required)."""

from pathlib import Path
import re
import sys

import yaml


def main():
    root = Path(__file__).resolve().parents[1]
    errors = []
    skills = sorted((root / "skills").rglob("SKILL.md"))
    if not skills:
        errors.append("skills: no SKILL.md files found")
    for path in skills:
        try:
            match = re.match(r"\A---\r?\n(.*?)\r?\n---(?:\r?\n|\Z)", path.read_text(), re.S)
            if not match:
                raise ValueError("missing YAML frontmatter delimiters")
            metadata = yaml.safe_load(match[1])
            for field in ("name", "description"):
                value = metadata.get(field) if isinstance(metadata, dict) else None
                if not isinstance(value, str) or not value.strip():
                    raise ValueError(f"frontmatter requires a nonempty {field} string")
        except (OSError, ValueError, yaml.YAMLError) as error:
            errors.append(f"{path.relative_to(root)}: {error}")

    try:
        html = (root / "index.html").read_text()
        band = re.search(r'<div class="band"[^>]*>(.*?)</div>', html, re.S)
        badges = re.findall(r"<span>(\d+) tools</span>", band[1] if band else "")
        if len(badges) != 1:
            raise ValueError("index.html: expected exactly one tools badge in the band")
        readme = (root / "toolkit/README.md").read_text()
        table = re.search(
            r"^\| Tool \| What it does \| Install \|\n\| --- \| --- \| --- \|\n((?:\|[^\n]+(?:\n|$))+)",
            readme,
            re.M,
        )
        if not table:
            raise ValueError("toolkit/README.md: tool table not found")
        entries = table[1].splitlines()
        if not all(re.match(r"^\| \[[^\]]+\]\([^)]+\) \|", row) for row in entries):
            raise ValueError("toolkit/README.md: invalid tool table entry")
        tool_count = len(entries)
        if int(badges[0]) != tool_count:
            raise ValueError(f"index.html: badge says {badges[0]} tools; toolkit/README.md lists {tool_count}")
    except (OSError, ValueError) as error:
        errors.append(str(error))

    if errors:
        print("\n".join(f"ERROR: {error}" for error in errors), file=sys.stderr)
        return 1
    print(f"PASS: {len(skills)} skill frontmatters; toolkit badge matches {tool_count} entries")
    return 0


if __name__ == "__main__":
    sys.exit(main())
