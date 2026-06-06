class_name Card

const SUITS := ["hearts", "diamonds", "clubs", "spades"]
const RANKS := [2, 3, 4, 5, 6, 7, 8, 9, 10, "J", "Q", "K", "A"]


static func hi_lo_tag(rank: Variant) -> int:
	if rank is int and rank >= 2 and rank <= 6:
		return 1
	if rank is int and (rank == 7 or rank == 8 or rank == 9):
		return 0
	return -1


static func rank_value(rank: Variant) -> int:
	if rank is int:
		return rank
	if rank == "A":
		return 11
	return 10


static func card_equals(a: Dictionary, b: Dictionary) -> bool:
	return a["suit"] == b["suit"] and a["rank"] == b["rank"]


static func is_pair(cards: Array) -> bool:
	return cards.size() == 2 and rank_value(cards[0]["rank"]) == rank_value(cards[1]["rank"])
