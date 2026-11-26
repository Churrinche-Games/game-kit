# Changelog

All releases are semver tags (`vX.Y.Z`). A breaking change bumps the major.

## 0.5.4 — 2026-11-26

- `KitSheet`: switch and button labels wrap onto more lines instead of widening the panel past its width (a long Spanish setting pushed it off the right edge of a phone).

## 0.5.3 — 2026-11-25

- `KitSound`: an effect takes a free player, or the one whose sound ends first, instead of the next in turn, so a long effect (a win fanfare) is no longer cut off by quick ones. `clock` can be replaced in tests.
- Tests: the WAV helper made empty streams (packed arrays are copied on read); fixed.

## 0.5.2 — 2026-11-24

- `KitTheme`: the switch icons are drawn at twice their size (sharp on phones, where the canvas is scaled up); a 16 px gap between a switch's label and its toggle.

## 0.5.1 — 2026-11-24

- `KitTheme`: buttons keep their text 16 px off the border; switches get drawn toggle icons sized for the 30 px text (`KitTheme.switch_icon`), instead of Godot's 16 px ones.

## 0.5.0 — 2026-11-24

- `sound/synth.mjs`: a deterministic synthesizer for games' sound build scripts (Node, no packages): oscillators with glides, seeded noise, plucked strings, envelopes, mixing, loop folding, normalizing and a 16-bit mono WAV writer.
- `tests/tools/test_node.sh` runs all the Node library tests (it replaces `test_art.sh`).

## 0.4.1 — 2026-11-24

- `KitSheet.add_image(texture, height)`: a centred picture.

## 0.4.0 — 2026-11-24

- `art/engraving.mjs`: the engraving style as a Node library (no packages) for games' art build scripts: path parsing (M L C Q Z, absolute and relative) and an inside test, `Drawing` with `engrave` (form-following lines whose width follows a tone), `band` markings, outline, eye, strokes, and the FULL and SIMPLE levels; `toSvg()` is reproducible. Tested with `node --test` (`tests/tools/test_art.sh`).

## 0.3.2 — 2026-11-24

- `KitSheet`: fixed an endless resize loop (a freeze, then a crash) when wrapped text re-measured at a slightly different width; placement now runs deferred, once per change.
- `KitSheet.area_rect`: the panel stays inside it (games pass the device safe area).

## 0.3.1 — 2026-11-24

- `KitTheme`: switches (CheckButton) keep a paper box when on; they used to take the dark pressed fill and hide their label.

## 0.3.0 — 2026-11-24

- `KitTheme.make(palette)`: the shared Theme from the palette slots `paper`, `line`, `accent`, `error`.
- `KitSheet`: a modal, scrolling panel with titles, text, switches, buttons, actions, links and one-of choices.
- `KitLanguage`: Spanish when the device is in Spanish, otherwise English; a saved choice overrides it. Shared strings in `i18n/kit_strings.csv` (es/en; games register the two translations).
- `KitGameInfo` (reads the game's `res://game_info.cfg`), `KitLinks`, and `KitPages`: About (version, source link, licenses, Godot credit), third-party licenses, Feedback (email with the game and version in the subject, GitHub issues), Support (donation links, only in builds with the `itch` feature). Missing email, repo or links hide their entries.
- `KitSound`: effects and a looping music track with separate on/off switches (music off by default).
- `KitMobile`: the safe area in canvas units, and the back-button notification.
- Template: `game_info.cfg` (exported via `include_filter`), Android preset with the `play` feature and Web with `itch`, the kit strings registered, `quit_on_go_back=false`.

## 0.2.0 — 2026-11-24

- `tools/new-game.sh` and `templates/game/`: create a game repo (`~/src/<slug>`) from the newest kit tag, with the harness, the kit, GUT, the skills, Android and Web export presets that leave tests and GUT out, and one local commit. The default Android package is `com.churrinche.<slug without hyphens>`.
- The `new-game` skill, and `.claude/skills/OWN-SKILLS.txt` listing our own (not vendored) skills.

## 0.1.0 — 2026-11-24

- The kit is a Godot 4.7 project with GUT 9.7.1, gdlint and gdformat; `tools/check.sh` runs everything.
- `SaveStore`: a versioned JSON save file with migrations; broken saves and saves from newer versions are moved to `<path>.broken`; saving is atomic; loaded values are converted back to the shape of the defaults (ints, also inside arrays and int-keyed maps, and typed arrays).
- The vetted Claude skills, vendored at pinned commits (see `THIRD_PARTY.md`).
- `tools/vendor.sh` + `tools/vendor.lock`: reproducible vendoring of third-party code.
- `tools/sync-kit.sh`: vendor a kit tag into a game; refuses over local edits (committed or not) unless `--force`; keeps the game's own skills.
- Licenses: MIT for code, CC BY-NC 4.0 for art and sound; the name and logo are not licensed.
