#!/usr/bin/env bash
# verify skill — run a scenario suite.
#
# Reads one JSON file per endpoint and fires every variant through call.sh.
# See references/scenario-design.md for the file format.
#
#   scripts/run-scenarios.sh                      # all files in <run>/scenarios/
#   scripts/run-scenarios.sh path/to/one.json     # just these
#
# Exits 0 only when every variant passes.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib.sh"

vf_load_adapter
vf_require_cmd jq
vf_require_cmd curl
[ -n "$VERIFY_RUN_DIR" ] || vf_init_run_dir "scenarios" >/dev/null

files=()
if [ $# -gt 0 ]; then
  files=("$@")
else
  for f in "$VERIFY_RUN_DIR"/scenarios/*.json; do
    [ -f "$f" ] && files+=("$f")
  done
fi

[ "${#files[@]}" -gt 0 ] || vf_die "no scenario files. Write them to $VERIFY_RUN_DIR/scenarios/ first."

total=0
passed=0
failed_names=""

for f in "${files[@]}"; do
  jq -e . "$f" >/dev/null 2>&1 || vf_die "not valid JSON: $f"

  slug="$(basename "$f" .json)"
  endpoint="$(jq -r '.endpoint // "unnamed"' "$f")"
  auth="$(jq -r '.auth // "required"' "$f")"
  count="$(jq '.variants | length' "$f")"

  vf_log ""
  vf_log "--- $endpoint ($count variants, auth=$auth) ---"

  i=0
  while [ "$i" -lt "$count" ]; do
    name="$(jq -r ".variants[$i].name" "$f")"
    method="$(jq -r ".variants[$i].method // \"GET\"" "$f")"
    vpath="$(jq -r ".variants[$i].path" "$f")"
    source="$(jq -r ".variants[$i].source // \"unspecified\"" "$f")"

    # Query object -> url-encoded query string.
    query="$(jq -r ".variants[$i].query // {} | to_entries | map(\"\(.key)=\(.value|tostring|@uri)\") | join(\"&\")" "$f")"

    # Body: a JSON object is re-serialized; a string is passed through.
    body="$(jq -r ".variants[$i].body // empty | if type == \"string\" then . else tojson end" "$f")"

    args=(--name "$slug.$name" --method "$method" --path "$vpath" --source "$source")
    [ -n "$query" ] && args+=(--query "$query")
    [ -n "$body" ] && args+=(--body "$body")
    [ "$auth" = "none" ] && args+=(--no-auth)

    ct="$(jq -r ".variants[$i].contentType // empty" "$f")"
    [ -n "$ct" ] && args+=(--content-type "$ct")

    while IFS= read -r st; do
      [ -n "$st" ] && args+=(--expect-status "$st")
    done < <(jq -r ".variants[$i].expect.status // empty | if type == \"array\" then .[] else . end" "$f")

    while IFS= read -r expr; do
      [ -n "$expr" ] && args+=(--expect-jq "$expr")
    done < <(jq -r ".variants[$i].expect.jq // [] | .[]" "$f")

    # A variant may call as a different identity — that is what an `authz`
    # variant is. The adapter builds VERIFY_TOKEN_SUBJECT from these same
    # variables, so the token cache key changes with them and the wrong
    # cached token is never reused.
    envs=()
    while IFS= read -r kv; do
      [ -n "$kv" ] && envs+=("$kv")
    done < <(jq -r ".variants[$i].env // {} | to_entries | map(\"\(.key)=\(.value|tostring)\") | .[]" "$f")

    total=$((total + 1))
    if env ${envs+"${envs[@]}"} "$HERE/call.sh" "${args[@]}"; then
      passed=$((passed + 1))
    else
      failed_names="$failed_names $slug.$name"
    fi

    i=$((i + 1))
  done
done

vf_log ""
vf_log "=================================================="
vf_log "scenario suite: $passed/$total passed"
if [ -n "$failed_names" ]; then
  vf_log "failed:$failed_names"
  vf_log "receipts: $VERIFY_RUN_DIR/receipts/04-scenario/"
  vf_log "=================================================="
  exit 1
fi
vf_log "receipts: $VERIFY_RUN_DIR/receipts/04-scenario/"
vf_log "=================================================="
