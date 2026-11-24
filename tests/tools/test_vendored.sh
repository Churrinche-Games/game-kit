#!/usr/bin/env bash
# Every vendored skill is in the lock, every lock item exists, every lock ref is in THIRD_PARTY.md,
# and every skill has a SKILL.md.
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
lock="$root/tools/vendor.lock"
fail=0
problem() { echo "test_vendored: $*" >&2; fail=1; }

lines="$(grep -Ev '^\s*(#|$)' "$lock")"

shopt -s nullglob
for dir in "$root"/.claude/skills/*/; do
  name="$(basename "$dir")"
  [ "$name" = "_licenses" ] && continue
  echo "$lines" | awk '{print $4}' | grep -qx ".claude/skills/$name" || problem "skill $name is not in tools/vendor.lock"
  [ -f "$dir/SKILL.md" ] || problem "skill $name has no SKILL.md"
done

while read -r repo ref _src dest; do
  [ -e "$root/$dest" ] || problem "$dest (from $repo) is missing; run tools/vendor.sh"
  grep -q "$ref" "$root/THIRD_PARTY.md" || problem "$repo@$ref is not listed in THIRD_PARTY.md"
done <<< "$lines"

[ "$fail" -eq 0 ] && echo "test_vendored: ok"
exit "$fail"
