# Build floor

Checks on the built UI, run together in the one verify round. The reference image and brief override anything here; habit does not.

- **Contrast:** body and placeholder text ≥ 4.5:1, large text ≥ 3:1. Secondary text on colored surfaces is tinted from that hue, not grey.
- **States:** default, hover, focus-visible, active, disabled, loading, empty, error. Every interactive element has a visible keyboard focus ring.
- **Targets:** at least 24×24 px on desktop, 44×44 px on touch.
- **Feedback:** destructive actions offer undo (toast) rather than a confirm dialog unless loss is unrecoverable. Errors name the problem and the fix.
- **Type:** a real scale with obvious steps; body measure 65-75ch; tabular numerals for times, counts, and money; nothing overflows with the real copy.
- **Spacing:** 8px grid; tight within groups, generous between them; more space above a heading than below.
- **Depth:** shadows have offset and soft blur; no zero-offset colored glow.
- **Browser surfaces:** theme text selection, caret, focus rings, scrollbars, and underline offset from the palette.
- **Icons:** one library or authored SVG, one stroke weight; never emoji or unicode glyphs as icons.
- **Fonts:** load the face matching the reference's type character (e.g. Pretendard for Korean UI); not the system fallback.
- **Motion:** one purposeful moment (often the signature move); ease-out; respect `prefers-reduced-motion`.
- **Refuse:** the EXCLUDE list in prompting.md applies to the build too.
