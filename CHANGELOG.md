# Changelog

All releases are semver tags (`vX.Y.Z`). A breaking change bumps the major.

## 0.1.0 — 2026-11-24

- The kit is a Godot 4.7 project with GUT 9.7.1, gdlint and gdformat; `tools/check.sh` runs everything.
- `SaveStore`: a versioned JSON save file with migrations; broken saves and saves from newer versions are moved to `<path>.broken`; saving is atomic; loaded values are converted back to the shape of the defaults (ints, also inside arrays and int-keyed maps, and typed arrays).
- The vetted Claude skills, vendored at pinned commits (see `THIRD_PARTY.md`).
- `tools/vendor.sh` + `tools/vendor.lock`: reproducible vendoring of third-party code.
- `tools/sync-kit.sh`: vendor a kit tag into a game; refuses over local edits (committed or not) unless `--force`; keeps the game's own skills.
- Licenses: MIT for code, CC BY-NC 4.0 for art and sound; the name and logo are not licensed.
