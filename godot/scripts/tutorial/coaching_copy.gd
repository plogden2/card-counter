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
