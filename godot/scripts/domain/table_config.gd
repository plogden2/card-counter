class_name TableConfig

const DEFAULT_TABLE_CONFIG := {
	"deckCount": 6,
	"initialOtherPlayers": 3,
	"handsBeforeReshuffle": 75,
	"tableMinBet": 5,
	"tableMaxBet": 500,
}

const STARTING_BANKROLL := 1000


static func validate(config: Dictionary) -> Dictionary:
	var deck_count: int = _clamp_int(int(config.get("deckCount", 6)), 1, 6)
	var initial_other_players: int = _clamp_int(int(config.get("initialOtherPlayers", 3)), 0, 5)
	var hands_before_reshuffle: int = _clamp_int(int(config.get("handsBeforeReshuffle", 75)), 20, 200)
	return {
		"deckCount": deck_count,
		"initialOtherPlayers": initial_other_players,
		"handsBeforeReshuffle": hands_before_reshuffle,
		"tableMinBet": 5,
		"tableMaxBet": 500,
	}


static func _clamp_int(value: int, min_value: int, max_value: int) -> int:
	return maxi(min_value, mini(max_value, value))
