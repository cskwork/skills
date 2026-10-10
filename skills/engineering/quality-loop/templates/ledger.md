# Quality ledger

Durable quality record for this project. Read it before a run; append to it before reporting. Newest round on top. Never delete a round; mark superseded receipts instead.

## Current state

| Field | Value |
|---|---|
| Last build scored | <commit / build no. / URL + entry and bundle hashes> |
| Result | <PASS / FAIL>, quality <xx>%, avg <x.xx> (Experience <s> · Function <s> · Consumer <s> · Engineering <s>) |
| Judge | <independent / self>, <date> |
| Fix rounds (this session) | <n> of <cap> |
| Open blockers | <count, IDs> |

## Verification records

A check listed here is done for the build or source hash it names. Re-run it only when the hash changes or an invalidating change lands. A URL alone never identifies a build.

| Date | Criterion / scope | Bound to | Result | Invalidated by |
|---|---|---|---|---|
| <YYYY-MM-DD> | <FN-1 J1-J5, iPhone SE + iPad compat, ko/en> | <commit or source hash> | <pass> | <any change under Sources/Persistence/> |

## Ratchet guards

Every fixed finding leaves a guard. Audit rounds propose guards; improve rounds install them. Removing a guard needs the owner's approval and a reason here.

| Criterion | Defect | Guard (test, lint, CI check, checklist line) | Status | Added |
|---|---|---|---|---|
| <FN-2> | <draft lost after kill during save> | <test_kill_during_save> | <proposed / installed> | <date, commit> |

## Rounds

Audit rounds are `audit <n>`; fix rounds are `fix <n>` and count toward the cap.

### <audit 1 | fix 1> · <YYYY-MM-DD> · build <id>

- Mode: <audit / improve / maintain>; scope: <full / changed since last round>
- Scores: Experience <s> · Function <s> · Consumer <s> · Engineering <s> → avg <x.xx>, quality <xx>% <PASS/FAIL>
- Why not higher: <dimension: points lost, finding IDs>
- Floors: <all pass / F-x breached: receipt>
- Fixed: <[ID] what, guard>
- Deferred: <[ID] why, trigger to revisit>
- Open, in order of impact: <[ID] receipt -> concrete change>
- Evidence gaps and n/a: <criteria with no receipt; n/a with reason>
- Receipts: <evidence_dir path>

## Exceptions and decisions

| Date | Decision | Who confirmed |
|---|---|---|
| <YYYY-MM-DD> | <dropped Function dimension: owner verifies journeys by hand> | <owner> |
