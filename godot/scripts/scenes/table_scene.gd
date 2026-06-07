extends Control

const SIDEBAR_SCENE = preload("res://scenes/table/sidebar.tscn")

@onready var _controller: Node = get_node_or_null("/root/GameController")
@onready var _sidebar_container: Control = %SidebarContainer
@onready var _sidebar: VBoxContainer = %Sidebar
@onready var _main_split: BoxContainer = %MainSplit
@onready var _table_3d: SubViewportContainer = %Viewport3D
@onready var _table_area: Control = %TableArea
@onready var _felt_label: Label = %FeltLabel
@onready var _dealer_label: Label = %DealerCards
@onready var _player_label: Label = %PlayerCards
@onready var _phase_label: Label = %PhaseValue
@onready var _action_buttons := {
	"place-bet": %PlaceBetButton,
	"deal": %DealButton,
	"hit": %HitButton,
	"stand": %StandButton,
	"double": %DoubleButton,
	"split": %SplitButton,
	"insurance-accept": %InsuranceAcceptButton,
	"insurance-decline": %InsuranceDeclineButton,
	"continue": %ContinueButton,
	"home": %HomeButton,
}

var _coaching_message := ""
var _current_layout := ""


func set_controller(controller: Node) -> void:
	_controller = controller


func _ready() -> void:
	_ensure_sidebar_instance()
	_bind_controller_events()
	_connect_buttons()
	_update_from_session()
	_apply_layout_for_width(get_viewport_rect().size.x)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_layout_for_width(size.x)


func _on_count_updated(_payload: Dictionary) -> void:
	_update_from_session()


func _on_hand_settled(_payload: Dictionary) -> void:
	_update_from_session()


func _on_shoe_reshuffled(_payload: Dictionary) -> void:
	_update_from_session()


func _on_coaching_message(payload: Dictionary) -> void:
	_coaching_message = str(payload.get("text", ""))
	_update_from_session()


func _connect_buttons() -> void:
	for action in _action_buttons.keys():
		var button: Button = _action_buttons[action]
		if not button.pressed.is_connected(_on_action_pressed.bind(action)):
			button.pressed.connect(_on_action_pressed.bind(action))


func _on_action_pressed(action: String) -> void:
	if _controller == null:
		return
	match action:
		"place-bet":
			_controller.call("place_bet", 25)
		"deal":
			_controller.call("deal")
		"continue":
			_controller.call("continue_to_next_hand")
		"home":
			SceneRouter.go_to("home")
			return
		_:
			_controller.call("apply_action", action)
	_update_from_session()


func _bind_controller_events() -> void:
	if _controller == null:
		return
	var events: Variant = _controller.get("events")
	if events == null:
		return
	events.on("count:updated", Callable(self, "_on_count_updated"))
	events.on("hand:settled", Callable(self, "_on_hand_settled"))
	events.on("shoe:reshuffled", Callable(self, "_on_shoe_reshuffled"))
	events.on("coaching:message", Callable(self, "_on_coaching_message"))


func _ensure_sidebar_instance() -> void:
	if _sidebar != null:
		return
	var packed: PackedScene = SIDEBAR_SCENE
	var instance: Node = packed.instantiate()
	_sidebar_container.add_child(instance)
	_sidebar = instance as VBoxContainer


func _update_from_session() -> void:
	if _controller == null:
		return
	var session: Dictionary = _controller.call("get_session")
	if session.is_empty():
		_felt_label.text = "Place a bet to start."
		_dealer_label.text = "Dealer: --"
		_player_label.text = "Player: --"
		_phase_label.text = "betting"
		_update_action_visibility(session)
		return

	var learner_hand: Dictionary = _get_learner_hand(session)
	var learner_cards: Array = learner_hand.get("cards", [])
	var dealer_cards: Array = session.get("dealerCards", [])

	var legal_actions: Array = _get_legal_actions(session, learner_hand)
	var cards_text: String = _cards_to_text(learner_cards)
	var dealer_text: String = _cards_to_text(dealer_cards)
	var phase: String = str(session.get("phase", "betting"))
	var suggested_bet: int = _recommended_bet(session)
	var cards_left: int = int(session.get("shoe", {}).get("cards", []).size())
	var total_cards: int = int(session.get("tableConfiguration", {}).get("deckCount", 1)) * 52
	var progress: float = 0.0
	if total_cards > 0:
		progress = float(total_cards - cards_left) / float(total_cards)

	_felt_label.text = "Actions: %s" % ", ".join(legal_actions)
	_dealer_label.text = "Dealer: %s" % dealer_text
	_player_label.text = "Player: %s" % cards_text
	_phase_label.text = phase
	_sync_3d_view(session, learner_cards, dealer_cards)

	_sidebar.call("update_stats", {
		"runningCount": int(session.get("countState", {}).get("runningCount", 0)),
		"trueCount": int(session.get("countState", {}).get("trueCount", 0)),
		"bankroll": int(session.get("balance", 0)),
		"recommendedBet": suggested_bet,
		"shoeProgress": "%d%%" % int(round(progress * 100.0)),
	})

	if _coaching_message != "":
		_felt_label.text = "%s\n%s" % [_felt_label.text, _coaching_message]

	_update_action_visibility(session)


func _update_action_visibility(session: Dictionary) -> void:
	var phase: String = str(session.get("phase", "betting"))
	var learner_hand: Dictionary = _get_learner_hand(session)
	var legal: Array = _get_legal_actions(session, learner_hand)

	for action in _action_buttons.keys():
		var button: Button = _action_buttons[action]
		button.visible = legal.has(action)
		button.disabled = not button.visible

	_action_buttons["place-bet"].visible = phase == "betting"
	_action_buttons["deal"].visible = phase == "betting"
	_action_buttons["continue"].visible = phase == "settled"
	_action_buttons["home"].visible = true
	_action_buttons["home"].disabled = false


func _get_legal_actions(session: Dictionary, hand: Dictionary) -> Array:
	var phase: String = str(session.get("phase", "betting"))
	if phase == "betting":
		return ["place-bet", "deal"]
	if phase == "insurance":
		return ["insurance-accept", "insurance-decline"]
	if phase == "settled":
		return ["continue"]
	if phase != "player-turn":
		return []

	var actions := ["hit", "stand"]
	var cards: Array = hand.get("cards", [])
	var status: String = str(hand.get("status", "active"))
	if cards.size() == 2 and status == "active":
		if not bool(hand.get("doubled", false)):
			actions.append("double")
		if not bool(hand.get("isSplit", false)) and cards.size() == 2:
			var rank_a: Variant = cards[0].get("rank", "")
			var rank_b: Variant = cards[1].get("rank", "")
			if rank_a == rank_b:
				actions.append("split")
	return actions


func _get_learner_hand(session: Dictionary) -> Dictionary:
	var seats: Array = session.get("seats", [])
	for seat in seats:
		if bool(seat.get("isLearner", false)):
			var hands: Array = seat.get("hands", [])
			if hands.is_empty():
				return {}
			var hand_index: int = int(session.get("activeHandIndex", 0))
			hand_index = clampi(hand_index, 0, hands.size() - 1)
			return hands[hand_index]
	return {}


func _cards_to_text(cards: Array) -> String:
	if cards.is_empty():
		return "--"
	var chunks: Array[String] = []
	for card in cards:
		chunks.append("%s%s" % [str(card.get("rank", "?")), str(card.get("suit", "?")).substr(0, 1)])
	return ", ".join(chunks)


func _recommended_bet(session: Dictionary) -> int:
	var table: Dictionary = session.get("tableConfiguration", {})
	var min_bet: int = int(table.get("tableMinBet", 5))
	var max_bet: int = int(table.get("tableMaxBet", 500))
	var true_count: int = int(session.get("countState", {}).get("trueCount", 0))
	var candidate: int = min_bet + maxi(true_count, 0) * min_bet
	return clampi(candidate, min_bet, max_bet)


func _sync_3d_view(session: Dictionary, learner_cards: Array, dealer_cards: Array) -> void:
	if _table_3d == null:
		return
	var cards_to_show: Array = []
	cards_to_show.append_array(learner_cards)
	cards_to_show.append_array(dealer_cards)
	var seats: Array = session.get("seats", [])
	var dog_count: int = maxi(0, seats.size() - 1)
	_table_3d.call("set_dog_count", dog_count)
	_table_3d.call("deal_cards", cards_to_show, bool(_controller.call("get_profile").get("motionReduced", false)))


func _apply_layout_for_width(width: float) -> void:
	if width < 900.0:
		if _current_layout != "stacked":
			_main_split.vertical = true
			_sidebar_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			_table_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_current_layout = "stacked"
	else:
		if _current_layout != "wide":
			_main_split.vertical = false
			_sidebar_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_table_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_current_layout = "wide"
