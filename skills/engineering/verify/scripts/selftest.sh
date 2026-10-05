#!/usr/bin/env bash
# verify skill — self-test.
#
# Runs all five gates against a throwaway server, then asserts that the
# harness itself behaved: the token cached, a failing assertion produced a
# FAIL, and the token never reached a receipt.
#
#   scripts/selftest.sh
#
# Needs curl, jq, and python3. Exits 0 when the harness is sound.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$HERE/.." && pwd)"

export VERIFY_SKILL_DIR="$SKILL_DIR"
export VERIFY_TARGET_DIR="$SKILL_DIR"
export VERIFY_ADAPTER=selftest
export SELFTEST_PORT="${SELFTEST_PORT:-8778}"

. "$HERE/lib.sh"

for c in curl jq python3; do vf_require_cmd "$c"; done

# The subscripts each load the adapter for themselves. This script also needs
# it, for VERIFY_BASE_URL in the health poll.
vf_load_adapter

# A server left behind by an interrupted run holds the port and every later
# run then fails on bind with a message that says nothing about the cause.
if lsof -ti "tcp:$SELFTEST_PORT" >/dev/null 2>&1; then
  vf_warn "port $SELFTEST_PORT is in use; stopping the process that holds it"
  lsof -ti "tcp:$SELFTEST_PORT" | xargs kill 2>/dev/null
  sleep 1
fi

checks=0
problems=0

# A `case` pattern's closing paren would end a $( ) substitution, so prefix
# matching lives in a function instead.
starts_with() {
  case "$2" in
    "$1"*) echo yes ;;
    *)     echo no ;;
  esac
}
check() {
  checks=$((checks + 1))
  if [ "$2" = "$3" ]; then
    printf '  ok    %s\n' "$1" >&2
  else
    printf '  FAIL  %s (expected %s, got %s)\n' "$1" "$3" "$2" >&2
    problems=$((problems + 1))
  fi
}

RUN_DIR="$(VERIFY_RUN_DIR="" vf_init_run_dir selftest)"
export VERIFY_RUN_DIR="$RUN_DIR"
vf_log "run dir: $VERIFY_RUN_DIR"

cleanup() {
  [ -n "${SERVER_PID:-}" ] && kill "$SERVER_PID" 2>/dev/null
  rm -rf "$VERIFY_TOKEN_CACHE_DIR"
}
trap cleanup EXIT

# --------------------------------------------------------------------------
vf_log ""
vf_log "== gate 1: build =="
"$HERE/gate-build.sh" >/dev/null 2>&1
check "gate-build exits 0" "$?" 0
check "build receipt exists" "$([ -f "$VERIFY_RUN_DIR/receipts/01-build.log" ] && echo yes || echo no)" yes

# --------------------------------------------------------------------------
vf_log ""
vf_log "== gate 2: static =="
"$HERE/gate-static.sh" >/dev/null 2>&1
check "gate-static exits 0" "$?" 0
check "static receipt exists" "$([ -f "$VERIFY_RUN_DIR/receipts/02-static.log" ] && echo yes || echo no)" yes
# The adapter's first check reads stdin. All three must still run.
check "all 3 static checks ran" \
  "$(grep -c '^--- ' "$VERIFY_RUN_DIR/receipts/02-static.log" 2>/dev/null | tr -d ' ')" 3

# --------------------------------------------------------------------------
vf_log ""
vf_log "== gate 4a: service up =="
rm -rf "$VERIFY_TOKEN_CACHE_DIR"
# Redirect the server's streams to a file. A background process that inherits
# this script's stdout holds the pipe open, so a caller piping to `tail` waits
# for the server instead of for the test.
( cd "$VERIFY_TARGET_DIR" && python3 scripts/selftest/server.py "$SELFTEST_PORT" ) \
  > "$VERIFY_RUN_DIR/receipts/00-server.log" 2>&1 &
SERVER_PID=$!
vf_wait_healthy 20 >/dev/null
check "health responds" "$?" 0

# --------------------------------------------------------------------------
vf_log ""
vf_log "== gate 4b: token =="
TOKEN="$("$HERE/token.sh" 2>/dev/null)"
check "token acquired" "$([ -n "$TOKEN" ] && echo yes || echo no)" yes
check "token looks like a JWT" "$(starts_with 'eyJ' "$TOKEN")" yes

# Second call must come from the cache, not the network.
cache_msg="$("$HERE/token.sh" 2>&1 >/dev/null | grep -c 'cache hit')"
check "second call hits the cache" "$cache_msg" 1

hdr="$("$HERE/token.sh" --header 2>/dev/null)"
check "header form is correct" "$(starts_with 'Authorization: Bearer eyJ' "$hdr")" yes

# --------------------------------------------------------------------------
vf_log ""
vf_log "== gate 4d: scenarios =="
cat > "$VERIFY_RUN_DIR/scenarios/items.json" <<'JSON'
{
  "endpoint": "GET /api/items",
  "auth": "required",
  "variants": [
    {
      "name": "happy",
      "method": "GET",
      "path": "/api/items",
      "query": { "limit": 3 },
      "expect": { "status": 200, "jq": [".code == \"00000\"", ".data.items | length == 3", ".data.total == 3"] },
      "source": "synthesized"
    },
    {
      "name": "boundary",
      "method": "GET",
      "path": "/api/items",
      "query": { "limit": 0 },
      "expect": { "status": 200, "jq": [".data.items | length == 0"] },
      "source": "synthesized"
    },
    {
      "name": "negative",
      "method": "GET",
      "path": "/api/items",
      "query": { "limit": "not-a-number" },
      "expect": { "status": 400 },
      "source": "synthesized"
    }
  ]
}
JSON

"$HERE/run-scenarios.sh" >/dev/null 2>&1
check "scenario suite exits 0" "$?" 0
check "3 receipts written" "$(ls "$VERIFY_RUN_DIR/receipts/04-scenario/" | wc -l | tr -d ' ')" 3

# --------------------------------------------------------------------------
vf_log ""
vf_log "== harness behaviour =="

# A negative variant must not be satisfied by a 500. Prove the assertion
# actually discriminates rather than passing on any response.
"$HERE/call.sh" --name selftest.wrong-status --method GET --path /api/items \
  --query 'limit=3' --expect-status 418 >/dev/null 2>&1
check "wrong expected status is a FAIL" "$?" 1

# An unauthenticated call must be refused, which proves the token header was
# doing real work in the passing variants.
"$HERE/call.sh" --name selftest.no-auth --method GET --path /api/items \
  --no-auth --expect-status 401 >/dev/null 2>&1
check "no-auth call is refused with 401" "$?" 0

# A variant with no stated expectation must not pass.
"$HERE/call.sh" --name selftest.no-expectation --method GET --path /api/items \
  --query 'limit=1' >/dev/null 2>&1
check "no expectation stated is a FAIL" "$?" 1

# The credential must not be on disk in any receipt.
leak="$(grep -rl "$TOKEN" "$VERIFY_RUN_DIR/receipts/" 2>/dev/null | wc -l | tr -d ' ')"
check "token absent from every receipt" "$leak" 0
redacted="$(grep -rl 'REDACTED' "$VERIFY_RUN_DIR/receipts/04-scenario/" 2>/dev/null | wc -l | tr -d ' ')"
check "receipts show redaction happened" "$([ "$redacted" -gt 0 ] && echo yes || echo no)" yes

# Redaction must consume the whole header value. BSD sed reads [^\r] as "not
# backslash, not r", so an earlier version stopped at the first r and left the
# rest of an opaque token in the clear.
opaque="$(printf 'Authorization: Bearer secret-r-value-123\n' | vf_redact)"
check "opaque token fully redacted" "$opaque" "Authorization: <REDACTED>"
cookie="$(printf 'Set-Cookie: session=r4bbit; Path=/\n' | vf_redact)"
check "cookie fully redacted" "$cookie" "Set-Cookie: <REDACTED>"

# The forbidden-host guard must actually refuse the call, not just document it.
VERIFY_FORBIDDEN_HOSTS='^127\.0\.0\.1$' "$HERE/call.sh" \
  --name selftest.forbidden-host --method GET --path /api/items \
  --query 'limit=1' --expect-status 200 >/dev/null 2>&1
check "forbidden host is refused" "$?" 1
check "no receipt written for a refused host" \
  "$([ -f "$VERIFY_RUN_DIR/receipts/04-scenario/selftest.forbidden-host.txt" ] && echo yes || echo no)" no

# Verdicts must be recorded for gate 5 to read back.
check "verdicts file exists" "$([ -f "$VERIFY_RUN_DIR/verdicts.tsv" ] && echo yes || echo no)" yes

# --------------------------------------------------------------------------
vf_log ""
vf_log "=================================================="
vf_log "self-test: $((checks - problems))/$checks checks passed"
vf_log "artifacts: $VERIFY_RUN_DIR"
vf_log "=================================================="
[ "$problems" -eq 0 ]
