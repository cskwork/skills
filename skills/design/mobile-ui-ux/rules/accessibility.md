# Accessibility

Many rules elsewhere are accessibility rules (T-1, T-7, TY-1, TY-4, C-1, C-4, F-7, F-13). This file adds what they do not cover. **(floor)** = cannot be relaxed by an override.

## Rules

**A-1 Labels for assistive tech (floor, apps and web).** Every interactive element has an accessible name that says what it does ("Sell unit", not "button 3"). Icon-only buttons included. Decorative images are hidden from VoiceOver. `[HIG-A11y]`

**A-2 Reading order.** VoiceOver / screen-reader order follows visual order: top to bottom, leading to trailing, primary content before chrome. Group related labels (title + value) into one element. `[HIG-A11y]`

**A-3 State is announced.** Selected, expanded, disabled, and value changes are exposed as traits or ARIA states, not just colors.

**A-4 Large text survives.** At the largest supported text size, nothing overlaps or clips; rows grow, horizontal layouts stack vertically. Only one scroll direction is needed to read any block. `[XAG-101]` `[WCAG-1.4.10]`

**A-5 Focus visible (web, keyboard, game controller).** A focused element is clearly visible (>= 3:1 focus indicator) and not hidden under sticky headers or overlays. `[WCAG-2.4.11]` `[WCAG-1.4.11]`

**A-6 No time pressure in menus.** Menus, dialogs, and reading text never time out. Time limits in gameplay can be extended or turned off in an assist option where the design allows. `[HIG-A11y]` `[GAG]`

**A-7 Simple language.** Short sentences, common words, one idea per sentence in instructions and errors. `[GAG]` `[Hodent]`

**A-8 Captions.** Speech and important sounds have captions or a visual equivalent; captions are on or offered before the first line of speech. `[GAG]`

**A-9 Settings persist.** Accessibility and comfort settings (text size, haptics, motion, contrast, volumes) are saved and restored on next launch. `[GAG]`

**A-10 Game assists (games).** Offer difficulty or speed options and at least one way to practice without failure. Surface accessibility options in the first-run flow or the main settings, not buried. `[HIG-A11y]` `[GAG]`

**A-11 Test with the real tools.** VoiceOver on a device, Accessibility Inspector (Xcode) audit, largest Dynamic Type size, Bold Text, Reduce Motion, Reduce Transparency, Increase Contrast, and grayscale for C-4.
