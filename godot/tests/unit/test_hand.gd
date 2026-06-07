extends GutTest

const Hand = preload("res://scripts/domain/hand.gd")


func _card(rank: Variant) -> Dictionary:
	return {"suit": "hearts", "rank": rank}


func _active_hand(cards: Array, overrides: Dictionary = {}) -> Dictionary:
	var hand := {
		"cards": cards,
		"wager": 10,
		"status": "active",
		"isSplit": false,
		"ownerSeatId": "learner",
	}
	for key in overrides.keys():
		hand[key] = overrides[key]
	return hand


func test_values_hard_totals():
	assert_eq(Hand.hand_value([_card(10), _card(7)]), {"total": 17, "soft": false})


func test_values_soft_hands_with_ace_as_eleven():
	assert_eq(Hand.hand_value([_card("A"), _card(6)]), {"total": 17, "soft": true})


func test_downgrades_aces_when_busting():
	assert_eq(Hand.hand_value([_card("A"), _card("A"), _card(9)]), {"total": 21, "soft": true})
	assert_eq(Hand.hand_value([_card("A"), _card(9), _card(5)]), {"total": 15, "soft": false})


func test_handles_multiple_aces_without_busting():
	assert_eq(Hand.hand_value([_card("A"), _card("A"), _card("A")])["total"], 13)


func test_detects_blackjack_on_two_card_twenty_one():
	assert_true(Hand.is_blackjack([_card("A"), _card("K")]))
	assert_false(Hand.is_blackjack([_card("A"), _card(9), _card(2)]))


func test_allows_split_on_matching_pairs_when_active():
	assert_true(Hand.can_split(_active_hand([_card(8), _card(8)])))
	assert_false(Hand.can_split(_active_hand([_card(8), _card(8)], {"isSplit": true})))
	assert_false(Hand.can_split(_active_hand([_card(8), _card(8)], {"status": "stood"})))


func test_allows_double_on_two_card_active_hands():
	assert_true(Hand.can_double(_active_hand([_card(9), _card(2)])))
	assert_false(Hand.can_double(_active_hand([_card(9), _card(2), _card(10)])))
	assert_false(Hand.can_double(_active_hand([_card(9), _card(2)], {"doubled": true})))


func test_bust_edge_case_hard_twenty_two_plus():
	assert_eq(Hand.hand_value([_card(10), _card(9), _card(5)])["total"], 24)
