# Research: 2.5D Visual & Audio Presentation

**Feature**: `002-2-5d-visual-audio` | **Date**: 2026-06-06

## R-001: 3D table architecture

**Decision**: Keep **SubViewport + SubViewportContainer** (`table_3d.tscn`) embedded in `table.tscn`;
Forward+ renderer; fixed camera with slight downward tilt.

**Rationale**: Already scaffolded in the Godot rewrite. Isolates 3D render from 2D Control UI, simplifies
responsive layout (sidebar is sibling Control, not child of 3D root), and matches spec split (2D shell +
3D play area). Fixed camera preserves card legibility for counting practice.

**Alternatives considered**:
- **Full-scene Node3D root**: Breaks Mix 2 sidebar overlay; harder responsive stacking.
- **2D faux perspective**: Rejected in spec clarifications (Pure C low-poly 3D).
- **Separate 3D scene swap**: Loses simultaneous sidebar + table view.

## R-002: Low-poly asset pipeline

**Decision**: **glTF 2.0** imports for room, round table, dog characters, shoe; **procedural BoxMesh/CylinderMesh**
fallbacks remain until art pass; card mesh = thin box + **AlbedoTexture** per rank/suit atlas.

**Rationale**: Godot 4 native glTF import with LOD-friendly low-poly meshes. Atlas texture keeps draw calls low
for up to 40 cards. Placeholder boxes allow TDD of layout logic before final art.

**Alternatives considered**:
- **CSG-only room**: Faster blockout but poor polish ceiling.
- **Sprite3D cards**: Weaker perspective/shadow spec compliance.
- **External Blender-only pipeline without fallbacks**: Blocks parallel engineering.

## R-003: Shared 2D UI shell (Mix 2)

**Decision**: Single Godot **`Theme` resource** (`assets/themes/mix2_shell.tres`) with `StyleBoxFlat` dark panels,
accent stat blocks (ColorRect children or custom `PanelContainer` variants), rounded `Button` styles, and
**`ui_theme.gd`** helper exposing `ScreenClass` (`MENU`, `SIDEBAR`, `OVERLAY`, `ACTION`).

**Rationale**: Godot themes propagate to all Control nodes; one resource enforces FR-001c consistency across
Home, Setup, Tutorial, sidebar, analytics, and contextual actions. Matches existing `sidebar.tscn` pattern.

**Alternatives considered**:
- **Per-scene duplicate styles**: Violates SC-010 cross-screen consistency.
- **CanvasItem shader panels**: Harder to test and maintain than StyleBoxFlat.
- **External UI framework**: Unnecessary for Control-based menus.

## R-004: Card layout & legibility

**Decision**: Pure module **`card_layout.gd`** computes per-seat transforms: fan angle spread, scale factor from
card count, learner seat **1.0×** scale multiplier, **0.65× minimum scale** floor; `table_3d.gd` applies results.

**Rationale**: Layout math is testable without rendering. Spec FR-002c/d require auto-scale, priority sizing, and
hover zoom — layout module centralizes thresholds.

**Alternatives considered**:
- **Layout inside `table_3d.gd` only**: Harder unit testing.
- **Physics-based card pile**: Overkill; risks legibility.

## R-005: Hover / focus zoom

**Decision**: **3D scale tween** on focused seat's card group (1.35×) triggered by `Area3D` mouse hover and
parallel **keyboard focus** via seat tab order; instant snap when `motionReduced`.

**Rationale**: Spec requires hover and keyboard parity (edge case). Area3D per seat is lightweight; zoom is
presentational only — does not block action input on 2D overlay.

**Alternatives considered**:
- **2D magnifier overlay**: Breaks 3D depth illusion.
- **Click-to-zoom**: Extra friction vs spec Option A.

## R-006: Contextual action menu

**Decision**: Extract legal-action filtering to **`action_menu.gd`** (from existing `table_scene._get_legal_actions`);
new **`action_panel.tscn`** anchored over 3D viewport near learner seat screen projection; buttons use shared theme.

**Rationale**: Spec FR-005/005a require hidden illegal actions and Balatro-style placement. Domain already exposes
phase + hand state via `GameController.get_session()`.

**Alternatives considered**:
- **Disable instead of hide**: Explicitly rejected in spec.
- **Permanent sidebar action row**: Current implementation; does not meet spec.

## R-007: Tutorial recommended-action highlight

**Decision**: **`coaching_cue.gd`** returns `highlight_action_id` when `mode == tutorial` and `Strategy.recommend_action`
matches a visible legal action; `action_panel` applies warm **modulate + StyleBox glow** (non-pulsing under reduced motion).

**Rationale**: `Strategy.recommend_action` already exists; tutorial lessons define coached steps. Non-blocking glow
meets FR-008/010.

**Alternatives considered**:
- **Auto-select recommended action**: Violates learning intent.
- **Pulsing animation only**: Reduced-motion conflict; static glow suffices.

## R-008: Audio system

**Decision**: Extend **`AudioManager`** with two **`AudioStreamPlayer`** nodes (BGM + SFX bus); **Ogg Vorbis**
assets; `SFX_MAP` covering all FR-013 categories; separate `musicEnabled` / `sfxEnabled` (or volume 0–1) persisted
in profile; Web autoplay unlock on first `InputEvent`.

**Rationale**: Godot native audio works on Steam/Web/iOS exports. Existing `audio_manager.gd` maps 5 actions but
does not play streams — extend in place. Life-sim palette aligns with spec audio direction.

**Alternatives considered**:
- **FMOD/Wwise**: Licensing and export complexity unjustified.
- **Single master volume only**: Insufficient for FR-012 separate controls.

## R-009: Analytics overlay

**Decision**: Keep **`analytics_overlay.gd`** + `Charts`; restyle with Mix 2 theme; trigger from sidebar
**Analytics** button (not inline charts); `toggle()` preserves hand state.

**Rationale**: Integration test `test_analytics_panel.gd` already exists; spec FR-001d requires on-demand drawer.

**Alternatives considered**:
- **Inline sidebar charts**: Rejected in clarifications (Option B).
- **3D chart objects**: Out of scope; 2D overlay only.

## R-010: Test layer mapping (Playwright → Godot)

**Decision**: Map spec **Playwright** rows to **`tests/integration/` scene harness** tests that instantiate
scenes + `GameController` without full export; **export smoke** (`run_smoke.gd`) covers cross-scene boot path.

**Rationale**: Constitution v3 replaces Playwright with GUT + export smoke. Scene integration tests assert
presentation state via public scene methods (`get_last_requested_scene`, `is_overlay_visible`, etc.).

**Alternatives considered**:
- **Reintroduce Playwright for Godot Web**: Duplicate CI stack; constitution forbids.
- **Manual-only presentation QA**: Fails Comprehensive TDD gate.

## R-011: Responsive layout breakpoint

**Decision**: Retain **900 px** width breakpoint in `table_scene._apply_layout_for_width`; stacked mode pins
sidebar `SIZE_SHRINK_BEGIN` and ensures stat row uses compact horizontal tile layout.

**Rationale**: Already implemented; spec FR-001f/g align. Research confirms no change needed — polish stat row
for no-scroll visibility on 768 px tablet portrait.

**Alternatives considered**:
- **Drawer sidebar on narrow**: Rejected in clarifications (Option B stacked).
