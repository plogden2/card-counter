extends GutTest

const AudioManager = preload("res://scripts/game/audio_manager.gd")


func test_leave_table_stops_bgm():
	var audio := AudioManager.new()
	add_child_autofree(audio)
	audio.unlock_autoplay()
	audio.start_table_bgm()
	audio.stop_table_bgm()
	assert_eq(audio.get_bgm_state(), "stopped")


func test_sfx_only_mute_keeps_bgm_attempt():
	var audio := AudioManager.new()
	add_child_autofree(audio)
	audio.unlock_autoplay()
	audio.set_sfx_enabled(false)
	audio.play_action("hit")
	assert_eq(audio.get_played_actions(), [])


func test_music_only_mute_still_allows_sfx_record():
	var audio := AudioManager.new()
	add_child_autofree(audio)
	audio.set_music_enabled(false)
	audio.play_action("stand")
	assert_eq(audio.get_played_actions(), ["stand"])
