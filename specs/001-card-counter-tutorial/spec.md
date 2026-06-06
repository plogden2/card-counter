# Feature Specification: Blackjack Card Counting Tutorial Game

**Feature Branch**: `001-card-counter-tutorial`

**Created**: 2026-06-06

**Status**: Draft

**Input**: User description: "Create a new Blackjack card counting tutorial and test game using Phaser. This should have an option for increasing the number of decks in the shuffle (1-6), the number of other players at the table and the number of hands before reshuffle. The goal should be teaching users how to adjust bet sizes to match optimal and when to leave the table. Include graphs to track the total balance, advantage, etc. A player's balance should persist between games unless they manually reset it. The visuals should be professional and follow a low-poly indie art style. The animations should be smooth. The sound effects should be cute satisfying and addictve. The players should all be dofgs, like the painting of dogs playing poker."

## Clarifications

### Session 2026-06-06

- Q: How should the system calculate the recommended optimal bet range from the true count? → A: Learner selects from multiple bet models; each model includes explanations of pros, cons, and expected return over time.
- Q: When should the drawdown warning suggest leaving the table? → A: Factor in players joining or leaving, reshuffles, and whether current advantage is worth staying versus too low.
- Q: What happens when the learner closes the browser mid-hand? → A: Prompt on return to choose forfeit or resume the partial hand.
- Q: Is insurance offered when the dealer shows an Ace? → A: Insurance always offered when dealer up-card is Ace.
- Q: How should the tutorial be structured for new learners? → A: Dual mode at launch — learner picks Tutorial or Free Play independently (no unlock gating).

## User Scenarios & Testing *(mandatory)*

### User Story 0 - Choose Tutorial or Free Play (Priority: P1)

A learner launches the game and chooses between a structured **Tutorial** track or
**Free Play** sandbox without either mode gated behind the other.

**Why this priority**: Mode selection is the first decision every learner makes; it frames
all subsequent flows and must be available immediately.

**Independent Test**: Can be tested by launching the app, selecting each mode independently,
and confirming the correct entry flow loads without completing the other mode first.

**Acceptance Scenarios**:

1. **Given** a first-time learner at launch, **When** they view the home screen, **Then**
   both Tutorial and Free Play options are visible and selectable with no unlock requirement.
2. **Given** a learner selects Tutorial, **When** the mode loads, **Then** they enter a
   guided lesson path with fixed teaching scenarios and step-by-step coaching.
3. **Given** a learner selects Free Play, **When** the mode loads, **Then** they enter the
   configurable sandbox (table setup, bet models, graphs) without completing Tutorial first.
4. **Given** a learner exits either mode, **When** they return to the home screen, **Then**
   they may switch modes freely on each launch.

**Test Mapping** *(mandatory per constitution)*:

| Layer | Test File(s) | Scenarios Covered |
|-------|--------------|-------------------|
| Unit | tests/unit/mode-routing.test.ts | Mode selection state, no gating rules |
| Functional | tests/functional/launch-modes.test.ts | Tutorial vs Free Play entry flows |
| Integration | tests/integration/mode-switch.test.ts | Home → mode → home → alternate mode |
| Playwright | tests/e2e/launch-modes.spec.ts | First-time learner picks either mode successfully |

---

### User Story 1 - Configure and Play at the Practice Table (Priority: P1)

A learner in **Free Play** configures table conditions (deck count, other players, hands
before reshuffle), and plays simulated blackjack hands against a dealer while practicing
card counting at a table populated by dog characters. Tutorial-mode learners encounter
preset table scenarios within guided lessons.

**Why this priority**: Without a working, configurable table and hand flow, no counting,
bet-sizing, or bankroll lessons can be demonstrated. This is the playable core.

**Independent Test**: Can be fully tested by starting a session with custom table settings,
completing at least one full hand (deal, player decisions, settle), and observing that
settings affect shoe length and table occupancy—without requiring bet coaching or graphs.

**Acceptance Scenarios**:

1. **Given** a new learner on the setup screen, **When** they choose 1–6 decks, 0–5 other
   players, and a hands-before-reshuffle value within the allowed range, **Then** the next
   session starts with those settings applied.
2. **Given** an active session, **When** a hand is dealt, **Then** the learner and each
   other player (dog characters) receive cards, the learner can take standard actions
   (hit, stand; double and split when rules allow), and the hand resolves with correct
   payouts for win, loss, push, and blackjack.
2a. **Given** the dealer's up-card is an Ace, **When** the hand begins, **Then** the
   learner is offered insurance before other actions; accepting or declining resolves
   with correct insurance payout rules when the dealer has blackjack.
3. **Given** cards are revealed during play, **When** the learner views the count aid,
   **Then** the running count and true count update to reflect Hi-Lo values for all
   visible cards dealt in the current shoe.
4. **Given** the configured number of hands has been played since the last shuffle,
   **When** the final hand of that shoe settles, **Then** the shoe reshuffles before the
   next hand and counts reset to zero.

**Test Mapping** *(mandatory per constitution)*:

| Layer | Test File(s) | Scenarios Covered |
|-------|--------------|-------------------|
| Unit | tests/unit/counting.test.ts, tests/unit/shoe.test.ts, tests/unit/hand.test.ts | Hi-Lo values, true count math, shoe composition, hand valuation |
| Functional | tests/functional/table-session.test.ts | Table config application, hand lifecycle, reshuffle trigger |
| Integration | tests/integration/practice-table.test.ts | Config → shoe → deal → count display wiring |
| Playwright | tests/e2e/practice-table.spec.ts | Learner configures table, plays one hand, sees count update |

---

### User Story 2 - Learn Optimal Bet Sizing with Live Feedback (Priority: P2)

A learner compares selectable bet-sizing models, chooses one that fits their learning
goals, and uses real-time guidance and charts to adjust bet sizes based on the current
player advantage under that model.

**Why this priority**: Bet sizing is the primary practical skill the tutorial exists to
teach; it depends on P1 table play but delivers the core educational value.

**Independent Test**: Can be tested by reviewing bet-model comparison content, selecting a
model, loading a session with a known count, placing bets of varying sizes, and verifying
that coaching messages and charts reflect whether each bet matched, under-, or over-shot
the selected model's recommended range.

**Acceptance Scenarios**:

1. **Given** a learner on the bet-model selection screen, **When** they view available
   models, **Then** each model displays pros, cons, and an educational expected-return
   projection over time (simulated, not a guarantee of real-world results).
2. **Given** a learner has selected a bet model, **When** they start or resume a session
   with a known true count, **Then** the system shows the recommended optimal bet range
   for that model given their bankroll and table minimum/maximum.
3. **Given** multiple hands played at varying counts, **When** the learner opens the
   analytics panel, **Then** line graphs display balance over time and estimated player
   advantage over time, updating after each settled hand.
4. **Given** the learner bets below the selected model's recommended range at a positive
   count, **When** the hand settles, **Then** tutorial feedback explains under-betting
   relative to that model (without blocking play).
5. **Given** the learner bets within or above the selected model's recommended range at a
   neutral or negative count, **When** the hand settles, **Then** tutorial feedback
   explains over-betting risk under that model.
6. **Given** a learner changes their selected bet model between hands, **When** the next
   hand begins, **Then** bet recommendations and coaching use the newly selected model.

**Test Mapping** *(mandatory per constitution)*:

| Layer | Test File(s) | Scenarios Covered |
|-------|--------------|-------------------|
| Unit | tests/unit/bet-sizing.test.ts, tests/unit/bet-models.test.ts, tests/unit/advantage.test.ts | Per-model bet formulas, advantage estimation, return projections |
| Functional | tests/functional/bet-coaching.test.ts, tests/functional/bet-model-selection.test.ts | Model comparison content, bet vs recommendation per model |
| Integration | tests/integration/analytics-panel.test.ts | Hand outcomes feed balance and advantage graph data |
| Playwright | tests/e2e/bet-sizing.spec.ts | Learner compares models, selects one, sees recommendation, views graphs |

---

### User Story 3 - Manage Bankroll and Know When to Leave (Priority: P3)

A learner builds session discipline by tracking a persistent bankroll, receiving dynamic
stay-or-leave guidance that weighs player advantage, table occupancy changes, and
reshuffle timing, and optionally resetting their balance to start fresh.

**Why this priority**: Leaving-table discipline and bankroll management complete the
counting curriculum; learners need to recognize when table conditions no longer justify
staying—not just when balance drops.

**Independent Test**: Can be tested by playing across multiple browser sessions, confirming
balance persists, triggering stay-or-leave coaching when advantage is low, after reshuffles,
or when players join/leave, and verifying manual reset restores the default starting bankroll.

**Acceptance Scenarios**:

1. **Given** a learner ends a session with a non-default balance, **When** they return
   later on the same device, **Then** their balance reflects the last saved amount.
2. **Given** a learner chooses "Reset bankroll" and confirms, **When** the reset
   completes, **Then** balance returns to the default starting amount and a new session
   history marker is recorded on graphs.
3. **Given** estimated player advantage is below the selected bet model's worthwhile
   threshold, **When** the condition persists for a defined streak of hands, **Then** the
   tutorial suggests considering leaving and explains that advantage is too low to justify
   staying.
4. **Given** a reshuffle occurs and the count resets to near neutral, **When** table
   conditions (player count, hands before next reshuffle, recent advantage trend) do not
   support staying, **Then** the tutorial evaluates whether remaining at the table is
   worthwhile and presents a stay-or-leave recommendation with reasoning.
5. **Given** one or more dog players join or leave between hands, **When** the occupancy
   change alters expected count pace or session variance, **Then** the stay-or-leave
   guidance updates to reflect the new table dynamics.
6. **Given** balance drops below 50% of session-start balance, **When** the threshold is
   crossed, **Then** the tutorial adds a bankroll-protection warning alongside any
   advantage-based stay-or-leave guidance.
7. **Given** a learner closes the browser during an active hand, **When** they return,
   **Then** the system prompts them to forfeit the partial hand or resume exactly where
   they left off.

**Test Mapping** *(mandatory per constitution)*:

| Layer | Test File(s) | Scenarios Covered |
|-------|--------------|-------------------|
| Unit | tests/unit/bankroll.test.ts, tests/unit/stay-or-leave.test.ts | Persistence, stay-worthiness scoring, reshuffle/player-change rules |
| Functional | tests/functional/session-persistence.test.ts, tests/functional/table-dynamics.test.ts | Save/load balance, join/leave events, stay-or-leave prompts |
| Integration | tests/integration/bankroll-flow.test.ts | Play → persist → reload → continue with stay guidance |
| Playwright | tests/e2e/bankroll-persistence.spec.ts | Cross-session balance, reset, stay-or-leave after reshuffle/player change |

---

### User Story 4 - Immersive Dogs-at-the-Table Presentation (Priority: P4)

A learner enjoys a polished, low-poly indie visual style with dog characters reminiscent
of classic dogs-playing-poker art, smooth card animations, and cute satisfying sound
effects that reinforce actions without distracting from learning.

**Why this priority**: Presentation supports engagement and retention but is not required
to validate counting or bet-sizing logic; it layers on after core mechanics work.

**Independent Test**: Can be tested by launching the game and verifying visual theme,
character styling, animation smoothness during a full hand, and audio feedback on key
actions—without requiring new game rules.

**Acceptance Scenarios**:

1. **Given** any game screen, **When** the learner views the table, **Then** all seated
   participants (learner and other players) appear as distinct low-poly dog characters
   in a cohesive indie art style inspired by dogs playing poker.
2. **Given** a hand in progress, **When** cards are dealt, flipped, collected, or chips
   move, **Then** animations play smoothly without visible stutter on reference hardware.
3. **Given** sound is enabled, **When** the learner bets, hits, stands, wins, or loses,
   **Then** distinct cute, satisfying sound effects play for each action category.
4. **Given** the learner has `prefers-reduced-motion` enabled, **When** they play a hand,
   **Then** motion is minimized or replaced with instant state changes while gameplay
   remains fully usable.

**Test Mapping** *(mandatory per constitution)*:

| Layer | Test File(s) | Scenarios Covered |
|-------|--------------|-------------------|
| Unit | tests/unit/motion-preference.test.ts | Reduced-motion flag handling |
| Functional | tests/functional/audio-cues.test.ts | Action-to-sound mapping, mute setting |
| Integration | tests/integration/table-presentation.test.ts | Character slots, animation triggers on hand events |
| Playwright | tests/e2e/presentation.spec.ts | Visual theme present, reduced-motion path, sound toggle |

---

### Edge Cases

- What happens when the learner sets 1 deck and minimum hands-before-reshuffle—does the
  shoe still reshuffle at the configured hand count even if cards remain?
- How does the system handle shoe exhaustion before the hand-count reshuffle threshold?
- What happens when the table is full (maximum other players) and card distribution
  spans many participants—does counting include all dealt visible cards?
- How does the system respond when the learner attempts a bet larger than their balance
  or table maximum?
- What happens when persisted balance data is missing or corrupted on load—graceful
  default with user notice?
- How does bet coaching behave at table minimum when the optimal bet calculation is below
  the minimum allowed wager?
- What happens when the learner switches bet models mid-session—do graphs and coaching
  history annotate the model change?
- How do expected-return projections differ when deck count or other-player settings change?
- What happens when the learner disables sound or enables reduced motion mid-session?
- How are push, double-after-split, and re-split rules handled when they affect payouts
  and visible cards?
- How does insurance interact with mid-hand forfeit— is the insurance wager refunded or
  settled on forfeit?
- Does Tutorial mode share the same persisted bankroll and bet-model selection as Free Play?
- What happens if persisted partial-hand state is corrupted on load—offer forfeit-only
  recovery with user notice?
- How does stay-or-leave guidance behave when players join mid-shoe versus at reshuffle?
- What happens when advantage is borderline but a reshuffle is many hands away—stay or leave?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST offer a simulated blackjack table for educational practice only
  (no real-money wagering or payouts).
- **FR-001a**: System MUST present Tutorial and Free Play as independently selectable modes
  at launch with no unlock gating between them.
- **FR-001b**: Tutorial mode MUST provide a guided lesson path with fixed scenarios and
  step-by-step coaching; Free Play MUST provide the full configurable sandbox.
- **FR-002**: System MUST let learners configure deck count (1–6), initial other-player
  count (0–5), and hands before reshuffle (range: 20–200, default 75).
- **FR-002a**: System MUST simulate dog players joining or leaving the table between hands
  (not during an active hand), within the 0–5 other-player cap, and reflect changes in
  stay-or-leave guidance.
- **FR-003**: System MUST deal and resolve hands using standard blackjack rules: dealer
  stands on soft 17, blackjack pays 3:2, double on first two cards, split pairs up to
  three times (four hands), no surrender in v1.
- **FR-003a**: System MUST offer insurance when the dealer's up-card is an Ace; insurance
  pays 2:1 when the dealer has blackjack and loses otherwise, up to half the learner's
  main wager.
- **FR-004**: System MUST seat the learner and all other players as visually distinct dog
  characters in a low-poly indie style evoking dogs playing poker.
- **FR-005**: System MUST track and display running count and true count using the Hi-Lo
  system for all cards visible on the table during play.
- **FR-006**: System MUST reshuffle the shoe when the configured hands-before-reshuffle
  count is reached, or sooner if the shoe cannot complete the next hand.
- **FR-007**: System MUST offer at least three selectable bet-sizing models in v1: spread
  table (default Hi-Lo ramp), flat unit ramp, and conservative Wonging (minimum bet below
  true count +1).
- **FR-007a**: System MUST display for each bet model a summary of pros, cons, and an
  educational expected-return-over-time projection based on simulated play assumptions
  (labeled clearly as illustrative, not guaranteed).
- **FR-007b**: System MUST let learners select a bet model at session setup and change it
  between hands (not during an active hand).
- **FR-008**: System MUST recommend an optimal bet range before each hand using the
  learner's selected bet model, true count, table limits, and current bankroll.
- **FR-008a**: System MUST provide non-blocking tutorial feedback after each hand comparing
  the learner's bet to the selected model's recommended range and explaining over- or
  under-betting.
- **FR-009**: System MUST display graphs of balance over time and estimated player
  advantage over time, updating after each settled hand.
- **FR-010**: System MUST persist the learner's balance between sessions on the same device
  until they manually reset it.
- **FR-010a**: System MUST persist in-progress hand state when the browser closes mid-hand
  and, on return, prompt the learner to forfeit the partial hand or resume it.
- **FR-010b**: If the learner chooses forfeit, the system MUST unwind the partial hand
  without balance settlement and restore the last completed-hand state; if they choose
  resume, the system MUST restore cards, bets, and action state exactly.
- **FR-011**: System MUST provide a confirmed manual "Reset bankroll" action that restores
  the default starting balance ($1,000 simulated).
- **FR-012**: System MUST evaluate stay-or-leave worthiness after each settled hand using
  estimated player advantage, selected bet model thresholds, hands until next reshuffle,
  and recent player join/leave events.
- **FR-012a**: System MUST prompt learners to consider leaving when the stay-worthiness
  assessment concludes advantage is too low to justify remaining, explaining which factors
  drove the recommendation (count, reshuffle proximity, table occupancy).
- **FR-012b**: System MUST re-evaluate stay-or-leave guidance immediately after each
  reshuffle and after each player join/leave event.
- **FR-012c**: System MUST also surface a bankroll-protection warning when balance drops
  below 50% of session-start balance, in addition to advantage-based guidance.
- **FR-013**: System MUST animate card and chip movements smoothly during play.
- **FR-014**: System MUST play distinct, cute, satisfying sound effects for bet, hit,
  stand, win, and loss actions, with a user-accessible mute toggle.
- **FR-015**: System MUST honor `prefers-reduced-motion` by reducing or disabling
  decorative animations while preserving playable UI.
- **FR-016**: System MUST support keyboard operation for primary actions (bet confirm,
  hit, stand, double, split, insurance accept/decline, leave table).

### Key Entities

- **Learner Profile**: Persistent balance, selected bet model, sound preference, motion
  preference, last session timestamp, optional in-progress hand snapshot, last selected
  mode (Tutorial or Free Play).
- **Game Mode**: Tutorial (guided lessons) or Free Play (configurable sandbox); selected
  at launch, switchable on return to home screen.
- **Table Configuration**: Deck count (1–6), initial other-player count (0–5), hands
  before reshuffle, table min/max bet.
- **Table Dynamics Event**: Player join or leave between hands; affects occupancy, count
  pace, and stay-or-leave assessment.
- **Stay-or-Leave Assessment**: Composite recommendation from advantage, bet model, reshuffle
  proximity, occupancy changes, and bankroll drawdown.
- **Shoe**: Ordered draw pile built from configured decks; tracks cards remaining and
  hands dealt since shuffle.
- **Hand**: Cards, value, status (active, stood, bust, blackjack), wager, owning seat.
- **Seat / Dog Player**: Character identity, seat position, hand(s), automated basic-strategy
  decisions for non-learner dogs.
- **Count State**: Running count, true count, cards seen, derived from Hi-Lo tags per rank.
- **Bet Model**: Named sizing strategy (e.g., spread table, flat ramp, Wonging) with pros,
  cons, expected-return projection, and recommendation rules.
- **Bet Recommendation**: Suggested min/max wager for current true count, bankroll, and
  active bet model.
- **Session Analytics**: Time-series points for balance and estimated advantage per hand.
- **Tutorial Message**: Contextual coaching text tied to bet sizing, count, or leave-table
  triggers.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 90% of first-time learners can select either Tutorial or Free Play and
  complete one full hand in the chosen mode without external instructions within 5 minutes.
- **SC-001a**: Insurance offer, accept, and decline paths settle with correct payouts in
  100% of scripted dealer-Ace scenarios.
- **SC-002**: Running count and true count match reference calculations for 100% of cards
  in scripted test deals across all deck configurations (1–6).
- **SC-003**: Bet recommendation and post-hand coaching correctly classify under-, optimal,
  and over-bets in 100% of scripted scenarios covering true counts from −6 to +8 for each
  selectable bet model.
- **SC-003a**: 100% of bet models expose pros, cons, and an expected-return summary
  visible before model selection; learners can switch models and see updated recommendations
  within one hand.
- **SC-004**: Balance persists correctly across browser restarts in 100% of automated
  persistence test cases; manual reset restores default in every attempt.
- **SC-004a**: Mid-hand interrupt prompts appear on return in 100% of test cases; forfeit
  and resume paths each produce the correct final balance and hand state.
- **SC-005**: Graphs reflect balance and advantage within one hand of settlement—no missing
  data points after 50 consecutive scripted hands.
- **SC-006**: Stay-or-leave prompts fire within one hand of threshold conditions in 100% of
  scripted scenarios covering low advantage, post-reshuffle neutral count, player
  join/leave, and bankroll drawdown.
- **SC-006a**: Stay-or-leave explanations cite at least two contributing factors (e.g.,
  advantage level and reshuffle proximity) in 100% of prompted scenarios.
- **SC-007**: Learners rate visual polish and audio satisfaction at least 4 out of 5 in
  moderated usability sessions (minimum 5 participants).
- **SC-008**: With reduced motion enabled, learners complete a full hand using keyboard
  only in under 3 minutes without animation-related blockers.

## Assumptions

- Target learners use modern desktop or tablet browsers; mobile phone layout is desirable
  but not required for v1.
- Hi-Lo is the sole counting system in v1; other systems are out of scope.
- Other players (dogs) follow basic strategy automatically; the learner focuses on
  counting and bet sizing on their own hands.
- Simulated player join/leave events occur between hands at a moderate, educationally
  realistic frequency (not every hand); exact timing is implementation detail.
- Stay-or-leave thresholds are tied to the selected bet model's minimum worthwhile
  advantage, not a single global true-count constant.
- Simulated currency only; no connection to real casinos, payments, or gambling accounts.
- Default starting bankroll is $1,000 simulated with table minimum $5 and maximum $500.
- Hands-before-reshuffle range of 20–200 is sufficient for tutorial depth; default 75.
- "Advantage" shown in graphs is an educational estimate derived from true count, not a
  guarantee of real-world casino edge.
- Expected-return-over-time figures are simulated illustrations for teaching bet-model
  tradeoffs; they are not financial advice or guaranteed outcomes.
- Default bet model at first launch is spread table (Hi-Lo ramp); learner's last selected
  model persists across sessions on the same device.
- Tutorial and Free Play share the same persisted bankroll and learner profile; mode
  choice does not reset balance unless the learner manually resets.
- Tutorial lessons use preset scenarios; Free Play exposes full table configuration controls.
- Low-poly dog art and sound assets are original or appropriately licensed; no dependency
  on external live services for core play.
