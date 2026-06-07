class_name MotionPreference


static func duration_ms(base_duration_ms: int, reduced_motion: bool) -> int:
	if reduced_motion:
		return 0
	return maxi(base_duration_ms, 0)
