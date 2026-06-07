# Godot 4 Cross-Platform Rewrite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the Blackjack Card Counting Tutorial Game in Godot 4 + GDScript so one codebase ships free on Steam (v1), Web, and iOS.

**Architecture:** Pure GDScript domain modules (no `Node` imports) mirror existing TypeScript contracts; `GameController` autoload orchestrates session state and emits typed signals; Godot scenes handle 2D UI shell + 3D table presentation per spec 002.

**Tech Stack:** Godot 4.4+, GDScript, GUT (unit/functional/integration), Forward+ 3D renderer, JSON persistence via `user://`

**Design reference:** [`docs/superpowers/specs/2026-06-06-godot-cross-platform-rewrite-design.md`](../specs/2026-06-06-godot-cross-platform-rewrite-design.md)

**TypeScript reference (port source):** `src/domain/`, `src/lib/`, `src/persistence/`, `src/game/controllers/GameController.ts`

**Test reference (acceptance spec):** `tests/unit/`, `tests/functional/`, `tests/integration/`

---

## File Structure

| Path | Responsibility |
|------|----------------|
| `godot/project.godot` | Engine config, autoloads, main scene |
| `godot/scripts/lib/rng.gd` | Seedable RNG (ports `src/lib/rng.ts`) |
| `godot/scripts/lib/events.gd` | Typed signal bus (ports `src/lib/events.ts`) |
| `godot/scripts/lib/motion_preference.gd` | Reduced-motion tween duration (ports `src/lib/motion-preference.ts`) |
| `godot/scripts/domain/*.gd` | Blackjack/counting/bet domain (ports `src/domain/*.ts`) |
| `godot/scripts/persistence/*.gd` | Profile + hand snapshot JSON (ports `src/persistence/*.ts`) |
| `godot/scripts/game/game_controller.gd` | Session orchestrator autoload |
| `godot/scripts/game/scene_router.gd` | Scene transitions |
| `godot/scripts/game/audio_manager.gd` | BGM + SFX playback |
| `godot/scripts/ui/charts.gd` | Balance/advantage line charts (`_draw`) |
| `godot/scenes/*.tscn` | Boot, Home, Setup, Tutorial, Table, Analytics |
| `godot/tests/unit/*.gd` | GUT tests mirroring Vitest files |
| `godot/tests/integration/*.gd` | GameController + scene harness tests |
| `godot/tests/run_smoke.gd` | Headless export smoke runner |
| `godot/export_presets.cfg` | Windows/Web/iOS export templates |

---

## Prerequisites

- Godot 4.4+ installed and on PATH (`godot --version`)
- Git worktree or branch: `003-godot-rewrite`
- Phaser `src/` kept intact as port reference (do not delete)

**GUT test command (all tasks):**

```bash
godot --headless --path godot -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

**Integration test command:**

```bash
godot --headless --path godot -s addons/gut/gut_cmdln.gd -gdir=res://tests/integration -gexit
```

---

## Phase 0: Project Scaffold & Governance

### Task 1: Update constitution for Godot

**Files:**
- Modify: `.specify/memory/constitution.md`

- [ ] **Step 1: Replace Phaser-First principle**

Find `### Phaser-First Game Architecture` and replace with:

```markdown
### Godot-First Game Architecture

The game MUST use Godot 4 as the primary rendering and scene-management engine. Domain
logic (deck state, hand valuation, counting systems, tutorial progression) MUST live
in plain GDScript modules under `godot/scripts/domain/` with zero `Node` imports so
GUT unit tests do not require a running scene. Scenes MUST orchestrate presentation
and input, not embed untested business rules.

**Rationale**: Godot supports 2D UI + 3D table in one project; separating logic keeps
TDD practical and avoids brittle scene-only tests.
```

- [ ] **Step 2: Replace Educational & Accessible Web section**

Replace `### Educational Clarity & Accessible Web` with:

```markdown
### Educational Clarity & Accessible Multi-Platform

The game MUST ship free as an educational tutorial on Steam, Web, and iOS. Tutorial
copy MUST teach counting concepts clearly and MUST NOT facilitate real-money gambling.
Desktop builds MUST support keyboard-operable controls. iOS builds MUST support touch
targets ≥ 44 pt. Motion and effects MUST respect reduced-motion preference with
usable non-animated fallbacks where motion is decorative.

**Rationale**: The product is a learning tool; clarity and accessibility are core
quality across all export targets.
```

- [ ] **Step 3: Update Technical Constraints**

Replace the `## Technical Constraints` block with:

```markdown
## Technical Constraints

- **Engine**: Godot 4.4+ (version pinned in each feature plan Technical Context).
- **Language**: GDScript for application and test code unless a plan documents an exception.
- **Test stack**: GUT for unit, functional, and integration tests; export smoke via
  headless CLI. Playwright is replaced by scene integration + export smoke for the
  Godot rewrite.
- **Game state**: Deck, shoe, hands, bets, and count state MUST be modeled explicitly;
  randomness MUST be seedable in tests.
- **Performance budget**: 60 fps on 3D table scene; initial Steam load < 5 s on SSD.
- **Persistence**: `user://card-counter/` JSON files per `persistence-schema.json` v1.
```

- [ ] **Step 4: Bump version and amend date**

Set `**Version**: 3.0.0` and `**Last Amended**: 2026-06-06` in the Governance footer.

- [ ] **Step 5: Commit**

```bash
git add .specify/memory/constitution.md
git commit -m "docs: update constitution for Godot cross-platform rewrite"
```

---

### Task 2: Create Godot project skeleton

**Files:**
- Create: `godot/project.godot`
- Create: `godot/scenes/boot.tscn`
- Create: `godot/scripts/game/scene_router.gd`
- Create: `godot/.gitignore`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p godot/scenes/table godot/scripts/domain godot/scripts/game godot/scripts/lib
mkdir -p godot/scripts/persistence godot/scripts/tutorial godot/scripts/ui
mkdir -p godot/assets/models godot/assets/ui godot/assets/audio
mkdir -p godot/tests/unit godot/tests/integration godot/addons
```

- [ ] **Step 2: Write `godot/project.godot`**

```ini
; Engine configuration file.
config_version=5

[application]
config/name="Card Counter"
run/main_scene="res://scenes/boot.tscn"
config/features=PackedStringArray("4.4", "Forward Plus")

[autoload]
GameController="*res://scripts/game/game_controller.gd"
SceneRouter="*res://scripts/game/scene_router.gd"

[rendering]
renderer/rendering_method="forward_plus"

[debug]
gdscript/warnings/untyped_declaration=1
```

- [ ] **Step 3: Write `godot/.gitignore`**

```
.godot/
*.translation
export_presets.cfg
```

- [ ] **Step 4: Write minimal `godot/scripts/game/scene_router.gd`**

```gdscript
extends Node

signal navigated(scene_name: String, data: Dictionary)

func go_to(scene_name: String, data: Dictionary = {}) -> void:
	navigated.emit(scene_name, data)
	get_tree().change_scene_to_file("res://scenes/%s.tscn" % scene_name)
```

- [ ] **Step 5: Write stub `godot/scripts/game/game_controller.gd`**

```gdscript
extends Node

var profile: Dictionary = {}

func _ready() -> void:
	profile = {"schemaVersion": 1, "balance": 1000.0, "selectedBetModel": "spread-table",
		"soundEnabled": true, "motionReduced": false}
```

- [ ] **Step 6: Create `godot/scenes/boot.tscn`**

In Godot editor: root `Node` named `Boot` with script that calls `SceneRouter.go_to("home")` on `_ready`. Or save minimal scene file loading home. Stub `home.tscn` as empty `Control` for now.

- [ ] **Step 7: Verify project opens**

Run: `godot --path godot --quit-after 1`
Expected: exits 0 without errors

- [ ] **Step 8: Commit**

```bash
git add godot/
git commit -m "feat: scaffold Godot 4 project skeleton"
```

---

### Task 3: Install GUT test framework

**Files:**
- Create: `godot/addons/gut/` (via git submodule or copy)
- Modify: `godot/project.godot` (enable plugin)

- [ ] **Step 1: Add GUT addon**

```bash
cd godot/addons
git clone --depth 1 --branch v9.4.0 https://github.com/bitwes/Gut.git gut
```

- [ ] **Step 2: Enable GUT plugin in `godot/project.godot`**

Append:

```ini
[editor_plugins]

enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

- [ ] **Step 3: Write smoke test `godot/tests/unit/test_smoke.gd`**

```gdscript
extends GutTest

func test_gut_runs():
	assert_true(true, "GUT is configured")
```

- [ ] **Step 4: Run GUT**

```bash
godot --headless --path godot -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

Expected: `1/1 passing`

- [ ] **Step 5: Commit**

```bash
git add godot/addons/gut godot/tests/unit/test_smoke.gd godot/project.godot
git commit -m "test: add GUT framework and smoke test"
```

---

## Phase 1: Foundation — RNG, Events, Card, Deck, Hand

### Task 4: Seedable RNG

**Files:**
- Create: `godot/scripts/lib/rng.gd`
- Create: `godot/tests/unit/test_rng.gd`
- Reference: `src/lib/rng.ts`, `tests/unit/rng.test.ts`

- [ ] **Step 1: Write failing test**

```gdscript
extends GutTest

func test_deterministic_sequences_for_same_seed():
	var a = Rng.create(42)
	var b = Rng.create(42)
	var seq_a: Array = []
	var seq_b: Array = []
	for i in 5:
		seq_a.append(a.next())
		seq_b.append(b.next())
	assert_eq(seq_a, seq_b)

func test_next_int_range():
	var rng = Rng.create(7)
	for i in 50:
		var v = rng.next_int(10)
		assert_gte(v, 0)
		assert_lt(v, 10)

func test_next_int_rejects_non_positive_max():
	var rng = Rng.create(1)
	assert_raises("max must be positive", Callable(rng, "next_int").bind(0))
```

- [ ] **Step 2: Run test — verify FAIL**

```bash
godot --headless --path godot -s addons/gut/gut_cmdln.gd -gtest=test_rng.gd -gexit
```

Expected: FAIL — `Rng` not found

- [ ] **Step 3: Implement `godot/scripts/lib/rng.gd`**

```gdscript
class_name Rng

var _state: int

static func create(seed: int) -> Rng:
	var rng := Rng.new()
	rng._state = seed & 0xFFFFFFFF
	return rng

func next() -> float:
	_state = (_state * 1664525 + 1013904223) & 0xFFFFFFFF
	return float(_state) / 4294967296.0

func next_int(max_val: int) -> int:
	if max_val <= 0:
		push_error("max must be positive")
		return 0
	return int(floor(next() * max_val))

static func shuffle(items: Array, rng: Rng) -> Array:
	var result := items.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j = rng.next_int(i + 1)
		var tmp = result[i]
		result[i] = result[j]
		result[j] = tmp
	return result
```

- [ ] **Step 4: Run test — verify PASS**

Expected: all `test_rng.gd` tests PASS

- [ ] **Step 5: Commit**

```bash
git add godot/scripts/lib/rng.gd godot/tests/unit/test_rng.gd
git commit -m "feat: add seedable RNG with GUT tests"
```

---

### Task 5: Card and deck primitives

**Files:**
- Create: `godot/scripts/domain/card.gd`
- Create: `godot/scripts/domain/deck.gd`
- Create: `godot/tests/unit/test_card.gd`
- Reference: `src/domain/card.ts`, `src/domain/deck.ts`, `tests/unit/card.test.ts`

- [ ] **Step 1: Write failing tests**

```gdscript
extends GutTest

func test_hi_lo_tags():
	assert_eq(Card.hi_lo_tag(5), 1)
	assert_eq(Card.hi_lo_tag(7), 0)
	assert_eq(Card.hi_lo_tag("K"), -1)

func test_create_deck_has_52_cards():
	var deck = Deck.create()
	assert_eq(deck.size(), 52)

func test_rank_value_ace_is_eleven():
	assert_eq(Card.rank_value("A"), 11)
```

- [ ] **Step 2: Run — verify FAIL**

- [ ] **Step 3: Implement `godot/scripts/domain/card.gd`**

```gdscript
class_name Card

const SUITS := ["hearts", "diamonds", "clubs", "spades"]
const RANKS := [2, 3, 4, 5, 6, 7, 8, 9, 10, "J", "Q", "K", "A"]

static func hi_lo_tag(rank) -> int:
	if rank is int and rank >= 2 and rank <= 6:
		return 1
	if rank == 7 or rank == 8 or rank == 9:
		return 0
	return -1

static func rank_value(rank) -> int:
	if rank is int:
		return rank
	if rank == "A":
		return 11
	return 10

static func card_equals(a: Dictionary, b: Dictionary) -> bool:
	return a.suit == b.suit and a.rank == b.rank

static func is_pair(cards: Array) -> bool:
	return cards.size() == 2 and rank_value(cards[0].rank) == rank_value(cards[1].rank)
```

- [ ] **Step 4: Implement `godot/scripts/domain/deck.gd`**

```gdscript
class_name Deck

static func create() -> Array:
	var cards: Array = []
	for suit in Card.SUITS:
		for rank in Card.RANKS:
			cards.append({"suit": suit, "rank": rank})
	return cards
```

- [ ] **Step 5: Run — verify PASS**

- [ ] **Step 6: Commit**

```bash
git add godot/scripts/domain/card.gd godot/scripts/domain/deck.gd godot/tests/unit/test_card.gd
git commit -m "feat: add card and deck domain primitives"
```

---

### Task 6: Hand valuation

**Files:**
- Create: `godot/scripts/domain/hand.gd`
- Create: `godot/tests/unit/test_hand.gd`
- Reference: `src/domain/hand.ts`, `tests/unit/hand.test.ts`

- [ ] **Step 1: Port all test cases from `tests/unit/hand.test.ts` to `test_hand.gd`**

Include: hard 17, soft 18 (A+7), double-adjusted totals, bust detection.

- [ ] **Step 2: Run — verify FAIL**

- [ ] **Step 3: Implement `hand.gd` by porting `handValue()` and helpers from `src/domain/hand.ts`**

Return `{"total": int, "soft": bool}` dictionary.

- [ ] **Step 4: Run — verify PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat: add hand valuation domain module"
```

---

### Task 7: Typed event bus

**Files:**
- Create: `godot/scripts/lib/events.gd`
- Create: `godot/tests/unit/test_events.gd`
- Reference: `src/lib/events.ts`, `tests/unit/events.test.ts`

- [ ] **Step 1: Write failing test**

```gdscript
extends GutTest

func test_emit_delivers_payload_to_listener():
	var bus = EventBus.new()
	var received = null
	bus.on("count:updated", func(payload): received = payload)
	bus.emit("count:updated", {"running": 2, "true": 1.0})
	assert_eq(received.running, 2)

func test_off_removes_listener():
	var bus = EventBus.new()
	var count = 0
	var cb = func(_p): count += 1
	bus.on("hand:settled", cb)
	bus.off("hand:settled", cb)
	bus.emit("hand:settled", {})
	assert_eq(count, 0)
```

- [ ] **Step 2: Implement `godot/scripts/lib/events.gd`**

Port `EventBus` class from `src/lib/events.ts`. Use `Dictionary` payloads matching `GameEventMap` keys: `count:updated`, `hand:settled`, `stay:assessed`, `player:joined`, `player:left`, `shoe:reshuffled`, `coaching:message`, `mode:changed`, `scene:navigate`.

- [ ] **Step 3: Run — verify PASS**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: add typed EventBus for GameController signals"
```

---

## Phase 2: User Story 1 — Configure and Play (P1 MVP)

### Task 8: Shoe module

**Files:**
- Create: `godot/scripts/domain/shoe.gd`
- Create: `godot/tests/unit/test_shoe.gd`
- Reference: `src/domain/shoe.ts`, `tests/unit/shoe.test.ts`

- [ ] **Step 1: Port all `shoe.test.ts` cases to GUT** (buildShoe, draw, reshuffle, insufficient cards)

- [ ] **Step 2: Implement `shoe.gd`** matching contract in `specs/001-card-counter-tutorial/contracts/domain-modules.md`:
  - `build_shoe(deck_count, rng) -> Dictionary`
  - `draw(shoe, n) -> {shoe, cards}`
  - `on_hand_settled(shoe, reshuffle_at) -> shoe`

- [ ] **Step 3: Run — verify PASS**

- [ ] **Step 4: Commit**

---

### Task 9: Hi-Lo counting

**Files:**
- Create: `godot/scripts/domain/counting.gd`
- Create: `godot/tests/unit/test_counting.gd`
- Reference: `src/domain/counting.ts`, `tests/unit/counting.test.ts`

- [ ] **Step 1: Port counting tests** (hiLoTag, updateCount, trueCount floor division, min decks 0.5)

- [ ] **Step 2: Implement `counting.gd`** per contract:
  - `update_count(state, cards) -> CountState`
  - `true_count(running, decks_remaining) -> float`

- [ ] **Step 3: Run — verify PASS**

- [ ] **Step 4: Commit**

---

### Task 10: Basic strategy

**Files:**
- Create: `godot/scripts/domain/strategy.gd`
- Create: `godot/tests/unit/test_strategy.gd`
- Reference: `src/domain/strategy.ts`, `tests/unit/strategy.test.ts`

- [ ] **Step 1: Port strategy tests**

- [ ] **Step 2: Implement `strategy.gd`** — `recommend_action(hand, dealer_up, can_double, can_split) -> String`

- [ ] **Step 3: Run — verify PASS**

- [ ] **Step 4: Commit**

---

### Task 11: Blackjack — deal and insurance

**Files:**
- Create: `godot/scripts/domain/session.gd`
- Create: `godot/scripts/domain/table_config.gd`
- Create: `godot/scripts/domain/blackjack.gd` (partial)
- Create: `godot/tests/unit/test_blackjack_deal.gd`
- Reference: `src/domain/blackjack.ts` (dealInitial, insurance), `tests/unit/blackjack.test.ts`

- [ ] **Step 1: Port deal + insurance test cases only**

- [ ] **Step 2: Implement `session.gd` and `table_config.gd`** — port types from `src/domain/session.ts`, `src/domain/table-config.ts`

- [ ] **Step 3: Implement `blackjack.gd`** functions: `create_session()`, `deal_initial()`, `apply_action()` for insurance-accept/insurance-decline only

- [ ] **Step 4: Run — verify PASS**

- [ ] **Step 5: Commit**

---

### Task 12: Blackjack — actions and settle

**Files:**
- Modify: `godot/scripts/domain/blackjack.gd`
- Create: `godot/tests/unit/test_blackjack_actions.gd`
- Reference: `src/domain/blackjack.ts` (hit, stand, double, split, settle)

- [ ] **Step 1: Port remaining blackjack tests** (split, double, blackjack 3:2, insurance 2:1, push)

- [ ] **Step 2: Complete `blackjack.gd`** — `apply_action()` for all `HandAction` values, `settle_hand()`, `hand_value()`

- [ ] **Step 3: Run all blackjack tests — verify PASS**

- [ ] **Step 4: Commit**

---

### Task 13: Functional — table session lifecycle

**Files:**
- Create: `godot/tests/functional/test_table_session.gd`
- Reference: `tests/functional/table-session.test.ts`

- [ ] **Step 1: Port functional test** — config → deal → actions → settle → reshuffle trigger

- [ ] **Step 2: Run**

```bash
godot --headless --path godot -s addons/gut/gut_cmdln.gd -gdir=res://tests/functional -gexit
```

- [ ] **Step 3: Fix any integration gaps in domain modules**

- [ ] **Step 4: Commit**

**Checkpoint US1 domain:** All unit + functional tests for shoe, counting, blackjack PASS.

---

## Phase 3: User Story 0 — Tutorial and Free Play Modes

### Task 14: Mode routing and tutorial domain

**Files:**
- Create: `godot/scripts/domain/mode_routing.gd`
- Create: `godot/scripts/domain/tutorial.gd`
- Create: `godot/scripts/tutorial/lessons.gd`
- Create: `godot/tests/unit/test_mode_routing.gd`
- Create: `godot/tests/unit/test_tutorial.gd`
- Reference: `src/domain/mode-routing.ts`, `src/domain/tutorial.ts`, `src/tutorial/lessons.ts`

- [ ] **Step 1: Port mode-routing tests** — no gating, lastMode persistence keys

- [ ] **Step 2: Port tutorial tests** — five lessons, step advancement

- [ ] **Step 3: Implement modules** — `lessons.gd` exports `LESSONS` array matching `src/tutorial/lessons.ts` content

- [ ] **Step 4: Run — verify PASS**

- [ ] **Step 5: Commit**

---

### Task 15: Home and Tutorial scenes (2D shell)

**Files:**
- Create: `godot/scenes/home.tscn`
- Create: `godot/scenes/tutorial.tscn`
- Create: `godot/scripts/scenes/home_scene.gd`
- Create: `godot/scripts/scenes/tutorial_scene.gd`
- Create: `godot/assets/ui/ui_kit.tres` (Theme resource)
- Create: `godot/tests/integration/test_mode_switch.gd`
- Reference: `src/game/scenes/HomeScene.ts`, `src/game/scenes/TutorialScene.ts`, `tests/integration/mode-switch.test.ts`

- [ ] **Step 1: Build Mix-2 Theme** — dark panel, chunky font, rounded buttons per spec 002

- [ ] **Step 2: Home scene** — two buttons: Tutorial, Free Play; wire to `GameController.select_mode()`

- [ ] **Step 3: Tutorial scene** — lesson list + coaching panel; wire `advance_tutorial_step()`

- [ ] **Step 4: Port integration test** — home → tutorial → home → free-play

- [ ] **Step 5: Run integration tests — verify PASS**

- [ ] **Step 6: Commit**

---

### Task 16: Setup scene

**Files:**
- Create: `godot/scenes/setup.tscn`
- Create: `godot/scripts/scenes/setup_scene.gd`
- Reference: `src/game/scenes/SetupScene.ts`

- [ ] **Step 1: Build setup UI** — spinboxes/sliders: decks 1–6, players 0–5, hands-before-reshuffle

- [ ] **Step 2: Wire to `GameController.start_session(config)`**

- [ ] **Step 3: Manual smoke** — `godot --path godot`, click Free Play → configure → start

- [ ] **Step 4: Commit**

**Checkpoint US0:** Mode selection and tutorial entry work in Godot editor.

---

## Phase 4: User Story 2 — Bet Sizing and Analytics

### Task 17: Bet models and sizing

**Files:**
- Create: `godot/scripts/domain/bet_models.gd`
- Create: `godot/scripts/domain/bet_sizing.gd`
- Create: `godot/scripts/domain/advantage.gd`
- Create: `godot/scripts/tutorial/coaching_copy.gd`
- Create: `godot/tests/unit/test_bet_models.gd`
- Create: `godot/tests/unit/test_bet_sizing.gd`
- Create: `godot/tests/unit/test_advantage.gd`
- Reference: `src/domain/bet-models.ts`, `src/domain/bet-sizing.ts`, `src/domain/advantage.ts`

- [ ] **Step 1: Port all three unit test files**

- [ ] **Step 2: Implement modules** — three models: `spread-table`, `flat-ramp`, `wonging`; TC −6..+8 recommendations

- [ ] **Step 3: Port functional tests** from `tests/functional/bet-coaching.test.ts` to `godot/tests/functional/test_bet_coaching.gd`

- [ ] **Step 4: Run — verify PASS**

- [ ] **Step 5: Commit**

---

### Task 18: Charts and analytics overlay

**Files:**
- Create: `godot/scripts/ui/charts.gd`
- Create: `godot/scenes/analytics_overlay.tscn`
- Create: `godot/scripts/scenes/analytics_overlay.gd`
- Create: `godot/tests/integration/test_analytics_panel.gd`
- Reference: `src/ui/charts.ts`, `src/game/scenes/AnalyticsOverlay.ts`

- [ ] **Step 1: Implement `charts.gd`** — `LineChart` Control with `_draw()` plotting balance and advantage series

- [ ] **Step 2: Analytics overlay** — slide-out drawer triggered from sidebar button

- [ ] **Step 3: Port integration test** — settled hand appends chart data point

- [ ] **Step 4: Run — verify PASS**

- [ ] **Step 5: Commit**

**Checkpoint US2:** Bet coaching and analytics overlay functional.

---

## Phase 5: User Story 3 — Bankroll and Stay-or-Leave

### Task 19: Persistence layer

**Files:**
- Create: `godot/scripts/persistence/learner_profile.gd`
- Create: `godot/scripts/persistence/hand_snapshot.gd`
- Create: `godot/tests/unit/test_bankroll.gd`
- Create: `godot/tests/functional/test_session_persistence.gd`
- Reference: `src/persistence/`, `tests/unit/bankroll.test.ts`, `tests/functional/session-persistence.test.ts`

- [ ] **Step 1: Port bankroll unit tests** — schema v1, default profile, mismatch notice

- [ ] **Step 2: Implement persistence** — read/write `user://card-counter/learner-profile.json` and `hand-snapshot.json` matching `persistence-schema.json`

- [ ] **Step 3: Port functional round-trip tests**

- [ ] **Step 4: Run — verify PASS**

- [ ] **Step 5: Commit**

---

### Task 20: Stay-or-leave and table dynamics

**Files:**
- Create: `godot/scripts/domain/stay_or_leave.gd`
- Create: `godot/scripts/domain/table_dynamics.gd`
- Create: `godot/tests/unit/test_stay_or_leave.gd`
- Create: `godot/tests/unit/test_table_dynamics.gd`
- Reference: `src/domain/stay-or-leave.ts`, `src/domain/table-dynamics.ts`

- [ ] **Step 1: Port unit tests**

- [ ] **Step 2: Implement modules** per `contracts/domain-modules.md`

- [ ] **Step 3: Port functional `table-dynamics.test.ts`**

- [ ] **Step 4: Run — verify PASS**

- [ ] **Step 5: Commit**

---

### Task 21: GameController full wiring

**Files:**
- Modify: `godot/scripts/game/game_controller.gd`
- Create: `godot/tests/integration/test_bankroll_flow.gd`
- Create: `godot/tests/integration/test_practice_table.gd`
- Reference: `src/game/controllers/GameController.ts`, `tests/integration/bankroll-flow.test.ts`, `tests/integration/practice-table.test.ts`

- [ ] **Step 1: Port GameController** — all public methods: `select_mode`, `start_session`, `place_bet`, `apply_action`, `settle`, persistence, mid-hand recovery prompt logic

- [ ] **Step 2: Wire EventBus emits** on count update, hand settled, stay assessed, shoe reshuffled, coaching messages

- [ ] **Step 3: Port integration tests**

- [ ] **Step 4: Run all integration tests**

```bash
godot --headless --path godot -s addons/gut/gut_cmdln.gd -gdir=res://tests/integration -gexit
```

- [ ] **Step 5: Commit**

**Checkpoint US3:** Bankroll persists; stay-or-leave fires; mid-hand snapshot saves.

---

## Phase 6: User Story 4 — Presentation (002 Visual Spec)

### Task 22: Table scene — 2D placeholder

**Files:**
- Create: `godot/scenes/table/table_root.tscn`
- Create: `godot/scenes/table/sidebar.tscn`
- Create: `godot/scripts/scenes/table_scene.gd`
- Create: `godot/scripts/scenes/sidebar.gd`

- [ ] **Step 1: Build sidebar** — Mix-2 stat blocks: running count, true count, bankroll, recommended bet, shoe progress

- [ ] **Step 2: Build placeholder table** — 2D `ColorRect` felt + `Label` card text (placeholder before 3D)

- [ ] **Step 3: Wire action buttons** — hit/stand/double/split/insurance; only show legal actions

- [ ] **Step 4: Wire GameController events** to update sidebar and action button visibility

- [ ] **Step 5: Commit**

---

### Task 23: 3D table scene

**Files:**
- Create: `godot/scenes/table/table_3d.tscn`
- Create: `godot/scripts/scenes/table_3d.gd`
- Create: `godot/assets/models/` (placeholder meshes: table, card, chip, dog, shoe)

- [ ] **Step 1: SubViewport + Camera3D** — replace 2D placeholder felt with 3D table mesh

- [ ] **Step 2: Card meshes** — thin boxes with rank/suit textures; deal animation via `Tween3D`

- [ ] **Step 3: Seat layout** — 0–5 dog placeholder meshes at seats

- [ ] **Step 4: Crowded-table fan layout** — auto-scale cards per seat; raycast hover zoom

- [ ] **Step 5: Reduced motion** — `motion_preference.gd` returns 0 ms tween when profile.motionReduced

- [ ] **Step 6: Commit**

---

### Task 24: Audio

**Files:**
- Create: `godot/scripts/game/audio_manager.gd`
- Create: `godot/assets/audio/bgm.ogg` (placeholder)
- Create: `godot/assets/audio/sfx/` (deal, hit, stand, win, lose placeholders)
- Create: `godot/tests/functional/test_audio_cues.gd`
- Reference: `src/game/audio/AudioManager.ts`, `tests/functional/audio-cues.test.ts`

- [ ] **Step 1: Implement AudioManager** — `play_action(name)`, `set_bgm(enabled)`, mute from profile

- [ ] **Step 2: Wire GameController** to call audio on each action

- [ ] **Step 3: Port audio functional tests**

- [ ] **Step 4: Commit**

---

### Task 25: Responsive stacked layout

**Files:**
- Modify: `godot/scenes/table/table_root.tscn`
- Modify: `godot/scripts/scenes/table_scene.gd`

- [ ] **Step 1: Add viewport size listener** — width < 900px switches sidebar above table (VBox vs HBox)

- [ ] **Step 2: Verify stats visible without scroll** on 768px-wide viewport

- [ ] **Step 3: Commit**

**Checkpoint US4:** Full presentation with 3D table, audio, responsive layout.

---

## Phase 7: Export Smoke & Full Test Suite

### Task 26: Export smoke runner

**Files:**
- Create: `godot/tests/run_smoke.gd`
- Create: `godot/tests/integration/test_export_smoke.gd`

- [ ] **Step 1: Write `run_smoke.gd`**

```gdscript
extends SceneTree

func _initialize() -> void:
	var gut = load("res://addons/gut/gut.gd").new()
	gut.add_directory("res://tests/unit")
	gut.add_directory("res://tests/functional")
	gut.add_directory("res://tests/integration")
	gut.test_scripts()
.quit()
```

- [ ] **Step 2: Run full suite**

```bash
godot --headless --path godot -s tests/run_smoke.gd
```

Expected: all tests PASS, exit 0

- [ ] **Step 3: Commit**

---

## Phase 8: Steam v1 Release

### Task 27: Windows export preset

**Files:**
- Create: `godot/export_presets.cfg` (gitignored locally; template committed as `godot/export_presets.example.cfg`)
- Create: `godot/export_presets.example.cfg`
- Create: `scripts/build-steam.sh` (or `.ps1` for Windows)

- [ ] **Step 1: Create export preset** — Windows Desktop x86_64, embed PCK, icon `assets/ui/icon.png`

- [ ] **Step 2: Build**

```bash
godot --headless --path godot --export-release "Windows Desktop" dist/steam/CardCounter.exe
```

- [ ] **Step 3: Smoke test binary** — launch `dist/steam/CardCounter.exe`, play one hand

- [ ] **Step 4: Document Steam upload steps in `specs/003-godot-rewrite/quickstart.md`**

- [ ] **Step 5: Commit** (example preset + build script + quickstart; not `export_presets.cfg`)

---

## Phase 9: Web Export

### Task 28: HTML5 export

**Files:**
- Modify: `godot/export_presets.example.cfg` (add Web preset)
- Create: `dist/web/` output directory in build script

- [ ] **Step 1: Add Web export preset** — HTML5, canvas resize, focus canvas

- [ ] **Step 2: Build**

```bash
godot --headless --path godot --export-release "Web" dist/web/index.html
```

- [ ] **Step 3: Serve and smoke test**

```bash
npx serve dist/web
```

Open browser, play one hand, verify persistence via IndexedDB

- [ ] **Step 4: Document web caveats** in quickstart (larger download, simplified mid-hand recovery)

- [ ] **Step 5: Commit**

---

## Phase 10: iOS Export

### Task 29: Touch layout and iOS export

**Files:**
- Modify: `godot/scenes/table/table_root.tscn` (touch target sizes)
- Modify: `godot/export_presets.example.cfg` (iOS preset)

**Requires:** Mac with Xcode

- [ ] **Step 1: Enforce minimum 44×44 pt touch targets** on action buttons and sidebar controls

- [ ] **Step 2: Verify stacked layout** on iPhone viewport dimensions

- [ ] **Step 3: Export iOS Xcode project**

```bash
godot --headless --path godot --export-release "iOS" dist/ios/CardCounter.xcodeproj
```

- [ ] **Step 4: Document App Store submission checklist** in quickstart (Education category, free, no IAP)

- [ ] **Step 5: Commit**

---

## Phase 11: Parity Verification & Phaser Archive

### Task 30: Feature parity checklist

**Files:**
- Create: `specs/003-godot-rewrite/parity-checklist.md`

- [ ] **Step 1: Walk design doc Feature Parity Checklist** — mark each item PASS/FAIL

- [ ] **Step 2: Fix any FAIL items**

- [ ] **Step 3: Move Phaser code** — `git mv src src-phaser-archive`, `git mv tests tests-phaser-archive` (only when all items PASS)

- [ ] **Step 4: Update README.md** — Godot quickstart replaces Vite/Phaser instructions

- [ ] **Step 5: Commit**

---

## Test Mapping Summary

| User Story | GUT Unit | GUT Functional | GUT Integration | Export Smoke |
|------------|----------|----------------|-----------------|--------------|
| US0 Modes | test_mode_routing, test_tutorial | test_launch_modes | test_mode_switch | run_smoke |
| US1 Table | test_shoe, test_counting, test_hand, test_blackjack_* | test_table_session | test_practice_table | run_smoke |
| US2 Bets | test_bet_models, test_bet_sizing, test_advantage | test_bet_coaching | test_analytics_panel | run_smoke |
| US3 Bankroll | test_bankroll, test_stay_or_leave, test_table_dynamics | test_session_persistence | test_bankroll_flow | run_smoke |
| US4 Presentation | test_motion_preference | test_audio_cues | test_table_presentation | manual + run_smoke |

---

## Self-Review

**Spec coverage:** All design doc phases (1–6), feature parity checklist, constitution update, and out-of-scope items mapped to tasks. ✅

**Placeholder scan:** No TBD/TODO steps. Large modules (blackjack.gd) split across Tasks 11–12 with explicit reference files. ✅

**Type consistency:** `CountState`, `SessionState`, `LearnerProfile` use Dictionary keys matching TypeScript field names throughout. Event names match `EventBus` in Task 7. ✅

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-06-godot-cross-platform-rewrite.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks, fast iteration
2. **Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
