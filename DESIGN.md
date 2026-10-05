---
name: cskwork/skills
description: A daily kit of agent skills, a system prompt, and CLIs, pressed and credited like a record.
colors:
  ultramarine: "#1f3bd6"
  signal-yellow: "#ffd23f"
  press-black: "#111114"
  paper: "#f7f7f5"
  sleeve-white: "#ffffff"
  sleeve-ink: "#c9d2ff"
  graphite: "#4a4a55"
  hairline: "#d5d5da"
  night-rule: "#3a3a44"
  night-text: "#c4c4cc"
typography:
  display:
    fontFamily: "Archivo, Helvetica Neue, Arial, sans-serif"
    fontSize: "calc(var(--sleeve) * .372)"
    fontWeight: 900
    lineHeight: 0.78
    letterSpacing: "-0.03em"
    fontVariation: "'wdth' 62"
  headline:
    fontFamily: "Archivo, Helvetica Neue, Arial, sans-serif"
    fontSize: "clamp(3rem, 9vw, 6rem)"
    fontWeight: 900
    lineHeight: 0.82
    letterSpacing: "-0.02em"
    fontVariation: "'wdth' 62"
  lede:
    fontFamily: "Archivo, Helvetica Neue, Arial, sans-serif"
    fontSize: "clamp(2rem, 3.6vw, 3.4rem)"
    fontWeight: 800
    lineHeight: 0.95
    letterSpacing: "-0.01em"
    fontVariation: "'wdth' 72"
  title:
    fontFamily: "Archivo, Helvetica Neue, Arial, sans-serif"
    fontSize: "1.5rem"
    fontWeight: 800
    lineHeight: 1
    letterSpacing: "0.02em"
    fontVariation: "'wdth' 75"
  track:
    fontFamily: "Archivo, Helvetica Neue, Arial, sans-serif"
    fontSize: "1.125rem"
    fontWeight: 700
    lineHeight: 1.55
    fontVariation: "'wdth' 90"
  body:
    fontFamily: "Archivo, Helvetica Neue, Arial, sans-serif"
    fontSize: "1.0625rem"
    fontWeight: 400
    lineHeight: 1.55
  label:
    fontFamily: "Archivo, Helvetica Neue, Arial, sans-serif"
    fontSize: "0.8125rem"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "0.08em"
    fontVariation: "'wdth' 80"
  mono:
    fontFamily: "ui-monospace, SF Mono, Menlo, Consolas, Liberation Mono, monospace"
    fontSize: "0.8125rem"
    fontWeight: 400
    lineHeight: 1.4
    fontFeature: "'tnum' 1"
rounded:
  hairline: "2px"
  sm: "3px"
  md: "4px"
  sticker: "6px"
  disc: "50%"
spacing:
  gutter: "clamp(1.25rem, 4vw, 4rem)"
  section: "clamp(3.5rem, 8vw, 7rem)"
  row: "0.8rem"
  stack: "1rem"
components:
  button-primary:
    backgroundColor: "{colors.press-black}"
    textColor: "{colors.sleeve-white}"
    typography: "{typography.label}"
    rounded: "{rounded.sm}"
    padding: "0.8rem 1.1rem"
  button-primary-hover:
    backgroundColor: "{colors.ultramarine}"
    textColor: "{colors.sleeve-white}"
  button-outline:
    backgroundColor: "transparent"
    textColor: "{colors.press-black}"
    typography: "{typography.label}"
    rounded: "{rounded.sm}"
    padding: "0.8rem 1.1rem"
  button-outline-hover:
    backgroundColor: "{colors.press-black}"
    textColor: "{colors.sleeve-white}"
  command-bar:
    backgroundColor: "{colors.press-black}"
    textColor: "{colors.sleeve-white}"
    typography: "{typography.mono}"
    rounded: "{rounded.md}"
    padding: "0.6rem 0.7rem"
  copy-chip:
    backgroundColor: "{colors.sleeve-white}"
    textColor: "{colors.press-black}"
    typography: "{typography.label}"
    padding: "0 0.75rem"
  copy-chip-hover:
    backgroundColor: "{colors.signal-yellow}"
    textColor: "{colors.press-black}"
  sticker:
    backgroundColor: "{colors.signal-yellow}"
    textColor: "{colors.press-black}"
    rounded: "{rounded.sticker}"
    padding: "1rem 1.1rem 1.05rem"
  side-letter:
    backgroundColor: "{colors.ultramarine}"
    textColor: "{colors.sleeve-white}"
    rounded: "{rounded.disc}"
    size: "2.1rem"
  track-row:
    backgroundColor: "{colors.sleeve-white}"
    textColor: "{colors.press-black}"
    typography: "{typography.track}"
    padding: "0.8rem 0.25rem"
---

# Design System: cskwork/skills

## Overview

**Creative North Star: "Liner Notes"**

The site is a record you hold in your hands. The front sleeve is a flat field of ultramarine with one heavy, very narrow word set across it; a black disc slides halfway out of the sleeve and turns; a yellow shrink-wrap sticker sits crooked over the corner and carries the install command. Everything after the fold is the back of the sleeve: white board, black rules, small credit type, and numbered tracks that open into their notes.

Density is that of a printed back cover: many small facts (track numbers, authors, commit hashes, licenses) held in place by rules, not boxes. Personality comes from type width and weight contrast, not from decoration. Archivo does all the speaking, from 62% width at weight 900 for the giant words to normal width at 400 for reading text. Monospace is reserved for things you would find etched in the run-out groove: hashes, numbers, commands.

The system refuses the dark-terminal look common to developer tools, refuses card grids, and refuses serif or cream "editorial" warmth. It stays cool: ultramarine, ink-black, white board, and a single yellow.

**Key Characteristics:**
- Full-bleed colour blocks per section (paper, white, ultramarine, black) instead of cards.
- One condensed variable grotesk at extreme width and weight contrast; uppercase for everything that names.
- Ruled lists: heavy rule under a heading, medium rule on top of a list, hairlines between rows.
- Yellow is a signal, not a surface.
- Only physical objects (sleeve, disc, sticker) cast shadows; the printed page is flat.
- Motion is slow and physical, and stops entirely under reduced motion.

## Colors

A cool, high-contrast press palette: one saturated blue, one signal yellow, near-black ink, and white board.

### Primary
- **Ultramarine** (#1f3bd6): the front-sleeve field, the liner-notes section background, the side-letter discs, track numbers, commit hashes and matrix links, the expand icon, and the primary button's hover. White text sits on it at roughly 8:1.

### Secondary
- **Signal Yellow** (#ffd23f): the shrink-wrap sticker, the copy chip on hover and after a successful copy, the focus ring, text selection, the disc's centre label, pull-quote marks and the drop cap on blue, credit-name hover and license lines on black. Never a section background.

### Neutral
- **Press Black** (#111114): body text, all rules on light ground, the command bar, the primary button, the sleeve's stat band, the credits section background.
- **Paper** (#f7f7f5): page ground for the hero and the toolkit section. A neutral off-white, not cream.
- **Sleeve White** (#ffffff): the tracklist board, text on blue and black, the copy chip at rest.
- **Sleeve Ink** (#c9d2ff): secondary text printed on ultramarine (the sleeve's small lines, section intros on blue).
- **Graphite** (#4a4a55): secondary text on light ground: section intros, authors, toolkit row labels, the matrix line.
- **Hairline** (#d5d5da): 1px separators between track rows and toolkit rows on light ground.
- **Night Rule** (#3a3a44): 1px separators on black.
- **Night Text** (#c4c4cc): secondary text and links on black.

### Named Rules
**The One Sticker Rule.** Yellow marks the thing to act on or the thing in focus. It never fills an area larger than the sticker, and it never appears as decoration on white ground.

**The Ink-On-Board Rule.** Every surface is one of four solid grounds (paper, white, ultramarine, black). No gradients on page surfaces; the only gradients in the system draw the vinyl disc.

## Typography

**Display Font:** Archivo variable, self-hosted (with Helvetica Neue, Arial fallback)
**Body Font:** Archivo variable, same file, normal width
**Label/Mono Font:** system monospace stack (ui-monospace, SF Mono, Menlo, Consolas)

**Character:** One grotesk stretched across its whole width axis. Narrow and black for anything that names; normal width and regular weight for anything you read. The width axis (62% to 100%) is the hierarchy, as much as size is.

### Hierarchy
- **Display** (900, 62% width, sized to 37% of the sleeve, line-height 0.78, uppercase): the one word on the front sleeve. Fills the sleeve's width.
- **Headline** (900, 62% width, clamp(3rem, 9vw, 6rem), 0.82, uppercase): section titles, sitting on a heavy rule.
- **Lede** (800, 72% width, clamp(2rem, 3.6vw, 3.4rem), 0.95, uppercase): the hero pitch line. The liner pull quote uses the same voice slightly larger and narrower (900, 66%, up to 4.75rem).
- **Title** (800, 75% width, 1.5rem, uppercase): side headings in the tracklist. Credit and toolkit names use 900 at 72% width, 1.5 to 1.6rem.
- **Track** (700, 90% width, 1.125rem): track and bonus names, set in the skill's own lowercase.
- **Body** (400, 100% width, 1.0625rem, 1.55): reading text, held to 34ch in the hero and 62ch in track notes. The long essay drops to 0.9375rem at 1.6 in up to three ruled columns.
- **Label** (700, 80 to 85% width, 0.75 to 0.8125rem, 0.02 to 0.14em tracking, uppercase): nav links, buttons, the copy chip, stat band, toolkit row terms, track counts.
- **Mono** (0.75 to 0.8125rem, tabular numerals): track numbers, commit hashes, commands, license lines, the run-out line.

### Named Rules
**The Narrow-Heavy Rule.** Names are set narrow and heavy (weight 800 to 900, width 62 to 75%), uppercase. Reading text is never condensed. There is no serif anywhere and no second display face.

**The Run-Out Groove Rule.** Monospace is for machine facts only: hashes, numbers, commands, licenses. Never for headings or prose.

## Layout

Edge gutters are fluid (clamp(1.25rem, 4vw, 4rem)); sections are full-bleed colour bands with fluid vertical padding (clamp(3.5rem, 8vw, 7rem)). Every section opens with the same head: a giant headline on the left, a short intro capped at 30rem on the right, aligned to the bottom, with a 3px rule underneath.

The hero is a two-column grid whose first column is a square sleeve sized min(76vh, 47vw, 720px); everything on the sleeve (padding, small type, sticker position) scales from that one sleeve size. The disc pokes 44% of its width out of the sleeve, and the pitch column clears it.

The tracklist is two uneven columns (1.15fr / 1fr) of sides; the toolkit is a two-column definition list of ruled rows; credits are an auto-fit grid (min 15rem). Bonus tracks sit in a 2px dashed box, the one place a full border appears.

At 960px everything collapses to one column; the disc only pokes out 18% and the sticker moves to the sleeve's bottom edge. At 560px the nav keeps only the GitHub link, the sticker spans the sleeve width below it, track authors drop under the title, and commands stack above their copy chip.

## Elevation & Depth

The printed page is flat. Depth belongs only to the three physical objects of the record, and each casts a soft, downward, blurred shadow as if lying on a table. Sections, lists, buttons and command bars have no shadow.

### Shadow Vocabulary
- **Sleeve** (`box-shadow: 0 24px 50px -20px rgb(17 17 40 / .55), inset 0 0 0 1px rgb(255 255 255 / .06)`): the front sleeve, with a faint printed-board grain overlay.
- **Disc** (`box-shadow: 0 18px 40px -12px rgb(0 0 0 / .45)`): the vinyl.
- **Sticker** (`box-shadow: 0 10px 24px -8px rgb(0 0 0 / .45)`): the yellow sticker.

### Named Rules
**The Printed Object Rule.** A shadow means "this is a physical thing on the table." Only objects of the record (sleeve, disc, sticker) get one; interface elements never do.

## Shapes

Mostly square. The board, sleeve, section bands and rules have hard corners. Small interactive pieces get barely-softened corners (3px buttons and code chips, 4px command bar, 6px sticker). Circles are reserved for record things: the disc and the side-letter discs. The sticker is the only rotated element (-4deg, -2deg on phones). Rules carry the structure: 3px under section heads, 2px atop each list, 1px between rows.

## Components

### Buttons
Blunt, printed, uppercase.
- **Shape:** near-square (3px), 2px black border.
- **Primary:** black fill, white label (800 weight, 80% width, 0.875rem, 0.06em tracking), leading 1em line icon.
- **Hover / Focus:** primary turns ultramarine (fill and border); outline fills black with white text. Transitions run 0.2s on the shared ease-out curve. Focus everywhere is a 3px yellow outline with a 6px black halo.
- **Outline:** transparent fill, black border and text.

### Command Bar and Copy Chip
The system's most-repeated component: every install path ends in one.
- **Bar:** black, 4px corners, 2px black border, monospace command in white that wraps at word tokens rather than mid-word.
- **Copy chip:** flush white segment at the bar's right end, uppercase label with a copy icon. Hover turns it yellow; after a copy it stays yellow, swaps to a check icon and reads "Copied" for 1.8s, and announces the result to screen readers. On failure it selects the command for manual copying.
- **Phone:** the chip stacks under the command at full width.

### Sticker
Yellow, 6px corners, rotated, soft shadow. A short narrow-heavy uppercase line (900, 68% width, 1.35rem) above a command bar. It is the home of the primary install command.

### Tracklist Side and Track Row
- **Side heading:** an ultramarine circle holding the side letter, the side name in the Title style, and the track count right-aligned in small graphite label type.
- **Track row:** disclosure row on white with a hairline beneath: mono track number in ultramarine, track name, author in graphite with the commit hash in ultramarine mono, and a plus icon that turns 45deg into a close mark when open. Hover tints the row a faint blue (#eef0fb).
- **Open note:** indented under the title, a short description, a "Matrix" line (source repo@commit and the SKILL.md link), and the track's own command bar.

### Navigation
A plain top bar on paper: the repo name left, uppercase label links right (700, 85% width, 0.8125rem). Underline on hover only. No background, no sticky behaviour.

### Vinyl Disc (signature)
A black disc drawn with stacked radial gradients for grooves and a yellow centre label with two lines of narrow uppercase type. On load it slides out of the sleeve over 1.6s on an expo-out curve, and its label turns once every 14s. Both stop under reduced motion.

## Do's and Don'ts

### Do:
- **Do** give each section one solid ground (paper, white, ultramarine or black) and open it with the headline-plus-intro head over a 3px rule.
- **Do** set every name in Archivo at weight 800 to 900 and 62 to 75% width, uppercase; keep reading text at normal width and weight 400.
- **Do** end every install path in a command bar with a copy chip, and give it the copied/failed states and the screen-reader announcement.
- **Do** credit and date things the record way: track numbers, authors, and commit hashes in ultramarine monospace.
- **Do** keep focus as the 3px yellow outline with a black halo on every interactive element.
- **Do** stop every animation under prefers-reduced-motion.

### Don't:
- **Don't** use yellow as a section background or as decoration; it marks the action or the focus.
- **Don't** put list content in cards or boxes with shadows; use ruled rows.
- **Don't** cast a shadow from anything that is not a physical part of the record.
- **Don't** introduce a serif, a cream ground, or a second display family.
- **Don't** use a dark-terminal hero or a feature-card grid.
- **Don't** set prose or headings in monospace.
