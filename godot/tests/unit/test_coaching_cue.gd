extends GutTest

const CoachingCue = preload("res://scripts/presentation/coaching_cue.gd")
const GameControllerScript = preload("res://scripts/game/game_controller.gd")
const LearnerProfile = preload("res://scripts/persistence/learner_profile.gd")


func before_each() -> void:
	LearnerProfile.clear_profile_for_tests()


func test_no_highlight_in_free_play():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	assert_eq(CoachingCue.highlight_action(controller.call("get_session"), "free-play"), "")


func test_tutorial_betting_recommends_place_bet():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_tutorial_table")
	assert_eq(CoachingCue.highlight_action(controller.call("get_session"), "tutorial"), "place-bet")


func test_count_tag_values():
	assert_eq(CoachingCue.count_tag_value(5), 1)
	assert_eq(CoachingCue.count_tag_value(8), 0)
	assert_eq(CoachingCue.count_tag_value("K"), -1)


func test_single_legal_action_still_highlights_in_tutorial():
	var session := {
		"phase": "insurance",
		"seats": [],
	}
	assert_eq(CoachingCue.highlight_action(session, "tutorial"), "insurance-decline")


func test_post_choice_feedback_for_suboptimal_action():
	var session := {
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
	assert_eq(CoachingCue.highlight_action(session, "tutorial"), "hit")
	var feedback := CoachingCue.post_choice_feedback(session, "tutorial", "stand")
	assert_string_contains(feedback, "Stand")
	assert_string_contains(feedback, "Hit")


func test_post_choice_feedback_skipped_for_recommended_action():
	var session := {
		"phase": "betting",
		"seats": [],
	}
	assert_eq(CoachingCue.post_choice_feedback(session, "tutorial", "place-bet"), "")
