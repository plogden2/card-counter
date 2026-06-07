extends Node

const SFX_MAP := {
	"bet": "res://assets/audio/sfx/bet_confirm.ogg",
	"deal": "res://assets/audio/sfx/deal.ogg",
	"hit": "res://assets/audio/sfx/hit.ogg",
	"stand": "res://assets/audio/sfx/stand.ogg",
	"double": "res://assets/audio/sfx/double.ogg",
	"split": "res://assets/audio/sfx/split.ogg",
	"insurance-accept": "res://assets/audio/sfx/insurance_yes.ogg",
	"insurance-decline": "res://assets/audio/sfx/insurance_no.ogg",
	"win": "res://assets/audio/sfx/win.ogg",
	"loss": "res://assets/audio/sfx/lose.ogg",
	"push": "res://assets/audio/sfx/push.ogg",
	"blackjack": "res://assets/audio/sfx/blackjack.ogg",
	"shuffle": "res://assets/audio/sfx/shuffle.ogg",
	"chip": "res://assets/audio/sfx/chip.ogg",
	"ui-confirm": "res://assets/audio/sfx/ui_confirm.ogg",
}

const BGM_PATH := "res://assets/audio/bgm/table_loop.ogg"

var _master_enabled := true
var _music_enabled := true
var _sfx_enabled := true
var _music_volume := 0.5
var _sfx_volume := 0.8
var _autoplay_unlocked := false
var _bgm_state := "stopped"
var _played_actions: Array[String] = []
var _bgm_player: AudioStreamPlayer = null


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BgmPlayer"
	add_child(_bgm_player)


func set_enabled(enabled: bool) -> void:
	_master_enabled = enabled
	if not enabled:
		stop_table_bgm()


func is_enabled() -> bool:
	return _master_enabled


func set_bgm(enabled: bool) -> void:
	set_music_enabled(enabled)


func is_bgm_enabled() -> bool:
	return _music_enabled


func set_master_enabled(enabled: bool) -> void:
	set_enabled(enabled)


func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	if not enabled:
		stop_table_bgm()
	elif _bgm_state == "paused":
		start_table_bgm()


func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled


func set_music_volume(level: float) -> void:
	_music_volume = clampf(level, 0.0, 1.0)
	if _bgm_player:
		_bgm_player.volume_db = linear_to_db(_music_volume)


func set_sfx_volume(level: float) -> void:
	_sfx_volume = clampf(level, 0.0, 1.0)


func unlock_autoplay() -> void:
	_autoplay_unlocked = true


func map_action_to_sound(action: String, settle_outcome: String = "") -> String:
	match action:
		"place-bet":
			return "bet"
		"deal":
			return "deal"
		"hit":
			return "hit"
		"stand":
			return "stand"
		"double":
			return "double"
		"split":
			return "split"
		"insurance-accept":
			return "insurance-accept"
		"insurance-decline":
			return "insurance-decline"
		"settle":
			if settle_outcome == "win":
				return "win"
			if settle_outcome == "loss":
				return "loss"
			if settle_outcome == "push":
				return "push"
			if settle_outcome == "blackjack":
				return "blackjack"
			return ""
		"shoe:reshuffled":
			return "shuffle"
		_:
			return ""


func play_action(action: String, settle_outcome: String = "") -> String:
	var cue: String = map_action_to_sound(action, settle_outcome)
	if cue == "":
		return ""
	if not _master_enabled or not _sfx_enabled:
		return cue
	_played_actions.append(cue)
	_try_play_sfx(cue)
	return cue


func play_ui(action: String = "ui-confirm") -> void:
	if not _master_enabled or not _sfx_enabled:
		return
	_played_actions.append(action)
	_try_play_sfx(action)


func start_table_bgm() -> void:
	if not _master_enabled or not _music_enabled:
		return
	if not _autoplay_unlocked and OS.has_feature("web"):
		_bgm_state = "paused"
		return
	if _bgm_player == null:
		return
	if ResourceLoader.exists(BGM_PATH):
		var stream: AudioStream = load(BGM_PATH)
		_bgm_player.stream = stream
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		_bgm_player.volume_db = linear_to_db(_music_volume)
		_bgm_player.play()
		_bgm_state = "playing"
	else:
		_bgm_state = "stopped"


func stop_table_bgm() -> void:
	if _bgm_player and _bgm_player.playing:
		_bgm_player.stop()
	_bgm_state = "stopped"


func get_bgm_state() -> String:
	return _bgm_state


func get_played_actions() -> Array[String]:
	return _played_actions.duplicate()


func clear_played_actions() -> void:
	_played_actions.clear()


func _try_play_sfx(cue: String) -> void:
	if not SFX_MAP.has(cue):
		return
	var path: String = SFX_MAP[cue]
	if not ResourceLoader.exists(path):
		push_warning("Missing SFX asset: %s" % path)
		return
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	player.volume_db = linear_to_db(_sfx_volume)
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
