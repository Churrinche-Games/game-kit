# Argentine games

A portfolio of small, free, Argentine-themed Android games, each its own Google Play app, built from one repo with a shared kit. (Working name until the brand is chosen.)

**Start here:** read [docs/superpowers/specs/2026-11-21-portfolio-design.md](docs/superpowers/specs/2026-11-21-portfolio-design.md). It has the intent, the decisions (free, no ads, one app per game, art and sound in code, the stack), the game catalog and the release process. Each game has its own design doc next to it.

## Repo

- Local git only, no remote. Pushing anywhere happens only when Juan says so.
- One repo for every game: `apps/<game>/` per game (a Vite app plus its Capacitor Android project), `packages/kit/` for shared pieces. Not scaffolded yet.

## Environment

- Node 26 via nvm: run `nvm use` first (the default `node` on this machine is 18). In a non-interactive shell: `export PATH="$HOME/.nvm/versions/node/v26.13.1/bin:$PATH"`.
- Android builds need Android Studio and the Android SDK.

## Commands

Not set up yet. Planned, from the repo root:

```sh
npm run dev      # Vite dev server for a game
npm test         # vitest run
npm run lint     # oxlint
npm run build    # tsc -b && vite build
```

Before calling work done: `npm test && npm run lint && npm run build` must all pass.

## Architecture

```
apps/
  <game>/          one game: Vite + React app, Capacitor Android project
packages/
  kit/             shared: more-games screen, feedback, rating prompt, sound synth, storage, theme, i18n strings, tip jar (later)
docs/superpowers/specs/
```

- Shared code lives in `packages/kit`, never copied between games.
- Art is SVG drawn in code; sound and music are synthesized in code. No asset files unless the design doc says so.
- Each game is a genre with its own Argentine theme, never a copy of a specific existing game.

## Conventions

- Code, comments, commit messages and docs in English. Interface text in both rioplatense Spanish and English.
- Phone first: check layouts at 360 and 390 px wide.
- **TDD is the rule:** write a failing test first, watch it fail, then write the minimal code to pass.
- Feature folders; tests colocated as `*.test.ts` (Vitest). Pure logic goes in `.ts` files with tests, kept out of components. No component tests.
- Pin new dependencies to existing major versions; don't add a dependency when a few lines will do.
- Tailwind v4 (CSS-first config).
- Never add co-author or AI attribution to commits or PRs.
- Commit to `main`; push only when asked.
