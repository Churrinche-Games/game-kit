---
name: new-game
description: Use when Juan asks to start, create, set up or scaffold a new Churrinche Games game, a new Godot game repo in ~/src, before any game design or code exists.
---

# New game

Every Churrinche game repo is created by `~/src/game-kit/tools/new-game.sh`. It copies the game template from the newest kit tag, vendors the kit, GUT and the skills, writes the harness (CLAUDE.md, settings, .gitignore, licenses, export presets that leave tests and GUT out), runs the game's `tools/check.sh` and makes one local commit on `main`. Use it; don't build a game repo by hand, and don't use the web-app recipe from the global CLAUDE.md (games are Godot, not Vite).

## Steps

1. **Pick the values.**
   - Slug: the name in lowercase with hyphens (`Mate 2048` → `mate-2048`). Folder: `~/src/<slug>`.
   - Display name: exactly as Juan said it.
   - Android package: keep the default, `com.churrinche.<slug without hyphens>` (the design doc's rule). Pass `--package` only if Juan gave one.
2. **Check the name.** If it contains the name of an existing game or brand (`2048`, `Tetris`, `Wordle`, `Candy`…), the design doc's anti-goals apply: ask Juan whether it is a working title before creating. This is the only question that blocks; anything else you want to ask goes in the same message or after the repo exists.
3. **Make sure the newest kit tag has what you need.** The game is made from the newest `vX.Y.Z` tag, not the kit's working tree. If a kit change it needs is uncommitted or untagged, finish it in the kit (`tools/check.sh` passes, commit, new tag; never move a tag) before creating the game.
4. **Create it:** `bash ~/src/game-kit/tools/new-game.sh <slug> "<Display name>"`. On any error it removes the half-made folder; read the message, fix the cause, run it again.
5. **Verify:** the script ends with `Created …`; in the new folder `tools/check.sh` passes, `git log --oneline` shows one commit, `git remote -v` prints nothing.
6. **Stay local.** No remote, no push, no GitHub repo until Juan says so.
7. **Tell Juan:** the folder, the kit tag, that it is local only, and the Android package, saying it becomes permanent with the first Google Play upload (so this is the moment to change it).
8. **Next: the game's design,** with superpowers:brainstorming. Save it at exactly the path the new CLAUDE.md links (`docs/superpowers/specs/<creation date>-<slug>-design.md`), even if it is written on a later day. No game code before the design.

## Quick reference

| Value | Default | Change when |
|---|---|---|
| Folder | `~/src/<slug>` | Juan names another (`--dir`) |
| Package | `com.churrinche.<slug without hyphens>` | Juan names one (`--package`); never after the first Play upload |
| Kit tag | newest `vX.Y.Z` | a specific kit version is needed (`--tag`) |

## Common mistakes

- Creating the repo by hand or from the web-app recipe: it misses the kit, GUT exclusion from exports, and the harness.
- Inventing a package (`io.github…`, `ar.com…`): the design doc fixes the rule.
- Running the script while the needed kit change is still only in the kit's working tree: the game silently gets the older tag.
- Editing `addons/churrinche_kit`, `addons/gut` or the kit's skills inside the game: they are vendored; change the kit, tag, then `tools/sync-kit.sh <tag> .` in the game.
- Starting game code before the design doc.
