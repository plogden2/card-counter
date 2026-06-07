extends SceneTree

const TABLE_SCENE := preload("res://scenes/table/table_3d.tscn")
const OUTPUT_PATH := "res://tests/visual/output/table_capture.png"
const VIEWPORT_SIZE := Vector2i(960, 720)


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var root := Control.new()
	root.name = "CaptureRoot"
	root.custom_minimum_size = VIEWPORT_SIZE
	root.size = VIEWPORT_SIZE

	var table: SubViewportContainer = TABLE_SCENE.instantiate()
	table.custom_minimum_size = VIEWPORT_SIZE
	table.size = VIEWPORT_SIZE
	table.set_process(false)
	root.add_child(table)

	get_root().add_child(root)
	root.get_viewport().size = VIEWPORT_SIZE

	await create_timer(0.2).timeout

	if table.has_method("configure_table_dogs"):
		table.call("configure_table_dogs", 2)

	var subvp: SubViewport = table.get_node("SubViewport")
	subvp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await create_timer(0.25).timeout

	var tex := subvp.get_texture()
	if tex == null:
		push_error("SubViewport returned no texture")
		quit(1)
		return

	var img: Image = tex.get_image()
	var out_dir := ProjectSettings.globalize_path("res://tests/visual/output/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var out_file := ProjectSettings.globalize_path(OUTPUT_PATH)
	var err := img.save_png(out_file)
	if err != OK:
		push_error("Failed to save table capture: %s" % err)
		quit(1)
		return
	print("Saved table capture to ", out_file)
	quit(0)
