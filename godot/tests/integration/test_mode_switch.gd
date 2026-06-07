extends GutTest

const GameControllerScript = preload("res://scripts/game/game_controller.gd")
const HomeSceneScript = preload("res://scripts/scenes/home_scene.gd")
const TutorialSceneScript = preload("res://scripts/scenes/tutorial_scene.gd")
const ModeRouting = preload("res://scripts/domain/mode_routing.gd")


func test_navigates_home_tutorial_home_free_play():
	var controller = GameControllerScript.new()
	controller._ready()

	var home = HomeSceneScript.new()
	home.set_controller(controller)
	home.select_tutorial_mode()
	assert_eq(controller.get_profile()["lastMode"], "tutorial")
	assert_eq(home.get_last_requested_scene(), "tutorial")
	assert_eq(ModeRouting.route_for_mode(controller.get_profile()["lastMode"])["scene"], "TutorialScene")

	var tutorial = TutorialSceneScript.new()
	tutorial.set_controller(controller)
	tutorial.go_home()
	assert_eq(tutorial.get_last_requested_scene(), "home")

	home.select_free_play_mode()
	assert_eq(controller.get_profile()["lastMode"], "free-play")
	assert_eq(home.get_last_requested_scene(), "setup")
	assert_eq(ModeRouting.route_for_mode(controller.get_profile()["lastMode"])["scene"], "SetupScene")


func test_persists_last_mode_across_scene_switches():
	var controller = GameControllerScript.new()
	controller._ready()

	var home = HomeSceneScript.new()
	home.set_controller(controller)
	home.select_tutorial_mode()

	var tutorial = TutorialSceneScript.new()
	tutorial.set_controller(controller)
	tutorial.go_home()

	home.select_free_play_mode()
	assert_eq(controller.get_profile()["lastMode"], "free-play")
