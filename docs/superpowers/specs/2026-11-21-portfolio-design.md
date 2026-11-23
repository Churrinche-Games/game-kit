# Churrinche Games portfolio: design

Date: 2026-11-21 (rewritten 2026-11-22: Godot, open source, donations, new brand)

This is the base document for every game in the portfolio. Each game gets its own design doc later; this one holds what they all share.

## Intent

A portfolio of small, free, open-source, Argentine-themed mobile games, each published as its own Android app on Google Play (and on itch.io). The purpose is to:

- have a public portfolio of finished work, code included,
- start building an audience,
- get feedback from real players on small games before attempting anything bigger.

Income is welcome but not the goal; what there is comes from **donations**. Expected traffic is unknown and assumed to be low at first.

## Brand: Churrinche Games

The churrinche is a tiny bright-red bird of the litoral (the vermilion flycatcher), and also a factura. Small, sweet games from Rosario.

| Thing | Value |
|---|---|
| Play developer name | Churrinche Games |
| GitHub organization | `churrinche-games` (free on 2026-11-22; `churrinche` is a taken personal account) |
| itch.io | `churrinche.itch.io` (free on 2026-11-22) |
| Domain | `churrinchegames.com` was free; start with GitHub Pages (`churrinche-games.github.io`) and buy the domain only if needed. `churrinche.com` and `.com.ar` are taken. |
| App IDs (permanent) | `com.churrinche.<game>` |
| Kit addon | `churrinche_kit` |

No game, studio or app using the name was found on 2026-11-22 (web search only). **Before announcing:** search the INPI register for "churrinche".

## Goals

- Ship small games often, each one complete and polished on its own.
- Every game helps the others get found (a More games screen inside each game).
- Collect feedback cheaply: Play reviews, an in-game feedback link, GitHub issues, Play Console stats.
- Reuse as much as possible between games: engine, kit, skills, release process.
- Every repo is public and readable as a portfolio piece.

## Non-goals (for now)

- Ads.
- Accounts, logins, online leaderboards, multiplayer.
- Analytics or tracking SDKs. Play Console's own stats are enough, and this keeps the Data safety form trivial.
- iOS. Godot doesn't rule it out later.

## Anti-goals (failure even if it "works")

- Games that feel like a copy of a specific existing game (its name, art, look or levels). We build in a genre with our own Argentine theme.
- Monetization that annoys players or costs reviews.
- Anything that leaks the developer's home address or personal data without a deliberate decision (commit emails included).
- Shared code edited inside a game and drifting from the kit.
- Art that copies real banknotes.

## Open source

- **Every repo is public** under the `churrinche-games` GitHub org: the kit and each game.
- **Each game links to its GitHub repo** from its About screen ("Source code on GitHub").
- **Licenses** *(proposed, confirm before the first public push)*:
  - Code: **MIT**.
  - Art, sound and music: **CC BY-NC 4.0** (credit required, no commercial use).
  - The Churrinche Games name and logo: not licensed; forks must rename.
- Commits are authored by Juan's personal GitHub account, so the work shows as Juan's own contributions. Which email the commits use (personal or GitHub's noreply alias, both link to the same profile) is Juan's choice.
- Before the first push: check the history for anything private.

## Donations

Donations are the only income. Stores have different rules, so each build gets its own Support screen:

| Channel | How | Notes |
|---|---|---|
| **GitHub** | `FUNDING.yml` in the org's `.github` repo, so every repo shows a Sponsor button: GitHub Sponsors (supports Argentina, no fee from personal sponsors), Ko-fi and Cafecito (custom URL); PayPal optional. | Set up once for all repos. |
| **itch.io** | Each game published free with pay-what-you-want (web build + APK). Revenue share is ours to choose; payout via PayPal or Payoneer. | The itch build's Support screen can link to all the donation pages. |
| **Google Play build** | **No donation links or donation wording.** Play's payments policy forbids steering to outside payments. The About screen links to the GitHub repo only (informational). | The repo page has a Sponsor button; that's a gray area, accepted as low risk. Re-check the policy before each launch. |
| **Play tip jar (later)** | Play Billing consumables, 2–3 amounts, once a game has players. | Needs the payments profile sorted (Argentina; profile country can't change) and the EU "trader" status checked: selling anything can make the address public on the listing. |

A build flag (`store = play | itch`) decides what the Support screen shows.

## Distribution

- **Each game is its own Play app,** with its own listing and stats, so we can see which games resonate. Also on itch.io.
- **Developer account: personal** (no existing account, no company). US$25, identity verification.
- **Closed test before each launch:** personal accounts created after 2023-11-13 need ≥12 testers opted in for 14 continuous days on the closed track before production. One standing tester group (friends, family, coworkers), reused for every game; they're also the first feedback group. Test the next game while the current one is in review.

## Art direction

All art is made by Claude in code; no AI image generators and no external asset files beyond CC0 fallbacks.

Two candidate directions (choose one before the first game's art; a visual comparison comes first):

1. **Banknote engraving:** the style of the Argentine peso series with native animals: fine line work, cross-hatching, guilloche patterns, a cream "paper" background, a limited palette per game. Drawn as SVG generated by script (Godot imports SVG).
2. **Pixel art version of that style:** the same animals and palettes as low-resolution pixel art, written as text grids and turned into PNGs by a script; nearest-neighbor filtering, integer scaling.

Rules either way:

- **Inspiration only.** Never reproduce a real bill, its layout, denominations, portraits, BCRA marks or security features.
- Source files (scripts, grids, SVG) are committed; generated files are rebuilt by a script, so the art is reproducible and open.
- Never imitate existing characters or brands.
- The churrinche itself is the logo.

## Sound

- **Effects:** synthesized sfxr-style by a script into `.wav` files (committed with their generator), or with `AudioStreamGenerator` at runtime when that's simpler.
- **Music:** short chiptune loops written as note sequences and rendered by the same script. Traditional rhythms (chacarera, zamba) and traditional melodies are fair game; modern recordings and arrangements are not.
- **Fallback:** CC0 packs (Kenney, CC0 items on OpenGameArt/Freesound), credited anyway.
- Every game has separate mute toggles for music and effects, saved locally.

## Stack: Godot 4

**Godot 4.7** (installed: 4.7.2), **GDScript**, Android export as AAB, plus a web export for itch.io. Godot is also Argentine-born, which fits the brand.

- **Tests:** GUT (pinned, vendored in `addons/gut`), run headless: `godot --headless -s addons/gut/gut_cmdln.gd -gexit`. Pure logic lives in plain scripts (`RefCounted`, no nodes) so it's easy to test. **TDD is the rule.** The exit code must reflect failures (see the `godot-gdscript-headless-testing` skill).
- **Lint and format:** gdtoolkit (`gdlint`, `gdformat`), pinned.
- **Build check:** a headless import plus an export of each preset must succeed with no script errors.
- **Translations:** CSV files + `tr()` + `TranslationServer`; rioplatense Spanish and English, following the device language, with a switch in settings.
- **Mobile basics, in the kit:** Android back button (`NOTIFICATION_WM_GO_BACK_REQUEST`), pause and save on background (`NOTIFICATION_APPLICATION_PAUSED`), safe areas (`DisplayServer.get_display_safe_area()`), layouts that work at 360 px wide.
- **Toolchain to install** (needs Juan's OK): JDK 17, Android SDK platform and build-tools 35+, Godot export templates for 4.7.2, butler for itch.io uploads, gdtoolkit.
- Signing keystores and their passwords never enter any repo.

### Approaches considered (engine)

| Approach | Trade-off | Verdict |
|---|---|---|
| Godot 4 | Real engine with physics, animation and a web export; open source like us; Argentine-born. New language and a weaker testing story, solved with GUT and logic kept out of nodes. | **Chosen by Juan** |
| Web stack + Capacitor (Bichoku's stack) | Reuses Bichoku as is, but physics games are a stretch. | Rejected; Bichoku gets ported to Godot |
| Unity | Too heavy; licensing history. | Rejected |

## Repos and code sharing

**One repo per game, plus one kit repo.** Juan ruled out a single repo for everything.

```
~/src/game-kit/       the kit (Godot addon), shared skills, this design doc: home base
                      → github.com/churrinche-games/kit
~/src/<game>/         each game: a Godot project → github.com/churrinche-games/<game>
~/src/sudoku/         Bichoku's current web version; the Godot port is a new repo
```

What gets shared, and how:

| What | How | Why |
|---|---|---|
| **Kit code** (`addons/churrinche_kit`) | **Vendored copy at a kit tag**: a sync script copies the addon from a kit tag into the game and records the tag in `addons/churrinche_kit/VERSION`. Committed in the game repo. | Anyone can clone a game and open it in Godot, with no submodules or package manager. Each game stays on the kit version it shipped with and upgrades on purpose. |
| **Claude skills** (`.claude/skills/`) | Copied by the same sync script. | Every project has the same skills; see below. |
| **Setup files** (`project.godot` basics, export presets without secrets, CLAUDE.md, `.claude/settings.json`, `.gitignore`, lint config) | Created by the `new-game` skill from templates in the kit. | Written once per game. |
| **Game logic** | Not shared. | Each game's rules are its own. |

Rules:

- **Never edit `addons/churrinche_kit` inside a game.** Fix it in the kit, tag a release, sync. A check in the sync script refuses to overwrite local changes.
- Kit releases are semver tags (`vX.Y.Z`); breaking changes bump the major. Never move or delete a tag.
- While developing kit and game together, the sync script can copy from the kit's working tree; the committed copy is always from a tag.
- Later option: publish the kit on the Godot Asset Library. Not needed now.

### Approaches considered (code sharing)

| Approach | Trade-off | Verdict |
|---|---|---|
| One repo for everything | Easiest sharing, but every game tied into one repo. | Rejected by Juan |
| Git submodule in `addons/` | Pins an exact commit, but clones need `--recursive` (bad for open-source visitors) and edits inside are error-prone. | Rejected |
| Godot Asset Library | Proper Godot install flow, but public review for every release; slow loop. | Later, maybe |
| Hand copy-paste | Copies drift. | Rejected |
| Vendored copy at a tag, by script | Self-contained repos, pinned versions, one command to upgrade. | **Chosen** |

## Claude skills in every project

The kit holds the skills every project uses, in `.claude/skills/`, and the sync script copies them into each game.

**Third-party, vendored at a pinned commit with their license files** (read in full and vetted on 2026-11-21: nothing unsafe, current for Godot 4.7):

- From GodotPrompter (MIT): `gdscript-patterns`, `godot-testing`, `mobile-development`, `export-pipeline`, `localization`, `responsive-ui`, `audio-system`.
- From awesome-gamedev-agent-skills (Apache-2.0): `godot-gdscript-headless-testing`, `puzzle`, `game-feel`.

Not included: `addon-development` (editor plugins; our kit is runtime code), godot-mcp (the shell is enough for now), AI pixel-art generators, Unity skills.

**Our own** (written with the writing-skills process):

- `new-game`: creates `~/src/<game>` with the harness, the kit and the skills.
- `game-art`: how to draw in the chosen art direction, with palettes and scripts. Written after the direction is chosen.
- `release-game`: the release checklist below, Play and itch.io.

`THIRD_PARTY.md` in the kit lists each vendored skill with its source, commit and license. Updating a skill is a deliberate kit release.

## Shared kit (`churrinche_kit`)

- **About screen:** game name and version, "Source code on GitHub" link, licenses and credits, Support entry (store-dependent, see Donations).
- **More games screen:** a static list of the portfolio's games with their Play (or itch.io) links. The current game and unreleased games are hidden.
- **Feedback:** opens an email with the game and version filled in ("Comentarios sobre X v…" / "Feedback on X v…"), plus a link to GitHub issues.
- **Rating prompt:** Play In-App Review, asked once, after 3 wins and on the second session or later; never after a loss, never on first launch. Play build only.
- **Sound:** effects player, music player, mute settings.
- **Settings and storage:** a small versioned save file in `user://`, tolerant of old and broken saves.
- **i18n:** shared strings (es/en) and the language switch.
- **Theme:** a shared Godot `Theme` base and palette slots each game fills.
- **Mobile:** back button, pause on background, safe areas.
- **Tip jar (later):** Play Billing wrapper.

## Game catalog

Ordered by build sequence. Each game is a genre with our own Argentine theme.

| # | Game | Mode | Notes |
|---|---|---|---|
| 1 | **Bichoku** (sudoku, Argentine animals) | levels by difficulty | Port of the web version to Godot. Proves the whole pipeline: kit, art direction, Play, itch.io. |
| 2 | 2048-style merge | endless | Small logic; tiles that grow (coins → bills, plain mate → fancy mate…). |
| 3 | Match-3 | levels | Cascades and specials. |
| 4 | Merge-2 | endless + orders | Biggest of the grid games. |
| 5 | Alfajor stacker | endless | One-tap; quick filler release. |
| 6 | Bondi traffic (sliding-block puzzle) | levels | Levels generated and checked by code. |
| 7 | Peg shooter | levels | Godot physics. |
| 8 | Pinball | endless | Godot physics. |
| later | Fileteado blocks (block placement) | endless | Candidate. |
| later | Escoba solitaire | levels/endless | Card foundation for truco. |
| later | Truco | vs computer | Needs a bluffing AI; its own project. |

The order after #2 is not fixed; quick releases can slot in between bigger ones.

## Release process (per game)

1. Game design doc in `docs/superpowers/specs/`.
2. Build with TDD; tests, lint and the build check pass.
3. Signed AAB (Play App Signing) and web/APK builds for itch.io.
4. Store listings in es-419 and en-US: name, descriptions, icon, screenshots, feature graphic, all made in code like the game.
5. Privacy policy (required by Play even with no data collected) on the GitHub Pages site.
6. Content rating, target audience 13+, Data safety (no data collected).
7. Closed test with the standing tester group for 14 days; collect feedback.
8. Production on Play; publish on itch.io; make the repo public if it isn't yet.
9. Add the game to the kit's More games list, tag a kit release, sync it into the other games with their next update.

## Left to the builder

- Where the More games list lives in the kit and how a game marks itself as current.
- Whether the feedback email is a dedicated address (needed before the first release; never Juan's personal address).
- The exact sfx synth (script vs runtime) per sound.

## Decided with Juan

- **2026-11-21 Language:** Spanish (rioplatense, voseo) and English in every game and listing.
- **2026-11-21 Audience:** 13+ in Play Console, family-friendly content.
- **2026-11-21 Code sharing:** one repo per game plus a kit repo.
- **2026-11-22 Open source:** all repos public; each game links to its repo.
- **2026-11-22 Monetization:** donations (see Donations).
- **2026-11-22 Engine:** Godot for every game.
- **2026-11-22 Art:** banknote-engraving style or a pixel art version of it (choice pending).
- **2026-11-22 Brand:** Churrinche Games (replaces Electro Chicken).
- **2026-11-22 Skills:** every project includes the vetted skills.

## Still open

- Art direction: engraving or pixel art (next step, with a visual comparison).
- Licenses (proposal above).
- GitHub org created under the brand (recommended over a personal account).
- Payments profile and the Play tip jar (later).
- Feedback email address.
- INPI check for the name.
