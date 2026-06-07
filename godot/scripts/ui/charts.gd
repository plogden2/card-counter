class_name Charts


static func build_labels(points: Array) -> Array:
	var labels: Array = []
	for point in points:
		labels.append(str(point.get("handIndex", labels.size() + 1)))
	return labels


static func balance_series(points: Array) -> Array:
	var values: Array = []
	for point in points:
		values.append(point.get("balance", 0))
	return values


static func advantage_series(points: Array) -> Array:
	var values: Array = []
	for point in points:
		values.append(point.get("estimatedAdvantage", 0.0))
	return values
