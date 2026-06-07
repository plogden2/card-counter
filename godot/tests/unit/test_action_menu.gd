extends GutTest

const ActionMenu = preload("res://scripts/presentation/action_menu.gd")
const GameControllerScript = preload("res://scripts/game/game_controller.gd")
const LearnerProfile = preload("res://scripts/persistence/learner_profile.gd")


func before_each() -> void:
	LearnerProfile.clear_profile_for_tests()


func test_betting_phase_shows_bet_and_deal():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	var actions: Array[String] = ActionMenu.visible_actions(controller.call("get_session"))
	assert_true(actions.has("place-bet"))
	assert_true(actions.has("deal"))


func test_insurance_phase_shows_only_insurance_actions():
	var session := {
		"phase": "insurance",
		"seats": [],
	}
	var actions: Array[String] = ActionMenu.visible_actions(session)
	assert_eq(actions, ["insurance-accept", "insurance-decline", "home"])


func test_dealer_turn_shows_no_player_actions():
	var session := {"phase": "dealer-turn", "seats": []}
	var actions: Array[String] = ActionMenu.visible_actions(session)
	assert_false(actions.has("hit"))
	assert_false(actions.has("stand"))
	assert_true(actions.has("home"))
