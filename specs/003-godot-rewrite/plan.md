# Implementation Plan: Godot 4 Cross-Platform Rewrite

**Branch**: `003-godot-rewrite` | **Date**: 2026-06-06 | **Spec**: [design doc](../../docs/superpowers/specs/2026-06-06-godot-cross-platform-rewrite-design.md)

**Input**: Approved design from brainstorming (`docs/superpowers/specs/2026-06-06-godot-cross-platform-rewrite-design.md`)

## Summary

Rewrite the Blackjack Card Counting Tutorial Game in **Godot 4 + GDScript** with pure
domain modules, GameController autoload, 2D UI shell + 3D table presentation. Ship free
on **Steam v1 (Windows)**, then Web HTML5, then iOS.

**Full task-by-task plan:** [`docs/superpowers/plans/2026-06-06-godot-cross-platform-rewrite.md`](../../docs/superpowers/plans/2026-06-06-godot-cross-platform-rewrite.md)

## Technical Context

**Language/Version**: GDScript, Godot 4.4+

**Primary Dependencies**: GUT 9.4 (testing), Forward+ renderer (3D table)

**Storage**: `user://card-counter/` JSON — schema v1 unchanged (`persistence-schema.json`)

**Testing**: GUT unit + functional + integration; export smoke via `tests/run_smoke.gd`

**Target Platform**: Steam Windows x64 (v1) → Web HTML5 → iOS

**Project Type**: Godot cross-platform educational card game (client-only)

**Performance Goals**: 60 fps 3D table; Steam cold start < 5 s on SSD

**Constraints**: Seedable RNG; reduced-motion fallbacks; no real-money gambling; domain scripts MUST NOT extend `Node`

**Scale/Scope**: Feature parity with Phaser implementation (US0–US4); 002 visual spec (3D table + Mix-2 2D shell)

## Constitution Check

| Gate | Requirement | Status |
|------|-------------|--------|
| Spec-First | Design doc approved; plan references it; stories map to tasks | ✅ Pass |
| Comprehensive TDD | Each story has GUT unit, functional, integration tests declared | ✅ Pass |
| Incremental Scope | Phases 1–3 deliver playable MVP before bets/bankroll/presentation | ✅ Pass |
| Godot Architecture | Domain in `godot/scripts/domain/`; scenes orchestrate only | ✅ Pass |
| Educational & Accessible Multi-Platform | Free tutorial, keyboard + touch + reduced-motion in plan | ✅ Pass |

## Project Structure

### Documentation (this feature)

```text
specs/003-godot-rewrite/
├── plan.md              # This file (summary + constitution check)
├── quickstart.md        # Created in Task 27
└── parity-checklist.md  # Created in Task 30

docs/superpowers/
├── specs/2026-06-06-godot-cross-platform-rewrite-design.md
└── plans/2026-06-06-godot-cross-platform-rewrite.md  # Full 30-task plan
```

### Source Code

```text
godot/
├── scripts/domain/      # Ported from src/domain/
├── scripts/game/        # GameController, SceneRouter, AudioManager
├── scripts/persistence/ # Profile + hand snapshot
├── scenes/              # Boot, Home, Setup, Tutorial, Table, Analytics
├── assets/              # 3D models, 2D UI kit, audio
└── tests/               # GUT unit, functional, integration
```

**Structure Decision**: Godot project in `godot/`; Phaser code archived at `src-phaser-archive/` and `tests-phaser-archive/`.

## Phases (30 Tasks)

| Phase | Tasks | Deliverable |
|-------|-------|-------------|
| 0 Scaffold | 1–3 | Constitution updated, Godot project, GUT running |
| 1 Foundation | 4–7 | RNG, card, deck, hand, events |
| 2 US1 Domain | 8–13 | Shoe, counting, blackjack, table session tests green |
| 3 US0 Modes | 14–16 | Home, Tutorial, Setup scenes |
| 4 US2 Bets | 17–18 | Bet models, charts, analytics overlay |
| 5 US3 Bankroll | 19–21 | Persistence, stay-or-leave, GameController |
| 6 US4 Presentation | 22–25 | Table 2D placeholder → 3D, audio, responsive |
| 7 Test Suite | 26 | Full GUT + smoke runner |
| 8 Steam v1 | 27 | Windows export + quickstart |
| 9 Web | 28 | HTML5 export |
| 10 iOS | 29 | Touch layout + Xcode export |
| 11 Parity | 30 | Checklist, archive Phaser, README update |

## Complexity Tracking

> No violations.
