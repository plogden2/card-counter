class_name Shoe

const Deck = preload("res://scripts/domain/deck.gd")
const Rng = preload("res://scripts/lib/rng.gd")


static func build_shoe(deck_count: int, rng: Rng, reshuffle_at: int = 75) -> Dictionary:
	var cards := _shuffle_decks(deck_count, rng)
	return {
		"cards": cards,
		"handsDealtSinceShuffle": 0,
		"reshuffleAt": reshuffle_at,
	}


static func draw(shoe: Dictionary, n: int) -> Dictionary:
	var cards: Array = shoe["cards"]
	if n > cards.size():
		push_error("Insufficient cards in shoe")
		return {"shoe": shoe, "cards": []}
	var drawn := cards.slice(0, n)
	return {
		"shoe": {
			"cards": cards.slice(n),
			"handsDealtSinceShuffle": shoe["handsDealtSinceShuffle"],
			"reshuffleAt": shoe["reshuffleAt"],
		},
		"cards": drawn,
	}


static func on_hand_settled(shoe: Dictionary, reshuffle_at: int) -> Dictionary:
	return {
		"cards": shoe["cards"],
		"handsDealtSinceShuffle": int(shoe["handsDealtSinceShuffle"]) + 1,
		"reshuffleAt": reshuffle_at,
	}


static func needs_reshuffle(shoe: Dictionary, cards_needed: int = 1) -> bool:
	return (
		int(shoe["handsDealtSinceShuffle"]) >= int(shoe["reshuffleAt"])
		or shoe["cards"].size() < cards_needed
	)


static func reshuffle(shoe: Dictionary, deck_count: int, rng: Rng) -> Dictionary:
	return {
		"cards": _shuffle_decks(deck_count, rng),
		"handsDealtSinceShuffle": 0,
		"reshuffleAt": shoe["reshuffleAt"],
	}


static func _shuffle_decks(deck_count: int, rng: Rng) -> Array:
	var cards: Array = []
	for _i in deck_count:
		cards.append_array(Deck.create())
	return Rng.shuffle(cards, rng)
