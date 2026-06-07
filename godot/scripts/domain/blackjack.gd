class_name Blackjack

const Counting = preload("res://scripts/domain/counting.gd")
const Hand = preload("res://scripts/domain/hand.gd")
const Session = preload("res://scripts/domain/session.gd")
const Shoe = preload("res://scripts/domain/shoe.gd")
const TableConfig = preload("res://scripts/domain/table_config.gd")
const Rng = preload("res://scripts/lib/rng.gd")


static func create_session(mode: String, config: Dictionary, balance: int = TableConfig.STARTING_BANKROLL, bet_model: String = "spread-table", rng: Rng = null) -> Dictionary:
	var use_rng: Rng = rng if rng != null else Rng.create(1)
	var table_configuration: Dictionary = TableConfig.validate(config)
	var shoe: Dictionary = Shoe.build_shoe(table_configuration["deckCount"], use_rng, table_configuration["handsBeforeReshuffle"])
	var seats: Array = [Session.create_seat("learner", true, "learner-dog")]
	for i in int(table_configuration["initialOtherPlayers"]):
		seats.append(Session.create_seat("dog-%d" % (i + 1), false, "breed-%d" % (i + 1)))
	return {
		"mode": mode,
		"tableConfiguration": table_configuration,
		"shoe": shoe,
		"seats": seats,
		"dealerCards": [],
		"dealerHoleHidden": true,
		"countState": Counting.create_count_state(shoe["cards"].size()),
		"balance": balance,
		"sessionStartBalance": balance,
		"analytics": [],
		"currentBetModel": bet_model,
		"handsPlayed": 0,
		"dynamicsEvents": [],
		"phase": "betting",
		"activeSeatId": "learner",
		"activeHandIndex": 0,
		"currentWager": 0,
		"lowAdvantageStreak": 0,
	}


static func place_bet(session: Dictionary, wager: int) -> Dictionary:
	if session["phase"] != "betting":
		push_error("Cannot place bet outside betting phase")
		return session
	var table_configuration: Dictionary = session["tableConfiguration"]
	var max_wager: int = mini(int(session["balance"]), int(table_configuration["tableMaxBet"]))
	var clamped: int = maxi(int(table_configuration["tableMinBet"]), mini(wager, max_wager))
	var next: Dictionary = session.duplicate(true)
	next["currentWager"] = clamped
	return next


static func deal_initial(session: Dictionary, rng: Rng) -> Dictionary:
	if int(session["currentWager"]) < int(session["tableConfiguration"]["tableMinBet"]):
		push_error("Must place bet before dealing")
		return session

	var state: Dictionary = session.duplicate(true)
	var shoe: Dictionary = state["shoe"]
	var cards_needed: int = state["seats"].size() * 2 + 2
	if Shoe.needs_reshuffle(shoe, cards_needed):
		shoe = Shoe.reshuffle(shoe, state["tableConfiguration"]["deckCount"], rng)
		state["countState"] = Counting.create_count_state(shoe["cards"].size())

	var seats: Array = []
	for seat in state["seats"]:
		var hand := {
			"cards": [],
			"wager": int(state["currentWager"]) if seat["isLearner"] else int(state["tableConfiguration"]["tableMinBet"]),
			"status": "active",
			"isSplit": false,
			"ownerSeatId": seat["id"],
		}
		seats.append({
			"id": seat["id"],
			"isLearner": seat["isLearner"],
			"dogBreed": seat["dogBreed"],
			"hands": [hand],
		})

	var dealer_cards: Array = []
	for round in 2:
		for seat in seats:
			var draw_result: Dictionary = Shoe.draw(shoe, 1)
			shoe = draw_result["shoe"]
			seat["hands"][0]["cards"].append(draw_result["cards"][0])
		var dealer_draw: Dictionary = Shoe.draw(shoe, 1)
		shoe = dealer_draw["shoe"]
		dealer_cards.append(dealer_draw["cards"][0])

	var visible_cards: Array = []
	for seat in seats:
		visible_cards.append_array(seat["hands"][0]["cards"])
	visible_cards.append(dealer_cards[0])

	state["shoe"] = shoe
	state["seats"] = seats
	state["dealerCards"] = dealer_cards
	state["dealerHoleHidden"] = true
	state["countState"] = Counting.update_count(state["countState"], visible_cards, shoe["cards"].size())
	state["activeSeatId"] = "learner"
	state["activeHandIndex"] = 0
	state["phase"] = "insurance" if (dealer_cards[0]["rank"] is String and dealer_cards[0]["rank"] == "A") else "player-turn"
	return state


static func apply_action(session: Dictionary, seat_id: String, action: String, rng: Rng) -> Dictionary:
	var state: Dictionary = session.duplicate(true)

	if action == "insurance-accept" or action == "insurance-decline":
		return _handle_insurance(state, seat_id, action)

	if state["phase"] != "player-turn":
		push_error("Cannot apply %s in phase %s" % [action, state["phase"]])
		return state

	var seat_index: int = _find_seat_index(state["seats"], seat_id)
	if seat_index == -1:
		push_error("Seat not found")
		return state

	var active_hand_index: int = int(state["activeHandIndex"])
	var hand: Dictionary = state["seats"][seat_index]["hands"][active_hand_index]
	if hand["status"] != "active":
		push_error("No active hand")
		return state

	match action:
		"hit":
			state = _hit(state, seat_index, active_hand_index)
		"stand":
			state["seats"][seat_index]["hands"][active_hand_index]["status"] = "stood"
		"double":
			if not Hand.can_double(hand):
				push_error("Cannot double")
				return state
			state = _double_down(state, seat_index, active_hand_index)
		"split":
			if not Hand.can_split(hand):
				push_error("Cannot split")
				return state
			state = _split_hand(state, seat_index, active_hand_index)
		_:
			push_error("Unknown action")
			return state

	state = _advance_turn(state)
	if state["phase"] == "dealer-turn":
		state = _play_dealer(state)
		state = settle_hand(state)
	return state


static func settle_hand(session: Dictionary) -> Dictionary:
	var state: Dictionary = session.duplicate(true)
	var dealer_total: int = int(Hand.hand_value(state["dealerCards"])["total"])
	var dealer_blackjack: bool = Hand.is_blackjack(state["dealerCards"]) and state["dealerCards"].size() == 2
	var balance: int = int(state["balance"])

	for seat in state["seats"]:
		for hand in seat["hands"]:
			if hand["status"] == "bust":
				balance -= int(hand["wager"])
				continue

			var player_total: int = int(Hand.hand_value(hand["cards"])["total"])
			var player_blackjack: bool = Hand.is_blackjack(hand["cards"]) and hand["cards"].size() == 2 and not bool(hand["isSplit"])

			if dealer_blackjack:
				if not player_blackjack:
					balance -= int(hand["wager"])
			elif player_blackjack:
				balance += int(floor(float(hand["wager"]) * 1.5))
			elif player_total > dealer_total or dealer_total > 21:
				balance += int(hand["wager"])
			elif player_total < dealer_total:
				balance -= int(hand["wager"])

	state["balance"] = balance
	state["shoe"] = Shoe.on_hand_settled(state["shoe"], state["tableConfiguration"]["handsBeforeReshuffle"])
	state["phase"] = "settled"
	state["handsPlayed"] = int(state["handsPlayed"]) + 1
	state["dealerHoleHidden"] = false
	return state


static func hand_value(cards: Array) -> Dictionary:
	return Hand.hand_value(cards)


static func _handle_insurance(session: Dictionary, seat_id: String, action: String) -> Dictionary:
	var state: Dictionary = session.duplicate(true)
	if state["phase"] != "insurance":
		push_error("Insurance not offered")
		return state
	if not (state["dealerCards"][0]["rank"] is String and state["dealerCards"][0]["rank"] == "A"):
		push_error("Insurance only when dealer shows Ace")
		return state

	var seat_index: int = _find_seat_index(state["seats"], seat_id)
	if seat_index == -1:
		push_error("Seat not found")
		return state
	if action == "insurance-accept":
		var insurance_wager: int = int(floor(float(state["seats"][seat_index]["hands"][0]["wager"]) / 2.0))
		state["seats"][seat_index]["hands"][0]["insuranceWager"] = insurance_wager

	if Hand.is_blackjack(state["dealerCards"]):
		var hand: Dictionary = state["seats"][seat_index]["hands"][0]
		if hand.has("insuranceWager"):
			state["balance"] = int(state["balance"]) + int(hand["insuranceWager"]) * 2
		if Hand.is_blackjack(hand["cards"]):
			state["balance"] = int(state["balance"]) + int(floor(float(hand["wager"]) * 2.5))
		else:
			state["balance"] = int(state["balance"]) - int(hand["wager"])
		state["shoe"] = Shoe.on_hand_settled(state["shoe"], state["tableConfiguration"]["handsBeforeReshuffle"])
		state["countState"] = Counting.update_count(state["countState"], [state["dealerCards"][1]], state["shoe"]["cards"].size())
		state["phase"] = "settled"
		state["handsPlayed"] = int(state["handsPlayed"]) + 1
		state["dealerHoleHidden"] = false
		return state

	state["phase"] = "player-turn"
	state["activeSeatId"] = seat_id
	state["activeHandIndex"] = 0
	return state


static func _hit(session: Dictionary, seat_index: int, hand_index: int) -> Dictionary:
	var state: Dictionary = session
	var draw_result: Dictionary = Shoe.draw(state["shoe"], 1)
	state["shoe"] = draw_result["shoe"]
	var card: Dictionary = draw_result["cards"][0]
	state["seats"][seat_index]["hands"][hand_index]["cards"].append(card)
	state["countState"] = Counting.update_count(state["countState"], [card], state["shoe"]["cards"].size())
	var total: int = int(Hand.hand_value(state["seats"][seat_index]["hands"][hand_index]["cards"])["total"])
	if total > 21:
		state["seats"][seat_index]["hands"][hand_index]["status"] = "bust"
	return state


static func _double_down(session: Dictionary, seat_index: int, hand_index: int) -> Dictionary:
	var state: Dictionary = session
	var hand: Dictionary = state["seats"][seat_index]["hands"][hand_index]
	state["balance"] = int(state["balance"]) - int(hand["wager"])
	hand["wager"] = int(hand["wager"]) * 2
	hand["doubled"] = true
	state["seats"][seat_index]["hands"][hand_index] = hand
	state = _hit(state, seat_index, hand_index)
	if state["seats"][seat_index]["hands"][hand_index]["status"] == "active":
		state["seats"][seat_index]["hands"][hand_index]["status"] = "stood"
	return state


static func _split_hand(session: Dictionary, seat_index: int, hand_index: int) -> Dictionary:
	var state: Dictionary = session
	var hand: Dictionary = state["seats"][seat_index]["hands"][hand_index]
	if state["seats"][seat_index]["hands"].size() >= 4:
		push_error("Max splits reached")
		return state

	state["balance"] = int(state["balance"]) - int(hand["wager"])

	var hand1 := {
		"cards": [hand["cards"][0]],
		"wager": hand["wager"],
		"status": "active",
		"isSplit": true,
		"ownerSeatId": state["seats"][seat_index]["id"],
	}
	var hand2 := {
		"cards": [hand["cards"][1]],
		"wager": hand["wager"],
		"status": "active",
		"isSplit": true,
		"ownerSeatId": state["seats"][seat_index]["id"],
	}

	var draw1: Dictionary = Shoe.draw(state["shoe"], 1)
	state["shoe"] = draw1["shoe"]
	hand1["cards"].append(draw1["cards"][0])
	state["countState"] = Counting.update_count(state["countState"], draw1["cards"], state["shoe"]["cards"].size())

	var draw2: Dictionary = Shoe.draw(state["shoe"], 1)
	state["shoe"] = draw2["shoe"]
	hand2["cards"].append(draw2["cards"][0])
	state["countState"] = Counting.update_count(state["countState"], draw2["cards"], state["shoe"]["cards"].size())

	state["seats"][seat_index]["hands"] = [hand1, hand2]
	state["activeHandIndex"] = 0
	return state


static func _advance_turn(session: Dictionary) -> Dictionary:
	var state: Dictionary = session
	if state["phase"] != "player-turn":
		return state
	var seat_index: int = _find_seat_index(state["seats"], state["activeSeatId"])
	if seat_index == -1:
		state["phase"] = "dealer-turn"
		return state
	var hand_index: int = int(state["activeHandIndex"])
	var hand: Dictionary = state["seats"][seat_index]["hands"][hand_index]
	if hand["status"] == "active":
		return state
	if hand_index < state["seats"][seat_index]["hands"].size() - 1:
		state["activeHandIndex"] = hand_index + 1
	else:
		state["phase"] = "dealer-turn"
	return state


static func _play_dealer(session: Dictionary) -> Dictionary:
	var state: Dictionary = session
	state["dealerHoleHidden"] = false
	if state["dealerCards"].size() > 1:
		state["countState"] = Counting.update_count(state["countState"], [state["dealerCards"][1]], state["shoe"]["cards"].size())
	var dealer_value: Dictionary = Hand.hand_value(state["dealerCards"])
	var total: int = int(dealer_value["total"])
	var soft: bool = bool(dealer_value["soft"])
	while total < 17 or (total == 17 and soft):
		var draw_result: Dictionary = Shoe.draw(state["shoe"], 1)
		state["shoe"] = draw_result["shoe"]
		state["dealerCards"].append(draw_result["cards"][0])
		state["countState"] = Counting.update_count(state["countState"], draw_result["cards"], state["shoe"]["cards"].size())
		dealer_value = Hand.hand_value(state["dealerCards"])
		total = int(dealer_value["total"])
		soft = bool(dealer_value["soft"])
	return state


static func _find_seat_index(seats: Array, seat_id: String) -> int:
	for i in seats.size():
		if seats[i]["id"] == seat_id:
			return i
	return -1
