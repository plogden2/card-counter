# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]

**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

**Language/Version**: [e.g., TypeScript 5.x or NEEDS CLARIFICATION]

**Primary Dependencies**: [e.g., Phaser 3.x or NEEDS CLARIFICATION]

**Storage**: [if applicable, e.g., localStorage for tutorial progress, N/A]

**Testing**: [Vitest (unit/functional), integration test runner, Playwright — all four layers REQUIRED per constitution]

**Target Platform**: [e.g., modern browsers (Chrome/Firefox/Safari latest) or NEEDS CLARIFICATION]

**Project Type**: [e.g., Phaser web tutorial game, SPA or NEEDS CLARIFICATION]

**Performance Goals**: [e.g., 60 fps Phaser scenes, <200ms interaction p95 or NEEDS CLARIFICATION]

**Constraints**: [e.g., bundle size, seedable RNG for tests, prefers-reduced-motion or NEEDS CLARIFICATION]

**Scale/Scope**: [e.g., number of tutorial lessons, deck/shoe configurations or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Requirement | Status |
|------|-------------|--------|
| Spec-First | `spec.md` exists; this plan references it; stories map to acceptance scenarios | ☐ Pass / ☐ Exception |
| Comprehensive TDD | Each story lists unit, functional, integration, and Playwright tests to write first | ☐ Pass / ☐ Exception |
| Incremental Scope | User stories independently testable; P1 MVP identified; TDD cycle per story before next | ☐ Pass / ☐ Exception |
| Phaser Architecture | Domain logic separated from scenes; Phaser used for presentation/input | ☐ Pass / ☐ Exception |
| Educational & Accessible Web | Tutorial clarity, no real-money gambling, keyboard + reduced-motion addressed | ☐ Pass / ☐ Exception |

Document any ☐ Exception rows in **Complexity Tracking** below with rationale.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit-plan output)
├── research.md          # Phase 0 output (/speckit-plan)
├── data-model.md        # Phase 1 output (/speckit-plan)
├── quickstart.md        # Phase 1 output (/speckit-plan)
├── contracts/           # Phase 1 output (/speckit-plan)
└── tasks.md             # Phase 2 output (/speckit-tasks - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
# Single project (DEFAULT for card-counter Phaser game)
src/
├── game/                # Phaser scenes, game config, assets wiring
├── domain/              # Deck, hands, counting logic (Phaser-free)
├── tutorial/            # Lesson flow, copy, progression
└── lib/                 # Shared utilities

tests/
├── unit/
├── functional/
├── integration/
└── e2e/                 # Playwright specs
```

**Structure Decision**: [Document the selected structure and reference the real directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., extra game framework] | [current need] | [why Phaser-only approach insufficient] |
