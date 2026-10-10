# Scorecard

Score each in-scope dimension 1-5 (half points allowed) from receipts of one build. Use the lowest score across devices and languages. A floor breach caps its dimension at 3. A criterion with no receipt is a gap; n/a criteria leave the denominator; a dimension with gaps in more than a quarter of its remaining criteria cannot score above 3. A gap counts against the bar the way a fail does, but it is reported as missing evidence, never as a product defect.

**Quality %:** average / 5 x 100, rounded down. A 4.5 average is 90%.

**Default bar:** every in-scope dimension >= 4, average >= 4.5 (quality >= 90%), all floors pass, and for a release candidate the judge's verdict is PASS. The override can raise the bar or drop a dimension the owner verifies personally; it cannot lower a floor.

## Anchors

| Score | Meaning |
|---|---|
| 1 | Broken: a core journey cannot be finished, or the product cannot be read on the smallest device. |
| 2 | Usable only with effort; several floor breaches. |
| 3 | Works, but a first-time user stumbles: a floor breach, or several clear criterion failures. Typical prototype. |
| 4 | Shippable: no floor breach; a few minor misses a careful reviewer notices and a user rarely hits. |
| 5 | Matches or beats the reference products on the same journeys; nothing a reviewer can name with a receipt. |

| Dim | 3 looks like | 4 looks like | 5 looks like |
|---|---|---|---|
| Experience | Readable on big phones only, generic look, missing states, clipped Korean. | UX-1 rubric passes, every state designed, settings matrix holds. | Side by side with the reference, it holds up in every language and setting. |
| Function | Happy path works; resume, offline, or double submit breaks something. | Every journey and boundary passes on the shipped artifact; writes are atomic. | `bughunt` persona matrix passes twice clean; previous-version data migrates. |
| Consumer | A new user needs help; trust links missing or stale; listing oversells. | New users finish core journeys; trust surfaces complete; no deceptive patterns. | Faster to first value than the reference; field signals stay positive release over release. |
| Engineering | Tests exist but skip UI; budgets unmeasured; manual release steps. | All suites in the default command and pre-push; budgets met on the smallest device; clean reproducible release. | Budgets met in field data; crash and hang trends flat or falling; every past defect has a guard. |

## Severity

| Severity | Meaning | Order |
|---|---|---|
| blocker | Floor breach or broken core journey. | Fix first; blocks release. |
| major | A first-time user stumbles, or a budget is missed. | Next, by score gain per effort. |
| minor | A careful reviewer notices; users rarely hit it. | When majors are done. |
| polish | Beyond the bar. | Only when the owner asks. |

## Score sheet

```
Build: <commit / build no. / URL>   Date: <YYYY-MM-DD>   Judge: <self | independent>
Profile: <ios-app | web | game | ...>   Devices: <smallest> / <largest> / <iPad mode>   Languages: <list>
Bar: dims >= 4, avg >= 4.5 (90%), floors pass
| Dim         | Score | Lost, and why (finding IDs) | Floors        | Main receipts               |
| Experience  |       |                             | F-5 F-6       |                             |
| Function    |       |                             | F-1 F-2 F-3   |                             |
| Consumer    |       |                             | F-4 F-7 F-8 F-9 |                           |
| Engineering |       |                             | F-7 F-10      |                             |
Average: x.xx   Quality: xx%   Result: PASS | FAIL
Findings, in order of impact:
1. [FN-2, F-2] blocker: draft lost after kill during save (resume_se3_ko_after_kill.png) -> write to temp file, fsync, rename; guard: test_kill_during_save
Evidence gaps: <criteria with no receipt>   n/a: <criteria and reason>
```

## Judge prompt

Send to a separate agent that has not seen the code or the builder's reasoning. Attach only receipts (screenshots, recordings, test output, measurements, listing text) and this prompt.

```
You are an independent product-quality judge for a <iPhone app | website | web app | <genre> game>.
Judge only the receipts attached. You have not seen the code.

Context:
- Build: <id>. Reject any receipt that names another build as stale.
- Profile and devices: <smallest> / <largest> / <iPad compatibility mode or desktop width>.
- Languages: <list, primary first>.
- Core journeys and their done-when: <list>.
- Reference products to compare against: <1-3 names>.
- Previous round's findings: <list>. Mark each fixed, partly fixed, or not fixed.

Score 1-5 (half points allowed) for: Experience, Function, Consumer, Engineering
<drop any dimension the override excludes>.
Anchors: 3 = works but a first-time user stumbles, or a floor is broken;
4 = no floor broken, only minor misses, shippable; 5 = matches the reference products.
Floors (any breach caps that dimension at 3): no crash/freeze/soft-lock or data loss in a core journey;
every core journey completes from fresh install; no placeholder text, dead links, or debug UI;
contrast >= 4.5:1, targets >= 44 pt (iOS) / 24 CSS px (web), iOS text >= 11 pt;
every screen fits on every device class including iPad compatibility mode;
declared data collection matches actual; no deceptive pricing, renewal, pre-selection, or cancel friction;
in-product account deletion if accounts exist; no weakened or skipped checks.
A criterion with no receipt is a gap and blocks PASS; a stale, vacuous (asserts nothing), or flaky receipt counts as FAIL for that criterion. A criterion marked n/a with a reason you accept leaves the count.

Bar: every dimension >= <4>, average >= <4.5>, all floors pass. Quality % = average / 5 x 100, rounded down.

Output:
1. PASS or FAIL, quality %, average, bar.
   For each dimension below 5: the points lost and the findings that cost them.
2. Score table with the main receipt per dimension.
3. Findings in order of impact, max 8: criterion ID if known, receipt and position, what is wrong,
   a concrete change with numbers (pt, ms, %, steps).
4. Evidence gaps to capture next round.
Be strict. Do not praise. Tie every finding to a receipt.
```
