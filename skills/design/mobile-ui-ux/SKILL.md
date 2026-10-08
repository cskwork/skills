---
name: mobile-ui-ux
description: Measurable usability and interaction rules for iPhone apps, mobile web, and mobile games, with a 7-category scoring rubric, an independent-judge prompt, and a pre-ship checklist. Use for any UI/UX design, review, or implementation work on an iPhone app, a mobile web page or PWA, or a mobile game (HUD, combat readability, drag-and-drop, onboarding, settings sheets). Also use when asked to score, judge, or QA a mobile interface, or to set up project UI/UX overrides. Pairs with impeccable, which owns aesthetic direction.
license: MIT
---

# mobile-ui-ux

Concrete rules for usable phone interfaces: sizes in pt, contrast ratios, durations, layout limits. Each rule has an ID (`T-3`, `G-12`) so reviews, overrides, and commit messages can point at it.

This skill answers "can a person on a small phone read it, reach it, understand it, and recover from mistakes?" It does not pick a visual style. For aesthetic direction, typography choice, palette, and critique of taste, use **impeccable**; then run this skill's rules and rubric on the result.

## When to use

- Designing or building any screen for an iPhone app, a mobile web page, or a mobile game.
- Reviewing screenshots or a running build for UI/UX quality.
- Scoring a build against a quality bar, or writing a prompt for an independent judge.
- Creating or editing a project's UI/UX overrides file.

Not for: backend work, store metadata copy, App Review compliance (see the workspace's release docs).

## Files

| File | Read when |
|---|---|
| `rules/layout.md` | Any screen. Safe areas, margins, grids, small-device fit, overflow. |
| `rules/touch.md` | Anything tappable or draggable. Target sizes, spacing, thumb reach, gestures. |
| `rules/typography.md` | Any text. Sizes, Dynamic Type, line length, truncation. |
| `rules/color.md` | Any color or contrast choice, dark mode, color-blind safety. |
| `rules/feedback-motion.md` | Press states, animation timing, haptics, sound, Reduce Motion. |
| `rules/navigation.md` | Screen structure, tab bars, sheets, back, destructive actions. |
| `rules/forms.md` | Text input, pickers, validation, keyboards. |
| `rules/states.md` | Empty, loading, error, offline, first-run states. |
| `rules/accessibility.md` | VoiceOver, Dynamic Type at large sizes, alternatives to gestures. |
| `rules/localization.md` | More than one language, or any Korean/CJK text. |
| `rules/performance.md` | Load time, input latency, frame rate as felt by the user. |
| `rules/web.md` | Mobile web or PWA: viewport, `env()`, `dvh`, input zoom. |
| `rules/games.md` | Any game: HUD, combat readability, damage numbers, drag-and-drop, FTUE. |
| `rubric.md` | Scoring a build; judge prompt template. |
| `checklist.md` | Before calling a UI done, before a release commit. |
| `CUSTOMIZE.md` | Setting up or reading project overrides. |
| `references.md` | Source for any rule; cite it when a rule is challenged. |

Load only the rule files the task touches. A settings screen in an app needs layout, touch, typography, color, navigation, forms. A game battle screen needs layout, touch, typography, color, feedback-motion, games.

## Workflow

### 1. Read project overrides

Look in the project root, in this order, and use the first that exists:

1. `.ui-ux.md`
2. `docs/ui-ux-overrides.md`
3. `DESIGN.md` section headed `## UI/UX overrides`

The file sets platform profile, smallest and largest supported device, languages, bar threshold, genre references, brand constraints, and rule exceptions. Format and defaults: `CUSTOMIZE.md`. If no file exists, use the defaults below and say so in one line of your output.

Defaults when no override exists:

- Smallest device: iPhone SE (3rd gen), 375 x 667 pt, @2x (1334 x 750 px landscape).
- Largest device: iPhone Pro Max class, 440 x 956 pt, @3x.
- Languages: the languages the project already ships. If it ships Korean, Korean is primary.
- Bar: every rubric category >= 4, average >= 4.3.
- Appearance: light and dark if the app supports both; games: whatever the game ships.

An override can relax a rule only with a stated reason. It can never relax rules marked **(floor)**: those are accessibility and legibility minimums.

### 2. Pick the platform profile

| Profile | Use for | Rule files always loaded |
|---|---|---|
| `app` | Native iPhone app (SwiftUI, UIKit, React Native, Flutter) | layout, touch, typography, color, navigation, states, accessibility |
| `web` | Mobile web page, web app, PWA | the `app` set + `web`, `performance` |
| `game` | Any game, any engine (Godot, Unity, SpriteKit, web canvas) | layout, touch, typography, color, feedback-motion, games, accessibility |

A game's menus, shop, and settings are app-like screens: apply navigation and forms rules there too.

### 3. Apply the rules while designing

- Design for the smallest device first. Fit there, then let the layout breathe on large devices. Never design at Pro Max size and shrink.
- Before placing any element, decide its priority (primary, secondary, tertiary). Primary content gets the center and the largest size; tertiary content can move behind a tap.
- Every tap target >= 44 x 44 pt (T-1). Every text >= 11 pt at the smallest device (TY-1). Both measured in points on the real device, not in canvas pixels.
- When something does not fit, follow L-8: show less and add an overflow cue, never shrink below floors or clip silently.
- Write the rule ID next to any decision that departs from a default, in code comments or the design note.

### 4. Self-check with the checklist

Walk `checklist.md` for the profile. Mark each item pass, fail, or n/a with the evidence (screenshot name, test name). A fail is fixed before scoring, not explained away.

### 5. Score with the rubric and iterate

- Score each of the 7 categories in `rubric.md` from 1 to 5 using its anchors.
- If any category is under the bar, list fixes in order of impact (largest score gain per effort first), fix them, recapture, rescore.
- For release candidates or when the owner asks for an independent review, send the judge prompt in `rubric.md` to a separate agent that has not seen the code or your reasoning: only screenshots, the rubric, and the bar. Your own score does not count as the gate.
- Stop when the bar is met. Do not keep polishing past the bar unless asked.

### 6. Capture evidence

Every review round produces screenshots, named `<screen>_<device>_<lang>_<state>.png`, for example `battle_se3_ko_mid_combat.png`.

Minimum set per round:

- Each primary screen at the smallest and the largest supported device.
- Each supported language on the screen with the most text.
- The states that rules call out: empty, loading, error, full/limit-reached, mid-drag, settings open.
- Games: prep, mid-combat, result, and one frame strip (3 to 5 frames) of the busiest transition.
- Accessibility pass: one shot at the largest Dynamic Type size the app supports (apps) and one with Reduce Motion on, if motion changes.

Record what was captured and on which build in the project's QA doc so the next round does not repeat it.

## Composing with impeccable

| Question | Skill |
|---|---|
| What should this feel like? Which typeface, palette, layout concept? | impeccable |
| Is this bold enough, too generic, on-brand? | impeccable |
| Can a person reach, read, and operate it on an SE? Is the HP bar readable? | mobile-ui-ux |
| Did it pass the bar? | mobile-ui-ux rubric |

Typical order: impeccable sets direction and builds; mobile-ui-ux rules constrain the build; impeccable polishes; mobile-ui-ux scores. If the two disagree, rules marked **(floor)** win; otherwise the project override decides; otherwise impeccable owns look and this skill owns usability.

## Output format for reviews

```
Profile: game · Smallest device: iPhone SE 3 (override: none) · Bar: all >= 4, avg >= 4.3
Scores: hierarchy 4 · primary screen 3.5 · HUD 4 · core interaction 3.5 · touch 3 · polish 4 · l10n 3.5 → avg 3.64 FAIL
Fixes in order of impact:
1. [G-4, L-3] HP bars merge in packed rows (battle_se3_ko_mid_combat.png): cap bar at 80% of cell width, 4 pt gap, 1 pt outline.
2. ...
Evidence gaps: equip_full_error state not captured.
```

Each fix names the rule ID, the screenshot, and a concrete change with numbers.
