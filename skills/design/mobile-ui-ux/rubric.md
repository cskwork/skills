# Scoring rubric

Seven categories, each scored 1 to 5 (half points allowed). Score from screenshots at the smallest and largest supported device in every shipped language. The lower of the two device scores counts.

**Default bar:** every category >= 4 **and** average >= 4.3. A project override can raise or lower the bar (see `CUSTOMIZE.md`); it cannot waive a category.

Any **(floor)** rule violation caps the related category at 3, whatever else is good.

## Anchors (shared across categories)

| Score | Meaning |
|---|---|
| 1 | Broken. Cannot be used or read on the smallest device. |
| 2 | Usable only with effort; several floor violations. |
| 3 | Works, but a first-time user stumbles: at least one floor violation or several clear rule failures. Typical "developer UI". |
| 4 | Good. No floor violations; a few minor rule misses that a careful reviewer notices but a user rarely hits. Ready to ship. |
| 5 | Excellent. Matches or beats the best app or game in its category at the smallest device; nothing to fix that a reviewer can name with evidence. |

## Categories

### 1. Visual hierarchy and readability
- **3:** Text readable on large devices but under 11 pt or low contrast somewhere on the smallest; competing focal points.
- **4:** All text >= 11 pt and meets contrast; one clear focal point per screen; type scale consistent.
- **5:** The eye lands on the right thing first on every screen, in every language; hierarchy survives the largest text size.
- Rules: TY-1..13, C-1..3, L-3, N-3.

### 2. Primary-screen clarity (battle screen for games)
- **3:** Primary content readable, but overlaps (bars, numbers, banners) or clutter slow the user down.
- **4:** Nothing important is covered; a new user can say what is happening within ~3 s.
- **5:** Readable even at peak busyness (mid-combat, full list); frame strips of transitions show no frame where key content is hidden.
- Rules: L-9, L-12, G-4..G-11, S-1..S-3.

### 3. Status, HUD, and navigation
- **3:** Status info present but crowded, floating over content, or clipped without a cue.
- **4:** Tiered HUD or clear nav; overflow cues present; back/close always findable.
- **5:** Status is glanceable, compact, and placed where the eye already is; zero hunting.
- Rules: G-1..3, G-18..19, L-8, N-1..N-11.

### 4. Core-interaction usability (equipping, placing, form entry, the main task)
- **3:** The core task works but needs trial and error; errors are silent or unclear; drag only.
- **4:** Clear affordances, valid-target highlights, tap alternative, error states with reasons.
- **5:** The core loop feels effortless and forgiving; previews, snapping, and undo make mistakes cheap.
- Rules: G-12..G-17, T-7, I-1..I-10, S-4, S-6, N-7.

### 5. Touch ergonomics, including the smallest supported device
- **3:** Targets under 44 pt on the smallest device, or destructive actions next to common ones.
- **4:** All targets >= 44 pt (or justified 28 pt menu icons), spacing OK, primary actions in thumb reach.
- **5:** Comfortable one-handed (apps) or two-thumbed (games) at the smallest device; no mis-taps observed in play.
- Rules: T-1..T-13, L-5..L-7.

### 6. Polish and genre/platform feel
- **3:** Functional but flat: missing press states, sound, or transitions; or motion that gets in the way.
- **4:** Responsive press states, purposeful motion, haptics and sound where expected; feels native (apps) or genre-appropriate (games).
- **5:** Side by side with the genre/platform reference, it holds up; feedback is juicy without noise; Reduce Motion version still feels finished.
- Rules: F-1..F-16, G-28..G-30, C-8.

### 7. Consistency and localization
- **3:** Mixed capitalisation or terms, auto-shrunk siblings, clipped labels, or mid-word wraps in any shipped language.
- **4:** Every shipped language fits at the smallest device; consistent terms, case, and treatments.
- **5:** Each language reads as if designed in it; tests guard overlap and wrapping.
- Rules: LOC-1..10, TY-5, TY-6, TY-10, G-20, N-11.

## Score sheet

```
Build: <commit or build no.>   Date: <YYYY-MM-DD>   Judge: <self | independent>
Devices: <smallest> / <largest>   Languages: <list>   Bar: all >= 4, avg >= 4.3
| # | Category                         | Score | Main evidence (screenshot) |
| 1 | Visual hierarchy & readability   |       |                            |
| 2 | Primary-screen clarity           |       |                            |
| 3 | Status / HUD / navigation        |       |                            |
| 4 | Core-interaction usability       |       |                            |
| 5 | Touch ergonomics (smallest dev.) |       |                            |
| 6 | Polish & genre/platform feel     |       |                            |
| 7 | Consistency & localization       |       |                            |
Average: x.xx  Result: PASS | FAIL
Fixes in order of impact: 1. [rule IDs] problem (screenshot) -> concrete change with numbers
Evidence gaps: states or sizes not captured
```

## Independent-judge prompt template

Send to a separate agent with no access to the code or the builder's reasoning. Attach only the screenshots and this prompt. Fill the `<...>` fields.

```
You are an independent UI/UX judge for a <iPhone app | mobile web app | mobile <genre> game>.
You have not seen the code. Judge only what the screenshots show.

Context:
- Smallest supported device: <e.g. iPhone SE 3, 375x667 pt, @2x>. Largest: <e.g. Pro Max, 440x956 pt, @3x>.
- Languages: <e.g. Korean (primary), English>.
- Genre/platform references to compare against: <e.g. Teamfight Tactics mobile, Clash Royale | iOS Settings and Reminders>.
- Screenshots: <list file names with a one-line description each; pt = px / device scale>.
- Previous round's fixes, if any: <list>. Verify each one; say fixed, partly fixed, or not fixed.

Score these 7 categories from 1 to 5 (half points allowed), using the anchors below:
1 Visual hierarchy & readability, 2 Primary-screen clarity, 3 Status/HUD/navigation,
4 Core-interaction usability, 5 Touch ergonomics incl. smallest device,
6 Polish & genre/platform feel, 7 Consistency & localization.
Anchors: 3 = works but a first-time user stumbles or a legibility/target minimum is broken;
4 = no minimums broken, only minor misses, shippable; 5 = matches the best in its category.
Hard minimums (any miss caps that category at 3): text >= 11 pt, tap targets >= 44 pt,
text contrast >= 4.5:1 (3:1 for large/bold), nothing inside unsafe screen areas,
no overlapping labels or bars, no mid-word breaks in Korean, drag actions have a tap alternative.

Bar: every category >= <4> and average >= <4.3>.

Output:
1. Title line: PASS or FAIL, average, bar.
2. Score table.
3. Fixes in order of impact, max 8. Each: the screenshot and approximate position, what is wrong,
   and a concrete change with numbers (pt, ms, ratio). Estimate sizes in pt.
4. Evidence gaps: states or sizes you need to see next round.
Be strict. Do not praise. Do not suggest changes you cannot tie to a screenshot.
```
