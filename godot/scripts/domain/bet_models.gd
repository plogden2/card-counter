class_name BetModels


static func get_bet_model(model_id: String) -> Dictionary:
	return _models().get(model_id, _models()["spread-table"])


static func list_bet_models() -> Array:
	return [
		_models()["spread-table"],
		_models()["flat-ramp"],
		_models()["wonging"],
	]


static func _models() -> Dictionary:
	return {
		"spread-table": {
			"id": "spread-table",
			"name": "Spread Table",
			"pros": [
				"Maximizes edge at high true counts",
				"Industry-standard Hi-Lo ramp for learning",
				"Scales bets proportionally to advantage",
			],
			"cons": [
				"Higher variance at large spreads",
				"Larger bet jumps may be noticeable",
				"Requires larger bankroll for high counts",
			],
			"expectedReturnProjection": func(_table: Dictionary) -> Dictionary:
				return {"hourlyEVMin": 8, "hourlyEVMax": 35},
			"recommend": func(ctx: Dictionary) -> Dictionary:
				var units: int = _spread_units(int(ctx.get("trueCount", 0)))
				var unit_size: int = maxi(5, int(floor(float(ctx.get("bankroll", 1000)) / 100.0)))
				return _clamp_bet(units * unit_size, ctx),
		},
		"flat-ramp": {
			"id": "flat-ramp",
			"name": "Flat Unit Ramp",
			"pros": [
				"Simple to learn and remember",
				"Gradual bet increases reduce variance",
				"Good for beginners practicing count-to-bet mapping",
			],
			"cons": [
				"Under-bets at very high true counts",
				"Over-bets at low positive counts",
				"Lower long-term EV than optimal spreads",
			],
			"expectedReturnProjection": func(_table: Dictionary) -> Dictionary:
				return {"hourlyEVMin": 4, "hourlyEVMax": 18},
			"recommend": func(ctx: Dictionary) -> Dictionary:
				var tc: int = int(ctx.get("trueCount", 0))
				var units: int = maxi(1, mini(8, int(floor(float(tc)))))
				var unit_size: int = maxi(5, int(floor(float(ctx.get("bankroll", 1000)) / 100.0)))
				return _clamp_bet(units * unit_size, ctx),
		},
		"wonging": {
			"id": "wonging",
			"name": "Conservative Wonging",
			"pros": [
				"Minimizes hours at disadvantage",
				"Reduces variance during negative counts",
				"Teaches table-entry discipline",
			],
			"cons": [
				"Misses hands at neutral counts",
				"Requires patience and discipline",
				"Lower hourly volume than continuous play",
			],
			"expectedReturnProjection": func(_table: Dictionary) -> Dictionary:
				return {"hourlyEVMin": 6, "hourlyEVMax": 22},
			"recommend": func(ctx: Dictionary) -> Dictionary:
				var tc: int = int(ctx.get("trueCount", 0))
				if tc < 1:
					return _clamp_bet(int(ctx.get("tableMinBet", 5)), ctx)
				var units: int = _wonging_units(tc)
				var unit_size: int = maxi(5, int(floor(float(ctx.get("bankroll", 1000)) / 100.0)))
				return _clamp_bet(units * unit_size, ctx),
		},
	}


static func _clamp_bet(amount: int, ctx: Dictionary) -> Dictionary:
	var unit_size: int = maxi(5, int(floor(float(ctx.get("bankroll", 1000)) / 100.0)))
	var table_min: int = int(ctx.get("tableMinBet", 5))
	var table_max: int = int(ctx.get("tableMaxBet", 500))
	var bankroll: int = int(ctx.get("bankroll", 1000))
	var minimum: int = maxi(table_min, amount)
	var floor_applied: bool = minimum > amount
	var maximum: int = mini(mini(table_max, bankroll), minimum * 2)
	if maximum < minimum:
		maximum = minimum
	return {
		"min": minimum,
		"max": maximum,
		"unitSize": unit_size,
		"floorApplied": floor_applied,
	}


static func _spread_units(tc: int) -> int:
	if tc <= 0:
		return 1
	if tc == 1:
		return 2
	if tc == 2:
		return 4
	if tc == 3:
		return 6
	return 8


static func _wonging_units(tc: int) -> int:
	if tc < 1:
		return 0
	if tc == 1:
		return 1
	if tc == 2:
		return 2
	if tc == 3:
		return 4
	return 6
