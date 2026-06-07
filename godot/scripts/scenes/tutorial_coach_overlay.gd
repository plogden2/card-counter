extends Control

const UiTheme = preload("res://scripts/lib/ui_theme.gd")

@onready var _message: Label = %Message
@onready var _star_icon: TextureRect = $Bubble/HBox/StarIcon


func _ready() -> void:
	theme = UiTheme.load_theme()
	var bubble: PanelContainer = get_node_or_null("Bubble")
	if bubble:
		bubble.add_theme_stylebox_override("panel", theme.get_stylebox("panel_bubble", "PanelContainer"))
	var star := UiTheme.load_icon(UiTheme.ICON_STAR)
	if _star_icon != null and star != null:
		_star_icon.texture = star
	visible = false


func show_message(text: String) -> void:
	if text == "":
		visible = false
		return
	_message.text = text
	visible = true


func hide_overlay() -> void:
	visible = false
