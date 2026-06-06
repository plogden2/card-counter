# Implementation Plan: Blackjack Card Counting Tutorial Game

**Branch**: `001-card-counter-tutorial` | **Date**: 2026-06-06 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-card-counter-tutorial/spec.md`

## Summary

Build a browser-based blackjack card-counting **tutorial and practice game** using **Phaser 3**
for table presentation and **TypeScript domain modules** for all game logic (testable without
canvas). Learners choose **Tutorial** or **Free Play** at launch, configure table conditions
(1–6 decks, 0–5 other dog players, hands before reshuffle), practice **Hi-Lo** counting,
compare **three bet-sizing models**, view **balance/advantage graphs**, and receive **stay-or-leave**
coaching that accounts for reshuffles and table occupancy. Balance and settings persist in
**localStorage**; mid-hand browser close prompts **forfeit or resume**.

Technical approach: **Vite + Phaser + Vitest + Playwright**; strict **TDD** (unit → functional
→ integration → e2e) per user story before implementation.

## Technical Context

**Language/Version**: TypeScript 5.7, Node.js 22 LTS

**Primary Dependencies**: Phaser 3.80.x, Vite 6, Chart.js 4, Howler 2.x

**Storage**: localStorage (`card-counter:learner-profile`, `card-counter:hand-snapshot`); schema v1

**Testing**: Vitest 3 (unit, functional, integration via domain + scene harness), Playwright 1.52 (e2e)

**Target Platform**: Modern browsers — Chrome, Firefox, Safari, Edge (latest −1); desktop/tablet primary

**Project Type**: Single-page Phaser web tutorial game (client-only)

**Performance Goals**: 60 fps during card animations on reference hardware (Ryzen 5 / integrated GPU);
initial load < 3 s on broadband; input response < 100 ms p95

**Constraints**: Seedable RNG for all tests; `prefers-reduced-motion` instant transitions; no real-money
integration; bundle budget < 5 MB gzipped excluding audio assets

**Scale/Scope**: 5 tutorial lessons; 3 bet models; 1 counting system (Hi-Lo); 0–5 simulated dog players;
20–200 hands/shoe setting

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Requirement | Status |
|------|-------------|--------|
| Spec-First | `spec.md` exists; this plan references it; stories map to acceptance scenarios | ✅ Pass |
| Comprehensive TDD | Each story lists unit, functional, integration, and Playwright tests to write first | ✅ Pass |
| Incremental Scope | User stories independently testable; P1 MVP identified; TDD cycle per story before next | ✅ Pass |
| Phaser Architecture | Domain logic in `src/domain/`; Phaser scenes in `src/game/` orchestrate only | ✅ Pass |
| Educational & Accessible Web | Tutorial/Free Play modes, keyboard controls, reduced-motion, simulated currency only | ✅ Pass |

*Post-Phase 1 re-check (2026-06-06): All gates pass. Domain contracts in `contracts/` enforce testable
boundaries; no constitution exceptions required.*

## Project Structure

### Documentation (this feature)

```text
specs/001-card-counter-tutorial/
├── plan.md              # This file
├── research.md          # Phase 0 decisions
├── data-model.md        # Phase 1 entities
├── quickstart.md        # Dev & test commands
├── contracts/           # Domain & persistence contracts
└── tasks.md             # Phase 2 (/speckit-tasks — not yet created)
```

### Source Code (repository root)

```text
src/
├── domain/
│   ├── card.ts
│   ├── deck.ts
│   ├── shoe.ts
│   ├── hand.ts
│   ├── blackjack.ts      # deal/resolve, insurance, splits
│   ├── counting.ts       # Hi-Lo running/true count
│   ├── bet-models.ts     # spread, ramp, wonging
│   ├── advantage.ts
│   ├── stay-or-leave.ts
│   ├── strategy.ts       # basic strategy for dogs
│   ├── table-dynamics.ts # join/leave simulation
│   └── tutorial.ts       # lesson definitions
├── game/
│   ├── main.ts
│   ├── config.ts
│   ├── scenes/
│   │   ├── BootScene.ts
│   │   ├── HomeScene.ts
│   │   ├── TutorialScene.ts
│   │   ├── SetupScene.ts
│   │   ├── TableScene.ts
│   │   └── AnalyticsOverlay.ts
│   └── controllers/
│       └── GameController.ts
├── tutorial/
│   ├── lessons.ts
│   └── coaching-copy.ts
├── persistence/
│   ├── learner-profile.ts
│   └── hand-snapshot.ts
├── ui/
│   └── charts.ts          # Chart.js wiring
└── lib/
    ├── rng.ts
    └── events.ts

tests/
├── unit/
├── functional/
├── integration/
└── e2e/

public/
└── assets/                # sprites, audio
```

**Structure Decision**: Single-project layout per constitution default. All blackjack and counting
rules live in `src/domain/` with zero Phaser imports. `GameController` is the only bridge tested
in integration layer.

## TDD Strategy by User Story

Tests are written **first** for each story. Story is done when all four layers pass and edge cases
from spec are covered.

### US0 — Choose Tutorial or Free Play (P1)

| Layer | Files | Key scenarios |
|-------|-------|---------------|
| Unit | `tests/unit/mode-routing.test.ts` | Mode enum, no gating flag, last-mode persistence |
| Functional | `tests/functional/launch-modes.test.ts` | Route to Tutorial vs Free Play entry states |
| Integration | `tests/integration/mode-switch.test.ts` | Home → mode → home → alternate mode |
| E2E | `tests/e2e/launch-modes.spec.ts` | Both buttons visible; each loads correct screen |

### US1 — Configure and Play (P1)

| Layer | Files | Key scenarios |
|-------|-------|---------------|
| Unit | `counting.test.ts`, `shoe.test.ts`, `hand.test.ts`, `blackjack.test.ts` | Hi-Lo, true count, deal, insurance, reshuffle |
| Functional | `table-session.test.ts` | Config application, multi-seat deal, hand lifecycle |
| Integration | `practice-table.test.ts` | GameController deal/settle updates count display state |
| E2E | `practice-table.spec.ts` | Configure 6-deck table, play hand, count updates |

### US2 — Bet Sizing & Analytics (P2)

| Layer | Files | Key scenarios |
|-------|-------|---------------|
| Unit | `bet-models.test.ts`, `bet-sizing.test.ts`, `advantage.test.ts` | Three models, TC −6..+8 recommendations |
| Functional | `bet-coaching.test.ts`, `bet-model-selection.test.ts` | Pros/cons content, under/over classification |
| Integration | `analytics-panel.test.ts` | Settled hands append chart series |
| E2E | `bet-sizing.spec.ts` | Select model, bet, graph updates |

### US3 — Bankroll & Stay-or-Leave (P3)

| Layer | Files | Key scenarios |
|-------|-------|---------------|
| Unit | `bankroll.test.ts`, `stay-or-leave.test.ts` | Persistence schema, composite stay score |
| Functional | `session-persistence.test.ts`, `table-dynamics.test.ts` | localStorage round-trip, join/leave events |
| Integration | `bankroll-flow.test.ts` | Reload continues balance; mid-hand prompt |
| E2E | `bankroll-persistence.spec.ts` | Cross-session balance; forfeit vs resume |

### US4 — Presentation (P4)

| Layer | Files | Key scenarios |
|-------|-------|---------------|
| Unit | `motion-preference.test.ts` | Reduced-motion disables tween duration |
| Functional | `audio-cues.test.ts` | Action → sound mapping; mute |
| Integration | `table-presentation.test.ts` | Hand events trigger animation hooks |
| E2E | `presentation.spec.ts` | Dog sprites visible; reduced-motion path |

## Complexity Tracking

> No violations. Complexity Tracking table intentionally empty.
