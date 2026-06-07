extends SubViewportContainer

const MotionPreference = preload("res://scripts/lib/motion_preference.gd")

@onready var _table: MeshInstance3D = %TableMesh
@onready var _shoe: MeshInstance3D = %ShoeMesh
@onready var _card_root: Node3D = %CardRoot
@onready var _seat_root: Node3D = %SeatRoot

var _card_nodes: Array[MeshInstance3D] = []
var _dog_nodes: Array[Node3D] = []


func _ready() -> void:
	_spawn_dog_placeholders(3)


func set_dog_count(count: int) -> void:
	_spawn_dog_placeholders(clampi(count, 0, 5))


func deal_cards(cards: Array, motion_reduced: bool = false) -> void:
	_clear_cards()
	for i in cards.size():
		var card := _create_card_mesh()
		card.position = Vector3(0.0, 0.4, -1.7)
		_card_root.add_child(card)
		_card_nodes.append(card)

		var col := i % 5
		var row := i / 5
		var target := Vector3(-0.9 + float(col) * 0.45, 0.4, -0.5 + float(row) * 0.7)
		_animate_card_to(card, target, motion_reduced)


func _spawn_dog_placeholders(count: int) -> void:
	for node in _dog_nodes:
		node.queue_free()
	_dog_nodes.clear()

	for i in count:
		var anchor := Node3D.new()
		anchor.name = "DogSeat%d" % i
		var angle := (TAU / 6.0) * float(i + 1)
		anchor.position = Vector3(cos(angle) * 1.9, 0.0, sin(angle) * 1.9)
		anchor.look_at(Vector3.ZERO, Vector3.UP, true)

		var body := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.35, 0.35, 0.5)
		body.mesh = mesh
		body.position = Vector3(0.0, 0.2, 0.0)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.from_hsv(float(i) / 6.0, 0.45, 0.9)
		body.material_override = mat
		anchor.add_child(body)

		_seat_root.add_child(anchor)
		_dog_nodes.append(anchor)


func _create_card_mesh() -> MeshInstance3D:
	var card := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.28, 0.02, 0.4)
	card.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.98, 0.97, 0.94)
	mat.roughness = 0.75
	card.material_override = mat
	return card


func _animate_card_to(card: Node3D, target: Vector3, motion_reduced: bool) -> void:
	var duration_ms: int = MotionPreference.duration_ms(260, motion_reduced)
	if duration_ms <= 0:
		card.position = target
		return

	var tween := create_tween()
	tween.tween_property(card, "position", target, float(duration_ms) / 1000.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _clear_cards() -> void:
	for card in _card_nodes:
		card.queue_free()
	_card_nodes.clear()
