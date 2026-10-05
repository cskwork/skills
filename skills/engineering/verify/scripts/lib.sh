#!/usr/bin/env bash
# verify skill — shared library.
# Sourced by the other scripts. Not meant to be run directly.
# Targets bash 3.2 so it works on a stock macOS shell.

set -uo pipefail

# --------------------------------------------------------------------------
# Paths
# --------------------------------------------------------------------------

VERIFY_SKILL_DIR="${VERIFY_SKILL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
VERIFY_TARGET_DIR="${VERIFY_TARGET_DIR:-$PWD}"
VERIFY_RUN_DIR="${VERIFY_RUN_DIR:-}"
VERIFY_TOKEN_CACHE_DIR="${VERIFY_TOKEN_CACHE_DIR:-$VERIFY_TARGET_DIR/.verify/.token-cache}"

# --------------------------------------------------------------------------
# Logging. Everything human-facing goes to stderr so stdout stays a clean
# channel for values such as the token.
# --------------------------------------------------------------------------

vf_log()  { printf '%s\n' "$*" >&2; }
vf_warn() { printf 'WARN: %s\n' "$*" >&2; }
vf_die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

vf_require_cmd() {
  command -v "$1" >/dev/null 2>&1 || vf_die "required command not found: $1"
}

# --------------------------------------------------------------------------
# Redaction.
#
# Receipts are committed to disk and pasted into reports, so credentials must
# not reach them. This filter reads stdin and writes a redacted copy.
#
# Add stack-specific patterns via VERIFY_REDACT_EXTRA, a newline-separated
# list of sed expressions.
# --------------------------------------------------------------------------

vf_redact() {
  local extra_file
  extra_file="$(mktemp)"

  {
    # JWTs — three base64url segments starting with the standard JOSE header.
    echo 's|eyJ[A-Za-z0-9_-]\{6,\}\.[A-Za-z0-9_-]\{6,\}\.[A-Za-z0-9_-]\{6,\}|<REDACTED-JWT>|g'
    # Authorization / cookie / api-key headers, request or response side.
    #
    # Use .* here, not [^\r]*. BSD sed reads [^\r] as "not backslash, not r",
    # so it stops at the first r and leaves the rest of the value in the clear.
    echo 's|\([Aa]uthorization: *\).*|\1<REDACTED>|g'
    echo 's|\([Cc]ookie: *\).*|\1<REDACTED>|g'
    echo 's|\([Ss]et-[Cc]ookie: *\).*|\1<REDACTED>|g'
    echo 's|\([Xx]-[Aa][Pp][Ii]-[Kk]ey: *\).*|\1<REDACTED>|g'
    # JSON fields that hold secrets.
    echo 's|"\(password\|passwd\|secret\|token\|accessToken\|access_token\|refreshToken\|refresh_token\|apiKey\|api_key\)" *: *"[^"]*"|"\1":"<REDACTED>"|g'
    # The live token value, when we know it.
    if [ -n "${VERIFY_TOKEN_VALUE:-}" ] && [ "${#VERIFY_TOKEN_VALUE}" -ge 8 ]; then
      printf 's|%s|<REDACTED-TOKEN>|g\n' "$(printf '%s' "$VERIFY_TOKEN_VALUE" | sed 's|[|\\&]|\\&|g')"
    fi
    if [ -n "${VERIFY_REDACT_EXTRA:-}" ]; then
      printf '%s\n' "$VERIFY_REDACT_EXTRA"
    fi
  } > "$extra_file"

  sed -f "$extra_file"
  rm -f "$extra_file"
}

# --------------------------------------------------------------------------
# Run directory. One per verification run; every receipt lands inside it.
# --------------------------------------------------------------------------

vf_init_run_dir() {
  local slug="${1:-run}"
  if [ -z "$VERIFY_RUN_DIR" ]; then
    VERIFY_RUN_DIR="$VERIFY_TARGET_DIR/.verify/$(date +%Y%m%d-%H%M)-$slug"
  fi
  mkdir -p "$VERIFY_RUN_DIR/receipts/04-scenario" \
           "$VERIFY_RUN_DIR/fixtures" \
           "$VERIFY_RUN_DIR/scenarios"
  export VERIFY_RUN_DIR
  printf '%s\n' "$VERIFY_RUN_DIR"
}

# --------------------------------------------------------------------------
# Adapter loading.
#
# An adapter is a plain shell file of VERIFY_* assignments. Resolution order:
#   1. $VERIFY_ADAPTER_FILE            explicit path
#   2. <target>/.verify/adapter.env    per-repo, checked in or local
#   3. <skill>/adapters/<name>.env     shipped adapter, selected by name
# --------------------------------------------------------------------------

vf_load_adapter() {
  local name="${1:-${VERIFY_ADAPTER:-}}"
  local candidate=""

  if [ -n "${VERIFY_ADAPTER_FILE:-}" ]; then
    candidate="$VERIFY_ADAPTER_FILE"
  elif [ -f "$VERIFY_TARGET_DIR/.verify/adapter.env" ]; then
    candidate="$VERIFY_TARGET_DIR/.verify/adapter.env"
  elif [ -n "$name" ] && [ -f "$VERIFY_SKILL_DIR/adapters/$name.env" ]; then
    candidate="$VERIFY_SKILL_DIR/adapters/$name.env"
  fi

  [ -n "$candidate" ] || vf_die "no adapter found. Set VERIFY_ADAPTER=<name> or write .verify/adapter.env (see adapters/_template.env)."
  [ -f "$candidate" ] || vf_die "adapter file not found: $candidate"

  # shellcheck disable=SC1090
  . "$candidate"
  VERIFY_ADAPTER_RESOLVED="$candidate"
  export VERIFY_ADAPTER_RESOLVED
  vf_log "adapter: $candidate"
}

# --------------------------------------------------------------------------
# Target guard.
#
# Refuses to call a host the adapter marked as forbidden. This exists because
# the mistake it prevents is not recoverable: one write variant against
# production is not something a later verdict can undo.
#
# VERIFY_FORBIDDEN_HOSTS is an extended-regex of hosts. Set it in the adapter
# to your production and any other off-limits hostnames.
# --------------------------------------------------------------------------

vf_guard_target() {
  local url="${1:-${VERIFY_BASE_URL:-}}"
  [ -n "${VERIFY_FORBIDDEN_HOSTS:-}" ] || return 0
  [ -n "$url" ] || return 0

  # Strip scheme, then userinfo, then path and port, leaving the host.
  local host="${url#*://}"
  host="${host#*@}"
  host="${host%%/*}"
  host="${host%%:*}"

  if printf '%s' "$host" | grep -qE "$VERIFY_FORBIDDEN_HOSTS"; then
    vf_die "target '$host' matches VERIFY_FORBIDDEN_HOSTS. This skill does not call it. Hand the user the command instead of running it."
  fi
}

# --------------------------------------------------------------------------
# Health. Polls until the service answers or the deadline passes.
# --------------------------------------------------------------------------

vf_wait_healthy() {
  local timeout="${1:-90}"
  local url="${VERIFY_BASE_URL:-}${VERIFY_HEALTH_PATH:-}"
  [ -n "${VERIFY_BASE_URL:-}" ] || vf_die "VERIFY_BASE_URL is not set"
  [ -n "${VERIFY_HEALTH_PATH:-}" ] || vf_die "VERIFY_HEALTH_PATH is not set"

  vf_guard_target "$url"

  local waited=0 code
  while [ "$waited" -lt "$timeout" ]; do
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$url" 2>/dev/null || echo 000)"
    case "$code" in
      2*|3*) vf_log "healthy: $url -> $code"; printf '%s\n' "$code"; return 0 ;;
    esac
    sleep 3
    waited=$((waited + 3))
  done

  vf_warn "not healthy after ${timeout}s: $url (last status ${code:-000})"
  printf '%s\n' "${code:-000}"
  return 1
}

# --------------------------------------------------------------------------
# Verdict lines. Appended to the run's verdict file so gate 5 can read them
# back instead of trusting memory.
# --------------------------------------------------------------------------

vf_record_verdict() {
  local gate="$1" verdict="$2" detail="${3:-}"
  case "$verdict" in
    PASS|FAIL|BLOCKED) ;;
    *) vf_die "verdict must be PASS, FAIL, or BLOCKED (got: $verdict)" ;;
  esac
  [ -n "$VERIFY_RUN_DIR" ] || vf_die "VERIFY_RUN_DIR is not set; call vf_init_run_dir first"
  printf '%s\t%s\t%s\n' "$gate" "$verdict" "$detail" >> "$VERIFY_RUN_DIR/verdicts.tsv"
  vf_log "[$gate] $verdict ${detail:+- $detail}"
}
