class_name Deck

const Card = preload("res://scripts/domain/card.gd")


static func create() -> Array:
	var cards: Array = []
	for suit in Card.SUITS:
		for rank in Card.RANKS:
			cards.append({"suit": suit, "rank": rank})
	return cards
