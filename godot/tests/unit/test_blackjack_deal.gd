extends GutTest

const Blackjack = preload("res://scripts/domain/blackjack.gd")
const Rng = preload("res://scripts/lib/rng.gd")


func _card(rank: Variant, suit: String = "hearts") -> Dictionary:
	return {"suit": suit, "rank": rank}


func _base_session() -> Dictionary:
	return Blackjack.create_session(
		"free-play",
		{"deckCount": 1, "initialOtherPlayers": 0, "handsBeforeReshuffle": 30},
		1000,
		"spread-table",
		Rng.create(99)
	)


func _insurance_session(dealer_hole: Dictionary, learner_cards: Array) -> Dictionary:
	var session: Dictionary = _base_session()
	return {
		"mode": session["mode"],
		"tableConfiguration": session["tableConfiguration"],
		"shoe": session["shoe"],
		"seats": [
			{
				"id": "learner",
				"isLearner": true,
				"dogBreed": "learner-dog",
				"hands": [
					{
						"cards": learner_cards,
						"wager": 20,
						"status": "active",
						"isSplit": false,
						"ownerSeatId": "learner",
					}
				],
			}
		],
		"dealerCards": [_card("A", "spades"), dealer_hole],
		"dealerHoleHidden": true,
		"countState": session["countState"],
		"balance": 1000,
		"sessionStartBalance": 1000,
		"analytics": [],
		"currentBetModel": "spread-table",
		"handsPlayed": 0,
		"dynamicsEvents": [],
		"phase": "insurance",
		"activeSeatId": "learner",
		"activeHandIndex": 0,
		"currentWager": 20,
		"lowAdvantageStreak": 0,
	}


func test_creates_session_in_betting_phase():
	var session: Dictionary = _base_session()
	assert_eq(session["phase"], "betting")
	assert_eq(session["balance"], 1000)
	assert_eq(session["seats"].size(), 1)


func test_clamps_bets_to_table_min_max_and_balance():
	var session: Dictionary = _base_session()
	session = Blackjack.place_bet(session, 3)
	assert_eq(session["currentWager"], 5)
	session = Blackjack.place_bet(session, 10000)
	assert_eq(session["currentWager"], 500)


func test_requires_bet_before_dealing():
	var session: Dictionary = _base_session()
	var dealt: Dictionary = Blackjack.deal_initial(session, Rng.create(1))
	assert_eq(dealt["phase"], "betting")


func test_deals_initial_cards_and_enters_player_turn_or_insurance():
	var session: Dictionary = Blackjack.place_bet(_base_session(), 10)
	session = Blackjack.deal_initial(session, Rng.create(42))
	assert_eq(session["seats"][0]["hands"][0]["cards"].size(), 2)
	assert_eq(session["dealerCards"].size(), 2)
	assert_true(session["phase"] == "insurance" or session["phase"] == "player-turn")
	assert_gt(session["countState"]["cardsSeen"], 0)


func test_accepts_insurance_and_records_half_wager_side_bet():
	var session: Dictionary = _insurance_session(_card(7, "clubs"), [_card("Q"), _card(9)])
	var result: Dictionary = Blackjack.apply_action(session, "learner", "insurance-accept", Rng.create(1))
	assert_eq(result["seats"][0]["hands"][0]["insuranceWager"], 10)
	assert_eq(result["phase"], "player-turn")


func test_declines_insurance_and_proceeds_to_player_turn():
	var session: Dictionary = _insurance_session(_card(7, "clubs"), [_card("Q"), _card(9)])
	var result: Dictionary = Blackjack.apply_action(session, "learner", "insurance-decline", Rng.create(1))
	assert_false(result["seats"][0]["hands"][0].has("insuranceWager"))
	assert_eq(result["phase"], "player-turn")


func test_settles_immediately_when_dealer_has_blackjack_and_insurance_pays():
	var session: Dictionary = _insurance_session(_card("K", "clubs"), [_card("Q"), _card(9)])
	var result: Dictionary = Blackjack.apply_action(session, "learner", "insurance-accept", Rng.create(1))
	assert_eq(result["phase"], "settled")
	assert_eq(result["balance"], 1000)


func test_pays_blackjack_when_both_player_and_dealer_have_blackjack():
	var session: Dictionary = _insurance_session(_card("K", "clubs"), [_card("A"), _card("K")])
	var result: Dictionary = Blackjack.apply_action(session, "learner", "insurance-decline", Rng.create(1))
	assert_eq(result["phase"], "settled")
	assert_eq(result["balance"], 1050)
