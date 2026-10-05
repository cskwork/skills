#!/usr/bin/env bash
# claude-call smoke test (this skill runs INSIDE Codex CLI; we test the
# wrapper scripts here, since you can also invoke them from any shell)
set -u

SKILL=claude-call
FAIL=0
note() { printf '[%s] %s\n' "$SKILL" "$*"; }
fail() { printf '[%s] FAIL: %s\n' "$SKILL" "$*" >&2; FAIL=1; }

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# L0 — claude binary present
if command -v claude >/dev/null 2>&1; then
  V=$(claude --version 2>&1 | head -1)
  note "L0 ok: claude $V"
else
  note "L0 skip: claude not on PATH"
  exit 3
fi

# L1 — wrapper scripts syntax-valid + help works
for s in scripts/preflight-auth.sh scripts/preflight-shell.sh scripts/claude-mcp-tools.sh scripts/claude-implement.sh scripts/claude-plan.sh scripts/claude-review.sh; do
  if bash -n "$SCRIPT_DIR/$s"; then
    note "L1a ok: $s syntax"
  else
    fail "L1a: $s syntax error"
  fi
done
if python3 -c 'import ast, pathlib; ast.parse(pathlib.Path(__import__("sys").argv[1]).read_text())' "$SCRIPT_DIR/scripts/claude-review-stream.py"; then
  note "L1a ok: scripts/claude-review-stream.py syntax"
else
  fail "L1a: scripts/claude-review-stream.py syntax error"
fi
if claude --help >/dev/null 2>&1; then
  note "L1b ok: claude --help"
else
  fail "L1b: claude --help failed"
fi

if grep -Eq 'dangerously-skip-permissions|bypassPermissions' \
  "$SCRIPT_DIR/scripts/claude-implement.sh" "$SCRIPT_DIR/scripts/preflight-shell.sh"; then
  fail "L1d: Claude write path weakens permission checks"
else
  note "L1d ok: Claude write path keeps permission checks"
fi

if grep -q -- '--max-budget-usd 0.05' "$SCRIPT_DIR/scripts/preflight-shell.sh"; then
  note "L1e ok: shell probe cost capped"
else
  fail "L1e: shell probe needs a cost cap"
fi

if grep -q -- '--safe-mode' "$SCRIPT_DIR/scripts/preflight-shell.sh" \
  && grep -q -- '--tools Bash' "$SCRIPT_DIR/scripts/preflight-shell.sh" \
  && grep -q -- '--max-turns 4' "$SCRIPT_DIR/scripts/preflight-shell.sh"; then
  note "L1f ok: shell probe context minimized"
else
  fail "L1f: shell probe must isolate configuration and tools"
fi

if grep -q -- 'CLAUDE_PROBE_MODEL:-haiku' "$SCRIPT_DIR/scripts/preflight-shell.sh"; then
  note "L1k ok: shell probe model honors CLAUDE_PROBE_MODEL"
else
  fail "L1k: shell probe model must stay overridable via CLAUDE_PROBE_MODEL"
fi

# L1g — planning and implementation allow configured MCP servers, with a safe fallback.
# Review intentionally has no MCP surface and is covered by the offline stream harness.
MCP_TEST_LOG=$(mktemp "${TMPDIR:-/tmp}/claude-mcp-test.XXXXXX")
claude() {
  if [ "${1:-}" = "auth" ] && [ "${2:-}" = "status" ]; then
    printf '%s\n' '{"loggedIn":true,"authMethod":"test"}'
    return 0
  fi
  if [ "${1:-}" = "mcp" ] && [ "${2:-}" = "list" ]; then
    [ "${CLAUDE_MCP_LIST_FAIL:-0}" = "1" ] && return 1
    printf '%s\n' \
      'Checking MCP server health…' \
      '' \
      'team server: https://example.test/mcp - ✔ Connected' \
      'claude.ai Figma: https://figma.example.test/mcp - ✔ Connected' \
      '한글.server: npx unicode-mcp - ✔ Connected' \
      'plugin:demo:tools: npx demo-mcp - ✘ Failed to connect'
    return 0
  fi

  case " $* " in
    *" --model "*)
      case " $* " in
        *" --max-turns "*) ;; # shell probe: not the delegated call
        *)
          for arg in "$@"; do
            printf 'ARG=%s\n' "$arg" >>"$MCP_TEST_LOG"
          done
          ;;
      esac
      ;;
  esac
  case " $* " in
    *" Run pwd with Bash. "*) printf '%s\n' '{"result":"SHELL_OK"}' ;;
    *) printf '%s\n' '{"result":"OK"}' ;;
  esac
}
export -f claude
export MCP_TEST_LOG

check_mcp_wrapper() {
  local wrapper=$1 expected=$2 list_fail=$3 expected_mode=$4 expected_tools=$5
  : >"$MCP_TEST_LOG"
  if LC_ALL=C CLAUDE_MCP_LIST_FAIL="$list_fail" "$SCRIPT_DIR/scripts/$wrapper" test >/dev/null 2>&1; then
    :
  else
    fail "L1g: $wrapper must still call Claude when MCP discovery fails"
    return
  fi

  if [ -n "$expected" ]; then
    if grep -Fqx -- "ARG=$expected" "$MCP_TEST_LOG"; then
      :
    else
      fail "L1g: $wrapper allowed tools mismatch (list_fail=$list_fail)"
      return
    fi
  elif grep -Fqx -- 'ARG=--allowedTools' "$MCP_TEST_LOG"; then
    fail "L1g: $wrapper must omit an empty allowed-tools flag"
    return
  fi

  if ! grep -Fqx -- "ARG=$expected_mode" "$MCP_TEST_LOG"; then
    fail "L1g: $wrapper permission mode must be $expected_mode"
    return
  fi
  if [ -n "$expected_tools" ]; then
    if ! grep -Fqx -- 'ARG=--tools' "$MCP_TEST_LOG" \
      || ! grep -Fqx -- "ARG=$expected_tools" "$MCP_TEST_LOG"; then
      fail "L1g: $wrapper built-in tool surface must be $expected_tools"
      return
    fi
  elif grep -Fqx -- 'ARG=--tools' "$MCP_TEST_LOG"; then
    fail "L1g: $wrapper must preserve its existing built-in tool surface"
    return
  fi

  if [ "$list_fail" = "0" ]; then
    note "L1g ok: $wrapper allows each configured MCP server"
  elif grep -Fq -- 'mcp__' "$MCP_TEST_LOG"; then
    fail "L1g: $wrapper must not invent MCP permissions after discovery failure"
  else
    note "L1g ok: $wrapper preserves its prior call after MCP discovery failure"
  fi
}

check_mcp_wrapper claude-plan.sh \
  'mcp__team_server mcp__claude_ai_Figma mcp_____server mcp__plugin_demo_tools' \
  0 dontAsk 'Read,Grep,Glob'
check_mcp_wrapper claude-implement.sh \
  'Read Grep Glob Edit Write Bash mcp__team_server mcp__claude_ai_Figma mcp_____server mcp__plugin_demo_tools' \
  0 acceptEdits ''
check_mcp_wrapper claude-plan.sh '' 1 dontAsk 'Read,Grep,Glob'
check_mcp_wrapper claude-implement.sh \
  'Read Grep Glob Edit Write Bash' 1 acceptEdits ''

# L1j — model selection is flexible: CLAUDE_MODEL overrides the opus default.
: >"$MCP_TEST_LOG"
if CLAUDE_MODEL=fable "$SCRIPT_DIR/scripts/claude-plan.sh" test >/dev/null 2>&1 \
   && grep -Fqx -- 'ARG=--model' "$MCP_TEST_LOG" \
   && grep -Fqx -- 'ARG=fable' "$MCP_TEST_LOG"; then
  note "L1j ok: CLAUDE_MODEL overrides the default model"
else
  fail "L1j: CLAUDE_MODEL override not honored"
fi
if CLAUDE_MODEL=sonnet "$SCRIPT_DIR/scripts/claude-implement.sh" test >/dev/null 2>&1 \
   && grep -Fqx -- 'ARG=sonnet' "$MCP_TEST_LOG"; then
  note "L1j ok: CLAUDE_MODEL overrides the implement model"
else
  fail "L1j: CLAUDE_MODEL override not honored by claude-implement.sh"
fi
: >"$MCP_TEST_LOG"

BASH32_NORMALIZED=$(LC_ALL=C /bin/bash -c '
claude() {
  printf "%s\n" "한글.server: npx unicode-mcp - ✔ Connected"
}
source "$1"
load_claude_allowed_tools
printf "%s\n" "${CLAUDE_ALLOWED_TOOLS_ARGS[*]}"
' _ "$SCRIPT_DIR/scripts/claude-mcp-tools.sh")
if [ "$BASH32_NORMALIZED" = '--allowedTools mcp_____server' ]; then
  note "L1h ok: macOS Bash 3.2 C locale matches Claude's Unicode normalization"
else
  fail "L1h: macOS Bash 3.2 C-locale normalization mismatch: $BASH32_NORMALIZED"
fi

unset -f claude
rm -f "$MCP_TEST_LOG"

if python3 "$SCRIPT_DIR/tests/test-review-stream.py" "$SCRIPT_DIR/scripts/claude-review-stream.py"; then
  note "L1i ok: bounded review stream harness"
else
  fail "L1i: bounded review stream harness"
fi

# L1c — preflight runs (may exit 2 if no auth; that's the "warn" path)
if "$SCRIPT_DIR/scripts/preflight-auth.sh" >/dev/null 2>&1; then
  note "L1c ok: preflight passed (auth present)"
  HAVE_AUTH=1
else
  note "L1c warn: preflight reports no auth — run \`claude auth login\`"
  HAVE_AUTH=0
fi

# L2s — shell-capability probe (small model call)
if [ "${RUN_L2_SHELL:-0}" = "1" ] && [ "$HAVE_AUTH" = "1" ]; then
  if "$SCRIPT_DIR/scripts/preflight-shell.sh"; then
    note "L2s ok: shell capability"
  else
    fail "L2s: shell capability unavailable"
  fi
fi

# L2 — actual claude -p round-trip
if [ "${RUN_L2:-0}" = "1" ] && [ "$HAVE_AUTH" = "1" ]; then
  OUT=$(claude -p --print \
          --output-format json \
          --no-session-persistence \
          "Reply with exactly: OK" 2>/dev/null \
        | python3 -c 'import sys,json
d=json.load(sys.stdin)
if isinstance(d,list): d=next((x for x in d if isinstance(x,dict) and x.get("type")=="result"),{})
print(d.get("result",""))' \
        | tr -d '[:space:]')
  if echo "$OUT" | grep -qi 'ok'; then
    note "L2 ok: round-trip"
  else
    fail "L2: unexpected response: $OUT"
  fi
fi

# L2m — review deliberately has no MCP surface. The offline L1i harness proves the
# strict tool boundary without spending credits or invoking a configured server.
if [ "${RUN_L3_MCP:-0}" = "1" ]; then
  note "L2m skip: review is intentionally MCP-free"
fi

# L3 — plan & review wrappers
if [ "${RUN_L3:-0}" = "1" ] && [ "$HAVE_AUTH" = "1" ]; then
  if "$SCRIPT_DIR/scripts/claude-plan.sh" "Plan a one-line hello-world script. One step only." >/tmp/claude-plan-test.txt 2>/dev/null \
     && [ -s /tmp/claude-plan-test.txt ]; then
    note "L3a ok: claude-plan.sh"
  else
    fail "L3a: claude-plan.sh failed"
  fi
  rm -f /tmp/claude-plan-test.txt
fi

exit "$FAIL"
