# Feedback, motion, haptics, sound

**(floor)** = cannot be relaxed by an override.

## Feedback

**F-1 Acknowledge every input within 100 ms.** A tap shows a pressed state immediately; under 100 ms feels instant. If the result takes longer than 1 s, show progress; over ~10 s, show progress with an estimate and let the user do something else. Keep interaction round trips under 400 ms where possible. `[NNG-Response]` `[LawsUX-Doherty]` `[HIG-GameCtl]`

**F-2 Feedback is multi-channel.** Important events use at least two of: visual, sound, haptic. Nothing important is conveyed by sound alone or haptic alone. `[HIG-A11y]` `[GAG]`

**F-3 Optimistic UI only when reversible.** Show the result immediately when the action is cheap to roll back; on failure, revert visibly and say why.

## Motion

**F-4 Durations.** Small feedback (toggle, press, checkbox): ~100 ms. Element enter/exit, sheet, modal: 200 to 300 ms. Large screen changes: up to ~400 ms. Nothing routine exceeds 500 ms. Entrances slightly longer than exits. `[NNG-Anim]`

**F-5 Easing.** Ease-out for entering, ease-in for exiting, never linear for UI movement (linear is fine for progress fills and continuous rotation). Prefer system springs on iOS. `[NNG-Anim]` `[HIG-Motion]`

**F-6 Purposeful and brief.** Motion explains a change (where something came from, where it went) or confirms an action. No decorative motion on frequent interactions. Let the user act or skip during an animation; never block input to finish a flourish. `[HIG-Motion]`

**F-7 Reduce Motion (floor).** When Reduce Motion is on (iOS setting, `prefers-reduced-motion` on web): replace slides, zooms, parallax, and screen shake with fades or instant changes; no auto-playing looping motion. Information carried by motion stays available as a static cue. Games also offer an in-game motion/screen-shake option. `[HIG-Motion]` `[WCAG-2.3.3]` `[MDN-reduced-motion]` `[GAG]`

**F-8 Pause, stop, hide.** Anything that moves, blinks, or auto-updates for more than 5 s alongside other content can be paused or hidden (carousels, tickers, idle animations near text). `[WCAG-2.2.2]`

**F-9 Flashing (floor).** Nothing flashes more than 3 times per second. Large full-screen flashes (hit flashes, explosions) respect a "reduce flashing" option. `[WCAG-2.3.1]` `[GAG]`

**F-10 Frame rate.** Animations hold a steady 60 fps (or 30 fps steady in games that target it; 120 on ProMotion where supported). A steady lower rate beats a stuttering higher one. `[HIG-Motion]`

**F-11 Timed UI.** Toasts and banners that carry information stay long enough to read (about 1 s + 60 ms per character, minimum 2 s) unless they are pure confirmation; critical messages never auto-dismiss. Games: combat banners are the exception (G-9). `[HIG-A11y]`

## Haptics

**F-12 Haptics match meaning.** Use system haptic patterns for their documented meaning (success, warning, error, selection, impact). Same event, same haptic, every time. Do not reuse a "failure" pattern for success. `[HIG-Haptics]`

**F-13 Haptics are optional (floor for games).** Provide a haptics on/off toggle (games: a toggle or intensity slider). Respect the system setting. The experience works fully without haptics. `[HIG-Haptics]` `[GAG]`

**F-14 Haptic budget.** Not on every tap. Reserve for confirmations, errors, snapping into place, and key game moments (crit, level up, round won). No continuous buzzing.

## Sound

**F-15 Separate volumes.** Games and audio-heavy apps provide separate music, effects, and voice volume controls, each mutable. Respect the silent switch for non-essential sounds in apps. `[GAG]`

**F-16 Distinct cues.** Key events have distinct sounds that are not confusable. `[GAG]`
