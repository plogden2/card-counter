extends Node

signal navigated(scene_name: String, data: Dictionary)

func go_to(scene_name: String, data: Dictionary = {}) -> void:
	if scene_name != "table":
		var controller := get_node_or_null("/root/GameController")
		if controller != null and controller.get("audio_manager") != null:
			controller.audio_manager.call("stop_table_bgm")
	navigated.emit(scene_name, data)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/%s.tscn" % scene_name)
