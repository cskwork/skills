#!/usr/bin/env bash
# gpt-pro-bundle.sh - package a sanitized context bundle for ChatGPT Pro (web).
# Builds <out>/{PROMPT.md, source/...}, scans for secrets (fail-fast), tars it,
# and copies the prompt to the clipboard. The peer step (paste into chatgpt.com,
# upload the archive, read the answer back) is done by the human - this is the
# reliable path that needs no browser automation.
#
# Usage: gpt-pro-bundle.sh "<QUESTION>" [options]
#   --role "<persona>"      reviewer persona in PROMPT.md (default: senior engineer)
#   --files <path|glob> ...  files/dirs to include (repeatable; reads until next --flag)
#   --out <dir>              output base (default: $GPT_PRO_OUT or ~/Documents/GPT Pro Analysis)
#   --paste-file             also emit PASTE_THIS.txt (single paste, no upload)
#   --allow-secrets          skip the fail-fast secret block (use with care)
#   --no-clip                do not touch the clipboard
#   -h, --help               show this header
set -uo pipefail

die()  { echo "gpt-pro-bundle: $*" >&2; exit 2; }
note() { printf '[gpt-pro] %s\n' "$*"; }

[ "$#" -ge 1 ] || { sed -n '2,18p' "$0"; exit 2; }
case "$1" in -h|--help) sed -n '2,18p' "$0"; exit 0;; esac

QUESTION="$1"; shift
ROLE="a senior software engineer giving a rigorous, skeptical second-opinion review"
OUT_BASE="${GPT_PRO_OUT:-$HOME/Documents/GPT Pro Analysis}"
FILES=()
PASTE_FILE=0
ALLOW_SECRETS=0
NO_CLIP=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --role)  ROLE="${2:?--role needs a value}"; shift 2;;
    --out)   OUT_BASE="${2:?--out needs a dir}"; shift 2;;
    --files) shift; while [ "$#" -gt 0 ] && [ "${1#--}" = "$1" ]; do FILES+=("$1"); shift; done;;
    --paste-file)    PASTE_FILE=1; shift;;
    --allow-secrets) ALLOW_SECRETS=1; shift;;
    --no-clip)       NO_CLIP=1; shift;;
    -h|--help) sed -n '2,18p' "$0"; exit 0;;
    *) die "unknown option: $1";;
  esac
done

# Dated, slugged output dir (kept stable across runs of the same day/question).
slug=$(printf '%s' "$QUESTION" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' \
        | sed 's/^-*//; s/-*$//' | cut -c1-50)
[ -n "$slug" ] || slug="query"
OUT="$OUT_BASE/$(date +%Y-%m-%d)-$slug"
mkdir -p "$OUT/source" || die "cannot create $OUT"

# Collect requested files/dirs under source/, preserving relative structure.
copied=0
add_file() {
  local f="$1" rel dest n
  rel="${f#./}"; rel="${rel#/}"
  rel="${rel//..\//}"; rel="${rel#/}"          # strip parent refs so nothing escapes source/
  [ -n "$rel" ] && [ "$rel" != "." ] || rel="$(basename "$f")"
  dest="$OUT/source/$rel"
  if [ -e "$dest" ]; then                        # different roots, same rel -> don't clobber
    n=2; while [ -e "$dest.$n" ]; do n=$((n+1)); done; dest="$dest.$n"
  fi
  mkdir -p "$(dirname "$dest")" && cp "$f" "$dest" && copied=$((copied+1))
}
for f in ${FILES[@]+"${FILES[@]}"}; do
  if   [ -f "$f" ]; then add_file "$f"
  elif [ -d "$f" ]; then cp -R "$f" "$OUT/source/$(basename "$f")" && copied=$((copied+1))
  else note "skip (not found): $f"; fi
done

# Best-effort project context (tree + recent history) when run inside a git repo.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git ls-files 2>/dev/null | head -500 > "$OUT/source/_FILE_TREE.txt" || true
  git log --oneline -20 2>/dev/null > "$OUT/source/_GIT_LOG.txt" || true
fi

# Fail-fast secret scan - refuse to package leaked credentials (no in-place
# redaction: that risks silent corruption; the user excludes or overrides).
SECRET_RE='-----BEGIN ([A-Z]+ )?PRIVATE KEY|sk-[A-Za-z0-9]{16,}|ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|aws_secret_access_key|api[_-]?key[[:space:]]*[:=]|secret[[:space:]]*[:=]|password[[:space:]]*[:=]|bearer[[:space:]]+[A-Za-z0-9._-]{20,}'
if [ "$ALLOW_SECRETS" -ne 1 ]; then
  hits=$(grep -rIEin -e "$SECRET_RE" "$OUT/source" 2>/dev/null || true)
  qhit=$(printf '%s' "$QUESTION" | grep -IEin -e "$SECRET_RE" 2>/dev/null || true)  # also scan the question text
  if [ -n "$hits" ] || [ -n "$qhit" ]; then
    echo "gpt-pro-bundle: potential secrets detected - refusing to package:" >&2
    [ -n "$qhit" ] && echo "  (in question text) $qhit" >&2
    [ -n "$hits" ] && printf '%s\n' "$hits" | sed "s#^$OUT/source/#  #" | head -50 >&2
    echo "  Fix: exclude those files / clean the question, or re-run with --allow-secrets to override." >&2
    rm -rf "$OUT"
    exit 2
  fi
fi

# The prompt is the product: framing beats raw code (quality in = quality out).
cat > "$OUT/PROMPT.md" <<EOF
# Role
You are $ROLE. Be concrete and evidence-driven; prefer specifics over generalities.

# Context
This bundle was prepared by an AI coding agent (call-agent) for a deep
second-opinion review. The relevant files are provided to you directly - either
inline below in this message, or attached as an archive (under \`source/\`), or
both; a file tree and recent git history are included where available. Review
whatever is present here - do NOT look for or wait on external/workspace files.

# Question
$QUESTION

# What to examine
- Correctness and edge cases; concurrency and error handling.
- Security: input validation, secrets, injection, authn/authz.
- Simplicity and maintainability: dead code, over-abstraction, naming.
- Anything the original author most likely missed.

# Output format
For each finding:
- **Finding** - what is wrong or risky (one line)
- **Evidence** - file:line or a quoted snippet
- **Fix** - the smallest correct change
- **Impact** - severity (critical/high/medium/low) and why

End with a short, prioritized action list.
EOF

# Single-paste convenience for small bundles (or when explicitly asked).
SIZE=$(find "$OUT/source" -type f -exec cat {} + 2>/dev/null | wc -c | tr -d ' ')
if [ "$PASTE_FILE" -eq 1 ] || { [ "${SIZE:-0}" -lt 50000 ] && [ "$copied" -gt 0 ]; }; then
  {
    cat "$OUT/PROMPT.md"
    printf '\n---\n# Attached files (inline)\n\n'
    find "$OUT/source" -type f | sort | while read -r p; do
      printf '## %s\n```\n' "${p#"$OUT"/source/}"; cat "$p"; printf '\n```\n\n'
    done
  } > "$OUT/PASTE_THIS.txt"
fi

# Archive + clipboard.
TARBALL="$OUT.tar.gz"
tar -czf "$TARBALL" -C "$(dirname "$OUT")" "$(basename "$OUT")" || die "tar failed"

CLIP_SRC="$OUT/PROMPT.md"
[ -f "$OUT/PASTE_THIS.txt" ] && CLIP_SRC="$OUT/PASTE_THIS.txt"
if [ "$NO_CLIP" -ne 1 ] && command -v pbcopy >/dev/null; then
  pbcopy < "$CLIP_SRC" && note "clipboard <- $(basename "$CLIP_SRC")"
fi

note "bundle:  $OUT"
note "archive: $TARBALL"
note "files:   $copied collected"
[ -f "$OUT/PASTE_THIS.txt" ] && note "paste:   PASTE_THIS.txt (single paste, <50KB)"
cat <<EOF

Next (manual handoff to ChatGPT Pro):
  1. Open https://chatgpt.com/  and select the Pro / deep-reasoning model
  2. Cmd+V - the prompt is already on your clipboard
  3. Upload $TARBALL  (or paste PASTE_THIS.txt instead, if present)
  4. Send; when Pro replies, paste its answer back here for the host to use
EOF
exit 0
