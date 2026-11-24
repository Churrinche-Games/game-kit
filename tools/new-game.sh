#!/usr/bin/env bash
# Create a new Churrinche game repo from the kit.
#
#   tools/new-game.sh [--dir <path>] [--package <android.package>] [--tag <kit-tag>] <slug> "<Display name>"
#
# Defaults: --dir ~/src/<slug>, --package com.churrinche.<slug without hyphens> (the design doc's rule; permanent on Play), --tag the kit's
# newest vX.Y.Z tag. Copies templates/game from that tag, syncs the kit into it, runs the game's
# tools/check.sh and makes one local commit on main. Never pushes.
set -euo pipefail

die() { echo "new-game: $*" >&2; exit 1; }
kit="${KIT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

dir="" package="" tag="" args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) dir="${2:-}"; shift 2 || die "--dir needs a path" ;;
    --package) package="${2:-}"; shift 2 || die "--package needs a value" ;;
    --tag) tag="${2:-}"; shift 2 || die "--tag needs a value" ;;
    --*) die "unknown option $1" ;;
    *) args+=("$1"); shift ;;
  esac
done
[ "${#args[@]}" -eq 2 ] || die 'usage: tools/new-game.sh [--dir <path>] [--package <id>] [--tag <tag>] <slug> "<Display name>"'
slug="${args[0]}"
name="${args[1]}"

[[ "$slug" =~ ^[a-z][a-z0-9-]*$ ]] || die "slug must be lowercase letters, digits and hyphens, starting with a letter: $slug"
[ -n "$name" ] || die "the display name is empty"
case "$name" in *'"'* | *'\'* | *$'\n'*) die "the display name must not contain quotes, backslashes or newlines" ;; esac
package="${package:-com.churrinche.${slug//-/}}"
[[ "$package" =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$ ]] || die "not a valid Android package name: $package"
dir="${dir:-$HOME/src/$slug}"
[ ! -e "$dir" ] || die "$dir already exists"

if [ -z "$tag" ]; then
  tag="$(git -C "$kit" tag -l 'v[0-9]*' --sort=-v:refname | head -1)"
  [ -n "$tag" ] || die "the kit has no release tags"
fi
git -C "$kit" rev-parse -q --verify "refs/tags/$tag^{commit}" > /dev/null || die "no tag $tag in $kit"
git -C "$kit" cat-file -e "$tag:templates/game" 2> /dev/null || die "kit $tag has no templates/game"

mkdir -p "$dir"
trap '[ "${done:-0}" = 1 ] || rm -rf "$dir"' EXIT
git -C "$kit" archive "$tag" templates/game | tar -x -C "$dir" --strip-components 2

export NG_NAME="$name" NG_SLUG="$slug" NG_PACKAGE="$package" NG_TAG="$tag" NG_DATE="$(date +%F)"
find "$dir" -type f -print0 | xargs -0 perl -pi -e '
  s/\{\{NAME\}\}/$ENV{NG_NAME}/g; s/\{\{SLUG\}\}/$ENV{NG_SLUG}/g; s/\{\{PACKAGE\}\}/$ENV{NG_PACKAGE}/g;
  s/\{\{KIT_TAG\}\}/$ENV{NG_TAG}/g; s/\{\{DATE\}\}/$ENV{NG_DATE}/g;'
mkdir -p "$dir/.superpowers/sdd" "$dir/docs/superpowers/specs" "$dir/docs/superpowers/plans"
printf '*\n' > "$dir/.superpowers/sdd/.gitignore"
touch "$dir/docs/superpowers/specs/.gitkeep" "$dir/docs/superpowers/plans/.gitkeep"
chmod +x "$dir/tools/check.sh"

git -C "$dir" init -q -b main
KIT_DIR="$kit" bash "$kit/tools/sync-kit.sh" "$tag" "$dir" > /dev/null
(cd "$dir" && bash tools/check.sh > /dev/null 2>&1) || {
  (cd "$dir" && bash tools/check.sh) >&2 || true
  die "the new game's tools/check.sh failed"
}
git -C "$dir" add -A
git -C "$dir" commit -q -m "Create $name from Churrinche kit $tag"
done=1

echo "Created $name in $dir (package $package, kit $tag). Local only, no remote."
echo "Next: write the game design in docs/superpowers/specs/$NG_DATE-$slug-design.md."
