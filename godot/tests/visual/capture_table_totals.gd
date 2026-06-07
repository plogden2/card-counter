extends SceneTree

const TABLE_SCENE := preload("res://scenes/table/table_3d.tscn")
const VIEWPORT_SIZE := Vector2i(960, 720)


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var root := Control.new()
	root.custom_minimum_size = VIEWPORT_SIZE
	root.size = VIEWPORT_SIZE

	var table: SubViewportContainer = TABLE_SCENE.instantiate()
	table.custom_minimum_size = VIEWPORT_SIZE
	table.size = VIEWPORT_SIZE
	root.add_child(table)
	get_root().add_child(root)
	root.get_viewport().size = VIEWPORT_SIZE

	await create_timer(0.25).timeout
	table.set_process(false)

	var view := {
		"shoeRemaining": 280,
		"seats": [
			{
				"seatId": "dealer",
				"cards": [
					{"rank": 3, "faceUp": true, "fanAngle": -8.0},
					{"rank": 10, "faceUp": false, "fanAngle": 8.0},
				],
			},
			{
				"seatId": "learner",
				"isLearner": true,
				"cards": [
					{"rank": 9, "faceUp": true, "fanAngle": -10.0},
					{"rank": 5, "faceUp": true, "fanAngle": 10.0},
				],
			},
			{
				"seatId": "seat0",
				"cards": [
					{"rank": 5, "faceUp": true, "fanAngle": -10.0},
					{"rank": 2, "faceUp": true, "fanAngle": 10.0},
				],
			},
			{
				"seatId": "seat1",
				"cards": [
					{"rank": 8, "faceUp": true, "fanAngle": -10.0},
					{"rank": 11, "faceUp": true, "fanAngle": 10.0},
				],
			},
		],
	}
	table.call("configure_table_dogs", 2)
	table.call("sync_presentation", view, true)
	table.call("set_table_overview", true)

	var subvp: SubViewport = table.get_node("SubViewport")
	subvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await create_timer(0.6).timeout

	var out := ProjectSettings.globalize_path("res://tests/visual/output/table_overview_totals.png")
	var err := subvp.get_texture().get_image().save_png(out)
	if err != OK:
		push_error("save failed")
		quit(1)
		return
	print("Saved ", out)
	quit(0)
