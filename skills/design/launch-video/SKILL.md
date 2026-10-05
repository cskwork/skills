---
name: launch-video
description: Make a motion-graphics product launch or feature-announcement video (Apple/Google keynote style, the SaaS launch videos posted on X) from real captures of the user's running app on iOS Simulator, Android emulator, web, or desktop. Use when asked for a launch video, promo, commercial, feature reel, or app trailer built from the actual product.
---

# launch-video

Turn a real, running product into a short launch video that looks like a senior motion designer's showreel. Every UI pixel comes from the product itself.

## Brief

Settle these before capturing. Take the user's words first, then the default. Ask only what blocks the work, one question at a time.

| Parameter | Default |
| --- | --- |
| Source surface | The one the user names ("native iOS app in the simulator", "the web app at URL"). Capture only from that surface, even when another is easier. |
| Length | 30 s |
| Frame | 1920×1080, 60 fps. 1080×1080 or 1080×1920 when asked for feed or vertical. |
| Scope | Whole-product launch, or one feature when the user names it. |
| Copy language | The user's language. |
| Audio | Music only from a file the user supplies or a license they confirm; otherwise a silent cut plus a note. |
| Prior work | Fresh concept every run. When the user says not to look at past work, leave earlier videos, compositions, and templates in the workspace unopened. |

Done when every row has a value you can state in one line.

## 1. Capture

Read [references/capture.md](references/capture.md) for the commands of the chosen surface.

- Inventory the product: open every main screen, list the 3–5 features with the clearest visible payoff.
- Pull brand material from the source repo: app icon, colour tokens, fonts, product name and tagline, real copy strings.
- Capture each feature as a clean still at native resolution and a 3–8 s clip of its hero interaction. Clean means: 9:41 status bar, full battery, realistic demo data, no debug overlays, no personal data.
- Write `assets/manifest.md`: one line per file with source surface, screen, and what it shows.

Done when every feature beat you plan has at least one real still and one clip in the manifest. The video shows only captured UI; to animate one element on its own, crop it from a capture instead of redrawing it.

## 2. Beat sheet

Write `beats.md` before any composition code. For a 30 s cut:

| Time | Beat |
| --- | --- |
| 0–3 s | Hook: the boldest UI moment or claim, already moving on frame 0. |
| 3–6 s | Promise: one line on what the product changes for the viewer. |
| 6–24 s | 3–4 feature beats, 4–5 s each: feature name, benefit line, the real UI doing it. |
| 24–27 s | Montage climax: fast cuts across screens, rising tempo. |
| 27–30 s | Lockup: icon, name, tagline, CTA or URL, held at least 1.5 s. |

Scale proportionally for other lengths. Each beat row names: on-screen copy (6 words or fewer), the asset file, the camera or element move, the transition out, and the accent hit.

Done when every second of the timeline is covered and every asset named exists in the manifest.

## 3. Look

Derive the look from the product, not from a preset: background family, one text colour, one accent from the brand tokens, the product's own typeface or the platform face (SF Pro on iOS, Roboto/Google Sans on Android, Inter on web). Draw device frames procedurally (rounded body, bezel, island or punch-hole) at the correct aspect for the captures.

## 4. Motion bar

This is the showreel standard. Each beat uses at least two of these, and the whole cut uses most of them:

- 3D device moves: perspective turns, tilts, floats, multiple devices in depth.
- Camera push into a UI region, then pull back to context.
- Element lift: a card or button cropped from a capture rises out of the screen with shadow and scale.
- Kinetic type: per-word or per-letter springs, masked line reveals, words that swap in place.
- Tap ripples or a cursor driving the real recorded interaction.
- Counters, progress fills, and charts that tick up in sync with the UI.
- Match cuts and whip transitions with directional motion blur.
- Parallax across 2–3 depth layers, light sweeps on glass, background depth blur.
- Speed ramps on the clips.

Timing rules: frame 0 is already moving; something meaningful changes every 0.8–2 s; entrances use springs or ease-out-expo with slight overshoot; 30–60 ms staggers; linear motion only for tickers; copy stays on screen long enough to read twice; held shots get a slow push (scale 1 → 1.04).

## 5. Build and render

- Engine: the project's existing video pipeline if it has one; otherwise Remotion (`npx create-video@latest`; check its license fits the user's company size) or an HTML composition rendered frame by frame with Playwright and ffmpeg.
- Animation is a pure function of frame time: no wall clock, no unseeded randomness.
- Export H.264, yuv420p, `-movflags +faststart`, CRF 16–18, plus a poster PNG from the lockup.

## 6. QA

1. `ffprobe` duration, resolution, and fps match the brief.
2. Contact sheet: `ffmpeg -i out.mp4 -vf "fps=2,scale=480:-1,tile=10x6" contact.png`; view it and a full-resolution still from every beat.
3. Check: every UI shown traces to the manifest, no placeholder or lorem text, no typos, text inside 5% safe margins, nothing static for more than 2 s, lockup readable, file under 512 MB for X.

Fix and re-render until every check passes.

## Deliver

Report: the MP4 path, the poster path, length and frame size, the features shown, the audio status, and the re-render command. Keep the work folder (`assets/`, `beats.md`, composition source) next to the output.

## Example request

"Launch video for our app from the native iOS app running in the simulator, not the web app; don't look at past work; 30 s; go all out" → surface: iOS Simulator; length: 30 s; frame: 1920×1080 at 60 fps; prior work: unopened; motion bar: full.
