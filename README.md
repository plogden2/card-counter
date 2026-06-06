# Card Counter

A blackjack card-counting **tutorial web game** built with **Phaser**. Learners practice
counting systems through guided drills and simulated play—educational only, not real-money
gambling.

## Development

### Prerequisites

- Node.js 18+ (22 LTS recommended; Vite 6 requires Node ≥ 18)
- npm 10+

### First-time setup

```bash
cd card-counter
nvm install 22.22.0   # Windows (nvm-windows): install once if not already present
nvm use 22.22.0       # reads .nvmrc; requires Node 18+ for Vite 6
npm install
npx playwright install chromium   # only needed for e2e tests
```

If you already have Node 20 via nvm, `nvm use 20.20.2` also works (18+ is required).

### Start the dev server

```bash
nvm use 22.22.0   # skip if your shell already reports node v18+
npm run dev
```

Verify with `node --version` before starting — **Node 16 will fail** with a `node:fs/promises` error from Vite.

Open [http://localhost:5173](http://localhost:5173). Vite serves the Phaser app with hot reload.

### Other commands

```bash
npm run build      # production build → dist/
npm run preview    # preview production build locally
npm run test       # unit + functional tests
npm run test:all   # full suite (unit, integration, e2e)
```

More detail (smoke checklist, test layers): [`specs/001-card-counter-tutorial/quickstart.md`](specs/001-card-counter-tutorial/quickstart.md).

## Governance

Feature work is governed by the [project constitution](.specify/memory/constitution.md).
All plans follow **spec-first** delivery and **comprehensive TDD** (unit, functional,
integration, and Playwright tests written before implementation).

## Spec Kit

Active feature specs live under `specs/`. See `.specify/feature.json` for the current
feature directory.
