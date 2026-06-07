extends GutTest

const Blackjack = preload("res://scripts/domain/blackjack.gd")
const HandSnapshot = preload("res://scripts/persistence/hand_snapshot.gd")
const LearnerProfile = preload("res://scripts/persistence/learner_profile.gd")
const Rng = preload("res://scripts/lib/rng.gd")


func before_each() -> void:
	LearnerProfile.clear_profile_for_tests()
	HandSnapshot.clear_hand_snapshot()


func test_round_trips_learner_profile():
	var profile: Dictionary = LearnerProfile.default_profile()
	profile["balance"] = 842
	profile["lastMode"] = "free-play"
	LearnerProfile.save_profile(profile)

	var loaded: Dictionary = LearnerProfile.load_profile()
	assert_eq(loaded["balance"], 842)
	assert_eq(loaded["lastMode"], "free-play")
	assert_true(loaded.has("lastSessionAt"))


func test_recovers_from_corrupted_profile_json():
	LearnerProfile.write_raw_profile_json("{not valid json")
	var loaded: Dictionary = LearnerProfile.load_profile()
	assert_eq(loaded["balance"], LearnerProfile.default_profile()["balance"])


func test_recovers_from_invalid_schema_version():
	LearnerProfile.write_raw_profile_json("{\"schemaVersion\":2,\"balance\":123}")
	assert_eq(LearnerProfile.load_profile()["balance"], LearnerProfile.default_profile()["balance"])


func test_saves_and_loads_mid_hand_snapshot():
	var session: Dictionary = Blackjack.create_session(
		"free-play",
		{"deckCount": 1},
		1000,
		"spread-table",
		Rng.create(1)
	)
	session["phase"] = "player-turn"
	session["activeSeatId"] = "learner"

	HandSnapshot.save_hand_snapshot(HandSnapshot.create_snapshot(session, "player-turn", "learner"))

	var loaded: Dictionary = HandSnapshot.load_hand_snapshot()
	assert_eq(loaded["phase"], "player-turn")
	assert_eq(int(loaded["sessionState"]["balance"]), 1000)
	assert_eq(loaded["activeSeatId"], "learner")


func test_rejects_corrupted_hand_snapshot():
	HandSnapshot.write_raw_snapshot_json("{\"bad\":true}")
	var loaded: Variant = HandSnapshot.load_hand_snapshot_or_null()
	assert_eq(loaded, null)


func test_clears_snapshot_after_hand_completes():
	var session: Dictionary = Blackjack.create_session(
		"free-play",
		{"deckCount": 1},
		1000,
		"spread-table",
		Rng.create(1)
	)
	session["phase"] = "player-turn"
	session["activeSeatId"] = "learner"
	HandSnapshot.save_hand_snapshot(HandSnapshot.create_snapshot(session, "player-turn", "learner"))
	assert_true(HandSnapshot.has_snapshot())

	HandSnapshot.clear_hand_snapshot()
	assert_false(HandSnapshot.has_snapshot())
