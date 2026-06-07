extends SceneTree

const SIDEBAR_SCENE := preload("res://scenes/table/sidebar.tscn")
const UiTheme = preload("res://scripts/lib/ui_theme.gd")

const OUTPUT_PATH := "res://tests/visual/output/sidebar_capture.png"
const VIEWPORT_SIZE := Vector2i(320, 640)


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var root := Control.new()
	root.name = "CaptureRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	root.custom_minimum_size = VIEWPORT_SIZE
	root.size = VIEWPORT_SIZE

	var shell := PanelContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.custom_minimum_size = VIEWPORT_SIZE
	shell.size = VIEWPORT_SIZE
	UiTheme.apply_to(shell, UiTheme.ScreenClass.SIDEBAR)
	shell.theme = UiTheme.load_theme()
	root.add_child(shell)

	var sidebar: VBoxContainer = SIDEBAR_SCENE.instantiate()
	sidebar.custom_minimum_size = Vector2(295, 0)
	shell.add_child(sidebar)

	get_root().add_child(root)
	root.get_viewport().size = VIEWPORT_SIZE

	for _i in 4:
		await create_timer(0.05).timeout

	sidebar.set_ref_display(true)
	sidebar.call("update_stats", {
		"runningCount": 2,
		"trueCount": 1,
		"decksRemaining": 2.0,
		"bet": 25,
		"refDisplay": true,
		"bettingEnabled": false,
		"tipText": "Positive counts are good! Consider increasing your bet.",
	})

	await create_timer(0.1).timeout

	var img: Image = root.get_viewport().get_texture().get_image()
	var out_dir := ProjectSettings.globalize_path("res://tests/visual/output/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var out_file := ProjectSettings.globalize_path(OUTPUT_PATH)
	var err := img.save_png(out_file)
	if err != OK:
		push_error("Failed to save sidebar capture: %s" % err)
		quit(1)
		return
	print("Saved sidebar capture to ", out_file)
	quit(0)
