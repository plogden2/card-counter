---
description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: MANDATORY — constitution requires unit, functional, integration, and Playwright tests written before implementation for every user story.

**Organization**: Tasks are grouped by user story. Within each story, all test tasks precede implementation tasks (TDD red-green-refactor).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `frontend/src/`, `backend/src/` (only if plan.md selects multi-project layout)
- Paths shown below assume single Phaser project — adjust based on plan.md structure

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create project structure per implementation plan
- [ ] T002 Initialize TypeScript + Phaser project with test dependencies (Vitest, Playwright)
- [ ] T003 [P] Configure linting, formatting, and CI test runners for all four layers

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Tests for Foundation (write first)

- [ ] T004 [P] Unit tests for RNG/seed helper in tests/unit/rng.test.ts
- [ ] T005 [P] Integration test harness for Phaser scene bootstrapping in tests/integration/scene-harness.test.ts

### Implementation for Foundation

- [ ] T006 Define core domain models (Card, Deck, Shoe, Hand) in src/domain/
- [ ] T007 [P] Implement seedable RNG utility in src/lib/rng.ts
- [ ] T008 [P] Setup Phaser game config and base scene in src/game/
- [ ] T009 Configure test scripts: unit, functional, integration, playwright

**Checkpoint**: Foundation ready — user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 1 (MANDATORY — write first, expect red) 🔴

- [ ] T010 [P] [US1] Unit tests for [domain logic] in tests/unit/[name].test.ts
- [ ] T011 [P] [US1] Functional tests for [behavior slice] in tests/functional/[name].test.ts
- [ ] T012 [P] [US1] Integration tests for [module/scene wiring] in tests/integration/[name].test.ts
- [ ] T013 [P] [US1] Playwright E2E for [user journey] in tests/e2e/[name].spec.ts

### Implementation for User Story 1 🟢

- [ ] T014 [P] [US1] Implement domain logic in src/domain/[file].ts
- [ ] T015 [US1] Implement Phaser scene/UI in src/game/[scene].ts
- [ ] T016 [US1] Wire tutorial copy and progression in src/tutorial/[file].ts
- [ ] T017 [US1] Refactor while keeping all US1 tests green

### Edge Cases & Coverage for User Story 1

- [ ] T018 [P] [US1] Add edge-case unit/functional tests per spec.md Edge Cases section
- [ ] T019 [US1] Verify all US1 tests pass; confirm coverage complete for story scope

**Checkpoint**: User Story 1 fully functional, all four test layers green, edge cases covered

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 2 (MANDATORY — write first) 🔴

- [ ] T020 [P] [US2] Unit tests in tests/unit/[name].test.ts
- [ ] T021 [P] [US2] Functional tests in tests/functional/[name].test.ts
- [ ] T022 [P] [US2] Integration tests in tests/integration/[name].test.ts
- [ ] T023 [P] [US2] Playwright E2E in tests/e2e/[name].spec.ts

### Implementation for User Story 2 🟢

- [ ] T024 [P] [US2] [Task description with file path]
- [ ] T025 [US2] [Task description with file path]

### Edge Cases & Coverage for User Story 2

- [ ] T026 [US2] Add edge-case tests and verify full coverage for US2

**Checkpoint**: User Stories 1 AND 2 work independently with complete test coverage

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] TXXX [P] Documentation updates in docs/ and quickstart.md
- [ ] TXXX Performance profiling against plan.md frame-rate targets
- [ ] TXXX Accessibility pass (keyboard, reduced motion, tutorial clarity)
- [ ] TXXX Run full CI suite (unit + functional + integration + Playwright)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
- **User Stories (Phase 3+)**: Depend on Foundational; proceed P1 → P2 → P3; complete TDD cycle per story before next
- **Polish (Final Phase)**: Depends on desired user stories being complete

### Within Each User Story (TDD — non-negotiable)

1. Unit tests → functional tests → integration tests → Playwright tests (red)
2. Domain implementation → scene wiring → tutorial integration (green)
3. Refactor
4. Edge-case tests until coverage complete

### Parallel Opportunities

- All test tasks marked [P] within a story can be authored in parallel before implementation
- Domain and scene files marked [P] can be implemented in parallel after tests exist

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story MUST complete its full TDD cycle before the next priority starts
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
