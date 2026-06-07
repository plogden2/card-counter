extends SubViewportContainer

const MotionPreference = preload("res://scripts/lib/motion_preference.gd")
const Hand = preload("res://scripts/domain/hand.gd")
const FACETED_MAT = preload("res://assets/materials/faceted_mat.tres")
const CEL_SHADER := preload("res://assets/materials/cel_faceted.gdshader")
const DOG_MODELS := [
	preload("res://assets/models/dog_player_red.glb"),
	preload("res://assets/models/dog_player_blue.glb"),
	preload("res://assets/models/dog_player_green.glb"),
]
const DOG_DEALER_MODEL = preload("res://assets/models/dog_dealer.glb")
const CHIP_MODEL = preload("res://assets/models/chip.glb")
const SHOE_MODEL = preload("res://assets/models/card_shoe.glb")
const ROUND_TABLE_MODEL = preload("res://assets/models/round_table.glb")
const LAMP_MODEL = preload("res://assets/models/overhead_lamp.glb")
const PLANT_MODEL = preload("res://assets/models/potted_plant.glb")
const DISCARD_MODEL = preload("res://assets/models/discard_tray.glb")
const SIDEBOARD_MODEL = preload("res://assets/models/sideboard.glb")
const COUNT_GUIDE_MODEL = preload("res://assets/models/count_guide.glb")
const LANTERN_MODEL = preload("res://assets/models/lantern.glb")
const CURTAIN_MODEL = preload("res://assets/models/curtain.glb")
const HAND_DISPLAY_MODEL = preload("res://assets/models/hand_total_display.glb")
const UiTheme = preload("res://scripts/lib/ui_theme.gd")

const SURFACE_PLAQUE_BASE := Color(0.18, 0.14, 0.11)
const SURFACE_PLAQUE_FACE := Color(0.85, 0.78, 0.65)
const SURFACE_TEXT_COLOR := Color(0.949, 0.91, 0.835)
const HAND_BOARD_FRAME := Color(0.32, 0.22, 0.14)
const HAND_BOARD_FACE := Color(0.07, 0.07, 0.08)
const HAND_BOARD_OVERVIEW_FACE := Color(0.94, 0.9, 0.82)
const HAND_BOARD_TEXT := Color(1.0, 1.0, 1.0)
const HAND_BOARD_SIZE := Vector3(0.26, 0.05, 0.18)
const HAND_BOARD_TILT_DEG := 42.0
const CARD_PLANE_SIZE := Vector2(0.30, 0.44)
const TABLE_SURFACE_Y := 0.112

const CARD_TEXTURE_DIR := "res://assets/textures/cards/"
const ACTION_BAR_HEIGHT := 76.0

const CAMERA_HOME_POS := Vector3(5.0, 4.3, 5.0)
const CAMERA_HOME_LOOK := Vector3(0.0, 0.42, 0.05)
const CAMERA_HOME_SIZE := 5.2
const CAMERA_TOPDOWN_POS := Vector3(0.0, 7.2, 0.0)
const CAMERA_TOPDOWN_LOOK := Vector3(0.0, TABLE_SURFACE_Y, 0.0)
const CAMERA_TOPDOWN_SIZE := 3.85
const CAMERA_TOPDOWN_ROT := Vector3(-PI * 0.5, 0.0, 0.0)
const HAND_BOARD_OVERVIEW_SCALE := 1.65
const HAND_BOARD_HOME_FONT := 56
const HAND_BOARD_OVERVIEW_FONT := 88
const TABLE_RX := 1.52
const TABLE_RZ := 2.08
const TABLE_DEALER_Z := -0.52
const TABLE_RIM_DROP := 0.12
const TABLE_RIM_OUTSET := 0.14
const TABLE_ARC_SEGMENTS := 28
const DEAL_SNAP_MS := 260
const CHIP_BOUNCE_MS := 180
const DOG_REACTION_MS := 240
const OUTCOME_CUE_MS := 320
const FOCUS_ZOOM_MS := 320
const FOCUS_CARD_SCALE := 1.2

# Performance: up to ~40 card meshes share one BoxMesh prototype and unshaded materials.
# Cards parent under a single CardRoot; SubViewport WYSIWYG mode keeps draw calls bounded for 60 fps.

const _SEAT_CARD_BASES := {
	"learner": Vector3(0.0, TABLE_SURFACE_Y + 0.012, 0.72),
	"dealer": Vector3(0.0, TABLE_SURFACE_Y + 0.012, -0.72),
}

const CHIP_STACK_POS := Vector3(-0.42, 0.125, 0.74)
const CHIP_LAYER_HEIGHT := 0.028

const _DOG_BREED_DEALER := "dealer"
const _DOG_BREED_LEARNER := "learner"
const _DOG_BREED_BEAR := "bear"
const _DOG_BREED_HUSKY := "husky"
const _DOG_BREED_GENERIC := "generic"

const DOG_STOOL_SEAT_Y := 0.38

const _DOG_DEALER_SLOT := {
	"breed": _DOG_BREED_DEALER,
	"pos": Vector3(0.0, TABLE_SURFACE_Y, -1.72),
	"rot_y": 0.0,
}
const _DOG_LEARNER_SLOT := {
	"breed": _DOG_BREED_LEARNER,
	"pos": Vector3(0.0, TABLE_SURFACE_Y, 1.22),
	"rot_y": 0.0,
}
const _DOG_PLAYER_SLOTS := [
	{"breed": _DOG_BREED_BEAR, "pos": Vector3(-1.42, TABLE_SURFACE_Y, 1.18), "rot_y": -0.38},
	{"breed": _DOG_BREED_HUSKY, "pos": Vector3(1.42, TABLE_SURFACE_Y, 1.18), "rot_y": 0.38},
	{"breed": _DOG_BREED_GENERIC, "pos": Vector3(-0.72, TABLE_SURFACE_Y, 1.52), "rot_y": -0.12},
	{"breed": _DOG_BREED_GENERIC, "pos": Vector3(0.72, TABLE_SURFACE_Y, 1.52), "rot_y": 0.12},
]

@onready var _subviewport: SubViewport = $SubViewport
@onready var _camera: Camera3D = %Camera3D
@onready var _table: MeshInstance3D = %TableMesh
@onready var _table_rim: MeshInstance3D = %TableRim
@onready var _shoe: MeshInstance3D = %ShoeMesh
@onready var _discard_tray: MeshInstance3D = %DiscardTray
@onready var _card_root: Node3D = %CardRoot
@onready var _seat_root: Node3D = %SeatRoot
@onready var _seat_areas: Node3D = %SeatAreas
@onready var _shoe_label: Label3D = get_node_or_null("%ShoeLabel")
@onready var _room_root: Node3D = %RoomRoot
@onready var _world: Node3D = get_node_or_null("SubViewport/World")

var _card_nodes: Array[MeshInstance3D] = []
var _dog_nodes: Array[Node3D] = []
var _dog_bodies: Array[MeshInstance3D] = []
var _seat_area_nodes: Dictionary = {}
var _seat_card_groups: Dictionary = {}
var _seat_scale_tweens: Dictionary = {}
var _texture_cache: Dictionary = {}
var _focused_seat := ""
var _table_overview := false
var _motion_reduced := false
var _shoe_remaining := 0
var _camera_tween: Tween = null
var _chip_stack_root: Node3D = null
var _chip_meshes: Array[MeshInstance3D] = []
var _last_chip_count := 0
var _outcome_cue_node: MeshInstance3D = null
var _active_tweens := 0
var _last_dog_reaction := ""
var _idle_tweens: Array[Tween] = []
var _hand_total_labels: Dictionary = {}
var _hand_total_renderer: SubViewport = null
var _hand_total_renderer_label: Label = null
var _hand_total_tex_cache: Dictionary = {}
var _hand_total_bake_queue: Array = []
var _hand_total_baking := false
var _room_prop_nodes: Array[Node3D] = []
var _configured_other_player_count := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_runtime_nodes()
	_apply_generated_model_meshes()
	_apply_isometric_camera()
	_setup_table_lighting()
	_setup_casino_room()
	_ensure_felt_labels()
	_apply_faceted_materials()
	_attach_shoe_label()
	_bind_seat_areas()
	_ensure_chip_stack_root()
	_ensure_hand_total_renderer()
	_ensure_outcome_cue_node()
	configure_table_dogs(2)
	set_process(true)


func _sync_subviewport_size() -> void:
	# SubViewportContainer.stretch=true resizes the inner SubViewport automatically.
	pass


func get_card_count() -> int:
	return _card_nodes.size()


func get_focused_seat() -> String:
	return _focused_seat


func is_table_overview() -> bool:
	return _table_overview


func set_table_overview(active: bool) -> void:
	if _table_overview == active:
		return
	_table_overview = active
	_set_room_backdrop_visible(not active)
	_refresh_all_hand_total_boards()
	_animate_camera_view()


func get_deal_snap_duration_ms(motion_reduced: bool) -> int:
	return MotionPreference.duration_ms(DEAL_SNAP_MS, motion_reduced)


func get_active_animation_count() -> int:
	return _active_tweens


func get_last_dog_reaction() -> String:
	return _last_dog_reaction


func has_chip_node() -> bool:
	return _chip_stack_root != null and _chip_meshes.size() > 0


func get_chip_stack_count() -> int:
	return _chip_meshes.size()


func is_outcome_cue_active() -> bool:
	return _outcome_cue_node != null and _outcome_cue_node.visible


func set_dog_count(count: int) -> void:
	configure_table_dogs(count)


func configure_table_dogs(other_player_count: int) -> void:
	var clamped := clampi(other_player_count, 0, _DOG_PLAYER_SLOTS.size())
	if clamped == _configured_other_player_count and not _dog_nodes.is_empty():
		return
	_configured_other_player_count = clamped
	_spawn_table_dogs(clamped)
	_start_dog_idle_loops()


func set_shoe_remaining(count: int) -> void:
	_shoe_remaining = count
	_ensure_shoe_count_display()
	if _shoe_label:
		_shoe_label.text = "%d" % count
		var display_root := _shoe_label.get_parent()
		if display_root:
			display_root.visible = count > 0


func _ensure_shoe_count_display() -> void:
	if _shoe == null:
		return
	var display: Node3D = _shoe.get_node_or_null("ShoeCountDisplay")
	if display != null:
		_shoe_label = display.get_node_or_null("Value") as Label3D
		return
	var legacy := _world.get_node_or_null("ShoeLabel") if _world else null
	if legacy != null:
		legacy.queue_free()
	if _shoe_label != null and _shoe_label.get_parent() != _shoe:
		_shoe_label.queue_free()
		_shoe_label = null
	display = _build_surface_number_node(Vector3(0.14, 0.006, 0.1), 16, false)
	display.name = "ShoeCountDisplay"
	display.position = Vector3(0.0, 0.3, 0.04)
	display.rotation_degrees = Vector3(-52, 0, 0)
	_shoe.add_child(display)
	_shoe_label = display.get_node("Value") as Label3D


func _attach_shoe_label() -> void:
	_ensure_shoe_count_display()


func sync_presentation(view: Dictionary, motion_reduced: bool = false) -> void:
	_ensure_runtime_nodes()
	_motion_reduced = motion_reduced
	var seats: Array = view.get("seats", [])
	set_shoe_remaining(int(view.get("shoeRemaining", 0)))
	_clear_cards()

	var other_index := 0
	for seat_view in seats:
		var seat_id := str(seat_view.get("seatId", ""))
		if seat_id == "dealer":
			_place_seat_cards(seat_view, _seat_position_for("dealer"), motion_reduced)
			continue
		if bool(seat_view.get("isLearner", false)):
			_place_seat_cards(seat_view, _seat_position_for("learner"), motion_reduced)
		else:
			var side_pos := Vector3(-1.1, TABLE_SURFACE_Y + 0.012, 0.48) if other_index % 2 == 0 else Vector3(1.1, TABLE_SURFACE_Y + 0.012, 0.48)
			_place_seat_cards(seat_view, side_pos, motion_reduced)
			other_index += 1

	_update_hand_totals(seats)


func focus_seat(seat_id: String, focused: bool) -> void:
	var previous := _focused_seat
	_focused_seat = seat_id if focused and seat_id != "" else ""
	if previous != "" and previous != _focused_seat:
		_animate_seat_card_scale(previous, 1.0)
	if _focused_seat != "":
		_animate_seat_card_scale(_focused_seat, FOCUS_CARD_SCALE)


func deal_cards(cards: Array, motion_reduced: bool = false) -> void:
	var view := {
		"seats": [{
			"seatId": "learner",
			"isLearner": true,
			"cards": cards,
			"scale": 1.0,
			"yaw": 0.0,
		}],
		"shoeRemaining": _shoe_remaining,
	}
	sync_presentation(view, motion_reduced)


func play_chip_bounce(_motion_reduced: bool = false) -> void:
	pass


func sync_chip_wager(wager: int, _phase: String, motion_reduced: bool = false) -> void:
	_ensure_runtime_nodes()
	_ensure_chip_stack_root()
	if wager <= 0:
		_clear_chip_stack()
		_last_chip_count = 0
		return

	var target_count := _chips_for_wager(wager)
	var prev_count := _chip_meshes.size()
	while _chip_meshes.size() < target_count:
		var index := _chip_meshes.size()
		var chip := _make_chip_mesh(index)
		_chip_stack_root.add_child(chip)
		_chip_meshes.append(chip)
		if index >= prev_count:
			_animate_chip_drop(chip, index, motion_reduced)
	while _chip_meshes.size() > target_count:
		var removed: MeshInstance3D = _chip_meshes.pop_back()
		removed.queue_free()
	_chip_stack_root.visible = _chip_meshes.size() > 0
	_last_chip_count = _chip_meshes.size()


func play_dog_reaction(reaction: String, motion_reduced: bool = false) -> void:
	_last_dog_reaction = reaction
	if _dog_bodies.is_empty():
		return
	var body: MeshInstance3D = _dog_bodies[0]
	var duration_ms: int = MotionPreference.duration_ms(DOG_REACTION_MS, motion_reduced)
	var base_y: float = body.position.y
	if duration_ms <= 0:
		body.rotation.z = 0.0
		body.scale = Vector3.ONE
		body.position.y = base_y
		return
	_track_tween(_dog_reaction_tween(body, reaction, base_y, duration_ms))


func play_outcome_cue(outcome: String, motion_reduced: bool = false) -> void:
	_ensure_runtime_nodes()
	_ensure_outcome_cue_node()
	if _outcome_cue_node == null:
		return
	_outcome_cue_node.visible = true
	var duration_ms: int = MotionPreference.duration_ms(OUTCOME_CUE_MS, motion_reduced)
	match outcome:
		"win":
			_outcome_cue_node.modulate = Color(1.0, 0.95, 0.55, 0.9)
		"loss":
			_outcome_cue_node.modulate = Color(0.55, 0.62, 0.85, 0.75)
		_:
			_outcome_cue_node.modulate = Color(0.9, 0.9, 0.9, 0.5)
	if duration_ms <= 0:
		_outcome_cue_node.visible = false
		return
	_track_tween(_outcome_cue_tween(duration_ms))


func _seat_position_for(seat_id: String) -> Vector3:
	return _SEAT_CARD_BASES.get(seat_id, Vector3.ZERO)


func _place_seat_cards(seat_view: Dictionary, base_pos: Vector3, motion_reduced: bool) -> void:
	var seat_id := str(seat_view.get("seatId", ""))
	var group := _ensure_seat_card_group(seat_id, base_pos)
	group.rotation.y = float(seat_view.get("yaw", 0.0))
	var cards: Array = seat_view.get("cards", [])
	var scale: float = float(seat_view.get("scale", 1.0))
	for i in cards.size():
		var card_data: Dictionary = cards[i]
		var card := _create_card_mesh(card_data)
		card.scale = Vector3(scale, 1.0, scale)
		group.add_child(card)
		_card_nodes.append(card)

		var fan: float = float(card_data.get("fanAngle", 0.0))
		var lift: float = float(i) * 0.003
		var target := Vector3(fan * 0.55, 0.008 + lift, absf(fan) * 0.12)
		_animate_card_to(card, target, motion_reduced)

	if _focused_seat == seat_id:
		group.scale = Vector3(FOCUS_CARD_SCALE, FOCUS_CARD_SCALE, FOCUS_CARD_SCALE)


func _apply_generated_model_meshes() -> void:
	_apply_blackjack_table_mesh()
	if _table != null:
		_table.visible = true
	if _table_rim != null:
		_table_rim.visible = true
	var shoe_mesh: Mesh = _mesh_from_glb(SHOE_MODEL)
	if shoe_mesh != null and _shoe != null:
		_shoe.mesh = shoe_mesh
	var tray_mesh: Mesh = _mesh_from_glb(DISCARD_MODEL)
	if tray_mesh != null and _discard_tray != null:
		_discard_tray.mesh = tray_mesh
	var lamp_mesh: Mesh = _mesh_from_glb(LAMP_MODEL)
	if lamp_mesh != null and _room_root != null:
		var lamp_shade: MeshInstance3D = _room_root.get_node_or_null("LampMesh/LampShade")
		if lamp_shade:
			lamp_shade.mesh = lamp_mesh
	var plant_mesh: Mesh = _mesh_from_glb(PLANT_MODEL)
	if plant_mesh != null and _room_root != null:
		for plant_name in ["Plant1", "Plant2"]:
			var plant: Node3D = _room_root.get_node_or_null(plant_name)
			if plant:
				var pot: MeshInstance3D = plant.get_node_or_null("Pot")
				if pot:
					pot.mesh = plant_mesh
				var leaves: MeshInstance3D = plant.get_node_or_null("PlantLeaves")
				if leaves and plant_mesh != null:
					leaves.mesh = plant_mesh


func _apply_blackjack_table_mesh() -> void:
	if _table == null or _table_rim == null:
		return
	var outline := _blackjack_table_outline()
	_table.mesh = _build_table_felt_mesh(outline)
	_table.position = Vector3(0.0, TABLE_SURFACE_Y, 0.0)
	_table.scale = Vector3.ONE
	_table_rim.mesh = _build_table_rim_mesh(outline)
	_table_rim.position = Vector3(0.0, TABLE_SURFACE_Y, 0.0)
	_table_rim.scale = Vector3.ONE


func _blackjack_table_outline() -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i in range(TABLE_ARC_SEGMENTS + 1):
		var t := float(i) / float(TABLE_ARC_SEGMENTS)
		var angle := lerpf(0.0, PI, t)
		points.append(Vector2(
			TABLE_RX * cos(angle),
			TABLE_DEALER_Z + TABLE_RZ * sin(angle)
		))
	return points


func _outline_centroid(outline: PackedVector2Array) -> Vector2:
	var center := Vector2.ZERO
	for point in outline:
		center += point
	return center / float(maxi(outline.size(), 1))


func _expand_outline(outline: PackedVector2Array, amount: float) -> PackedVector2Array:
	var center := _outline_centroid(outline)
	var expanded: PackedVector2Array = []
	for point in outline:
		var dir := point - center
		if dir.length_squared() < 0.0001:
			expanded.append(point)
			continue
		expanded.append(point + dir.normalized() * amount)
	return expanded


func _build_table_felt_mesh(outline: PackedVector2Array) -> ArrayMesh:
	var center := _outline_centroid(outline)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	st.add_vertex(Vector3(center.x, 0.0, center.y))
	for point in outline:
		st.add_vertex(Vector3(point.x, 0.0, point.y))
	for i in range(outline.size() - 1):
		st.add_index(0)
		st.add_index(i + 1)
		st.add_index(i + 2)
	return st.commit()


func _build_table_rim_mesh(outline: PackedVector2Array) -> ArrayMesh:
	var outer := _expand_outline(outline, TABLE_RIM_OUTSET)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertex_index := 0
	for i in outline.size():
		var next_i := (i + 1) % outline.size()
		var inner_a := outline[i]
		var inner_b := outline[next_i]
		var outer_a := outer[i]
		var outer_b := outer[next_i]
		var top_inner_a := Vector3(inner_a.x, 0.0, inner_a.y)
		var top_inner_b := Vector3(inner_b.x, 0.0, inner_b.y)
		var top_outer_a := Vector3(outer_a.x, 0.0, outer_a.y)
		var top_outer_b := Vector3(outer_b.x, 0.0, outer_b.y)
		var bot_inner_a := top_inner_a + Vector3(0.0, -TABLE_RIM_DROP, 0.0)
		var bot_inner_b := top_inner_b + Vector3(0.0, -TABLE_RIM_DROP, 0.0)
		var bot_outer_a := top_outer_a + Vector3(0.0, -TABLE_RIM_DROP, 0.0)
		var bot_outer_b := top_outer_b + Vector3(0.0, -TABLE_RIM_DROP, 0.0)
		vertex_index = _add_rim_quad(st, top_outer_a, top_outer_b, bot_outer_b, bot_outer_a, vertex_index)
		vertex_index = _add_rim_quad(st, top_inner_a, top_outer_a, bot_outer_a, bot_inner_a, vertex_index)
		vertex_index = _add_rim_quad(st, top_inner_b, bot_inner_b, bot_outer_b, top_outer_b, vertex_index)
	return st.commit()


func _add_rim_quad(
	st: SurfaceTool,
	v0: Vector3,
	v1: Vector3,
	v2: Vector3,
	v3: Vector3,
	vertex_index: int
) -> int:
	var normal := (v1 - v0).cross(v3 - v0).normalized()
	if normal.length_squared() < 0.0001:
		normal = Vector3.UP
	var base := vertex_index
	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v1)
	st.set_normal(normal)
	st.add_vertex(v2)
	st.set_normal(normal)
	st.add_vertex(v3)
	st.add_index(base)
	st.add_index(base + 1)
	st.add_index(base + 2)
	st.add_index(base)
	st.add_index(base + 2)
	st.add_index(base + 3)
	return base + 4


func _apply_isometric_camera() -> void:
	if _camera == null:
		return
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = CAMERA_HOME_SIZE
	_camera.position = CAMERA_HOME_POS
	_camera.look_at(CAMERA_HOME_LOOK, Vector3.UP)
	_camera.current = true


func _setup_table_lighting() -> void:
	if _world == null:
		return
	var lamp := _world.get_node_or_null("LampLight") as OmniLight3D
	if lamp != null:
		lamp.position = Vector3(0.0, 3.35, 0.0)
		lamp.light_color = Color(1.0, 0.9, 0.72)
		lamp.light_energy = 2.4
		lamp.omni_range = 8.5
	var fill := _world.get_node_or_null("FillLight") as OmniLight3D
	if fill != null:
		fill.light_energy = 0.55
	var sun := _world.get_node_or_null("Sun") as DirectionalLight3D
	if sun != null:
		sun.light_energy = 0.3
	var overhead := _world.get_node_or_null("OverheadSpot") as SpotLight3D
	if overhead == null:
		overhead = SpotLight3D.new()
		overhead.name = "OverheadSpot"
		_world.add_child(overhead)
	overhead.position = Vector3(0.0, 3.45, 0.0)
	overhead.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	overhead.light_color = Color(1.0, 0.94, 0.82)
	overhead.light_energy = 4.0
	overhead.spot_range = 8.0
	overhead.spot_angle = 52.0
	overhead.shadow_enabled = true


func _setup_casino_room() -> void:
	if _room_root == null:
		return
	for clutter_name in [
		"Bookshelf", "Clock", "WindowFrame", "WindowGlass", "Skyline",
		"WallArt", "Plant1", "Plant2", "Floor", "BackWall", "Wainscot",
		"LeftWall", "RightWall",
	]:
		var clutter := _room_root.get_node_or_null(clutter_name)
		if clutter != null:
			clutter.queue_free()
	if _room_root.get_node_or_null("CasinoRoom") != null:
		_room_root.get_node_or_null("CasinoRoom").queue_free()
	var room := Node3D.new()
	room.name = "CasinoRoom"
	_room_root.add_child(room)
	var half_w := 4.8
	var half_d := 3.1
	var wall_h := 2.5
	var side_depth := 3.4
	var side_center_z := -0.65
	_add_room_panel(room, Vector3(0.0, -0.02, 0.0), Vector3(half_w * 2.0, 0.04, half_d * 2.0 + 0.4), "Floor")
	_add_room_panel(room, Vector3(0.0, wall_h * 0.5, -half_d), Vector3(half_w * 2.0, wall_h, 0.14), "BackWall")
	_add_room_panel(room, Vector3(0.0, 0.55, -half_d + 0.06), Vector3(half_w * 2.0, 1.0, 0.16), "WainscotBack")
	_add_room_panel(room, Vector3(-half_w, wall_h * 0.5, side_center_z), Vector3(0.14, wall_h, side_depth), "LeftWall")
	_add_room_panel(room, Vector3(-half_w + 0.06, 0.55, side_center_z), Vector3(0.16, 1.0, side_depth), "WainscotLeft")
	_add_room_panel(room, Vector3(half_w, wall_h * 0.5, side_center_z), Vector3(0.14, wall_h, side_depth), "RightWall")
	_add_room_panel(room, Vector3(half_w - 0.06, 0.55, side_center_z), Vector3(0.16, 1.0, side_depth), "WainscotRight")
	var env := _world.get_node_or_null("WorldEnvironment") as WorldEnvironment if _world else null
	if env != null and env.environment != null:
		env.environment.background_color = Color(0.12, 0.22, 0.14)


func _add_room_panel(parent: Node3D, pos: Vector3, panel_size: Vector3, panel_name: String) -> void:
	var panel := MeshInstance3D.new()
	panel.name = panel_name
	var mesh := BoxMesh.new()
	mesh.size = panel_size
	panel.mesh = mesh
	panel.position = pos
	parent.add_child(panel)


func _spawn_room_props() -> void:
	pass


func _ensure_felt_labels() -> void:
	if _world == null or _world.get_node_or_null("FeltLabels") != null:
		return
	var root := Node3D.new()
	root.name = "FeltLabels"
	_world.add_child(root)
	var lines := ["BLACKJACK", "DEALER MUST HIT SOFT 17", "INSURANCE PAYS 2 TO 1"]
	for i in lines.size():
		var anchor := _build_felt_text_marker(lines[i], 24)
		anchor.position = Vector3(0.0, TABLE_SURFACE_Y, -0.22 + float(i) * 0.16)
		root.add_child(anchor)


func _build_felt_text_marker(text: String, font_size: int) -> Node3D:
	var anchor := Node3D.new()
	var lbl := Label3D.new()
	lbl.name = "Text"
	lbl.text = text
	lbl.font_size = font_size
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lbl.modulate = Color(0.86, 0.72, 0.28)
	lbl.position = Vector3(0.0, 0.002, 0.0)
	lbl.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	anchor.add_child(lbl)
	return anchor


func _build_hand_total_board() -> Node3D:
	var root := Node3D.new()
	var plaque := _build_hand_total_plaque()
	plaque.name = "Plaque"
	root.add_child(plaque)
	return root


func _build_hand_total_plaque() -> Node3D:
	var root := Node3D.new()
	var frame := MeshInstance3D.new()
	frame.name = "Frame"
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = HAND_BOARD_SIZE
	frame.mesh = frame_mesh
	_paint_mesh(frame, HAND_BOARD_FRAME)
	root.add_child(frame)

	var face_display := MeshInstance3D.new()
	face_display.name = "FaceDisplay"
	var plane := PlaneMesh.new()
	plane.size = Vector2(HAND_BOARD_SIZE.x * 0.82, HAND_BOARD_SIZE.z * 0.78)
	face_display.mesh = plane
	face_display.position = Vector3(0.0, HAND_BOARD_SIZE.y * 0.52, 0.0)
	face_display.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_paint_mesh(face_display, HAND_BOARD_FACE)
	root.add_child(face_display)

	var value_label := Label3D.new()
	value_label.name = "Value"
	value_label.text = ""
	value_label.font_size = HAND_BOARD_HOME_FONT
	value_label.modulate = HAND_BOARD_TEXT
	value_label.outline_size = 8
	value_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	value_label.position = Vector3(0.0, HAND_BOARD_SIZE.y * 0.52 + 0.008, 0.0)
	value_label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	var font := UiTheme.get_heavy_font()
	if font != null:
		value_label.font = font
	root.add_child(value_label)

	var stand := MeshInstance3D.new()
	stand.name = "Stand"
	var stand_mesh := BoxMesh.new()
	stand_mesh.size = Vector3(HAND_BOARD_SIZE.x * 0.72, 0.05, HAND_BOARD_SIZE.z * 0.34)
	stand.mesh = stand_mesh
	stand.position = Vector3(0.0, 0.018, -HAND_BOARD_SIZE.z * 0.34)
	stand.rotation_degrees = Vector3(-24.0, 0.0, 0.0)
	_paint_mesh(stand, HAND_BOARD_FRAME.darkened(0.08))
	root.add_child(stand)
	return root


func _ensure_hand_total_renderer() -> void:
	if _hand_total_renderer != null:
		return
	_hand_total_renderer = SubViewport.new()
	_hand_total_renderer.name = "HandTotalRenderer"
	_hand_total_renderer.size = Vector2i(384, 288)
	_hand_total_renderer.disable_3d = true
	_hand_total_renderer.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var holder := Node.new()
	holder.name = "HandTotalRenderUtility"
	add_child(holder)
	holder.add_child(_hand_total_renderer)

	var backdrop := ColorRect.new()
	backdrop.color = HAND_BOARD_FACE
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hand_total_renderer.add_child(backdrop)

	_hand_total_renderer_label = Label.new()
	_hand_total_renderer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hand_total_renderer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hand_total_renderer_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	var font := UiTheme.get_heavy_font()
	if font != null:
		_hand_total_renderer_label.add_theme_font_override("font", font)
	_hand_total_renderer_label.add_theme_font_size_override("font_size", 168)
	_hand_total_renderer_label.add_theme_color_override("font_color", HAND_BOARD_TEXT)
	_hand_total_renderer.add_child(_hand_total_renderer_label)


func _queue_hand_total_texture(face: MeshInstance3D, text: String) -> void:
	if face == null or text == "":
		return
	if _hand_total_tex_cache.has(text):
		_apply_hand_total_face_texture(face, _hand_total_tex_cache[text])
		return
	_hand_total_bake_queue.append({"face": face, "text": text})
	if not _hand_total_baking:
		_hand_total_baking = true
		_process_hand_total_bake_queue()


func _process_hand_total_bake_queue() -> void:
	if _hand_total_bake_queue.is_empty():
		_hand_total_baking = false
		return
	var item: Dictionary = _hand_total_bake_queue[0]
	var text: String = str(item.get("text", ""))
	var face: MeshInstance3D = item.get("face")
	_hand_total_bake_queue.remove_at(0)
	if text == "" or face == null or not is_instance_valid(face):
		_process_hand_total_bake_queue()
		return
	if _hand_total_tex_cache.has(text):
		_apply_hand_total_face_texture(face, _hand_total_tex_cache[text])
		_process_hand_total_bake_queue()
		return
	_ensure_hand_total_renderer()
	var overview := _table_overview
	_hand_total_renderer_label.text = text
	_hand_total_renderer_label.add_theme_font_size_override(
		"font_size",
		220 if overview else 168
	)
	var backdrop: ColorRect = _hand_total_renderer.get_child(0) as ColorRect
	if backdrop != null:
		backdrop.color = HAND_BOARD_OVERVIEW_FACE if overview else HAND_BOARD_FACE
	_hand_total_renderer_label.add_theme_color_override(
		"font_color",
		Color(0.08, 0.08, 0.1) if overview else HAND_BOARD_TEXT
	)
	_hand_total_renderer.render_target_update_mode = SubViewport.UPDATE_ONCE
	_bake_hand_total_texture_when_ready(text, face)


func _bake_hand_total_texture_when_ready(text: String, face: MeshInstance3D) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var viewport_tex: ViewportTexture = _hand_total_renderer.get_texture()
	if viewport_tex != null:
		var image: Image = viewport_tex.get_image()
		if image != null and not image.is_empty():
			var baked := ImageTexture.create_from_image(image)
			_hand_total_tex_cache[text] = baked
			if is_instance_valid(face):
				_apply_hand_total_face_texture(face, baked)
	_hand_total_renderer.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_process_hand_total_bake_queue()


func _apply_hand_total_face_texture(face: MeshInstance3D, tex: Texture2D) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = Color.WHITE
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	face.material_override = mat


func _build_surface_number_node(plaque_size: Vector3, font_size: int, flat_on_table: bool) -> Node3D:
	var root := Node3D.new()
	var plaque := _build_number_plaque(plaque_size)
	plaque.name = "Plaque"
	root.add_child(plaque)
	var lbl := Label3D.new()
	lbl.name = "Value"
	lbl.font_size = font_size
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lbl.modulate = SURFACE_TEXT_COLOR
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector3(0.0, plaque_size.y * 0.5 + 0.001, 0.0)
	if flat_on_table:
		lbl.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	else:
		lbl.rotation_degrees = Vector3(-72.0, 0.0, 0.0)
	root.add_child(lbl)
	return root


func _build_number_plaque(size: Vector3) -> MeshInstance3D:
	var plaque := MeshInstance3D.new()
	var glb_mesh: Mesh = _mesh_from_glb(HAND_DISPLAY_MODEL)
	if glb_mesh != null:
		plaque.mesh = glb_mesh
		plaque.scale = Vector3(
			size.x / 0.18,
			size.y / 0.12,
			size.z / 0.04,
		)
	else:
		var mesh := BoxMesh.new()
		mesh.size = size
		plaque.mesh = mesh
	_paint_mesh(plaque, SURFACE_PLAQUE_BASE)
	var face := MeshInstance3D.new()
	face.name = "Face"
	var face_mesh := BoxMesh.new()
	face_mesh.size = Vector3(size.x * 0.82, maxf(size.y * 0.35, 0.002), size.z * 0.72)
	face.mesh = face_mesh
	face.position = Vector3(0.0, size.y * 0.45, 0.0)
	_paint_mesh(face, SURFACE_PLAQUE_FACE)
	plaque.add_child(face)
	return plaque


func _update_hand_totals(seats: Array) -> void:
	for seat_view in seats:
		var seat_id := str(seat_view.get("seatId", ""))
		if seat_id == "":
			continue
		var cards: Array = seat_view.get("cards", [])
		var total := 0
		var hide_board := false
		if not cards.is_empty():
			var raw_cards: Array = []
			for card_data in cards:
				if bool(card_data.get("faceUp", true)):
					raw_cards.append({"rank": card_data.get("rank", 0)})
				elif seat_id == "dealer":
					hide_board = true
			if not raw_cards.is_empty() and not hide_board:
				total = int(Hand.hand_value(raw_cards)["total"])
		_ensure_hand_total_label(seat_id, total)


func _ensure_hand_total_label(seat_id: String, total: int) -> void:
	if _world == null:
		return
	if not _hand_total_labels.has(seat_id):
		var display := _build_hand_total_board()
		display.name = "HandTotal_%s" % seat_id
		_world.add_child(display)
		_hand_total_labels[seat_id] = display
	elif _hand_total_labels[seat_id].get_node_or_null("Plaque") == null:
		_hand_total_labels[seat_id].queue_free()
		_hand_total_labels.erase(seat_id)
		_ensure_hand_total_label(seat_id, total)
		return
	var anchor_node: Node3D = _hand_total_labels[seat_id]
	_style_hand_total_board(anchor_node, seat_id)
	anchor_node.visible = total > 0
	var value_label: Label3D = anchor_node.get_node_or_null("Plaque/Value")
	var face_display: MeshInstance3D = anchor_node.get_node_or_null("Plaque/FaceDisplay")
	var total_text := str(total) if total > 0 else ""
	if value_label != null:
		value_label.text = total_text
	if face_display != null:
		if total > 0:
			_queue_hand_total_texture(face_display, total_text)
		else:
			_paint_mesh(face_display, HAND_BOARD_FACE)


func _attach_hand_total_board(board: Node3D, seat_id: String) -> void:
	if board.get_parent() != _world:
		if board.get_parent() != null:
			board.reparent(_world)
		else:
			_world.add_child(board)
	board.position = _hand_total_world_position(seat_id)
	board.rotation_degrees = Vector3(-HAND_BOARD_TILT_DEG, _hand_total_yaw_deg(seat_id), 0.0)


func _style_hand_total_board(board: Node3D, seat_id: String) -> void:
	_attach_hand_total_board(board, seat_id)
	var frame: Node3D = board.get_node_or_null("Plaque/Frame")
	var face_display: MeshInstance3D = board.get_node_or_null("Plaque/FaceDisplay")
	var value_label: Label3D = board.get_node_or_null("Plaque/Value")
	var stand: Node3D = board.get_node_or_null("Plaque/Stand")
	if _table_overview:
		board.scale = Vector3.ONE * HAND_BOARD_OVERVIEW_SCALE
		board.position = _hand_total_overview_position(seat_id)
		board.rotation_degrees = Vector3(0.0, _hand_total_yaw_deg(seat_id), 0.0)
		if frame != null:
			frame.visible = false
		if stand != null:
			stand.visible = false
		if face_display != null:
			face_display.visible = true
			face_display.position = Vector3(0.0, 0.006, 0.0)
			face_display.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
			if face_display.material_override == null:
				_paint_mesh(face_display, HAND_BOARD_OVERVIEW_FACE)
		if value_label != null:
			value_label.font_size = HAND_BOARD_OVERVIEW_FONT
			value_label.position = Vector3(0.0, 0.018, 0.0)
			value_label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
			value_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			value_label.no_depth_test = true
	else:
		board.scale = Vector3.ONE
		if frame != null:
			frame.visible = true
		if stand != null:
			stand.visible = true
		if face_display != null:
			face_display.visible = true
			face_display.position = Vector3(0.0, HAND_BOARD_SIZE.y * 0.52, 0.0)
			face_display.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		if value_label != null:
			value_label.font_size = HAND_BOARD_HOME_FONT
			value_label.position = Vector3(0.0, HAND_BOARD_SIZE.y * 0.52 + 0.008, 0.0)
			value_label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
			value_label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
			value_label.no_depth_test = false


func _hand_total_overview_position(seat_id: String) -> Vector3:
	var base: Vector3 = _SEAT_CARD_BASES.get(seat_id, Vector3.ZERO)
	if _seat_card_groups.has(seat_id):
		base = _seat_card_groups[seat_id].position
	var offset: Vector3 = _hand_total_overview_offset(seat_id)
	return Vector3(base.x + offset.x, TABLE_SURFACE_Y + 0.02, base.z + offset.z)


func _hand_total_overview_offset(seat_id: String) -> Vector3:
	match seat_id:
		"dealer":
			return Vector3(0.34, 0.0, 0.22)
		"learner":
			return Vector3(0.34, 0.0, -0.24)
		_:
			if _seat_card_groups.has(seat_id):
				var base_x: float = _seat_card_groups[seat_id].position.x
				if base_x < -0.5:
					return Vector3(0.28, 0.0, -0.16)
				if base_x > 0.5:
					return Vector3(-0.28, 0.0, -0.16)
			return Vector3(0.28, 0.0, -0.16)


func _refresh_all_hand_total_boards() -> void:
	for seat_id in _hand_total_labels.keys():
		var board: Node3D = _hand_total_labels[seat_id]
		if is_instance_valid(board) and board.visible:
			_style_hand_total_board(board, str(seat_id))
			var value_label: Label3D = board.get_node_or_null("Plaque/Value")
			var face_display: MeshInstance3D = board.get_node_or_null("Plaque/FaceDisplay")
			if value_label != null and face_display != null and value_label.text != "":
				_queue_hand_total_texture(face_display, value_label.text)


func _hand_total_world_position(seat_id: String) -> Vector3:
	var base: Vector3 = _SEAT_CARD_BASES.get(seat_id, Vector3.ZERO)
	if _seat_card_groups.has(seat_id):
		base = _seat_card_groups[seat_id].position
	var offset: Vector3 = _hand_total_board_offset(seat_id)
	return Vector3(base.x + offset.x, TABLE_SURFACE_Y + 0.24, base.z + offset.z)


func _hand_total_board_offset(seat_id: String) -> Vector3:
	match seat_id:
		"dealer":
			return Vector3(0.24, 0.0, 0.12)
		"learner":
			return Vector3(0.24, 0.0, 0.14)
		_:
			if _seat_card_groups.has(seat_id):
				var base_x: float = _seat_card_groups[seat_id].position.x
				if base_x < -0.5:
					return Vector3(0.20, 0.0, 0.12)
				if base_x > 0.5:
					return Vector3(-0.20, 0.0, 0.12)
			return Vector3(0.20, 0.0, 0.12)


func _hand_total_yaw_deg(seat_id: String) -> float:
	match seat_id:
		"dealer":
			return 180.0
		_:
			if _seat_card_groups.has(seat_id):
				var base_x: float = _seat_card_groups[seat_id].position.x
				if base_x < -0.5:
					return -18.0
				if base_x > 0.5:
					return 18.0
			return 0.0


func _paint_node_meshes(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		_paint_mesh(node, color)
	for child in node.get_children():
		_paint_node_meshes(child, color)


func _mesh_from_glb(glb: PackedScene) -> Mesh:
	if glb == null:
		return null
	var inst: Node = glb.instantiate()
	var found: Mesh = _find_mesh_in_node(inst)
	inst.queue_free()
	return found


func _find_mesh_in_node(node: Node) -> Mesh:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return (node as MeshInstance3D).mesh
	for child in node.get_children():
		var found := _find_mesh_in_node(child)
		if found != null:
			return found
	return null


func _apply_faceted_materials() -> void:
	_paint_mesh(_table, Color(0.12, 0.48, 0.24))
	_paint_mesh(_table_rim, Color(0.52, 0.34, 0.18))
	_paint_mesh(_shoe, Color(0.42, 0.32, 0.22))
	_paint_mesh(_discard_tray, Color(0.38, 0.28, 0.2))
	_paint_static_chips()
	_paint_world_props()

	if _room_root:
		for child in _room_root.get_children():
			_paint_room_node(child)


func _paint_static_chips() -> void:
	var parent := _table.get_parent() if _table else null
	if parent == null:
		return
	var chip_colors := [
		Color(0.82, 0.18, 0.16),
		Color(0.22, 0.62, 0.32),
		Color(0.52, 0.28, 0.72),
	]
	var idx := 0
	for child in parent.get_children():
		if str(child.name).begins_with("ChipStack"):
			_paint_mesh(child, chip_colors[idx % chip_colors.size()])
			idx += 1


func _paint_world_props() -> void:
	var world: Node = _table.get_parent() if _table else null
	if world == null:
		return
	if _chip_stack_root != null:
		for chip in _chip_meshes:
			if is_instance_valid(chip):
				var stripe := _chip_meshes.find(chip) % 2 == 0
				_paint_mesh(chip, Color(0.82, 0.18, 0.16) if stripe else Color(0.96, 0.9, 0.78))


func _paint_room_node(node: Node) -> void:
	if node is MeshInstance3D:
		var color := Color(0.42, 0.3, 0.2)
		if node.name.contains("BackWall"):
			color = Color(0.14, 0.32, 0.18)
		elif node.name.contains("Wall"):
			color = Color(0.16, 0.34, 0.2)
		elif node.name.contains("Wainscot"):
			color = Color(0.38, 0.26, 0.16)
		elif node.name.contains("Ceiling"):
			color = Color(0.14, 0.14, 0.16)
		elif node.name.contains("Floor"):
			color = Color(0.42, 0.3, 0.2)
		elif node.name.contains("Lamp") or _is_lamp_child(node):
			color = Color(0.92, 0.78, 0.45)
		elif node.name.contains("Plant"):
			color = Color(0.22, 0.48, 0.24)
		elif node.name.contains("Pot"):
			color = Color(0.5, 0.32, 0.2)
		elif node.name.contains("Book"):
			color = Color(0.38, 0.24, 0.16)
		elif node.name.contains("Clock"):
			color = Color(0.55, 0.48, 0.38)
		elif node.name.contains("Window"):
			color = Color(0.35, 0.5, 0.65)
		elif node.name.contains("Skyline"):
			color = Color(0.12, 0.14, 0.22)
		elif node.name.contains("Art"):
			color = Color(0.55, 0.35, 0.28)
		elif node.name.contains("Chip"):
			color = Color(0.78, 0.2, 0.18)
		_paint_mesh(node, color)
	for child in node.get_children():
		_paint_room_node(child)


func _paint_mesh(mesh_instance: MeshInstance3D, color: Color) -> void:
	if mesh_instance == null:
		return
	if CEL_SHADER != null:
		var cel := ShaderMaterial.new()
		cel.shader = CEL_SHADER
		cel.set_shader_parameter("albedo_color", color)
		mesh_instance.material_override = cel
		return
	if FACETED_MAT == null:
		return
	var mat: StandardMaterial3D = FACETED_MAT.duplicate()
	mat.albedo_color = color
	mesh_instance.material_override = mat


func _is_lamp_child(node: Node) -> bool:
	var parent := node.get_parent()
	return parent != null and str(parent.name).contains("Lamp")


func _seat_id_from_area(area_name: String) -> String:
	var base := area_name.replace("Area", "")
	if base.begins_with("Seat") and base.length() > 4:
		return "seat-%s" % base.substr(4)
	return base.to_lower()


func _bind_seat_areas() -> void:
	if _seat_areas == null:
		return
	for child in _seat_areas.get_children():
		if child is Area3D:
			var seat_id := _seat_id_from_area(str(child.name))
			_seat_area_nodes[seat_id] = child
			if not child.mouse_entered.is_connected(_on_seat_mouse_entered):
				child.mouse_entered.connect(_on_seat_mouse_entered.bind(seat_id))
			if not child.mouse_exited.is_connected(_on_seat_mouse_exited):
				child.mouse_exited.connect(_on_seat_mouse_exited.bind(seat_id))


func _on_seat_mouse_entered(seat_id: String) -> void:
	if _table_overview:
		return
	focus_seat(seat_id, true)


func _on_seat_mouse_exited(seat_id: String) -> void:
	if _table_overview:
		return
	if _focused_seat == seat_id:
		focus_seat("", false)


func _process(_delta: float) -> void:
	_update_hover_from_mouse()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_update_hover_from_mouse()


func _update_hover_from_mouse() -> void:
	if _subviewport == null or _camera == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var local := get_local_mouse_position()
	var over_table := local.x >= 0.0 and local.y >= 0.0 and local.x <= size.x and local.y <= size.y
	set_table_overview(over_table)
	if not over_table and _focused_seat != "":
		focus_seat("", false)


func _seat_id_from_collider(collider: Object) -> String:
	for seat_id in _seat_area_nodes.keys():
		if _seat_area_nodes[seat_id] == collider:
			return seat_id
	return ""


func _ensure_seat_card_group(seat_id: String, base_pos: Vector3) -> Node3D:
	if _seat_card_groups.has(seat_id):
		var existing: Node3D = _seat_card_groups[seat_id]
		existing.position = base_pos
		return existing
	var group := Node3D.new()
	group.name = "Cards_%s" % seat_id
	group.position = base_pos
	_card_root.add_child(group)
	_seat_card_groups[seat_id] = group
	return group


func _animate_seat_card_scale(seat_id: String, target_scale: float) -> void:
	if not _seat_card_groups.has(seat_id):
		return
	var group: Node3D = _seat_card_groups[seat_id]
	if _seat_scale_tweens.has(seat_id):
		var old_tween: Tween = _seat_scale_tweens[seat_id]
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()
		_seat_scale_tweens.erase(seat_id)

	var target := Vector3(target_scale, target_scale, target_scale)
	var duration_ms := MotionPreference.duration_ms(FOCUS_ZOOM_MS, _motion_reduced)
	if duration_ms <= 0:
		group.scale = target
		return
	var tween := create_tween()
	tween.tween_property(group, "scale", target, float(duration_ms) / 1000.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_seat_scale_tweens[seat_id] = tween


func _camera_view_targets(overview: bool) -> Dictionary:
	if overview:
		return {
			"position": CAMERA_TOPDOWN_POS,
			"rotation": CAMERA_TOPDOWN_ROT,
			"size": CAMERA_TOPDOWN_SIZE,
		}
	var cam := Camera3D.new()
	cam.look_at_from_position(CAMERA_HOME_POS, CAMERA_HOME_LOOK, Vector3.UP)
	var home_rot := cam.rotation
	cam.free()
	return {
		"position": CAMERA_HOME_POS,
		"rotation": home_rot,
		"size": CAMERA_HOME_SIZE,
	}


func _animate_camera_view() -> void:
	if _camera == null:
		return
	if _camera_tween != null and _camera_tween.is_valid():
		_camera_tween.kill()

	var targets := _camera_view_targets(_table_overview)
	var target_pos: Vector3 = targets["position"]
	var target_rot: Vector3 = targets["rotation"]
	var target_size: float = targets["size"]

	var duration_ms := MotionPreference.duration_ms(FOCUS_ZOOM_MS, _motion_reduced)
	if duration_ms <= 0:
		_camera.position = target_pos
		_camera.rotation = target_rot
		_camera.size = target_size
		return

	_camera_tween = create_tween()
	_camera_tween.set_parallel(true)
	_camera_tween.tween_property(_camera, "position", target_pos, float(duration_ms) / 1000.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(_camera, "rotation", target_rot, float(duration_ms) / 1000.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(_camera, "size", target_size, float(duration_ms) / 1000.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _set_room_backdrop_visible(visible: bool) -> void:
	if _room_root == null:
		return
	var room := _room_root.get_node_or_null("CasinoRoom")
	if room != null:
		room.visible = visible


func _ensure_runtime_nodes() -> void:
	if _card_root != null:
		return
	var viewport := SubViewport.new()
	viewport.name = "SubViewport"
	add_child(viewport)
	_world = Node3D.new()
	_world.name = "World"
	viewport.add_child(_world)
	_table = MeshInstance3D.new()
	_table.name = "TableMesh"
	_table.unique_name_in_owner = true
	_world.add_child(_table)
	_shoe = MeshInstance3D.new()
	_shoe.name = "ShoeMesh"
	_shoe.unique_name_in_owner = true
	_world.add_child(_shoe)
	_seat_root = Node3D.new()
	_seat_root.name = "SeatRoot"
	_seat_root.unique_name_in_owner = true
	_world.add_child(_seat_root)
	_card_root = Node3D.new()
	_card_root.name = "CardRoot"
	_card_root.unique_name_in_owner = true
	_world.add_child(_card_root)
	_shoe_label = null


func _ensure_chip_stack_root() -> void:
	if _chip_stack_root != null:
		return
	var parent := _world if _world != null else _card_root.get_parent() if _card_root else self
	_chip_stack_root = Node3D.new()
	_chip_stack_root.name = "ChipStack"
	_chip_stack_root.position = CHIP_STACK_POS
	_chip_stack_root.visible = false
	parent.add_child(_chip_stack_root)


func _chips_for_wager(wager: int) -> int:
	return clampi(maxi(1, wager / 5), 1, 12)


func _make_chip_mesh(stack_index: int) -> MeshInstance3D:
	var chip := MeshInstance3D.new()
	chip.name = "Chip%d" % stack_index
	var glb_mesh: Mesh = _mesh_from_glb(CHIP_MODEL)
	if glb_mesh != null:
		chip.mesh = glb_mesh
	else:
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.1
		mesh.bottom_radius = 0.1
		mesh.height = CHIP_LAYER_HEIGHT
		chip.mesh = mesh
	var chip_colors := [
		Color(0.82, 0.18, 0.16),
		Color(0.22, 0.62, 0.32),
		Color(0.52, 0.28, 0.72),
		Color(0.22, 0.42, 0.82),
	]
	_paint_mesh(chip, chip_colors[stack_index % chip_colors.size()])
	chip.position = Vector3(0.0, float(stack_index) * CHIP_LAYER_HEIGHT, 0.0)
	return chip


func _clear_chip_stack() -> void:
	for chip in _chip_meshes:
		chip.queue_free()
	_chip_meshes.clear()
	if _chip_stack_root != null:
		_chip_stack_root.visible = false


func _animate_chip_drop(chip: MeshInstance3D, stack_index: int, motion_reduced: bool) -> void:
	var rest_y := float(stack_index) * CHIP_LAYER_HEIGHT
	var duration_ms := MotionPreference.duration_ms(CHIP_BOUNCE_MS, motion_reduced)
	chip.position.y = rest_y + 0.18
	if duration_ms <= 0:
		chip.position.y = rest_y
		return
	var tween := create_tween()
	tween.tween_property(chip, "position:y", rest_y + 0.06, float(duration_ms) * 0.00045)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(chip, "position:y", rest_y, float(duration_ms) * 0.00055)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_track_tween(tween)


func _ensure_outcome_cue_node() -> void:
	if _outcome_cue_node != null:
		return
	var parent := _world if _world != null else _card_root.get_parent() if _card_root else self
	_outcome_cue_node = MeshInstance3D.new()
	_outcome_cue_node.name = "OutcomeCue"
	var mesh := SphereMesh.new()
	mesh.radius = 0.08
	mesh.height = 0.16
	_outcome_cue_node.mesh = mesh
	_outcome_cue_node.position = Vector3(0.0, 0.75, 0.0)
	_outcome_cue_node.visible = false
	parent.add_child(_outcome_cue_node)


func _spawn_table_dogs(other_player_count: int) -> void:
	_stop_idle_tweens()
	for node in _dog_nodes:
		node.queue_free()
	_dog_nodes.clear()
	_dog_bodies.clear()

	var slots_to_spawn: Array = [_DOG_DEALER_SLOT, _DOG_LEARNER_SLOT]
	slots_to_spawn.append_array(_DOG_PLAYER_SLOTS.slice(0, other_player_count))

	for i in slots_to_spawn.size():
		var slot: Dictionary = slots_to_spawn[i]
		var anchor := Node3D.new()
		anchor.name = "DogSeat%d" % i
		anchor.position = slot["pos"]
		anchor.rotation.y = float(slot["rot_y"]) + PI

		_build_dog_stool(anchor, i)
		var body_pivot := Node3D.new()
		body_pivot.name = "BodyPivot"
		body_pivot.position = Vector3(0.0, DOG_STOOL_SEAT_Y, 0.0)
		anchor.add_child(body_pivot)

		var torso := _build_breed_dog(body_pivot, str(slot["breed"]), i)
		_seat_root.add_child(anchor)
		_dog_nodes.append(anchor)
		if torso != null:
			_dog_bodies.append(torso)


func _build_dog_stool(parent: Node3D, variant: int) -> void:
	var wood := Color(0.48, 0.32, 0.18)
	var wood_dark := Color(0.34, 0.22, 0.12)
	var cushions: Array[Color] = [
		Color(0.78, 0.14, 0.12),
		Color(0.72, 0.16, 0.14),
		Color(0.68, 0.12, 0.16),
	]
	var cushion: Color = cushions[variant % cushions.size()]
	_add_dog_box(parent, Vector3(0.0, 0.04, 0.0), Vector3(0.34, 0.05, 0.34), wood_dark)
	_add_dog_box(parent, Vector3(0.0, 0.20, 0.0), Vector3(0.08, 0.28, 0.08), wood)
	_add_dog_box(parent, Vector3(0.0, 0.12, 0.12), Vector3(0.24, 0.03, 0.05), wood_dark)
	_add_dog_box(parent, Vector3(0.0, DOG_STOOL_SEAT_Y - 0.04, 0.0), Vector3(0.38, 0.08, 0.38), cushion)


func _build_breed_dog(parent: Node3D, breed: String, variant: int) -> MeshInstance3D:
	match breed:
		_DOG_BREED_DEALER:
			return _build_dealer_dog(parent)
		_DOG_BREED_LEARNER:
			return _build_hoodie_dog(parent, Color(0.28, 0.68, 0.32), Color(0.78, 0.66, 0.5))
		_DOG_BREED_BEAR:
			return _build_hoodie_dog(parent, Color(0.22, 0.48, 0.82), Color(0.82, 0.62, 0.38))
		_DOG_BREED_HUSKY:
			return _build_husky_dog(parent, Color(0.82, 0.2, 0.18))
		_:
			var hoodies := [
				Color(0.28, 0.68, 0.32),
				Color(0.72, 0.48, 0.22),
			]
			return _build_hoodie_dog(parent, hoodies[variant % hoodies.size()], Color(0.78, 0.66, 0.5))


func _build_dealer_dog(parent: Node3D) -> MeshInstance3D:
	# Dealer anchor rotates PI so the camera-facing side is local -Z.
	var front := -1.0
	var tan := Color(0.82, 0.68, 0.52)
	var tan_dark := Color(0.48, 0.32, 0.20)
	var white := Color(0.96, 0.94, 0.90)
	var black := Color(0.06, 0.05, 0.05)
	var grey := Color(0.52, 0.52, 0.50)
	var bow_red := Color(0.82, 0.14, 0.12)

	var torso := _add_dog_box(parent, Vector3(0.0, 0.28, 0.04), Vector3(0.34, 0.30, 0.24), white)

	# Black vest panels + open white shirt front.
	_add_dog_box(parent, Vector3(-0.12, 0.27, 0.0), Vector3(0.12, 0.26, 0.26), black)
	_add_dog_box(parent, Vector3(0.12, 0.27, 0.0), Vector3(0.12, 0.26, 0.26), black)
	_add_dog_box(parent, Vector3(0.0, 0.30, front * 0.13), Vector3(0.08, 0.22, 0.02), white)

	# Shirt buttons down the placket.
	for i in range(3):
		var button_y := 0.38 - float(i) * 0.06
		_add_dog_box(parent, Vector3(0.0, button_y, front * 0.14), Vector3(0.04, 0.04, 0.02), grey)

	# Collar tips and bow tie (camera side).
	var collar_l := _add_dog_box(parent, Vector3(-0.10, 0.44, front * 0.10), Vector3(0.08, 0.05, 0.06), white)
	collar_l.rotation.z = 0.35
	var collar_r := _add_dog_box(parent, Vector3(0.10, 0.44, front * 0.10), Vector3(0.08, 0.05, 0.06), white)
	collar_r.rotation.z = -0.35
	_add_dog_box(parent, Vector3(-0.06, 0.46, front * 0.15), Vector3(0.07, 0.05, 0.04), bow_red)
	_add_dog_box(parent, Vector3(0.06, 0.46, front * 0.15), Vector3(0.07, 0.05, 0.04), bow_red)
	_add_dog_box(parent, Vector3(0.0, 0.46, front * 0.14), Vector3(0.04, 0.04, 0.04), bow_red)

	# Continuous arms: shoulder → upper arm → forearm → paw (overlapping segments).
	for side_x in [-1.0, 1.0]:
		_add_dog_box(parent, Vector3(side_x * 0.17, 0.30, -0.04), Vector3(0.07, 0.12, 0.16), white)
		_add_dog_box(parent, Vector3(side_x * 0.18, 0.24, -0.20), Vector3(0.08, 0.11, 0.28), white)
		_add_dog_box(parent, Vector3(side_x * 0.19, 0.17, -0.44), Vector3(0.09, 0.10, 0.30), white)
		_add_dog_box(parent, Vector3(side_x * 0.19, 0.11, -0.66), Vector3(0.13, 0.05, 0.12), tan)

	# Solid St Bernard head — one core block plus overlays (no gaps between slices).
	_add_dog_box(parent, Vector3(0.0, 0.68, 0.0), Vector3(0.42, 0.38, 0.32), tan)
	_add_dog_box(parent, Vector3(0.0, 0.84, 0.0), Vector3(0.36, 0.06, 0.28), tan)
	_add_dog_box(parent, Vector3(0.0, 0.68, 0.12), Vector3(0.38, 0.34, 0.08), tan)
	_add_dog_box(parent, Vector3(0.0, 0.50, 0.02), Vector3(0.24, 0.10, 0.22), white)
	_add_dog_box(parent, Vector3(0.0, 0.67, front * 0.15), Vector3(0.14, 0.32, 0.05), white)
	_add_dog_box(parent, Vector3(-0.17, 0.67, front * 0.06), Vector3(0.10, 0.28, 0.20), tan.darkened(0.04))
	_add_dog_box(parent, Vector3(0.17, 0.67, front * 0.06), Vector3(0.10, 0.28, 0.20), tan.darkened(0.04))
	_add_dog_box(parent, Vector3(-0.24, 0.76, 0.02), Vector3(0.10, 0.20, 0.06), tan_dark)
	_add_dog_box(parent, Vector3(0.24, 0.76, 0.02), Vector3(0.10, 0.20, 0.06), tan_dark)
	_add_dog_box(parent, Vector3(-0.10, 0.72, front * 0.19), Vector3(0.09, 0.09, 0.04), tan_dark)

	# Muzzle and facial features on the camera-facing side.
	_add_dog_box(parent, Vector3(0.0, 0.58, front * 0.22), Vector3(0.17, 0.14, 0.11), white)
	_add_dog_box(parent, Vector3(0.0, 0.62, front * 0.18), Vector3(0.12, 0.08, 0.06), tan)
	_add_dog_box(parent, Vector3(-0.06, 0.72, front * 0.22), Vector3(0.05, 0.06, 0.03), black)
	_add_dog_box(parent, Vector3(0.06, 0.72, front * 0.22), Vector3(0.05, 0.06, 0.03), black)
	_add_dog_box(parent, Vector3(0.0, 0.60, front * 0.30), Vector3(0.07, 0.06, 0.05), black)
	_add_dog_box(parent, Vector3(-0.04, 0.54, front * 0.29), Vector3(0.035, 0.025, 0.025), black)
	_add_dog_box(parent, Vector3(0.04, 0.54, front * 0.29), Vector3(0.035, 0.025, 0.025), black)
	return torso


func _build_hoodie_dog(parent: Node3D, hoodie: Color, fur: Color) -> MeshInstance3D:
	var torso := _add_dog_box(parent, Vector3(0.0, 0.3, 0.0), Vector3(0.4, 0.32, 0.3), hoodie)
	_add_dog_box(parent, Vector3(0.0, 0.34, -0.04), Vector3(0.44, 0.36, 0.34), hoodie.lightened(0.05))
	_add_dog_box(parent, Vector3(0.0, 0.68, 0.02), Vector3(0.44, 0.4, 0.34), fur)
	_add_dog_box(parent, Vector3(0.0, 0.64, 0.2), Vector3(0.16, 0.12, 0.12), fur.lightened(0.1))
	_add_dog_box(parent, Vector3(-0.2, 0.84, -0.04), Vector3(0.12, 0.16, 0.1), fur.darkened(0.1))
	_add_dog_box(parent, Vector3(0.2, 0.84, -0.04), Vector3(0.12, 0.16, 0.1), fur.darkened(0.1))
	_add_dog_eyes(parent, Vector3(0.0, 0.72, 0.18))
	_add_dog_box(parent, Vector3(-0.18, 0.12, 0.08), Vector3(0.12, 0.18, 0.12), hoodie.darkened(0.12))
	_add_dog_box(parent, Vector3(0.18, 0.12, 0.08), Vector3(0.12, 0.18, 0.12), hoodie.darkened(0.12))
	return torso


func _build_husky_dog(parent: Node3D, hoodie: Color) -> MeshInstance3D:
	var white := Color(0.92, 0.9, 0.88)
	var black := Color(0.12, 0.12, 0.14)
	var torso := _add_dog_box(parent, Vector3(0.0, 0.3, 0.0), Vector3(0.4, 0.32, 0.3), hoodie)
	_add_dog_box(parent, Vector3(0.0, 0.34, -0.04), Vector3(0.44, 0.36, 0.34), hoodie.lightened(0.04))
	_add_dog_box(parent, Vector3(0.0, 0.72, 0.0), Vector3(0.4, 0.32, 0.32), black)
	_add_dog_box(parent, Vector3(0.0, 0.66, 0.18), Vector3(0.24, 0.2, 0.14), white)
	_add_dog_box(parent, Vector3(-0.2, 0.84, -0.04), Vector3(0.12, 0.16, 0.1), black)
	_add_dog_box(parent, Vector3(0.2, 0.84, -0.04), Vector3(0.12, 0.16, 0.1), black)
	_add_dog_eyes(parent, Vector3(0.0, 0.72, 0.18))
	_add_dog_box(parent, Vector3(-0.18, 0.12, 0.08), Vector3(0.12, 0.18, 0.12), hoodie.darkened(0.12))
	_add_dog_box(parent, Vector3(0.18, 0.12, 0.08), Vector3(0.12, 0.18, 0.12), hoodie.darkened(0.12))
	return torso


func _add_dog_eyes(parent: Node3D, center: Vector3) -> void:
	var black := Color(0.05, 0.05, 0.05)
	_add_dog_box(parent, center + Vector3(-0.1, 0.04, 0.02), Vector3(0.06, 0.06, 0.04), black)
	_add_dog_box(parent, center + Vector3(0.1, 0.04, 0.02), Vector3(0.06, 0.06, 0.04), black)


func _add_dog_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = pos
	_paint_mesh(part, color)
	parent.add_child(part)
	return part


func _start_dog_idle_loops() -> void:
	_stop_idle_tweens()
	for body in _dog_bodies:
		var base_y: float = body.position.y
		var tween := create_tween().set_loops()
		tween.tween_property(body, "position:y", base_y + 0.03, 1.2).set_trans(Tween.TRANS_SINE)
		tween.tween_property(body, "position:y", base_y, 1.2).set_trans(Tween.TRANS_SINE)
		_idle_tweens.append(tween)


func _stop_idle_tweens() -> void:
	for tween in _idle_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_idle_tweens.clear()


func _create_card_mesh(card_data: Dictionary) -> MeshInstance3D:
	var card := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = CARD_PLANE_SIZE
	card.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.roughness = 0.9
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var face_up: bool = bool(card_data.get("faceUp", true))
	if face_up:
		var tex := _load_card_texture(card_data.get("rank", "?"), card_data.get("suit", "spades"))
		if tex:
			mat.albedo_texture = tex
			mat.albedo_color = Color.WHITE
		else:
			mat.albedo_color = Color(0.98, 0.97, 0.94)
	else:
		var back_tex := _load_texture("back.png")
		if back_tex:
			mat.albedo_texture = back_tex
			mat.albedo_color = Color.WHITE
		else:
			mat.albedo_color = Color(0.18, 0.28, 0.55)

	card.material_override = mat
	card.position.y = 0.008
	return card


func _load_card_texture(rank: Variant, suit: Variant) -> Texture2D:
	var rank_str := str(rank)
	var suit_str := _normalize_suit(suit)
	return _load_texture("%s_%s.png" % [rank_str, suit_str])


func _normalize_suit(suit: Variant) -> String:
	var key := str(suit).to_lower()
	match key:
		"h", "hearts":
			return "hearts"
		"d", "diamonds":
			return "diamonds"
		"c", "clubs":
			return "clubs"
		"s", "spades":
			return "spades"
	if key in ["hearts", "diamonds", "clubs", "spades"]:
		return key
	return "spades"


func _load_texture(filename: String) -> Texture2D:
	if _texture_cache.has(filename):
		return _texture_cache[filename]
	var path := CARD_TEXTURE_DIR + filename
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute):
		var image := Image.load_from_file(absolute)
		if image != null and not image.is_empty():
			var runtime_tex := ImageTexture.create_from_image(image)
			_texture_cache[filename] = runtime_tex
			return runtime_tex
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		if tex:
			_texture_cache[filename] = tex
			return tex
	return null


func _animate_card_to(card: Node3D, target: Vector3, motion_reduced: bool) -> void:
	var duration_ms: int = MotionPreference.duration_ms(DEAL_SNAP_MS, motion_reduced)
	card.position = _deal_origin_local()
	if duration_ms <= 0:
		card.position = target
		return
	_track_tween(_deal_card_tween(card, target, duration_ms))


func _deal_origin_local() -> Vector3:
	return Vector3(0.15, 0.02, -0.28)


func _deal_card_tween(card: Node3D, target: Vector3, duration_ms: int) -> Tween:
	var tween := create_tween()
	tween.tween_property(card, "position", target, float(duration_ms) / 1000.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return tween




func _dog_reaction_tween(body: MeshInstance3D, reaction: String, base_y: float, duration_ms: int) -> Tween:
	var tween := create_tween()
	var seconds := float(duration_ms) / 1000.0
	match reaction:
		"deal":
			tween.tween_property(body, "position:y", base_y + 0.08, seconds * 0.4)
			tween.tween_property(body, "position:y", base_y, seconds * 0.6)
		"win":
			tween.tween_property(body, "rotation:z", 0.12, seconds * 0.35)
			tween.tween_property(body, "rotation:z", 0.0, seconds * 0.65)
		"loss":
			tween.tween_property(body, "position:y", base_y - 0.05, seconds * 0.5)
			tween.tween_property(body, "position:y", base_y, seconds * 0.5)
		_:
			tween.tween_property(body, "scale", Vector3(1.05, 1.05, 1.05), seconds * 0.5)
			tween.tween_property(body, "scale", Vector3.ONE, seconds * 0.5)
	return tween


func _outcome_cue_tween(duration_ms: int) -> Tween:
	var tween := create_tween()
	var seconds := float(duration_ms) / 1000.0
	_outcome_cue_node.scale = Vector3(0.6, 0.6, 0.6)
	tween.tween_property(_outcome_cue_node, "scale", Vector3(1.4, 1.4, 1.4), seconds * 0.45).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_outcome_cue_node, "scale", Vector3.ONE, seconds * 0.55).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void: _outcome_cue_node.visible = false)
	return tween


func _track_tween(tween: Tween) -> void:
	_active_tweens += 1
	tween.finished.connect(func() -> void:
		_active_tweens = maxi(_active_tweens - 1, 0)
	, CONNECT_ONE_SHOT)


func _clear_cards() -> void:
	for card in _card_nodes:
		card.queue_free()
	_card_nodes.clear()
	for seat_id in _seat_card_groups.keys():
		var group: Node3D = _seat_card_groups[seat_id]
		if is_instance_valid(group):
			group.queue_free()
	_seat_card_groups.clear()
	for seat_id in _hand_total_labels.keys():
		var board: Node3D = _hand_total_labels[seat_id]
		if is_instance_valid(board):
			board.visible = false
			var value_label: Label3D = board.get_node_or_null("Plaque/Value")
			if value_label != null:
				value_label.text = ""
