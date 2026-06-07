extends Control

const UiTheme = preload("res://scripts/lib/ui_theme.gd")

@onready var _message: Label = %Message


func _ready() -> void:
	UiTheme.apply_to(self, UiTheme.ScreenClass.OVERLAY)
	visible = false


func show_message(text: String) -> void:
	if text == "":
		visible = false
		return
	_message.text = text
	visible = true


func hide_overlay() -> void:
	visible = false
