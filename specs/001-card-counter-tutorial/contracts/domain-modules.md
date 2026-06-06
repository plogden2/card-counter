# Contract: Domain Module Public API

**Version**: 1.0.0 | **Feature**: `001-card-counter-tutorial`

Domain modules MUST NOT import Phaser. All functions are pure or depend only on other domain
modules and `lib/rng`.

## `counting.ts`

```typescript
export function hiLoTag(rank: Rank): -1 | 0 | 1;
export function updateCount(state: CountState, cards: Card[]): CountState;
export function trueCount(running: number, decksRemaining: number): number;
```

**Invariants**: `trueCount` uses floor division; empty shoe → decksRemaining minimum `0.5`.

## `shoe.ts`

```typescript
export function buildShoe(deckCount: number, rng: Rng): Shoe;
export function draw(shoe: Shoe, n: number): { shoe: Shoe; cards: Card[] };
export function onHandSettled(shoe: Shoe, reshuffleAt: number): Shoe;
```

**Invariants**: `draw` throws `InsufficientCards` if `n > cards.length` (caller reshuffles).

## `blackjack.ts`

```typescript
export type HandAction = 'hit' | 'stand' | 'double' | 'split' | 'insurance-accept' | 'insurance-decline';

export function dealInitial(session: SessionState, rng: Rng): SessionState;
export function applyAction(session: SessionState, seatId: string, action: HandAction): SessionState;
export function settleHand(session: SessionState): SessionState;
export function handValue(cards: Card[]): { total: number; soft: boolean };
```

**Invariants**: Insurance offered only when dealer up-card is Ace; payouts 3:2 BJ, 2:1 insurance.

## `bet-models.ts`

```typescript
export type BetModelId = 'spread-table' | 'flat-ramp' | 'wonging';

export interface BetModel {
  id: BetModelId;
  name: string;
  pros: string[];
  cons: string[];
  expectedReturnProjection(table: TableConfiguration): { hourlyEVMin: number; hourlyEVMax: number };
  recommend(ctx: WagerContext): BetRecommendation;
}

export function getBetModel(id: BetModelId): BetModel;
export function listBetModels(): BetModel[];
```

## `stay-or-leave.ts`

```typescript
export function assessStayOrLeave(session: SessionState): StayOrLeaveAssessment;
```

**Invariants**: Must return ≥2 `factors` when recommendation is `consider-leaving`.

## `table-dynamics.ts`

```typescript
export function maybeJoinOrLeave(session: SessionState, rng: Rng): SessionState;
```

**Invariants**: Only between hands; occupancy `0..5` other players.

## `persistence` (via `learner-profile.ts`, `hand-snapshot.ts`)

```typescript
export function loadProfile(): LearnerProfile;
export function saveProfile(profile: LearnerProfile): void;
export function loadHandSnapshot(): HandSnapshot | null;
export function saveHandSnapshot(snapshot: HandSnapshot): void;
export function clearHandSnapshot(): void;
```

**Invariants**: Schema version mismatch → default profile + user notice.

## Event bus (`lib/events.ts`)

Typed events emitted by `GameController` for Phaser scenes:

| Event | Payload |
|-------|---------|
| `count:updated` | `CountState` |
| `hand:settled` | `SessionAnalytics` |
| `stay:assessed` | `StayOrLeaveAssessment` |
| `player:joined` / `player:left` | `TableDynamicsEvent` |
| `shoe:reshuffled` | `{ handIndex: number }` |
| `coaching:message` | `{ text: string; type: 'bet' \| 'stay' \| 'info' }` |

Scenes MUST NOT mutate domain state directly; all changes go through `GameController`.
