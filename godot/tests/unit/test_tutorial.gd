extends GutTest

const Tutorial = preload("res://scripts/domain/tutorial.gd")
const Lessons = preload("res://scripts/tutorial/lessons.gd")


func test_defines_five_guided_lessons():
	assert_eq(Tutorial.get_lesson_count(), 5)
	var ids: Array = []
	for lesson in Lessons.LESSONS:
		ids.append(lesson["id"])
	assert_eq(ids, ["L1", "L2", "L3", "L4", "L5"])


func test_starts_at_l1_step_0_by_default():
	var progress = Tutorial.create_tutorial_progress()
	assert_eq(progress["currentLessonId"], "L1")
	assert_eq(progress["currentStep"], 0)
	assert_eq(progress["completedLessons"], [])


func test_returns_current_step_coaching_text():
	var progress = Tutorial.create_tutorial_progress("L1")
	var text: String = Tutorial.get_current_step_text(progress)
	assert_true(text.contains("Hi-Lo"))


func test_advances_within_lesson_before_moving_to_next():
	var progress = Tutorial.create_tutorial_progress("L1")
	var lesson: Dictionary = Lessons.LESSONS[0]

	progress = Tutorial.advance_tutorial_step(progress)
	assert_eq(progress["currentLessonId"], "L1")
	assert_eq(progress["currentStep"], 1)

	for _i in range(1, lesson["steps"].size()):
		progress = Tutorial.advance_tutorial_step(progress)

	assert_true(progress["completedLessons"].has("L1"))
	assert_eq(progress["currentLessonId"], "L2")
	assert_eq(progress["currentStep"], 0)


func test_marks_final_lesson_complete_on_last_step():
	var progress = Tutorial.create_tutorial_progress("L5")
	var lesson: Dictionary = Lessons.LESSONS[4]

	for _i in range(0, lesson["steps"].size() - 2):
		progress = Tutorial.advance_tutorial_step(progress)
		assert_false(Tutorial.is_lesson_complete(progress))

	progress = Tutorial.advance_tutorial_step(progress)
	assert_true(Tutorial.is_lesson_complete(progress))

	progress = Tutorial.advance_tutorial_step(progress)
	assert_true(progress["completedLessons"].has("L5"))
	assert_true(Tutorial.is_lesson_complete(progress))


func test_each_lesson_has_preset_table_configuration():
	for lesson in Lessons.LESSONS:
		assert_gte(lesson["presetConfig"]["deckCount"], 1)
		assert_gt(lesson["presetConfig"]["handsBeforeReshuffle"], 0)
