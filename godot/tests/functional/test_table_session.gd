extends GutTest

const Blackjack = preload("res://scripts/domain/blackjack.gd")
const Shoe = preload("res://scripts/domain/shoe.gd")
const Rng = preload("res://scripts/lib/rng.gd")


func _start_session(config: Dictionary) -> Dictionary:
	return Blackjack.create_session("free-play", config, 1000, "spread-table", Rng.create(99))


func _play_one_hand(session: Dictionary, wager: int) -> Dictionary:
	session = Blackjack.place_bet(session, wager)
	session = Blackjack.deal_initial(session, Rng.create(42))
	if session["phase"] == "insurance":
		session = Blackjack.apply_action(session, "learner", "insurance-decline", Rng.create(42))
	if session["phase"] == "player-turn":
		session = Blackjack.apply_action(session, "learner", "stand", Rng.create(42))
	return session


func _continue_to_next_hand(session: Dictionary) -> Dictionary:
	var next: Dictionary = session.duplicate(true)
	next["phase"] = "betting"
	next["seats"][0]["hands"] = []
	next["currentWager"] = 0
	return next


func test_runs_betting_deal_action_settle_flow():
	var session: Dictionary = _start_session({
		"deckCount": 1,
		"initialOtherPlayers": 0,
		"handsBeforeReshuffle": 30,
	})
	session = Blackjack.place_bet(session, 10)
	assert_eq(session["currentWager"], 10)
	session = Blackjack.deal_initial(session, Rng.create(42))
	assert_eq(session["dealerCards"].size(), 2)
	assert_eq(session["seats"][0]["hands"][0]["cards"].size(), 2)
	if session["phase"] == "insurance":
		session = Blackjack.apply_action(session, "learner", "insurance-decline", Rng.create(42))
	if session["phase"] == "player-turn":
		session = Blackjack.apply_action(session, "learner", "stand", Rng.create(42))
	assert_eq(session["phase"], "settled")
	assert_eq(session["handsPlayed"], 1)


func test_tracks_hands_toward_reshuffle_threshold():
	var session: Dictionary = _start_session({
		"deckCount": 6,
		"initialOtherPlayers": 0,
		"handsBeforeReshuffle": 20,
	})
	for _i in 5:
		session = _play_one_hand(session, 10)
		session = _continue_to_next_hand(session)
	assert_eq(session["shoe"]["handsDealtSinceShuffle"], 5)
	assert_eq(session["shoe"]["reshuffleAt"], 20)


func test_triggers_reshuffle_when_threshold_reached():
	var session: Dictionary = _start_session({
		"deckCount": 6,
		"initialOtherPlayers": 0,
		"handsBeforeReshuffle": 20,
	})
	for _i in 20:
		session = _play_one_hand(session, 10)
		session = _continue_to_next_hand(session)
	assert_eq(session["shoe"]["handsDealtSinceShuffle"], 20)
	assert_eq(session["shoe"]["reshuffleAt"], 20)
	assert_true(Shoe.needs_reshuffle(session["shoe"]), "threshold should request reshuffle")
	session["shoe"] = Shoe.reshuffle(session["shoe"], session["tableConfiguration"]["deckCount"], Rng.create(123))
	assert_eq(session["shoe"]["handsDealtSinceShuffle"], 0)
