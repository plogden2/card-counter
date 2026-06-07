extends Control

const UiTheme = preload("res://scripts/lib/ui_theme.gd")
const OPTIONS_SCENE = preload("res://scenes/options_panel.tscn")

@onready var _controller: Node = get_node_or_null("/root/GameController")
@onready var _panel: PanelContainer = %MenuPanel
var _options_panel: PanelContainer = null
var _last_requested_scene := ""


func get_screen_class() -> int:
	return UiTheme.ScreenClass.MENU


func uses_shared_theme() -> bool:
	return theme != null


func set_controller(controller: Node) -> void:
	_controller = controller
	if _options_panel:
		_options_panel.call("set_controller", controller)


func get_last_requested_scene() -> String:
	return _last_requested_scene


func _ready() -> void:
	UiTheme.apply_to(_panel, UiTheme.ScreenClass.MENU)
	theme = UiTheme.load_theme()
	_spawn_options_panel()


func _spawn_options_panel() -> void:
	_options_panel = OPTIONS_SCENE.instantiate()
	add_child(_options_panel)
	_options_panel.set_controller(_controller)


func select_tutorial_mode() -> void:
	if _controller and _controller.has_method("select_mode"):
		_controller.call("select_mode", "tutorial")
	_last_requested_scene = "tutorial"
	if Engine.is_editor_hint():
		return
	SceneRouter.go_to("tutorial")


func select_free_play_mode() -> void:
	if _controller and _controller.has_method("select_mode"):
		_controller.call("select_mode", "free-play")
	_last_requested_scene = "setup"
	if Engine.is_editor_hint():
		return
	SceneRouter.go_to("setup")


func _on_tutorial_pressed() -> void:
	select_tutorial_mode()


func _on_free_play_pressed() -> void:
	select_free_play_mode()


func _on_options_pressed() -> void:
	if _options_panel:
		_options_panel.call("open")
