# Layout and safe areas

Source keys in `[brackets]` resolve in `references.md`. `[Field]` = lesson from a real independent-judge review cycle on a shipped mobile game. **(floor)** = cannot be relaxed by an override.

## Rules

**L-1 Safe area (floor).** No control, text, or essential game element inside the unsafe insets: status bar, Dynamic Island or notch, home indicator, rounded corners. Backgrounds and art may bleed under them. `[HIG-Layout]` `[HIG-GameCtl]`

**L-2 Edge margins.** Content inset at least 16 pt from the safe-area edge on phones (20 pt on Pro Max widths). Floating panels and sheets keep >= 16 pt from every safe-area edge. `[HIG-Layout]` `[Field]`

**L-3 Spacing scale.** Use one 4 pt based scale (4, 8, 12, 16, 24, 32, 48). Related items 4 to 8 pt apart, groups 16 to 24 pt apart. Proximity defines grouping, so unrelated items never sit closer than related ones. `[LawsUX-Proximity]`

**L-4 Size classes, not devices.** Decide layout from available width and height (compact or regular), not from model name or orientation. A landscape-only game still has to fit 16:9 (SE), 19.5:9 (modern iPhone) and 4:3 (iPad, if supported). `[HIG-Layout]` `[HIG-Games]`

**L-5 Design at the smallest device first.** Lay out at 375 x 667 pt (SE) first, then check that large devices fill sensibly. Large devices must not leave a large dead zone: if the primary content uses less than ~60% of the available width on a large device while a smaller one uses more, the framing is wrong. `[Field]`

**L-6 Points, not pixels (floor).** All sizes in this skill are iOS points (CSS px on web). On a canvas or game engine, convert: pt = rendered px / device scale (2 on SE, 3 on Pro). A fixed-resolution canvas that is stretched to fit makes every UI element smaller on @2x small phones; size UI from the device's point size, not the design canvas. `[Field]`

**L-7 Never shrink below floors to fit.** Auto-shrink text and scale-to-fit containers are allowed down to the floors (TY-1, T-1) and no further. `[Field]`

**L-8 Overflow is visible.** When a list or panel cannot show everything, show the rows that fit fully plus a cue: a "+N more" row, a bottom fade with a scroll affordance, or a "See all" link. Never clip a row, a count, or a label at a container edge without a cue. Rule of thumb on short screens: top 4 + the user's own row, the rest behind a tap. `[Field]`

**L-9 No overlap of interactive or informational elements.** Two labels, two bars, or a label and a button never overlap at any supported device or language. Decorative art can overlap. Add an automated label-overlap test where the layout is code-driven (see `checklist.md`). `[Field]`

**L-10 Sheets and dialogs fit the safe area.** A sheet, settings panel, or dialog has all four edges visible inside the safe area at the smallest device. Long content scrolls inside the panel with a fade mask; the close or primary button lives in a pinned footer or header inside the panel, never in the scrolling region. `[Field]` `[HIG-Layout]`

**L-11 Content fits without scrolling where it is a summary.** Detail cards that summarize one item (unit card, product card, profile header) fit without scrolling at every supported size. If they cannot, cut or collapse secondary content rather than scroll. `[Field]`

**L-12 Floating chrome stays off primary content.** Counters, pills, and status chips sit in a bar or beside the element they describe, not floating over the playfield or list content. `[Field]`

**L-13 Empty containers do not draw frames.** Empty slots that are not interactive in the current mode render as a thin strip or nothing, not heavy boxes. `[Field]`

**L-14 Readable line length.** Body text lines 30 to 75 characters for Latin scripts, up to ~40 characters for Korean/CJK. Use the system readable-content guide or a max-width. `[HIG-Layout]` `[XAG-101]`

**L-15 Orientation.** If the app supports rotation, every screen works in both. If locked (common for games), lock deliberately and still respect L-1 on both landscape sides (the island can be left or right). `[HIG-Games]`

**L-16 iPhone-only still means iPad (floor).** App Review installs iPhone-only apps on iPad and reviews them in iPhone compatibility mode (a scaled iPhone-size window inside the iPad screen), and rejects under Guideline 4 (Design) if the UI is "crowded, laid out, or displayed in a way that made it difficult to use". Treat that window as a supported size: run the shipped build on an iPad simulator (e.g. iPad Pro 11-inch) in compatibility mode, record the viewport, scale and safe-area insets the app actually receives there, and pass every floor rule (L-1, L-9, L-10, T-1, TY-1) at that size. Engines that compute their own canvas scale (Godot, Unity, web canvas) are most at risk: they can pick a different scale or aspect in the compatibility window than on any phone. If the app is universal, design the regular-width layout explicitly instead. `[AppReview-4]` `[Field]`

## Anti-patterns

- Layout built at Pro Max size and scaled down.
- Close button half outside the screen on the SE.
- A count ("2/4") hidden under a button with no cue that the list continues.
- A status pill floating over the game board.
- Using the full screen width for a paragraph on iPad or landscape.
- Testing only on iPhones because the app is iPhone-only; App Review still opens it on an iPad.
