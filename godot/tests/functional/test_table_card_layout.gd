extends GutTest

const CardLayout = preload("res://scripts/presentation/card_layout.gd")
const TABLE_3D_SCENE = preload("res://scenes/table/table_3d.tscn")
const GameControllerScript = preload("res://scripts/game/game_controller.gd")
const LearnerProfile = preload("res://scripts/persistence/learner_profile.gd")


func before_each() -> void:
	LearnerProfile.clear_profile_for_tests()


func _spawn_table() -> Node:
	var table: Node = TABLE_3D_SCENE.instantiate()
	add_child_autofree(table)
	await get_tree().process_frame
	return table


func test_face_up_cards_in_presentation_view():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	controller.call("place_bet", 10)
	controller.call("deal")
	var view: Dictionary = CardLayout.build(controller.call("get_session"))
	var learner_found := false
	for seat in view["seats"]:
		if bool(seat.get("isLearner", false)):
			learner_found = true
			for card in seat.get("cards", []):
				assert_true(bool(card.get("faceUp", true)))
	assert_true(learner_found)


func test_table_3d_sync_places_cards():
	var table: Node = await _spawn_table()
	var view := {
		"seats": [{
			"seatId": "learner",
			"isLearner": true,
			"cards": [{"rank": "K", "suit": "S", "faceUp": true, "fanAngle": 0.0, "index": 0}],
			"scale": 1.0,
			"yaw": 0.0,
		}],
		"shoeRemaining": 50,
	}
	table.call("sync_presentation", view, true)
	assert_eq(table.call("get_card_count"), 1)


func test_reduced_motion_instant_placement():
	var table: Node = await _spawn_table()
	var view := {
		"seats": [{
			"seatId": "learner",
			"isLearner": true,
			"cards": [
				{"rank": "5", "suit": "H", "faceUp": true, "fanAngle": -0.1, "index": 0},
				{"rank": "9", "suit": "D", "faceUp": true, "fanAngle": 0.1, "index": 1},
			],
			"scale": 1.0,
			"yaw": 0.0,
		}],
		"shoeRemaining": 50,
	}
	table.call("sync_presentation", view, true)
	assert_eq(table.call("get_card_count"), 2)


func test_crowded_hand_scale_stays_above_minimum():
	var scale: float = CardLayout.scale_for_card_count(8, true)
	assert_gte(scale, CardLayout.MIN_CARD_SCALE)


func test_reduced_motion_cards_skip_deal_origin():
	var table: Node = await _spawn_table()
	var view := {
		"seats": [{
			"seatId": "learner",
			"isLearner": true,
			"cards": [{"rank": "A", "suit": "S", "faceUp": true, "fanAngle": 0.0, "index": 0}],
			"scale": CardLayout.scale_for_card_count(1, true),
			"yaw": 0.0,
		}],
		"shoeRemaining": 50,
	}
	table.call("sync_presentation", view, true)
	assert_gt(table.call("get_card_count"), 0)
	var card_root: Node3D = table.get_node("SubViewport/World/CardRoot")
	assert_gt(card_root.get_child_count(), 0)
	var card: Node3D = card_root.get_child(0)
	var deal_origin := Vector3(1.4, 0.5, -1.2)
	assert_ne(card.position, deal_origin)
	assert_gte(card.scale.x, CardLayout.MIN_CARD_SCALE)


func test_animation_juice_hooks_exposed():
	var table: Node = await _spawn_table()
	assert_true(table.has_method("sync_chip_wager"))
	assert_true(table.has_method("play_dog_reaction"))
	assert_true(table.has_method("play_outcome_cue"))
	table.call("sync_chip_wager", 25, "betting", true)
	assert_true(table.call("has_chip_node"))
	assert_gte(table.call("get_chip_stack_count"), 1)
	table.call("play_dog_reaction", "deal", true)
	assert_eq(table.call("get_last_dog_reaction"), "deal")
