extends GutTest

const AudioManager = preload("res://scripts/game/audio_manager.gd")


func test_all_action_categories_mapped():
	var audio := AudioManager.new()
	var cases := {
		"place-bet": "bet",
		"deal": "deal",
		"hit": "hit",
		"stand": "stand",
		"double": "double",
		"split": "split",
		"insurance-accept": "insurance-accept",
		"insurance-decline": "insurance-decline",
	}
	for action in cases.keys():
		assert_eq(audio.map_action_to_sound(action), cases[action])


func test_settle_outcomes_mapped():
	var audio := AudioManager.new()
	assert_eq(audio.map_action_to_sound("settle", "win"), "win")
	assert_eq(audio.map_action_to_sound("settle", "loss"), "loss")
	assert_eq(audio.map_action_to_sound("settle", "push"), "push")
	assert_eq(audio.map_action_to_sound("settle", "blackjack"), "blackjack")
