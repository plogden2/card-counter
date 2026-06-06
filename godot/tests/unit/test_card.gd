extends GutTest

const Card = preload("res://scripts/domain/card.gd")
const Deck = preload("res://scripts/domain/deck.gd")


func test_hi_lo_tag_low_cards_are_positive_one():
	for rank in [2, 3, 4, 5, 6]:
		assert_eq(Card.hi_lo_tag(rank), 1)


func test_hi_lo_tag_neutral_cards_are_zero():
	assert_eq(Card.hi_lo_tag(7), 0)
	assert_eq(Card.hi_lo_tag(8), 0)
	assert_eq(Card.hi_lo_tag(9), 0)


func test_hi_lo_tag_high_cards_are_negative_one():
	assert_eq(Card.hi_lo_tag(10), -1)
	assert_eq(Card.hi_lo_tag("J"), -1)
	assert_eq(Card.hi_lo_tag("Q"), -1)
	assert_eq(Card.hi_lo_tag("K"), -1)
	assert_eq(Card.hi_lo_tag("A"), -1)


func test_create_deck_has_standard_52_cards():
	var deck := Deck.create()
	assert_eq(deck.size(), 52)
	var suits := {}
	for card in deck:
		suits[card["suit"]] = true
	assert_eq(suits.size(), 4)


func test_card_equals_matches_same_rank_and_suit():
	var a := {"suit": "hearts", "rank": "A"}
	var b := {"suit": "hearts", "rank": "A"}
	assert_true(Card.card_equals(a, b))


func test_card_equals_rejects_different_rank_or_suit():
	assert_false(Card.card_equals({"suit": "hearts", "rank": "A"}, {"suit": "spades", "rank": "A"}))
	assert_false(Card.card_equals({"suit": "hearts", "rank": "A"}, {"suit": "hearts", "rank": "K"}))


func test_rank_value_for_number_cards():
	assert_eq(Card.rank_value(7), 7)


func test_rank_value_for_face_cards_and_ace():
	assert_eq(Card.rank_value("J"), 10)
	assert_eq(Card.rank_value("Q"), 10)
	assert_eq(Card.rank_value("K"), 10)
	assert_eq(Card.rank_value("A"), 11)


func test_is_pair_detects_matching_two_card_hands():
	var cards := [
		{"suit": "hearts", "rank": "K"},
		{"suit": "spades", "rank": "K"},
	]
	assert_true(Card.is_pair(cards))


func test_is_pair_treats_ten_and_face_as_pairable():
	var cards := [
		{"suit": "hearts", "rank": 10},
		{"suit": "spades", "rank": "Q"},
	]
	assert_true(Card.is_pair(cards))


func test_is_pair_rejects_non_pairs():
	assert_false(Card.is_pair([{"suit": "hearts", "rank": 5}, {"suit": "spades", "rank": 9}]))
	assert_false(Card.is_pair([{"suit": "hearts", "rank": 5}]))
