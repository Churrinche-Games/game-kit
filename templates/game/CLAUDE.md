# {{NAME}}

A small, free, open-source, Argentine-themed game by Churrinche Games, made with Godot for Android (Google Play) and the web (itch.io).

**Start here:** read [docs/superpowers/specs/{{DATE}}-{{SLUG}}-design.md](docs/superpowers/specs/{{DATE}}-{{SLUG}}-design.md), the game's design. The portfolio's design (brand, art direction, release process) is in the kit: `~/src/game-kit/docs/superpowers/specs/2026-11-21-portfolio-design.md`.

## Repo

- Local git only, no remote. Pushing anywhere happens only when Juan says so. The future home is `github.com/churrinche-games/{{SLUG}}` (public).
- Created from Churrinche kit `{{KIT_TAG}}`. The kit is vendored: `addons/churrinche_kit`, `addons/gut` and the skills listed in `.claude/skills/.kit-skills` are **never edited here**. Fix things in `~/src/game-kit`, tag a kit release, then run `~/src/game-kit/tools/sync-kit.sh <tag> .` here and commit.
- Android package: `{{PACKAGE}}`. It is permanent once the game is on Google Play.

## Environment

- Godot 4.7.2 at `/Applications/Godot.app/Contents/MacOS/Godot` (scripts read `$GODOT`).
- gdtoolkit (`gdlint`, `gdformat`), JDK 17 and the Android SDK are installed (see the kit's CLAUDE.md).

## Commands

```sh
tools/check.sh   # everything: import, GUT tests, shell tests, lint, format. Must pass before work is done.
```

GUT exits 0 when a test script fails to parse, so use `tools/check.sh`, not bare GUT, to call something done.

## Architecture

```
project.godot          portrait 720x1280, mobile renderer; main scene src/main/main.tscn
src/<feature>/         game code and scenes, one folder per feature
tests/                 GUT tests mirroring src/
addons/churrinche_kit/ the kit (vendored, see Repo)
addons/gut/            GUT (vendored with the kit)
export_presets.cfg     Android and Web; tests, GUT, docs and tools are excluded from exports
docs/superpowers/      specs/ and plans/
```

## Conventions

- Code, comments, commit messages and docs in English. Interface text in rioplatense Spanish (voseo) and English.
- **TDD is the rule:** write a failing test first, watch it fail, then write the minimal code to pass.
- Feature folders in `src/`; tests in `tests/` mirroring them. Pure logic in plain `RefCounted` scripts, out of nodes and scenes.
- Static typing in GDScript everywhere.
- Art follows the kit's engraving style (design doc, Art direction; reference `~/src/game-kit/tools/art/engraving-study.html`).
- Pin new dependencies to existing major versions; don't add a dependency when a few lines will do.
- Keystores and passwords never enter the repo.
- Never add co-author or AI attribution to commits or PRs.
- Commit to `main`; push only when asked.
