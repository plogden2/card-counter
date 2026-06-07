class_name Hand

const Card = preload("res://scripts/domain/card.gd")


static func hand_value(cards: Array) -> Dictionary:
	var total := 0
	var aces := 0
	for card in cards:
		var rank: Variant = card["rank"]
		if rank is String and rank == "A":
			aces += 1
			total += 11
		else:
			total += Card.rank_value(rank)
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	var soft := aces > 0 and total <= 21
	return {"total": total, "soft": soft}


static func is_blackjack(cards: Array) -> bool:
	return cards.size() == 2 and hand_value(cards)["total"] == 21


static func can_split(hand: Dictionary) -> bool:
	return (
		hand["cards"].size() == 2
		and hand["isSplit"] == false
		and Card.rank_value(hand["cards"][0]["rank"]) == Card.rank_value(hand["cards"][1]["rank"])
		and hand["status"] == "active"
	)


static func can_double(hand: Dictionary) -> bool:
	var doubled: bool = bool(hand.get("doubled", false))
	return hand["cards"].size() == 2 and hand["status"] == "active" and doubled == false
