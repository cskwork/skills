#!/usr/bin/env bash
# verify skill — one recorded API call.
#
# Fires a single request and writes a receipt: the request, the response, and
# the outcome of every assertion. Exits 0 only when all assertions pass.
#
#   scripts/call.sh --name summary.happy \
#                   --method GET --path /api/v1/reports/summary \
#                   --query 'accountId=15978' \
#                   --expect-status 200 \
#                   --expect-jq '.data != null' \
#                   --expect-jq '.data.total == 12'
#
# Options:
#   --name <id>            receipt name, usually <endpoint>.<variant>
#   --method <verb>        default GET
#   --path <path>          appended to VERIFY_BASE_URL, or a full URL
#   --query <qs>           raw query string, no leading ?
#   --body <json|form>     request body
#   --content-type <ct>    default application/json when a body is present
#   --header <line>        extra header, repeatable
#   --no-auth              omit the token header
#   --expect-status <code> exact status, repeatable for "any of"
#   --expect-jq <expr>     jq expression that must yield true, repeatable
#   --source <rung>        payload provenance, recorded in the receipt

set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

NAME=""
METHOD=GET
PATH_ARG=""
QUERY=""
BODY=""
CONTENT_TYPE=""
SOURCE="unspecified"
NO_AUTH=0
EXTRA_HEADERS=()
EXPECT_STATUS=()
EXPECT_JQ=()

while [ $# -gt 0 ]; do
  case "$1" in
    --name)           NAME="$2"; shift ;;
    --method)         METHOD="$2"; shift ;;
    --path)           PATH_ARG="$2"; shift ;;
    --query)          QUERY="$2"; shift ;;
    --body)           BODY="$2"; shift ;;
    --content-type)   CONTENT_TYPE="$2"; shift ;;
    --header)         EXTRA_HEADERS+=("$2"); shift ;;
    --source)         SOURCE="$2"; shift ;;
    --no-auth)        NO_AUTH=1 ;;
    --expect-status)  EXPECT_STATUS+=("$2"); shift ;;
    --expect-jq)      EXPECT_JQ+=("$2"); shift ;;
    -h|--help)        sed -n '2,30p' "$0" | sed 's|^# \{0,1\}||'; exit 0 ;;
    *) vf_die "unknown argument: $1" ;;
  esac
  shift
done

[ -n "$NAME" ]     || vf_die "--name is required"
[ -n "$PATH_ARG" ] || vf_die "--path is required"

vf_load_adapter
vf_require_cmd curl
[ -n "$VERIFY_RUN_DIR" ] || vf_init_run_dir "adhoc" >/dev/null

RECEIPT="$VERIFY_RUN_DIR/receipts/04-scenario/$NAME.txt"
mkdir -p "$(dirname "$RECEIPT")"

# --------------------------------------------------------------------------
# Build the request.
# --------------------------------------------------------------------------

url="$PATH_ARG"
case "$url" in
  http://*|https://*) ;;
  *) url="${VERIFY_BASE_URL:-}$url" ;;
esac
[ -n "$QUERY" ] && case "$url" in
  *\?*) url="$url&$QUERY" ;;
  *)    url="$url?$QUERY" ;;
esac

vf_guard_target "$url"

headers=()
if [ "$NO_AUTH" -eq 0 ]; then
  token_header="$("$(dirname "${BASH_SOURCE[0]}")/token.sh" --header)" || {
    vf_record_verdict "4:$NAME" BLOCKED "token acquisition failed"
    vf_die "cannot authenticate; scenario is BLOCKED"
  }
  headers+=("$token_header")
  export VERIFY_TOKEN_VALUE="${token_header#*: }"
  VERIFY_TOKEN_VALUE="${VERIFY_TOKEN_VALUE#Bearer }"
  export VERIFY_TOKEN_VALUE
fi

if [ -n "$BODY" ]; then
  [ -n "$CONTENT_TYPE" ] || CONTENT_TYPE="application/json"
  headers+=("Content-Type: $CONTENT_TYPE")
fi

if [ -n "${VERIFY_EXTRA_HEADERS:-}" ]; then
  while IFS= read -r hline; do
    [ -n "$hline" ] && headers+=("$hline")
  done <<EOF
$VERIFY_EXTRA_HEADERS
EOF
fi

for h in ${EXTRA_HEADERS+"${EXTRA_HEADERS[@]}"}; do headers+=("$h"); done

curl_args=(-s -X "$METHOD" --max-time "${VERIFY_CALL_TIMEOUT:-30}")
for h in ${headers+"${headers[@]}"}; do curl_args+=(-H "$h"); done
[ -n "$BODY" ] && curl_args+=(--data-binary "$BODY")

# --------------------------------------------------------------------------
# Fire it.
# --------------------------------------------------------------------------

hdr_file="$(mktemp)"
body_file="$(mktemp)"
started="$(date +%s)"

status="$(curl "${curl_args[@]}" -D "$hdr_file" -o "$body_file" -w '%{http_code}' "$url" 2>/dev/null || echo 000)"
elapsed=$(( $(date +%s) - started ))

# --------------------------------------------------------------------------
# Assert.
# --------------------------------------------------------------------------

assert_lines=""
result=PASS

add_assert() {
  assert_lines="${assert_lines}$(printf '%-52s %s' "$1" "$2")
"
  [ "$2" = PASS ] || result=FAIL
}

if [ "${#EXPECT_STATUS[@]}" -gt 0 ]; then
  matched=0
  for want in "${EXPECT_STATUS[@]}"; do
    [ "$status" = "$want" ] && matched=1
  done
  if [ "$matched" -eq 1 ]; then
    add_assert "status in [${EXPECT_STATUS[*]}]" PASS
  else
    add_assert "status in [${EXPECT_STATUS[*]}] (got $status)" FAIL
  fi
else
  add_assert "status (no expectation stated: proves nothing)" FAIL
fi

if [ "${#EXPECT_JQ[@]}" -gt 0 ]; then
  vf_require_cmd jq
  for expr in "${EXPECT_JQ[@]}"; do
    got="$(jq -r "$expr" < "$body_file" 2>/dev/null)"
    if [ "$got" = "true" ]; then
      add_assert "jq: $expr" PASS
    else
      add_assert "jq: $expr (got: ${got:-<error or empty>})" FAIL
    fi
  done
fi

# --------------------------------------------------------------------------
# Write the receipt.
# --------------------------------------------------------------------------

{
  echo "=== VARIANT ==="
  echo "name:           $NAME"
  echo "payload source: $SOURCE"
  echo "at:             $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "=== REQUEST ==="
  echo "$METHOD $url"
  for h in ${headers+"${headers[@]}"}; do echo "$h"; done
  if [ -n "$BODY" ]; then echo; echo "$BODY"; fi
  echo
  echo "=== RESPONSE ==="
  echo "status:   $status"
  echo "duration: ${elapsed}s"
  echo "--- headers ---"
  cat "$hdr_file"
  echo "--- body ---"
  if command -v jq >/dev/null 2>&1 && jq -e . < "$body_file" >/dev/null 2>&1; then
    jq . < "$body_file"
  else
    cat "$body_file"
  fi
  echo
  echo "=== ASSERTIONS ==="
  printf '%s' "$assert_lines"
  echo
  echo "RESULT: $result"
} | vf_redact > "$RECEIPT"

rm -f "$hdr_file" "$body_file"

vf_log "[$NAME] $result (status $status) -> $RECEIPT"
vf_record_verdict "4:$NAME" "$result" "status $status"

[ "$result" = PASS ]
