# Data Model: Blackjack Card Counting Tutorial Game

**Feature**: `001-card-counter-tutorial` | **Date**: 2026-06-06

## Entity Relationship Overview

```text
LearnerProfile ──< SessionState >── TableConfiguration
       │                │
       │                ├── Shoe ──< Card
       │                ├── CountState
       │                ├── Seat[] ── Hand[]
       │                ├── SessionAnalytics[]
       │                └── StayOrLeaveAssessment
       │
       └── BetModel (selected)

HandSnapshot (optional, mid-hand persist)
TutorialLesson (mode = Tutorial)
TableDynamicsEvent (join/leave)
```

## Entities

### LearnerProfile

| Field | Type | Rules |
|-------|------|-------|
| `schemaVersion` | `1` | Required; mismatch → reset with notice |
| `balance` | `number` | Default 1000; ≥ 0; persisted across sessions |
| `selectedBetModel` | `BetModelId` | Default `spread-table` |
| `lastMode` | `'tutorial' \| 'free-play'` | Optional |
| `soundEnabled` | `boolean` | Default true |
| `motionReduced` | `boolean` | Synced from `prefers-reduced-motion` unless overridden |
| `lastSessionAt` | `ISO8601` | Updated on save |

**Persistence key**: `card-counter:learner-profile`

### GameMode

| Value | Description |
|-------|-------------|
| `tutorial` | Guided lessons with preset scenarios |
| `free-play` | Full sandbox configuration |

No unlock gating between modes.

### TableConfiguration

| Field | Type | Validation |
|-------|------|------------|
| `deckCount` | `1..6` | Integer |
| `initialOtherPlayers` | `0..5` | Integer |
| `handsBeforeReshuffle` | `20..200` | Default 75 |
| `tableMinBet` | `5` | Fixed v1 |
| `tableMaxBet` | `500` | Fixed v1 |

### Card

| Field | Type | Notes |
|-------|------|-------|
| `suit` | `'hearts' \| 'diamonds' \| 'clubs' \| 'spades'` | |
| `rank` | `2..10 \| 'J' \| 'Q' \| 'K' \| 'A'` | |
| `hiLoValue` | `-1 \| 0 \| 1` | Derived: 2–6 → +1, 7–9 → 0, 10–A → −1 |

### Shoe

| Field | Type | Notes |
|-------|------|-------|
| `cards` | `Card[]` | Draw pile; built from `deckCount` standard decks |
| `handsDealtSinceShuffle` | `number` | Increment per resolved hand |
| `reshuffleAt` | `number` | From `handsBeforeReshuffle` |

**Transitions**:
- `build()` → fresh shuffled shoe
- `draw(n)` → remove cards; fail if insufficient (trigger reshuffle)
- `onHandSettled()` → increment counter; if `>= reshuffleAt` or cannot deal → `reshuffle()`

### Hand

| Field | Type | Notes |
|-------|------|-------|
| `cards` | `Card[]` | |
| `wager` | `number` | Main bet |
| `insuranceWager` | `number?` | ≤ wager / 2 |
| `status` | `active \| stood \| bust \| blackjack \| surrendered` | surrendered unused v1 |
| `isSplit` | `boolean` | Max 3 splits (4 hands) |
| `ownerSeatId` | `string` | |

### Seat / DogPlayer

| Field | Type | Notes |
|-------|------|-------|
| `id` | `string` | `learner` or `dog-{n}` |
| `isLearner` | `boolean` | |
| `dogBreed` | `string` | Cosmetic (low-poly sprite id) |
| `hands` | `Hand[]` | Learner: 1–4 after splits |
| `strategy` | `basic-s17` | Auto for dogs |

### CountState

| Field | Type | Rules |
|-------|------|-------|
| `runningCount` | `number` | Sum Hi-Lo for all seen cards this shoe |
| `decksRemaining` | `number` | `cards.length / 52` approx |
| `trueCount` | `number` | `floor(runningCount / decksRemaining)` |

Updates on every card reveal to table (all seats + dealer).

### BetModelId

| Id | Name |
|----|------|
| `spread-table` | Spread Table (default) |
| `flat-ramp` | Flat Unit Ramp |
| `wonging` | Conservative Wonging |

Each model includes: `pros`, `cons`, `expectedReturnProjection`, `recommend(wagerContext)`.

### BetRecommendation

| Field | Type |
|-------|------|
| `min` | `number` |
| `max` | `number` |
| `unitSize` | `number` | Bankroll-derived unit |
| `floorApplied` | `boolean` | True when min > optimal |

### SessionAnalytics (per hand)

| Field | Type |
|-------|------|
| `handIndex` | `number` |
| `balance` | `number` |
| `estimatedAdvantage` | `number` | From true count |
| `trueCount` | `number` |
| `betModelId` | `BetModelId` |
| `annotation` | `string?` | e.g. model change, reshuffle |

### StayOrLeaveAssessment

| Field | Type |
|-------|------|
| `stayScore` | `0..1` | Composite (see research R-007) |
| `recommendation` | `'stay' \| 'consider-leaving'` |
| `factors` | `string[]` | ≥2 when prompting |
| `lowAdvantageStreak` | `number` | Consecutive below-threshold hands |

### TableDynamicsEvent

| Field | Type |
|-------|------|
| `type` | `'join' \| 'leave'` |
| `seatId` | `string` |
| `handIndex` | `number` |

Occurs only between hands; occupancy stays within 0–5 other players.

### HandSnapshot (mid-hand persist)

| Field | Type |
|-------|------|
| `sessionState` | `SessionState` | Serialized subset |
| `phase` | `insurance \| player-turn \| dealer-turn` |
| `activeSeatId` | `string` |
| `savedAt` | `ISO8601` |

**Persistence key**: `card-counter:hand-snapshot`

On corrupt load: delete snapshot, notify learner, forfeit-only recovery.

### TutorialLesson (enum v1)

| Id | Title | Focus |
|----|-------|-------|
| `L1` | Running Count Basics | Identify Hi-Lo tags |
| `L2` | True Count | Decks remaining adjustment |
| `L3` | Bet Models | Compare and select model |
| `L4` | Stay or Leave | Reshuffle & occupancy factors |
| `L5` | Free Play Ready | Transition prompt to sandbox |

### SessionState (aggregate root)

Runtime object combining: `mode`, `tableConfiguration`, `shoe`, `seats`, `countState`,
`sessionStartBalance`, `analytics[]`, `currentBetModel`, `handsPlayed`, `dynamicsEvents[]`.

**Session-start balance**: captured at table entry; used for 50% drawdown rule (FR-012c).

## State Transitions (hand lifecycle)

```text
BETTING → DEAL → [INSURANCE?] → PLAYER_ACTIONS → DEALER_PLAY → SETTLE → BETTING
                      ↓
              (dealer Ace up-card)

INSURANCE: learner accept/decline → continue or early settle if dealer BJ

Mid-hand interrupt: save HandSnapshot → on return FORFEIT (restore pre-hand) | RESUME
```

## Validation Rules Summary

- Wager: `tableMinBet ≤ wager ≤ min(balance, tableMaxBet)`
- Insurance: only when dealer up-card Ace; `insuranceWager ≤ wager / 2`
- Split: pairs only; max 3 splits per seat
- Double: first two cards only
- Count includes all visible cards on table each round
- Reshuffle at hand-count threshold even if physical cards remain in shoe
