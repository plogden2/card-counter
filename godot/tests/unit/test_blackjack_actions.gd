extends GutTest

const Rng = preload("res://scripts/lib/rng.gd")


func _blackjack():
	return load("res://scripts/domain/blackjack.gd")


func _card(rank: Variant, suit: String = "hearts") -> Dictionary:
	return {"suit": suit, "rank": rank}


func _base_session() -> Dictionary:
	var Blackjack = _blackjack()
	assert_not_null(Blackjack)
	return Blackjack.create_session(
		"free-play",
		{"deckCount": 1, "initialOtherPlayers": 0, "handsBeforeReshuffle": 30},
		1000,
		"spread-table",
		Rng.create(99)
	)


func test_allows_hit_and_stand_during_player_turn():
	var Blackjack = _blackjack()
	assert_not_null(Blackjack)
	var session: Dictionary = Blackjack.place_bet(_base_session(), 10)
	session = Blackjack.deal_initial(session, Rng.create(42))
	if session["phase"] == "insurance":
		session = Blackjack.apply_action(session, "learner", "insurance-decline", Rng.create(42))
	if session["phase"] == "player-turn":
		session = Blackjack.apply_action(session, "learner", "hit", Rng.create(42))
		assert_gte(session["seats"][0]["hands"][0]["cards"].size(), 2)
		session = Blackjack.apply_action(session, "learner", "stand", Rng.create(42))
		assert_eq(session["phase"], "settled")


func test_split_creates_two_hands_and_consumes_balance():
	var Blackjack = _blackjack()
	assert_not_null(Blackjack)
	var session: Dictionary = _base_session()
	session["phase"] = "player-turn"
	session["balance"] = 1000
	session["dealerCards"] = [_card(6), _card(10)]
	session["seats"] = [{
		"id": "learner",
		"isLearner": true,
		"dogBreed": "learner-dog",
		"hands": [{
			"cards": [_card(8), _card(8)],
			"wager": 20,
			"status": "active",
			"isSplit": false,
			"ownerSeatId": "learner",
		}],
	}]
	var updated: Dictionary = Blackjack.apply_action(session, "learner", "split", Rng.create(7))
	assert_eq(updated["seats"][0]["hands"].size(), 2)
	assert_eq(updated["balance"], 980)
	assert_eq(updated["seats"][0]["hands"][0]["cards"].size(), 2)
	assert_eq(updated["seats"][0]["hands"][1]["cards"].size(), 2)


func test_double_doubles_wager_and_draws_once():
	var Blackjack = _blackjack()
	assert_not_null(Blackjack)
	var session: Dictionary = _base_session()
	session["phase"] = "player-turn"
	session["balance"] = 1000
	session["dealerCards"] = [_card(6), _card(10)]
	session["seats"] = [{
		"id": "learner",
		"isLearner": true,
		"dogBreed": "learner-dog",
		"hands": [{
			"cards": [_card(5), _card(6)],
			"wager": 20,
			"status": "active",
			"isSplit": false,
			"ownerSeatId": "learner",
		}],
	}]
	var updated: Dictionary = Blackjack.apply_action(session, "learner", "double", Rng.create(8))
	assert_eq(updated["seats"][0]["hands"][0]["wager"], 40)
	assert_eq(updated["seats"][0]["hands"][0]["cards"].size(), 3)
	assert_true(updated["seats"][0]["hands"][0]["status"] == "stood" or updated["seats"][0]["hands"][0]["status"] == "bust")


func test_settle_hand_adjusts_balance_for_busts_and_wins():
	var Blackjack = _blackjack()
	assert_not_null(Blackjack)
	var session: Dictionary = _base_session()
	session["phase"] = "dealer-turn"
	session["dealerCards"] = [_card(10), _card(7)]
	session["seats"] = [{
		"id": "learner",
		"isLearner": true,
		"dogBreed": "learner-dog",
		"hands": [{
			"cards": [_card(10), _card(9)],
			"wager": 20,
			"status": "stood",
			"isSplit": false,
			"ownerSeatId": "learner",
		}],
	}]
	session["balance"] = 1000
	var settled: Dictionary = Blackjack.settle_hand(session)
	assert_eq(settled["balance"], 1020)
	assert_eq(settled["phase"], "settled")
	assert_eq(settled["handsPlayed"], 1)


func test_blackjack_pays_three_to_two():
	var Blackjack = _blackjack()
	assert_not_null(Blackjack)
	var session: Dictionary = _base_session()
	session["phase"] = "dealer-turn"
	session["dealerCards"] = [_card(10), _card(9)]
	session["seats"] = [{
		"id": "learner",
		"isLearner": true,
		"dogBreed": "learner-dog",
		"hands": [{
			"cards": [_card("A"), _card("K")],
			"wager": 20,
			"status": "stood",
			"isSplit": false,
			"ownerSeatId": "learner",
		}],
	}]
	session["balance"] = 1000
	var settled: Dictionary = Blackjack.settle_hand(session)
	assert_eq(settled["balance"], 1030)


func test_push_keeps_balance_unchanged():
	var Blackjack = _blackjack()
	assert_not_null(Blackjack)
	var session: Dictionary = _base_session()
	session["phase"] = "dealer-turn"
	session["dealerCards"] = [_card(10), _card(8)]
	session["seats"] = [{
		"id": "learner",
		"isLearner": true,
		"dogBreed": "learner-dog",
		"hands": [{
			"cards": [_card(9), _card(9)],
			"wager": 20,
			"status": "stood",
			"isSplit": false,
			"ownerSeatId": "learner",
		}],
	}]
	session["balance"] = 1000
	var settled: Dictionary = Blackjack.settle_hand(session)
	assert_eq(settled["balance"], 1000)
