# Token module

`scripts/token.sh`. One job: print a usable bearer token on stdout.

Everything else — logs, warnings, errors — goes to stderr, so `TOKEN=$(scripts/token.sh)` captures the token and nothing else.

## Use it

```sh
export VERIFY_ADAPTER=spring-mybatis
export VERIFY_TARGET_DIR=/path/to/repo

TOKEN=$(scripts/token.sh)                 # cached when fresh, acquired when not
scripts/token.sh --header                 # "Authorization: Bearer <token>"
scripts/token.sh --refresh                # force a new one, after a 401
scripts/token.sh --status                 # cache state, acquires nothing
scripts/token.sh --clear                  # drop the cache
```

`scripts/call.sh` calls it for you. You rarely need it by hand except when debugging a new adapter.

## Why it caches

A thirty-variant suite would otherwise log in thirty times. Some auth backends rate-limit that. Some charge for it. Some issue a token that invalidates the previous one, so the suite fights itself.

The cache lives in `<target>/.verify/.token-cache/`, mode 600, keyed by a hash of the adapter path, the mode, the URL, the query, the body, and `VERIFY_TOKEN_SUBJECT`.

That last one matters. **Put every value that changes the identity into `VERIFY_TOKEN_SUBJECT`.** Without it, switching from an admin to a member reuses the admin's cached token. The calls then authenticate and fail every business rule, and the receipts look like an application bug.

`VERIFY_TOKEN_TTL` should sit below the real expiry. A suite that starts fresh and hits a 401 at variant nineteen produces a receipt file that reads as a broken endpoint.

## The five modes

| Mode | Use when | Needs |
|------|----------|-------|
| `static` | A human or CI can supply a token. | `VERIFY_TOKEN_STATIC` |
| `http_get` | A dev-token endpoint takes query params. | `VERIFY_TOKEN_URL`, `VERIFY_TOKEN_QUERY` |
| `http_post_json` | A JSON login endpoint. | `VERIFY_TOKEN_URL`, `VERIFY_TOKEN_BODY` |
| `http_post_form` | An OAuth2 or form login. | `VERIFY_TOKEN_URL`, `VERIFY_TOKEN_BODY` |
| `command` | Anything else. | `VERIFY_TOKEN_COMMAND` |

`command` is the escape hatch and it covers more cases than the others combined: a browser login script, an OAuth device flow, `aws sts`, `gcloud auth print-identity-token`, a local signing script. Its stdout is the token, or the JSON that `VERIFY_TOKEN_JQ` reads.

When a login script prints progress alongside the token, pipe it: `... | tail -1`.

## Extraction

`VERIFY_TOKEN_JQ` is a jq path into the response body:

```sh
VERIFY_TOKEN_JQ=".data.accessToken"     # {"data":{"accessToken":"ey..."}}
VERIFY_TOKEN_JQ=".token"                # {"token":"ey..."}
VERIFY_TOKEN_JQ=""                      # the body is the token
```

A wrong path is a loud failure, not a silent one: the script prints the redacted response and exits non-zero. It never caches an empty token, because a cached empty token turns every later call into a 401 that looks like an authorization defect.

A leading `Bearer ` in the extracted value is stripped, so a header-shaped response works too.

## A failed acquisition is BLOCKED

The script exits non-zero and says so. Gate 4 records `BLOCKED`, not `FAIL`.

The distinction carries information. `FAIL` says the code is wrong. `BLOCKED` says you could not look. Reporting a credential problem as a code problem sends the next person to debug the wrong thing.

## Credentials stay off disk

The token is written only to the cache file, mode 600, inside a `.verify/` directory you should gitignore.

`scripts/lib.sh` redacts on the way into every receipt: JWTs by shape, `Authorization`, `Cookie`, `Set-Cookie` and `X-Api-Key` headers, JSON fields named for secrets, and the live token value by exact match.

Do not put a real password in an adapter you commit. Reference the environment instead:

```sh
VERIFY_TOKEN_BODY="{\"username\":\"${DEV_USER:?set DEV_USER}\",\"password\":\"${DEV_PASS:?set DEV_PASS}\"}"
```

The `:?` form fails at load with a clear message. A missing variable otherwise expands to an empty string, and the receipt shows a 401 for a reason nobody can see.

## Adding a stack

1. Copy `adapters/_template.env`.
2. Find the auth entry point. Read the security config or middleware for what it accepts, and look for a dev-only login or mint endpoint.
3. Check the bootstrap is not circular. A mint endpoint sitting behind the auth filter it mints for cannot issue your first token. Look for an offline signing path or a seeded credential instead. This is common enough to check every time.
4. Set `VERIFY_TOKEN_SUBJECT` to whatever identifies the caller.
5. Run `scripts/token.sh --status`, then `scripts/token.sh`.
6. Call one known-good endpoint with the token before trusting it. A token that parses is not a token the service accepts.
