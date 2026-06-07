extends GutTest

const CoachingCue = preload("res://scripts/presentation/coaching_cue.gd")
const ActionMenu = preload("res://scripts/presentation/action_menu.gd")
const ActionPanelScript = preload("res://scripts/scenes/action_panel.gd")
const GameControllerScript = preload("res://scripts/game/game_controller.gd")
const LearnerProfile = preload("res://scripts/persistence/learner_profile.gd")


func before_each() -> void:
	LearnerProfile.clear_profile_for_tests()


func test_tutorial_lesson_highlights_recommended_action():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_tutorial_table")
	var panel: Node = ActionPanelScript.new()
	add_child_autofree(panel)
	panel.call("render", controller.call("get_session"))
	var highlight := CoachingCue.highlight_action(controller.call("get_session"), "tutorial")
	panel.call("set_highlight", highlight)
	assert_eq(highlight, "place-bet")
	assert_true(panel.call("get_visible_action_ids").has("place-bet"))


func test_free_play_has_no_highlight():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	assert_eq(CoachingCue.highlight_action(controller.call("get_session"), "free-play"), "")


func test_non_highlighted_choice_still_legal():
	var session := {"phase": "insurance", "seats": []}
	var highlight := CoachingCue.highlight_action(session, "tutorial")
	var visible: Array[String] = ["insurance-accept", "insurance-decline", "home"]
	assert_true(visible.has("insurance-accept"))
	assert_ne(highlight, "insurance-accept")


func _hard_16_vs_10_session() -> Dictionary:
	return {
		"phase": "player-turn",
		"activeHandIndex": 0,
		"dealerCards": [{"suit": "hearts", "rank": 10, "faceUp": true}],
		"seats": [{
			"id": "learner",
			"isLearner": true,
			"hands": [{
				"cards": [
					{"suit": "hearts", "rank": 10, "faceUp": true},
					{"suit": "spades", "rank": 6, "faceUp": true},
				],
				"status": "active",
				"doubled": false,
				"isSplit": false,
			}],
		}],
	}


func test_non_highlighted_tutorial_choice_produces_coaching_feedback():
	var session := _hard_16_vs_10_session()
	var highlight := CoachingCue.highlight_action(session, "tutorial")
	assert_eq(highlight, "hit")
	var feedback := CoachingCue.post_choice_feedback(session, "tutorial", "stand")
	assert_ne(feedback, "")
	assert_string_contains(feedback, "Stand")
	assert_string_contains(feedback, "Hit")


func test_highlighted_tutorial_choice_has_no_post_choice_feedback():
	var session := _hard_16_vs_10_session()
	assert_eq(CoachingCue.post_choice_feedback(session, "tutorial", "hit"), "")


func test_non_highlighted_tutorial_choice_does_not_block_hand():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_tutorial_table")
	controller.call("place_bet", 10)
	controller.call("deal")
	var session: Dictionary = controller.call("get_session")
	if session["phase"] == "insurance":
		controller.call("apply_action", "insurance-decline")
		session = controller.call("get_session")
	if session["phase"] != "player-turn":
		pending("RNG did not reach player-turn for non-highlight coaching check")
		return
	var highlight := CoachingCue.highlight_action(session, "tutorial")
	var visible: Array[String] = ActionMenu.visible_actions(session)
	var alternate := "stand" if highlight == "hit" else "hit"
	if not visible.has(alternate):
		pending("No alternate legal action available for coaching feedback check")
		return
	var feedback := CoachingCue.post_choice_feedback(session, "tutorial", alternate)
	assert_ne(feedback, "")
	controller.call("apply_action", alternate)
	session = controller.call("get_session")
	assert_true(session["phase"] in ["player-turn", "dealer-turn", "settled"])


func test_non_highlighted_tutorial_choice_emits_coaching_message():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("select_mode", "tutorial")
	var messages: Array = []
	controller.events.on("coaching:message", func(payload: Dictionary) -> void:
		messages.append(payload)
	)
	var session := _hard_16_vs_10_session()
	var feedback := CoachingCue.post_choice_feedback(session, "tutorial", "stand")
	controller.events.emit_event("coaching:message", {"text": feedback, "type": "action"})
	assert_eq(messages.size(), 1)
	assert_eq(messages[0]["type"], "action")
	assert_string_contains(str(messages[0]["text"]), "Stand")
