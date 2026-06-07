extends Control

const UiTheme = preload("res://scripts/lib/ui_theme.gd")

@onready var _count_line: Label = %CountLine
@onready var _subtitle: Label = %Subtitle


func _ready() -> void:
	theme = UiTheme.load_theme()
	var panel: PanelContainer = get_node_or_null("Panel")
	if panel:
		panel.add_theme_stylebox_override("panel", theme.get_stylebox("panel_status", "PanelContainer"))
	visible = false


func update_status(running_count: int, subtitle: String) -> void:
	_count_line.text = "Running Count: %s" % UiTheme.format_signed_count(running_count)
	_subtitle.text = subtitle
	visible = true


func hide_bar() -> void:
	visible = false
