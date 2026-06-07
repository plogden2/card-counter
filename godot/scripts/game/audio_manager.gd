extends Node

const SFX_MAP := {
	"deal": "res://assets/audio/sfx/deal.ogg",
	"hit": "res://assets/audio/sfx/hit.ogg",
	"stand": "res://assets/audio/sfx/stand.ogg",
	"win": "res://assets/audio/sfx/win.ogg",
	"lose": "res://assets/audio/sfx/lose.ogg",
}

var _enabled := true
var _bgm_enabled := true
var _played_actions: Array[String] = []
var _bgm_path := "res://assets/audio/bgm.ogg"


func set_enabled(enabled: bool) -> void:
	_enabled = enabled


func is_enabled() -> bool:
	return _enabled


func set_bgm(enabled: bool) -> void:
	_bgm_enabled = enabled


func is_bgm_enabled() -> bool:
	return _bgm_enabled


func map_action_to_sound(action: String, settle_outcome: String = "") -> String:
	match action:
		"place-bet", "deal":
			return "deal"
		"hit":
			return "hit"
		"stand":
			return "stand"
		"settle":
			if settle_outcome == "win":
				return "win"
			if settle_outcome == "loss":
				return "lose"
			return ""
		_:
			return ""


func play_action(action: String, settle_outcome: String = "") -> String:
	var cue: String = map_action_to_sound(action, settle_outcome)
	if cue == "":
		return ""
	if not _enabled:
		return cue
	_played_actions.append(cue)
	return cue


func get_played_actions() -> Array[String]:
	return _played_actions.duplicate()


func clear_played_actions() -> void:
	_played_actions.clear()
