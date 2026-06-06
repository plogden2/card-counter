class_name Strategy

const Hand = preload("res://scripts/domain/hand.gd")

const HARD := {
	8: {2: "hit", 3: "hit", 4: "hit", 5: "hit", 6: "hit", 7: "hit", 8: "hit", 9: "hit", 10: "hit", 11: "hit"},
	9: {2: "hit", 3: "double", 4: "double", 5: "double", 6: "double", 7: "hit", 8: "hit", 9: "hit", 10: "hit", 11: "hit"},
	10: {2: "double", 3: "double", 4: "double", 5: "double", 6: "double", 7: "double", 8: "double", 9: "double", 10: "hit", 11: "hit"},
	11: {2: "double", 3: "double", 4: "double", 5: "double", 6: "double", 7: "double", 8: "double", 9: "double", 10: "double", 11: "hit"},
	12: {2: "hit", 3: "hit", 4: "stand", 5: "stand", 6: "stand", 7: "hit", 8: "hit", 9: "hit", 10: "hit", 11: "hit"},
	13: {2: "stand", 3: "stand", 4: "stand", 5: "stand", 6: "stand", 7: "hit", 8: "hit", 9: "hit", 10: "hit", 11: "hit"},
	14: {2: "stand", 3: "stand", 4: "stand", 5: "stand", 6: "stand", 7: "hit", 8: "hit", 9: "hit", 10: "hit", 11: "hit"},
	15: {2: "stand", 3: "stand", 4: "stand", 5: "stand", 6: "stand", 7: "hit", 8: "hit", 9: "hit", 10: "hit", 11: "hit"},
	16: {2: "stand", 3: "stand", 4: "stand", 5: "stand", 6: "stand", 7: "hit", 8: "hit", 9: "hit", 10: "hit", 11: "hit"},
	17: {2: "stand", 3: "stand", 4: "stand", 5: "stand", 6: "stand", 7: "stand", 8: "stand", 9: "stand", 10: "stand", 11: "stand"},
}

const SOFT := {
	13: {2: "hit", 3: "hit", 4: "hit", 5: "double", 6: "double", 7: "hit", 8: "hit", 9: "hit", 10: "hit", 11: "hit"},
	14: {2: "hit", 3: "hit", 4: "hit", 5: "double", 6: "double", 7: "hit", 8: "hit", 9: "hit", 10: "hit", 11: "hit"},
	15: {2: "hit", 3: "hit", 4: "double", 5: "double", 6: "double", 7: "hit", 8: "hit", 9: "hit", 10: "hit", 11: "hit"},
	16: {2: "hit", 3: "hit", 4: "double", 5: "double", 6: "double", 7: "hit", 8: "hit", 9: "hit", 10: "hit", 11: "hit"},
	17: {2: "hit", 3: "double", 4: "double", 5: "double", 6: "double", 7: "hit", 8: "hit", 9: "hit", 10: "hit", 11: "hit"},
	18: {2: "stand", 3: "double", 4: "double", 5: "double", 6: "double", 7: "stand", 8: "stand", 9: "hit", 10: "hit", 11: "hit"},
	19: {2: "stand", 3: "stand", 4: "stand", 5: "stand", 6: "stand", 7: "stand", 8: "stand", 9: "stand", 10: "stand", 11: "stand"},
}


static func recommend_action(hand: Dictionary, dealer_up: Dictionary, can_double: bool, can_split: bool) -> String:
	var hand_value := Hand.hand_value(hand["cards"])
	var total: int = int(hand_value["total"])
	var soft: bool = bool(hand_value["soft"])
	var dealer := _dealer_up_value(dealer_up)

	if can_split and hand["cards"].size() == 2 and _same_rank(hand["cards"][0]["rank"], hand["cards"][1]["rank"]):
		var pair_rank = hand["cards"][0]["rank"]
		match pair_rank:
			"A", 8:
				return "split"
			10, "J", "Q", "K":
				return "stand"
			9:
				if dealer != 7 and dealer != 10 and dealer != 11:
					return "split"
			7:
				if dealer <= 7:
					return "split"
			6:
				if dealer <= 6:
					return "split"
			4:
				if dealer == 5 or dealer == 6:
					return "split"
			3, 2:
				if dealer <= 7:
					return "split"

	if soft and SOFT.has(total):
		var soft_action = SOFT[total].get(dealer, "stand")
		if soft_action == "double" and not can_double:
			return "hit"
		return soft_action

	var clamped_total: int = mini(17, maxi(8, total))
	var hard_action = HARD[clamped_total].get(dealer, "stand" if total >= 17 else "hit")
	if hard_action == "double" and not can_double:
		return "hit"
	return hard_action


static func _dealer_up_value(dealer_up: Dictionary) -> int:
	var rank = dealer_up["rank"]
	if rank is String and rank == "A":
		return 11
	if rank is int:
		return rank
	return 10


static func _same_rank(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	return a == b
