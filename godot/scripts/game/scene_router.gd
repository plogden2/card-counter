extends Node

signal navigated(scene_name: String, data: Dictionary)

func go_to(scene_name: String, data: Dictionary = {}) -> void:
	navigated.emit(scene_name, data)
	get_tree().change_scene_to_file("res://scenes/%s.tscn" % scene_name)
