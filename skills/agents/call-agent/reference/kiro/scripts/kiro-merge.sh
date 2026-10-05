#!/usr/bin/env bash
# kiro-merge.sh — open Kiro's 3-way merge GUI and block until user closes.
# Usage: kiro-merge.sh <left> <right> <base> <output>
#
# Useful for resolving git merge conflicts visually. After the user saves
# and closes the merge window, `output` contains the merged file.
set -uo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: $0 <left> <right> <base> <output>" >&2; exit 2
fi
if ! command -v kiro >/dev/null; then
  echo "kiro not installed" >&2; exit 2
fi

LEFT="$1"; RIGHT="$2"; BASE="$3"; OUT="$4"

for f in "$LEFT" "$RIGHT" "$BASE"; do
  [ -e "$f" ] || { echo "missing input: $f" >&2; exit 2; }
done

case "$OUT" in
  /*) ;;
   *) echo "output path must be absolute: $OUT" >&2; exit 2;;
esac
mkdir -p "$(dirname "$OUT")"

# --wait blocks until the merge window closes
kiro -m "$LEFT" "$RIGHT" "$BASE" "$OUT" --wait

if [ ! -s "$OUT" ]; then
  echo "kiro-merge: $OUT not written (user may have cancelled)" >&2
  exit 1
fi
echo "kiro-merge: wrote $OUT"
