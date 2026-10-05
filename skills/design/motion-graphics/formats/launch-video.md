# Format: product launch video

A launch or feature-announcement video in the Apple/Google keynote style, the kind posted on X for a SaaS launch. Every UI pixel comes from the real, running product.

## Brief

Take the user's words first, then the default. Ask only what blocks the work, one question at a time.

| Parameter | Default |
| --- | --- |
| Source surface | The one the user names ("native iOS app in the simulator", "the web app at URL"). Capture only from that surface, even when another is easier. |
| Length | 30 s |
| Frame | 1920×1080, 60 fps. 1080×1080 or 1080×1920 when asked for feed or vertical (then also apply the Shorts safe zones). |
| Scope | Whole-product launch, or one feature when the user names it. |
| Copy language | The user's language. |
| Audio | Music from a file the user supplies or a license they confirm; otherwise silent plus a note. |

Done when every row has a value you can state in one line.

## Capture

Read [../references/capture.md](../references/capture.md) for the commands of the chosen surface.

- Inventory the product: open every main screen and list the 3–5 features with the clearest visible payoff.
- Pull brand material from the source repo: app icon, colour tokens, fonts, product name and tagline, real copy strings.
- Capture each feature as a clean still at native resolution and a 3–8 s clip of its hero interaction. Clean means: 9:41 status bar, full battery, realistic demo data, no debug overlays, no personal data.
- Record each file in `assets/manifest.md`.

Done when every feature beat has at least one real still and one clip in the manifest. The video shows only captured UI; to animate one element on its own, crop it from a capture instead of redrawing it.

## Beat sheet (30 s)

| Time | Beat |
| --- | --- |
| 0–3 s | Hook: the boldest UI moment or claim, already moving on frame 0. |
| 3–6 s | Promise: one line on what the product changes for the viewer. |
| 6–24 s | 3–4 feature beats, 4–5 s each: feature name, benefit line, the real UI doing it. |
| 24–27 s | Montage climax: fast cuts across screens, rising tempo. |
| 27–30 s | Lockup: icon, name, tagline, CTA or URL, held at least 1.5 s. |

Scale proportionally for other lengths. On-screen copy is 6 words or fewer per line.

## Look

Derive it from the product, not a preset: background family, text colour, and accent from the brand tokens; the product's typeface or the platform face (SF Pro on iOS, Roboto or Google Sans on Android, Inter on web). Draw device frames in CSS (rounded body, bezel, island or punch-hole) at the captures' aspect.

## Motion vocabulary

Each beat uses at least two; the whole cut uses most:

- 3D device moves: perspective turns, tilts, floats, several devices in depth.
- Camera push into a UI region, then pull back to context.
- Element lift: a card or button cropped from a capture rises out of the screen with shadow and scale.
- Kinetic type: per-word springs, masked line reveals, words that swap in place.
- Tap ripples or a cursor driving the recorded interaction (`MG.clip`).
- Counters, progress fills, and charts that tick in sync with the UI.
- Match cuts and whip transitions with directional blur.
- Light sweeps on glass, background depth blur, speed ramps on clips.

## Format checks

- Every UI shown traces to a captured file in the manifest.
- Text sits inside the 5% title-safe margins; the lockup is readable for at least 1.5 s.
- File under 512 MB for X; export a poster PNG from the lockup.

## Example request

"Launch video for our app from the native iOS app running in the simulator, not the web app; don't look at past work; 30 s; go all out" → surface: iOS Simulator; length: 30 s; frame: 1920×1080 at 60 fps; past work: unopened; motion vocabulary: full.
