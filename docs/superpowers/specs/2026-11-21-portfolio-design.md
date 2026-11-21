# Argentine games portfolio: design

Date: 2026-11-21

This is the base document for every game in the portfolio. Each game gets its own design doc later; this one holds what they all share.

## Intent

A portfolio of small, free, Argentine-themed mobile games, each published as its own Android app on Google Play. The purpose is to:

- have a public portfolio of finished work,
- start building an audience,
- get feedback from real players on small games before attempting anything bigger.

Income is welcome but not the goal. Expected traffic is unknown and assumed to be low at first.

## Goals

- Ship small games often, each one complete and polished on its own.
- Every game helps the others get found (cross-promotion inside the games).
- Collect feedback cheaply: Play reviews, an in-game feedback link, Play Console install and retention stats.
- Reuse as much as possible between games: stack, shared pieces, release process.

## Non-goals (for now)

- Ads.
- Accounts, logins, online leaderboards, multiplayer.
- Analytics or tracking SDKs. Play Console's own stats are enough to start, and this keeps the Data safety form trivial. *(Claude's call.)*
- iOS. The stack doesn't rule it out later.

## Anti-goals (failure even if it "works")

- Games that feel like a copy of a specific existing game (its name, art, look or levels). We build in a genre with our own Argentine theme.
- Monetization that annoys early players or costs reviews.
- Anything that leaks the developer's home address or personal data without a deliberate decision.
- Shared code copied between games and drifting apart.

## Monetization

- **Launch: completely free, no ads, no purchases.**
- **Later, once a game has players:** a "Support the developer" tip jar through **Google Play Billing** (in-app consumables, 2–3 amounts). Tips must go through Play Billing; linking out to Cafecito/Mercado Pago from inside the app risks breaking Play's payments policy.
- Before turning on any purchase: check what Play Console will show publicly. An account that sells anything is a "trader" under EU rules, and its address and contact details may be displayed on the listing.
- **Ads** come back up only if one game clearly takes off.

## Distribution

- **Each game is its own Play app,** with its own listing, search traffic and stats, so we can see which games resonate.
- **Developer account: personal** (decided: no existing developer account, no registered company). US$25 one-time, identity verification.
- **Closed test before each launch:** personal accounts created after 2023-11-13 need ≥12 testers opted in continuously for 14 days on the *closed* track (internal testing doesn't count) before production. We keep one standing group of testers (friends, family, coworkers) and reuse it for every game; they are also the first feedback group. Overlap: test the next game while the current one is in review.
- **Developer name:** the public brand the portfolio appears under. It can be changed later in Play Console (Settings → Developer account → Account details), but should be settled before the first public launch.
- **Package names are permanent:** `com.electrochicken.<game>`.

## Art and sound

Everything is made in code, so there are no external asset files, licenses or AI-image questions. No Google Play rule was found requiring disclosure for fixed game assets (Google's AI-Generated Content policy covers apps that *generate* content for users). Re-check the Play policy page before each launch.

- **Art:** flat SVG drawn in code, as in Bichoku's `AnimalIcon.tsx`. Never imitate existing characters or brands.
- **Sound effects:** synthesized with Web Audio at runtime, sfxr-style (blips, pops, chimes).
- **Music:** short chiptune loops written as note sequences played by a small built-in synth. Folk rhythms (chacarera, zamba) are fair game as rhythms and as traditional melodies; modern recordings and arrangements are not.
- **Fallback:** CC0 packs (Kenney, CC0 items on OpenGameArt/Freesound) if a game needs something code can't do well.
- Every game has a mute toggle for music and effects, saved locally.

## Stack

Same as Bichoku (`~/src/sudoku`): **Vite + React + TypeScript + Tailwind v4, Vitest, oxlint, Node 26**, wrapped as an Android app with **Capacitor** (game files bundled in the app, works offline).

- Translations: a small typed dictionary per game plus shared kit strings, no i18n library. *(Claude's call.)*
- Grid and puzzle games (sudoku, 2048-style, match-3, merge-2, block puzzle, sliding puzzle): React, with CSS transforms for movement.
- Physics games (peg shooter, pinball, maybe the stacker): a canvas plus a physics library (matter-js or Planck.js), still TypeScript inside the same shell.
- Native features through Capacitor plugins: Play Billing (tip jar, later), Play In-App Review, haptics.
- Building the Android app needs Android Studio and the Android SDK installed locally.

### Approaches considered (engine)

| Approach | Trade-off | Verdict |
|---|---|---|
| Web stack + Capacitor | Reuses Bichoku, TDD and the shared pieces; Claude works best fully in code. Heavy sprite or physics action is a stretch for plain React. | **Chosen** |
| Same + Phaser/PixiJS/physics library per game | Covers action and physics games without leaving the stack. | **Chosen as an add-on** for the games that need it |
| Godot | Real engine with good physics, but a new language, editor-centric, a weaker testing story, nothing shared with Bichoku. | Rejected unless most games turn out action-heavy |
| Unity | Too heavy for small games; unstable licensing history. | Rejected |

### Approaches considered (monetization and distribution)

- Ads from day one: earns almost nothing at low traffic, costs reviews, more compliance work. Rejected for launch.
- Donations via external links: payments policy risk. Rejected in favor of a Play Billing tip jar, later.
- One collection app: one test and one listing, but weaker store discovery and no per-game signal. Rejected in favor of one app per game.
- Organization developer account: no closed test, but needs a legal business and a D-U-N-S number. Rejected for now.

## Repos and code sharing

**One repo per game, plus one kit repo.** Juan ruled out a single repo for everything.

```
~/src/game-kit/       the shared kit (below) + this portfolio design doc: home base
~/src/sudoku/         Bichoku (stays where it is)
~/src/<game>/         each new game: Vite app + its Capacitor Android project
```

What gets shared, and how:

| What | How | Why |
|---|---|---|
| **Kit code** (changes often; the More games list changes with every launch) | Kit repo installed into each game as a **version-pinned package** | One copy; each game stays on the version it was released with and upgrades on purpose. |
| **Setup files** (Vite, tsconfig, Tailwind, oxlint, CLAUDE.md, `.claude/`, Capacitor config; ~100 lines) | **Copied** from the most recent game when starting a new one | Written once per game, rarely changed; copying is cheaper than a tool. |
| **Game logic** | Not shared | Each game's rules are its own. |

**How the kit is consumed** (verified with a throwaway spike on 2026-11-21):

- Each game's `package.json` has `"@electrochicken/kit": "git+file:///Users/juansturla/src/game-kit#v0.3.0"`, a git dependency on a **tag**, working with local-only git. npm copies the kit into `node_modules` (no symlink), so a game is frozen at its tag. Upgrading is changing the tag and running `npm install`.
- The kit ships **TypeScript source** with no build step: `package.json` `exports` point at `src/*.ts`. The game's `tsc` type-checks it and Vite bundles it. This worked in the spike with Vite 8 and TypeScript 7.
- Each game's CSS adds `@source` pointing at the kit so Tailwind picks up the kit components' classes.
- Kit releases follow semver tags (`vX.Y.Z`); breaking changes bump the major.
- While developing kit and game together, `npm link` (or a temporary `file:` path) skips the tag-and-reinstall loop; the committed dependency is always a tag.
- When the repos get a remote, the URL becomes the GitHub one (one line per game). Publishing to an npm registry (npmjs or GitHub Packages) is an option then, not needed now.

Harness in every repo as in the other projects: `CLAUDE.md`, `.claude/settings.json` allowlist, `.gitignore`, `.nvmrc` = 26, oxlint config, TDD, feature folders with colocated tests, pure logic in `.ts` outside components, local git only.

### Approaches considered (code sharing)

| Approach | Trade-off | Verdict |
|---|---|---|
| One repo for everything (monorepo) | Easiest sharing, but every game tied into one repo. | Rejected by Juan |
| Copy-paste everything | Simplest, but every kit fix or new game means editing N repos by hand, and the copies drift. | Kept only for setup files |
| Git submodule | Pins an exact version, but clones need extra flags and edits inside it are error-prone. | Rejected |
| Git subtree | Code lives inside each game, but updates come with merge noise and sending fixes back is awkward. | Rejected |
| Kit repo as a versioned git package | One copy, versions pinned per game; costs a tag-and-reinstall per kit change. | **Chosen** |

## Shared kit (`~/src/game-kit`)

Built once, used by every game:

- **More games screen:** a static list of the portfolio's games, each linking to its Play listing. The current game is hidden; unreleased games are hidden.
- **Feedback:** a "Send feedback" entry that opens an email (or a short form) with the game name and version filled in.
- **Rating prompt:** Play In-App Review, asked once after a few wins or a good session, never after a loss, never on first launch.
- **Sound:** the effects synth, the music sequencer, the mute settings.
- **Storage:** guarded localStorage helpers (as in Bichoku's `storage.ts`).
- **Theme:** shared tokens and dark mode, with each game picking its own palette.
- **Tip jar (later):** Play Billing wrapper and a small "Support" screen.

## Game catalog

Ordered by build sequence. Each game is a genre with our own Argentine theme.

| # | Game | Mode | Notes |
|---|---|---|---|
| 1 | **Bichoku** (sudoku, Argentine animals) | levels by difficulty | Already built. First release proves the whole pipeline. |
| 2 | 2048-style merge | endless | Small logic; tiles that grow (coins → bills, plain mate → fancy mate…). |
| 3 | Match-3 | levels | Cascades and specials; harder logic. |
| 4 | Merge-2 | endless + orders | Biggest of the grid games (board, orders, meta layer). |
| 5 | Alfajor stacker | endless | One-tap; quickest build, good filler release. |
| 6 | Bondi traffic (sliding-block puzzle) | levels | Levels generated and checked by code, like Bichoku's. |
| 7 | Peg shooter | levels | Physics. |
| 8 | Pinball | endless | Physics. |
| later | Fileteado blocks (block placement) | endless | Candidate. |
| later | Escoba solitaire | levels/endless | Card foundation for truco. |
| later | Truco | vs computer | Needs a bluffing AI; its own project. A first attempt as a Wordle-like didn't make sense. |

The order after #2 is not fixed; quick releases (stacker, bondi) can slot in between bigger ones.

## Release process (per game)

1. Game design doc in `docs/superpowers/specs/`.
2. Build with TDD; `npm test && npm run lint && npm run build` pass.
3. Capacitor Android build, signed AAB, Play App Signing.
4. Store listing: name, short and long description, icon, screenshots, feature graphic. The art is drawn in code like the game.
5. Privacy policy page (required by Play even when no data is collected), hosted on a static page under the brand.
6. Content rating questionnaire, target audience, Data safety form (no data collected).
7. Closed test with the standing tester group for 14 days; collect their feedback.
8. Production release; add the game to the kit's More games list, tag a new kit version, and roll it into the other games with their next update.

## Left to the builder

- Where the kit's More games list lives inside the kit, and how a game marks itself as "current".
- The exact rating-prompt trigger and the feedback channel (email vs form).
- Whether the stacker needs the physics library or simple math is enough.

## Decided with Juan (2026-11-21)

- **Language: Spanish and English.** Every game's interface ships in both: rioplatense Spanish (voseo) and English, following the device language, with a switch in settings. Store listings in both (es-419 and en-US). Bichoku needs a Spanish translation before its release. *(Device-language default and the switch are Claude's call.)*
- **Target audience: 13 and up** in Play Console, to stay outside the Families policy. The games stay family-friendly in content anyway.
- **Brand / developer name: Electro Chicken** (the nickname Juan and Juan's wife go by). Play developer name "Electro Chicken"; app IDs `com.electrochicken.<game>` (permanent); kit package `@electrochicken/kit`. No game, Play developer or trademark use of the name found on 2026-11-21. `electrochicken.com` is taken (parked since 2020); `electrochicken.com.ar` was free, to be registered for the privacy policy and games page.
- **Code sharing: one repo per game plus a kit repo** consumed as a version-pinned package; setup files copied (see Repos and code sharing).
