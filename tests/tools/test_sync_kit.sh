#!/usr/bin/env bash
# Tests for tools/sync-kit.sh, against a throwaway clone of the kit and a throwaway game repo.
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
sync="$root/tools/sync-kit.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fail=0
TAG=v9.9.9-test

git_q() { git -c user.name=test -c user.email=test@example.invalid "$@" -q; }

setup() {
  rm -rf "$work/kit" "$work/game"
  git clone -q "$root" "$work/kit"
  git -C "$work/kit" tag "$TAG"
  mkdir -p "$work/game/.claude/skills/bichoku-rules"
  echo "mine" > "$work/game/.claude/skills/bichoku-rules/SKILL.md"
  git -C "$work/game" init -q -b main
  git -C "$work/game" add -A
  git_q -C "$work/game" commit -m init
}
run_sync() { KIT_DIR="$work/kit" "$sync" "$@" > "$work/out" 2>&1; }
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1: $2" >&2; cat "$work/out" >&2; fail=1; fi; }

setup; run_sync "$TAG" "$work/game"; status=$?
check test_copies_tagged_files '[ $status -eq 0 ] && [ -f "$work/game/addons/churrinche_kit/kit_version.gd" ] && [ -f "$work/game/.claude/skills/godot-testing/SKILL.md" ] && [ -f "$work/game/addons/gut/gut_cmdln.gd" ] && [ -f "$work/game/addons/churrinche_kit/THIRD_PARTY.md" ]'
check test_records_tag_and_commit '[ "$(sed -n 1p "$work/game/addons/churrinche_kit/SYNCED_FROM")" = "$TAG" ] && [ "$(sed -n 2p "$work/game/addons/churrinche_kit/SYNCED_FROM")" = "$(git -C "$work/kit" rev-parse "$TAG")" ]'
check test_keeps_game_own_skills '[ "$(cat "$work/game/.claude/skills/bichoku-rules/SKILL.md")" = mine ]'
check test_does_not_commit '[ "$(git -C "$work/game" rev-list --count HEAD)" = 1 ]'

setup; echo "# local edit" >> "$work/kit/addons/churrinche_kit/kit_version.gd"; run_sync "$TAG" "$work/game"
check test_uses_tag_not_working_tree '! grep -q "local edit" "$work/game/addons/churrinche_kit/kit_version.gd"'

setup; mkdir -p "$work/game/.claude/skills/dropped-skill"; echo x > "$work/game/.claude/skills/dropped-skill/SKILL.md"
printf 'dropped-skill\n' > "$work/game/.claude/skills/.kit-skills"; git -C "$work/game" add -A; git_q -C "$work/game" commit -m prev
run_sync "$TAG" "$work/game"
check test_removes_skills_the_kit_dropped '[ ! -e "$work/game/.claude/skills/dropped-skill" ] && grep -qx godot-testing "$work/game/.claude/skills/.kit-skills"'

commit_game() { git -C "$work/game" add -A; git_q -C "$work/game" commit -m "$1"; }
synced_game() { setup; run_sync "$TAG" "$work/game"; commit_game "sync"; }

synced_game; run_sync v0.0.0-nope "$work/game"; status=$?
check test_missing_tag_fails '[ $status -ne 0 ] && [ -z "$(git -C "$work/game" status --porcelain)" ]'

synced_game; echo "edit" >> "$work/game/addons/churrinche_kit/kit_version.gd"; run_sync "$TAG" "$work/game"; status=$?
check test_refuses_dirty_game '[ $status -ne 0 ] && grep -q edit "$work/game/addons/churrinche_kit/kit_version.gd"'

synced_game; echo "# fix" >> "$work/game/addons/churrinche_kit/kit_version.gd"; commit_game edit; run_sync "$TAG" "$work/game"; status=$?
check test_refuses_committed_edit '[ $status -ne 0 ] && grep -q "# fix" "$work/game/addons/churrinche_kit/kit_version.gd"'

synced_game; echo "# fix" >> "$work/game/.claude/skills/godot-testing/SKILL.md"; commit_game edit; run_sync "$TAG" "$work/game"; status=$?
check test_refuses_committed_skill_edit '[ $status -ne 0 ] && grep -q "# fix" "$work/game/.claude/skills/godot-testing/SKILL.md"'

synced_game; echo "# fix" >> "$work/game/addons/churrinche_kit/kit_version.gd"; commit_game edit; run_sync --force "$TAG" "$work/game"; status=$?
check test_force_overrides_committed_edit '[ $status -eq 0 ] && ! grep -q "# fix" "$work/game/addons/churrinche_kit/kit_version.gd"'

setup; mkdir -p "$work/game/addons/churrinche_kit"; echo old > "$work/game/addons/churrinche_kit/old.gd"; commit_game unrecorded
run_sync "$TAG" "$work/game"; status=$?
check test_refuses_unrecorded_kit_copy '[ $status -ne 0 ] && [ -e "$work/game/addons/churrinche_kit/old.gd" ]'
run_sync --force "$TAG" "$work/game"; status=$?
check test_force_replaces_unrecorded_kit_copy '[ $status -eq 0 ] && [ ! -e "$work/game/addons/churrinche_kit/old.gd" ]'

setup; echo "extra" > "$work/kit/addons/churrinche_kit/extra.gd"; git -C "$work/kit" add -A; git_q -C "$work/kit" commit -m extra
git -C "$work/kit" tag v9.9.8-test; run_sync v9.9.8-test "$work/game"; commit_game "sync old"; run_sync "$TAG" "$work/game"; status=$?
check test_replaces_stale_files '[ $status -eq 0 ] && [ ! -e "$work/game/addons/churrinche_kit/extra.gd" ]'

synced_game; mkdir -p "$work/outside"; echo keep > "$work/outside/file"
echo "../../../outside" >> "$work/game/.claude/skills/.kit-skills"; commit_game evil; run_sync --force "$TAG" "$work/game"; status=$?
check test_rejects_bad_kit_skills_name '[ $status -ne 0 ] && [ -f "$work/outside/file" ]'

setup; mkdir -p "$work/notgit"; run_sync "$TAG" "$work/notgit"; status=$?
check test_refuses_non_git_dir '[ $status -ne 0 ] && [ -z "$(ls -A "$work/notgit")" ]'

exit "$fail"
