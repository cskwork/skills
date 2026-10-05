# Clean-code gate

Gate 3. A review of the diff, by eye, for the things a compiler and a linter cannot see.

Judge the diff. Not the file it lives in, and not the module around it. When you find a real problem outside the diff, write it as a note and leave it alone.

## The severity bar

Two levels. The bar decides whether the gate fails, so it has to be sharp.

**Blocking** — fails the gate. A reviewer who saw this would ask for a change before merge.

**Note** — recorded, gate still passes. Real, but not worth blocking a ship.

When you cannot decide, it is a note. A gate that blocks on taste stops being believed, and then it stops being read.

## Blocking findings

Seven. Each is a defect in the change itself, not a difference of style.

1. **A masked symptom.** A `catch` that logs and continues, a null check that returns an empty list, a default that hides a missing value. The error still happened. Now nobody will find out. Fix the cause instead.
2. **An unrequested behaviour change.** The diff changes an output the task did not ask about. Either it is a bug the author did not notice, or it is scope creep. Both need a decision.
3. **A split source of truth.** The same rule now decides in two places. The next person will change one of them.
4. **A name that lies.** `getUser` writes. `isValid` mutates. `total` holds a count. The reader trusts the name and then debugs for an hour.
5. **A hardcoded environment value.** A URL, a credential, a port, a tenant id, an account id, a date. It works on the author's machine.
6. **A new path with no boundary handling.** The diff introduces a branch that the diff itself leaves unguarded against empty, null, or zero. Not a general audit of the file — only paths this change created.
7. **Dead code from this change.** A replaced method left in place, a flag nothing reads, an import for a deleted call. It reads as live to the next person.

## Note-level findings

Naming that could be clearer but is not wrong. Comment density against the surrounding code. A long method that was already long. An extraction that would help but is not needed. Ordering and grouping.

## Reading order

Work through the diff once per question. One pass per question finds more than one pass looking for everything.

1. **Does it read like its neighbours?** Match the file's own naming, comment density, and idiom. A correct change in a foreign style costs the next reader time.
2. **Does the control flow stay flat?** A new nesting level, an early return that skips cleanup, a loop that mutates what it iterates.
3. **Is every new name honest?** Read each identifier the diff adds. Ask what a reader would expect it to do.
4. **What happens on the sad path?** Follow the error, the empty result, and the missing field to where they surface.
5. **What did the change leave behind?** Old code, old comments, old tests, old flags.

## Output

One row per changed file. Write `none` where you found nothing — an empty table does not distinguish clean from unread.

```markdown
| File | Severity | Finding |
|------|----------|---------|
| `src/.../TotalService.java` | blocking | `catch (Exception e)` at line 84 logs and returns 0. A failed lookup now reports a valid total of zero. |
| `src/.../TotalMapper.xml` | note | The new `CASE` duplicates the grade logic in `selectGradeBand`. Extract it when this file is next touched. |
| `src/.../dto/TotalRequest.java` | none | |
```

Then one line the report can carry: the count of blocking findings and the count of notes.
