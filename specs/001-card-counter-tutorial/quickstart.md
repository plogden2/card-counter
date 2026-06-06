# Quickstart: Blackjack Card Counting Tutorial Game

**Feature**: `001-card-counter-tutorial`

## Prerequisites

- Node.js 18+ (22 LTS recommended; Vite 6 requires Node ≥ 18)
- npm 10+

## Initial setup (first time)

```bash
cd card-counter
npm install
npx playwright install chromium
```

Use Node 22 if available (`nvm use` reads `.nvmrc`).

## Development

```bash
npm run dev          # Vite dev server → http://localhost:5173
```

## Testing (TDD — run before implementation per story)

```bash
# All unit + functional
npm run test

# Integration (domain + controller harness)
npm run test:integration

# E2E (requires dev server or preview)
npm run test:e2e

# Full CI-equivalent suite
npm run test:all
```

### Expected `package.json` scripts (to be added in implementation)

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "vitest run tests/unit tests/functional",
    "test:integration": "vitest run tests/integration",
    "test:e2e": "playwright test",
    "test:all": "npm run test && npm run test:integration && npm run test:e2e"
  }
}
```

## Manual smoke checklist

1. Launch → Home shows **Tutorial** and **Free Play** (no gating).
2. Free Play → configure 6 decks, 3 players, 75 hands → play one hand → counts update.
3. Dealer Ace → insurance prompt appears.
4. Select bet model → recommendation changes; graph updates after hand.
5. Close tab mid-hand → return → forfeit/resume prompt.
6. Reload browser → balance persists.
7. Enable reduced motion → cards appear instantly; keyboard still works.

## Key paths

| Artifact | Path |
|----------|------|
| Spec | `specs/001-card-counter-tutorial/spec.md` |
| Plan | `specs/001-card-counter-tutorial/plan.md` |
| Domain logic | `src/domain/` |
| Phaser scenes | `src/game/scenes/` |
| Tests | `tests/{unit,functional,integration,e2e}/` |

## Reference hardware (performance)

- CPU: Ryzen 5 5600 or equivalent
- GPU: Integrated graphics
- Target: 60 fps card animations, < 3 s cold load
