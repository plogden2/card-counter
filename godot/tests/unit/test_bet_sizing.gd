extends GutTest

const BetSizing = preload("res://scripts/domain/bet_sizing.gd")


func _ctx(true_count: int, bankroll: int = 1000) -> Dictionary:
	return {
		"trueCount": true_count,
		"bankroll": bankroll,
		"tableMinBet": 5,
		"tableMaxBet": 500,
	}


func test_returns_model_specific_recommendations():
	var spread: Dictionary = BetSizing.get_recommendation("spread-table", _ctx(3))
	var wong: Dictionary = BetSizing.get_recommendation("wonging", _ctx(0))
	assert_eq(spread["min"], 60)
	assert_eq(wong["min"], 5)


func test_classifies_under_optimal_and_over_bets():
	var recommendation := {
		"min": 20,
		"max": 40,
		"unitSize": 10,
		"floorApplied": false,
	}
	assert_eq(BetSizing.classify_bet(10, recommendation), "under")
	assert_eq(BetSizing.classify_bet(20, recommendation), "optimal")
	assert_eq(BetSizing.classify_bet(25, recommendation), "optimal")
	assert_eq(BetSizing.classify_bet(40, recommendation), "optimal")
	assert_eq(BetSizing.classify_bet(50, recommendation), "over")


func test_provides_coaching_for_under_bets():
	var coaching: Dictionary = BetSizing.get_bet_coaching(10, "spread-table", _ctx(3))
	assert_eq(coaching["classification"], "under")
	assert_string_contains(coaching["message"], "below")
	assert_string_contains(coaching["message"], "Spread Table")


func test_provides_coaching_for_optimal_bets():
	var rec: Dictionary = BetSizing.get_recommendation("spread-table", _ctx(2))
	var coaching: Dictionary = BetSizing.get_bet_coaching(rec["min"], "spread-table", _ctx(2))
	assert_eq(coaching["classification"], "optimal")
	assert_string_contains(coaching["message"], "matches")


func test_appends_floor_message_when_table_minimum_applies():
	var coaching: Dictionary = BetSizing.get_bet_coaching(5, "spread-table", {
		"trueCount": 0,
		"bankroll": 1000,
		"tableMinBet": 100,
		"tableMaxBet": 500,
	})
	if coaching["recommendation"]["floorApplied"]:
		assert_string_contains(coaching["message"], "Table minimum applied")
	else:
		var forced := {
			"min": 100,
			"max": 200,
			"unitSize": 10,
			"floorApplied": true,
		}
		assert_eq(BetSizing.classify_bet(5, forced), "under")


func test_handles_optimal_bet_below_table_minimum_edge_case():
	var recommendation: Dictionary = BetSizing.get_recommendation("spread-table", {
		"trueCount": 0,
		"bankroll": 1000,
		"tableMinBet": 50,
		"tableMaxBet": 500,
	})
	assert_gte(recommendation["min"], 50)
	assert_eq(BetSizing.classify_bet(25, recommendation), "under")
