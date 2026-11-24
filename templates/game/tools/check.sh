#!/usr/bin/env bash
# Everything that must pass before work is done: import, GUT tests, shell tests, lint, format.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"

echo "== import"
"$GODOT" --headless --import > /dev/null 2>&1 || { "$GODOT" --headless --import; exit 1; }

echo "== GUT"
# GUT exits 0 when a test script fails to parse (it just skips it), so the output is checked too.
out="$(mktemp)"
trap 'rm -f "$out"' EXIT
status=0
"$GODOT" --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit 2>&1 | tee "$out" || status=$?
if [ "$status" -ne 0 ] || grep -qE 'SCRIPT ERROR|Failed to load script|GUT ERROR|Nothing was run' "$out"; then
  echo "GUT failed" >&2
  exit 1
fi

echo "== shell tests"
for t in tests/tools/test_*.sh; do
  [ -e "$t" ] || continue
  echo "-- $t"
  bash "$t"
done

echo "== lint"
gdlint src tests
gdformat --check src tests
echo "== all checks passed"
