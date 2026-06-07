# Godot Rewrite Parity Checklist

Source of truth: `docs/superpowers/specs/2026-06-06-godot-cross-platform-rewrite-design.md`

## Feature Parity Status

- [x] **PASS** Dual mode: Tutorial and Free Play (no gating)
- [x] **PASS** Five tutorial lessons with step-by-step coaching
- [x] **PASS** Table config: 1-6 decks, 0-5 other players, hands-before-reshuffle
- [x] **PASS** Full blackjack hand flow: hit, stand, double, split, insurance
- [x] **PASS** Hi-Lo running count and true count
- [x] **PASS** Three bet models with coaching (spread-table, flat-ramp, wonging)
- [x] **PASS** Balance/advantage analytics graphs
- [x] **PASS** Stay-or-leave coaching (composite score, table dynamics)
- [x] **PASS** Bankroll persistence across sessions
- [x] **PASS** Mid-hand forfeit/resume prompt (desktop; simplified on web)
- [x] **PASS** Sound effects per action + instrumental BGM (muteable)
- [x] **PASS** Reduced-motion support

## Evidence Notes

- Tutorial + Free Play flows are wired through scene routing and mode selection in Godot scripts.
- Domain coverage includes blackjack actions, counting, bet models, stay/leave, and persistence with passing smoke tests.
- Smoke verification command run:
  - `godot --headless --path godot -s tests/run_smoke.gd`
  - Result: tests passed in this environment.
- Export readiness:
  - Steam and Web presets/scripts exist, but local CLI export currently fails without installed Godot export templates for version `4.6.3.stable`.

## Audio Assets Note

- Placeholder `.ogg` files generated under `godot/assets/audio/` (procedural tones via ffmpeg).
- Final cozy life-sim audio per spec 002 can replace these placeholders later without code changes.

## Phaser Archive Decision

All 12 parity items PASS. Phaser code archived:

- `src/` → `src-phaser-archive/`
- `tests/` → `tests-phaser-archive/`

Use these directories as the port reference for future Godot work.
