extends Control

@onready var _controller: Node = get_node_or_null("/root/GameController")

var deck_count := 6
var other_players := 3
var hands_before_reshuffle := 75
var selected_model := "spread-table"


func set_controller(controller: Node) -> void:
	_controller = controller


func set_deck_count(value: int) -> void:
	deck_count = clampi(value, 1, 6)


func set_other_players(value: int) -> void:
	other_players = clampi(value, 0, 5)


func set_hands_before_reshuffle(value: int) -> void:
	hands_before_reshuffle = maxi(value, 20)


func start_table() -> void:
	var config := {
		"deckCount": deck_count,
		"initialOtherPlayers": other_players,
		"handsBeforeReshuffle": hands_before_reshuffle,
		"betModel": selected_model,
	}
	if _controller and _controller.has_method("start_session"):
		_controller.call("start_session", config)


func _on_start_pressed() -> void:
	start_table()
	if not Engine.is_editor_hint():
		SceneRouter.go_to("table")


func _on_home_pressed() -> void:
	SceneRouter.go_to("home")
