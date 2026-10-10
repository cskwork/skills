# Prompting UI images

Goal: a functional, current-generation product screen, not a dribbble shot. "Modern" means the finish of the best products in the category today (precise grid, real type scale, tinted neutrals, keyboard and inline affordances), not a saturated look every model ships.

## Surface modes

Pick the mode from the screen, not the product (a tool's landing page is Persuade).

- **Operate** (admin, dashboards, app screens, editors, settings): the user completes a task. It must first read as a working product of its category. The direction lends only type, palette, density, and one signature move; navigation and controls stay standard (tabs, inputs, selects, tables with sortable headers, buttons). Color does real jobs: a colored shell (rail, header, tinted ground), states, selection, data series. A grey screen with one accent is the category default, not restraint. Show realistic data with plausible values and units and one state worth seeing.
- **Persuade** (landing, marketing, pricing): the visitor decides and acts. One dominant visual move, real offer copy, a clear action, a glimpse of what follows. Bolder color strategies are allowed. Body text at real reading size.
- **Read** (docs, articles, help): structure for comprehension; comfortable measure, clear heading scale, navigation that orients.
- **Experience** (portfolio, gallery, showcase): the work leads from the first viewport; the interface recedes.
- **Game** (title, HUD, inventory, shop, result): the game world owns the art; HUD and menus stay legible at play size, with clear touch or click targets, readable numbers, and one focal element per screen. Painted art is a raster asset; text and controls are code.

## Before prompting, decide (write into brief.md)

1. **Job:** the one thing the user must do on this screen, and the primary action that does it.
2. **Read order:** what is seen 1st, 2nd, 3rd.
3. **Scene sentence:** who, where, what light. It decides light or dark.
4. **Direction (shared by all three options):** color strategy (Restrained: tinted neutrals + one accent that does jobs; Committed: one saturated color owns 30-60% of the surface; Full palette: 3-4 named roles), palette with roles and hex (shell, ground, surface, text, secondary text, accent, state colors), type character and size steps in px, radius, 8px spacing grid, density, icon style, depth (hairline borders or soft offset shadows).
5. **Signature move:** one concrete, named, visible moment (where and how). A direction that is only a color scheme has no move yet.
6. **Calibration check:** generated UIs cluster around a few looks: warm cream + serif display + terracotta/red accent; near-black + one neon + glow; editorial hairlines + italic serif + small mono labels; purple gradient, aurora blobs, glass. If the direction lands in one and the brief did not pin it, rework it. If someone could guess the look from the category alone, rework it.

## Prompt blocks, in this order

```
FRAME     High-fidelity UI design of <product>'s <screen>, <platform>, <aspect> <orientation>.
          The app screen itself, edge to edge: no browser window, no device frame, no desk.
BAR       Finish on par with the best current <category> products: aligned grid, consistent
          spacing, a real type scale, clear hierarchy. Standard controls a user already knows.
SHELL     Navigation model and regions in reading order with widths or heights in %.
JOB       The main job, the primary action and where it sits, what reads first/second/third,
          the keyboard or inline affordance (e.g. "⌘K", "Enter로 추가", inline edit).
CONTENT   Real strings and data per region, quoted. Counts must agree with the items shown.
          Short labels; no lorem ipsum.
STATE     One state worth seeing: selected item, overdue, inline edit open, drag in progress,
          empty column, error with recovery, undo toast.
DIRECTION Palette roles with hex, type character + sizes, radius, spacing, density,
          light/dark (from the scene), icon set (one outline style, one stroke weight), depth.
SIGNATURE The signature move, where it appears, and that it is the only loud element.
EXCLUDE   Nothing not listed in CONTENT (no avatars, bells, promo banners, extra features).
          No colored left stripe on cards or rows, no progress rings or sparklines as
          decoration, no eyebrow labels above headings, no gradient text, no glass, no emoji
          icons, no nested cards, no same-size icon cards as page structure, no pure
          #000/#fff, no centered-everything layout.
```

Varying the three: keep DIRECTION and SIGNATURE identical; change SHELL and JOB framing (navigation model, how work areas divide the screen, which data leads, density, where the signature move sits). Each must look different at thumbnail size. A variant that only adds ornament adds no choice.

## Korean and dense text

Short Korean strings render well; long sentences garble. Keep each string under ~15 characters, quote it exactly, and expect the implementation to use the brief's copy, not the image's.

## Review each render

- Covering the name, it reads as a working product of its category (Operate) or as the page itself (Persuade), never as a poster or a photo with text.
- The primary action is the most findable thing; read order matches the plan.
- The signature move is visible and is the only loud element.
- Nothing from EXCLUDE appeared; counts agree; no invented features.

Regenerate once with the failing block restated; report if it fails again.
