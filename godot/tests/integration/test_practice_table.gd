extends GutTest

const GameControllerScript = preload("res://scripts/game/game_controller.gd")


func _settle_hand(controller: Node) -> void:
	var current: Dictionary = controller.call("get_session")
	if current["phase"] == "insurance":
		controller.call("apply_action", "insurance-decline")
		current = controller.call("get_session")
	if current["phase"] == "player-turn":
		controller.call("apply_action", "stand")


func test_applies_setup_config_and_deals_with_count_updates():
	var controller: Node = GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})

	var counts: Array = []
	controller.events.on("count:updated", func(state: Dictionary) -> void:
		counts.append(state["runningCount"])
	)

	controller.call("place_bet", 10)
	controller.call("deal")
	var session: Dictionary = controller.call("get_session")
	assert_true(session["dealerCards"].size() >= 1)
	assert_eq(session["seats"][0]["hands"][0]["cards"].size(), 2)
	assert_gt(counts.size(), 0)


func test_wires_table_configuration_from_setup_to_session():
	var controller: Node = GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 4, "initialOtherPlayers": 2})
	var session: Dictionary = controller.call("get_session")
	assert_eq(int(session["tableConfiguration"]["deckCount"]), 4)
	assert_eq(int(session["tableConfiguration"]["initialOtherPlayers"]), 2)
	assert_eq(session["phase"], "betting")


func test_completes_a_hand_through_stand():
	var controller: Node = GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	controller.call("place_bet", 10)
	controller.call("deal")
	_settle_hand(controller)
	var session: Dictionary = controller.call("get_session")
	assert_eq(session["phase"], "settled")
	assert_eq(int(session["handsPlayed"]), 1)
