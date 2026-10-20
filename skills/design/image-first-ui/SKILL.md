---
name: image-first-ui
description: Image-first interface creation. Generates three UX-distinct UI images through the user's ChatGPT plan (Codex CLI image generation), shows them side by side, locks the user's pick as the reference image, then builds the real UI to match it and verifies against it. Use when the user wants to see UI options as images before building, says "image first", "이미지로 시안", "UI 시안 3개", or wants a mockup-led admin, web app, landing page, or game screen (menu, HUD, shop). Not for edits to an existing UI that only need code changes.
license: MIT
---

# image-first-ui

The picked image is the source of truth for layout, hierarchy, density, palette, type character, and component shapes. The brief is the source of truth for copy, data, and behavior: generated text and numbers can be wrong or invented, so never copy them from the image.

Self-contained: `<skill>` below is this file's directory. Requires a logged-in `codex` CLI on a ChatGPT plan with image generation (`codex login`) and `python3` with Pillow. If image generation fails, report the layer by exit code (table below); do not substitute HTML mockups or another image model without asking.

Work directory: `<project>/.image-first/<surface>/` (absolute paths everywhere; gen.sh requires them).

```
brief.md            job, read order, scene, direction, signature move, real content, stack
prompts/{A,B,C}.txt the exact prompt each option received
options/{A,B,C}.png generated options
board.html          picker board
reference.png       locked pick (never edited)
reference.json      {option, prompt, approved: true, date, notes}
spec.md             measured spec built from reference.png
compare.html        reference vs build screenshot
```

## Reference first (required)

Before proposing a visual direction, generating design images, or writing UI code, complete this gate:

1. **Find and inspect.** Search the web and image results for relevant visual references; open the actual pages/images, preferring originals, official sites, and reliable archives. Search snippets and remembered impressions do not establish visual facts. Ordinary interfaces need relevant layout/type/material references too. Reuse sufficient user-provided references or existing verified captures; honor an explicit no-browse request and record that limit.
2. **Verify the subject.** For a named work, character, or brand, establish identity and version, documented gender and role where relevant, palette, silhouette, and essential motifs before adapting it. Resolve searchable basics yourself. Keep observed source facts separate from design interpretation; search ambiguity first, then ask only about unresolved choices that materially change the work. If browsing is unavailable, state the evidence gap rather than presenting recollection as verified.
3. **Record and adapt.** In `brief.md` or the existing surface brief, record each source URL/file, observed defining traits, what to preserve, and the original adaptation. Preserve the requested concept instead of substituting generic stock imagery. When the user excludes copied logos or actor likeness, retain the concept through original composition, forms, and material cues while omitting those identifiers. Record usage/license evidence for reused assets; do not promise that an adaptation is “copyright free.”

Gate complete: inspected references support the subject and direction, the brief separates observation from interpretation, and material identity or direction ambiguities are resolved. Carry the verified traits into prompts and implementation.

When changing this gate, check [the regression cases](references/reference-first-cases.md).

## 1. Brief

Get, or infer from the project and state: surface type and mode, primary user and their main job on this screen, real content (sample rows, labels, counts, states), target viewport, and the stack. With an existing app, take a screenshot of a representative page; it goes into every generation as `--ref` and its palette and components become the direction. Ask only what changes the images.

Viewport: admin/web desktop 16:9 landscape; mobile or mobile-first portrait; game at its native orientation. gen.sh has no size flag: state the aspect in the prompt and read the real size afterwards (a "desktop 16:9 landscape" prompt returned 1672x941 on 2026-10-10).

## 2. Three options

Read [references/prompting.md](references/prompting.md) and follow it: pick the mode, record the decisions (job, read order, scene, direction, signature move, calibration check) in `brief.md`, then write each prompt in its block order. All three share the direction and signature move and differ in UX strategy: navigation model, how the work areas divide the screen, which data leads, density, primary interaction. Name each strategy in one line.

Save prompts to `prompts/`, write `jobs.jsonl`, and generate all three in one batch:

```bash
# jobs.jsonl, one line per option; "refs" optional
{"prompt": "<contents of prompts/A.txt>", "out": "/abs/<dir>/options/A.png", "refs": ["/abs/screenshot.png"]}

python3 <skill>/scripts/batch.py <dir>/jobs.jsonl --workers 3
```

About 1-2.5 min per image; all three share the plan quota; jobs whose `out` exists are skipped, so re-running resumes. Single image or edit: `bash <skill>/scripts/gen.sh --prompt "<text>" --out /abs/out.png [--ref /abs/ref.png]...`.

| exit | meaning | action |
|---|---|---|
| 3 | `codex` or `python3` missing | stop, report |
| 4 | `--ref` file missing | fix path |
| 5 | `codex exec` failed (auth, network) | stop, suggest `codex login` |
| 7 | no image produced (feature off) | stop, report |
| 8 | refused by content policy | ask the user how to rephrase; never soften silently |
| 9 | plan quota or rate limit | stop, tell the user |

If stderr shows `image tool received a rewritten prompt:` and the meaning changed, tell the user.

Open each image and run the review in prompting.md. Regenerate a failing option once with the failing block restated; report if it fails again.

## 3. Pick

```bash
python3 <skill>/scripts/board.py --title "<surface>: pick one" --out <dir>/board.html \
  <dir>/options/A.png "A · <strategy>" <dir>/options/B.png "B · <strategy>" <dir>/options/C.png "C · <strategy>"
open <dir>/board.html
```

Show the three images inline too, with one line per option on its strategy and trade-off. Ask: which one, what to keep from the others, what feels wrong. Then stop and wait. Accepted answers: pick; pick + changes (regenerate that one with `--ref` to the pick and the change in words); combine (regenerate with both as `--ref`); reject all (back to step 2 with the reasons). Repeat until one image is approved. Do not start code before approval.

## 4. Lock and spec

Copy the approved image to `reference.png` and write `reference.json`. Then write `spec.md`:

1. **Scale:** calibrate with [references/production-scale.md](references/production-scale.md). The image gives proportions, hierarchy, and topology; absolute sizes come from the production ranges. Never copy image pixels as CSS pixels.
2. **Tokens:** palette mapped to roles (`python3 <skill>/scripts/palette.py <dir>/reference.png` for sampled colors), type steps, radius, spacing grid, shadows.
3. **Regions:** each region with its proportion of the frame and its job.
4. **Components:** inventory with every state each needs (not only the states drawn).
5. **Patterns:** the category pattern inventory from [references/patterns.md](references/patterns.md), each marked must / should / skip.
6. **Stack:** chosen with [references/stack.md](references/stack.md), with a one-line reason.
7. **Not literal:** things in the image that are placeholder, invented, or outside the brief.

Painted imagery (illustration, game art, texture) is a raster asset: generate it with gen.sh using a crop of the reference as `--ref`; text, controls, and layout are code.

## 5. Build

Set up the chosen stack from its current docs, map the spec tokens into the component kit's theme first, then build screens from kit components. Use realistic seed data (20-50 items, mixed lengths, every state) so density is designed, not discovered. Keep the reference's topology and hierarchy; do not recompose. Apply [references/build-floor.md](references/build-floor.md) and build every must/should pattern.

## 6. Quality gate (bounded)

Run [references/quality-gate.md](references/quality-gate.md):

1. Fidelity: screenshot the main state at the reference's aspect and build `compare.html`:
   ```bash
   python3 <skill>/scripts/board.py --title "reference vs build" --out <dir>/compare.html \
     <dir>/reference.png "Reference" <dir>/qa/main-1440.png "Build"
   ```
   Check topology, proportions, palette roles, hierarchy, signature move. Sizes follow the spec's calibrated scale, not the image.
2. The screenshot matrix, interaction script, axe check, native-control check, and scale check.
3. The independent judge (fresh agent, different model if available) scoring 6 categories; floor 8/10 each.

Fix all findings in one batch, re-run once; at most 2 fix rounds. Report final scores, check results, and remaining gaps honestly.
