# Quality overrides

Copy to the project root as `.quality.md`. Keys shown with a concrete value have that default when missing. Keys shown in `<angle brackets>` have no default: fill them, or leave them out and the skill records a gap. Floors (F-1..F-10) cannot be relaxed; an exception that names a floor is ignored and reported.

```yaml
profile: ios-app            # ios-app | web | game | [game, web] for hybrids
dimensions: [experience, function, consumer, engineering]
                            # drop one only when the owner verifies it personally; say who
core_journeys:              # 3-7 journeys a paying user must finish
  - id: J1
    name: First run to first value
    steps: install fresh -> open -> <first meaningful action>
    done_when: <observable result, e.g. "first task saved and visible after relaunch">
    fixtures: <inputs the journey needs: a sample audio file, a seeded account, test data; "none" if none>
references:                 # 1-3 products the result must hold up against (UX-5, CS-1, GM-1)
  - <category leader>       # with no owner, the agent picks one and labels it agent-chosen
devices:
  smallest: iPhone SE 3, 375x667 pt @2x       # web: 320x568 CSS px @2x
  largest: iPhone Pro Max, 440x956 pt @3x     # web: 1280x800 CSS px desktop
  ipad: compatibility mode                    # compatibility mode | native | n/a
languages: [ko, en]         # shipped UI languages, primary first
appearance: both            # light | dark | both
autosave_interval_ms: 1000  # F-2: the last edit must persist within this, and before unload
input_limits: <declared maximum per field, or "none declared">
bar:
  min_dimension: 4
  min_average: 4.5   # quality >= 90%
  judge: independent        # release candidates always use an independent judge
budgets:                    # raise freely; lowering below a source number needs a reason
  ios_first_frame_ms: 400
  ios_main_thread_busy_ms: 250
  web_lcp_s: 2.5
  web_inp_ms: 200
  web_cls: 0.1
release_target: none        # app-store | play | web | internal | none
release_checklist: <path to the project's release checklist, if any>
ledger: QUALITY-LEDGER.md
evidence_dir: docs/quality/
round_cap: 3                # fix rounds per session before escalating
exceptions:                 # each needs criterion, scope, reason; floors cannot appear here
  - criterion: UX-6
    scope: Bold Text on the game board
    reason: board labels are icon-only; text size setting covers it
confirmed_by: <owner, date>  # who agreed to journeys, references, and dimensions; "none" for an ownerless audit
```

## Notes

Free text: brand tone, audience, known trade-offs, things the owner has already verified.
