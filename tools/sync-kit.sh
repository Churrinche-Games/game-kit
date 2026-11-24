#!/usr/bin/env bash
# Vendor the Churrinche kit into a game, from a kit tag (never from the kit's working tree).
#
#   tools/sync-kit.sh [--force] <tag> <game-dir>
#
# Replaces addons/churrinche_kit and addons/gut, and the skills the kit put in .claude/skills
# (listed in .claude/skills/.kit-skills; the game's own skills are left alone). Does not commit.
#
# Refuses when the game has uncommitted changes in those paths, and when its copy differs from the
# kit commit recorded in addons/churrinche_kit/SYNCED_FROM (a local edit, even a committed one):
# move such changes into the kit instead. --force skips the second check.
set -euo pipefail

die() { echo "sync-kit: $*" >&2; exit 1; }
force=0
if [ "${1:-}" = "--force" ]; then force=1; shift; fi
[ $# -eq 2 ] || die "usage: tools/sync-kit.sh [--force] <tag> <game-dir>"
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

skills="$game/.claude/skills"
kit_skills=()
if [ -f "$skills/.kit-skills" ]; then
  while read -r name; do
    [ -z "$name" ] && continue
    [[ "$name" =~ ^[A-Za-z0-9_][A-Za-z0-9._-]*$ ]] || die "bad skill name in .claude/skills/.kit-skills: $name"
    kit_skills+=("$name")
  done < "$skills/.kit-skills"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# The game's copy must match the kit commit it was synced from, or the sync would undo local edits.
synced="$game/addons/churrinche_kit/SYNCED_FROM"
if [ "$force" -eq 0 ]; then
  if [ -f "$synced" ]; then
    old="$(sed -n 2p "$synced")"
    git -C "$kit" cat-file -e "$old^{commit}" 2> /dev/null || die "the recorded kit commit $old is not in $kit; pass --force"
    mkdir -p "$tmp/old"
    git -C "$kit" archive "$old" "${dirs[@]}" .claude/skills | tar -x -C "$tmp/old"
    changed=""
    for d in "${dirs[@]}"; do
      changed+="$(diff -rq -x SYNCED_FROM -x THIRD_PARTY.md "$tmp/old/$d" "$game/$d" 2>&1)" || true
    done
    for name in "${kit_skills[@]+"${kit_skills[@]}"}"; do
      [ -e "$tmp/old/.claude/skills/$name" ] || [ -e "$skills/$name" ] || continue
      changed+="$(diff -rq "$tmp/old/.claude/skills/$name" "$skills/$name" 2>&1)" || true
    done
    [ -z "$changed" ] || die "the game's copy of the kit has local changes since $(sed -n 1p "$synced"):
$changed
Move them into the kit and tag a release, or pass --force to discard them."
  elif [ -e "$game/addons/churrinche_kit" ]; then
    die "the game has addons/churrinche_kit but no SYNCED_FROM; pass --force to replace it"
  fi
fi

mkdir -p "$tmp/new"
git -C "$kit" archive "$tag" "${dirs[@]}" .claude/skills THIRD_PARTY.md | tar -x -C "$tmp/new"

for d in "${dirs[@]}"; do
  rm -rf "${game:?}/$d"
  mkdir -p "$(dirname "$game/$d")"
  cp -R "$tmp/new/$d" "$game/$d"
done
cp "$tmp/new/THIRD_PARTY.md" "$game/addons/churrinche_kit/THIRD_PARTY.md"

mkdir -p "$skills"
for name in "${kit_skills[@]+"${kit_skills[@]}"}"; do
  rm -rf "${skills:?}/$name"
done
: > "$skills/.kit-skills"
for src in "$tmp/new/.claude/skills"/*/; do
  name="$(basename "$src")"
  rm -rf "${skills:?}/$name"
  cp -R "$src" "$skills/$name"
  echo "$name" >> "$skills/.kit-skills"
done

printf '%s\n%s\n' "$tag" "$commit" > "$game/addons/churrinche_kit/SYNCED_FROM"

echo "Synced kit $tag ($commit) into $game. To commit it:"
echo "  git -C \"$game\" add addons/churrinche_kit addons/gut .claude/skills"
echo "  git -C \"$game\" commit -m \"Sync kit $tag\""
