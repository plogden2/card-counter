class_name BetSizing

const BetModels = preload("res://scripts/domain/bet_models.gd")


static func get_recommendation(model_id: String, ctx: Dictionary) -> Dictionary:
	return BetModels.get_bet_model(model_id)["recommend"].call(ctx)


static func classify_bet(wager: int, recommendation: Dictionary) -> String:
	if wager < int(recommendation["min"]):
		return "under"
	if wager > int(recommendation["max"]):
		return "over"
	return "optimal"


static func get_bet_coaching(wager: int, model_id: String, ctx: Dictionary) -> Dictionary:
	var recommendation: Dictionary = get_recommendation(model_id, ctx)
	var classification: String = classify_bet(wager, recommendation)
	var model: Dictionary = BetModels.get_bet_model(model_id)
	var message: String = ""
	match classification:
		"under":
			message = "You bet $%d, below the %s recommended range ($%d-$%d). Under-betting at positive counts leaves edge on the table." % [
				wager,
				model["name"],
				recommendation["min"],
				recommendation["max"],
			]
		"over":
			message = "You bet $%d, above the %s recommended range ($%d-$%d). Over-betting increases variance without proportional edge." % [
				wager,
				model["name"],
				recommendation["min"],
				recommendation["max"],
			]
		_:
			message = "Your $%d bet matches the %s recommended range. Well sized for TC %d." % [
				wager,
				model["name"],
				int(ctx.get("trueCount", 0)),
			]
	if bool(recommendation.get("floorApplied", false)):
		message += " Table minimum applied - optimal calculation was below the floor."
	return {
		"classification": classification,
		"message": message,
		"recommendation": recommendation,
	}
