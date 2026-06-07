extends Node

const Blackjack = preload("res://scripts/domain/blackjack.gd")
const EventBus = preload("res://scripts/lib/events.gd")
const Lessons = preload("res://scripts/tutorial/lessons.gd")
const Rng = preload("res://scripts/lib/rng.gd")
const Tutorial = preload("res://scripts/domain/tutorial.gd")

var profile: Dictionary = {}
var events := EventBus.new()
var tutorial_progress: Dictionary = {}
var session: Dictionary = {}
var rng = Rng.create(42)


func _ready() -> void:
	profile = {
		"schemaVersion": 1,
		"balance": 1000,
		"selectedBetModel": "spread-table",
		"soundEnabled": true,
		"motionReduced": false,
		"lastMode": "tutorial",
	}
	tutorial_progress = Tutorial.create_tutorial_progress()


func get_profile() -> Dictionary:
	return profile


func get_session() -> Dictionary:
	return session


func get_tutorial_progress() -> Dictionary:
	return tutorial_progress


func select_mode(mode: String) -> void:
	profile["lastMode"] = mode
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
	session = Blackjack.create_session(
		mode,
		config,
		int(profile.get("balance", 1000)),
		str(profile.get("selectedBetModel", "spread-table")),
		rng
	)
	return session
