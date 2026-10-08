# Customizing mobile-ui-ux

Two ways to customize:

1. **Per project (recommended):** add an overrides file to the project. The skill reads it at step 1 of the workflow. Nothing in the skill changes.
2. **For yourself, everywhere:** edit the rule files in this skill folder (your own fork or local copy). Keep rule IDs stable; add new rules at the end of a file with the next number.

## Overrides file

Location, first match wins:

1. `<project root>/.ui-ux.md`
2. `<project root>/docs/ui-ux-overrides.md`
3. A `## UI/UX overrides` section in `<project root>/DESIGN.md`

Format: Markdown with one YAML block at the top, followed by free-text notes. Every key is optional; missing keys use the defaults in the table below.

| Key | Meaning | Default |
|---|---|---|
| `profile` | `app`, `web`, or `game` (list for hybrids, e.g. `[game, web]`) | inferred from the project |
| `smallest_device` | Name and size in pt | `iPhone SE 3, 375x667, @2x` |
| `largest_device` | Name and size in pt | `iPhone Pro Max, 440x956, @3x` |
| `orientation` | `portrait`, `landscape`, `both` | what the project ships |
| `languages` | Shipped languages, primary first | what the project ships |
| `appearance` | `light`, `dark`, `both` | what the project ships |
| `bar.min_category` | Minimum score per rubric category | `4` |
| `bar.min_average` | Minimum average | `4.3` |
| `bar.judge` | `self` or `independent` for release gates | `independent` |
| `genre_references` | Apps or games to compare against (G-30, rubric 6) | none |
| `brand` | Short notes: tint color, typefaces, tone, pen name | none |
| `extra_rules` | Project-specific rules, with IDs `P-1`, `P-2`, ... | none |
| `exceptions` | List of `{rule, scope, reason}` that relax a rule | none |
| `evidence_dir` | Where screenshots and score sheets go | `docs/ux/` |

### Exceptions

- Each exception names the rule ID, where it applies, and why.
- Rules marked **(floor)** cannot be relaxed. The skill ignores such an exception and reports it.
- An exception without a reason is ignored.

## Example: landscape mobile game

~~~markdown
# UI/UX overrides

```yaml
profile: game
smallest_device: iPhone SE 3, 667x375 (landscape), @2x
largest_device: iPhone 17 Pro Max, 956x440 (landscape), @3x
orientation: landscape
languages: [ko, en]
appearance: dark
bar:
  min_category: 4
  min_average: 4.3
  judge: independent
genre_references:
  - Teamfight Tactics (mobile)
  - Hearthstone Battlegrounds (mobile)
brand:
  tint: "#E0B04A"
  display_font: custom serif for titles only; system font for UI
  copyright_name: pen name only
extra_rules:
  - id: P-1
    rule: Gold and HP always visible in the top bar during every phase.
  - id: P-2
    rule: Shop opens automatically at round start and never covers the bench.
exceptions:
  - rule: T-4
    scope: top-bar menu and settings icons in the corners
    reason: rarely used, not time-critical; 44 pt hit areas instead of 48 pt, padded toward screen center
  - rule: L-14
    scope: lore text in codex
    reason: allow up to 45 Korean characters per line for a book-like feel
evidence_dir: docs/ux/
```

Notes: Korean is primary; English must fit without shrinking. Judges get Korean screenshots first.
~~~

## Example: iPhone productivity app

```yaml
profile: app
languages: [ko, en]
appearance: both
bar: { min_category: 4, min_average: 4.5, judge: independent }
genre_references: [Apple Reminders, Things 3]
exceptions:
  - rule: N-2
    scope: Today tab badge
    reason: badge shows overdue count only
```

## How the skill uses the file

- Reports in one line which file it used (or "no overrides, defaults").
- Uses `smallest_device` and `largest_device` for every size check and screenshot set.
- Scores against `bar`; uses `genre_references` in rubric category 6 and G-30.
- Applies `extra_rules` alongside the built-in rules and cites their IDs.
- Lists applied exceptions in every review output so a reader can see what was relaxed.
