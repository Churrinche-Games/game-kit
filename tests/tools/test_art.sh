#!/usr/bin/env bash
# The engraving library's tests (Node's built-in test runner; no packages).
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
node --test "$root"/tests/art/*.test.mjs
