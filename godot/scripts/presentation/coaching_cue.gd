class_name CoachingCue

const ActionMenu = preload("res://scripts/presentation/action_menu.gd")
const CoachingCopy = preload("res://scripts/tutorial/coaching_copy.gd")
const Strategy = preload("res://scripts/domain/strategy.gd")


static func highlight_action(session: Dictionary, mode: String) -> String:
	if mode != "tutorial":
		return ""
	if session.is_empty():
		return ""

	var phase: String = str(session.get("phase", "betting"))
	if phase == "betting":
		return "place-bet"
	if phase == "insurance":
		return "insurance-decline"
	if phase != "player-turn":
		return ""

	var learner_hand := _get_learner_hand(session)
	if learner_hand.is_empty():
		return ""

	var dealer_cards: Array = session.get("dealerCards", [])
	if dealer_cards.is_empty():
		return ""
	var dealer_up: Dictionary = dealer_cards[0]
	var cards: Array = learner_hand.get("cards", [])
	var can_double := cards.size() == 2 and not bool(learner_hand.get("doubled", false))
	var can_split := cards.size() == 2 and not bool(learner_hand.get("isSplit", false))
	return Strategy.recommend_action(learner_hand, dealer_up, can_double, can_split)


static func post_choice_feedback(session: Dictionary, mode: String, chosen_action: String) -> String:
	if mode != "tutorial":
		return ""
	if chosen_action in ["home", "continue"]:
		return ""
	var recommended := highlight_action(session, mode)
	if recommended == "" or chosen_action == recommended:
		return ""
	var visible: Array[String] = ActionMenu.visible_actions(session)
	if not visible.has(chosen_action):
		return ""
	return CoachingCopy.action_choice_feedback(chosen_action, recommended)


static func should_show_count_tags(mode: String) -> bool:
	return mode == "tutorial"


static func count_tag_value(rank: Variant) -> int:
	if rank is String:
		if rank == "A":
			return -1
		if rank == "J" or rank == "Q" or rank == "K":
			return -1
		return 0
	if rank is int:
		if rank >= 2 and rank <= 6:
			return 1
		if rank >= 7 and rank <= 9:
			return 0
		return -1
	return 0


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
