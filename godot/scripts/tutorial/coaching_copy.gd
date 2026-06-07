class_name CoachingCopy


static func bet_coaching_headline(classification: String) -> String:
	match classification:
		"under":
			return "Under-bet detected"
		"over":
			return "Over-bet detected"
		_:
			return "Optimal bet"


static func stay_or_leave_message(assessment: Dictionary) -> String:
	if assessment.get("recommendation", "stay") == "stay":
		return "Conditions favor staying at the table."
	var factors: Array = assessment.get("factors", [])
	return "Consider leaving: %s" % "; ".join(factors.slice(0, 3))


static func action_choice_feedback(chosen_action: String, recommended_action: String) -> String:
	var labels := {
		"place-bet": "Place Bet",
		"deal": "Deal",
		"hit": "Hit",
		"stand": "Stand",
		"double": "Double Down",
		"split": "Split",
		"insurance-accept": "Accept Insurance",
		"insurance-decline": "Decline Insurance",
	}
	var chosen_label: String = labels.get(chosen_action, chosen_action)
	var recommended_label: String = labels.get(recommended_action, recommended_action)
	return "You chose %s. Basic strategy recommends %s in this spot." % [chosen_label, recommended_label]
