extends GutTest

const Blackjack = preload("res://scripts/domain/blackjack.gd")
const Rng = preload("res://scripts/lib/rng.gd")
const StayOrLeave = preload("res://scripts/domain/stay_or_leave.gd")


func _session(overrides: Dictionary = {}) -> Dictionary:
	var base: Dictionary = Blackjack.create_session(
		"free-play",
		{"deckCount": 6, "initialOtherPlayers": 0, "handsBeforeReshuffle": 75},
		1000,
		"spread-table",
		Rng.create(1)
	)
	for key in overrides.keys():
		base[key] = overrides[key]
	return base


func test_recommends_staying_at_favorable_counts():
	var result: Dictionary = StayOrLeave.assess_stay_or_leave(_session({
		"countState": {"runningCount": 12, "decksRemaining": 3, "trueCount": 4, "cardsSeen": 100},
		"balance": 1100,
		"sessionStartBalance": 1000,
	}))
	assert_eq(result["recommendation"], "stay")
	assert_gt(result["stayScore"], 0.35)


func test_tracks_low_advantage_streak():
	var result: Dictionary = StayOrLeave.assess_stay_or_leave(_session({
		"countState": {"runningCount": -8, "decksRemaining": 4, "trueCount": -2, "cardsSeen": 50},
		"lowAdvantageStreak": 2,
	}))
	assert_eq(result["lowAdvantageStreak"], 3)


func test_resets_low_advantage_streak_when_count_improves():
	var result: Dictionary = StayOrLeave.assess_stay_or_leave(_session({
		"countState": {"runningCount": 8, "decksRemaining": 2, "trueCount": 4, "cardsSeen": 50},
		"lowAdvantageStreak": 5,
	}))
	assert_eq(result["lowAdvantageStreak"], 0)


func test_penalizes_heavy_drawdown():
	var result: Dictionary = StayOrLeave.assess_stay_or_leave(_session({
		"countState": {"runningCount": 2, "decksRemaining": 4, "trueCount": 0, "cardsSeen": 20},
		"balance": 400,
		"sessionStartBalance": 1000,
	}))
	assert_true(result["factors"].any(func(factor: String) -> bool: return factor.contains("50%")))


func test_flags_proximity_to_reshuffle():
	var result: Dictionary = StayOrLeave.assess_stay_or_leave(_session({
		"shoe": {
			"cards": [],
			"handsDealtSinceShuffle": 70,
			"reshuffleAt": 75,
		},
		"countState": {"runningCount": 1, "decksRemaining": 4, "trueCount": 0, "cardsSeen": 10},
	}))
	assert_true(result["factors"].any(func(factor: String) -> bool: return factor.contains("reshuffle")))


func test_considers_recent_table_dynamics():
	var result: Dictionary = StayOrLeave.assess_stay_or_leave(_session({
		"dynamicsEvents": [
			{"type": "join", "seatId": "dog-1", "handIndex": 4},
			{"type": "leave", "seatId": "dog-2", "handIndex": 5},
		],
		"handsPlayed": 5,
		"countState": {"runningCount": 0, "decksRemaining": 4, "trueCount": 0, "cardsSeen": 10},
	}))
	assert_true(result["factors"].any(func(factor: String) -> bool: return factor.contains("join/leave")))


func test_recommends_leaving_after_sustained_low_advantage():
	var result: Dictionary = StayOrLeave.assess_stay_or_leave(_session({
		"countState": {"runningCount": -10, "decksRemaining": 5, "trueCount": -2, "cardsSeen": 80},
		"lowAdvantageStreak": 3,
		"shoe": {
			"cards": [],
			"handsDealtSinceShuffle": 60,
			"reshuffleAt": 75,
		},
		"balance": 900,
		"sessionStartBalance": 1000,
	}))
	assert_eq(result["recommendation"], "consider-leaving")
	assert_gt(result["factors"].size(), 0)


func test_uses_higher_threshold_for_wonging():
	var result: Dictionary = StayOrLeave.assess_stay_or_leave(_session({
		"currentBetModel": "wonging",
		"countState": {"runningCount": -4, "decksRemaining": 4, "trueCount": -1, "cardsSeen": 10},
	}))
	assert_true(result["factors"].any(func(factor: String) -> bool: return factor.contains("Conservative Wonging")))
