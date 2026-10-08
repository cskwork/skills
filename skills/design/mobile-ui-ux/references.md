# References

All sources accessed 2026-10-08. Rules are original summaries written for this skill; no text is copied beyond short quoted numbers and setting names. Keys in rule files (`[HIG-A11y]`) map to the rows below. Keys that look like rule IDs (`[C-4]`, `[T-7]`) are cross-references to other rules in this skill.

## Apple

| Key | Source |
|---|---|
| HIG-A11y | Apple HIG, Accessibility (text sizes 17 pt default / 11 pt minimum; 44x44 pt default and 28x28 pt minimum controls; ~12 pt / ~24 pt padding; contrast table; gesture alternatives) — https://developer.apple.com/design/human-interface-guidelines/accessibility |
| HIG-Games | Apple HIG, Designing for games (legible text, button sizes, safe areas, aspect ratios 16:10 / 19.5:9 / 4:3, teach through play, defer requests, initial download <= 30 min) — https://developer.apple.com/design/human-interface-guidelines/designing-for-games |
| HIG-GameCtl | Apple HIG, Game controls (virtual controls: 44x44 pt frequent, 28x28 pt menus; thumb placement; press states; floating thumbstick; action symbols) — https://developer.apple.com/design/human-interface-guidelines/game-controls |
| HIG-Layout | Apple HIG, Layout (safe areas, size classes, layout guides) — https://developer.apple.com/design/human-interface-guidelines/layout |
| HIG-Typography | Apple HIG, Typography (text styles, Dynamic Type) — https://developer.apple.com/design/human-interface-guidelines/typography |
| HIG-Motion | Apple HIG, Motion (purposeful, brief, optional motion; cancelable; 30 to 60 fps for games) — https://developer.apple.com/design/human-interface-guidelines/motion |
| HIG-Haptics | Apple HIG, Playing haptics (documented meanings, consistency, optional) — https://developer.apple.com/design/human-interface-guidelines/playing-haptics |
| HIG-Materials | Apple HIG, Materials (Liquid Glass for the controls/navigation layer, sparing use, clear vs regular variants) — https://developer.apple.com/design/human-interface-guidelines/materials |
| HIG-TabBars | Apple HIG, Tab bars (navigation not actions, keep visible, avoid More tab, do not hide tabs) — https://developer.apple.com/design/human-interface-guidelines/tab-bars |
| Apple-Hangul | Apple Developer, `NSParagraphStyle.LineBreakStrategy.hangulWordPriority` (iOS 14+) — https://developer.apple.com/documentation/uikit/nsparagraphstyle/linebreakstrategy-swift.struct/hangulwordpriority |

## W3C / WCAG 2.2

| Key | Source |
|---|---|
| WCAG-1.4.3 | Contrast (Minimum), 4.5:1 / 3:1 large — https://www.w3.org/TR/WCAG22/#contrast-minimum |
| WCAG-1.4.4 | Resize Text, 200% — https://www.w3.org/TR/WCAG22/#resize-text |
| WCAG-1.4.10 | Reflow, 320 CSS px — https://www.w3.org/TR/WCAG22/#reflow |
| WCAG-1.4.11 | Non-text Contrast, 3:1 — https://www.w3.org/TR/WCAG22/#non-text-contrast |
| WCAG-1.4.12 | Text Spacing (1.5 / 2 / 0.12 / 0.16) — https://www.w3.org/TR/WCAG22/#text-spacing |
| WCAG-2.2.2 | Pause, Stop, Hide (> 5 s) — https://www.w3.org/TR/WCAG22/#pause-stop-hide |
| WCAG-2.3.1 | Three Flashes or Below Threshold — https://www.w3.org/TR/WCAG22/#three-flashes-or-below-threshold |
| WCAG-2.3.3 | Animation from Interactions — https://www.w3.org/TR/WCAG22/#animation-from-interactions |
| WCAG-2.4.11 | Focus Not Obscured (Minimum) — https://www.w3.org/TR/WCAG22/#focus-not-obscured-minimum |
| WCAG-2.5.7 | Dragging Movements — https://www.w3.org/TR/WCAG22/#dragging-movements |
| WCAG-2.5.8 | Target Size (Minimum), 24x24 CSS px with spacing exception — https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html |
| WCAG-3.3.7 | Redundant Entry — https://www.w3.org/TR/WCAG22/#redundant-entry |
| WCAG-3.3.8 | Accessible Authentication (Minimum) — https://www.w3.org/TR/WCAG22/#accessible-authentication-minimum |
| KLREQ | W3C, Requirements for Hangul Text Layout and Typography — https://www.w3.org/TR/klreq/ |
| W3C-i18n | W3C Internationalization, Text size in translation — https://www.w3.org/International/articles/article-text-size |

## Cross-platform design systems and research

| Key | Source |
|---|---|
| M3 | Material Design 3, Accessibility / structure (48x48 dp targets, 8 dp spacing) — https://m3.material.io/foundations/designing/structure |
| NNG-Touch | Nielsen Norman Group, Touch Targets on Touchscreens (1 x 1 cm minimum) — https://www.nngroup.com/articles/touch-target-size/ |
| NNG-Response | Nielsen Norman Group, Response Times: The 3 Important Limits (0.1 s / 1 s / 10 s) — https://www.nngroup.com/articles/response-times-3-important-limits/ |
| NNG-Anim | Nielsen Norman Group, Executing UX Animations: Duration and Motion Characteristics (100 to 500 ms; ease-out) — https://www.nngroup.com/articles/animation-duration/ |
| NNG-Forms | Nielsen Norman Group, Placeholders in Form Fields Are Harmful — https://www.nngroup.com/articles/form-design-placeholders/ |
| Hoober-Hold | Steven Hoober, How Do Users Really Hold Mobile Devices? (1,333 observations: 49% one-handed, 36% cradled, 15% two-handed) — https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php |
| Hoober-Fingers | Steven Hoober, Design for Fingers, Touch, and People, Part 1 (center ~7 mm vs corners ~12 mm targets) — https://www.uxmatters.com/mt/archives/2017/03/design-for-fingers-touch-and-people-part-1.php |
| LawsUX-* | Jon Yablonski, Laws of UX — https://lawsofux.com/ (Fitts: /fittss-law/, Hick: /hicks-law/, Jakob: /jakobs-law/, Miller: /millers-law/, Doherty: /doherty-threshold/, Proximity: /law-of-proximity/, Von Restorff: /von-restorff-effect/, Choice Overload: /choice-overload/, Active User: /paradox-of-the-active-user/) |

## Mobile web

| Key | Source |
|---|---|
| CWV | web.dev, Web Vitals (LCP <= 2.5 s, INP <= 200 ms, CLS <= 0.1 at p75) — https://web.dev/articles/vitals |
| MDN-env | MDN, `env()` (safe-area-inset-*) — https://developer.mozilla.org/en-US/docs/Web/CSS/env |
| MDN-length | MDN, CSS length, viewport units (`dvh`, `svh`, `lvh`) — https://developer.mozilla.org/en-US/docs/Web/CSS/length |
| WebDev-Viewport | web.dev, The large, small, and dynamic viewport units — https://web.dev/blog/viewport-units |
| MDN-viewport | MDN, Viewport meta tag — https://developer.mozilla.org/en-US/docs/Web/HTML/Viewport_meta_tag |
| MDN-reduced-motion | MDN, `prefers-reduced-motion` — https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion |
| MDN-word-break | MDN, `word-break` (`keep-all` for CJK) — https://developer.mozilla.org/en-US/docs/Web/CSS/word-break |
| InputZoom | Rick Strahl, Preventing iOS Textbox Auto Zooming and ViewPort Sizing (inputs < 16 px zoom on focus) — https://weblog.west-wind.com/posts/2023/Apr/17/Preventing-iOS-Textbox-Auto-Zooming-and-ViewPort-Sizing |
| WebDev-PWA | web.dev, Learn PWA — https://web.dev/learn/pwa/ |

## Games

| Key | Source |
|---|---|
| GAG | Game Accessibility Guidelines (basic / intermediate / advanced) — https://gameaccessibilityguidelines.com/full-list/ |
| XAG-101 | Xbox Accessibility Guideline 101, Text display (mobile 18 px at 100 DPI scaling linearly; 200% scaling; 40 CJK characters per line; 1.5 line spacing) — https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101 |
| XAG-102 | Xbox Accessibility Guideline 102, Contrast (4.5:1 standard, 3:1 large and inactive, 7:1 high-contrast mode; measure against the lowest-contrast background area) — https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102 |
| Hodent | Celia Hodent, The Gamer's Brain (usability and engage-ability pillars) — https://celiahodent.com/ (book: CRC Press 2017, ISBN 9781498775502) |
| BeyondHUD | Fagerholt and Lorentzon, Beyond the HUD: User Interfaces for Increased Player Immersion in FPS Games (Chalmers, 2009; diegetic, non-diegetic, spatial, meta) — https://odr.chalmers.se/handle/20.500.12380/111921 |
| Juice | Martin Jonasson and Petri Purho, Juice It or Lose It (2012) — https://www.gamedeveloper.com/design/video-is-your-game-juicy-enough- |
| GameUIDB | Game UI Database (screens and patterns by genre) — https://www.gameuidatabase.com/ |
| TFT-Mobile | Riot Games, Teamfight Tactics Mobile Update (item panel drag/preview, shop auto-opens near the top each round) — https://teamfighttactics.leagueoflegends.com/en-us/news/riot-games/teamfight-tactics-mobile-update/ |
| Pattern | Observed patterns in Teamfight Tactics mobile, Hearthstone Battlegrounds, and Clash Royale (drag previews, valid-target highlights, snap-back, compact standings). Not official guidelines. |

## Field lessons

| Key | Source |
|---|---|
| Field | Independent-judge UI/UX review rounds (two rounds, 2026-10) on a landscape iPhone auto-battler, scored with this rubric. Findings are generalized; no project details are included. |
