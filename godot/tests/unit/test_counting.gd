extends GutTest

const Counting = preload("res://scripts/domain/counting.gd")


func _card(rank: Variant) -> Dictionary:
	return {"suit": "hearts", "rank": rank}


func test_initializes_count_state_from_cards_remaining():
	var state = Counting.create_count_state(312)
	assert_eq(state["runningCount"], 0)
	assert_eq(state["trueCount"], 0)
	assert_eq(state["cardsSeen"], 0)
	assert_eq(state["decksRemaining"], 6.0)


func test_floors_decks_remaining_at_minimum_half():
	assert_eq(Counting.true_count(5, 0.1), 10)
	var state = Counting.create_count_state(10)
	assert_eq(state["decksRemaining"], 0.5)


func test_true_count_uses_floor_division():
	assert_eq(Counting.true_count(7, 3.5), 2)
	assert_eq(Counting.true_count(-4, 2), -2)


func test_updates_running_count_from_dealt_cards():
	var initial = Counting.create_count_state(312)
	var cards: Array = [_card(5), _card("K"), _card(3), _card(9)]
	var updated = Counting.update_count(initial, cards, 300)
	assert_eq(updated["runningCount"], 1)
	assert_eq(updated["cardsSeen"], 4)
	assert_eq(updated["trueCount"], int(floor(float(updated["runningCount"]) / float(updated["decksRemaining"]))))


func test_counts_visible_cards_from_multiple_seats():
	var state = Counting.create_count_state(312)
	var seat1: Array = [_card(2), _card("A")]
	var seat2: Array = [_card(6), _card("Q")]
	var dealer_up: Array = [_card(4)]
	var visible_cards: Array = []
	visible_cards.append_array(seat1)
	visible_cards.append_array(seat2)
	visible_cards.append_array(dealer_up)
	state = Counting.update_count(state, visible_cards, 300)
	assert_eq(state["runningCount"], 1)
	assert_eq(state["cardsSeen"], 5)


func test_accumulates_count_across_multiple_updates():
	var state = Counting.create_count_state(312)
	state = Counting.update_count(state, [_card(2), _card(3)], 308)
	state = Counting.update_count(state, [_card("K"), _card("A")], 304)
	assert_eq(state["runningCount"], 0)
	assert_eq(state["cardsSeen"], 4)
