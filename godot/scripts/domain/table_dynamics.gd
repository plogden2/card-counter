class_name TableDynamics

const Rng = preload("res://scripts/lib/rng.gd")
const Session = preload("res://scripts/domain/session.gd")


static func count_other_players(seats: Array) -> int:
	return seats.filter(func(seat: Dictionary) -> bool: return not bool(seat.get("isLearner", false))).size()


static func maybe_join_or_leave(session: Dictionary, rng: Rng) -> Dictionary:
	var phase: String = str(session.get("phase", "betting"))
	if phase != "betting" and phase != "settled":
		return session
	if rng.next() > 0.15:
		return session

	var seats: Array = session.get("seats", [])
	var other_count: int = count_other_players(seats)
	var should_join: bool = other_count < 5 and (other_count == 0 or rng.next() > 0.4)
	var should_leave: bool = other_count > 0 and not should_join

	if should_join and other_count < 5:
		var new_id: String = "dog-%d" % (other_count + 1)
		var event := {
			"type": "join",
			"seatId": new_id,
			"handIndex": int(session.get("handsPlayed", 0)),
		}
		var next: Dictionary = session.duplicate(true)
		next["seats"].append(Session.create_seat(new_id, false, "breed-%d" % (other_count + 1)))
		next["dynamicsEvents"].append(event)
		return next

	if should_leave and other_count > 0:
		var dog_seats: Array = seats.filter(func(seat: Dictionary) -> bool: return not bool(seat.get("isLearner", false)))
		if dog_seats.is_empty():
			return session
		var leaving: Dictionary = dog_seats[rng.next_int(dog_seats.size())]
		var leave_event := {
			"type": "leave",
			"seatId": str(leaving.get("id", "")),
			"handIndex": int(session.get("handsPlayed", 0)),
		}
		var after_leave: Dictionary = session.duplicate(true)
		after_leave["seats"] = after_leave["seats"].filter(func(seat: Dictionary) -> bool: return seat.get("id", "") != leaving.get("id", ""))
		after_leave["dynamicsEvents"].append(leave_event)
		return after_leave

	return session
