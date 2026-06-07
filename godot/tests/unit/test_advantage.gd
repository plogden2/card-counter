extends GutTest

const Advantage = preload("res://scripts/domain/advantage.gd")


func test_estimates_advantage_as_half_percent_per_true_count():
	assert_eq(Advantage.estimate_advantage(0), 0.0)
	assert_eq(Advantage.estimate_advantage(2), 1.0)
	assert_eq(Advantage.estimate_advantage(-4), -2.0)


func test_normalizes_advantage_below_threshold():
	assert_almost_eq(Advantage.normalized_advantage(0), 0.6666667, 0.01)
	assert_eq(Advantage.normalized_advantage(-2), 0.0)
	assert_eq(Advantage.normalized_advantage(0, 2), 0.5)


func test_normalizes_advantage_at_and_above_threshold():
	assert_eq(Advantage.normalized_advantage(1), 0.5)
	assert_eq(Advantage.normalized_advantage(3), 0.7)
	assert_eq(Advantage.normalized_advantage(10), 1.0)


func test_uses_wonging_threshold_for_assessment():
	assert_almost_eq(Advantage.normalized_advantage(0, 1), 0.6666667, 0.01)
	assert_eq(Advantage.normalized_advantage(1, 1), 0.5)
