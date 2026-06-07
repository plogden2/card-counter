extends GutTest

const ActionMenu = preload("res://scripts/presentation/action_menu.gd")
const ActionPanelScript = preload("res://scripts/scenes/action_panel.gd")
const GameControllerScript = preload("res://scripts/game/game_controller.gd")
const LearnerProfile = preload("res://scripts/persistence/learner_profile.gd")


func before_each() -> void:
	LearnerProfile.clear_profile_for_tests()


func test_action_panel_matches_legal_set_in_betting():
	var panel: Node = ActionPanelScript.new()
	add_child_autofree(panel)
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	panel.call("render", controller.call("get_session"))
	var visible: Array = panel.call("get_visible_action_ids")
	var legal: Array[String] = ActionMenu.visible_actions(controller.call("get_session"))
	for action in legal:
		assert_true(visible.has(action))


func test_insurance_only_actions():
	var session := {"phase": "insurance", "seats": []}
	var actions: Array[String] = ActionMenu.visible_actions(session)
	assert_eq(actions.size(), 3)
	assert_true(actions.has("insurance-accept"))
	assert_true(actions.has("insurance-decline"))


func test_mid_hand_action_change_after_stand():
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
		session = controller.call("get_session")
	var actions: Array[String] = ActionMenu.visible_actions(session)
	assert_false(actions.has("hit"))
