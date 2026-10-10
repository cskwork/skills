---
name: quality-loop
description: Product quality bar and improvement loop for iPhone apps, websites, web apps, games, and other software. Scores UI/UX, function, consumer trust, and engineering against hard floors, gates release candidates with an independent judge, and ratchets every fix in a ledger. Use to audit quality, bring a product up to the bar, gate a release candidate, or maintain quality per change or on a schedule (완성도, 품질 개선 루프).
license: MIT
---

# quality-loop

One standard and one loop for "is this product good enough for a paying consumer, and does it stay that way?"

- **Bar**: every in-scope dimension scores >= 4 of 5, average >= 4.5 (quality >= 90%), all floors pass. A project can raise it; floors never relax.
- **Quality %**: the average score / 5 x 100, rounded down to a whole number. Every report opens with it and the reason for each lost point.
- **Floor**: a hard minimum (crash, data loss, broken core journey, accessibility minimum, deceptive design...). Any floor breach caps its dimension at 3 and blocks release.
- **Receipt**: evidence bound to one build (commit or build number, date, device, language). A receipt from another build is stale.
- **Ledger**: the project's durable quality record. Read it first, write it last.
- **Ratchet**: every fixed defect leaves a guard (test, lint rule, CI check, checklist line) so quality only moves up.
- **Judge**: a fresh-context agent that sees only receipts, the scorecard, and the bar. A self-score never closes a gate.

Green tests prove the code does what the tests say. They do not prove the product is good. Score the product a person actually gets.

## Files

| File | Read when |
|---|---|
| [standard.md](standard.md) | Always. The four dimensions, criterion IDs, floors, profile matrix, checks. |
| [scorecard.md](scorecard.md) | Scoring, writing findings, sending the judge prompt. |
| [found-practices.md](found-practices.md) | Planning a run, briefing delegates, before reporting done. Lessons from real releases. |
| [references.md](references.md) | Citing or challenging a number. |
| [templates/quality.md](templates/quality.md) | The project has no `.quality.md` override yet. |
| [templates/ledger.md](templates/ledger.md) | The project has no ledger yet. |

## Modes

| Mode | Does | Edits product code |
|---|---|---|
| `audit` | Steps 0-4, then 7 and 8 with no fix round: record the baseline in the ledger, propose guards, clean up, report. | No |
| `improve` (default) | Steps 0-8, fix rounds until the bar or the round cap. | Yes |
| `maintain` | Step 0, then steps 1-8 scoped to what changed since the last ledger receipt, plus field signals (CS-7). Full audit on a release candidate. Runs per change, per PR, or on a schedule (`/loop`). | Yes, within scope |

## Specialist skills

Use these when installed; otherwise use the fallback in `standard.md`. Name them in every delegate prompt: delegates do not inherit skills.

| Need | Skill |
|---|---|
| Aesthetic direction, visual critique, polish | `impeccable` |
| Mobile usability rules, 7-category UX rubric | `mobile-ui-ux` |
| Interaction bugs via seeded personas and invariants | `bughunt` |
| Browser checks, Lighthouse, scripted journeys | `browser-qa`, `playwright-cli`, or Chrome DevTools |
| Security review | `security-review` |
| Claims of done | `verification-before-completion` |

## The loop

### 0. Frame

Read repository instructions, the override (`.quality.md`, else `docs/quality.md`), and the ledger (path in the override, default `QUALITY-LEDGER.md`). If no override exists, draft one from `templates/quality.md`: infer the profile, core journeys, devices, and languages from the code, or from the shipped artifact when there is no source, and label them inferred.

Before the first fix round, the owner confirms three things: the dimensions in scope, the core journeys, and 1-3 reference products the result must hold up against. The override's `confirmed_by` records it; later runs reuse it until the owner changes it. Audit mode may proceed on stated defaults: keep all four dimensions, and with no owner pick a reference product yourself, label it `agent-chosen`, and mark UX-5 and CS-1 provisional.

Done when: profile, dimensions, core journeys (each with a done-when), devices, languages, reference products, bar, and budgets are written in the override.

### 1. Baseline

Identify the build: commit, dirty diff, build number, tool versions; for a deployed URL, the SHA-256 of the entry document and main bundles, since a URL alone can serve changed assets. Build or serve the **shipped artifact** (release/exported build, production bundle), not only the editor or a debug run. Check the ledger: a criterion whose receipt is bound to this exact build or source hash is already verified; skip it and say so. URL equality alone never skips a check.

Done when: build identity is recorded and the evidence matrix (criteria x devices x languages x states) lists what this round will capture.

### 2. Collect receipts

Run the checks in `standard.md` for every in-scope criterion: journeys through the real UI from a fresh install, screenshots at the smallest and largest device (and iPad compatibility mode for iPhone apps), measurements, test runs, store/legal checks. Use separate test profiles and data; leave the owner's devices and data alone. Name screenshots `<screen>_<device>_<lang>_<state>.png` and keep them in the override's `evidence_dir`.

Done when: every in-scope criterion has a receipt or is listed as an evidence gap. A gap is reported as a gap, never as a pass.

### 3. Score and write findings

Score each dimension with `scorecard.md`. Mark each criterion pass, fail, gap, or n/a with its reason (`standard.md` defines them). Write each finding as: criterion ID, severity (blocker, major, minor, polish), receipt, and a concrete change with numbers. In audit mode, name the guard each fix should leave as a proposal.

Done when: the score sheet is complete and every finding cites a receipt.

### 4. Gate

The bar is met when every in-scope dimension passes, all floors pass, and, for a release candidate, the judge agrees. Send the judge prompt in `scorecard.md` to a separate agent with receipts only. An audit or a non-release round may self-score, labeled `Judge: self`; a self-score never closes a release gate.

Bar met: go to step 8. Audit mode: step 7. Otherwise: step 5.

### 5. Fix round

Take blockers first, then the largest score gain per effort; at most 8 findings per round. Fix the root cause. Keep every existing check at full strength: a failing check is diagnosed at its layer, and a test changes only when the spec says the new behavior is correct, with the reason in the commit. For each fix add a ratchet guard and name it in the ledger. Preserve unrelated work and existing features.

Done when: each finding in the round is fixed with a guard, or deferred with a reason.

### 6. Verify

Rebuild the shipped artifact. Re-run every check the round touched plus the full regression suite (core and UI tests together). Recapture receipts for touched screens. The judge re-scores with the previous round's findings listed and marks each fixed, partly fixed, or not fixed.

Done when: new receipts exist for this build and the judge has scored it.

### 7. Record and repeat

Append the round to the ledger: build, date, scores, fixed, open, guards added or proposed, and which future changes invalidate each receipt. Audit rounds are `audit n`; fix rounds are `fix n` and are the ones the cap counts. Keep the counter in the ledger, not in memory. Bar met or audit mode: step 8. Below the bar and under the round cap (default 3 fix rounds per session): step 5. Cap reached: stop and report the remaining findings with receipts; churning past the cap wastes the owner's money.

### 8. Close

Every mode ends here. Write the verification record to the ledger (scope, date, build, judge verdict, quality %). Stop simulators, emulators, servers, browsers, and processes this run created; delete simulator clones it made; leave the owner's own devices and sessions alone. Report in this shape. The first line is the quality %, the target, and who scored it; then one line per dimension with what it lost and the finding that cost it. Label a score with no independent judge `self-scored`.

```
Quality 82% (avg 4.13 / 5) · target >= 90% · FAIL · independent judge
quality-loop · improve · profile: ios-app · build 1.2.0 (14) @ a1b2c3d · 2026-10-09
Bar: dims >= 4, avg >= 4.5 (90%), floors pass · Judge: independent
Why not higher:
  Experience 4.5 (-0.5: [UX-6] Korean settings label clipped at the largest text size on SE, settings_se3_ko_xxl.png)
  Function 4.0 (-1.0: [FN-2] draft lost after kill during save, resume_se3_ko_after_kill.png; fixed this run, re-check next round)
  Consumer 4.5 (-0.5: [CS-2] 2 of 5 simulated new users stuck on sync sign-in)
  Engineering 3.5 (-1.5: [EN-3] first frame 620 ms on SE vs 400 ms budget; [EN-1] UI tests not in pre-push)
Floors: all pass
Fixed this run (3 rounds): [FN-2] resume after kill lost draft (guard: test_resume_draft) ...
Open, in order of impact: 1. [EN-3] first frame 620 ms on SE (launch_se3.trace) -> defer font load, target 400 ms
Evidence gaps: VoiceOver pass on settings not captured
Ledger: QUALITY-LEDGER.md round 3
```
