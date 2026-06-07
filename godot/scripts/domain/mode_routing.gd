class_name ModeRouting

const NO_GATING := true


static func route_for_mode(mode: String) -> Dictionary:
	if mode == "tutorial":
		return {"mode": mode, "scene": "TutorialScene"}
	return {"mode": mode, "scene": "SetupScene"}


static func is_mode_accessible(_mode: String) -> bool:
	return NO_GATING


static func parse_mode(value: Variant) -> Variant:
	if value == "tutorial" or value == "free-play":
		return value
	return null
