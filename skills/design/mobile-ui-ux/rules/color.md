# Color and contrast

**(floor)** = cannot be relaxed by an override.

## Rules

**C-1 Text contrast (floor).** Text up to 17 pt regular: >= 4.5:1 against its background. Text >= 18 pt, or bold at any size: >= 3:1. Measure against the lowest-contrast area behind the text (gradients, art, game scenes). Placeholder text in inputs: 4.5:1 too. `[HIG-A11y]` `[WCAG-1.4.3]` `[XAG-102]`

**C-2 Non-text contrast (floor).** Control boundaries, icons that carry meaning, focus rings, HP/progress bar fills against their track, and selection states: >= 3:1 against adjacent colors. `[WCAG-1.4.11]` `[XAG-102]`

**C-3 Disabled is still readable.** Disabled or locked labels: >= 3:1. Explain why something is disabled when it matters (locked until level 5). `[XAG-102]`

**C-4 Never color alone (floor).** Every color-coded meaning has a second channel: icon, shape, text, pattern, or position. Team colors, rarity, error/success, and ally/enemy all qualify. Avoid red-vs-green as the only distinction. `[HIG-Games]` `[GAG]` `[XAG-102]`

**C-5 Semantic colors.** One accent (tint) for interactive elements. Red reserved for destructive actions and errors, green for success, amber for warnings. Do not reuse the accent for decoration. `[HIG-A11y]`

**C-6 Dark mode (apps).** If the system supports dark mode, the app supports it or deliberately locks one appearance. Check C-1 and C-2 in both. Use system semantic colors where possible so Increase Contrast works. `[HIG-A11y]`

**C-7 Increase Contrast.** If default colors fall short anywhere, provide a higher-contrast variant when the system Increase Contrast setting is on. Games: offer a high-contrast option where UI reaches >= 7:1. `[HIG-A11y]` `[XAG-102]`

**C-8 Materials and Liquid Glass (iOS 26+).** Liquid Glass belongs to the control and navigation layer floating above content (tab bars, toolbars, sidebars), not the content layer. Use it sparingly on custom controls; use the clear variant only over visually rich backgrounds. Check legibility with Reduce Transparency and Increase Contrast on. `[HIG-Materials]`

**C-9 Error and toast contrast.** Error messages: red edge or icon plus text at >= 4.5:1. Never red text alone on a dark red background. `[Field]` `[XAG-102]`

**C-10 Hints are not faint.** Instructional hints and empty-state text meet C-1. "Subtle" is achieved with size and position, not with contrast below 4.5:1. `[Field]`

## Tools

- Contrast: WebAIM Contrast Checker, Colour Contrast Analyser, Xcode Accessibility Inspector.
- Color blindness: Sim Daltonism (macOS), Color Oracle.
- Measure on real screenshots, not design tokens, when text sits on art.
