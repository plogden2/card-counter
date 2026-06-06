<!--
Sync Impact Report
- Version change: 2.0.0 → 3.0.0 (Godot cross-platform rewrite)
- Modified principles:
  - Phaser-First Game Architecture → Godot-First Game Architecture (redefined)
  - Educational Clarity & Accessible Web → Educational Clarity & Accessible Multi-Platform (expanded)
- Modified sections: Technical Constraints (Godot 4.4+, GUT, export smoke; Playwright replaced)
- Retained principles: Spec-First Development, Comprehensive Test-Driven Development,
  Incremental Story-Scoped Delivery, Quality Standards & Non-Goals
- Templates: pending sync in subsequent tasks (plan-template, spec-template, tasks-template)
- Deferred TODOs: template and dependent artifact sync
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

### Godot-First Game Architecture

The game MUST use Godot 4 as the primary rendering and scene-management engine. Domain
logic (deck state, hand valuation, counting systems, tutorial progression) MUST live
in plain GDScript modules under `godot/scripts/domain/` with zero `Node` imports so
GUT unit tests do not require a running scene. Scenes MUST orchestrate presentation
and input, not embed untested business rules.

**Rationale**: Godot supports 2D UI + 3D table in one project; separating logic keeps
TDD practical and avoids brittle scene-only tests.

### Educational Clarity & Accessible Multi-Platform

The game MUST ship free as an educational tutorial on Steam, Web, and iOS. Tutorial
copy MUST teach counting concepts clearly and MUST NOT facilitate real-money gambling.
Desktop builds MUST support keyboard-operable controls. iOS builds MUST support touch
targets ≥ 44 pt. Motion and effects MUST respect reduced-motion preference with
usable non-animated fallbacks where motion is decorative.

**Rationale**: The product is a learning tool; clarity and accessibility are core
quality across all export targets.

## Technical Constraints

- **Engine**: Godot 4.4+ (version pinned in each feature plan Technical Context).
- **Language**: GDScript for application and test code unless a plan documents an exception.
- **Test stack**: GUT for unit, functional, and integration tests; export smoke via
  headless CLI. Playwright is replaced by scene integration + export smoke for the
  Godot rewrite.
- **Game state**: Deck, shoe, hands, bets, and count state MUST be modeled explicitly;
  randomness MUST be seedable in tests.
- **Performance budget**: 60 fps on 3D table scene; initial Steam load < 5 s on SSD.
- **Persistence**: `user://card-counter/` JSON files per `persistence-schema.json` v1.

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

**Version**: 3.0.0 | **Ratified**: 2026-06-04 | **Last Amended**: 2026-06-06
