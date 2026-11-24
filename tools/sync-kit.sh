#!/usr/bin/env bash
# Vendor the Churrinche kit into a game, from a kit tag (never from the kit's working tree).
#
#   tools/sync-kit.sh <tag> <game-dir>
#
# Replaces addons/churrinche_kit and addons/gut, and the skills the kit put in .claude/skills
# (listed in .claude/skills/.kit-skills; the game's own skills are left alone). Refuses if the
# game has uncommitted changes in those paths. Does not commit.
set -euo pipefail

die() { echo "sync-kit: $*" >&2; exit 1; }
[ $# -eq 2 ] || die "usage: tools/sync-kit.sh <tag> <game-dir>"
tag="$1"
game="$2"
kit="${KIT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

commit="$(git -C "$kit" rev-parse -q --verify "refs/tags/$tag^{commit}")" || die "no tag $tag in $kit"
[ -d "$game" ] && git -C "$game" rev-parse --is-inside-work-tree > /dev/null 2>&1 || die "$game is not a git repo"
game="$(cd "$game" && pwd)"

dirs=(addons/churrinche_kit addons/gut)
dirty="$(git -C "$game" status --porcelain -- "${dirs[@]}" .claude/skills)"
[ -z "$dirty" ] || die "uncommitted changes in the game's kit paths; commit or revert them first:
$dirty"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git -C "$kit" archive "$tag" "${dirs[@]}" .claude/skills THIRD_PARTY.md | tar -x -C "$tmp"

for d in "${dirs[@]}"; do
  rm -rf "${game:?}/$d"
  mkdir -p "$(dirname "$game/$d")"
  cp -R "$tmp/$d" "$game/$d"
done
cp "$tmp/THIRD_PARTY.md" "$game/addons/churrinche_kit/THIRD_PARTY.md"

skills="$game/.claude/skills"
mkdir -p "$skills"
if [ -f "$skills/.kit-skills" ]; then
  while read -r name; do
    [ -n "$name" ] && rm -rf "${skills:?}/$name"
  done < "$skills/.kit-skills"
fi
: > "$skills/.kit-skills"
for src in "$tmp/.claude/skills"/*/; do
  name="$(basename "$src")"
  rm -rf "${skills:?}/$name"
  cp -R "$src" "$skills/$name"
  echo "$name" >> "$skills/.kit-skills"
done

printf '%s\n%s\n' "$tag" "$commit" > "$game/addons/churrinche_kit/SYNCED_FROM"

echo "Synced kit $tag ($commit) into $game. To commit it:"
echo "  git -C \"$game\" add addons/churrinche_kit addons/gut .claude/skills"
echo "  git -C \"$game\" commit -m \"Sync kit $tag\""
