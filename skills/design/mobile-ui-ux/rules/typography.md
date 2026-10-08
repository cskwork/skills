# Typography and readability

**(floor)** = cannot be relaxed by an override.

## Rules

**TY-1 Minimum size (floor).** No text under 11 pt on iPhone at the smallest supported device, including game HUD labels, badges, sub-lines, and odds rows. Default body text is 17 pt. Thin or light weights need larger sizes. `[HIG-A11y]` `[HIG-Games]`

**TY-2 Web input size (floor).** Text in `input`, `textarea`, and `select` is >= 16 CSS px, or iOS Safari zooms the page on focus and stays zoomed. `[InputZoom]`

**TY-3 Type scale.** Use a small set of sizes with clear steps (for example 11, 13, 15, 17, 20, 28, 34 pt, matching iOS text styles). At most 4 sizes on one screen. Hierarchy comes from size and weight together, not color alone. `[HIG-Typography]`

**TY-4 Dynamic Type (apps).** Native apps use system text styles so text follows the user's size setting. Layouts work up to at least the largest standard size; text can grow to 200% without losing content or function. Games: offer an in-game text size option (at least 100%, 150%, 200%) or follow the system setting. `[HIG-A11y]` `[XAG-101]` `[HIG-Games]`

**TY-5 One fixed size per role.** All labels with the same role (all trait names, all list titles) share one size. Per-label auto-shrink that gives sibling labels different sizes is not allowed; use ellipsis or a 2-line wrap instead. `[Field]`

**TY-6 Truncation order.** When text is too long: (1) wrap to 2 lines if the role allows, (2) ellipsize at the end, (3) use a shorter approved string. Never clip mid-glyph, never truncate numbers or counts, never truncate the only distinguishing part of a label. Provide the full text on tap or long-press where truncation hides meaning. `[Field]` `[XAG-101]`

**TY-7 Numbers.** Use tabular (monospaced) figures for counters, timers, scores, and columns that update or align. Right-align numeric columns in a fixed-width column so names never collide with counts. `[Field]`

**TY-8 Line height and spacing.** Body line height 1.3 to 1.5 x the font size (Korean 1.5 to 1.7). Text must survive WCAG text-spacing overrides on web (line height 1.5, letter 0.12 em, word 0.16 em) without clipping. `[WCAG-1.4.12]` `[XAG-101]`

**TY-9 Text over imagery.** Text on art, video, or a busy game scene gets a solid or semi-opaque plate, or a 1 to 2 pt dark outline/shadow, so it meets C-1 against the worst-case background pixel. `[XAG-102]`

**TY-10 Case.** Sentence case for sentences and buttons; title case or sentence case for labels, but consistent per role across the app. No all-caps body text. `[XAG-101]` `[Field]`

**TY-11 Alignment.** Body text left-aligned (or right in RTL). Center only short headings, single-line buttons, and banners. No full justification on phones. `[XAG-101]`

**TY-12 Fonts.** System font (SF Pro, Apple SD Gothic Neo for Korean) for UI by default. A display face for titles and branding is fine. Any custom font must contain full glyph sets for every shipped language (Korean Hangul syllables included) so nothing falls back mid-string. `[HIG-Typography]` `[XAG-101]`

**TY-13 Icon and glyph text.** Text inside icons, badges, and button glyphs meets TY-1 too. `[XAG-101]`

## Anti-patterns

- 8 pt standings sub-lines on the SE.
- "Long Faction Name" auto-shrunk to 9 pt while "Plague" stays 13 pt.
- Thin 300-weight 12 pt grey text on a photo.
- Mixing "field 3/3" and "Items" capitalisation on one screen.
