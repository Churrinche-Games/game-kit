#!/usr/bin/env bash
# Tests for tools/new-game.sh, against a throwaway clone of the kit; games are created in a temp dir.
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fail=0
TAG=v9.9.9-test
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.invalid GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.invalid

git clone -q "$root" "$work/kit"
# The clone gets the committed kit; overlay the working tree's script and templates so the test
# exercises what is being written, then tag that.
rm -rf "$work/kit/templates" && cp -R "$root/templates" "$work/kit/templates" 2> /dev/null
cp "$root/tools/new-game.sh" "$work/kit/tools/" 2> /dev/null
git -C "$work/kit" add -A && git -C "$work/kit" -c commit.gpgsign=false commit -qm overlay --allow-empty
git -C "$work/kit" tag "$TAG"
new_game() { bash "$work/kit/tools/new-game.sh" "$@" > "$work/out" 2>&1; }
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1: $2" >&2; tail -20 "$work/out" >&2; fail=1; fi; }

g="$work/games/mi-juego"
new_game --dir "$g" mi-juego "Mi Juego & Cía"; status=$?
check test_creates_game '[ $status -eq 0 ] && [ -f "$g/project.godot" ]'
check test_one_commit_clean_tree '[ "$(git -C "$g" rev-list --count HEAD)" = 1 ] && [ -z "$(git -C "$g" status --porcelain)" ] && [ "$(git -C "$g" branch --show-current)" = main ]'
check test_name_is_literal 'grep -qF "config/name=\"Mi Juego & Cía\"" "$g/project.godot"'
check test_no_placeholders_left '! grep -rF "{{" "$g" --exclude-dir=.git --exclude-dir=addons --exclude-dir=.claude --exclude-dir=.godot'
check test_kit_synced_from_latest_tag '[ "$(sed -n 1p "$g/addons/churrinche_kit/SYNCED_FROM")" = "$TAG" ] && [ -f "$g/.claude/skills/godot-testing/SKILL.md" ]'
check test_default_package '[ "$(grep -c "package/unique_name=\"com.churrinche.mijuego\"" "$g/export_presets.cfg")" = 1 ]'
check test_exports_exclude_tests_and_gut '[ "$(grep -c "^exclude_filter=.*addons/gut/\*" "$g/export_presets.cfg")" = 2 ] && [ "$(grep -c "^exclude_filter=.*tests/\*" "$g/export_presets.cfg")" = 2 ]'
check test_claude_md_links_spec 'grep -qE "docs/superpowers/specs/[0-9]{4}-[0-9]{2}-[0-9]{2}-mi-juego-design\.md" "$g/CLAUDE.md"'
check test_harness_files '[ -f "$g/.claude/settings.json" ] && grep -q ponytail "$g/.claude/settings.json" && grep -qx ".superpowers/" "$g/.gitignore" && grep -qx "CLAUDE.local.md" "$g/.gitignore" && [ -f "$g/.superpowers/sdd/.gitignore" ] && [ -f "$g/LICENSE" ] && [ -f "$g/LICENSE-ART.md" ]'
check test_secrets_ignored 'grep -qx "\*.keystore" "$g/.gitignore" && grep -qx "\*.jks" "$g/.gitignore"'
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
(cd "$g" && "$GODOT" --headless --export-pack Web "$work/web.pck" > "$work/out" 2>&1)
strings "$work/web.pck" > "$work/web.txt" 2> /dev/null
check test_export_leaves_out_tests_and_gut '[ -s "$work/web.pck" ] && grep -q "src/main/main.tscn" "$work/web.txt" && ! grep -qE "addons/gut|tests/test_smoke" "$work/web.txt"'
check test_game_check_passes '(cd "$g" && bash tools/check.sh > "$work/check.out" 2>&1)'

new_game --dir "$work/games/pkg" --package ar.example.pkg pkg "Pkg"
check test_custom_package 'grep -qF "package/unique_name=\"ar.example.pkg\"" "$work/games/pkg/export_presets.cfg"'

before="$(git -C "$g" rev-parse HEAD)"; new_game --dir "$g" mi-juego "Otro"; status=$?
check test_refuses_existing_dir '[ $status -ne 0 ] && [ "$(git -C "$g" rev-parse HEAD)" = "$before" ] && grep -qF "Mi Juego & Cía" "$g/project.godot"'

new_game --dir "$work/games/bad" "Bad Slug" "Bad"; status=$?
check test_rejects_bad_slug '[ $status -ne 0 ] && [ ! -e "$work/games/bad" ]'
new_game --dir "$work/games/bad2" bad2 "Bad" --package "Not.A.Package"; status=$?
new_game --dir "$work/games/bad2" --package "Not-A.package" bad2 "Bad"; status2=$?
check test_rejects_bad_package '[ $status -ne 0 ] && [ $status2 -ne 0 ] && [ ! -e "$work/games/bad2" ]'
new_game --dir "$work/games/bad3" bad3 'Say "hi"'; status=$?
check test_rejects_quote_in_name '[ $status -ne 0 ] && [ ! -e "$work/games/bad3" ]'

exit "$fail"
