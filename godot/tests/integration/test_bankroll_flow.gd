extends GutTest

const GameControllerScript = preload("res://scripts/game/game_controller.gd")
const HandSnapshot = preload("res://scripts/persistence/hand_snapshot.gd")
const LearnerProfile = preload("res://scripts/persistence/learner_profile.gd")


func before_each() -> void:
	LearnerProfile.clear_profile_for_tests()
	HandSnapshot.clear_hand_snapshot()


func _settle_once(controller: Node) -> void:
	controller.call("place_bet", 10)
	controller.call("deal")
	var current: Dictionary = controller.call("get_session")
	if current["phase"] == "insurance":
		controller.call("apply_action", "insurance-decline")
		current = controller.call("get_session")
	if current["phase"] == "player-turn":
		controller.call("apply_action", "stand")


func test_persists_balance_across_controller_reload():
	var controller: Node = GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	_settle_once(controller)
	var balance_after: int = int(controller.call("get_session")["balance"])

	var reloaded: Node = GameControllerScript.new()
	reloaded._ready()
	assert_eq(int(reloaded.call("get_profile")["balance"]), balance_after)


func test_detects_mid_hand_snapshot_presence():
	var session_controller: Node = GameControllerScript.new()
	session_controller._ready()
	session_controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	session_controller.call("place_bet", 10)
	session_controller.call("deal")
	assert_true(session_controller.call("has_mid_hand_snapshot"))


func test_forfeits_mid_hand_and_restores_pre_deal_balance():
	var controller: Node = GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	var before: int = int(controller.call("get_session")["balance"])
	controller.call("place_bet", 10)
	controller.call("deal")
	var after_forfeit: Dictionary = controller.call("forfeit_mid_hand")
	assert_eq(after_forfeit["phase"], "betting")
	assert_eq(int(after_forfeit["balance"]), before)
	assert_false(controller.call("has_mid_hand_snapshot"))


func test_resets_bankroll_with_confirmation():
	LearnerProfile.save_profile({
		"schemaVersion": 1,
		"balance": 350,
		"selectedBetModel": "spread-table",
		"soundEnabled": true,
		"motionReduced": false,
	})
	var controller: Node = GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	controller.call("reset_bankroll_confirmed")
	assert_eq(int(controller.call("get_profile")["balance"]), 1000)
	assert_eq(int(controller.call("get_session")["balance"]), 1000)
