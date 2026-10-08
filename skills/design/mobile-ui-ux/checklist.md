# Pre-ship checklist

Mark each item pass / fail / n/a with evidence (screenshot or test name). Fix fails before scoring.

## 1. Devices and sizes to capture

- [ ] Smallest supported device (default iPhone SE 3rd gen, 375 x 667 pt, @2x).
- [ ] A mid device (6.1" class, 393 x 852 pt, @3x).
- [ ] Largest supported device (Pro Max class, 440 x 956 pt, @3x).
- [ ] Each supported orientation; for landscape games, Dynamic Island on the left and on the right.
- [ ] iPad only if the app ships on iPad (4:3, Stage Manager window sizes).
- [ ] Web: 320, 375, 393, 440 CSS px wide; iOS Safari with toolbar shown and hidden; standalone PWA if installable.

## 2. Languages

- [ ] Every shipped language on the screen with the most text, at the smallest device.
- [ ] Longest strings tested (pseudo-localization with +40% length if available).
- [ ] Korean: no mid-word wraps (LOC-1); line height OK.

## 3. Accessibility settings

- [ ] Largest Dynamic Type size the app supports (apps), or in-game text size 200% (games).
- [ ] Bold Text on.
- [ ] Reduce Motion on: transitions fade, no shake, banners fade only.
- [ ] Reduce Transparency and Increase Contrast on (Liquid Glass and materials still legible).
- [ ] Dark mode and light mode (apps that support both).
- [ ] VoiceOver: each primary screen navigable, labels meaningful, order logical.
- [ ] Grayscale screenshot: no meaning lost (C-4).
- [ ] Haptics off and sound off: everything still understandable.

## 4. Measurements

- [ ] Smallest text measured in pt at the smallest device >= 11 pt (TY-1).
- [ ] Smallest tap target measured >= 44 pt (T-1); list the exceptions with reason.
- [ ] Contrast checked with a tool on the real screenshot for: body text, smallest text, hint text, error text, text over art (C-1, C-2).
- [ ] Safe-area: nothing interactive inside insets (L-1).
- [ ] Sheets: all four edges visible at the smallest device (L-10).

## 5. States

- [ ] Empty, loading, error, offline, limit-reached, success (S-1..S-7).
- [ ] Games: prep, mid-combat (busiest moment), result, mid-drag, invalid drop, settings open in match.
- [ ] One frame strip (3 to 5 frames) of the busiest transition.

## 6. Automated layout tests (add where the UI is code-driven)

Suggested tests; name them so they run in CI or a pre-commit hook:

- [ ] **Label overlap:** collect the screen rects of all visible labels and interactive nodes per screen, per language, per device size; fail if any two intersect (allow an explicit decorative list).
- [ ] **Minimum target:** fail if any interactive node's hit rect is < 44 x 44 pt at the smallest device (allow-list for 28 pt menu icons with reason).
- [ ] **Minimum font:** fail if any rendered text is < 11 pt at the smallest device (convert px to pt by device scale).
- [ ] **Safe area:** fail if any interactive node intersects the unsafe insets.
- [ ] **Clipping:** fail if a label's text is wider than its container without ellipsis or an overflow cue.
- [ ] **Korean word wrap:** for every Korean string that wraps, fail if any line break falls between two Hangul syllables of the same word.
- [ ] **Sibling size:** fail if labels of the same role render at different font sizes (auto-shrink drift).
- [ ] **Screenshot regression:** golden screenshots for each primary screen at the smallest and largest device per language.
- [ ] Web: Lighthouse mobile (performance, accessibility) and axe-core in CI.

Tools: XCUITest (`frame`, `isHittable`), SwiftUI previews at multiple sizes, Godot/Unity scene-tree walkers that read global rects, Playwright with device emulation for web.

## 7. Before committing a release candidate

- [ ] Rubric scored; bar met by an independent judge (not self-score) for release candidates.
- [ ] Score sheet and screenshots saved in the project (path in the commit message).
- [ ] Unchecked items listed in the commit message or the project's readiness doc.
