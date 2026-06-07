class_name ActionMenu

const KEYBOARD_MAP := {
	"hit": "H",
	"stand": "S",
	"double": "D",
	"split": "P",
	"insurance-accept": "I",
	"insurance-decline": "N",
	"place-bet": "Enter",
	"deal": "Enter",
	"continue": "Enter",
	"home": "Escape",
}


static func visible_actions(session: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if session.is_empty():
		result.append("home")
		return result

	var phase: String = str(session.get("phase", "betting"))
	match phase:
		"betting":
			result.append_array(["place-bet", "deal"])
		"insurance":
			result.append_array(["insurance-accept", "insurance-decline"])
		"player-turn":
			var learner_hand := _get_learner_hand(session)
			result.append_array(_legal_player_actions(session, learner_hand))
		"settled":
			result.append("continue")
	result.append("home")
	return result


static func keyboard_bindings(visible: Array[String]) -> Dictionary:
	var bindings := {}
	for action in visible:
		if KEYBOARD_MAP.has(action):
			bindings[KEYBOARD_MAP[action]] = action
	return bindings


static func _legal_player_actions(session: Dictionary, hand: Dictionary) -> Array[String]:
	if hand.is_empty():
		return []
	var actions: Array[String] = ["hit", "stand"]
	var cards: Array = hand.get("cards", [])
	var status: String = str(hand.get("status", "active"))
	if cards.size() == 2 and status == "active":
		if not bool(hand.get("doubled", false)):
			actions.append("double")
		if not bool(hand.get("isSplit", false)):
			var rank_a: Variant = cards[0].get("rank", "")
			var rank_b: Variant = cards[1].get("rank", "")
			if rank_a == rank_b:
				actions.append("split")
	return actions


static func _get_learner_hand(session: Dictionary) -> Dictionary:
	var seats: Array = session.get("seats", [])
	for seat in seats:
		if bool(seat.get("isLearner", false)):
			var hands: Array = seat.get("hands", [])
			if hands.is_empty():
				return {}
			var hand_index: int = int(session.get("activeHandIndex", 0))
			hand_index = clampi(hand_index, 0, hands.size() - 1)
			return hands[hand_index]
	return {}
