extends Control

const SIDEBAR_SCENE = preload("res://scenes/table/sidebar.tscn")
const CardLayout = preload("res://scripts/presentation/card_layout.gd")
const ActionMenu = preload("res://scripts/presentation/action_menu.gd")
const CoachingCue = preload("res://scripts/presentation/coaching_cue.gd")
const TableDynamics = preload("res://scripts/domain/table_dynamics.gd")
const UiTheme = preload("res://scripts/lib/ui_theme.gd")
const COACH_OVERLAY_SCENE = preload("res://scenes/table/tutorial_coach_overlay.tscn")
const STATUS_BAR_SCENE = preload("res://scenes/table/tutorial_status_bar.tscn")

@onready var _controller: Node = get_node_or_null("/root/GameController")
@onready var _sidebar_container: Control = %SidebarContainer
@onready var _sidebar: VBoxContainer = %Sidebar
@onready var _main_split: BoxContainer = %MainSplit
@onready var _table_3d: SubViewportContainer = %Viewport3D
@onready var _table_area: Control = %TableArea
@onready var _overlay_layer: Control = %OverlayLayer
@onready var _action_panel: Control = %ActionPanel
@onready var _analytics_drawer: Control = %AnalyticsDrawer
@onready var _options_panel: PanelContainer = %OptionsPanel

var _coaching_message := ""
var _current_layout := ""
var _mode := "free-play"
var _coach_overlay: Control = null
var _status_bar: Control = null
var _next_button: Button = null
var _count_tags: HBoxContainer = null
var _balance_before_hand := 0
var _selected_bet := 25


func set_controller(controller: Node) -> void:
	_controller = controller


func get_layout_mode() -> String:
	return _current_layout if _current_layout != "" else "wide"


func _ready() -> void:
	_ensure_sidebar_instance()
	_bind_controller_events()
	_wire_panels()
	_spawn_tutorial_overlays()
	_apply_sidebar_theme()
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
	if _sidebar and _sidebar.has_signal("menu_requested"):
		_sidebar.menu_requested.connect(_on_menu_requested)
	if _sidebar and _sidebar.has_signal("help_requested"):
		_sidebar.help_requested.connect(_on_help_requested)
	if _sidebar and _sidebar.has_signal("bet_amount_changed"):
		_sidebar.bet_amount_changed.connect(_on_bet_amount_changed)
	if _options_panel:
		_options_panel.set_controller(_controller)
	if _controller != null:
		_controller.call("init_overlay")
		var overlay: Node = _controller.get("analytics_overlay")
		if overlay != null and _analytics_drawer != null:
			_analytics_drawer.call("bind_overlay", overlay)


func _on_menu_requested() -> void:
	SceneRouter.go_to("home")


func _on_help_requested() -> void:
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
			"decksRemaining": 2.0,
			"bet": _selected_bet,
			"selectedBet": _selected_bet,
			"minBet": 5,
			"maxBet": 500,
			"bettingEnabled": true,
			"refDisplay": _mode == "tutorial",
			"tipText": "Place a bet to start.",
		})
		if _action_panel:
			_action_panel.call("set_motion_reduced", motion_reduced)
			_action_panel.call("render", session)
		_update_tutorial_overlays({}, 0)
		return

	var count_state: Dictionary = session.get("countState", {})
	var decks_remaining: float = float(count_state.get("decksRemaining", 2.0))
	var running_count: int = int(count_state.get("runningCount", 0))
	var table: Dictionary = session.get("tableConfiguration", {})
	var min_bet: int = int(table.get("tableMinBet", 5))
	var max_bet: int = int(table.get("tableMaxBet", 500))
	var phase: String = str(session.get("phase", "betting"))
	var betting_enabled: bool = phase == "betting"
	if betting_enabled and _sidebar != null and _sidebar.has_method("get_selected_bet"):
		_selected_bet = int(_sidebar.call("get_selected_bet"))
	_selected_bet = clampi(_selected_bet, min_bet, mini(max_bet, int(session.get("balance", 0))))

	var ref_display := _mode == "tutorial"
	_sidebar.call("update_stats", {
		"runningCount": running_count,
		"trueCount": int(count_state.get("trueCount", 0)),
		"decksRemaining": decks_remaining,
		"bet": int(session.get("currentWager", 0)) if phase != "betting" else _selected_bet,
		"selectedBet": _selected_bet,
		"minBet": min_bet,
		"maxBet": max_bet,
		"bettingEnabled": betting_enabled,
		"refDisplay": ref_display,
		"tipText": _coaching_tip_text(running_count),
	})
	if _sidebar.has_method("set_ref_display"):
		_sidebar.call("set_ref_display", ref_display)

	var presentation: Dictionary = CardLayout.build(session)
	if _table_3d != null:
		var other_dogs := TableDynamics.count_other_players(session.get("seats", []))
		_table_3d.call("configure_table_dogs", other_dogs)
		_table_3d.call("sync_presentation", presentation, motion_reduced)
		var wager: int = int(session.get("currentWager", 0))
		_table_3d.call("sync_chip_wager", wager, phase, motion_reduced)

	if _action_panel:
		_action_panel.call("set_motion_reduced", motion_reduced)
		_action_panel.call("render", session)
		var highlight := CoachingCue.highlight_action(session, _mode)
		_action_panel.call("set_highlight", highlight)
		if ref_display:
			_action_panel.visible = _tutorial_needs_action_panel(session)
			var visible_actions: Array = _action_panel.call("get_visible_action_ids")
			_hide_continue_in_action_panel(visible_actions.has("continue"))
		else:
			_action_panel.visible = true
			_hide_continue_in_action_panel(false)

	_update_tutorial_overlays(session, running_count)


func _spawn_tutorial_overlays() -> void:
	if _overlay_layer == null:
		return
	_coach_overlay = COACH_OVERLAY_SCENE.instantiate()
	_coach_overlay.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_coach_overlay.offset_left = -170.0
	_coach_overlay.offset_top = 12.0
	_coach_overlay.offset_right = 170.0
	_coach_overlay.offset_bottom = 92.0
	_coach_overlay.visible = false
	_coach_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.add_child(_coach_overlay)

	_status_bar = STATUS_BAR_SCENE.instantiate()
	_status_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_status_bar.offset_left = -160.0
	_status_bar.offset_top = -68.0
	_status_bar.offset_right = 160.0
	_status_bar.offset_bottom = -4.0
	_status_bar.visible = false
	_status_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.add_child(_status_bar)

	_next_button = Button.new()
	_next_button.name = "TutorialNextButton"
	_next_button.text = "NEXT >"
	_next_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_next_button.offset_left = -132.0
	_next_button.offset_top = -56.0
	_next_button.offset_right = -12.0
	_next_button.offset_bottom = -8.0
	_next_button.custom_minimum_size = Vector2(120, 48)
	_next_button.visible = false
	_next_button.pressed.connect(_on_tutorial_next_pressed)
	_overlay_layer.add_child(_next_button)

	_count_tags = HBoxContainer.new()
	_count_tags.name = "CountTags"
	_count_tags.visible = false
	_count_tags.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_count_tags.offset_left = -160.0
	_count_tags.offset_top = 96.0
	_count_tags.offset_right = 160.0
	_count_tags.offset_bottom = 132.0
	_count_tags.alignment = BoxContainer.ALIGNMENT_CENTER
	_count_tags.add_theme_constant_override("separation", 8)
	_count_tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.add_child(_count_tags)


func _apply_sidebar_theme() -> void:
	if _sidebar_container is PanelContainer:
		UiTheme.apply_to(_sidebar_container, UiTheme.ScreenClass.SIDEBAR)
	if _sidebar != null:
		_sidebar.theme = UiTheme.load_theme()
		_sidebar.add_theme_constant_override("separation", 10)
	if _action_panel != null:
		_action_panel.theme = UiTheme.load_theme()
	if _next_button != null:
		_next_button.theme = UiTheme.load_theme()
		_next_button.add_theme_font_size_override("font_size", 16)


func _coaching_tip_text(running_count: int) -> String:
	if _coaching_message != "":
		return _coaching_message
	if running_count > 0:
		return "Positive counts are good! Consider increasing your bet."
	if running_count < 0:
		return "Negative counts favor the house. Bet conservatively."
	return "Watch the running count as cards are dealt."


func _on_tutorial_next_pressed() -> void:
	_on_action_pressed("continue")


func _hide_continue_in_action_panel(hide_continue: bool) -> void:
	if _action_panel == null or not _action_panel.has_method("set_action_visible"):
		return
	_action_panel.call("set_action_visible", "continue", not hide_continue)


func _tutorial_needs_action_panel(session: Dictionary) -> bool:
	var visible: Array[String] = _action_panel.call("get_visible_action_ids")
	for action_id in visible:
		if action_id != "continue":
			return true
	return false


func _status_subtitle(running_count: int) -> String:
	if _coaching_message != "" and not _coaching_message.begins_with("Positive"):
		return _coaching_message
	if running_count > 0:
		return "Nice! You're doing great!"
	if running_count < 0:
		return "Stay steady — counts will swing back."
	return "Watch each card as it appears."


func _update_tutorial_overlays(session: Dictionary, running_count: int = 0) -> void:
	if _coach_overlay == null or _count_tags == null:
		return
	if _mode != "tutorial":
		_coach_overlay.call("hide_overlay")
		if _status_bar != null:
			_status_bar.call("hide_bar")
		if _next_button != null:
			_next_button.visible = false
		_count_tags.visible = false
		_hide_continue_in_action_panel(false)
		return

	if _coaching_message != "":
		_coach_overlay.call("show_message", _coaching_message)
	else:
		_coach_overlay.call("hide_overlay")

	if _status_bar != null:
		_status_bar.call("update_status", running_count, _status_subtitle(running_count))

	var show_next := false
	if _action_panel != null and _next_button != null:
		var visible: Array[String] = _action_panel.call("get_visible_action_ids")
		show_next = visible.has("continue")
		_next_button.visible = show_next

	_count_tags.visible = CoachingCue.should_show_count_tags(_mode) and session.get("phase", "") != "betting"
	for child in _count_tags.get_children():
		child.queue_free()

	var learner_hand := _get_learner_hand(session)
	for card in learner_hand.get("cards", []):
		if not bool(card.get("faceUp", true)):
			continue
		var tag := Label.new()
		var value := CoachingCue.count_tag_value(card.get("rank", 0))
		tag.text = "%+d" % value if value != 0 else "0"
		tag.add_theme_color_override("font_color", UiTheme.TEXT_CREAM)
		tag.add_theme_font_size_override("font_size", 13)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var badge := PanelContainer.new()
		badge.add_theme_stylebox_override("panel", UiTheme.load_theme().get_stylebox(
			UiTheme.hilo_badge_style(value),
			"PanelContainer"
		))
		badge.add_child(tag)
		_count_tags.add_child(badge)


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
	if _main_split == null or _sidebar_container == null or _table_area == null:
		return
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
			_sidebar_container.custom_minimum_size = Vector2(311, 0)
			_table_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_current_layout = "wide"
