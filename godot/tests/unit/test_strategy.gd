extends GutTest

const Strategy = preload("res://scripts/domain/strategy.gd")


func _card(rank: Variant) -> Dictionary:
	return {"suit": "hearts", "rank": rank}


func _hand(cards: Array) -> Dictionary:
	return {
		"cards": cards,
		"wager": 10,
		"status": "active",
		"isSplit": false,
		"ownerSeatId": "learner",
	}


func test_stands_on_hard_17_vs_dealer_10():
	assert_eq(Strategy.recommend_action(_hand([_card(10), _card(7)]), _card(10), true, true), "stand")


func test_hits_hard_16_vs_dealer_10():
	assert_eq(Strategy.recommend_action(_hand([_card(10), _card(6)]), _card(10), true, true), "hit")


func test_doubles_hard_11_vs_dealer_6():
	assert_eq(Strategy.recommend_action(_hand([_card(7), _card(4)]), _card(6), true, true), "double")


func test_splits_aces_and_8s():
	assert_eq(Strategy.recommend_action(_hand([_card("A"), _card("A")]), _card(6), true, true), "split")
	assert_eq(Strategy.recommend_action(_hand([_card(8), _card(8)]), _card(10), true, true), "split")


func test_stands_on_ten_value_pairs():
	assert_eq(Strategy.recommend_action(_hand([_card(10), _card("K")]), _card(6), true, true), "stand")


func test_splits_2s_through_7s_vs_weak_dealer_cards():
	assert_eq(Strategy.recommend_action(_hand([_card(2), _card(2)]), _card(6), true, true), "split")
	assert_eq(Strategy.recommend_action(_hand([_card(6), _card(6)]), _card(6), true, true), "split")


func test_doubles_soft_17_vs_dealer_6():
	assert_eq(Strategy.recommend_action(_hand([_card("A"), _card(6)]), _card(6), true, true), "double")


func test_stands_soft_19_vs_dealer_6():
	assert_eq(Strategy.recommend_action(_hand([_card("A"), _card(8)]), _card(6), true, true), "stand")


func test_hits_hard_8_vs_any_dealer_up_card():
	assert_eq(Strategy.recommend_action(_hand([_card(3), _card(5)]), _card(2), true, true), "hit")
