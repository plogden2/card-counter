class_name Lessons

const LESSONS := [
	{
		"id": "L1",
		"title": "Running Count Basics",
		"focus": "Identify Hi-Lo tags for each card rank",
		"steps": [
			"Welcome! In Hi-Lo counting, cards 2-6 count as +1.",
			"Cards 7-9 are neutral (0).",
			"10s and face cards count as -1.",
			"Watch the running count update as cards are dealt.",
			"Try playing one hand and observe the count change."
		],
		"presetConfig": {"deckCount": 1, "initialOtherPlayers": 0, "handsBeforeReshuffle": 30},
	},
	{
		"id": "L2",
		"title": "True Count",
		"focus": "Adjust running count by decks remaining",
		"steps": [
			"Running count alone is not enough with multiple decks.",
			"True count = running count / decks remaining (rounded down).",
			"More decks dilute the advantage of a positive running count.",
			"Play a hand and compare running vs true count."
		],
		"presetConfig": {"deckCount": 4, "initialOtherPlayers": 1, "handsBeforeReshuffle": 50},
	},
	{
		"id": "L3",
		"title": "Bet Models",
		"focus": "Compare and select a bet-sizing model",
		"steps": [
			"Bet sizing converts your count advantage into wager size.",
			"Spread Table ramps bets aggressively at high counts.",
			"Flat Ramp is simpler but less optimal.",
			"Wonging means minimum bets until the count is favorable.",
			"Review the three models and pick one for practice."
		],
		"presetConfig": {"deckCount": 6, "initialOtherPlayers": 2, "handsBeforeReshuffle": 75},
	},
	{
		"id": "L4",
		"title": "Stay or Leave",
		"focus": "Reshuffle and occupancy factors",
		"steps": [
			"Not every positive count justifies staying.",
			"Consider hands until reshuffle - counts reset after shuffle.",
			"Players joining or leaving affect table pace.",
			"Watch for stay-or-leave coaching after each hand."
		],
		"presetConfig": {"deckCount": 6, "initialOtherPlayers": 3, "handsBeforeReshuffle": 40},
	},
	{
		"id": "L5",
		"title": "Free Play Ready",
		"focus": "Transition to the full sandbox",
		"steps": [
			"You have learned the core counting skills!",
			"Free Play lets you configure any table setting.",
			"Practice with bet models, graphs, and persistence.",
			"Return home anytime to switch between Tutorial and Free Play."
		],
		"presetConfig": {"deckCount": 6, "initialOtherPlayers": 3, "handsBeforeReshuffle": 75},
	},
]


static func get_lesson(id: String) -> Dictionary:
	for lesson in LESSONS:
		if lesson["id"] == id:
			return lesson
	return {}


static func get_next_lesson_id(current_id: String) -> Variant:
	for i in range(LESSONS.size()):
		if LESSONS[i]["id"] == current_id:
			if i >= LESSONS.size() - 1:
				return null
			return LESSONS[i + 1]["id"]
	return null
