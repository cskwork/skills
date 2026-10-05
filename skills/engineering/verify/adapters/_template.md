# Writing an adapter

The gates are stack-agnostic. An adapter holds the six facts they cannot guess.

Write one once per repository. Save it as `<target-repo>/.verify/adapter.env`, which the scripts find on their own, or as `adapters/<name>.env` here and select it with `VERIFY_ADAPTER=<name>`.

Start from [`_template.env`](_template.env). See [`spring-mybatis.env`](spring-mybatis.env) and [`spring-mybatis.md`](spring-mybatis.md) for a filled-in example.

## Do not guess. Go read.

Every value below has an authoritative source in the repository. Read it. A build command copied from a blog post fails on the first run and costs more than the two minutes of looking.

| Fact | Where it lives |
|------|----------------|
| Build command | `README`, CI workflow files, `Makefile`, `package.json` scripts, `build.gradle` tasks |
| Static checks | The same CI workflow. Whatever the pipeline runs on a pull request is the honest list. |
| Run command and port | `README`, `docker-compose.yml`, a `run-*.sh` script, the server config file |
| Health path | The framework's default, confirmed by calling it |
| Token acquisition | The auth filter or middleware, plus any dev-only login endpoint |
| Account creation | Seed scripts, fixtures, migrations, a provisioning tool |

The CI workflow is the highest-value file. It already encodes what this project believes a passing build is.

## The six facts

### 1. Build

The cheapest command that proves the changed code compiles.

Prefer compile-only over a full build. `./gradlew compileJava` over `./gradlew build`; `tsc --noEmit` over `npm run build`. Gate 4 proves behaviour, so a six-minute test suite in gate 1 slows every iteration and proves nothing gate 4 will not prove better.

Add `--offline` or its equivalent when the repo vendors its dependencies. A gate that fails because the network blinked teaches the agent to ignore gate failures.

### 2. Static checks

Only tools the repo already owns. A linter you introduce reports its opinions, not this project's standards, and its two hundred findings bury the one that matters.

Scope to changed files where the tool supports it.

Include the checks a compiler misses: schema and mapper XML parsing, migration syntax, config file validity, lock-file drift.

### 3. Run

How the service starts locally, with the profile and the port.

Write down what it needs from outside: a database, a cache, a message broker, a secret. Say whether those are reachable from a laptop. This is the single most common reason gate 4 lands on `BLOCKED`, and knowing it up front is worth more than discovering it after a build.

The scripts do not run this command. A long-lived process needs the agent's own job control.

### 4. Health

The URL that answers when the service is ready. Confirm it by calling it — a guessed health path returns 404 and looks exactly like a service that failed to start.

### 5. Token

Pick the mode that matches the stack:

- **`static`** — the token comes from an environment variable or a CI secret. Simplest. Use it when a human can paste one.
- **`http_get`** / **`http_post_json`** / **`http_post_form`** — a login or dev-token endpoint. Set `VERIFY_TOKEN_JQ` to where the token sits in the response, or leave it empty when the body is the token.
- **`command`** — anything else. A browser login script, an OAuth device flow, a cloud CLI, a signing script. Its stdout is the token, or the JSON that `VERIFY_TOKEN_JQ` reads.

Two things to get right:

- **`VERIFY_TOKEN_TTL` below the real expiry.** A suite that starts fresh and dies on a 401 halfway through produces receipts that look like application failures.
- **`VERIFY_TOKEN_SUBJECT` set to whatever identifies the caller.** It is part of the cache key. Without it, a token for an admin gets reused for a member run and every business rule fails for reasons that have nothing to do with the diff.

Never commit a real credential. Point at an environment variable instead:

```sh
VERIFY_TOKEN_BODY="{\"username\":\"${DEV_USER:?set DEV_USER}\",\"password\":\"${DEV_PASS:?set DEV_PASS}\"}"
```

### 6. Account

The token needs a subject that exists. Record how to create one and what it needs.

Name the real mechanism: the seed script, the stored procedure, the provisioning CLI, the fixture file. Prefer whatever the team already uses over a hand-built row — a synthesized account that skips a required relation yields a token that authenticates and then fails every business rule, which reads as an application bug and wastes an hour.

## Check it before you trust it

Four commands, in order. Each one fails loudly and locally.

```sh
export VERIFY_ADAPTER=<name>
export VERIFY_TARGET_DIR=/path/to/repo

scripts/gate-build.sh          # fact 1
scripts/gate-static.sh         # fact 2
scripts/token.sh --status      # config parses, cache state
scripts/token.sh               # facts 4, 5, 6 — needs the service up
```

An adapter that survives those four is worth committing.
