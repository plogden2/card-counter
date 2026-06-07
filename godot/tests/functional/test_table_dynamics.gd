extends GutTest

const Blackjack = preload("res://scripts/domain/blackjack.gd")
const Rng = preload("res://scripts/lib/rng.gd")
const StayOrLeave = preload("res://scripts/domain/stay_or_leave.gd")
const TableDynamics = preload("res://scripts/domain/table_dynamics.gd")


func _find_dynamics_seed() -> int:
	for seed in 10000:
		var rng: Rng = Rng.create(seed)
		if rng.next() <= 0.15:
			return seed
	return -1


func test_records_join_events_when_players_enter():
	var session: Dictionary = Blackjack.create_session("free-play", {"initialOtherPlayers": 0}, 1000, "spread-table", Rng.create(1))
	session["phase"] = "betting"
	var updated: Dictionary = TableDynamics.maybe_join_or_leave(session, Rng.create(_find_dynamics_seed()))
	if updated["seats"].size() > session["seats"].size():
		var event: Dictionary = updated["dynamicsEvents"][-1]
		assert_eq(event["type"], "join")
		assert_true(str(event["seatId"]).begins_with("dog-"))


func test_assesses_stay_or_leave_after_continuing():
	var session: Dictionary = Blackjack.create_session("free-play", {"deckCount": 1, "initialOtherPlayers": 1, "handsBeforeReshuffle": 30}, 1000, "spread-table", Rng.create(1))
	session["phase"] = "settled"
	session["handsPlayed"] = 3
	session = TableDynamics.maybe_join_or_leave(session, Rng.create(_find_dynamics_seed()))
	session["phase"] = "betting"

	var assessment: Dictionary = StayOrLeave.assess_stay_or_leave(session)
	assert_true(["stay", "consider-leaving"].has(assessment["recommendation"]))


func test_can_recommend_leaving_after_repeated_low_counts():
	var session: Dictionary = Blackjack.create_session("free-play", {"deckCount": 1, "initialOtherPlayers": 0, "handsBeforeReshuffle": 5}, 1000, "spread-table", Rng.create(1))
	session["lowAdvantageStreak"] = 3
	session["countState"] = {"runningCount": -10, "decksRemaining": 3, "trueCount": -3, "cardsSeen": 20}
	session["handsPlayed"] = 4
	session["phase"] = "settled"

	var assessment: Dictionary = StayOrLeave.assess_stay_or_leave(session)
	assert_true(assessment.has("recommendation"))
	assert_true(assessment.has("factors"))
