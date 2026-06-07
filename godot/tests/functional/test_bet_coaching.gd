extends GutTest

const BetSizing = preload("res://scripts/domain/bet_sizing.gd")
const CoachingCopy = preload("res://scripts/tutorial/coaching_copy.gd")
const CoachingCue = preload("res://scripts/presentation/coaching_cue.gd")


func _ctx(true_count: int) -> Dictionary:
	return {
		"trueCount": true_count,
		"bankroll": 1000,
		"tableMinBet": 5,
		"tableMaxBet": 500,
	}


func test_maps_under_classification_to_headline():
	var coaching: Dictionary = BetSizing.get_bet_coaching(10, "spread-table", _ctx(3))
	var headline: String = CoachingCopy.bet_coaching_headline(coaching["classification"])
	assert_eq(coaching["classification"], "under")
	assert_eq(headline, "Under-bet detected")


func test_maps_optimal_classification_to_headline():
	var recommendation: Dictionary = BetSizing.get_recommendation("spread-table", _ctx(2))
	var coaching: Dictionary = BetSizing.get_bet_coaching(recommendation["min"], "spread-table", _ctx(2))
	var headline: String = CoachingCopy.bet_coaching_headline(coaching["classification"])
	assert_eq(coaching["classification"], "optimal")
	assert_eq(headline, "Optimal bet")


func test_generates_stay_or_leave_copy():
	var stay_message: String = CoachingCopy.stay_or_leave_message({
		"recommendation": "stay",
		"factors": [],
	})
	assert_eq(stay_message, "Conditions favor staying at the table.")

	var leave_message: String = CoachingCopy.stay_or_leave_message({
		"recommendation": "consider-leaving",
		"factors": [
			"True count -2 yields low estimated advantage",
			"Only 3 hands until reshuffle",
			"Recent player join/leave changes table pace",
			"Balance below 50% of session start",
		],
	})
	assert_string_contains(leave_message, "Consider leaving:")
	assert_string_contains(leave_message, "True count -2")


func test_tutorial_betting_highlights_place_bet():
	var session := {"phase": "betting", "seats": []}
	assert_eq(CoachingCue.highlight_action(session, "tutorial"), "place-bet")


func test_tutorial_betting_does_not_highlight_deal():
	var session := {"phase": "betting", "seats": []}
	var highlight := CoachingCue.highlight_action(session, "tutorial")
	assert_ne(highlight, "deal")
	assert_true(highlight != "")


func test_free_play_betting_has_no_coaching_highlight():
	var session := {"phase": "betting", "seats": []}
	assert_eq(CoachingCue.highlight_action(session, "free-play"), "")


func test_bet_coaching_classification_maps_to_highlight_eligible_phase():
	var session := {"phase": "betting", "seats": []}
	var highlight := CoachingCue.highlight_action(session, "tutorial")
	var coaching: Dictionary = BetSizing.get_bet_coaching(10, "spread-table", _ctx(3))
	assert_eq(highlight, "place-bet")
	assert_eq(coaching["classification"], "under")
	assert_eq(CoachingCopy.bet_coaching_headline(coaching["classification"]), "Under-bet detected")
