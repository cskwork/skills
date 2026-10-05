# Format: vertical shorts

A YouTube Shorts, Reels, or TikTok video: motion graphics and kinetic type that explain, tell, or joke in under a minute. Viewers decide in the first second.

## Brief

Take the user's words first, then the default. Ask only what blocks the work, one question at a time.

| Parameter | Default |
| --- | --- |
| Topic and angle | From the user. Write the one-sentence takeaway the viewer leaves with. |
| Length | 20–30 s |
| Frame | 1080×1920, 60 fps (30 fps for text-heavy pieces). |
| Language | The user's language; one composition can carry a second language with per-language text and captions. |
| Narration | None (text-led) unless asked. With narration, captions come from `motion.json`. |
| Audio | Instrumental music and SFX from licensed sources or the user's files; otherwise silent plus a note. |
| Facts | Every number or claim on screen has a source in `brief.md`. |

Done when every row has a value and the takeaway fits one sentence.

## Script

Write in `brief.md`: the idea, the format borrowed (listicle, myth vs fact, before/after, countdown, story), what makes this one different, and the scene plan. Then `beats.md`:

| Time | Beat |
| --- | --- |
| 0–2 s | Hook on screen by 0.3 s: the surprising number, question, or image. |
| 2–N s | One idea per beat, 0.8–2 s each, each changing layout, scale, colour, or number. |
| Last 2–3 s | Payoff that answers the hook; the final frame matches frame 0 so the video loops. |

## Look and type

- Display type 110–220 px, body at least 56 px; about 14 Korean or 24 Latin characters per line at most; at least 1.2 s of reading time per short line.
- Shorts UI safe zones (`?guides=1`): key text stays out of the top 12.5%, the bottom 25%, and the right action rail.
- Captions sit above the bottom UI block (`.mg-caption`).

## Facts on screen

- Show only sourced values. A counter or odometer that sweeps through numbers puts unsourced values on mid frames: sweep a bar without digits, then slam the sourced value with its unit and qualifiers in one frame.
- Read the source's own results text before quoting a number; when sources disagree, use the value several agree on.

## Originality

Each video needs its own idea and script. Swapping words in a reused template is the mass-produced pattern that YouTube's inauthentic-content policy demonetises.

## Format checks

- Frame 0 already shows the hook in motion; the last frame matches frame 0.
- Beat frames checked with captions on: nothing under the caption band or the safe zones.
- Every on-screen fact has its source in `brief.md`; credits required by audio licenses are in the description draft.
- Write `metadata.md`: title, description, credits, and hashtags.
