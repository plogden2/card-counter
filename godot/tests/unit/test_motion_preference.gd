extends GutTest

const MotionPreference = preload("res://scripts/lib/motion_preference.gd")


func test_returns_base_duration_when_motion_not_reduced():
	assert_eq(MotionPreference.duration_ms(260, false), 260)


func test_returns_zero_when_reduced_motion():
	assert_eq(MotionPreference.duration_ms(260, true), 0)


func test_clamps_negative_base_to_zero():
	assert_eq(MotionPreference.duration_ms(-10, false), 0)
