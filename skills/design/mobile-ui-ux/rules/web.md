# Mobile web and PWA

Applies with the `web` profile, plus all `app` rules in CSS px.

## Rules

**W-1 Viewport.** `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">`. Never disable zoom (`user-scalable=no`, `maximum-scale=1`). `[MDN-viewport]` `[WCAG-1.4.4]`

**W-2 Safe-area insets.** With `viewport-fit=cover`, pad fixed headers, bottom bars, and floating buttons with `env(safe-area-inset-top|right|bottom|left)`, for example `padding-bottom: max(16px, env(safe-area-inset-bottom));`. `[MDN-env]`

**W-3 Viewport height.** Use `100dvh` (or `100svh` for layouts that must never be covered by browser chrome) instead of `100vh`, which is taller than the visible area on iOS Safari when the toolbar shows. `[MDN-length]` `[WebDev-Viewport]`

**W-4 Input zoom.** Inputs >= 16 px (TY-2). Do not "fix" zoom by disabling user zoom.

**W-5 Reflow.** Content works at 320 CSS px wide without horizontal scrolling (except maps, tables, games, and other content that needs two dimensions). `[WCAG-1.4.10]`

**W-6 Text resize.** Text can be zoomed to 200% without loss of content or function. Use `rem` for type. `[WCAG-1.4.4]`

**W-7 Tap behavior.** `touch-action: manipulation` on controls removes double-tap-zoom delay. No hover-only menus (T-12). `:hover` styles wrapped in `@media (hover: hover)` so they do not stick on touch.

**W-8 Reduced motion and color scheme.** Honor `prefers-reduced-motion` (F-7) and `prefers-color-scheme` (C-6). `[MDN-reduced-motion]`

**W-9 Fixed elements.** At most one fixed bar top and one bottom on phones; fixed elements must not cover focused fields when the keyboard opens. `[WCAG-2.4.11]`

**W-10 PWA basics (if installable).** Web app manifest with name, icons (incl. 180 px apple-touch-icon), `display: standalone`, theme and background colors matching the first screen; an offline fallback page; standalone mode still honors W-2. `[WebDev-PWA]`

**W-11 Landscape and notch.** In landscape, left/right safe-area insets apply; check both rotations.

**W-12 Canvas games on web.** Size the canvas to CSS px x `devicePixelRatio` for sharpness, lay out HUD in CSS px (L-6), and handle `visualViewport` resize when browser chrome appears.
