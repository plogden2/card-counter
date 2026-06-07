extends GutTest

const AudioManager = preload("res://scripts/game/audio_manager.gd")
const GameControllerScript = preload("res://scripts/game/game_controller.gd")
const LearnerProfile = preload("res://scripts/persistence/learner_profile.gd")


func before_each() -> void:
	LearnerProfile.clear_profile_for_tests()


func test_maps_player_actions_to_sound_categories():
	var audio := AudioManager.new()
	assert_eq(audio.map_action_to_sound("place-bet"), "bet")
	assert_eq(audio.map_action_to_sound("hit"), "hit")
	assert_eq(audio.map_action_to_sound("stand"), "stand")
	assert_eq(audio.map_action_to_sound("unknown"), "")
	assert_eq(audio.map_action_to_sound("settle", "win"), "win")
	assert_eq(audio.map_action_to_sound("settle", "loss"), "loss")


func test_records_sfx_when_enabled():
	var audio := AudioManager.new()
	audio.set_enabled(true)
	audio.play_action("hit")
	assert_eq(audio.get_played_actions(), ["hit"])


func test_suppresses_sfx_when_muted():
	var audio := AudioManager.new()
	audio.set_enabled(false)
	audio.play_action("deal")
	audio.play_action("stand")
	assert_eq(audio.get_played_actions(), [])


func test_game_controller_emits_action_audio():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	controller.call("place_bet", 10)
	controller.call("deal")
	var session: Dictionary = controller.call("get_session")
	if session["phase"] == "insurance":
		controller.call("apply_action", "insurance-decline")
		session = controller.call("get_session")
	if session["phase"] == "player-turn":
		controller.call("apply_action", "stand")
	var played: Array = controller.audio_manager.call("get_played_actions")
	assert_true(played.has("deal"))


func test_rapid_action_overlap_records_all_cues():
	var audio := AudioManager.new()
	add_child_autofree(audio)
	audio.set_enabled(true)
	var actions := ["place-bet", "deal", "hit", "stand", "double", "split"]
	var expected: Array[String] = []
	for action in actions:
		audio.play_action(action)
		expected.append(audio.map_action_to_sound(action))
	assert_eq(audio.get_played_actions(), expected)
	var sfx_players := 0
	for child in audio.get_children():
		if child is AudioStreamPlayer and child.name != "BgmPlayer":
			sfx_players += 1
	assert_gt(sfx_players, 0)


func test_missing_sfx_asset_continues_silently():
	var rel_path := "res://assets/audio/sfx/bet_confirm.ogg"
	var disk_path := ProjectSettings.globalize_path(rel_path)
	var backup_path := "%s.test_bak" % disk_path
	var had_file := FileAccess.file_exists(disk_path)
	if had_file:
		DirAccess.rename_absolute(disk_path, backup_path)
	var audio := AudioManager.new()
	add_child_autofree(audio)
	audio.set_enabled(true)
	audio.play_action("place-bet")
	assert_eq(audio.get_played_actions(), ["bet"])
	if had_file:
		DirAccess.rename_absolute(backup_path, disk_path)


func test_uses_profile_sound_flag_to_mute_audio():
	LearnerProfile.save_profile({
		"schemaVersion": 1,
		"balance": 1000,
		"selectedBetModel": "spread-table",
		"soundEnabled": false,
		"motionReduced": false,
	})
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	controller.call("place_bet", 10)
	controller.call("deal")
	var played: Array = controller.audio_manager.call("get_played_actions")
	assert_eq(played.size(), 0)
