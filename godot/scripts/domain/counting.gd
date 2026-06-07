class_name Counting

const Card = preload("res://scripts/domain/card.gd")


static func create_count_state(cards_remaining: int) -> Dictionary:
	var decks_remaining: float = max(float(cards_remaining) / 52.0, 0.5)
	return {
		"runningCount": 0,
		"decksRemaining": decks_remaining,
		"trueCount": 0,
		"cardsSeen": 0,
	}


static func true_count(running: int, decks_remaining: float) -> int:
	var decks: float = max(decks_remaining, 0.5)
	return int(floor(float(running) / decks))


static func update_count(state: Dictionary, cards: Array, cards_remaining: int) -> Dictionary:
	var running: int = int(state["runningCount"])
	for card in cards:
		running += Card.hi_lo_tag(card["rank"])
	var decks_remaining: float = max(float(cards_remaining) / 52.0, 0.5)
	return {
		"runningCount": running,
		"decksRemaining": decks_remaining,
		"trueCount": true_count(running, decks_remaining),
		"cardsSeen": int(state["cardsSeen"]) + cards.size(),
	}
