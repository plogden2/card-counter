class_name Rng

var _state: int

static func create(seed: int) -> Rng:
	var rng := Rng.new()
	rng._state = seed & 0xFFFFFFFF
	return rng

func next() -> float:
	_state = (_state * 1664525 + 1013904223) & 0xFFFFFFFF
	return float(_state) / 4294967296.0

func next_int(max_val: int) -> int:
	if max_val <= 0:
		push_error("max must be positive")
		return 0
	return int(floor(next() * max_val))

static func shuffle(items: Array, rng: Rng) -> Array:
	var result := items.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j = rng.next_int(i + 1)
		var tmp = result[i]
		result[i] = result[j]
		result[j] = tmp
	return result
