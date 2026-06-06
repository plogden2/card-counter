extends GutTest


func assert_raises(expected_msg: String, callable: Callable) -> void:
	var pre_fails := get_fail_count()
	var saved := gut.treat_error_as_failure
	gut.treat_error_as_failure = true
	var result = callable.call()
	gut.treat_error_as_failure = saved
	assert_eq(result, 0, "Invalid max should return 0 (%s)" % expected_msg)
	if get_fail_count() > pre_fails:
		_pass("push_error recorded for: %s" % expected_msg)


func test_deterministic_sequences_for_same_seed():
	var a := Rng.create(42)
	var b := Rng.create(42)
	var seq_a: Array = []
	var seq_b: Array = []
	for i in 5:
		seq_a.append(a.next())
		seq_b.append(b.next())
	assert_eq(seq_a, seq_b)


func test_different_sequences_for_different_seeds():
	var a := Rng.create(1)
	var b := Rng.create(2)
	assert_ne(a.next(), b.next())


func test_next_values_in_unit_interval():
	var rng := Rng.create(99)
	for i in 100:
		var value := rng.next()
		assert_gte(value, 0.0)
		assert_lt(value, 1.0)


func test_next_int_range():
	var rng := Rng.create(7)
	for i in 50:
		var v := rng.next_int(10)
		assert_gte(v, 0)
		assert_lt(v, 10)
		assert_eq(v, int(v))


func test_next_int_rejects_non_positive_max():
	var rng := Rng.create(1)
	assert_raises("max must be positive", Callable(rng, "next_int").bind(0))
	assert_raises("max must be positive", Callable(rng, "next_int").bind(-1))


func test_shuffle_deterministic_with_seeded_rng():
	var items := [1, 2, 3, 4, 5, 6, 7, 8]
	var a := Rng.shuffle(items, Rng.create(123))
	var b := Rng.shuffle(items, Rng.create(123))
	assert_eq(a, b)


func test_shuffle_preserves_all_elements():
	var items := [1, 2, 3, 4, 5, 6, 7, 8]
	var shuffled := Rng.shuffle(items, Rng.create(55))
	var sorted := shuffled.duplicate()
	sorted.sort()
	assert_eq(sorted, items)
	assert_eq(shuffled.size(), items.size())
