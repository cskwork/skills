---
name: verify-app
description: Build and run the app to prove a code change does what it should, by driving the changed behavior end to end and reporting the evidence. Use after implementing a change and before committing, or when asked to verify, smoke-test, or prove that a change works in the running app. Tests and type checks are not the proof here. For agents without a built-in verify, such as Codex; in Claude Code prefer the bundled /verify.
disable-model-invocation: true
---

# verify-app

Prove the change in the running app. A passing test suite or a clean type check is not the proof this skill produces.

## 1. Name the change

- Read the diff: `git diff HEAD` (or against the base branch when the work is committed).
- Write one sentence: "After this change, <observable result> happens when <action>."
- If you cannot write it, the change has no runnable behavior (docs, refactor with no visible effect). Report `not applicable` and stop.

## 2. Find how the app runs

Use a recorded recipe first, in this order:

1. `.agents/skills/run-*/SKILL.md`, `.claude/skills/run-*/SKILL.md`, `.claude/skills/verify/SKILL.md`
2. README, `package.json` scripts, `Makefile`, `justfile`, `docker-compose.yml`, `Procfile`

Use dev or local configuration only. Never point the run at production data or services.

## 3. Run it and drive the changed path

| App type | How to exercise the change |
| --- | --- |
| CLI | Run the command with input that reaches the changed code. |
| Server or API | Start it in the background, wait for it to answer, then call the changed endpoint with `curl`. |
| Web UI | Start the dev server and drive the page with a browser tool (Playwright, agent-browser). Take a screenshot of the result. |
| TUI | Run it in a pseudo-terminal (`tmux`, `script`) and capture the screen. |
| Library | Write a throwaway script that calls the public API the way a user would. Do not add it to the test suite. |

Exercise the main path, then one edge or failure case the change should handle.

## 4. Capture evidence

For every step, keep: the exact command, exit code, and the relevant output (HTTP status and body excerpt, log lines, or screenshot path). Evidence you did not capture did not happen.

## 5. Clean up

Stop every process you started and delete scratch files and data you created.

## 6. Save the recipe

If getting the app running took more than the obvious command, save the steps that worked as a project skill at `.agents/skills/run-<app>/SKILL.md` so the next run starts from them.

## Report

```
Verdict: verified | failed | blocked | not applicable
Change: <the one sentence from step 1>
Ran: <commands, in order>
Evidence: <outputs, statuses, screenshot paths>
Not covered: <what this run did not exercise>
```

- **failed:** say what happened versus what should have. Do not fix and re-claim without running again.
- **blocked:** name the blocker (missing secret, external service, hardware) and what was proven instead. Never report `verified` for a run that did not happen.
