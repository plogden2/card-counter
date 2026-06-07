extends Control

const AnalyticsOverlayScript = preload("res://scripts/scenes/analytics_overlay.gd")
const UiTheme = preload("res://scripts/lib/ui_theme.gd")

@onready var _overlay: Control = %AnalyticsOverlay
@onready var _close_button: Button = %CloseButton

var _delegate: Node = null


func _ready() -> void:
	UiTheme.apply_to(self, UiTheme.ScreenClass.OVERLAY)
	visible = false
	if _close_button and not _close_button.pressed.is_connected(_on_close_pressed):
		_close_button.pressed.connect(_on_close_pressed)


func bind_overlay(overlay: Node) -> void:
	_delegate = overlay


func toggle() -> void:
	if _delegate != null:
		_delegate.call("toggle")
	visible = _delegate != null and bool(_delegate.call("is_overlay_visible"))
	_sync_overlay()


func is_open() -> bool:
	return visible


func set_analytics(points: Array) -> void:
	if _delegate != null:
		_delegate.call("set_analytics", points)
	_sync_overlay()


func append_point(point: Dictionary) -> void:
	if _delegate != null:
		_delegate.call("append_point", point)
	_sync_overlay()


func _sync_overlay() -> void:
	if _overlay == null or _delegate == null:
		return
	_overlay.call("set_analytics", _delegate.call("get_analytics_points"))


func _on_close_pressed() -> void:
	toggle()
