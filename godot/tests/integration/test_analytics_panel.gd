extends GutTest

const AnalyticsOverlayScript = preload("res://scripts/scenes/analytics_overlay.gd")
const Charts = preload("res://scripts/ui/charts.gd")


func _point(hand_index: int, balance: int, advantage: float) -> Dictionary:
	return {
		"handIndex": hand_index,
		"balance": balance,
		"estimatedAdvantage": advantage,
		"trueCount": 1,
		"betModelId": "spread-table",
	}


func test_appends_analytics_series_when_hand_settles():
	var overlay: Node = AnalyticsOverlayScript.new()
	overlay.set_analytics([])
	overlay.append_point(_point(1, 1010, 0.5))

	assert_eq(overlay.get_point_count(), 1)
	assert_eq(overlay.get_balance_points(), [1010])
	assert_eq(overlay.get_advantage_points(), [0.5])


func test_toggles_overlay_visibility():
	var overlay: Node = AnalyticsOverlayScript.new()
	overlay.set_analytics([])
	assert_false(overlay.is_overlay_visible())
	overlay.toggle()
	assert_true(overlay.is_overlay_visible())
	overlay.toggle()
	assert_false(overlay.is_overlay_visible())


func test_accumulates_series_across_multiple_hands():
	var overlay: Node = AnalyticsOverlayScript.new()
	overlay.set_analytics([])
	overlay.append_point(_point(1, 990, -0.5))
	overlay.append_point(_point(2, 1005, 0.3))

	assert_eq(overlay.get_point_count(), 2)
	assert_eq(overlay.get_balance_points(), [990, 1005])
	assert_eq(Charts.build_labels(overlay.get_analytics_points()), ["1", "2"])
