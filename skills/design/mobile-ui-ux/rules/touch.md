# Touch and ergonomics

**(floor)** = cannot be relaxed by an override. Source keys resolve in `references.md`.

## Rules

**T-1 Target size (floor).** Every tappable control has a hit area >= 44 x 44 pt. The visible shape may be smaller if the hit area is padded. Apple's absolute minimum of 28 x 28 pt is allowed only for rarely used, non-time-critical controls (menu icons in a game's top bar), and never for anything used during play or in a list row. Web: >= 44 x 44 CSS px by default; 24 x 24 CSS px is the WCAG AA legal floor, not a design target. `[HIG-A11y]` `[HIG-GameCtl]` `[WCAG-2.5.8]` `[M3]`

**T-2 Spacing between targets.** About 12 pt padding around bezeled (boxed) controls, about 24 pt around unbezeled ones (icons, text links). Minimum 8 pt between any two hit areas. `[HIG-A11y]` `[M3]` `[NNG-Touch]`

**T-3 Rows and tiles.** List rows, inventory tiles, bench slots, and standings rows are >= 44 pt tall at the smallest device. If they cannot fit, show fewer (L-8), do not shrink. `[Field]`

**T-4 Edge and corner targets are bigger.** Accuracy is best at the center of the screen and worst at the edges and corners. Targets in the outer 15% of the screen or in corners get >= 48 pt hit areas, or extra padding toward the edge. `[Hoober-Fingers]`

**T-5 Thumb reach.** About half of phone use is one-handed and most of the rest is cradled or two-thumbed; grips change every few seconds. Primary and frequent actions go in the bottom half (portrait) or the lower left and right thirds (landscape, two thumbs). Rare and destructive actions, menus, and settings go at the top. `[Hoober-Hold]` `[HIG-GameCtl]`

**T-6 Fitts's law.** The more frequent or time-critical an action, the larger and closer it is. The primary action of a screen is the largest tappable element in its zone. `[LawsUX-Fitts]`

**T-7 Gesture alternatives (floor).** Every swipe, drag, long-press, or multi-finger gesture has a visible single-tap alternative that reaches the same result (button, tap-then-tap, menu). `[HIG-A11y]` `[WCAG-2.5.7]`

**T-8 Simple gestures for frequent actions.** Frequent actions use tap or single-finger drag. No multi-finger or simultaneous-press requirements; hold-to-act has a toggle alternative. `[HIG-A11y]` `[GAG]`

**T-9 Do not fight system gestures.** Keep the left-edge back swipe on navigation stacks and the bottom home-indicator swipe working. In full-screen games, use deferred system gestures (edge protection) only on edges where play actually happens. `[HIG-Layout]` `[HIG-GameCtl]`

**T-10 Destructive actions are far from common ones.** A destructive action (sell, delete, leave match) is never adjacent to Close, Back, or Confirm. Put it on the opposite side or bottom-left, and make it hold-to-confirm, confirm dialog, or undoable. `[Field]` `[HIG-A11y]`

**T-11 Press feedback within 100 ms.** Every touch shows a visible pressed state that is visible around the finger (glow, scale, color shift larger than the fingertip), plus optional haptic. See F-1. `[HIG-GameCtl]`

**T-12 No hover dependence.** Touch has no hover. Any hover style must not stick after a tap; information shown on hover must also be available on tap or long-press. `[Field]`

**T-13 Accidental-tap protection.** Targets that appear under the finger after a transition (new screen, popup) ignore taps for ~150 to 250 ms after appearing, so a double-tap does not trigger them. `[NNG-Touch]`

## Anti-patterns

- 31 pt item tiles on the SE because the canvas was scaled down.
- Sell button next to Close.
- Swipe-to-delete with no Edit / Delete button.
- Drag-only equip with no tap path.
- Primary button in the top-right corner of a portrait app used one-handed.
