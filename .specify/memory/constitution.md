<!--
Sync Impact Report
- Version change: 1.0.0 → 2.0.0
- Modified principles:
  - Spec-First Development → Spec-First Development (retained, wording aligned to game context)
  - Smooth, Geospatially Faithful Animation → Comprehensive Test-Driven Development (new)
  - Incremental, Story-Scoped Delivery → Incremental, Story-Scoped Delivery (retained)
  - Simplicity & Minimal Dependencies → Phaser-First Game Architecture (redefined)
  - Accessible, Browser-First Experience → Educational Clarity & Accessible Web (expanded)
- Added sections: Technical Constraints (Phaser, TDD stack), Quality Standards & Non-Goals
- Removed sections: Route-animation geospatial constraints, GIS non-goals
- Templates:
  - .specify/templates/plan-template.md ✅ updated (Constitution Check gates for TDD + Phaser)
  - .specify/templates/spec-template.md ✅ updated (card-counting examples, mandatory test mapping)
  - .specify/templates/tasks-template.md ✅ updated (TDD-first mandatory test phases)
  - .specify/templates/commands/*.md ⚠ pending (directory not present)
  - README.md ✅ updated (project description + governance link)
  - .cursor/rules/specify-rules.mdc ✅ updated (feature plan reference)
  - .specify/feature.json ✅ updated (001-card-counter-tutorial)
- Deferred TODOs: none
-->

# Card Counter Constitution

## Core Principles

### Spec-First Development

Every feature MUST begin with a written specification and implementation plan before
production code changes. Plans MUST include a Constitution Check that passes or
documents justified exceptions in the Complexity Tracking table. Each user story MUST
map to acceptance scenarios and to the test layers that will verify it.

**Rationale**: Card-counting tutorials blend game rules, pedagogy, and UI flow;
changing them without upfront agreement wastes rework across Phaser scenes and test
suites.

### Comprehensive Test-Driven Development

All implementation plans and tasks MUST follow strict comprehensive TDD. For every
feature slice the workflow is non-negotiable:

1. Write unit, functional, integration, and Playwright tests first (red phase).
2. Implement the minimum code required to satisfy those tests (green phase).
3. Refactor while keeping all tests passing.
4. Add additional tests and edge cases until coverage is complete for the slice.

Plans MUST declare which test files and scenarios cover each layer. A story is NOT
done until all four layers exist, pass, and edge cases for that story are covered.

**Rationale**: Counting logic and tutorial progression are correctness-critical;
tests-first prevent regressions in rules, running counts, and learner guidance.

### Incremental, Story-Scoped Delivery

Work MUST be sliced into prioritized user stories that each deliver independently
testable tutorial or gameplay value. P1 (MVP) MUST be implementable and demonstrable
without waiting for lower-priority stories. Each story MUST ship with its full TDD
cycle complete before the next story starts.

**Rationale**: Tutorial games grow scene-by-scene; independent stories enable early
playtesting and isolated test suites per learning objective.

### Phaser-First Game Architecture

The game MUST use Phaser as the primary rendering and scene-management engine. Domain
logic (deck state, hand valuation, counting systems, tutorial progression) MUST live
outside Phaser scenes in plain modules so unit and integration tests do not require
a running canvas. Scenes MUST orchestrate presentation and input, not embed untested
business rules.

**Rationale**: Phaser excels at 2D game UX; separating logic keeps TDD practical and
avoids brittle scene-only tests.

### Educational Clarity & Accessible Web

Primary delivery MUST target modern browsers. Tutorial copy MUST teach counting
concepts clearly and MUST NOT facilitate real-money gambling. Interactive controls
MUST be keyboard-operable. Motion and effects MUST respect `prefers-reduced-motion`
with usable non-animated fallbacks where motion is decorative.

**Rationale**: The product is a learning tool; clarity and accessibility are core
quality, not optional polish.

## Technical Constraints

- **Engine**: Phaser (version pinned in each feature plan Technical Context).
- **Language**: TypeScript for application and test code unless a plan documents an
  exception.
- **Test stack**: Unit and functional tests (e.g., Vitest), integration tests for
  module boundaries and scene wiring, Playwright for end-to-end browser flows. All
  four MUST appear in `plan.md` and `tasks.md` for every story.
- **Game state**: Deck, shoe, hands, bets (if simulated), and count state MUST be
  modeled explicitly; randomness MUST be seedable in tests.
- **Performance budget**: Define frame-time and load targets in `plan.md` Technical
  Context; tutorial scenes MUST remain responsive on reference hardware.
- **Persistence / backend**: Not assumed unless specified in the feature spec; prefer
  client-only tutorial flows.

## Quality Standards & Non-Goals

**Done means:**

- Acceptance scenarios in the feature spec pass via the declared automated suites.
- Unit, functional, integration, and Playwright tests were written before implementation
  for the story, all pass, and edge cases for that story are covered.
- Counting and blackjack rule logic match documented success criteria with test proof.
- Reduced-motion and keyboard paths verified when UI motion or controls are present.
- No unexplained constitution violations in the active plan.

**Explicit non-goals (unless a spec overrides):**

- Real-money gambling, payment processing, or casino-account integration.
- Native mobile apps (web-first; responsive layout is in scope).
- Multiplayer or server-authoritative tables without an explicit spec requirement.
- Advantage-play deployment tooling (trip bankroll, camouflage, team signaling, etc.).

## Governance

This constitution supersedes ad-hoc agent instructions for governed work. Amendments
MUST be made via `/speckit-constitution` with an updated Sync Impact Report,
semantic version bump, and `LAST_AMENDED_DATE` set to the amendment date.

**Versioning policy:**

- **MAJOR**: Principle removal or backward-incompatible redefinition.
- **MINOR**: New principle or materially expanded guidance.
- **PATCH**: Clarifications and non-semantic wording fixes.

**Compliance review:** Every `plan.md` MUST include Constitution Check gates before
Phase 0 research and MUST re-check after Phase 1 design. `/speckit-analyze` treats
constitution conflicts as CRITICAL. `/speckit-tasks` MUST order test tasks before
implementation tasks per the TDD principle.

**Version**: 2.0.0 | **Ratified**: 2026-06-04 | **Last Amended**: 2026-06-06
