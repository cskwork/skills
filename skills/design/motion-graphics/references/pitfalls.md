# Pitfalls

Lessons from real renders. Check the composition against each before the first full render, and append new ones as `date · video · lesson`.

## Runtime

- Give each element to one `MG.scene` only. An element in two scenes stays hidden during the earlier one, because the later scene hides it whenever `t` is outside its range. Drive shared elements from one `MG.always`.
- `MG.scene` hides with `visibility: hidden`; a child set to `visibility: visible` still shows. Toggle children with `inherit`.
- Frames render out of order in parallel workers: set every animated property on every call; never rely on state from an earlier frame.
- An unknown ease name throws only at frames inside that tween, so a still elsewhere passes. Capture a frame inside every tween.
- Use unique class names per element; generic ones (`.dots`) leak styles to other elements.
- A leading space is lost at an inline-block boundary; use a non-breaking space.
- A loop tail that reuses the opening state must not feed `t` into the head keyframes; compare the last frame with frame 0.

## Springs and scale

- Slams: damping ≈ 1.2·√stiffness (ratio 0.6, about 10% overshoot). Long travel: damping ≈ 1.75·√stiffness (ratio 0.9); a slam damping on a 760 px move overshot to the frame edge.
- Overshoot scales near-full-width text past the frame edge. Fit slam lines to about 80% of the frame width, start large-scale slams at 1.2–1.3×, and check a frame 0.04 s after each slam and at the overshoot peak.
- Set `white-space: nowrap` on lines sized to fit; a wrapping line passes a width check and still overflows.

## Numbers

- Flip all digits of one number at the same time; a per-digit stagger shows wrong numbers mid-cascade (19,610 → "29,610" → 20,000).
- Hold a counter's final value until it has faded out; it can flash back to 0.
- Counting up from 0 shows invented values on mid frames. For factual content, slam the sourced value.

## Effects

- A glow on an element inside `overflow: hidden` or `clip-path` is clipped to that box and leaves a visible rectangle. Put the filter on a wrapper and the clip on an inner layer.
- An element springing in from far below passes behind the caption band; enter near captions with a scale pop and opacity ramp instead.

## Render and audio

- Run one full render at a time; a second render beside it broke the first. Stills-only runs can go in parallel.
- Render video while music is pending; muxing audio later does not need a re-render.
- A track can open with near-silence or hold a silent gap: run `silencedetect=n=-45dB:d=0.4` and cut from where it becomes audible.
- The limiter caps sample peaks, not AAC true peaks: stacked transients (click on impact) can exceed −1 dBFS after encoding. Measure true peak on the final file and lower the offending SFX.
- In zsh, `"$var:..."` inside an ffmpeg filter string applies a history modifier; write `${var}`.
