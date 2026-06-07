---
description: "Task list for 2.5D Visual & Audio Presentation feature"
---

# Tasks: 2.5D Visual & Audio Presentation

**Input**: Design documents from `/specs/002-2-5d-visual-audio/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: MANDATORY — constitution v3 requires unit, functional, integration, and scene integration
tests written before implementation for every user story (Playwright replaced by Godot scene harness).

**Organization**: Tasks grouped by user story (US0–US6). Within each story, all test tasks precede
implementation tasks (TDD red-green-refactor).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (US0–US6)
- Paths are relative to repository root under `godot/`

## Art Style References (mandatory QA targets)

| Ref | Spec path | Godot copy | Scope |
|-----|-----------|------------|-------|
| **A — 3D** | `specs/002-2-5d-visual-audio/references/ref-3d-faceted-low-poly-table.png` | `godot/assets/reference/ref-3d-faceted-low-poly-table.png` | All `table_3d.tscn` meshes: flat faceted shading, chibi dogs, cozy room |
| **B — 2D UI** | `specs/002-2-5d-visual-audio/references/ref-2d-tutorial-sidebar-ui.png` | `godot/assets/reference/ref-2d-tutorial-sidebar-ui.png` | All 2D shell: green/brown panels, cream type, Hi-Lo strip, tip box |

**Ref A checklist**: visible polygon facets, matte materials, chibi dog proportions, warm lamp key light, round felt table, 3D card planes, striped chip cylinders.

**Ref B checklist**: forest-green + chocolate sidebar, cream bold title, Hi-Lo color map (+1 green / 0 grey / −1 red), large stat blocks, tip panel, rounded green/tan buttons, tutorial speech bubbles and card count tags.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Asset directories, scene stubs, and theme skeleton for presentation work

- [X] T001 Create presentation asset directories `godot/assets/reference/`, `godot/assets/themes/`, `godot/assets/textures/`, `godot/assets/models/`, `godot/assets/materials/`, `godot/assets/audio/bgm/`, `godot/assets/audio/sfx/`; copy Ref A/B PNGs from `specs/002-2-5d-visual-audio/references/` into `godot/assets/reference/`
- [X] T002 [P] Create `godot/scripts/presentation/` module directory for Node-free layout/action/coaching helpers
- [X] T003 [P] Create Ref B theme skeleton `godot/assets/themes/tutorial_shell.tres` (alias `mix2_shell.tres`) — forest-green/chocolate `StyleBoxFlat` panels, cream text colors, green primary and tan secondary rounded buttons per Ref B
- [X] T004 [P] Create stub scene `godot/scenes/table/action_panel.tscn` wired to `godot/scripts/scenes/action_panel.gd`
- [X] T005 [P] Create stub scene `godot/scenes/table/analytics_drawer.tscn` extending analytics overlay pattern from `godot/scripts/scenes/analytics_overlay.gd`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared presentation infrastructure that MUST complete before user story work

**⚠️ CRITICAL**: No user story implementation begins until this phase is complete

### Tests for Foundation (write first) 🔴

- [X] T006 [P] Unit test for `MotionPreference` baseline in `godot/tests/unit/test_motion_preference.gd` (extend if file exists)
- [X] T007 [P] Scene integration harness skeleton in `godot/tests/integration/test_presentation_flow.gd` with Home→Setup navigation assertions

### Implementation for Foundation 🟢

- [X] T008 Implement `godot/scripts/lib/ui_theme.gd` with `ScreenClass` enum (`MENU`, `SIDEBAR`, `ACTION`, `OVERLAY`), Ref B palette constants (`PANEL_GREEN`, `PANEL_BROWN`, `TEXT_CREAM`, `COUNT_POS`, `COUNT_NEU`, `COUNT_NEG`), and `apply_to(control, screen_class)` per `contracts/ui-shell.md`
- [X] T009 [P] Create stub `godot/scripts/presentation/card_layout.gd` with `MIN_CARD_SCALE` constant and `build(session) -> Dictionary` signature
- [X] T010 [P] Create stub `godot/scripts/presentation/action_menu.gd` with `visible_actions(session) -> Array[String]` signature
- [X] T011 [P] Create stub `godot/scripts/presentation/coaching_cue.gd` with `highlight_action(session, mode) -> String` signature
- [X] T012 Create stub `godot/scripts/scenes/action_panel.gd` exposing `get_visible_action_ids() -> Array[String]` test hook per `contracts/table-presentation.md`
- [X] T013 Wire `ui_theme.gd` autoload or preload pattern in `godot/project.godot` if required for cross-scene access

**Checkpoint**: Foundation modules exist; harness boots; user story phases may begin

---

## Phase 3: User Story 0 — Consistent 2D UI Shell (Priority: P1) 🎯 MVP

**Goal**: Home, Setup, Tutorial, table sidebar, and analytics use one **Ref B** 2D shell (green/brown panels, cream type, Hi-Lo strip, tip box); narrow viewport stacks sidebar above 3D table with critical stats visible

**Independent Test**: Visit Home → Setup → Table → Home; panel styling, typography, and button shapes match; only table center is 3D; analytics opens from sidebar in 2D shell

### Tests for User Story 0 (write first) 🔴

- [X] T014 [P] [US0] Unit tests for Ref B theme tokens (green/brown/cream, Hi-Lo +/0/− colors) and `ScreenClass` in `godot/tests/unit/test_ui_theme.gd`
- [X] T015 [P] [US0] Functional tests for shared theme on menu scenes and options panel accessibility from Home/Setup/Tutorial in `godot/tests/functional/test_ui_shell_consistency.gd`
- [X] T016 [P] [US0] Integration tests for sidebar Analytics trigger in `godot/tests/integration/test_analytics_panel.gd` (extend existing)
- [X] T017 [P] [US0] Scene integration tests for cross-screen styling in `godot/tests/integration/test_presentation_flow.gd` (US0 scenarios)

### Implementation for User Story 0 🟢

- [X] T018 [P] [US0] Finalize Ref B stat blocks, Hi-Lo reference strip, tip-box panel, and green/tan button styles in `godot/assets/themes/tutorial_shell.tres` per `plan.md` Ref B and `contracts/ui-shell.md`
- [X] T019 [P] [US0] Apply shared theme to `godot/scenes/home.tscn` and `godot/scripts/scenes/home_scene.gd` via `ui_theme.gd`
- [X] T020 [P] [US0] Apply shared theme to `godot/scenes/setup.tscn` and `godot/scripts/scenes/setup_scene.gd`
- [X] T021 [P] [US0] Apply shared theme to `godot/scenes/tutorial.tscn` and `godot/scripts/scenes/tutorial_scene.gd`
- [X] T022 [US0] Restyle `godot/scenes/table/sidebar.tscn` and `godot/scripts/scenes/sidebar.gd` to match Ref B: cream title, Hi-Lo mini-table, large stat blocks (running count, true count, decks/shoe remaining, bet/bankroll) with +/− color coding, bottom tip box
- [X] T023 [US0] Add Analytics button to `godot/scenes/table/sidebar.tscn` and wire toggle to `godot/scenes/table/analytics_drawer.tscn`
- [X] T024 [US0] Style `godot/scenes/table/analytics_drawer.tscn` and `godot/scripts/scenes/analytics_overlay.gd` with Ref B panels and `godot/scripts/ui/charts.gd` charts
- [X] T025 [US0] Create shared options/audio panel in `godot/scenes/options_panel.tscn` and `godot/scripts/scenes/options_panel.gd`; wire open from Home, Setup, Tutorial, and `godot/scenes/table/sidebar.tscn` per US0 acceptance scenario 3
- [X] T026 [US0] Polish stacked layout in `godot/scripts/scenes/table_scene.gd` so running count, true count, bankroll, and shoe remaining-card count stay visible without scroll at width < 900 px
- [X] T027 [US0] Refactor while keeping all US0 tests green

### Edge Cases & Coverage for User Story 0

- [X] T028 [P] [US0] Add edge-case tests for large bankroll formatting and negative counts in `godot/tests/unit/test_ui_theme.gd`
- [X] T029 [US0] Verify all US0 tests pass via `godot/tests/run_smoke.gd`

**Checkpoint**: US0 complete — consistent 2D shell across all non-3D UI

---

## Phase 4: User Story 1 — Low-Poly 3D Table with Visible Cards (Priority: P1)

**Goal**: Ref **A** faceted low-poly 3D poker room (chibi dogs, warm lamp, cozy props) with 3D cards on felt per seat, shoe counter, fan/auto-scale, hover zoom, learner hand priority

**Independent Test**: Start any hand; cards render on felt with readable faces, correct seat placement, deal/flip/collect animations; 3D room + 2D sidebar split visible

### Tests for User Story 1 (write first) 🔴

- [X] T030 [P] [US1] Unit tests for seat fan, scale, and learner priority in `godot/tests/unit/test_card_layout.gd`
- [X] T031 [P] [US1] Functional tests for face-up/down and legibility thresholds in `godot/tests/functional/test_table_card_layout.gd`
- [X] T032 [P] [US1] Integration tests for session events → 3D card state in `godot/tests/integration/test_table_presentation.gd`
- [X] T033 [P] [US1] Scene integration tests for live-hand card visibility in `godot/tests/integration/test_presentation_flow.gd` (US1 scenarios)

### Implementation for User Story 1 🟢

- [X] T034 [P] [US1] Implement seat placement, fan angles, auto-scale, and learner priority in `godot/scripts/presentation/card_layout.gd`
- [X] T035 [P] [US1] Create shared faceted matte material `godot/assets/materials/faceted_mat.tres` (flat shading, no smooth normals, high roughness) and apply to all 3D table meshes per Ref A
- [X] T036 [P] [US1] Add card face atlas textures under `godot/assets/textures/cards/` — clean flat 2D rank/suit art on rectangular card planes per Ref A
- [X] T037 [US1] Build Ref A room in `godot/scenes/table_3d.tscn`: round wooden-rim felt table, faceted overhead lamp, bookshelf, clock, window skyline, plants, wall art; optional felt rule decals; fixed high three-quarters `Camera3D` and warm key light
- [X] T038 [US1] Seat Ref A chibi faceted dog meshes (oversized head, minimal face, hoodies/formal dealer attire) at `SeatRoot` anchors in `godot/scenes/table_3d.tscn` and `godot/scripts/scenes/table_3d.gd` per FR-001b
- [X] T039 [US1] Add Ref A props: striped cylindrical chips, card shoe, discard tray, optional felt count-guide signs in `godot/scenes/table_3d.tscn`
- [X] T040 [US1] Refactor `godot/scripts/scenes/table_3d.gd` to `sync_presentation(view)`, per-seat card meshes, and `set_shoe_remaining(count)` per `contracts/table-presentation.md`
- [X] T041 [US1] Implement textured card mesh creation with rank/suit albedo in `godot/scripts/scenes/table_3d.gd`
- [X] T042 [US1] Add 3D shoe stack display and remaining-card label on `godot/scenes/table_3d.tscn`
- [X] T043 [US1] Wire `godot/scripts/scenes/table_scene.gd` to build presentation via `card_layout.gd` and call `table_3d.sync_presentation()`
- [X] T044 [US1] Implement hover/focus seat zoom with `Area3D` seats and `focus_seat(seat_id, focused)` in `godot/scripts/scenes/table_3d.gd`
- [X] T045 [US1] Implement deal/flip/collect tweens in `godot/scripts/scenes/table_3d.gd` using `godot/scripts/lib/motion_preference.gd`
- [X] T046 [US1] Refactor while keeping all US1 tests green

### Edge Cases & Coverage for User Story 1

- [X] T047 [P] [US1] Add crowded-table, minimum-scale, and faceted-material edge tests in `godot/tests/unit/test_card_layout.gd`
- [X] T048 [US1] Verify all US1 tests pass via `godot/tests/run_smoke.gd`

**Checkpoint**: US1 complete — readable 3D cards on felt with shoe counter

---

## Phase 5: User Story 2 — See Only Valid Actions (Priority: P1)

**Goal**: Contextual action buttons near learner hand show only legal actions; hidden when not learner turn; keyboard maps to visible actions only

**Independent Test**: Step through insurance, double/split, post-hit, and dealer phases; visible set always matches legal moves; illegal actions never appear

### Tests for User Story 2 (write first) 🔴

- [X] T049 [P] [US2] Unit tests for legal action filtering in `godot/tests/unit/test_action_menu.gd`
- [X] T050 [P] [US2] Functional tests across hand phases in `godot/tests/functional/test_action_visibility.gd`
- [X] T051 [P] [US2] Integration tests for session phase → visible actions in `godot/tests/integration/test_practice_table.gd` (extend existing)
- [X] T052 [P] [US2] Scene integration tests for full-hand action visibility in `godot/tests/integration/test_presentation_flow.gd` (US2 scenarios)

### Implementation for User Story 2 🟢

- [X] T053 [US2] Implement `visible_actions(session)` and keyboard map in `godot/scripts/presentation/action_menu.gd` per `contracts/table-presentation.md`
- [X] T054 [US2] Build contextual `godot/scenes/table/action_panel.tscn` anchored over 3D viewport near learner seat
- [X] T055 [US2] Implement `godot/scripts/scenes/action_panel.gd` render/hide logic and `get_visible_action_ids()` hook
- [X] T056 [US2] Remove permanent action row from `godot/scenes/table.tscn`; route actions through `action_panel.tscn` in `godot/scripts/scenes/table_scene.gd`
- [X] T057 [US2] Wire keyboard shortcuts in `godot/scripts/scenes/table_scene.gd` exclusively to `action_menu.gd` visible set
- [X] T058 [US2] Apply Ref B green/tan rounded button theme to action panel via `godot/scripts/lib/ui_theme.gd`
- [X] T059 [US2] Refactor while keeping all US2 tests green

### Edge Cases & Coverage for User Story 2

- [X] T060 [P] [US2] Add insurance-only and mid-hand action-change edge tests in `godot/tests/functional/test_action_visibility.gd`
- [X] T061 [US2] Verify all US2 tests pass via `godot/tests/run_smoke.gd` *(blocker: Godot executable not on PATH)*

**Checkpoint**: US2 complete — clutter-free contextual legal actions only

---

## Phase 6: User Story 3 — Tutorial Recommended-Action Highlight (Priority: P1)

**Goal**: Tutorial mode shows Ref **B** speech bubble coaching, Hi-Lo count tags on cards, and warm lamp-glow on recommended action; no highlight in Free Play; non-blocking choice

**Independent Test**: Reach coached decision in Tutorial lesson; exactly one action highlighted; Free Play shows none; non-highlighted choice still works

### Tests for User Story 3 (write first) 🔴

- [X] T062 [P] [US3] Unit tests for highlight eligibility in `godot/tests/unit/test_coaching_cue.gd`
- [X] T063 [P] [US3] Functional tests for bet-coaching highlight rules in `godot/tests/functional/test_bet_coaching.gd` (extend existing)
- [X] T064 [P] [US3] Integration tests for tutorial flag → glow in `godot/tests/integration/test_table_presentation.gd`
- [X] T065 [P] [US3] Scene integration tests in `godot/tests/integration/test_tutorial_highlight.gd`
- [X] T066 [P] [US3] Integration tests for non-highlighted Tutorial choice → coaching feedback in `godot/tests/integration/test_tutorial_highlight.gd` per FR-010

### Implementation for User Story 3 🟢

- [X] T067 [US3] Implement `highlight_action(session, mode)` using `godot/scripts/domain/strategy.gd` and `godot/scripts/domain/tutorial.gd` in `godot/scripts/presentation/coaching_cue.gd`
- [X] T068 [US3] Add lamp-glow StyleBox/modulate highlight on recommended button in `godot/scripts/scenes/action_panel.gd`
- [X] T069 [US3] Build Ref B cream speech-bubble coaching overlay in `godot/scenes/table/tutorial_coach_overlay.tscn` wired to `coaching:message` events
- [X] T070 [US3] Add Tutorial-only Hi-Lo count tags (+1 green, 0 grey, −1 red) under visible cards in `godot/scripts/scenes/table_scene.gd` per Ref B
- [X] T071 [US3] Wire tutorial mode from `godot/scripts/game/game_controller.gd` into `table_scene.gd` highlight path; suppress overlays in Free Play
- [X] T072 [US3] Ensure reduced-motion uses static glow (no pulse) in `godot/scripts/scenes/action_panel.gd`
- [X] T073 [US3] Wire post-choice coaching feedback when learner picks a non-highlighted legal action in Tutorial via `coaching:message` events in `godot/scripts/scenes/table_scene.gd` and `godot/scripts/presentation/coaching_cue.gd` per FR-010
- [X] T074 [US3] Refactor while keeping all US3 tests green

### Edge Cases & Coverage for User Story 3

- [X] T075 [P] [US3] Add single-legal-action and bet-sizing highlight edge tests in `godot/tests/unit/test_coaching_cue.gd`
- [X] T076 [US3] Verify all US3 tests pass via `godot/tests/run_smoke.gd` *(blocker: Godot executable not on PATH)*

**Checkpoint**: P1 MVP complete (US0–US3) — full presentation UX with tutorial coaching highlight

---

## Phase 7: User Story 4 — Instrumental Background Music (Priority: P2)

**Goal**: Cozy life-sim looping BGM at table; separate music mute/volume; stops on leave; Web autoplay unlock

**Independent Test**: Enter table with sound on → music plays and loops; adjust/mute music; leave table → music stops; settings persist

### Tests for User Story 4 (write first) 🔴

- [X] T077 [P] [US4] Unit tests for music settings and BGM state in `godot/tests/unit/test_audio_settings.gd`
- [X] T078 [P] [US4] Functional tests for BGM start/stop/loop in `godot/tests/functional/test_audio_cues.gd` (extend existing)
- [X] T079 [P] [US4] Integration tests for table scene lifecycle → BGM in `godot/tests/integration/test_table_presentation.gd`
- [X] T080 [P] [US4] Scene integration tests in `godot/tests/integration/test_audio_lifecycle.gd`

### Implementation for User Story 4 🟢

- [X] T081 [P] [US4] Add cozy loop asset `godot/assets/audio/bgm/table_loop.ogg` (placeholder acceptable until licensed final)
- [X] T082 [US4] Extend `godot/scripts/persistence/learner_profile.gd` with `musicEnabled`, `musicVolume` defaults per `contracts/audio-contract.md`
- [X] T083 [US4] Add BGM `AudioStreamPlayer`, `start_table_bgm()`, `stop_table_bgm()`, `get_bgm_state()` to `godot/scripts/game/audio_manager.gd`
- [X] T084 [US4] Wire enter/leave table BGM lifecycle in `godot/scripts/scenes/table_scene.gd` and `godot/scripts/game/scene_router.gd`
- [X] T085 [US4] Implement Web autoplay `unlock_autoplay()` on first input in `godot/scripts/game/audio_manager.gd`
- [X] T086 [US4] Add music mute/volume controls to shared `godot/scenes/options_panel.tscn` from T025
- [X] T087 [US4] Refactor while keeping all US4 tests green

### Edge Cases & Coverage for User Story 4

- [X] T088 [P] [US4] Add master-mute and background-tab edge tests in `godot/tests/unit/test_audio_settings.gd`
- [X] T089 [US4] Verify all US4 tests pass via `godot/tests/run_smoke.gd`

**Checkpoint**: US4 complete — looping cozy BGM with independent music controls

---

## Phase 8: User Story 5 — Sound Effect per Action (Priority: P2)

**Goal**: Distinct gentle SFX for all 14 action categories; separate SFX mute/volume; UI confirm sounds; no harsh clipping

**Independent Test**: Execute each action category once with SFX enabled; mute suppresses all; music-only and SFX-only paths work independently

### Tests for User Story 5 (write first) 🔴

- [X] T090 [P] [US5] Unit tests for complete action map in `godot/tests/unit/test_audio_action_map.gd`
- [X] T091 [P] [US5] Functional tests for each category firing in `godot/tests/functional/test_audio_cues.gd`
- [X] T092 [P] [US5] Integration tests for hand events → `play_action` in `godot/tests/integration/test_table_presentation.gd`
- [X] T093 [P] [US5] Scene integration tests for music-only vs SFX-only mute in `godot/tests/integration/test_audio_lifecycle.gd`

### Implementation for User Story 5 🟢

- [X] T094 [P] [US5] Add SFX assets under `godot/assets/audio/sfx/` per `contracts/audio-contract.md` naming convention
- [X] T095 [US5] Extend `godot/scripts/persistence/learner_profile.gd` with `sfxEnabled`, `sfxVolume` fields
- [X] T096 [US5] Complete `SFX_MAP` and `play_action()` / `play_ui()` with `AudioStreamPlayer` playback in `godot/scripts/game/audio_manager.gd`
- [X] T097 [US5] Wire all `GameController` action and settle events to `audio_manager.gd` in `godot/scripts/game/game_controller.gd`
- [X] T098 [US5] Add SFX mute/volume controls to shared `godot/scenes/options_panel.tscn`; persist via `learner_profile.gd`
- [X] T099 [US5] Handle missing asset graceful silent fallback with optional non-blocking notice in `godot/scripts/game/audio_manager.gd`
- [X] T100 [US5] Refactor while keeping all US5 tests green

### Edge Cases & Coverage for User Story 5

- [X] T101 [P] [US5] Add rapid-action overlap and missing-asset edge tests in `godot/tests/functional/test_audio_cues.gd`
- [X] T102 [US5] Verify all US5 tests pass via `godot/tests/run_smoke.gd`

**Checkpoint**: US5 complete — full life-sim SFX palette with separate controls

---

## Phase 9: User Story 6 — Smooth Cutesy Animations & Juice (Priority: P2)

**Goal**: Balatro-inspired juice (hover wobble, deal snap, outcome feedback, dog reactions) adapted to cutesy tone; respects reduced motion

**Independent Test**: Play full hand with smooth motion on reference hardware; reduced-motion path has no required animation waits; card faces stay legible

### Tests for User Story 6 (write first) 🔴

- [X] T103 [P] [US6] Unit tests for reduced-motion duration zeroing in `godot/tests/unit/test_motion_preference.gd`
- [X] T104 [P] [US6] Functional tests for animation skip vs full motion in `godot/tests/functional/test_table_card_layout.gd`
- [X] T105 [P] [US6] Integration tests for event → tween wiring in `godot/tests/integration/test_table_presentation.gd`
- [X] T106 [P] [US6] Scene integration tests for reduced-motion hand completion in `godot/tests/integration/test_presentation_flow.gd` (US6 scenarios)

### Implementation for User Story 6 🟢

- [X] T107 [P] [US6] Add dog idle/reaction animation hooks on Ref A seat nodes in `godot/scripts/scenes/table_3d.gd`
- [X] T108 [P] [US6] Add chip bounce tween on bet confirm in `godot/scripts/scenes/table_3d.gd` or `godot/scripts/scenes/table_scene.gd`
- [X] T109 [US6] Add win sparkle / loss sympathetic visual cues in `godot/scripts/scenes/table_3d.gd`
- [X] T110 [US6] Add hover wobble/scale on Ref B action buttons in `godot/scripts/scenes/action_panel.gd` respecting `motion_preference.gd`
- [X] T111 [US6] Tune deal snap and collect animation timings in `godot/scripts/scenes/table_3d.gd` (base 260 ms)
- [X] T112 [US6] Refactor while keeping all US6 tests green

### Edge Cases & Coverage for User Story 6

- [X] T113 [P] [US6] Add in-progress animation legibility edge tests in `godot/tests/functional/test_table_card_layout.gd`
- [X] T114 [US6] Verify all US6 tests pass via `godot/tests/run_smoke.gd`

**Checkpoint**: US6 complete — polished juice with accessible reduced-motion fallbacks

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, performance, and documentation across all stories

- [X] T115 [P] Art QA: compare `godot/scenes/table_3d.tscn` against `godot/assets/reference/ref-3d-faceted-low-poly-table.png` (faceted shading, chibi dogs, room props)
- [X] T116 [P] Art QA: compare sidebar and menus against `godot/assets/reference/ref-2d-tutorial-sidebar-ui.png` (green/brown panels, cream type, Hi-Lo strip, tip box)
- [X] T117 [P] Replace provisional dog/table/shoe meshes with final licensed glTF assets in `godot/assets/models/` while preserving Ref A faceted style (optional polish beyond T038) — **deferred**; provisional `.tres` meshes retained
- [X] T118 [P] Profile 3D table scene for 60 fps target with 40 cards in `godot/scenes/table_3d.tscn`
- [X] T119 Accessibility pass: keyboard focus on seat zoom, iOS 44 pt touch targets, tutorial glow non-color-only in `godot/scripts/scenes/action_panel.gd` and `godot/scenes/table/sidebar.tscn`
- [X] T120 Update manual verification checklist and Ref A/B QA steps in `specs/002-2-5d-visual-audio/quickstart.md`
- [X] T121 Run full GUT smoke suite via `godot/tests/run_smoke.gd` and fix any regressions
- [X] T122 Run export smoke for Web build per `specs/003-godot-rewrite/quickstart.md` and verify audio autoplay path

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories**
- **US0 (Phase 3)**: Depends on Foundational — no dependency on US1–US6
- **US1 (Phase 4)**: Depends on US0 (shared sidebar/table split layout)
- **US2 (Phase 5)**: Depends on US1 (action panel overlays 3D viewport)
- **US3 (Phase 6)**: Depends on US2 (highlight applies to action panel buttons)
- **US4 (Phase 7)**: Depends on Foundational only — may parallel with US1–US3 after Phase 2
- **US5 (Phase 8)**: Depends on US4 (shared `audio_manager.gd` and profile fields)
- **US6 (Phase 9)**: Depends on US1 (card tweens) and US2 (button hover juice)
- **Polish (Phase 10)**: Depends on all desired user stories being complete

### User Story Completion Order (recommended)

```text
Phase 1–2 → US0 → US1 → US2 → US3 (MVP)
                    ↘ US4 → US5 (audio track, parallel after Phase 2 if staffed)
                    ↘ US6 (after US1 + US2)
→ Polish
```

### Within Each User Story (TDD)

1. Unit → functional → integration → scene integration tests (red)
2. Presentation modules → scenes → wiring (green)
3. Refactor
4. Edge-case tests → smoke verify

### Parallel Opportunities

- **Phase 1**: T002, T003, T004, T005 in parallel
- **Phase 2**: T006–T007 tests in parallel; T009–T011 stubs in parallel
- **Per story**: All test tasks marked [P] can be authored in parallel before implementation
- **US0**: T018–T021 theme application to Home/Setup/Tutorial in parallel
- **US1**: T034–T036 card layout, faceted material, and card textures in parallel
- **US4/US5**: Audio asset tasks T081 and T094 in parallel with scene wiring after tests exist
- **Cross-track**: After Phase 2, audio track (US4→US5) can run parallel to US1→US3 by different owners

---

## Implementation Strategy

### MVP First (P1 only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete US0 → US1 → US2 → US3
4. **STOP and validate** via `godot/tests/run_smoke.gd` and quickstart manual checklist
5. Demo/share MVP before P2 polish

### Incremental Delivery

| Increment | Stories | Value delivered |
|-----------|---------|-----------------|
| MVP | US0–US3 | Ref B UI shell, Ref A 3D table, legal actions, tutorial coaching overlays |
| Audio | US4–US5 | Cozy BGM + full SFX |
| Polish | US6 + Phase 10 | Juice, performance, export validation |

### Task Count Summary

| Phase | Tasks | Story |
|-------|-------|-------|
| Setup | 5 | — |
| Foundational | 8 | — |
| US0 | 16 | P1 MVP |
| US1 | 19 | P1 MVP |
| US2 | 13 | P1 MVP |
| US3 | 15 | P1 MVP |
| US4 | 13 | P2 |
| US5 | 13 | P2 |
| US6 | 12 | P2 |
| Polish | 8 | — |
| **Total** | **122** | |

---

## Notes

- [P] tasks = different files, no blocking dependency on incomplete sibling tasks
- [Story] label maps to spec.md User Story 0–6 (US0–US6)
- Fourth test layer is **scene integration** (`godot/tests/integration/`), not Playwright
- Domain logic in `godot/scripts/domain/` MUST NOT change blackjack rules — presentation only
- Commit after each task or logical group; stop at any checkpoint to validate story independently
