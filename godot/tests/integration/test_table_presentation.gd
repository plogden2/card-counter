extends GutTest

const CardLayout = preload("res://scripts/presentation/card_layout.gd")
const ActionMenu = preload("res://scripts/presentation/action_menu.gd")
const CoachingCue = preload("res://scripts/presentation/coaching_cue.gd")
const GameControllerScript = preload("res://scripts/game/game_controller.gd")
const LearnerProfile = preload("res://scripts/persistence/learner_profile.gd")


func before_each() -> void:
	LearnerProfile.clear_profile_for_tests()


func test_session_events_produce_presentation_view():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 1})
	controller.call("place_bet", 10)
	controller.call("deal")
	var view: Dictionary = CardLayout.build(controller.call("get_session"))
	assert_gt(view["seats"].size(), 0)
	assert_gte(int(view["shoeRemaining"]), 0)


func test_tutorial_flag_produces_highlight():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_tutorial_table")
	var highlight := CoachingCue.highlight_action(controller.call("get_session"), "tutorial")
	assert_eq(highlight, "place-bet")


func test_phase_maps_to_visible_actions():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	var actions: Array[String] = ActionMenu.visible_actions(controller.call("get_session"))
	assert_true(actions.has("deal"))


func test_audio_records_on_deal():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	controller.call("place_bet", 10)
	controller.call("deal")
	var played: Array = controller.audio_manager.call("get_played_actions")
	assert_true(played.has("deal"))
