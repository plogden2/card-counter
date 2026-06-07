class_name CardLayout

const MIN_CARD_SCALE := 0.65
const BASE_CARD_SCALE := 1.0
const LEARNER_SCALE_MULT := 1.15

const _SEAT_ANGLES := {
	"learner": 0.0,
	"dealer": PI,
	"seat-0": -1.2,
	"seat-1": -0.6,
	"seat-2": 0.6,
	"seat-3": 1.2,
}


static func build(session: Dictionary) -> Dictionary:
	if session.is_empty():
		return {"seats": [], "shoeRemaining": 0}

	var seats_out: Array = []
	var all_seats: Array = session.get("seats", [])
	var dealer_cards: Array = session.get("dealerCards", [])
	var shoe_remaining: int = int(session.get("shoe", {}).get("cards", []).size())

	seats_out.append(_build_seat_view("dealer", dealer_cards, false))

	for seat in all_seats:
		var seat_id: String = str(seat.get("id", ""))
		var is_learner: bool = bool(seat.get("isLearner", false))
		var hands: Array = seat.get("hands", [])
		if hands.is_empty():
			continue
		var hand_index: int = int(session.get("activeHandIndex", 0)) if is_learner else 0
		hand_index = clampi(hand_index, 0, hands.size() - 1)
		var hand: Dictionary = hands[hand_index]
		var cards: Array = hand.get("cards", [])
		seats_out.append(_build_seat_view(seat_id, cards, is_learner))

	return {
		"seats": seats_out,
		"shoeRemaining": shoe_remaining,
	}


static func fan_angle_for_index(index: int, total: int, seat_id: String) -> float:
	if total <= 1:
		return 0.0
	var spread := 0.18
	var mid := float(total - 1) * 0.5
	return (float(index) - mid) * spread


static func scale_for_card_count(count: int, is_learner: bool) -> float:
	var base := BASE_CARD_SCALE
	if is_learner:
		base *= LEARNER_SCALE_MULT
	if count <= 2:
		return base
	var shrink := 1.0 - float(count - 2) * 0.06
	return maxf(MIN_CARD_SCALE, base * shrink)


static func seat_yaw(seat_id: String, is_learner: bool) -> float:
	if is_learner:
		return _SEAT_ANGLES.get("learner", 0.0)
	return _SEAT_ANGLES.get(seat_id, 0.0)


static func _build_seat_view(seat_id: String, cards: Array, is_learner: bool) -> Dictionary:
	var card_views: Array = []
	var seat_scale := scale_for_card_count(cards.size(), is_learner)
	for i in cards.size():
		var card: Dictionary = cards[i]
		card_views.append({
			"rank": card.get("rank", "?"),
			"suit": card.get("suit", "?"),
			"faceUp": bool(card.get("faceUp", true)),
			"fanAngle": fan_angle_for_index(i, cards.size(), seat_id),
			"index": i,
		})
	return {
		"seatId": seat_id,
		"isLearner": is_learner,
		"cards": card_views,
		"scale": seat_scale,
		"yaw": seat_yaw(seat_id, is_learner),
	}
