@tool
class_name ChamferButtonStyle
extends StyleBox

@export var face_color: Color = Color(0.42, 0.54, 0.36, 1.0)
@export var highlight_color: Color = Color(0.55, 0.67, 0.46, 1.0)
@export var shadow_color: Color = Color(0.28, 0.38, 0.22, 1.0)
@export var outline_color: Color = Color(0.10, 0.12, 0.08, 0.92)
@export var glow_border_color: Color = Color(0, 0, 0, 0)
@export var glow_border_width: float = 0.0
@export var chamfer: float = 10.0
@export var bevel_width: float = 2.0
@export var pressed: bool = false


func _get_minimum_size() -> Vector2:
	return Vector2(
		content_margin_left + content_margin_right + chamfer * 2.0,
		content_margin_top + content_margin_bottom + chamfer * 2.0
	)


func _get_draw_rect(rect: Rect2) -> Rect2:
	return rect


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var inset := 1.0
	var draw_rect := rect
	if pressed:
		draw_rect = rect.grow(-1.0)
		inset = 2.0

	var outline_pts := _oct_points(draw_rect, 0.0)
	RenderingServer.canvas_item_add_polygon(
		to_canvas_item,
		outline_pts,
		PackedColorArray([outline_color])
	)

	if glow_border_width > 0.0 and glow_border_color.a > 0.0:
		var glow_pts := _oct_points(draw_rect, inset)
		RenderingServer.canvas_item_add_polyline(
			to_canvas_item,
			glow_pts + PackedVector2Array([glow_pts[0]]),
			PackedColorArray([glow_border_color]),
			glow_border_width,
			true
		)
		inset += glow_border_width

	var face_pts := _oct_points(draw_rect, inset)
	if not pressed:
		var shadow_pts := _shift_points(face_pts, Vector2(0.0, 1.5))
		RenderingServer.canvas_item_add_polygon(
			to_canvas_item,
			shadow_pts,
			PackedColorArray([shadow_color.darkened(0.08)])
		)

	RenderingServer.canvas_item_add_polygon(
		to_canvas_item,
		face_pts,
		PackedColorArray([face_color])
	)

	_draw_bevel_edges(to_canvas_item, face_pts)


func _oct_points(rect: Rect2, inset: float) -> PackedVector2Array:
	var r := rect.grow(-inset)
	var c := minf(chamfer, minf(r.size.x, r.size.y) * 0.35)
	var x0 := r.position.x
	var y0 := r.position.y
	var x1 := r.position.x + r.size.x
	var y1 := r.position.y + r.size.y
	return PackedVector2Array([
		Vector2(x0 + c, y0),
		Vector2(x1 - c, y0),
		Vector2(x1, y0 + c),
		Vector2(x1, y1 - c),
		Vector2(x1 - c, y1),
		Vector2(x0 + c, y1),
		Vector2(x0, y1 - c),
		Vector2(x0, y0 + c),
	])


func _shift_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var shifted := points.duplicate()
	for i in shifted.size():
		shifted[i] += offset
	return shifted


func _draw_bevel_edges(to_canvas_item: RID, points: PackedVector2Array) -> void:
	var width := maxf(bevel_width, 1.0)
	_add_edge(to_canvas_item, points[0], points[1], highlight_color, width)
	_add_edge(to_canvas_item, points[7], points[0], highlight_color, width)
	_add_edge(to_canvas_item, points[6], points[7], highlight_color, width)
	_add_edge(to_canvas_item, points[2], points[3], shadow_color, width)
	_add_edge(to_canvas_item, points[3], points[4], shadow_color, width)
	_add_edge(to_canvas_item, points[4], points[5], shadow_color, width)


func _add_edge(
	to_canvas_item: RID,
	from: Vector2,
	to: Vector2,
	color: Color,
	width: float
) -> void:
	RenderingServer.canvas_item_add_line(to_canvas_item, from, to, color, width, true)
