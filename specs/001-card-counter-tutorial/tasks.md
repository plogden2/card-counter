---
description: "Task list for Blackjack Card Counting Tutorial Game"
---

# Tasks: Blackjack Card Counting Tutorial Game

**Input**: Design documents from `/specs/001-card-counter-tutorial/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: MANDATORY — constitution requires unit, functional, integration, and Playwright tests written before implementation for every user story.

**Organization**: Tasks grouped by user story. Within each story: tests first (red) → implementation (green) → edge cases → coverage verification.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US0–US4 mapping to spec.md user stories
- Every task includes an exact file path

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize Vite + TypeScript + Phaser project and repository structure

- [ ] T001 Create directory structure per plan.md in `src/`, `tests/`, `public/assets/`
- [ ] T002 Initialize `package.json` with Vite 6, TypeScript 5.7, Phaser 3.80, Chart.js, Howler in project root
- [ ] T003 [P] Configure `tsconfig.json` and `vite.config.ts` with path aliases for `src/`
- [ ] T004 [P] Configure Vitest in `vitest.config.ts` for `tests/unit` and `tests/functional`
- [ ] T005 [P] Configure Playwright in `playwright.config.ts` for `tests/e2e/`
- [ ] T006 [P] Add npm scripts in `package.json` per `quickstart.md` (`dev`, `build`, `test`, `test:integration`, `test:e2e`, `test:all`)
- [ ] T007 [P] Create `index.html` and `src/game/main.ts` Phaser bootstrap stub

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core utilities and domain primitives required by ALL user stories

**⚠️ CRITICAL**: No user story work until this phase checkpoint passes

### Tests for Foundation (write first) 🔴

- [ ] T008 [P] Unit tests for seedable RNG in `tests/unit/rng.test.ts`
- [ ] T009 [P] Unit tests for Card rank/suit and Hi-Lo tag in `tests/unit/card.test.ts`
- [ ] T010 [P] Unit tests for event bus types in `tests/unit/events.test.ts`

### Implementation for Foundation 🟢

- [ ] T011 [P] Implement seedable RNG in `src/lib/rng.ts`
- [ ] T012 [P] Implement typed event bus in `src/lib/events.ts`
- [ ] T013 [P] Implement Card type and helpers in `src/domain/card.ts`
- [ ] T014 [P] Implement Deck builder in `src/domain/deck.ts`
- [ ] T015 Implement Hand valuation in `src/domain/hand.ts`
- [ ] T016 [P] Implement Phaser config in `src/game/config.ts`
- [ ] T017 Implement BootScene stub in `src/game/scenes/BootScene.ts`
- [ ] T018 [P] Create GameController skeleton in `src/game/controllers/GameController.ts`
- [ ] T019 [P] Integration harness for GameController boot in `tests/integration/scene-harness.test.ts`

**Checkpoint**: Foundation tests green; domain primitives and controller skeleton ready

---

## Phase 3: User Story 0 — Choose Tutorial or Free Play (Priority: P1)

**Goal**: Learner selects Tutorial or Free Play at launch (no gating) and Tutorial delivers a guided five-lesson path (FR-001b)

**Independent Test**: Launch app → both mode buttons visible → Tutorial opens lesson L1 with step-by-step coaching → Free Play opens setup → return home → switch modes freely

### Tests for User Story 0 (write first) 🔴

- [ ] T020 [P] [US0] Unit tests for mode routing and no-gating rules in `tests/unit/mode-routing.test.ts`
- [ ] T021 [P] [US0] Functional tests for Tutorial vs Free Play entry states in `tests/functional/launch-modes.test.ts`
- [ ] T022 [P] [US0] Integration tests for home → mode → home → alternate mode in `tests/integration/mode-switch.test.ts`
- [ ] T023 [P] [US0] Playwright E2E for mode selection in `tests/e2e/launch-modes.spec.ts`
- [ ] T024 [P] [US0] Unit tests for five tutorial lesson definitions and progression in `tests/unit/tutorial.test.ts`
- [ ] T025 [P] [US0] Playwright E2E for guided Tutorial L1 lesson flow in `tests/e2e/tutorial-lesson.spec.ts`

### Implementation for User Story 0 🟢

- [ ] T026 [P] [US0] Implement GameMode types and router in `src/domain/mode-routing.ts`
- [ ] T027 [US0] Implement HomeScene with Tutorial and Free Play buttons in `src/game/scenes/HomeScene.ts`
- [ ] T028 [P] [US0] Define `LearnerProfile` types and `lastMode` read/write stubs only in `src/persistence/learner-profile.ts` (balance persistence deferred to US3)
- [ ] T029 [US0] Connect HomeScene navigation to TutorialScene and SetupScene in `src/game/controllers/GameController.ts`
- [ ] T030 [P] [US0] Implement five tutorial lesson definitions in `src/tutorial/lessons.ts`
- [ ] T031 [US0] Implement tutorial progression wiring in `src/domain/tutorial.ts`
- [ ] T032 [US0] Implement TutorialScene guided lesson flow in `src/game/scenes/TutorialScene.ts`

### Edge Cases & Coverage for User Story 0

- [ ] T033 [US0] Verify all US0 tests pass; confirm FR-001a (no gating) and FR-001b (lesson path) acceptance scenarios

**Checkpoint**: US0 complete — mode selection and guided Tutorial lesson path independently testable

---

## Phase 4: User Story 1 — Configure and Play at the Practice Table (Priority: P1) 🎯 MVP

**Goal**: Configurable table, full blackjack hand flow, Hi-Lo counts, insurance, reshuffle

**Independent Test**: Free Play setup (6 decks, 3 players, 75 hands) → play full hand with insurance path → counts update → shoe reshuffles at threshold

### Tests for User Story 1 (write first) 🔴

- [ ] T034 [P] [US1] Unit tests for Hi-Lo counting in `tests/unit/counting.test.ts`
- [ ] T035 [P] [US1] Unit tests for shoe draw/reshuffle in `tests/unit/shoe.test.ts`
- [ ] T036 [P] [US1] Unit tests for hand valuation edge cases in `tests/unit/hand.test.ts`
- [ ] T037 [P] [US1] Unit tests for deal/insurance/split/settle in `tests/unit/blackjack.test.ts`
- [ ] T038 [P] [US1] Unit tests for basic strategy in `tests/unit/strategy.test.ts`
- [ ] T039 [P] [US1] Functional tests for table session lifecycle in `tests/functional/table-session.test.ts`
- [ ] T040 [P] [US1] Integration tests for config → deal → count in `tests/integration/practice-table.test.ts`
- [ ] T041 [P] [US1] Playwright E2E for configure and play hand in `tests/e2e/practice-table.spec.ts`

### Implementation for User Story 1 🟢

- [ ] T042 [P] [US1] Implement Shoe module in `src/domain/shoe.ts`
- [ ] T043 [P] [US1] Implement Hi-Lo counting in `src/domain/counting.ts`
- [ ] T044 [P] [US1] Implement basic strategy tables in `src/domain/strategy.ts`
- [ ] T045 [US1] Implement blackjack deal/actions/settle in `src/domain/blackjack.ts`
- [ ] T046 [P] [US1] Implement TableConfiguration types in `src/domain/table-config.ts`
- [ ] T047 [US1] Implement SetupScene controls (decks, players, hands) in `src/game/scenes/SetupScene.ts`
- [ ] T048 [US1] Implement TableScene betting and player actions in `src/game/scenes/TableScene.ts`
- [ ] T049 [US1] Wire GameController hand lifecycle and count events in `src/game/controllers/GameController.ts`
- [ ] T050 [P] [US1] Add placeholder dog seat rendering in `src/game/scenes/TableScene.ts`
- [ ] T051 [US1] Wire Tutorial lesson preset table configs to TableScene entry in `src/game/controllers/GameController.ts`

### Edge Cases & Coverage for User Story 1

- [ ] T052 [P] [US1] Add edge-case tests for shoe exhaustion and hand-count reshuffle in `tests/unit/shoe.test.ts`
- [ ] T053 [P] [US1] Add edge-case tests for insurance accept/decline/dealer BJ in `tests/unit/blackjack.test.ts`
- [ ] T054 [P] [US1] Add edge-case tests for multi-seat visible card counting in `tests/unit/counting.test.ts`
- [ ] T055 [US1] Verify all US1 tests pass; confirm coverage for US1 acceptance scenarios

**Checkpoint**: US1 complete — playable configurable table with counting

---

## Phase 5: User Story 2 — Learn Optimal Bet Sizing with Live Feedback (Priority: P2)

**Goal**: Three selectable bet models with pros/cons/EV, recommendations, coaching, graphs

**Independent Test**: Compare bet models → select spread table → positive TC hand → see recommendation → bet under range → coaching + graph update

### Tests for User Story 2 (write first) 🔴

- [ ] T056 [P] [US2] Unit tests for three bet models TC −6..+8 in `tests/unit/bet-models.test.ts`
- [ ] T057 [P] [US2] Unit tests for bet recommendation clamping in `tests/unit/bet-sizing.test.ts`
- [ ] T058 [P] [US2] Unit tests for advantage estimation in `tests/unit/advantage.test.ts`
- [ ] T059 [P] [US2] Functional tests for bet coaching classification in `tests/functional/bet-coaching.test.ts`
- [ ] T060 [P] [US2] Functional tests for model selection UI content in `tests/functional/bet-model-selection.test.ts`
- [ ] T061 [P] [US2] Integration tests for analytics series append in `tests/integration/analytics-panel.test.ts`
- [ ] T062 [P] [US2] Playwright E2E for bet sizing and graphs in `tests/e2e/bet-sizing.spec.ts`

### Implementation for User Story 2 🟢

- [ ] T063 [P] [US2] Implement three bet models in `src/domain/bet-models.ts`
- [ ] T064 [P] [US2] Implement advantage estimation in `src/domain/advantage.ts`
- [ ] T065 [US2] Implement bet recommendation and coaching logic in `src/domain/bet-sizing.ts`
- [ ] T066 [P] [US2] Implement coaching copy in `src/tutorial/coaching-copy.ts`
- [ ] T067 [US2] Implement Chart.js balance/advantage charts in `src/ui/charts.ts`
- [ ] T068 [US2] Implement AnalyticsOverlay toggle in `src/game/scenes/AnalyticsOverlay.ts`
- [ ] T069 [US2] Add bet model picker and recommendation UI to `src/game/scenes/SetupScene.ts` and `src/game/scenes/TableScene.ts`
- [ ] T070 [US2] Wire post-hand coaching events in `src/game/controllers/GameController.ts`

### Edge Cases & Coverage for User Story 2

- [ ] T071 [P] [US2] Add edge-case tests for optimal bet below table minimum in `tests/unit/bet-sizing.test.ts`
- [ ] T072 [P] [US2] Add edge-case tests for bet model switch between hands in `tests/functional/bet-model-selection.test.ts`
- [ ] T073 [US2] Verify all US2 tests pass; confirm graph data points for 50-hand script

**Checkpoint**: US2 complete — bet coaching and analytics independently testable

---

## Phase 6: User Story 3 — Manage Bankroll and Know When to Leave (Priority: P3)

**Goal**: Persistent balance, stay-or-leave coaching, table dynamics, mid-hand recovery, confirmed reset bankroll (FR-011)

**Independent Test**: Play across reload → balance persists → trigger stay prompt → mid-hand close → forfeit/resume prompt → manual reset with confirm restores $1,000

### Tests for User Story 3 (write first) 🔴

- [ ] T074 [P] [US3] Unit tests for learner profile schema in `tests/unit/bankroll.test.ts`
- [ ] T075 [P] [US3] Unit tests for stay-or-leave composite score in `tests/unit/stay-or-leave.test.ts`
- [ ] T076 [P] [US3] Unit tests for table join/leave rules in `tests/unit/table-dynamics.test.ts`
- [ ] T077 [P] [US3] Functional tests for localStorage round-trip in `tests/functional/session-persistence.test.ts`
- [ ] T078 [P] [US3] Functional tests for join/leave events in `tests/functional/table-dynamics.test.ts`
- [ ] T079 [P] [US3] Integration tests for persist/reload/mid-hand prompt in `tests/integration/bankroll-flow.test.ts`
- [ ] T080 [P] [US3] Playwright E2E for persistence, stay-or-leave, and confirmed reset bankroll in `tests/e2e/bankroll-persistence.spec.ts`

### Implementation for User Story 3 🟢

- [ ] T081 [P] [US3] Implement full learner profile load/save (balance, bet model, preferences) in `src/persistence/learner-profile.ts` extending US0 stubs
- [ ] T082 [P] [US3] Implement hand snapshot save/load/clear in `src/persistence/hand-snapshot.ts`
- [ ] T083 [US3] Implement stay-or-leave assessment in `src/domain/stay-or-leave.ts`
- [ ] T084 [US3] Implement table dynamics join/leave in `src/domain/table-dynamics.ts`
- [ ] T085 [US3] Wire balance persistence in `src/game/controllers/GameController.ts`
- [ ] T086 [US3] Implement reset bankroll confirm dialog and action in `src/game/scenes/TableScene.ts`
- [ ] T087 [US3] Implement mid-hand forfeit/resume dialog in `src/game/scenes/TableScene.ts`
- [ ] T088 [US3] Wire stay-or-leave coaching toasts in `src/game/scenes/TableScene.ts`

### Edge Cases & Coverage for User Story 3

- [ ] T089 [P] [US3] Add edge-case tests for corrupted profile/snapshot recovery in `tests/functional/session-persistence.test.ts`
- [ ] T090 [P] [US3] Add edge-case tests for insurance refund on forfeit in `tests/integration/bankroll-flow.test.ts`
- [ ] T091 [P] [US3] Add edge-case tests for drawdown + advantage composite prompts in `tests/unit/stay-or-leave.test.ts`
- [ ] T092 [US3] Verify all US3 tests pass; confirm FR-011 reset-with-confirm and cross-session persistence

**Checkpoint**: US3 complete — bankroll and stay-or-leave independently testable

---

## Phase 7: User Story 4 — Immersive Dogs-at-the-Table Presentation (Priority: P4)

**Goal**: Low-poly dog art, smooth animations, cute SFX, reduced-motion and mute

**Independent Test**: Launch table → distinct dog characters visible → SFX on actions → reduced-motion instant cards → keyboard playable

### Tests for User Story 4 (write first) 🔴

- [ ] T093 [P] [US4] Unit tests for reduced-motion tween config in `tests/unit/motion-preference.test.ts`
- [ ] T094 [P] [US4] Functional tests for action-to-sound mapping in `tests/functional/audio-cues.test.ts`
- [ ] T095 [P] [US4] Integration tests for animation hooks on hand events in `tests/integration/table-presentation.test.ts`
- [ ] T096 [P] [US4] Playwright E2E for presentation and a11y in `tests/e2e/presentation.spec.ts`

### Implementation for User Story 4 🟢

- [ ] T097 [P] [US4] Add low-poly dog sprite assets in `public/assets/sprites/dogs/`
- [ ] T098 [P] [US4] Add SFX assets per action category in `public/assets/audio/`
- [ ] T099 [US4] Implement Howler audio manager in `src/game/audio/AudioManager.ts`
- [ ] T100 [US4] Implement card/chip animations with reduced-motion branch in `src/game/scenes/TableScene.ts`
- [ ] T101 [US4] Implement distinct dog character seats in `src/game/scenes/TableScene.ts`
- [ ] T102 [US4] Wire mute toggle and motion preference in `src/game/scenes/HomeScene.ts`
- [ ] T103 [US4] Implement keyboard bindings for all primary actions in `src/game/scenes/TableScene.ts`

### Edge Cases & Coverage for User Story 4

- [ ] T104 [P] [US4] Add edge-case tests for mid-session mute and motion toggle in `tests/functional/audio-cues.test.ts`
- [ ] T105 [US4] Verify all US4 tests pass; confirm keyboard-only hand completable under reduced motion

**Checkpoint**: US4 complete — presentation layer polished

---

## Phase 8: Cross-Cutting Polish

**Purpose**: Full CI, performance, accessibility audit, documentation

- [ ] T106 [P] Run full CI suite via `npm run test:all` and fix failures
- [ ] T107 [P] Performance profiling against 60 fps target in `src/game/scenes/TableScene.ts`
- [ ] T108 Accessibility audit for keyboard paths and coaching clarity in `src/game/scenes/`
- [ ] T109 Update `specs/001-card-counter-tutorial/quickstart.md` with final commands and smoke steps

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1 (Setup)
    ↓
Phase 2 (Foundational) — BLOCKS all user stories
    ↓
Phase 3 (US0) ──┐  includes FR-001b lesson path (T024–T032)
Phase 4 (US1) ──┼── P1 MVP: US0 + US1
    ↓           │
Phase 5 (US2)   │
    ↓           │
Phase 6 (US3)   │
    ↓           │
Phase 7 (US4)   │
    ↓           │
Phase 8 (Polish)
```

### User Story Dependencies

| Story | Depends on | Can start after |
|-------|------------|-----------------|
| US0 | Foundation | Phase 2 checkpoint |
| US1 | Foundation, US0 (navigation + lesson presets) | Phase 3 checkpoint |
| US2 | US1 (hand settle events) | Phase 4 checkpoint |
| US3 | US1 (session state), US2 (bet model in stay calc) | Phase 5 checkpoint |
| US4 | US1 (TableScene exists) | Phase 4 checkpoint (may parallel with US2/US3) |

### Learner profile ownership

| Phase | Task | Scope |
|-------|------|-------|
| US0 T028 | Types + `lastMode` stubs only | No balance I/O |
| US3 T081 | Full profile load/save | Balance, bet model, preferences |

### Within Each User Story (TDD)

1. Unit → functional → integration → Playwright tests (expect red)
2. Domain modules → scenes → controller wiring (green)
3. Edge-case tests → coverage verification

### Parallel Opportunities

- **Phase 1**: T003, T004, T005, T006, T007 in parallel after T002
- **Phase 2**: T008–T010 tests parallel; T011–T014 domain parallel; T016, T018, T019 parallel
- **US0**: T024–T025 tests parallel after T023; T030 parallel with T026–T029
- **Per story**: All test tasks marked [P] can be written in parallel
- **US4** can start after US1 while US2/US3 proceed

---

## Implementation Strategy

### MVP First (P1)

Deliver **US0 + US1** first (Phases 3–4):

1. Complete Setup + Foundation
2. US0: Mode selection **and** guided Tutorial lesson path (FR-001b)
3. US1: Configurable Free Play table, hand flow, counting, insurance, reshuffle
4. **STOP and VALIDATE**: `npm run test:all` for US0 + US1 scopes

### Incremental Delivery

| Increment | Stories | Learner value |
|-----------|---------|---------------|
| MVP | US0 + US1 | Tutorial lessons + Free Play counting table |
| v0.2 | US2 | Bet models, coaching, graphs |
| v0.3 | US3 | Persistence, stay-or-leave, reset bankroll, mid-hand recovery |
| v0.4 | US4 + Phase 8 | Polish, dogs art, SFX, CI hardening |

### Suggested MVP Scope

**US0 + US1** (Tasks T001–T055): Tutorial lesson path, mode selection, Free Play configuration, full hand lifecycle, Hi-Lo display, insurance, reshuffle.

---

## Notes

- Total tasks: **109**
- Remediation 2026-06-06: US0 expanded for FR-001b; learner-profile split clarified; FR-011 reset UI added (T086, T080)
- Commit after each task or logical group
- Each story requires all four test layers green before moving to next priority
- Domain modules MUST NOT import Phaser (constitution)
- Use seeded RNG in all unit/functional tests per `src/lib/rng.ts`
