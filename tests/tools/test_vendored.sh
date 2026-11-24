#!/usr/bin/env bash
# Every skill is either vendored (in the lock) or ours (in .claude/skills/OWN-SKILLS.txt); every vendored skill is in the lock, every lock item exists, every lock ref is in THIRD_PARTY.md,
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
  in_lock=0 own=0
  grep -qx ".claude/skills/$name" <<< "$(awk '{print $4}' <<< "$lines")" && in_lock=1
  grep -qx "$name" "$root/.claude/skills/OWN-SKILLS.txt" 2> /dev/null && own=1
  [ $((in_lock + own)) -eq 1 ] || problem "skill $name must be either in tools/vendor.lock or in .claude/skills/OWN-SKILLS.txt (exactly one)"
  [ -f "$dir/SKILL.md" ] || problem "skill $name has no SKILL.md"
done

while read -r repo ref _src dest; do
  [ -e "$root/$dest" ] || problem "$dest (from $repo) is missing; run tools/vendor.sh"
  grep -q "$ref" "$root/THIRD_PARTY.md" || problem "$repo@$ref is not listed in THIRD_PARTY.md"
done <<< "$lines"

[ "$fail" -eq 0 ] && echo "test_vendored: ok"
exit "$fail"
