# Spring Boot + MyBatis — worked example

Config: [`spring-mybatis.env`](spring-mybatis.env).

Generalized from writing and running this skill against a real Spring Boot 3 and MyBatis service. Every trap below was found by executing, not by reading. None of them is visible from outside the repository, and each one produces a *wrong verdict* rather than an obvious error — which is why they matter more than the parts that fail loudly.

## 1. Two ports, one of them a decoy

Spring Boot commonly runs the application on one port and the actuator on another, and only the application port carries the context path.

| Port | Serves | Context path |
|------|--------|--------------|
| 8080 | Your APIs | `/api` |
| 18081 | Actuator | none |

An earlier version of this skill used the management port as its base URL and probed `/actuator/health`. The health check passed. Every endpoint call then went to the management port without the context path and failed. The suite reported a service that was answering correctly as broken.

**The rule that generalizes: probe health on the same base URL the scenario calls use.** A health check on a different port proves a different listener is alive.

Prefer the application's own health endpoint over actuator when it has one, because it sits behind the same context path and the same filter chain.

## 2. The IDE fights the build

Run `./gradlew compileJava` while an IDE has the project open and you get:

```
Cannot access output property 'destinationDirectory' of task ':compileJava'
  > java.nio.file.NoSuchFileException: build/classes/.../SomeDto__Javadoc.json
```

The IDE writes into `build/classes` continuously. Gradle snapshots the task outputs, a file disappears mid-snapshot, and the build reports a failure with nothing to do with your code. Adding `clean` does not help — the IDE writes again straight away.

The fix is isolation, not cleaning: `-Dorg.gradle.project.buildDir=build-verify`.

That also protects gate 4. `clean` deletes `build/libs/*.jar`, which is what `VERIFY_RUN_CMD` starts, so gate 1 would break gate 4. I did exactly that during development and had to rebuild a 142 MB jar.

**Two rules generalize:** gate 1 must not destroy what gate 4 needs, and a shared workspace has writers you did not account for.

## 3. The token bootstrap is often circular

Services frequently ship a dev-only mint endpoint, gated by profile:

```java
@Profile({"local", "dev"})
@RequestMapping("/test")
public class JwtTestController { ... }
```

You may not be able to call it. If `/test/**` is absent from the security config's permit list, `anyRequest().authenticated()` refuses the request with 403. The endpoint that mints the first token requires a token.

**Check this before writing the adapter, every time.** The usual way out is an offline signing script committed in the repo, using the same HS256 secret the dev profile validates with. Then `VERIFY_TOKEN_MODE=command` runs it.

Two follow-on traps:

- **A session may be required alongside the signature.** Look for a "token only auth" flag in the auth filter's config. It often defaults to false, and with no session in the cache the filter rejects a perfectly valid token. The status code looks like an application defect and is not one.
- **An offline token may carry fewer claims than a real login.** Compare the signing helper's claim list against the production token factory. If the helper calls a 5-argument overload while the factory sets seven claims, every endpoint scoped by one of the missing two cannot be verified this way. That is a coverage gap to name in the report's "what I did not verify" section — not something to work around.

## 4. MyBatis XML fails at the first call, not at compile

The Java compiler never reads `src/main/resources/**/*Mapper.xml`. A malformed statement, an unescaped `<` in a comparison, or a typo in a statement id compiles clean and throws when the endpoint runs. An unescaped `<>` in mapper XML has crash-looped a production pod.

So gate 2 runs `xmllint --noout` over the mapper files. Cheap check, expensive failure.

`xmllint` catches malformed XML only. It does not catch a valid-XML SQL error, a wrong column, or a join that returns too many rows. Those are gate 4's job, and for a changed query the **value** assertion in the `happy` variant is the one that tests them.

Two more MyBatis-specific gate-4 checks:

- **`selectOne` against a non-unique `WHERE`.** `TooManyResultsException` fires only when the data happens to have two matching rows. A changed `selectOne` needs a `boundary` variant built from a row that *does* have duplicates, or the check proves nothing.
- **A `LEFT JOIN` whose columns are absent from `GROUP BY`.** Widening or narrowing the join predicate then changes *values* without changing the row count. If you assert only on row count you will see no difference and conclude, wrongly, that the change did nothing. Assert on the field whose provenance the change was about.

That last one caught me. I set out to assert a row-count difference and the count was identical in both directions. The real fix had removed a cross join, and the honest assertion was per-record provenance.

## 5. Is the process running your code?

The trap that most deserves its own gate step.

Something is often already listening on the port — an IDE run, a container from last week, this morning's session. It answers health perfectly and serves code that predates your change. Every variant passes and the report certifies a fix that is not deployed.

I hit this. A process had been listening on the application port since 18:05:52. The commit under test was authored at 18:08:16. Verifying against it would have been a clean, confident, false pass.

Check it, do not assume it:

- Compare the process start time against the commit time. A process older than the commit cannot contain it.
- Or read a build identifier the service exposes.
- Or restart it yourself.

Found a foreign process? Do not kill it — it may be someone's debugger. Start a second instance, and move **both** ports.

## 6. "Local" is often not local

A dev profile usually points at a shared development database and cache, with encrypted connection strings. Running locally then means a local JVM against remote shared data.

Two consequences, both belonging in the plan you show the user before gate 4:

- **A write variant changes data other people are using.** Get approval per write endpoint. Run read variants first.
- **A VPN outage makes gate 4 `BLOCKED`, not `FAIL`.** The service will not boot at all.

Also confirm which profiles actually exist. A `@Profile({"local","dev"})` annotation does not mean a `local` profile is defined anywhere.

## 7. A 4xx contract that ships as 500

Worth measuring rather than assuming, because it changes how you write `negative` variants.

A platform may declare its validation errors as one status in an error-code enum and emit another on the wire. Check with a real call before you write the expectation:

```sh
curl -si "$BASE/api/resource?id=-1" | head -1
```

When the wire status disagrees with the code, find out whether it is **pre-existing** before blaming the diff. Call an older endpoint that the change did not touch. Same behaviour means platform-wide and pre-existing: record it as a note with the evidence, and do not block the gate.

Then set the `negative` variant's expectation to the status the service *actually* returns today. Asserting the status you wish it returned makes the variant fail and misattributes a platform issue to your change.

Still say it in the report. A 500 on bad input means the caller cannot tell "you sent something wrong" from "we are broken", and that is worth someone's attention even when it is nobody's regression.

## Preflight

```sh
export VERIFY_ADAPTER=spring-mybatis
export VERIFY_TARGET_DIR=/path/to/service

scripts/gate-build.sh
scripts/gate-static.sh
scripts/token.sh --status
scripts/token.sh                    # needs the service up
curl -s -o /dev/null -w '%{http_code}\n' "$VERIFY_BASE_URL$VERIFY_HEALTH_PATH"
```

An adapter that survives those five is worth committing.
