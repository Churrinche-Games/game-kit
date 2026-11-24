#!/usr/bin/env bash
# tools/vendor.sh must reject a bad lock before it touches anything. Runs a copy of the script in a
# throwaway root, so a bug here can never delete this repo.
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fail=0

try_lock() { # name, lock line
  rm -rf "$work/r"; mkdir -p "$work/r/tools" "$work/r/addons/keep"
  cp "$root/tools/vendor.sh" "$work/r/tools/"
  echo sentinel > "$work/r/addons/keep/file"
  printf '%s\n' "$2" > "$work/r/tools/vendor.lock"
  if PATH="/usr/bin:/bin" bash "$work/r/tools/vendor.sh" > "$work/out" 2>&1; then
    echo "FAIL $1: vendor.sh accepted the lock" >&2; fail=1
  elif [ ! -f "$work/r/addons/keep/file" ] || [ ! -f "$work/r/tools/vendor.sh" ]; then
    echo "FAIL $1: files were deleted" >&2; fail=1
  elif ! grep -q "vendor.lock" "$work/out"; then
    echo "FAIL $1: no lock error message" >&2; cat "$work/out" >&2; fail=1
  else
    echo "ok   $1"
  fi
}

try_lock test_rejects_missing_destination "bitwes/Gut v9.7.1 addons/gut"
try_lock test_rejects_extra_field "bitwes/Gut v9.7.1 addons/gut addons/gut extra"
try_lock test_rejects_absolute_destination "bitwes/Gut v9.7.1 addons/gut /tmp/x"
try_lock test_rejects_parent_destination "bitwes/Gut v9.7.1 addons/gut addons/../.."
try_lock test_rejects_destination_outside_vendored_dirs "bitwes/Gut v9.7.1 addons/gut tools"
exit "$fail"
