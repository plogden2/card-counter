extends SceneTree

const TABLE_SCENE := preload("res://scenes/table/table_3d.tscn")
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

	table.set_process(false)
	if table.has_method("set_table_overview"):
		table.call("set_table_overview", false)

	var subvp: SubViewport = table.get_node("SubViewport")
	subvp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await create_timer(0.25).timeout

	var out_dir := ProjectSettings.globalize_path("res://tests/visual/output/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	_save_viewport(subvp, out_dir.path_join("table_home.png"))

	if table.has_method("set_table_overview"):
		table.call("set_table_overview", true)
	subvp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await create_timer(0.35).timeout
	_save_viewport(subvp, out_dir.path_join("table_overview.png"))
	print("Saved home and overview captures")
	quit(0)


func _save_viewport(subvp: SubViewport, path: String) -> void:
	var tex := subvp.get_texture()
	if tex == null:
		push_error("SubViewport returned no texture")
		quit(1)
		return
	var err := tex.get_image().save_png(path)
	if err != OK:
		push_error("Failed to save capture: %s" % path)
		quit(1)
