extends Control

@onready var _controller: Node = get_node_or_null("/root/GameController")
var _last_requested_scene := ""


func set_controller(controller: Node) -> void:
	_controller = controller


func get_last_requested_scene() -> String:
	return _last_requested_scene


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
