#!/usr/bin/env bash
# The kit's Node libraries (art, sound): Node's built-in test runner, no packages.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
node --test "$root"/tests/art/*.test.mjs "$root"/tests/sound/*.test.mjs
