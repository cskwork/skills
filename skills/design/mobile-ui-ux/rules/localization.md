# Localization, including Korean

## Rules

**LOC-1 No mid-word breaks in Korean (floor when Korean ships).** Korean wraps at spaces between words (eojeol), never inside a word. Web/CSS: `word-break: keep-all;` with `overflow-wrap: anywhere;` only as a last resort for unbroken strings like URLs. Native iOS (UIKit/TextKit): include `.hangulWordPriority` in the paragraph style's `lineBreakStrategy` (iOS 14+; "prohibits breaking between Hangul characters"); for SwiftUI `Text`, verify on device with long Korean strings and fall back to a UIKit-backed label if words split. Game engines: enable word-level smart wrap (for example Godot `AUTOWRAP_WORD_SMART`) rather than character wrap. Add a test that fails when a Korean word is split across lines. `[MDN-word-break]` `[KLREQ]` `[Apple-Hangul]` `[Field]`

**LOC-2 Expansion budget.** Plan labels for at least 30% longer text than English (up to 100%+ for short strings under ~10 characters, for example German and French). Korean is often shorter than English in characters but needs larger sizes and more line height to read; check both directions. `[W3C-i18n]`

**LOC-3 Fixed-width count columns.** In any row with a name and a value ("Long Faction Name 2/4"), the value sits in a fixed-width trailing column; the name ellipsizes or wraps to 2 lines. Test the longest language. `[Field]`

**LOC-4 Short label variants.** Where space is tight, provide a deliberate short string per language ("Int +1" for "interest +1") instead of clipping. `[Field]`

**LOC-5 Consistent terms and case.** One term per concept across all screens per language, kept in a glossary. Capitalisation consistent per role (TY-10). `[Field]`

**LOC-6 No text in images.** UI text is live text, not baked into art, so it can be translated, scaled, and read by assistive tech. Logos excepted. `[XAG-102]`

**LOC-7 Formats.** Numbers, dates, currency, and plurals use the locale's formatter (`NumberFormatter`, `Intl`), never string concatenation. Korean counters and particles: avoid concatenating nouns with particles (을/를, 이/가); rephrase or use a form that works for any noun.

**LOC-8 Fonts cover the script.** See TY-12. Check that every glyph in every language renders in the shipped font without fallback boxes.

**LOC-9 Test every shipped language at the smallest device.** Screenshots of the busiest screen in every language, at the smallest device. The longest language usually fails first.

**LOC-10 RTL (if supported).** Mirror layout and directional icons; keep numbers and media controls LTR.

## Korean quick notes

- Line height 1.5 to 1.7 for body Korean text.
- Avoid letter-spacing tightening below 0 on Hangul body text.
- Korean sentence-ending forms in UI: pick one register (해요체 or 합니다체) per app and keep it.
- Keep particles readable: "장비 슬롯 가득 참 (3/3)" style compact labels are fine for games; full sentences for errors in apps.
