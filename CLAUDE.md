# Game kit

The shared kit for a portfolio of small, free, Argentine-themed Android games (each game is its own repo and its own Google Play app), and home base for the portfolio's design.

**Start here:** read [docs/superpowers/specs/2026-11-21-portfolio-design.md](docs/superpowers/specs/2026-11-21-portfolio-design.md). It has the intent, the decisions (free, no ads, one app per game, art and sound in code, the stack, how code is shared), the game catalog and the release process.

## Repo

- Local git only, no remote. Pushing anywhere happens only when Juan says so.
- Games install this repo as a git dependency pinned to a tag: `"@electrochicken/kit": "git+file:///Users/juansturla/src/game-kit#vX.Y.Z"`. Every release is a semver tag; a breaking change bumps the major. Never move or delete a tag a game may depend on.
- The kit ships TypeScript source (no build step): `package.json` `exports` point at `src/**/*.ts(x)`.
- Games: `~/src/sudoku` (Bichoku); each new game in `~/src/<game>`.

## Environment

- Node 26 via nvm: run `nvm use` first (the default `node` on this machine is 18). In a non-interactive shell: `export PATH="$HOME/.nvm/versions/node/v26.13.1/bin:$PATH"`.

## Commands

Not set up yet. Planned:

```sh
npm test         # vitest run
npm run lint     # oxlint
npm run build    # tsc -b (type-check only; games bundle the source)
```

Before calling work done: `npm test && npm run lint && npm run build` must all pass.

## Architecture

Not scaffolded yet. Planned:

```
src/
  more-games/      the portfolio's game list + screen
  feedback/        send-feedback link
  rating/          Play In-App Review prompt rules
  sound/           effects synth, music sequencer, mute settings
  storage/         guarded localStorage
  i18n/            Spanish/English strings and language switch
  theme/           shared tokens, dark mode
docs/superpowers/specs/
```

- Kit code must not know about any specific game.
- Art is SVG drawn in code; sound and music are synthesized in code.

## Conventions

- Code, comments, commit messages and docs in English. Interface text in both rioplatense Spanish and English.
- **TDD is the rule:** write a failing test first, watch it fail, then write the minimal code to pass.
- Feature folders; tests colocated as `*.test.ts` (Vitest). Pure logic goes in `.ts` files with tests, kept out of components. No component tests.
- Pin new dependencies to existing major versions; don't add a dependency when a few lines will do.
- Tailwind v4 (CSS-first config); games add `@source` for the kit.
- Never add co-author or AI attribution to commits or PRs.
- Commit to `main`; push only when asked.
