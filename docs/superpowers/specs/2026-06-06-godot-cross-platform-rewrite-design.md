# Design: Godot 4 Cross-Platform Rewrite

**Date**: 2026-06-06  
**Status**: Approved (brainstorming)  
**Replaces**: Phaser 3 + Vite web-only stack (retained as reference until parity)

## Goal

Rewrite the Blackjack Card Counting Tutorial Game in **Godot 4 + GDScript** so one
codebase ships as a **free educational game** on:

1. **Steam** (v1 — Windows x64 primary)
2. **Web** (HTML5 export — free browser tutorial)
3. **iOS** (touch layout — post-Steam)

## Decisions (Brainstorming)

| Question | Answer |
|----------|--------|
| Primary motivation | Full commercial-quality multi-platform rewrite (distribution, 3D, native features) |
| Language | Neutral on TypeScript — best engine wins |
| v1 launch platform | Steam (desktop) |
| Monetization | Free everywhere — educational positioning |
| Engine | **Godot 4 + GDScript** |

## Architecture Overview

**Pattern:** Domain logic (pure GDScript) + presentation (Godot scenes) + GameController bridge.

```text
┌─────────────────────────────────────────────────────────┐
│  Godot Scenes (2D UI shell + 3D table)                  │
│  Home · Setup · Tutorial · Table3D · AnalyticsOverlay   │
└───────────────────────┬─────────────────────────────────┘
                        │ signals / method calls
┌───────────────────────▼─────────────────────────────────┐
│  GameController (autoload singleton)                    │
│  Orchestrates session, emits typed events               │
└───────────────────────┬─────────────────────────────────┘
                        │ pure function calls
┌───────────────────────▼─────────────────────────────────┐
│  scripts/domain/  — blackjack, counting, bets, etc.     │
│  scripts/lib/     — rng, events, motion_preference      │
│  scripts/persistence/ — profile, hand snapshot          │
└─────────────────────────────────────────────────────────┘
```

### Invariants (carried from constitution)

- Domain scripts MUST NOT import Godot scene nodes or extend `Node`
- Scenes MUST NOT mutate session state directly — all changes go through `GameController`
- `GameController` emits the same event vocabulary as the Phaser version:
  `count:updated`, `hand:settled`, `stay:assessed`, `player:joined`, `player:left`,
  `shoe:reshuffled`, `coaching:message`

### Repository layout

- New Godot project at `godot/` subdirectory
- Existing Phaser `src/` and `tests/` remain as reference until feature parity
- After parity: archive Phaser code (do not delete until GUT suite covers all user stories)

## Project Structure

```text
godot/
├── project.godot
├── export_presets.cfg          # Steam (Win), Web, iOS templates
├── scenes/
│   ├── boot.tscn
│   ├── home.tscn               # 2D Control — mode select
│   ├── setup.tscn              # 2D — table config
│   ├── tutorial.tscn           # 2D — lesson picker + coaching panels
│   ├── table/
│   │   ├── table_3d.tscn       # 3D SubViewport — felt, cards, dogs, chips
│   │   └── sidebar.tscn        # 2D Mix-2 sidebar (instanced on table scene)
│   └── analytics_overlay.tscn  # 2D drawer — balance/advantage charts
├── scripts/
│   ├── domain/
│   │   ├── card.gd
│   │   ├── deck.gd
│   │   ├── shoe.gd
│   │   ├── hand.gd
│   │   ├── blackjack.gd
│   │   ├── counting.gd
│   │   ├── bet_models.gd
│   │   ├── bet_sizing.gd
│   │   ├── advantage.gd
│   │   ├── stay_or_leave.gd
│   │   ├── strategy.gd
│   │   ├── table_dynamics.gd
│   │   ├── table_config.gd
│   │   ├── session.gd
│   │   ├── mode_routing.gd
│   │   └── tutorial.gd
│   ├── game/
│   │   ├── game_controller.gd
│   │   ├── audio_manager.gd
│   │   └── scene_router.gd
│   ├── persistence/
│   │   ├── learner_profile.gd
│   │   └── hand_snapshot.gd
│   ├── tutorial/
│   │   ├── lessons.gd
│   │   └── coaching_copy.gd
│   ├── ui/
│   │   └── charts.gd
│   └── lib/
│       ├── rng.gd
│       ├── events.gd
│       └── motion_preference.gd
├── assets/
│   ├── models/                 # Low-poly 3D: table, cards, chips, dogs, shoe
│   ├── ui/                     # 2D kit: panels, buttons, stat blocks
│   └── audio/                  # Cozy instrumental BGM + SFX
└── tests/
    └── unit/                   # GUT tests mirroring tests/unit/*.test.ts
```

**Godot version:** 4.4+ stable, Forward+ renderer for 3D table scene.

## Domain Port & GameController

### Port strategy

Mechanical translation TypeScript → GDScript, preserving public APIs in
`specs/001-card-counter-tutorial/contracts/domain-modules.md`. Existing Vitest
tests are the acceptance specification; each gets a GUT equivalent written first
(red phase).

| TypeScript source | GDScript target | Notes |
|-------------------|-----------------|-------|
| `src/lib/rng.ts` | `scripts/lib/rng.gd` | Seedable `RandomNumberGenerator` wrapper |
| `src/domain/*.ts` | `scripts/domain/*.gd` | One file per module; `blackjack.gd` is largest |
| `src/persistence/*.ts` | `scripts/persistence/*.gd` | JSON via `user://card-counter/` |
| `src/game/controllers/GameController.ts` | `scripts/game/game_controller.gd` | Autoload singleton |

### Data model

GDScript typed dictionaries or `class_name` resources matching existing types:
`SessionState`, `LearnerProfile`, `HandSnapshot`, `CountState`, `TableConfiguration`.
Prefer immutable-style returns (new copies) to match current TypeScript patterns.

### Persistence

- **Schema:** Unchanged — `specs/001-card-counter-tutorial/contracts/persistence-schema.json` v1
- **Paths:** `user://card-counter/learner-profile.json`, `user://card-counter/hand-snapshot.json`
- **Platform mapping:**
  - Steam/desktop: OS app data via Godot `user://`
  - Web: IndexedDB-backed `user://`
  - iOS: App sandbox `user://`
- **Schema mismatch:** Default profile + user notice (same behavior as Phaser version)

## Presentation (002 Visual Spec)

Implements `specs/002-2-5d-visual-audio/spec.md` visual direction.

| Screen | Rendering | Implementation |
|--------|-----------|----------------|
| Home, Setup, Tutorial, sidebar, analytics | 2D UI shell (Mix-2 style) | `Control` nodes, shared `Theme` / `ui_kit.tres` |
| Table play area | Low-poly 3D | `SubViewport` + `Camera3D`; cards as thin meshes with face textures |
| Action buttons | 2D over 3D | `CanvasLayer` sibling to 3D viewport |
| Narrow viewport | Stacked layout | Sidebar moves above table via container size flags |
| Audio | Cozy life-sim palette | `AudioStreamPlayer`; mute persisted in profile |

### Table 3D scene

- Felt table mesh, dealer shoe stack, chip stacks (instanced meshes)
- Low-poly dog characters at 0–5 seats
- Card dealing via `Tween3D` / `AnimationPlayer`
- Crowded-table legibility: auto-fan per seat, hover/focus zoom via raycast + camera lerp
- Reduced motion: `motion_preference.gd` zeroes tween durations; instant card placement

### Analytics

- Balance and advantage charts open from sidebar button (overlay/drawer)
- Custom `Control._draw()` line charts (replaces Chart.js dependency)
- Same data series as Phaser `AnalyticsOverlay`

## Testing Strategy

Constitution TDD adapts to Godot. Four layers become three plus export smoke
(Playwright replaced by Godot-native testing).

| Layer | Tool | Scope |
|-------|------|-------|
| Unit | [GUT](https://github.com/bitwes/Gut) | All `scripts/domain/` and `scripts/lib/` |
| Functional | GUT | Multi-module flows (session lifecycle, bet coaching, mode routing) |
| Integration | GUT + scene harness | `GameController` → signal emission, scene transitions |
| Export smoke | CLI | `godot --headless --path godot -s tests/run_smoke.gd` |

### Test mapping (user stories)

Each user story from `specs/001-card-counter-tutorial/spec.md` (US0–US4) MUST have
GUT coverage equivalent to the existing Vitest/Playwright files listed in `tasks.md`
before the story is considered done.

### Constitution update required

Before implementation begins, update `.specify/memory/constitution.md`:

- Replace **Phaser-First Game Architecture** → **Godot-First Game Architecture**
- Replace Playwright e2e layer → **export smoke / scene integration**
- Update **Educational Clarity & Accessible Web** → **Educational Clarity & Accessible Multi-Platform**
  (keyboard on desktop, touch on iOS, reduced-motion on all targets)

## Platform Rollout

| Phase | Target | Deliverable |
|-------|--------|-------------|
| 1 | Dev | Godot scaffold, domain port, GUT unit tests green |
| 2 | Dev | 2D UI shell: Home, Setup, Tutorial |
| 3 | Dev | 3D table scene, sidebar, audio, analytics overlay |
| 4 | **Steam v1** | Windows x64 export; Linux/Mac if low effort |
| 5 | Web | HTML5 export to `dist/web/` |
| 6 | iOS | Touch stacked layout, Xcode export, App Store (free) |

### Steam packaging

- `export_presets.cfg` for Windows x64 (primary)
- Store positioning: educational card-counting tutorial; no real-money gambling
- GodotSteam plugin deferred (achievements/cloud saves not required for v1)

### Web export caveats

- Larger initial download than Vite build (~15–30 MB acceptable for free tutorial)
- Mid-session tab-close recovery: simplified prompt or omitted on web (document in spec)
- Threading limitations in HTML5 export — keep domain logic single-threaded

### iOS export requirements

- Mac with Xcode for export and App Store submission
- Stacked sidebar layout from 002 spec (touch-first)
- App Store category: Education or Games/Educational; free, no IAP

## Feature Parity Checklist

Godot rewrite MUST match Phaser implementation for:

- [ ] Dual mode: Tutorial and Free Play (no gating)
- [ ] Five tutorial lessons with step-by-step coaching
- [ ] Table config: 1–6 decks, 0–5 other players, hands-before-reshuffle
- [ ] Full blackjack hand flow: hit, stand, double, split, insurance
- [ ] Hi-Lo running count and true count
- [ ] Three bet models with coaching (spread-table, flat-ramp, wonging)
- [ ] Balance/advantage analytics graphs
- [ ] Stay-or-leave coaching (composite score, table dynamics)
- [ ] Bankroll persistence across sessions
- [ ] Mid-hand forfeit/resume prompt (desktop; simplified on web)
- [ ] Sound effects per action + instrumental BGM (mutable)
- [ ] Reduced-motion support

## Out of Scope (v1)

- Real-money gambling integration
- Additional counting systems beyond Hi-Lo
- GodotSteam achievements/cloud saves
- Android export
- Multiplayer

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| GDScript port introduces rule bugs | GUT tests written from Vitest specs before porting each module |
| 3D art scope creep | Phase 2 ships 2D placeholder table; Phase 3 replaces with low-poly assets |
| Web export performance | Profile early; reduce 3D poly count; optional 2D fallback export preset |
| Constitution still references Phaser | Update constitution in Phase 1 setup task before any domain code |

## Next Step

Invoke **writing-plans** skill to produce `specs/003-godot-rewrite/plan.md` with
phased tasks, TDD mapping, and export configuration steps.
