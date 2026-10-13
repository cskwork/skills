# Source and packaging

Source: https://github.com/epoko77-ai/im-not-ai
Version: 2.3.2
Commit: b37e0206d31fffd9149bf57168d4d62eb2086bee
Copied: 2026-10-14
License: MIT, Copyright (c) 2026 epoko77-ai; see LICENSE.

This standalone bundle uses the upstream Codex SKILL.md, shared references,
OpenAI interface metadata, and the nine runtime scripts listed in upstream
install.sh. References are real files; development launchers and repository
symlinks are not required.

Local changes: add version metadata and replace Codex-specific agent names
with generic agent wording so Claude Code, Codex, OpenCode, and Hermes can
share one installation; trim one trailing space in rewriting-playbook.md.
Routing, role contracts, thresholds, and scripts are unchanged. Agents without collaboration tools execute the roles
sequentially as the upstream skill specifies.
