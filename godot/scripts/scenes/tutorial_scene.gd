extends Control

const Tutorial = preload("res://scripts/domain/tutorial.gd")
const UiTheme = preload("res://scripts/lib/ui_theme.gd")
const OPTIONS_SCENE = preload("res://scenes/options_panel.tscn")

@onready var _controller: Node = get_node_or_null("/root/GameController")
@onready var _panel: PanelContainer = %MenuPanel
@onready var _step_label: RichTextLabel = %StepText
var _options_panel: PanelContainer = null
var _last_requested_scene := ""
var _step_text := ""


func get_screen_class() -> int:
	return UiTheme.ScreenClass.MENU


func uses_shared_theme() -> bool:
	return theme != null


func set_controller(controller: Node) -> void:
	_controller = controller
	_refresh_step_text()
	if _options_panel:
		_options_panel.call("set_controller", controller)


func get_last_requested_scene() -> String:
	return _last_requested_scene


func get_step_text() -> String:
	return _step_text


func _ready() -> void:
	UiTheme.apply_to(_panel, UiTheme.ScreenClass.MENU)
	theme = UiTheme.load_theme()
	_spawn_options_panel()
	_refresh_step_text()


func _spawn_options_panel() -> void:
	_options_panel = OPTIONS_SCENE.instantiate()
	add_child(_options_panel)
	_options_panel.set_controller(_controller)


func advance_step() -> void:
	if _controller and _controller.has_method("advance_tutorial_step"):
		_controller.call("advance_tutorial_step")
	_refresh_step_text()


func play_hand() -> void:
	if _controller and _controller.has_method("start_tutorial_table"):
		_controller.call("start_tutorial_table")
	_last_requested_scene = "table"
	if Engine.is_editor_hint():
		return
	SceneRouter.go_to("table")


func go_home() -> void:
	_last_requested_scene = "home"
	if Engine.is_editor_hint():
		return
	SceneRouter.go_to("home")


func _refresh_step_text() -> void:
	if _controller and _controller.has_method("get_tutorial_progress"):
		var progress: Dictionary = _controller.call("get_tutorial_progress")
		_step_text = Tutorial.get_current_step_text(progress)
	else:
		_step_text = ""
	if _step_label:
		_step_label.text = _step_text


func _on_next_step_pressed() -> void:
	advance_step()


func _on_play_hand_pressed() -> void:
	play_hand()


func _on_home_pressed() -> void:
	go_home()


func _on_options_pressed() -> void:
	if _options_panel:
		_options_panel.call("open")
