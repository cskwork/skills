# Games

Applies with the `game` profile, on top of layout, touch, typography, color, feedback-motion, and accessibility. Rules marked `[Field]` come from independent-judge review rounds on a landscape mobile auto-battler; each one was a real failure that cost a full review round. **(floor)** = cannot be relaxed by an override.

Genre references in the `[Pattern]` notes (Teamfight Tactics mobile, Hearthstone Battlegrounds, Clash Royale) are observed patterns of well-reviewed mobile games, not official guidelines. A project override can name its own genre references.

## HUD and information hierarchy

**G-1 Three tiers.** Classify every HUD element: tier 1 = needed every second (own HP, timer, current resource, primary action); tier 2 = needed every round (level, gold, standings, synergies); tier 3 = on demand (odds, logs, detailed stats). Tier 1 is largest, closest to the thumbs or the center of attention; tier 3 lives behind a tap. `[Hodent]` `[HIG-GameCtl]`

**G-2 HUD stays on the edges.** Non-diegetic HUD sits in the screen edges inside the safe area; the center belongs to play. Prefer spatial UI (bars over units, markers on the board) for information about a specific object, and keep it attached to that object. `[BeyondHUD]` `[HIG-GameCtl]`

**G-3 Show only what the phase needs.** Hide or collapse controls that cannot be used in the current phase (shop and bench controls during combat shrink to a thin strip). `[HIG-GameCtl]` `[Field]`

## Combat readability

**G-4 HP bars never merge (floor).** Each unit's HP bar is at most ~80% of its cell or unit width, with >= 4 pt gap to any neighbouring bar, a 1 pt dark outline, and height >= 4 pt at the smallest device. Packed rows must still read as separate bars. Ally and enemy bars differ by color **and** a second cue (frame shape, icon, or position). `[Field]` `[XAG-102]` `[C-4]`

**G-5 Bar extras attach to the bar.** Star level, shield, and status icons sit as small badges on the bar's ends or directly above it, never on top of the fill. Shield is a distinct overlay color with its own outline. `[Field]`

**G-6 Damage numbers stay off bars.** Floating combat text spawns >= 16 pt above the target's HP bar and drifts up and outward. It never covers a bar, a unit's face, or another number. `[Field]`

**G-7 Damage number budget.** Same-target hits within ~300 ms merge into one rising counter. Normal hits are small (about 60% of crit size) and fade in <= 450 ms total. Only crits and skills are large, outlined, and colored, with a short pop (scale 1.2 -> 1.0 over ~100 ms). Cap simultaneous numbers per target (about 3) and drop the oldest. `[Field]` `[Juice]`

**G-8 Every on-screen mark means something.** Any icon, ring, or marker on the battlefield is explainable in one sentence (target marker, AoE warning). Unexplained debug or leftover VFX is removed. If a reviewer asks "what is that?", it fails. `[Field]`

**G-9 Banners never cover play.** Round and phase banners ("Combat start") use a thin band under the top bar or the empty part of the screen, last < 1 s, and never cover units or the front rows. Under Reduce Motion they fade only. `[Field]` `[F-7]`

**G-10 Toasts avoid key areas.** Toasts and hints appear above the board under the top bar, fade within ~1.2 s for confirmations, and never cover bench slots, the enemy preview row, or the drag destination. Error toasts have a red edge or icon and text at >= 4.5:1. `[Field]` `[C-9]`

**G-11 Readable at a glance.** Unit silhouettes, team colors, and rarity frames are distinguishable at the smallest device in a grayscale screenshot (C-4). Status effects use icon + color. `[XAG-102]` `[GAG]`

## Drag-and-drop and placement

**G-12 Drag has full feedback.** On pick-up: item lifts (scale ~1.1, shadow), source slot dims. During drag: valid targets glow, the nearest valid target highlights strongly, invalid areas show no highlight. On drop: valid drop snaps into place with a short animation (~150 ms) and a haptic tick; invalid drop snaps back to the origin (~200 ms) with a brief red flash and a reason. `[Field]` `[Pattern: TFT, Clash Royale]`

**G-13 Tap alternative for every drag (floor).** Tap an item to select it (strong glow), then tap a target to apply. Show a hint under the top bar while an item is selected ("Tap a unit to equip"), pulse valid targets, and cancel on tapping empty space. `[T-7]` `[WCAG-2.5.7]` `[Field]`

**G-14 Drag previews do not hide the target.** Previews (combine result, slot row) appear above the finger and never cover the target or enemy units. Show slot rows only for the hovered or nearest target, a faint glow for other valid ones; neighbouring units' overlays must not overlap. `[Field]`

**G-15 Limits shown at the attempt.** "Slots full (3/3)" style messages with the slot flashing red and the item snapping back (S-6). `[Field]`

**G-16 Equipped state is visible.** Equipped items show as pips or icons under the unit's HP bar, >= 14 pt with frame and art, readable during combat. `[Field]`

**G-17 Drop zones are generous.** Drop hit areas extend >= 8 pt beyond the visible slot; board hexes or cells accept drops anywhere within the cell. `[T-1]` `[Hoober-Fingers]`

## Standings, scoreboards, shop

**G-18 Standings are compact and tappable.** Rows >= 44 pt tall; show top 4 + the player's own row on short screens, rest behind a tap (L-8). Player row is highlighted with more than color. Tapping a row scouts that player; tapping your own row returns. `[Field]`

**G-19 Scouting shows the scouted player's data.** When viewing another player, every panel shows their data with a header naming them; the player's own controls (Ready, timer) remain visible; a >= 44 pt back control with an arrow returns. `[Field]`

**G-20 Shop cards are uniform.** Every card uses the same layout and the same treatment for traits (all icons or all text, not mixed). Cost, name, and traits readable at the smallest device. `[Field]` `[Pattern: TFT, HS Battlegrounds]`

**G-21 Numbers in a fixed column.** Trait counts, gold, and HP use tabular figures in a fixed-width column (TY-7, LOC-3). Adjacent number pairs ("14 ♥ 100") have >= 12 pt gap or stack. `[Field]`

## Onboarding (FTUE)

**G-22 Play within 60 s.** First launch reaches interactive play within about 60 seconds and without an account. Teach one mechanic at a time inside play; written tutorials are an optional reference. `[HIG-Games]` `[Hodent]` `[GAG]`

**G-23 Reminders on demand.** Controls and the current objective can be recalled at any time during play (help button, long-press tooltips). `[GAG]`

**G-24 Practice without failure.** Offer a practice or sandbox mode, or make the first matches low-stakes. `[GAG]`

## Pause, settings, sheets

**G-25 Settings sheet fits (floor).** Pause and settings sheets fit inside the safe area at the smallest device with >= 16 pt margins on all sides, with Close pinned in a footer or header inside the panel and a fade mask on the scrolling list (L-10). Check both the main-menu and the in-match versions. `[Field]`

**G-26 Required settings.** Music, effects, and voice volumes (F-15); haptics toggle or intensity (F-13); screen shake / motion intensity (F-7); text size (TY-4); game speed where the genre allows; low-power or low-spec mode (P-4). `[GAG]` `[HIG-Games]`

**G-27 Pausing is always possible** in single-player and in any mode where the game can be paused, from a >= 44 pt control in a top corner; the game pauses when the app backgrounds. `[GAG]`

## Feel (juice)

**G-28 Every action has a reaction.** Hits, purchases, level-ups, and wins get layered feedback: visual (flash, particles, squash), audio (real SFX, not silence), and haptic for key moments. Small actions get small reactions; the biggest reaction is reserved for the rarest event. `[Juice]` `[F-2]`

**G-29 Screen shake and flashes are restrained.** Short (< 200 ms), small amplitude, off under Reduce Motion or the motion setting (F-7, F-9). `[Juice]` `[GAG]`

**G-30 Match the genre reference.** Before calling a game screen done, compare side by side with one named genre reference at the same device size: density of HUD, size of units, readability of combat. Note what the reference does better. `[GameUIDB]` `[Hodent]`

## Virtual controls (action games)

**G-31 Controls under the thumbs.** Frequent buttons >= 44 pt near the thumbs; menus >= 28 pt at the top. Movement on the left, camera on the right; use a floating thumbstick that appears where the thumb lands; direct-touch pan for camera. `[HIG-GameCtl]`

**G-32 Action icons, not button letters.** Use symbols that show the action (a sword for attack), not "A" or "R1". Press state visible around the finger. `[HIG-GameCtl]`

**G-33 Controller support is additive.** If a controller is connected, show its glyphs; touch always remains available. `[HIG-GameCtl]` `[HIG-Games]`

## Anti-patterns (all seen in real review rounds)

- A fixed-resolution canvas stretched to an @2x small phone, shrinking every tile below 44 pt and text to 6 to 8 pt.
- Damage numbers drawn on top of HP bars, the same number drawn twice, big grey numbers for normal hits.
- A row of HP bars in a packed front line reading as one long strip.
- "Combat start" banner over both front rows.
- Synergy list clipped by the Ready button with no "+N more".
- Settings sheet with no bottom edge and Close cut off on the SE.
- Mid-word Korean wrap in a unit description.
- Sell button next to Close in the unit detail.
- Craft toast covering bench slots.
- Scouting view showing the player's own empty state instead of the scouted player's data.
