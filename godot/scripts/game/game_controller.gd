extends Node

const AnalyticsOverlayScript = preload("res://scripts/scenes/analytics_overlay.gd")
const Advantage = preload("res://scripts/domain/advantage.gd")
const BetSizing = preload("res://scripts/domain/bet_sizing.gd")
const Blackjack = preload("res://scripts/domain/blackjack.gd")
const CoachingCopy = preload("res://scripts/tutorial/coaching_copy.gd")
const Counting = preload("res://scripts/domain/counting.gd")
const EventBus = preload("res://scripts/lib/events.gd")
const AudioManagerScript = preload("res://scripts/game/audio_manager.gd")
const HandSnapshot = preload("res://scripts/persistence/hand_snapshot.gd")
const LearnerProfile = preload("res://scripts/persistence/learner_profile.gd")
const Lessons = preload("res://scripts/tutorial/lessons.gd")
const Rng = preload("res://scripts/lib/rng.gd")
const Shoe = preload("res://scripts/domain/shoe.gd")
const StayOrLeave = preload("res://scripts/domain/stay_or_leave.gd")
const TableConfig = preload("res://scripts/domain/table_config.gd")
const TableDynamics = preload("res://scripts/domain/table_dynamics.gd")
const Tutorial = preload("res://scripts/domain/tutorial.gd")

var profile: Dictionary = {}
var events := EventBus.new()
var tutorial_progress: Dictionary = {}
var session: Dictionary = {}
var analytics_overlay: Node = null
var rng = Rng.create(42)
var pre_hand_snapshot: Dictionary = {}
var audio_manager: Node = null


func _ready() -> void:
	profile = LearnerProfile.load_profile()
	tutorial_progress = Tutorial.create_tutorial_progress()
	audio_manager = AudioManagerScript.new()
	add_child(audio_manager)
	var sound_on: bool = bool(profile.get("soundEnabled", true))
	audio_manager.call("set_enabled", sound_on)
	audio_manager.call("set_music_enabled", bool(profile.get("musicEnabled", sound_on)))
	audio_manager.call("set_sfx_enabled", bool(profile.get("sfxEnabled", sound_on)))
	audio_manager.call("set_music_volume", float(profile.get("musicVolume", 0.5)))
	audio_manager.call("set_sfx_volume", float(profile.get("sfxVolume", 0.8)))
	_check_mid_hand_recovery()


func get_profile() -> Dictionary:
	return profile


func get_session() -> Dictionary:
	return session


func get_tutorial_progress() -> Dictionary:
	return tutorial_progress


func select_mode(mode: String) -> void:
	profile["lastMode"] = mode
	LearnerProfile.write_last_mode(mode)
	LearnerProfile.save_profile(profile)
	events.emit_event("mode:changed", {"mode": mode})


func advance_tutorial_step() -> Dictionary:
	tutorial_progress = Tutorial.advance_tutorial_step(tutorial_progress)
	return tutorial_progress


func start_tutorial_table() -> Dictionary:
	var lesson: Dictionary = Lessons.get_lesson(tutorial_progress.get("currentLessonId", "L1"))
	var preset: Dictionary = lesson.get("presetConfig", {})
	var started: Dictionary = _start_session_for_mode(preset, "tutorial")
	if not started.is_empty():
		started["tutorialLessonId"] = tutorial_progress.get("currentLessonId", "L1")
		started["tutorialStep"] = tutorial_progress.get("currentStep", 0)
		session = started
	return session


func start_free_play(config: Dictionary) -> Dictionary:
	return start_session(config)


func start_session(config: Dictionary) -> Dictionary:
	return _start_session_for_mode(config, "free-play")


func _start_session_for_mode(config: Dictionary, mode: String) -> Dictionary:
	pre_hand_snapshot = {}
	session = Blackjack.create_session(
		mode,
		config,
		int(profile.get("balance", TableConfig.STARTING_BANKROLL)),
		str(profile.get("selectedBetModel", "spread-table")),
		rng
	)
	if analytics_overlay:
		analytics_overlay.call("set_analytics", session.get("analytics", []))
	return session


func init_overlay() -> void:
	if analytics_overlay == null:
		analytics_overlay = AnalyticsOverlayScript.new()


func place_bet(wager: int) -> Dictionary:
	if session.is_empty():
		return session
	session = Blackjack.place_bet(session, wager)
	return session


func deal() -> Dictionary:
	if session.is_empty():
		return session
	pre_hand_snapshot = session.duplicate(true)
	session = Blackjack.deal_initial(session, rng)
	_play_audio_action("deal")
	events.emit_event("count:updated", session["countState"])
	_persist_mid_hand()
	return session


func apply_action(action: String) -> Dictionary:
	if session.is_empty():
		return session
	var balance_before: int = int(session["balance"])
	session = Blackjack.apply_action(session, "learner", action, rng)
	_play_audio_action(action)
	events.emit_event("count:updated", session["countState"])

	if session["phase"] == "settled":
		_on_hand_settled(balance_before)
	else:
		_persist_mid_hand()
	return session


func continue_to_next_hand() -> Dictionary:
	if session.is_empty():
		return session
	HandSnapshot.clear_hand_snapshot()

	var next: Dictionary = session.duplicate(true)
	next["phase"] = "betting"
	next["seats"] = next["seats"].map(func(seat: Dictionary) -> Dictionary:
		var updated: Dictionary = seat.duplicate(true)
		updated["hands"] = []
		return updated
	)
	next["dealerCards"] = []
	next["dealerHoleHidden"] = true
	next["currentWager"] = 0

	if Shoe.needs_reshuffle(next["shoe"]):
		next["shoe"] = Shoe.reshuffle(next["shoe"], next["tableConfiguration"]["deckCount"], rng)
		next["countState"] = Counting.create_count_state(next["shoe"]["cards"].size())
		events.emit_event("shoe:reshuffled", {"handIndex": next["handsPlayed"]})
	else:
		next = TableDynamics.maybe_join_or_leave(next, rng)

	var assessment: Dictionary = StayOrLeave.assess_stay_or_leave(next)
	next["lastStayAssessment"] = assessment
	next["lowAdvantageStreak"] = assessment["lowAdvantageStreak"]
	events.emit_event("stay:assessed", assessment)
	if assessment["recommendation"] == "consider-leaving":
		events.emit_event("coaching:message", {
			"text": CoachingCopy.stay_or_leave_message(assessment),
			"type": "stay",
		})

	session = next
	return session


func toggle_analytics() -> bool:
	if analytics_overlay == null:
		init_overlay()
	analytics_overlay.call("set_analytics", session.get("analytics", []))
	analytics_overlay.call("toggle")
	return bool(analytics_overlay.call("is_overlay_visible"))


func reset_bankroll_confirmed() -> Dictionary:
	profile = LearnerProfile.reset_bankroll()
	if not session.is_empty():
		session["balance"] = profile["balance"]
		session["sessionStartBalance"] = profile["balance"]
		session["analytics"].append({
			"handIndex": int(session["handsPlayed"]),
			"balance": int(profile["balance"]),
			"estimatedAdvantage": 0.0,
			"trueCount": int(session["countState"]["trueCount"]),
			"betModelId": session["currentBetModel"],
			"annotation": "bankroll-reset",
		})
	return profile


func forfeit_mid_hand() -> Dictionary:
	if not pre_hand_snapshot.is_empty():
		session = pre_hand_snapshot.duplicate(true)
	HandSnapshot.clear_hand_snapshot()
	return session


func resume_mid_hand() -> Dictionary:
	var snapshot: Variant = HandSnapshot.load_hand_snapshot_or_null()
	if snapshot != null:
		session = snapshot["sessionState"]
	return session


func has_mid_hand_snapshot() -> bool:
	return HandSnapshot.has_snapshot()


func _on_hand_settled(balance_before: int) -> void:
	HandSnapshot.clear_hand_snapshot()
	var analytics_point := {
		"handIndex": int(session["handsPlayed"]),
		"balance": int(session["balance"]),
		"estimatedAdvantage": Advantage.estimate_advantage(int(session["countState"]["trueCount"])),
		"trueCount": int(session["countState"]["trueCount"]),
		"betModelId": session["currentBetModel"],
	}
	session["analytics"].append(analytics_point)
	profile["balance"] = int(session["balance"])
	LearnerProfile.save_profile(profile)

	events.emit_event("hand:settled", analytics_point)
	if analytics_overlay:
		analytics_overlay.call("append_point", analytics_point)

	var coaching: Dictionary = BetSizing.get_bet_coaching(
		int(session["currentWager"]),
		session["currentBetModel"],
		{
			"trueCount": int(session["countState"]["trueCount"]),
			"bankroll": int(session["balance"]),
			"tableMinBet": int(session["tableConfiguration"]["tableMinBet"]),
			"tableMaxBet": int(session["tableConfiguration"]["tableMaxBet"]),
		}
	)
	events.emit_event("coaching:message", {
		"text": "%s: %s" % [CoachingCopy.bet_coaching_headline(coaching["classification"]), coaching["message"]],
		"type": "bet",
	})

	var assessment: Dictionary = StayOrLeave.assess_stay_or_leave(session)
	session["lastStayAssessment"] = assessment
	session["lowAdvantageStreak"] = assessment["lowAdvantageStreak"]
	events.emit_event("stay:assessed", assessment)

	if int(session["balance"]) != balance_before:
		LearnerProfile.save_profile(profile)

	var outcome := "push"
	if int(session["balance"]) > balance_before:
		outcome = "win"
	elif int(session["balance"]) < balance_before:
		outcome = "loss"
	_play_audio_action("settle", outcome)


func _persist_mid_hand() -> void:
	if session.is_empty():
		return
	if session["phase"] == "betting" or session["phase"] == "settled":
		return
	HandSnapshot.save_hand_snapshot(
		HandSnapshot.create_snapshot(session, session["phase"], str(session.get("activeSeatId", "learner")))
	)


func _check_mid_hand_recovery() -> void:
	var snapshot: Variant = HandSnapshot.load_hand_snapshot_or_null()
	if snapshot != null:
		session = snapshot["sessionState"]


func _play_audio_action(action: String, settle_outcome: String = "") -> void:
	if audio_manager == null:
		return
	audio_manager.call("play_action", action, settle_outcome)
