extends GutTest

const LearnerProfile = preload("res://scripts/persistence/learner_profile.gd")
const TableConfig = preload("res://scripts/domain/table_config.gd")


func before_each() -> void:
	LearnerProfile.clear_profile_for_tests()


func test_defines_schema_version_one_defaults():
	var defaults: Dictionary = LearnerProfile.default_profile()
	assert_eq(defaults["schemaVersion"], 1)
	assert_eq(defaults["balance"], TableConfig.STARTING_BANKROLL)
	assert_eq(defaults["selectedBetModel"], "spread-table")
	assert_true(defaults["soundEnabled"])
	assert_false(defaults["motionReduced"])


func test_returns_defaults_when_storage_is_empty():
	var profile: Dictionary = LearnerProfile.load_profile()
	assert_eq(profile["balance"], TableConfig.STARTING_BANKROLL)
	assert_eq(profile["selectedBetModel"], "spread-table")


func test_round_trips_profile_through_disk():
	var profile: Dictionary = LearnerProfile.default_profile()
	profile["balance"] = 750
	profile["selectedBetModel"] = "wonging"
	profile["lastMode"] = "free-play"
	LearnerProfile.save_profile(profile)

	var loaded: Dictionary = LearnerProfile.load_profile()
	assert_eq(loaded["balance"], 750)
	assert_eq(loaded["selectedBetModel"], "wonging")
	assert_eq(loaded["lastMode"], "free-play")
	assert_true(loaded.has("lastSessionAt"))


func test_reads_and_writes_last_mode():
	LearnerProfile.write_last_mode("tutorial")
	assert_eq(LearnerProfile.read_last_mode(), "tutorial")


func test_reset_bankroll_restores_starting_balance():
	var profile: Dictionary = LearnerProfile.default_profile()
	profile["balance"] = 250
	LearnerProfile.save_profile(profile)

	var updated: Dictionary = LearnerProfile.reset_bankroll()
	assert_eq(updated["balance"], TableConfig.STARTING_BANKROLL)
	assert_eq(LearnerProfile.load_profile()["balance"], TableConfig.STARTING_BANKROLL)


func test_rejects_unknown_schema_versions():
	LearnerProfile.write_raw_profile_json("{\"schemaVersion\":99,\"balance\":500}")
	var loaded: Dictionary = LearnerProfile.load_profile()
	assert_eq(loaded["balance"], TableConfig.STARTING_BANKROLL)
