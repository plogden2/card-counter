# Data Model: 2.5D Visual & Audio Presentation

**Feature**: `002-2-5d-visual-audio` | **Date**: 2026-06-06

Presentation-layer entities extend the core game model (`001` / `003`) without changing blackjack rules.

## Entity Relationship Overview

```text
LearnerProfile ── audio fields ──> AudioProfile (runtime)
GameController.session ──> TablePresentation (derived view)
TablePresentation ──< CardVisual[] per seat
ActionMenu <── session phase + hand state
TutorialCoachingCue <── TutorialLesson + Strategy
UIShell (Theme) ── applied to ──> all 2D screens
AnalyticsOverlay ──< SessionAnalytics[] (from controller)
```

## Entities

### UIShell

Shared 2D design system applied to non-3D UI.

| Field | Type | Rules |
|-------|------|-------|
| `themeResource` | `res://assets/themes/mix2_shell.tres` | Single source for all shells |
| `panelBgColor` | `Color` | Dark neutral (~#1a1a2e) |
| `accentBlocks` | `Dictionary` | Keys: `count`, `bankroll`, `bet`, `shoe` → saturated colors |
| `buttonRadius` | `int` | Rounded rect corners (px) |
| `typographyScale` | `Dictionary` | `heading`, `stat`, `body` font sizes |

**Validation**: `ui_theme.gd` classifies scenes; table 3D viewport MUST NOT receive this theme.

### TablePresentation

Derived snapshot for rendering; rebuilt on each session update.

| Field | Type | Rules |
|-------|------|-------|
| `seats` | `SeatView[]` | One per participant including learner |
| `dealerCards` | `CardVisual[]` | Face-up/down per rules |
| `shoeCardsRemaining` | `int` | From `session.shoe.cards.size()` |
| `phase` | `string` | Mirrors session phase |
| `layoutMode` | `'wide' \| 'stacked'` | From viewport width ≥ 900 px |
| `motionReduced` | `bool` | From profile + system preference |

### SeatView

| Field | Type | Rules |
|-------|------|-------|
| `seatId` | `string` | `learner`, `dealer`, `dog-{n}` |
| `isLearner` | `bool` | Learner gets scale priority 1.0× |
| `worldPosition` | `Vector3` | On felt arc |
| `cards` | `CardVisual[]` | Fan layout from `card_layout.gd` |
| `dogModelId` | `string?` | Cosmetic breed id |

### CardVisual

| Field | Type | Rules |
|-------|------|-------|
| `cardId` | `string` | Unique per instance |
| `rank` | `string` | From domain `Card` |
| `suit` | `string` | From domain `Card` |
| `faceUp` | `bool` | Hole card hidden until reveal |
| `seatId` | `string` | Owner seat |
| `position` | `Vector3` | World coords on felt |
| `rotation` | `Vector3` | Fan tilt |
| `scale` | `float` | ≥ `MIN_CARD_SCALE` (0.65) |
| `animationPhase` | `'idle' \| 'dealing' \| 'flipping' \| 'collecting'` | Drives tweens |

**Legibility**: At `scale == MIN_CARD_SCALE`, rank+suit readable at default camera FOV.

### ActionMenu

| Field | Type | Rules |
|-------|------|-------|
| `visibleActions` | `string[]` | Subset of legal ids; illegal MUST be absent |
| `keyboardMap` | `Dictionary` | Only keys for `visibleActions` |
| `anchorSeatId` | `string` | Always `learner` |
| `isLearnerTurn` | `bool` | If false, menu hidden entirely |

**Action ids**: `place-bet`, `deal`, `hit`, `stand`, `double`, `split`, `insurance-accept`,
`insurance-decline`, `continue`, `home`.

### TutorialCoachingCue

| Field | Type | Rules |
|-------|------|-------|
| `lessonId` | `string` | Active tutorial lesson |
| `stepIndex` | `int` | Current coached step |
| `highlightActionId` | `string?` | Set when coaching active and recommendation exists |
| `highlightStyle` | `'lamp-glow'` | Warm accent; non-pulsing if reduced motion |
| `feedbackCopy` | `string` | Post-choice coaching text |

**Rules**:
- Free Play: `highlightActionId` always `null` (FR-009).
- Single legal action + recommendation: still highlight (edge case).
- Bet sizing steps: highlight recommended bet tier per lesson script.

### AnalyticsOverlay

| Field | Type | Rules |
|-------|------|-------|
| `isOpen` | `bool` | Toggle independent of hand lifecycle |
| `balanceSeries` | `{handIndex, balance}[]` | From `Charts.balance_series` |
| `advantageSeries` | `{handIndex, advantage}[]` | From `Charts.advantage_series` |
| `triggerControl` | `string` | Sidebar `Analytics` button id |

### AudioProfile

Extends `LearnerProfile` audio fields; runtime state not persisted except preferences.

| Field | Type | Rules |
|-------|------|-------|
| `masterEnabled` | `bool` | Maps to `soundEnabled` |
| `musicEnabled` | `bool` | Default true |
| `sfxEnabled` | `bool` | Default true |
| `musicVolume` | `float` | 0.0–1.0; default 0.5 |
| `sfxVolume` | `float` | 0.0–1.0; default 0.8 |
| `bgmState` | `'stopped' \| 'playing' \| 'paused'` | Runtime only |
| `autoplayUnlocked` | `bool` | Web first-gesture gate (FR-016) |

**Persistence**: Extend `learner-profile.json` v1 with optional `musicVolume`, `sfxVolume`, `musicEnabled`,
`sfxEnabled`; missing keys fall back to defaults in `LearnerProfile.load_profile()`.

### ActionSoundMap

| Category | Asset path (convention) | Trigger |
|----------|-------------------------|---------|
| `bet` | `sfx/bet_confirm.ogg` | Bet placed |
| `deal` | `sfx/deal.ogg` | Cards dealt |
| `insurance-accept` | `sfx/insurance_yes.ogg` | Insurance taken |
| `insurance-decline` | `sfx/insurance_no.ogg` | Insurance declined |
| `hit` | `sfx/hit.ogg` | Hit |
| `stand` | `sfx/stand.ogg` | Stand |
| `double` | `sfx/double.ogg` | Double down |
| `split` | `sfx/split.ogg` | Split |
| `win` | `sfx/win.ogg` | Hand win |
| `loss` | `sfx/lose.ogg` | Hand loss |
| `push` | `sfx/push.ogg` | Push |
| `blackjack` | `sfx/blackjack.ogg` | Natural blackjack |
| `shuffle` | `sfx/shuffle.ogg` | Shoe reshuffle |
| `chip` | `sfx/chip.ogg` | Chip movement |
| `ui-confirm` | `sfx/ui_confirm.ogg` | Button/panel confirm |

**BGM**: `bgm/table_loop.ogg` — seamless loop, life-sim mood.

## State Transitions

### TablePresentation

```text
session:updated → rebuild SeatView[] + CardVisual[]
phase:player-turn → show ActionMenu
phase:dealer-turn → hide ActionMenu
phase:settled → hide play actions; show continue
viewport:resized → update layoutMode
```

### AudioProfile

```text
enter_table → unlock autoplay (if needed) → start BGM if musicEnabled
leave_table → stop BGM
action:confirmed → play SFX if sfxEnabled
profile:saved → persist volume flags
asset:load_failed → silent continue + optional toast (FR-017)
```

### AnalyticsOverlay

```text
sidebar:analytics_pressed → isOpen = true
overlay:close → isOpen = false
hand:settled → append chart point (overlay may stay open)
```
