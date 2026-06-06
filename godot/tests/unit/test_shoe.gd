extends GutTest

const Rng = preload("res://scripts/lib/rng.gd")


func _shoe():
	return load("res://scripts/domain/shoe.gd")


func test_build_shoe_creates_shuffled_shoe_with_requested_decks():
	var Shoe = _shoe()
	assert_not_null(Shoe)
	var shoe = Shoe.build_shoe(6, Rng.create(42), 75)
	assert_eq(shoe["cards"].size(), 312)
	assert_eq(shoe["handsDealtSinceShuffle"], 0)
	assert_eq(shoe["reshuffleAt"], 75)


func test_draw_takes_cards_from_front_of_shoe():
	var Shoe = _shoe()
	assert_not_null(Shoe)
	var shoe = Shoe.build_shoe(1, Rng.create(1), 30)
	var first_card = shoe["cards"][0]
	var result = Shoe.draw(shoe, 1)
	assert_eq(result["cards"], [first_card])
	assert_eq(result["shoe"]["cards"].size(), 51)


func test_draw_rejects_overdraw_and_returns_no_cards():
	var Shoe = _shoe()
	assert_not_null(Shoe)
	var shoe = Shoe.build_shoe(1, Rng.create(2), 30)
	var result = Shoe.draw(shoe, 53)
	assert_eq(result["cards"], [])
	assert_eq(result["shoe"]["cards"].size(), shoe["cards"].size())


func test_on_hand_settled_increments_hand_counter():
	var Shoe = _shoe()
	assert_not_null(Shoe)
	var shoe = Shoe.build_shoe(1, Rng.create(3), 10)
	var updated = Shoe.on_hand_settled(shoe, 10)
	assert_eq(updated["handsDealtSinceShuffle"], 1)


func test_needs_reshuffle_when_hand_threshold_reached():
	var Shoe = _shoe()
	assert_not_null(Shoe)
	var cards = []
	for _i in 100:
		cards.append({"suit": "hearts", "rank": 2})
	var shoe = {
		"cards": cards,
		"handsDealtSinceShuffle": 75,
		"reshuffleAt": 75,
	}
	assert_true(Shoe.needs_reshuffle(shoe))


func test_needs_reshuffle_when_not_enough_cards_left():
	var Shoe = _shoe()
	assert_not_null(Shoe)
	var shoe = {
		"cards": [{"suit": "hearts", "rank": 2}],
		"handsDealtSinceShuffle": 0,
		"reshuffleAt": 75,
	}
	assert_true(Shoe.needs_reshuffle(shoe, 2))
	assert_false(Shoe.needs_reshuffle(shoe, 1))


func test_reshuffle_resets_cards_and_counter():
	var Shoe = _shoe()
	assert_not_null(Shoe)
	var shoe = Shoe.build_shoe(2, Rng.create(4), 50)
	var dealt = Shoe.on_hand_settled(Shoe.on_hand_settled(shoe, 50), 50)
	var fresh = Shoe.reshuffle(dealt, 2, Rng.create(5))
	assert_eq(fresh["cards"].size(), 104)
	assert_eq(fresh["handsDealtSinceShuffle"], 0)
	assert_eq(fresh["reshuffleAt"], 50)


func test_shoe_exhaustion_edge_case():
	var Shoe = _shoe()
	assert_not_null(Shoe)
	var shoe = Shoe.build_shoe(1, Rng.create(6), 200)
	var result = Shoe.draw(shoe, 52)
	shoe = result["shoe"]
	assert_eq(result["cards"].size(), 52)
	assert_eq(shoe["cards"].size(), 0)
	var exhausted_draw = Shoe.draw(shoe, 1)
	assert_eq(exhausted_draw["cards"], [])
