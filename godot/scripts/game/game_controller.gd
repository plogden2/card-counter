extends Node

var profile: Dictionary = {}

func _ready() -> void:
	profile = {"schemaVersion": 1, "balance": 1000.0, "selectedBetModel": "spread-table",
		"soundEnabled": true, "motionReduced": false}
