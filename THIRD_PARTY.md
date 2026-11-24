# Third-party code

Everything here is copied in by `tools/vendor.sh` from the pinned ref in `tools/vendor.lock`. Each item keeps its own license file. Updating one is a deliberate kit release.

| Item | Source | Ref | License | Path |
|---|---|---|---|---|
| GUT (test framework) | https://github.com/bitwes/Gut | `v9.7.1` | MIT | `addons/gut` (license: `addons/gut/LICENSE.md`) |
| Claude skills: `gdscript-patterns`, `godot-testing`, `mobile-development`, `export-pipeline`, `localization`, `responsive-ui`, `audio-system` | https://github.com/jame581/GodotPrompter | `426e8ab597473d1c71a11a04f6f0f2e1182a8e39` | MIT | `.claude/skills/<name>` (license: `.claude/skills/_licenses/GodotPrompter-LICENSE`) |
| Claude skills: `godot-gdscript-headless-testing`, `puzzle`, `game-feel` | https://github.com/gamedev-skills/awesome-gamedev-agent-skills | `c6ca6c41c839b68319ffc08430b99ab768debc32` | Apache-2.0 | `.claude/skills/<name>` (license and notice: `.claude/skills/_licenses/awesome-gamedev-agent-skills-LICENSE`, `-NOTICE`) |

The skills were read in full and vetted on 2026-11-21 at these commits. A new commit means reading the changes before bumping the lock.
