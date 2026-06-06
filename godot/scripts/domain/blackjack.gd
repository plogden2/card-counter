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


static func deal_initial(session: Dictionary, _rng: Rng) -> Dictionary:
	if int(session["currentWager"]) < int(session["tableConfiguration"]["tableMinBet"]):
		push_error("Must place bet before dealing")
		return session

	var state: Dictionary = session.duplicate(true)
	var shoe: Dictionary = state["shoe"]
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
	var count_state: Dictionary = Counting.update_count(state["countState"], visible_cards, shoe["cards"].size())

	state["shoe"] = shoe
	state["seats"] = seats
	state["dealerCards"] = dealer_cards
	state["dealerHoleHidden"] = true
	state["countState"] = count_state
	state["activeSeatId"] = "learner"
	state["activeHandIndex"] = 0
	var dealer_up_rank = dealer_cards[0]["rank"]
	state["phase"] = "insurance" if (dealer_up_rank is String and dealer_up_rank == "A") else "player-turn"
	return state


static func apply_action(session: Dictionary, seat_id: String, action: String, _rng: Rng) -> Dictionary:
	var state: Dictionary = session.duplicate(true)
	if action != "insurance-accept" and action != "insurance-decline":
		push_error("Action not implemented in Task 11")
		return state
	if state["phase"] != "insurance":
		push_error("Insurance not offered")
		return state
	if state["dealerCards"][0]["rank"] != "A":
		push_error("Insurance only when dealer shows Ace")
		return state

	for seat in state["seats"]:
		if seat["id"] == seat_id:
			var hand: Dictionary = seat["hands"][0]
			if action == "insurance-accept":
				hand["insuranceWager"] = int(floor(float(hand["wager"]) / 2.0))

	var dealer_blackjack: bool = Hand.is_blackjack(state["dealerCards"])
	if dealer_blackjack:
		var learner_hand: Dictionary = _find_seat(state["seats"], seat_id)["hands"][0]
		if learner_hand.has("insuranceWager"):
			state["balance"] = int(state["balance"]) + int(learner_hand["insuranceWager"]) * 2
		if Hand.is_blackjack(learner_hand["cards"]):
			state["balance"] = int(state["balance"]) + int(floor(float(learner_hand["wager"]) * 2.5))
		else:
			state["balance"] = int(state["balance"]) - int(learner_hand["wager"])
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


static func _find_seat(seats: Array, seat_id: String) -> Dictionary:
	for seat in seats:
		if seat["id"] == seat_id:
			return seat
	return {}
