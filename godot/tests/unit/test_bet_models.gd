extends GutTest

const BetModels = preload("res://scripts/domain/bet_models.gd")
const TableConfig = preload("res://scripts/domain/table_config.gd")


func _ctx(true_count: int) -> Dictionary:
	return {
		"trueCount": true_count,
		"bankroll": 1000,
		"tableMinBet": 5,
		"tableMaxBet": 500,
	}


func test_exposes_three_selectable_models():
	var models: Array = BetModels.list_bet_models()
	assert_eq(models.size(), 3)
	assert_eq(models[0]["id"], "spread-table")
	assert_eq(models[1]["id"], "flat-ramp")
	assert_eq(models[2]["id"], "wonging")


func test_each_model_has_pros_cons_and_ev_projection():
	for model in BetModels.list_bet_models():
		assert_gt(model["pros"].size(), 0)
		assert_gt(model["cons"].size(), 0)
		var ev: Dictionary = model["expectedReturnProjection"].call(TableConfig.DEFAULT_TABLE_CONFIG)
		assert_gt(ev["hourlyEVMax"], ev["hourlyEVMin"])


func test_spread_table_recommendations_tc_range():
	var model: Dictionary = BetModels.get_bet_model("spread-table")
	var cases := [
		{"tc": -6, "min": 10},
		{"tc": -1, "min": 10},
		{"tc": 0, "min": 10},
		{"tc": 1, "min": 20},
		{"tc": 2, "min": 40},
		{"tc": 3, "min": 60},
		{"tc": 4, "min": 80},
		{"tc": 8, "min": 80},
	]
	for test_case in cases:
		var rec: Dictionary = model["recommend"].call(_ctx(test_case["tc"]))
		assert_eq(rec["min"], test_case["min"])
		assert_eq(rec["unitSize"], 10)


func test_flat_ramp_recommendations_tc_range():
	var model: Dictionary = BetModels.get_bet_model("flat-ramp")
	assert_eq(model["recommend"].call(_ctx(-3))["min"], 10)
	assert_eq(model["recommend"].call(_ctx(3))["min"], 30)
	assert_eq(model["recommend"].call(_ctx(8))["min"], 80)


func test_wonging_recommendations_tc_range():
	var model: Dictionary = BetModels.get_bet_model("wonging")
	for tc in [-6, -1, 0]:
		var rec: Dictionary = model["recommend"].call(_ctx(tc))
		assert_eq(rec["min"], 5)
		assert_false(rec["floorApplied"])
	assert_eq(model["recommend"].call(_ctx(1))["min"], 10)
	assert_eq(model["recommend"].call(_ctx(4))["min"], 60)
