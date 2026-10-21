# Brief a delegate

Loaded by the `call-agent` router whenever the delegated task reads or changes code, data,
or infrastructure (implementation, fixes, migrations, reviews of a plan). The brief is the
delegate's whole world: it starts with none of your context, so every premise it needs must
be in the brief and true where the delegate runs.

## Fields

1. **Objective and acceptance criteria** — checkable conditions, not "make it work".
2. **Owned paths and checkout** — the directory or worktree the delegate works in, its
   branch or ref, and the only paths it may write. Shared files get one owner.
3. **Verified facts** — every fact the plan depends on, quoted from the delegate's own
   checkout: a `git -C <checkout> show HEAD:<path>` excerpt with line numbers, or a
   command and its real output. Label any fact that holds only on another ref with that
   ref (`only on origin/develop`). A fact you have not checked goes under step 4 or is
   left out.
4. **Data shape** — when the design depends on what the data looks like (uniqueness,
   nulls, duplicates, cardinality, volume), give the query that measured it and its
   result. When nobody has measured it yet, make measuring the delegate's first step and
   keep the design conditional on the result.
5. **Consumers** — for every interface the change touches (event payload, API response,
   DTO, schema, CLI output, file format), list the consumers' paths and how they treat
   the change: strict deserialization, unknown-field rejection, version checks. State the
   deploy order when one side must ship first.
6. **Baseline** — existing test failures with the command that produced them, so the
   delegate neither chases nor hides them.
7. **Constraints** — forbidden actions (commit, push, deploy, external writes) and the
   sandbox access the work needs: name every directory outside the working root it must
   write, such as build caches and log directories, and pass it to the target's
   add-dir option.
8. **Autonomy line** — "This brief is the agreed scope. Proceed to the acceptance
   criteria without asking; stop with one blocking question only when a verified fact
   turns out false." A delegate that inherits ask-first instructions otherwise pauses on
   its first step.

## Re-brief after a rejected result

Quote the delegate's own objection or premise-mismatch report verbatim in the next brief,
then say which premise changed and why. A corrected brief that drops the objection repeats
the failure.

**Done =** every field above filled or marked not applicable, each verified fact traceable
to the delegate's checkout or a recorded output.
