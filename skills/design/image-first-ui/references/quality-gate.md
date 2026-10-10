# Release quality gate

Fidelity to the reference is necessary, not sufficient. The gate asks whether the build would pass as a shipped product of its category.

## 1. Test matrix (screenshots)

Capture every cell with real browser screenshots into `<dir>/qa/`:

| | empty | 1 item | realistic (20-50 items) | long text / edge | detail or dialog open |
|---|---|---|---|---|---|
| 1440x900 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 1024x768 | | | ✓ | | ✓ |
| 390x844 | ✓ | | ✓ | | ✓ |

Add a dark-theme row when the product ships dark. Seed data must be realistic: plausible titles, mixed lengths, dates spread across past/today/future, every status.

## 2. Automated checks

- Interaction script: every `must`/`should` pattern from the inventory exercised once (add, edit, complete, undo, delete, move, search, keyboard path), and every overlay (menu, popover, dialog, sheet, palette, toast) opened at least once. Zero console errors and zero uncaught page errors: an overlay that throws on open can unmount the whole app while static checks stay green.
- Accessibility: run axe-core on the main view and with the dialog open; zero serious or critical violations.
- No unstyled native controls: date, time, select, checkbox, and file inputs use the component kit, not browser chrome.
- Scale: computed body text and control heights fall inside production-scale.md ranges.

## 3. Independent judge

Spawn a fresh agent (different model if available) with only: the brief, `reference.png`, the pattern inventory, and the matrix screenshots. It scores each category 0-10 with one line of evidence per score and lists concrete fixes:

1. **Hierarchy:** read order matches the brief; primary action is the most findable thing.
2. **Density & scale:** real work fits; sizes match the category; no oversized or cramped areas.
3. **Consistency:** one spacing grid, one radius set, one icon style, aligned edges, consistent type steps.
4. **Control quality:** every control is a polished component with hover, focus, active, disabled states; no browser defaults.
5. **States & edge cases:** empty, loading, error, long text, many items, undo, all handled and designed.
6. **Finish:** looks like a shipped product of the category's best tier: details, micro-interactions, copy, nothing placeholder.

Judge prompt core: "You are a principal product designer reviewing a release candidate. Score strictly against the best shipped products in this category, not against prototypes. A 10 is indistinguishable from the category leader's quality; 8 is shippable; below 8 blocks release. Cite the screenshot for every point."

Running the judge through Codex (a different model than the builder, read-only, screenshots attached):

```bash
codex exec --skip-git-repo-check --sandbox read-only -m <model> -o <dir>/judge-1.md \
  -i <dir>/reference.png -i <dir>/qa/<shot>.png ... - < <dir>/judge-prompt.md
```

The prompt names each attached image in order, points at `brief.md` and `spec.md`, states the automated results, and asks for a score table plus at most 12 concrete fixes with the screenshot each comes from. Screenshots cannot show hover, open menus, or toasts unless you capture them: include those states in the matrix.

## 4. Fix loop

Floor: every category ≥ 8 and all automated checks green. Fix all findings in one batch, re-run the matrix and the judge once. At most 2 fix rounds; then report the remaining scores and findings honestly instead of looping.
