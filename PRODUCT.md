# Product

<!-- impeccable:product-schema 1 -->

> Inferred from the owner's brief on 2026-10-05; no interview tool was available in that session. Items marked (inferred) were not confirmed by the owner.

## Platform

web

## Stack

Static HTML/CSS in one file, served by GitHub Pages from the repository root. No build step, no external JavaScript (owner's brief: works from a fresh clone).

## Users

Developers who run coding agents (Claude Code, Codex, and similar) and want a working set of skills, a system prompt, and the CLIs around them. They arrive from GitHub or a shared link and decide in seconds whether to install. (inferred: audience mirrors mattpocock/skills, which the owner named as the model.)

## Product Purpose

cskwork/skills publishes the skills, system prompt (AGENTS.md), and CLI toolkit the owner uses every day. Success: a visitor installs with `npx skills@latest add cskwork/skills`, picks the skills they want, or copies the system prompt.

## Positioning

A personal, working daily kit rather than a catalog: one operating contract (AGENTS.md) plus a small set of skills that fit it, each credited to its upstream source with the exact commit copied.

## Capabilities and Constraints

- 13 installable skills in four groups: engineering, productivity, design, agents.
- 3 skills from their own home: verify (Claude Code's bundled `/verify`), ego-browser (ego lite app), and hindsight (hindsight-agent-setup).
- System prompt: `system-prompt/AGENTS.md`, source of truth cskwork/THE-SYSTEM-PROMPT.
- Toolkit: claude-hud, claude-swap, codex-auth, firebase, gws, herdr, hermes, jk.
- Third-party skills keep their own license; sources and commits are listed in THIRD_PARTY.md.

## Brand Commitments

None stated. Owner GitHub handle: cskwork.

## Evidence on Hand

README.md, THIRD_PARTY.md, toolkit/README.md, and each skill's SKILL.md. No testimonials, user counts, stars, or benchmarks exist; do not invent them.

## Product Principles

- Credit every borrowed skill to its author, visibly.
- Installation first: the command is the product.
- Small and composable over comprehensive. (inferred)

## Accessibility & Inclusion

No product-specific requirement established; meet WCAG 2.2 AA.
