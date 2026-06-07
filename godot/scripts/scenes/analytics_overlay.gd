extends Control

const Charts = preload("res://scripts/ui/charts.gd")

var _analytics_points: Array = []
var _visible := false


func set_analytics(points: Array) -> void:
	_analytics_points = points.duplicate(true)
	queue_redraw()


func append_point(point: Dictionary) -> void:
	_analytics_points.append(point)
	queue_redraw()


func get_analytics_points() -> Array:
	return _analytics_points.duplicate(true)


func get_point_count() -> int:
	return _analytics_points.size()


func get_balance_points() -> Array:
	return Charts.balance_series(_analytics_points)


func get_advantage_points() -> Array:
	return Charts.advantage_series(_analytics_points)


func toggle() -> void:
	_visible = not _visible
	visible = _visible


func is_overlay_visible() -> bool:
	return _visible


func _ready() -> void:
	visible = _visible
