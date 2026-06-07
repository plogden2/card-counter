# Implementation Plan: 2.5D Visual & Audio Presentation

**Branch**: `002-2-5d-visual-audio` | **Date**: 2026-06-06 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-2-5d-visual-audio/spec.md`

## Summary

Upgrade the Godot card-counting tutorial with a **faceted low-poly 3D table scene** (Ref **A** — papercraft
chibi dogs, warm lamp-lit cozy room, 3D cards/chips/shoe) and a **tutorial sidebar 2D UI shell** (Ref **B** —
dark forest-green/chocolate panels, cream typography, Hi-Lo reference, color-coded count stats) across Home,
Setup, Tutorial, table sidebar, contextual actions, and analytics overlay. Add **filtered contextual actions**
(legal-only, near learner hand), **Tutorial recommended-action glow**, **cream speech-bubble coaching** and
**Hi-Lo count tags** on cards, **Animal Crossing / Stardew Valley-inspired** looping BGM and full per-action
SFX, and **Balatro-style juice** with reduced-motion fallbacks.

Builds on the Godot rewrite (`003-godot-rewrite`): domain logic stays in `godot/scripts/domain/`; presentation
lives in scenes, `table_3d.gd`, theme resources, and `AudioManager`. Strict **GUT TDD** (unit → functional →
integration → scene integration / export smoke) per constitution v3.

## Technical Context

**Language/Version**: GDScript, Godot 4.6+ (pinned in `godot/project.godot`)

**Primary Dependencies**: GUT 9.4 (testing), Forward+ renderer (3D table SubViewport), Godot `Theme` + `StyleBoxFlat`

**Storage**: `user://card-counter/learner-profile.json` — extend schema v1 with `musicVolume`, `sfxVolume` (optional
sub-controls alongside existing `soundEnabled` / `motionReduced`)

**Testing**: GUT unit + functional + integration; scene integration harness for presentation flows; export smoke
via `tests/run_smoke.gd` (replaces Playwright per constitution v3)

**Target Platform**: Steam Windows, Web HTML5, iOS — desktop/tablet primary; narrow viewport stacked layout

**Project Type**: Godot cross-platform educational card game (client-only presentation layer)

**Performance Goals**: 60 fps on 3D table scene with ≤ 40 animated cards; card deal tween < 300 ms; input response
< 100 ms p95

**Constraints**: Seedable RNG unchanged; `prefers-reduced-motion` via `MotionPreference` + profile flag; no
copyrighted asset reproduction; domain scripts MUST NOT extend `Node`; audio autoplay deferred until first gesture
on Web export

**Scale/Scope**: 6 user stories (US0–US6); 14 SFX categories + 1 BGM loop; 0–5 dog seats; responsive breakpoint
at 900 px width (existing)

**Visual references** (canonical targets for art QA):

| Ref | File | Applies to |
|-----|------|------------|
| **A — 3D table** | `specs/002-2-5d-visual-audio/references/ref-3d-faceted-low-poly-table.png` | All 3D models in `table_3d.tscn` |
| **B — 2D tutorial UI** | `specs/002-2-5d-visual-audio/references/ref-2d-tutorial-sidebar-ui.png` | All 2D UI shell scenes and overlays |

Copies for runtime/editor: `godot/assets/reference/` (same filenames).

## Visual Reference Targets

### Ref A — Faceted low-poly 3D (all table-scene models)

Every mesh in the 3D SubViewport MUST match the **papercraft / faceted** aesthetic of Ref A:

- **Shading**: Flat per-face shading — visible polygon facets; **no smooth shading**. Matte `StandardMaterial3D`
  (roughness ≈ 0.9, no specular highlights).
- **Characters**: Chibi anthropomorphic dogs — oversized heads, minimal black-dot eyes/noses, chunky limbs.
  Player dogs in colorful hoodies; dealer dog in white shirt + black vest + bowtie when present.
- **Environment**: Cozy nighttime poker room — round wooden-rim + green-felt blackjack table; warm overhead
  faceted lamp pool; wood furniture, bookshelf, analog clock, window with low-poly skyline, potted plants,
  framed wall art. Felt may show printed rule text (e.g. "BLACKJACK PAYS 3 TO 2").
- **Props**: Cylindrical striped poker chips, card shoe, discard tray, rectangular card planes with clean 2D
  face textures placed in 3D space, optional wooden "Count Guide" / point-total signs on felt.
- **Camera**: High three-quarters angle (~isometric with mild perspective); fixed for card legibility.
- **Lighting**: Single warm key from overhead lamp; soft blocky shadows; saturated earthy palette (browns,
  deep green felt, warm creams).

### Ref B — Tutorial sidebar 2D UI (all non-3D chrome)

Every 2D Control scene MUST match Ref B's **Card Counting Tutorial** panel language:

- **Panel**: Dark **forest green** and **chocolate brown** rounded vertical sidebar; cream/off-white (`#F5F0E1`)
  primary text on dark panels.
- **Title**: Bold cream sans-serif header ("CARD COUNTING TUTORIAL" or mode-appropriate variant).
- **Hi-Lo strip**: Compact reference table showing card groups (+1 green, 0 grey, −1 red) for learner glance.
- **Stats**: Large readable blocks — **RUNNING COUNT**, **TRUE COUNT**, **DECKS REMAINING** (or shoe cards
  left), **BET** / bankroll — color-coded signed values.
- **Tip box**: Bottom coaching panel with lightbulb icon and short lesson copy.
- **Buttons**: Large rounded rectangles — primary green (NEXT / confirm), secondary tan (MENU / HELP).
- **Tutorial overlays on table viewport**: Cream **speech bubbles** from coach character; small rounded
  **count tags** under each visible card (+1 green, −1 red, 0 grey) in Tutorial mode only.
- **Typography**: Clean bold sans-serif; stats chunky and high-contrast; no thin wireframe UI.

Ref B supersedes generic "Mix 2 sidebar" wording in older docs — same layout role, Ref B is the concrete palette.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Requirement | Status |
|------|-------------|--------|
| Spec-First | `spec.md` exists; this plan references it; stories map to acceptance scenarios | ✅ Pass |
| Comprehensive TDD | Each story lists unit, functional, integration, and scene integration tests to write first | ✅ Pass |
| Incremental Scope | User stories independently testable; P1 (US0–US3) before P2 audio/animation polish | ✅ Pass |
| Godot Architecture | Domain in `godot/scripts/domain/`; scenes/`table_3d`/`AudioManager` orchestrate only | ✅ Pass |
| Educational & Accessible Multi-Platform | Tutorial highlight non-blocking; keyboard + touch; reduced-motion; free educational product | ✅ Pass |

*Post-Phase 1 re-check (2026-06-06): All gates pass. Presentation contracts in `contracts/` define testable
scene boundaries; spec Playwright references mapped to Godot scene integration per constitution v3.*

## Current State vs Target

| Area | Current (`godot/`) | Target (this feature) |
|------|-------------------|----------------------|
| 3D table | BoxMesh placeholders, flat card grid | Ref **A** faceted room, chibi dogs, round felt, 3D cards/chips/shoe per seat |
| UI shell | Basic labels/buttons per scene | Ref **B** green/brown/cream `Theme` on Home, Setup, Tutorial, sidebar, actions |
| Actions | Permanent button row in table scene | Contextual 2D buttons near learner hand; hidden when illegal or not learner turn |
| Tutorial | Coaching text only | Ref **B** speech bubble + count tags; warm glow on recommended action |
| Audio | Partial `SFX_MAP` (5 cues), no playback | Full 14-category map, Ogg playback, looping BGM, separate music/SFX mute |
| Layout | Wide/stacked split at 900 px (done) | Retain; ensure critical stats visible without scroll in stacked mode |
| Analytics | `analytics_overlay.gd` toggle + `Charts` | Sidebar-triggered drawer; Mix 2 styling |

## Project Structure

### Documentation (this feature)

```text
specs/002-2-5d-visual-audio/
├── plan.md              # This file
├── research.md          # Phase 0 decisions
├── data-model.md        # Phase 1 presentation entities
├── quickstart.md        # Dev & test commands
├── contracts/           # UI, table, audio contracts
└── tasks.md             # Phase 2 (/speckit-tasks — not yet created)
```

### Source Code (repository root)

```text
godot/
├── assets/
│   ├── reference/       # ref-3d-faceted-low-poly-table.png, ref-2d-tutorial-sidebar-ui.png
│   ├── models/          # faceted low-poly: room, dogs, cards, shoe, chips (glTF or .tres)
│   ├── textures/        # card faces, felt decals, UI accents
│   ├── themes/          # tutorial_shell.tres — Ref B shared 2D theme (alias mix2_shell.tres)
│   ├── materials/       # faceted_mat.tres — flat-shaded matte preset for all 3D meshes
│   └── audio/
│       ├── bgm/         # cozy instrumental loop(s)
│       └── sfx/         # life-sim SFX library
├── scenes/
│   ├── home.tscn
│   ├── setup.tscn
│   ├── tutorial.tscn
│   ├── table.tscn
│   ├── table/
│   │   ├── sidebar.tscn
│   │   ├── action_panel.tscn   # contextual controls near learner
│   │   └── analytics_drawer.tscn
│   └── table_3d.tscn           # SubViewport 3D room
├── scripts/
│   ├── domain/          # unchanged rules; Strategy.recommend_action for highlight
│   ├── game/
│   │   ├── audio_manager.gd    # extend: playback, BGM, volumes
│   │   └── game_controller.gd
│   ├── lib/
│   │   ├── motion_preference.gd
│   │   └── ui_theme.gd         # screen classification, theme loader
│   ├── presentation/
│   │   ├── card_layout.gd      # fan, auto-scale, min size (domain-free)
│   │   ├── action_menu.gd      # legal action filter + keyboard map
│   │   └── coaching_cue.gd     # tutorial highlight eligibility
│   └── scenes/
│       ├── table_scene.gd
│       ├── table_3d.gd
│       ├── sidebar.gd
│       └── analytics_overlay.gd
└── tests/
    ├── unit/
    ├── functional/
    └── integration/
```

**Structure Decision**: Presentation helpers in `godot/scripts/presentation/` remain Node-free for GUT unit tests.
`table_3d.gd` and scene scripts wire SubViewport, theme, and audio only.

## TDD Strategy by User Story

Tests written **first** per story. Fourth layer = scene integration (spec "Playwright" rows adapted for Godot).

### US0 — Consistent 2D UI Shell (P1)

| Layer | Files | Key scenarios |
|-------|-------|---------------|
| Unit | `tests/unit/test_ui_theme.gd` | Ref B tokens (green/brown/cream), Hi-Lo color map, `ScreenClass` |
| Functional | `tests/functional/test_ui_shell_consistency.gd` | Home/Setup/Table sidebar share theme resource |
| Integration | `tests/integration/test_analytics_panel.gd` | Sidebar Analytics → overlay opens in 2D shell |
| Scene integration | `tests/integration/test_presentation_flow.gd` | Navigate Home → Setup → Table; panel styling match |

### US1 — Low-Poly 3D Table with Visible Cards (P1)

| Layer | Files | Key scenarios |
|-------|-------|---------------|
| Unit | `tests/unit/test_card_layout.gd` | Seat placement, fan angles, min scale; faceted material flag |
| Functional | `tests/functional/test_table_card_layout.gd` | Face-up/down rules, legibility thresholds |
| Integration | `tests/integration/test_table_presentation.gd` | Hand events → `table_3d` card count/positions |
| Scene integration | `tests/integration/test_presentation_flow.gd` | Cards visible on felt during live hand |

### US2 — Only Valid Actions (P1)

| Layer | Files | Key scenarios |
|-------|-------|---------------|
| Unit | `tests/unit/test_action_menu.gd`, `test_strategy.gd`, `test_hand.gd` | Legal set per phase; insurance-only |
| Functional | `tests/functional/test_action_visibility.gd` | Hidden vs visible across hand phases |
| Integration | `tests/integration/test_practice_table.gd` | Session phase → `ActionMenu.visible_actions` |
| Scene integration | `tests/integration/test_presentation_flow.gd` | Full hand: illegal actions never appear |

### US3 — Tutorial Recommended-Action Highlight (P1)

| Layer | Files | Key scenarios |
|-------|-------|---------------|
| Unit | `tests/unit/test_coaching_cue.gd`, `test_strategy.gd`, `test_tutorial.gd` | Highlight id per coached step |
| Functional | `tests/functional/test_bet_coaching.gd` | Bet coaching highlight eligibility |
| Integration | `tests/integration/test_table_presentation.gd` | Tutorial flag → glow on correct button |
| Scene integration | `tests/integration/test_tutorial_highlight.gd` | Highlight in lesson; absent in Free Play |

### US4 — Instrumental Background Music (P2)

| Layer | Files | Key scenarios |
|-------|-------|---------------|
| Unit | `tests/unit/test_audio_settings.gd` | Music mute/volume; BGM lifecycle state |
| Functional | `tests/functional/test_audio_cues.gd` | Start/stop on table enter/exit; loop seam |
| Integration | `tests/integration/test_table_presentation.gd` | SceneRouter table → AudioManager BGM |
| Scene integration | `tests/integration/test_audio_lifecycle.gd` | Leave table stops BGM; profile persists |

### US5 — Sound Effect per Action (P2)

| Layer | Files | Key scenarios |
|-------|-------|---------------|
| Unit | `tests/unit/test_audio_action_map.gd` | All 14 categories mapped |
| Functional | `tests/functional/test_audio_cues.gd` | Each action fires cue; mute suppresses |
| Integration | `tests/integration/test_table_presentation.gd` | Hand events → `play_action` |
| Scene integration | `tests/integration/test_audio_lifecycle.gd` | Music-only vs SFX-only mute paths |

### US6 — Cutesy Animations & Juice (P2)

| Layer | Files | Key scenarios |
|-------|-------|---------------|
| Unit | `tests/unit/test_motion_preference.gd` | Reduced-motion zero duration |
| Functional | `tests/functional/test_table_card_layout.gd` | Animation skip vs full motion |
| Integration | `tests/integration/test_table_presentation.gd` | Event → tween trigger wiring |
| Scene integration | `tests/integration/test_presentation_flow.gd` | Reduced-motion hand completes without waits |

## Implementation Phases

| Phase | Focus | Deliverable |
|-------|-------|-------------|
| 0 | Research + contracts | `research.md`, `contracts/*` (this plan run) |
| 1 | UI shell foundation | Ref **B** `tutorial_shell.tres`, Hi-Lo strip, tip box, apply to all 2D scenes |
| 2 | 3D table core | Ref **A** faceted room, chibi dogs, `faceted_mat.tres`, cards/chips/shoe |
| 3 | Actions + coaching | `action_panel`, `ActionMenu`, tutorial glow, speech bubble, count tags |
| 4 | Analytics + responsive | Styled drawer; stacked layout stat visibility |
| 5 | Audio | BGM loop, full SFX map, volume persistence |
| 6 | Juice + polish | Hover zoom, dog idle, chip bounce, button wobble |
| 7 | Test suite + smoke | All GUT layers green; export smoke passes |

**MVP (P1)**: Phases 1–4 (US0–US3). **P2 polish**: Phases 5–6 (US4–US6).

## Complexity Tracking

> No violations. Presentation logic stays out of domain; 3D is scoped to table SubViewport only.
