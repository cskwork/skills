#!/usr/bin/env bash
# verify skill — token module.
#
# Prints a usable bearer token on stdout. Caches it, so a suite of many calls
# costs one login. Everything else goes to stderr.
#
#   TOKEN=$(scripts/token.sh)              # cached if fresh, else acquired
#   scripts/token.sh --refresh             # force a new one, e.g. after a 401
#   scripts/token.sh --header              # "Authorization: Bearer <token>"
#   scripts/token.sh --status              # report cache state, acquire nothing
#   scripts/token.sh --clear               # drop the cache
#
# Configured entirely by the adapter. See adapters/_template.env.

set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

MODE_REFRESH=0
MODE_OUTPUT=token
MODE_STATUS=0
MODE_CLEAR=0

while [ $# -gt 0 ]; do
  case "$1" in
    --refresh) MODE_REFRESH=1 ;;
    --header)  MODE_OUTPUT=header ;;
    --status)  MODE_STATUS=1 ;;
    --clear)   MODE_CLEAR=1 ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's|^# \{0,1\}||'; exit 0 ;;
    *) vf_die "unknown argument: $1" ;;
  esac
  shift
done

vf_load_adapter
vf_require_cmd curl

TOKEN_TTL="${VERIFY_TOKEN_TTL:-1500}"
HEADER_NAME="${VERIFY_TOKEN_HEADER_NAME:-Authorization}"
HEADER_PREFIX="${VERIFY_TOKEN_HEADER_PREFIX:-Bearer }"

# --------------------------------------------------------------------------
# Cache key. Any change to the adapter or to the identity we ask for must
# produce a different key, or a stale token gets reused for a new subject.
# --------------------------------------------------------------------------

_cache_key() {
  local material
  material="${VERIFY_ADAPTER_RESOLVED:-none}|${VERIFY_TOKEN_MODE:-}|${VERIFY_TOKEN_URL:-}|${VERIFY_TOKEN_QUERY:-}|${VERIFY_TOKEN_BODY:-}|${VERIFY_TOKEN_SUBJECT:-}"
  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$material" | shasum -a 256 | cut -c1-16
  else
    printf '%s' "$material" | cksum | tr -d ' ' | cut -c1-16
  fi
}

CACHE_KEY="$(_cache_key)"
CACHE_FILE="$VERIFY_TOKEN_CACHE_DIR/$CACHE_KEY.token"

_cache_age() {
  [ -f "$CACHE_FILE" ] || { printf '%s\n' -1; return; }
  local mtime now
  # BSD stat first (macOS), GNU stat second.
  mtime="$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)"
  now="$(date +%s)"
  printf '%s\n' "$((now - mtime))"
}

if [ "$MODE_CLEAR" -eq 1 ]; then
  rm -f "$CACHE_FILE"
  vf_log "cache cleared: $CACHE_FILE"
  exit 0
fi

if [ "$MODE_STATUS" -eq 1 ]; then
  age="$(_cache_age)"
  if [ "$age" -lt 0 ]; then
    vf_log "cache: empty ($CACHE_FILE)"
  elif [ "$age" -lt "$TOKEN_TTL" ]; then
    vf_log "cache: fresh, ${age}s old, ttl ${TOKEN_TTL}s"
  else
    vf_log "cache: stale, ${age}s old, ttl ${TOKEN_TTL}s"
  fi
  exit 0
fi

# --------------------------------------------------------------------------
# Serve from cache when it is fresh.
# --------------------------------------------------------------------------

emit() {
  local token="$1"
  export VERIFY_TOKEN_VALUE="$token"
  if [ "$MODE_OUTPUT" = header ]; then
    printf '%s: %s%s\n' "$HEADER_NAME" "$HEADER_PREFIX" "$token"
  else
    printf '%s\n' "$token"
  fi
}

if [ "$MODE_REFRESH" -eq 0 ]; then
  age="$(_cache_age)"
  if [ "$age" -ge 0 ] && [ "$age" -lt "$TOKEN_TTL" ]; then
    vf_log "token: cache hit (${age}s old)"
    emit "$(cat "$CACHE_FILE")"
    exit 0
  fi
fi

# --------------------------------------------------------------------------
# Acquire.
# --------------------------------------------------------------------------

mode="${VERIFY_TOKEN_MODE:-}"
[ -n "$mode" ] || vf_die "VERIFY_TOKEN_MODE is not set. Use static, http_get, http_post_json, http_post_form, or command."

raw=""
http_status=""

case "$mode" in
  static)
    [ -n "${VERIFY_TOKEN_STATIC:-}" ] || vf_die "VERIFY_TOKEN_MODE=static needs VERIFY_TOKEN_STATIC"
    raw="$VERIFY_TOKEN_STATIC"
    ;;

  command)
    [ -n "${VERIFY_TOKEN_COMMAND:-}" ] || vf_die "VERIFY_TOKEN_MODE=command needs VERIFY_TOKEN_COMMAND"
    vf_log "token: running VERIFY_TOKEN_COMMAND"
    raw="$(eval "$VERIFY_TOKEN_COMMAND")" || vf_die "VERIFY_TOKEN_COMMAND failed"
    ;;

  http_get|http_post_json|http_post_form)
    [ -n "${VERIFY_TOKEN_URL:-}" ] || vf_die "VERIFY_TOKEN_MODE=$mode needs VERIFY_TOKEN_URL"
    url="$VERIFY_TOKEN_URL"
    case "$url" in
      http://*|https://*) ;;
      *) url="${VERIFY_BASE_URL:-}$url" ;;
    esac

    tmp_body="$(mktemp)"
    set -- -s -o "$tmp_body" -w '%{http_code}' --max-time "${VERIFY_TOKEN_TIMEOUT:-20}"

    if [ -n "${VERIFY_TOKEN_QUERY:-}" ]; then
      case "$url" in
        *\?*) url="$url&$VERIFY_TOKEN_QUERY" ;;
        *)    url="$url?$VERIFY_TOKEN_QUERY" ;;
      esac
    fi

    case "$mode" in
      http_post_json)
        set -- "$@" -X POST -H 'Content-Type: application/json' --data-binary "${VERIFY_TOKEN_BODY:-{\}}"
        ;;
      http_post_form)
        set -- "$@" -X POST -H 'Content-Type: application/x-www-form-urlencoded' --data "${VERIFY_TOKEN_BODY:-}"
        ;;
    esac

    if [ -n "${VERIFY_TOKEN_EXTRA_HEADERS:-}" ]; then
      # Newline-separated "Name: value" lines.
      while IFS= read -r hline; do
        [ -n "$hline" ] && set -- "$@" -H "$hline"
      done <<EOF
$VERIFY_TOKEN_EXTRA_HEADERS
EOF
    fi

    vf_guard_target "$url"
    vf_log "token: $mode $url"
    http_status="$(curl "$@" "$url" 2>/dev/null || echo 000)"
    raw="$(cat "$tmp_body")"
    rm -f "$tmp_body"

    case "$http_status" in
      2*) ;;
      *)
        vf_log "--- token endpoint response (status $http_status) ---"
        printf '%s\n' "$raw" | vf_redact >&2
        vf_die "token acquisition failed with status $http_status. This gate is BLOCKED, not PASS."
        ;;
    esac
    ;;

  *)
    vf_die "unknown VERIFY_TOKEN_MODE: $mode"
    ;;
esac

# --------------------------------------------------------------------------
# Extract. An empty VERIFY_TOKEN_JQ means the response body *is* the token.
# --------------------------------------------------------------------------

token=""
if [ -n "${VERIFY_TOKEN_JQ:-}" ]; then
  vf_require_cmd jq
  token="$(printf '%s' "$raw" | jq -r "${VERIFY_TOKEN_JQ}" 2>/dev/null)"
  if [ -z "$token" ] || [ "$token" = null ]; then
    vf_log "--- token endpoint response ---"
    printf '%s\n' "$raw" | vf_redact >&2
    vf_die "VERIFY_TOKEN_JQ '${VERIFY_TOKEN_JQ}' found no token in the response."
  fi
else
  token="$(printf '%s' "$raw" | tr -d '\r\n' | sed 's|^ *||; s| *$||; s|^"||; s|"$||')"
  [ -n "$token" ] || vf_die "token endpoint returned an empty body."
fi

# Strip a prefix the endpoint may already have included.
token="${token#Bearer }"
token="${token#bearer }"

mkdir -p "$VERIFY_TOKEN_CACHE_DIR"
chmod 700 "$VERIFY_TOKEN_CACHE_DIR" 2>/dev/null || true
printf '%s' "$token" > "$CACHE_FILE"
chmod 600 "$CACHE_FILE" 2>/dev/null || true

vf_log "token: acquired, cached for ${TOKEN_TTL}s"
emit "$token"
