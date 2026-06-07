extends GutTest

const ModeRouting = preload("res://scripts/domain/mode_routing.gd")


func test_enforces_no_gating():
	assert_true(ModeRouting.NO_GATING)
	assert_true(ModeRouting.is_mode_accessible("tutorial"))
	assert_true(ModeRouting.is_mode_accessible("free-play"))


func test_routes_tutorial_mode_to_tutorial_scene():
	assert_eq(
		ModeRouting.route_for_mode("tutorial"),
		{
			"mode": "tutorial",
			"scene": "TutorialScene",
		}
	)


func test_routes_free_play_mode_to_setup_scene():
	assert_eq(
		ModeRouting.route_for_mode("free-play"),
		{
			"mode": "free-play",
			"scene": "SetupScene",
		}
	)


func test_parses_valid_mode_strings():
	assert_eq(ModeRouting.parse_mode("tutorial"), "tutorial")
	assert_eq(ModeRouting.parse_mode("free-play"), "free-play")


func test_returns_null_for_invalid_or_missing_mode_strings():
	assert_eq(ModeRouting.parse_mode(""), null)
	assert_eq(ModeRouting.parse_mode("practice"), null)
	assert_eq(ModeRouting.parse_mode(null), null)
