extends GutTest

const UiTheme = preload("res://scripts/lib/ui_theme.gd")
const HomeSceneScript = preload("res://scripts/scenes/home_scene.gd")
const SetupSceneScript = preload("res://scripts/scenes/setup_scene.gd")
const TutorialSceneScript = preload("res://scripts/scenes/tutorial_scene.gd")


func test_menu_scenes_share_screen_class():
	var home := HomeSceneScript.new()
	var setup := SetupSceneScript.new()
	var tutorial := TutorialSceneScript.new()
	assert_eq(home.get_screen_class(), UiTheme.ScreenClass.MENU)
	assert_eq(setup.get_screen_class(), UiTheme.ScreenClass.MENU)
	assert_eq(tutorial.get_screen_class(), UiTheme.ScreenClass.MENU)


func test_theme_path_is_consistent():
	assert_eq(UiTheme.get_theme_path(), UiTheme.get_theme_path())


func test_sidebar_uses_sidebar_screen_class():
	var SidebarScript = preload("res://scripts/scenes/sidebar.gd")
	var sidebar := SidebarScript.new()
	assert_eq(sidebar.get_screen_class(), UiTheme.ScreenClass.SIDEBAR)
