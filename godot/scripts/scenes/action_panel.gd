extends Control

const ActionMenu = preload("res://scripts/presentation/action_menu.gd")
const UiTheme = preload("res://scripts/lib/ui_theme.gd")
const MotionPreference = preload("res://scripts/lib/motion_preference.gd")

signal action_pressed(action: String)

const HOVER_WOBBLE_DEG := 2.5
const HOVER_SCALE := 1.04
const HIGHLIGHT_PREFIX := "★ "

@onready var _button_row: HBoxContainer = %ButtonRow

var _buttons: Dictionary = {}
var _button_labels: Dictionary = {}
var _visible_ids: Array[String] = []
var _highlight_id := ""
var _motion_reduced := false
var _hover_tweens: Dictionary = {}


func _ready() -> void:
	UiTheme.apply_to(self, UiTheme.ScreenClass.ACTION)
	theme = UiTheme.load_theme()
	_build_buttons()
	for child in _button_row.get_children():
		if child is Button:
			child.add_theme_font_size_override("font_size", 16)
			child.custom_minimum_size = Vector2(130, 48)


func set_motion_reduced(reduced: bool) -> void:
	_motion_reduced = reduced


func get_visible_action_ids() -> Array[String]:
	return _visible_ids.duplicate()


func get_highlighted_action_id() -> String:
	return _highlight_id


func set_highlight(action_id: String) -> void:
	_highlight_id = action_id
	_apply_highlights()


func set_action_visible(action_id: String, visible: bool) -> void:
	var button: Button = _buttons.get(action_id)
	if button == null:
		return
	button.visible = visible
	button.disabled = not visible


func render(session: Dictionary) -> void:
	_visible_ids = ActionMenu.visible_actions(session)
	for action_id in _buttons.keys():
		var button: Button = _buttons[action_id]
		var visible := _visible_ids.has(action_id)
		button.visible = visible
		button.disabled = not visible
		if visible and _visible_ids.size() == 1:
			button.grab_focus()
	_apply_highlights()


func _build_buttons() -> void:
	var defs := {
		"place-bet": "Bet",
		"deal": "Deal",
		"hit": "Hit",
		"stand": "Stand",
		"double": "Double",
		"split": "Split",
		"insurance-accept": "Insure",
		"insurance-decline": "Decline",
		"continue": "Next",
		"home": "Home",
	}
	for action_id in defs.keys():
		var button := Button.new()
		button.text = defs[action_id]
		button.custom_minimum_size = Vector2(120, 44)
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_entered.connect(_on_button_hover_enter.bind(action_id))
		button.mouse_exited.connect(_on_button_hover_exit.bind(action_id))
		button.focus_entered.connect(_on_button_hover_enter.bind(action_id))
		button.focus_exited.connect(_on_button_hover_exit.bind(action_id))
		button.pressed.connect(_on_button_pressed.bind(action_id))
		_button_row.add_child(button)
		_buttons[action_id] = button
		_button_labels[action_id] = defs[action_id]


func _on_button_pressed(action_id: String) -> void:
	action_pressed.emit(action_id)


func _on_button_hover_enter(action_id: String) -> void:
	if _motion_reduced:
		return
	var button: Button = _buttons.get(action_id)
	if button == null or not button.visible:
		return
	_kill_hover_tween(action_id)
	var tween := create_tween()
	tween.tween_property(button, "rotation_degrees", HOVER_WOBBLE_DEG, 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(button, "rotation_degrees", -HOVER_WOBBLE_DEG, 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(button, "rotation_degrees", 0.0, 0.08).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(button, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), 0.12)
	_hover_tweens[action_id] = tween


func _on_button_hover_exit(action_id: String) -> void:
	_kill_hover_tween(action_id)
	var button: Button = _buttons.get(action_id)
	if button == null:
		return
	button.rotation_degrees = 0.0
	button.scale = Vector2.ONE


func _kill_hover_tween(action_id: String) -> void:
	var tween: Tween = _hover_tweens.get(action_id)
	if tween != null and tween.is_valid():
		tween.kill()
	_hover_tweens.erase(action_id)


func _apply_highlights() -> void:
	for action_id in _buttons.keys():
		var button: Button = _buttons[action_id]
		var base_label: String = _button_labels.get(action_id, button.text)
		if action_id == _highlight_id and button.visible:
			button.text = HIGHLIGHT_PREFIX + base_label
			button.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
			button.add_theme_stylebox_override("normal", UiTheme.style_button_glow())
			button.tooltip_text = "Recommended action"
		else:
			button.text = base_label
			button.remove_theme_color_override("font_color")
			button.remove_theme_stylebox_override("normal")
			button.tooltip_text = ""
