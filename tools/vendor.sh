#!/usr/bin/env bash
# Copy third-party files listed in tools/vendor.lock, each from its pinned ref.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

grep -Ev '^\s*(#|$)' "$root/tools/vendor.lock" | while read -r repo ref src dest; do
  key="$(echo "$repo@$ref" | tr '/@' '__')"
  if [ ! -d "$tmp/$key" ]; then
    mkdir -p "$tmp/$key"
    gh api "repos/$repo/tarball/$ref" > "$tmp/$key.tar.gz"
    tar -xzf "$tmp/$key.tar.gz" -C "$tmp/$key" --strip-components 1
  fi
  [ -e "$tmp/$key/$src" ] || { echo "vendor: $src not found in $repo@$ref" >&2; exit 1; }
  if [ -d "$tmp/$key/$src" ]; then
    rm -rf "${root:?}/$dest"
    mkdir -p "$(dirname "$root/$dest")"
    cp -R "$tmp/$key/$src" "$root/$dest"
  else
    mkdir -p "$(dirname "$root/$dest")"
    cp "$tmp/$key/$src" "$root/$dest"
  fi
  echo "vendored $repo@$ref $src -> $dest"
done
