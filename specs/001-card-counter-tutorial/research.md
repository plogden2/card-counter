# Research: Blackjack Card Counting Tutorial Game

**Feature**: `001-card-counter-tutorial` | **Date**: 2026-06-06

## R-001: Application scaffold & bundler

**Decision**: Vite 6 + TypeScript 5.7 + `phaser` 3.80.x as npm dependencies.

**Rationale**: Vite provides fast HMR for Phaser scene iteration, native ESM, and straightforward
Vitest/Playwright integration. Phaser 3.80 is stable, well-documented for 2D card games, and
supports WebGL/Canvas with scene lifecycle hooks that map cleanly to our architecture.

**Alternatives considered**:
- **Webpack**: Heavier config; no advantage for a single-page game.
- **Bun**: Faster installs but less mature Phaser ecosystem documentation.
- **PixiJS raw**: Lower-level; would reinvent scene management Phaser already provides.

## R-002: Test stack (constitution TDD)

**Decision**: Vitest 3 (unit + functional + integration), `@vitest/browser` or Phaser headless
harness for integration, Playwright 1.52 for e2e.

**Rationale**: Vitest shares Vite config, runs domain tests without canvas, and supports
seeded RNG fixtures. Playwright validates real browser flows (mode select, persistence,
reduced-motion). Four layers map 1:1 to spec Test Mapping tables.

**Alternatives considered**:
- **Jest**: Requires separate transform config for Vite/ESM.
- **Cypress**: Viable e2e but Playwright has stronger multi-tab persistence testing.
- **Phaser-only tests**: Cannot satisfy constitution unit/functional separation.

## R-003: Domain / presentation split

**Decision**: Pure TypeScript modules in `src/domain/` with zero Phaser imports; Phaser scenes
in `src/game/` subscribe to a thin `GameController` façade that delegates to domain services.

**Rationale**: Enables 100% unit coverage of counting, shoe, hand resolution, bet models, and
stay-or-leave logic without booting WebGL. Matches constitution Phaser-First principle
(presentation in scenes, rules in domain).

**Alternatives considered**:
- **Rules inside Phaser scenes**: Faster prototype but brittle, untestable without canvas.
- **ECS framework**: Over-engineered for turn-based blackjack.

## R-004: Persistence

**Decision**: `localStorage` key `card-counter:learner-profile` (JSON), versioned schema v1;
optional `card-counter:hand-snapshot` for mid-hand resume.

**Rationale**: Spec requires same-device balance persistence and mid-hand forfeit/resume prompt.
No backend in scope. Schema versioning supports corruption recovery (forfeit-only path).

**Alternatives considered**:
- **IndexedDB**: Unnecessary volume for <10 KB profile payload.
- **sessionStorage**: Fails cross-session balance persistence requirement.

## R-005: Analytics graphs

**Decision**: DOM overlay panel using Chart.js 4 (line charts for balance and advantage);
Phaser game canvas remains for table visuals only.

**Rationale**: Time-series charts are easier to test in functional tests via DOM queries;
decouples graph updates from Phaser render loop. Chart.js is lightweight and accessible.

**Alternatives considered**:
- **Phaser Graphics plotting**: Harder to label axes, tooltips, and test numerically.
- **D3**: Heavier dependency for two line charts.

## R-006: Bet-sizing models (v1)

**Decision**: Three built-in models with documented unit spreads:

| Model | Spread (units by true count) | Pros (summary) | Cons (summary) |
|-------|------------------------------|----------------|----------------|
| Spread table | ≤0:1, +1:2, +2:4, +3:6, ≥+4:8 | Maximizes edge at high counts | Higher variance, larger spreads detectable |
| Flat ramp | units = max(1, floor(TC)) capped at 8 | Simple to learn | Under-bets at high TC, over-bets at low positive TC |
| Wonging | bet only when TC ≥ +1 at 1 unit; ramp +2:2, +3:4, +4:6 | Reduces hours at disadvantage | Misses hands; requires discipline |

Expected-return projections: Monte Carlo simulation (seeded, 10k shoes) per model at current
table config; displayed as illustrative hourly EV range, not guaranteed.

**Rationale**: Spec requires ≥3 selectable models with pros/cons/expected return; these are
standard teaching spreads testable with fixed true-count fixtures.

**Alternatives considered**:
- **Kelly criterion**: Correct mathematically but confusing for beginners; defer to v2.
- **Single model only**: Rejected per clarification session.

## R-007: Stay-or-leave assessment

**Decision**: Composite score after each settled hand:

```
stayScore = w1 * normalizedAdvantage + w2 * reshuffleProximity + w3 * occupancyFactor - w4 * drawdownPenalty
```

- **normalizedAdvantage**: true count mapped to 0–1 vs selected bet model's worthwhile threshold.
- **reshuffleProximity**: higher when hands-until-reshuffle < 20% of configured shoe length.
- **occupancyFactor**: increases variance penalty when player count changes in last 3 hands.
- **drawdownPenalty**: triggers when balance < 50% session-start.

Prompt when `stayScore < 0.35` for 3 consecutive hands OR immediate prompt after reshuffle if
TC near 0 and proximity low.

**Rationale**: Implements clarification to factor reshuffles, join/leave, and advantage—not
drawdown alone.

**Alternatives considered**:
- **Fixed TC < +1 for 15 hands**: Too rigid; doesn't account for reshuffle or occupancy.
- **Manual learner judgment only**: Fails tutorial coaching requirement.

## R-008: Edge-case defaults (deferred from clarify)

| Case | Decision |
|------|----------|
| Shoe exhausted before hand-count threshold | Reshuffle immediately; cannot deal next hand |
| Hands-before-reshuffle with cards remaining | Still reshuffle at hand count (penetration-style tutorial setting) |
| Bet > balance or table max | Clamp to max allowed; show coaching message |
| Optimal bet < table min | Recommend table minimum; coaching notes "floor applied" |
| Corrupted profile/snapshot on load | Reset to defaults with notice; offer forfeit-only if snapshot corrupt |
| Insurance on mid-hand forfeit | Refund insurance wager; restore pre-hand balance and count state |
| Tutorial lesson count | 5 lessons (see data-model.md `TutorialLesson` enum) |
| Player join/leave frequency | ~15% chance per hand interval between hands, capped 0–5 others |
| Animation performance | Target 60 fps; reduced-motion uses instant transitions (0 ms) |

## R-009: Audio & art pipeline

**Decision**: Howler.js 2.x for SFX; low-poly GLB/PNG sprite atlases generated in Aseprite or
Blender-to-sprite workflow; placeholder geometric dog silhouettes acceptable for MVP tests.

**Rationale**: Howler is framework-agnostic, testable via mute flag; spec requires cute SFX
categories per action. Art pipeline documented for P4 story without blocking P1 domain tests.

**Alternatives considered**:
- **Phaser built-in audio only**: Sufficient but Howler gives finer per-category control.
- **3D low-poly in Phaser**: Possible via pre-rendered sprites; true 3D adds complexity without
  educational value.

## R-010: Basic strategy for dog players

**Decision**: S17 basic strategy lookup table (hard/soft/pair matrices) in `src/domain/strategy.ts`.

**Rationale**: Non-learner dogs must play automatically; standard S17 tables are deterministic
and unit-testable.

**Alternatives considered**:
- **Random valid moves**: Breaks table realism and count training value.
