class_name Tutorial

const Lessons = preload("res://scripts/tutorial/lessons.gd")


static func create_tutorial_progress(lesson_id: String = "L1") -> Dictionary:
	return {
		"currentLessonId": lesson_id,
		"currentStep": 0,
		"completedLessons": [],
	}


static func get_current_step_text(progress: Dictionary) -> String:
	var lesson: Dictionary = Lessons.get_lesson(progress.get("currentLessonId", ""))
	if lesson.is_empty():
		return ""
	var step_idx: int = int(progress.get("currentStep", 0))
	var steps: Array = lesson.get("steps", [])
	if step_idx < 0 or step_idx >= steps.size():
		return ""
	return steps[step_idx]


static func advance_tutorial_step(progress: Dictionary) -> Dictionary:
	var lesson: Dictionary = Lessons.get_lesson(progress.get("currentLessonId", ""))
	if lesson.is_empty():
		return progress

	var current_step: int = int(progress.get("currentStep", 0))
	var next_step: int = current_step + 1
	var steps: Array = lesson.get("steps", [])
	if next_step < steps.size():
		var advanced: Dictionary = progress.duplicate(true)
		advanced["currentStep"] = next_step
		return advanced

	var completed_lessons: Array = progress.get("completedLessons", []).duplicate()
	completed_lessons.append(progress.get("currentLessonId", ""))
	var next_lesson_id: Variant = Lessons.get_next_lesson_id(progress.get("currentLessonId", ""))
	if next_lesson_id == null:
		var done: Dictionary = progress.duplicate(true)
		done["completedLessons"] = completed_lessons
		done["currentStep"] = steps.size()
		return done

	return {
		"currentLessonId": next_lesson_id,
		"currentStep": 0,
		"completedLessons": completed_lessons,
	}


static func get_lesson_count() -> int:
	return Lessons.LESSONS.size()


static func is_lesson_complete(progress: Dictionary) -> bool:
	var lesson: Dictionary = Lessons.get_lesson(progress.get("currentLessonId", ""))
	if lesson.is_empty():
		return true
	var next_lesson_id: Variant = Lessons.get_next_lesson_id(progress.get("currentLessonId", ""))
	if next_lesson_id != null:
		return false
	var current_step: int = int(progress.get("currentStep", 0))
	return current_step >= lesson.get("steps", []).size() - 1
