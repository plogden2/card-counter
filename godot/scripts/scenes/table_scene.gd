extends Control

const SIDEBAR_SCENE = preload("res://scenes/table/sidebar.tscn")
const CardLayout = preload("res://scripts/presentation/card_layout.gd")
const ActionMenu = preload("res://scripts/presentation/action_menu.gd")
const CoachingCue = preload("res://scripts/presentation/coaching_cue.gd")
const UiTheme = preload("res://scripts/lib/ui_theme.gd")
const COACH_OVERLAY_SCENE = preload("res://scenes/table/tutorial_coach_overlay.tscn")

@onready var _controller: Node = get_node_or_null("/root/GameController")
@onready var _sidebar_container: Control = %SidebarContainer
@onready var _sidebar: VBoxContainer = %Sidebar
@onready var _main_split: BoxContainer = %MainSplit
@onready var _table_3d: SubViewportContainer = %Viewport3D
@onready var _table_area: Control = %TableArea
@onready var _action_panel: Control = %ActionPanel
@onready var _analytics_drawer: Control = %AnalyticsDrawer
@onready var _options_panel: PanelContainer = %OptionsPanel

var _coaching_message := ""
var _current_layout := ""
var _mode := "free-play"
var _coach_overlay: Control = null
var _count_tags: HBoxContainer = null
var _balance_before_hand := 0
var _selected_bet := 25


func set_controller(controller: Node) -> void:
	_controller = controller


func get_layout_mode() -> String:
	return _current_layout if _current_layout != "" else "wide"


func _ready() -> void:
	UiTheme.apply_to(_table_area, UiTheme.ScreenClass.MENU)
	_ensure_sidebar_instance()
	_bind_controller_events()
	_wire_panels()
	_spawn_tutorial_overlays()
	_update_from_session()
	_apply_layout_for_width(get_viewport_rect().size.x)
	if _controller != null and _controller.get("audio_manager") != null:
		_controller.audio_manager.call("start_table_bgm")


func _exit_tree() -> void:
	if _controller != null and _controller.get("audio_manager") != null:
		_controller.audio_manager.call("stop_table_bgm")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_layout_for_width(size.x)


func _unhandled_input(event: InputEvent) -> void:
	if _action_panel == null:
		return
	var visible: Array[String] = _action_panel.call("get_visible_action_ids")
	var bindings := ActionMenu.keyboard_bindings(visible)
	if event is InputEventKey and event.pressed and not event.echo:
		var key_name := OS.get_keycode_string(event.keycode)
		if bindings.has(key_name):
			_on_action_pressed(bindings[key_name])
			get_viewport().set_input_as_handled()


func _wire_panels() -> void:
	if _action_panel and not _action_panel.action_pressed.is_connected(_on_action_pressed):
		_action_panel.action_pressed.connect(_on_action_pressed)
	if _sidebar and _sidebar.has_signal("analytics_requested"):
		_sidebar.analytics_requested.connect(_on_analytics_requested)
	if _sidebar and _sidebar.has_signal("options_requested"):
		_sidebar.options_requested.connect(_on_options_requested)
	if _sidebar and _sidebar.has_signal("bet_amount_changed"):
		_sidebar.bet_amount_changed.connect(_on_bet_amount_changed)
	if _options_panel:
		_options_panel.set_controller(_controller)
	if _controller != null:
		_controller.call("init_overlay")
		var overlay: Node = _controller.get("analytics_overlay")
		if overlay != null and _analytics_drawer != null:
			_analytics_drawer.call("bind_overlay", overlay)


func _on_analytics_requested() -> void:
	if _analytics_drawer != null:
		_analytics_drawer.call("toggle")


func _on_options_requested() -> void:
	if _options_panel != null:
		_options_panel.call("open")


func _on_bet_amount_changed(amount: int) -> void:
	_selected_bet = amount


func _on_count_updated(_payload: Dictionary) -> void:
	_update_from_session()


func _on_hand_settled(_payload: Dictionary) -> void:
	if _controller != null and _table_3d != null:
		var session: Dictionary = _controller.call("get_session")
		var balance: int = int(session.get("balance", 0))
		var outcome := "push"
		if balance > _balance_before_hand:
			outcome = "win"
		elif balance < _balance_before_hand:
			outcome = "loss"
		var motion_reduced: bool = bool(_controller.call("get_profile").get("motionReduced", false))
		_table_3d.call("play_outcome_cue", outcome, motion_reduced)
		var reaction := "neutral"
		if outcome == "win":
			reaction = "win"
		elif outcome == "loss":
			reaction = "loss"
		_table_3d.call("play_dog_reaction", reaction, motion_reduced)
	_update_from_session()


func _on_shoe_reshuffled(_payload: Dictionary) -> void:
	_update_from_session()


func _on_coaching_message(payload: Dictionary) -> void:
	_coaching_message = str(payload.get("text", ""))
	_update_from_session()


func _on_action_pressed(action: String) -> void:
	if _controller == null:
		return
	if _controller.get("audio_manager") != null:
		_controller.audio_manager.call("unlock_autoplay")
	var motion_reduced: bool = bool(_controller.call("get_profile").get("motionReduced", false))
	match action:
		"place-bet":
			_controller.call("place_bet", _selected_bet)
		"deal":
			_balance_before_hand = int(_controller.call("get_session").get("balance", 0))
			_controller.call("deal")
			if _table_3d != null:
				_table_3d.call("play_dog_reaction", "deal", motion_reduced)
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
	if _controller.has_method("get_profile"):
		var profile: Dictionary = _controller.call("get_profile")
		_mode = str(profile.get("lastMode", "free-play"))


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
	var profile: Dictionary = _controller.call("get_profile")
	_mode = str(profile.get("lastMode", "free-play"))
	var motion_reduced: bool = bool(profile.get("motionReduced", false))

	if session.is_empty():
		_sidebar.call("update_stats", {
			"runningCount": 0,
			"trueCount": 0,
			"bankroll": int(profile.get("balance", 1000)),
			"recommendedBet": 25,
			"selectedBet": _selected_bet,
			"minBet": 5,
			"maxBet": 500,
			"bettingEnabled": true,
			"shoeRemaining": "--",
			"tipText": "Place a bet to start.",
		})
		if _action_panel:
			_action_panel.call("set_motion_reduced", motion_reduced)
			_action_panel.call("render", session)
		return

	var suggested_bet: int = _recommended_bet(session)
	var cards_left: int = int(session.get("shoe", {}).get("cards", []).size())
	var count_state: Dictionary = session.get("countState", {})
	var table: Dictionary = session.get("tableConfiguration", {})
	var min_bet: int = int(table.get("tableMinBet", 5))
	var max_bet: int = int(table.get("tableMaxBet", 500))
	var phase: String = str(session.get("phase", "betting"))
	var betting_enabled: bool = phase == "betting"
	if betting_enabled and _sidebar != null and _sidebar.has_method("get_selected_bet"):
		_selected_bet = int(_sidebar.call("get_selected_bet"))
	_selected_bet = clampi(_selected_bet, min_bet, mini(max_bet, int(session.get("balance", 0))))

	_sidebar.call("update_stats", {
		"runningCount": int(count_state.get("runningCount", 0)),
		"trueCount": int(count_state.get("trueCount", 0)),
		"bankroll": int(session.get("balance", 0)),
		"recommendedBet": suggested_bet,
		"selectedBet": _selected_bet,
		"minBet": min_bet,
		"maxBet": max_bet,
		"bettingEnabled": betting_enabled,
		"shoeRemaining": str(cards_left),
		"tipText": _coaching_message if _coaching_message != "" else "Track the count and bet with the true count.",
	})

	var presentation: Dictionary = CardLayout.build(session)
	if _table_3d != null:
		_table_3d.call("sync_presentation", presentation, motion_reduced)
		var wager: int = int(session.get("currentWager", 0))
		_table_3d.call("sync_chip_wager", wager, phase, motion_reduced)

	if _action_panel:
		_action_panel.call("set_motion_reduced", motion_reduced)
		_action_panel.call("render", session)
		var highlight := CoachingCue.highlight_action(session, _mode)
		_action_panel.call("set_highlight", highlight)

	_update_tutorial_overlays(session)


func _spawn_tutorial_overlays() -> void:
	if _table_area == null:
		return
	_coach_overlay = COACH_OVERLAY_SCENE.instantiate()
	_coach_overlay.position = Vector2(16, 16)
	_table_area.add_child(_coach_overlay)

	_count_tags = HBoxContainer.new()
	_count_tags.name = "CountTags"
	_count_tags.position = Vector2(16, 48)
	_table_area.add_child(_count_tags)


func _update_tutorial_overlays(session: Dictionary) -> void:
	if _coach_overlay == null or _count_tags == null:
		return
	if _mode != "tutorial":
		_coach_overlay.call("hide_overlay")
		_count_tags.visible = false
		return

	if _coaching_message != "":
		_coach_overlay.call("show_message", _coaching_message)
	else:
		_coach_overlay.call("hide_overlay")

	_count_tags.visible = CoachingCue.should_show_count_tags(_mode)
	for child in _count_tags.get_children():
		child.queue_free()

	var learner_hand := _get_learner_hand(session)
	for card in learner_hand.get("cards", []):
		if not bool(card.get("faceUp", true)):
			continue
		var tag := Label.new()
		var value := CoachingCue.count_tag_value(card.get("rank", 0))
		tag.text = "%+d" % value if value != 0 else "0"
		tag.add_theme_color_override("font_color", UiTheme.count_color(value))
		_count_tags.add_child(tag)


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


func _recommended_bet(session: Dictionary) -> int:
	var table: Dictionary = session.get("tableConfiguration", {})
	var min_bet: int = int(table.get("tableMinBet", 5))
	var max_bet: int = int(table.get("tableMaxBet", 500))
	var true_count: int = int(session.get("countState", {}).get("trueCount", 0))
	var candidate: int = min_bet + maxi(true_count, 0) * min_bet
	return clampi(candidate, min_bet, max_bet)


func _apply_layout_for_width(width: float) -> void:
	if width < 900.0:
		if _current_layout != "stacked":
			_main_split.vertical = true
			_sidebar_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			_sidebar_container.custom_minimum_size = Vector2(0, 0)
			_table_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_current_layout = "stacked"
	else:
		if _current_layout != "wide":
			_main_split.vertical = false
			_sidebar_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_sidebar_container.custom_minimum_size = Vector2(300, 0)
			_table_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_current_layout = "wide"
