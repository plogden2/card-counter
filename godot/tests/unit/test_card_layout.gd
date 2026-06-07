extends GutTest

const CardLayout = preload("res://scripts/presentation/card_layout.gd")
const GameControllerScript = preload("res://scripts/game/game_controller.gd")
const LearnerProfile = preload("res://scripts/persistence/learner_profile.gd")


func before_each() -> void:
	LearnerProfile.clear_profile_for_tests()


func test_build_returns_seat_views_for_live_session():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 1})
	controller.call("place_bet", 10)
	controller.call("deal")
	var view: Dictionary = CardLayout.build(controller.call("get_session"))
	assert_true(view.has("seats"))
	assert_true(view["seats"].size() >= 2)


func test_learner_seat_gets_priority_scale():
	var scale := CardLayout.scale_for_card_count(2, true)
	assert_gt(scale, CardLayout.scale_for_card_count(2, false))


func test_crowded_hand_hits_minimum_scale():
	var scale := CardLayout.scale_for_card_count(8, false)
	assert_eq(scale, CardLayout.MIN_CARD_SCALE)


func test_fan_angle_spreads_cards():
	var left := CardLayout.fan_angle_for_index(0, 3, "learner")
	var right := CardLayout.fan_angle_for_index(2, 3, "learner")
	assert_lt(left, right)
