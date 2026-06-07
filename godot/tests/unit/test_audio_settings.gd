extends GutTest

const AudioManager = preload("res://scripts/game/audio_manager.gd")
const LearnerProfile = preload("res://scripts/persistence/learner_profile.gd")


func before_each() -> void:
	LearnerProfile.clear_profile_for_tests()


func test_default_music_and_sfx_volumes():
	var profile := LearnerProfile.default_profile()
	assert_eq(float(profile["musicVolume"]), 0.5)
	assert_eq(float(profile["sfxVolume"]), 0.8)


func test_bgm_starts_stopped():
	var audio := AudioManager.new()
	add_child_autofree(audio)
	assert_eq(audio.get_bgm_state(), "stopped")


func test_master_mute_suppresses_sfx():
	var audio := AudioManager.new()
	add_child_autofree(audio)
	audio.set_master_enabled(false)
	audio.play_action("hit")
	assert_eq(audio.get_played_actions(), [])


func test_music_mute_stops_bgm_state():
	var audio := AudioManager.new()
	add_child_autofree(audio)
	audio.unlock_autoplay()
	audio.start_table_bgm()
	audio.set_music_enabled(false)
	assert_eq(audio.get_bgm_state(), "stopped")
