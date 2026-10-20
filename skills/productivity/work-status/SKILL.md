---
name: work-status
description: Progress snapshot of the user's current request in numbers (items done, in progress, todo, and blocked) plus an ETA for the rest. Use when the user asks how far the work has got ("/work-status", "작업 현황", "진행 상황", "어디까지 됐어").
---

# work-status

Answer "where are we?" so the user can act after one read: how many items are done, how many are left, how long the rest takes, and what needs the user. The report reads state only; implementation pauses for it.

## Steps

1. **Build the ledger**: one line per deliverable of the user's request, at the granularity the user would name (usually 3-10 items). Take items from, in order: the active todo/task list, the plan file (`PLAN.md`, `.sdlc/`, a kanban card), then the request text itself. Tag items the user added after the original request `+added`, so scope growth shows in the total. With no request in view (fresh session), use the plan file and recent commits; if those are empty too, ask which work to report. Done when every part of the request maps to exactly one ledger item.

2. **Classify each item on evidence**:
   - `done`: its completion criterion was checked: a test or build run, command output, a file or URL that exists, a commit or push hash. Cite it in a few words.
   - `in progress`: started, criterion not yet checked. Name the current sub-step. Written-but-unverified work lands here.
   - `todo`: not started.
   - `blocked`: waiting on the user, access, or an external system. Name exactly what unblocks it.

   Refresh cheap evidence now (`git status`, `git log -1`, state of delegated agents and background jobs). For slow checks, reuse the last run and give its time. Done when every item has one state and every `done` cites evidence.

3. **Estimate the rest** as a range of agent working minutes per open item, summed into one ETA. Set the pace from this session's finished work: how long each `done` item or finished sub-step took, read from timestamps (commits, file mtimes, logs, the session transcript, `date`). Before anything is finished, size items by scope and label the ETA `rough`. A `blocked` item's working minutes count in the ETA; the wait for the user or an external system does not. Done when the ETA is a range with its basis in one phrase.

4. **Report** with the template, in the user's language. If the request arrived while work was running, resume that work after the report.

## Template

The header line carries the whole picture for a reader who stops there.

```
**{done}/{total} done ({pct}%) · in progress {n} · todo {n} · blocked {n} · ETA {lo}-{hi} min ({basis}) · elapsed {n} min**

Done ({n})
1. {item}: {evidence}

In progress ({n})
2. {item}: {current sub-step}, ~{lo}-{hi} min

Todo ({n})
3. {item}: ~{lo}-{hi} min

Blocked ({n})
4. {item}: needs {what unblocks it}, then ~{lo}-{hi} min

Risks: {failing check, scope change, threat to the ETA}, one line each.
Next: {the next action}.
```

- `{pct}` counts items; the ETA carries effort.
- Drop `elapsed` when no timestamp gives it.
- Drop empty sections; the header keeps their zero.
- One line per item, with numbers, thresholds, and scoped conditions exact.
- A question the user must answer goes last, after Next.
