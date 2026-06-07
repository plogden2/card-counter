class_name StayOrLeave

const Advantage = preload("res://scripts/domain/advantage.gd")
const BetModels = preload("res://scripts/domain/bet_models.gd")


static func assess_stay_or_leave(session: Dictionary) -> Dictionary:
	var model: Dictionary = BetModels.get_bet_model(str(session.get("currentBetModel", "spread-table")))
	var true_count: int = int(session.get("countState", {}).get("trueCount", 0))
	var worthwhile_threshold: int = 1 if str(session.get("currentBetModel", "spread-table")) == "wonging" else 0

	var adv_norm: float = Advantage.normalized_advantage(true_count, worthwhile_threshold)
	var shoe: Dictionary = session.get("shoe", {})
	var reshuffle_at: int = int(shoe.get("reshuffleAt", 75))
	var hands_dealt: int = int(shoe.get("handsDealtSinceShuffle", 0))
	var hands_until_reshuffle: int = reshuffle_at - hands_dealt
	var reshuffle_proximity: float = 0.2 if hands_until_reshuffle <= int(reshuffle_at * 0.2) else 1.0

	var events: Array = session.get("dynamicsEvents", [])
	var hands_played: int = int(session.get("handsPlayed", 0))
	var recent_dynamics: Array = events.filter(func(e: Dictionary) -> bool: return int(e.get("handIndex", 0)) >= hands_played - 3)
	var occupancy_factor: float = 0.7 if recent_dynamics.size() > 0 else 1.0

	var balance: float = float(session.get("balance", 1000))
	var start_balance: float = maxf(1.0, float(session.get("sessionStartBalance", 1000)))
	var drawdown_ratio: float = balance / start_balance
	var drawdown_penalty: float = 0.4 if drawdown_ratio < 0.5 else 0.0

	var stay_score: float = (
		0.4 * adv_norm
		+ 0.25 * reshuffle_proximity
		+ 0.2 * occupancy_factor
		- 0.15 * drawdown_penalty
	)

	var factors: Array = []
	if adv_norm < 0.35:
		factors.append("True count %d yields low estimated advantage under %s" % [true_count, model["name"]])
	if reshuffle_proximity < 0.5:
		factors.append("Only %d hands until next reshuffle" % hands_until_reshuffle)
	if recent_dynamics.size() > 0:
		factors.append("Recent player join/leave changes table pace")
	if drawdown_penalty > 0:
		factors.append("Balance below 50% of session start - bankroll protection")

	var low_advantage_streak: int = int(session.get("lowAdvantageStreak", 0))
	if adv_norm < 0.35:
		low_advantage_streak += 1
	else:
		low_advantage_streak = 0

	var immediate_after_reshuffle: bool = hands_dealt == 0 and absf(float(true_count)) <= 1.0
	var should_leave: bool = (
		(stay_score < 0.35 and low_advantage_streak >= 3)
		or (immediate_after_reshuffle and stay_score < 0.4)
	)
	var recommendation: String = "consider-leaving" if should_leave else "stay"

	if recommendation == "consider-leaving" and factors.size() < 2:
		factors.append("Composite stay score below worthwhile threshold")
		factors.append("Current true count: %d" % true_count)

	return {
		"stayScore": stay_score,
		"recommendation": recommendation,
		"factors": factors,
		"lowAdvantageStreak": low_advantage_streak,
	}
