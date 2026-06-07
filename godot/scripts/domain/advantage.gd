class_name Advantage


static func estimate_advantage(true_count: int) -> float:
	return float(true_count) * 0.5


static func normalized_advantage(true_count: int, worthwhile_threshold: int = 1) -> float:
	if true_count < worthwhile_threshold:
		return maxf(0.0, float(true_count + 2) / float(worthwhile_threshold + 2))
	return minf(1.0, 0.5 + float(true_count - worthwhile_threshold) * 0.1)
