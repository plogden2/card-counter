extends GutTest

const EventBus = preload("res://scripts/lib/events.gd")


func test_delivers_payloads_to_subscribers():
	var bus = EventBus.new()
	var state := {"received_payload": {}}
	bus.on("count:updated", func(payload: Dictionary): state["received_payload"] = payload)
	var payload := {
		"runningCount": 3,
		"decksRemaining": 4,
		"trueCount": 0,
		"cardsSeen": 12,
	}
	bus.emit_event("count:updated", payload)
	assert_eq(state["received_payload"], payload)


func test_supports_multiple_listeners_on_same_event():
	var bus = EventBus.new()
	var state := {"count_a": 0, "count_b": 0}
	bus.on("mode:changed", func(_payload: Dictionary): state["count_a"] += 1)
	bus.on("mode:changed", func(_payload: Dictionary): state["count_b"] += 1)
	bus.emit_event("mode:changed", {"mode": "tutorial"})
	assert_eq(state["count_a"], 1)
	assert_eq(state["count_b"], 1)


func test_unsubscribes_via_returned_cleanup_function():
	var bus = EventBus.new()
	var state := {"calls": 0}
	var listener := func(_payload: Dictionary): state["calls"] += 1
	var unsubscribe: Callable = bus.on("scene:navigate", listener)
	unsubscribe.call()
	bus.emit_event("scene:navigate", {"scene": "HomeScene"})
	assert_eq(state["calls"], 0)


func test_removes_listeners_via_off():
	var bus = EventBus.new()
	var state := {"calls": 0}
	var listener := func(_payload: Dictionary): state["calls"] += 1
	bus.on("coaching:message", listener)
	bus.off("coaching:message", listener)
	bus.emit_event("coaching:message", {"text": "test", "type": "info"})
	assert_eq(state["calls"], 0)


func test_clear_removes_all_listeners():
	var bus = EventBus.new()
	var state := {"calls": 0}
	var listener := func(_payload: Dictionary): state["calls"] += 1
	bus.on("hand:settled", listener)
	bus.clear()
	bus.emit_event("hand:settled", {
		"handIndex": 1,
		"balance": 1000,
		"estimatedAdvantage": 0.5,
		"trueCount": 1,
		"betModelId": "spread-table",
	})
	assert_eq(state["calls"], 0)


func test_emits_stay_assessed_with_expected_shape():
	var bus = EventBus.new()
	var state := {"recommendation": ""}
	bus.on("stay:assessed", func(payload: Dictionary): state["recommendation"] = payload["recommendation"])
	bus.emit_event("stay:assessed", {
		"stayScore": 0.6,
		"recommendation": "stay",
		"factors": [],
		"lowAdvantageStreak": 0,
	})
	assert_eq(state["recommendation"], "stay")
