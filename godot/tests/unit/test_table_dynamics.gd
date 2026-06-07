extends GutTest

const Blackjack = preload("res://scripts/domain/blackjack.gd")
const Rng = preload("res://scripts/lib/rng.gd")
const TableDynamics = preload("res://scripts/domain/table_dynamics.gd")


func _find_join_seed() -> int:
	for seed in 10000:
		var rng: Rng = Rng.create(seed)
		if rng.next() <= 0.15:
			return seed
	return -1


func _find_leave_seed() -> int:
	for seed in 10000:
		var rng: Rng = Rng.create(seed)
		if rng.next() <= 0.15 and rng.next() <= 0.4:
			return seed
	return -1


func test_counts_other_players_excluding_learner():
	var session: Dictionary = Blackjack.create_session("free-play", {"initialOtherPlayers": 3}, 1000, "spread-table", Rng.create(1))
	assert_eq(TableDynamics.count_other_players(session["seats"]), 3)


func test_does_not_mutate_during_active_hand_phases():
	var session: Dictionary = Blackjack.create_session("free-play", {}, 1000, "spread-table", Rng.create(1))
	session["phase"] = "player-turn"
	var result: Dictionary = TableDynamics.maybe_join_or_leave(session, Rng.create(_find_join_seed()))
	assert_eq(result["seats"].size(), session["seats"].size())
	assert_eq(result["dynamicsEvents"].size(), 0)


func test_may_add_player_during_betting():
	var session: Dictionary = Blackjack.create_session("free-play", {"initialOtherPlayers": 0}, 1000, "spread-table", Rng.create(1))
	session["phase"] = "betting"
	var result: Dictionary = TableDynamics.maybe_join_or_leave(session, Rng.create(_find_join_seed()))
	assert_gte(result["seats"].size(), session["seats"].size())
	if result["seats"].size() > session["seats"].size():
		assert_eq(result["dynamicsEvents"][-1]["type"], "join")


func test_may_remove_player_when_table_occupied():
	var seed: int = _find_leave_seed()
	assert_gte(seed, 0)
	var session: Dictionary = Blackjack.create_session("free-play", {"initialOtherPlayers": 2}, 1000, "spread-table", Rng.create(1))
	session["phase"] = "settled"
	var result: Dictionary = TableDynamics.maybe_join_or_leave(session, Rng.create(seed))
	if result["seats"].size() < session["seats"].size():
		assert_eq(result["dynamicsEvents"][-1]["type"], "leave")
