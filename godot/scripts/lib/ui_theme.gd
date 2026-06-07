class_name UiTheme

enum ScreenClass { MENU, SIDEBAR, ACTION, OVERLAY }

const THEME_PATH := "res://assets/themes/tutorial_shell.tres"
const THEME_PATH_ALIAS := "res://assets/themes/mix2_shell.tres"

const PANEL_GREEN := Color(0.12, 0.28, 0.16, 1.0)
const PANEL_BROWN := Color(0.28, 0.16, 0.10, 1.0)
const TEXT_CREAM := Color(0.96, 0.94, 0.88, 1.0)
const COUNT_POS := Color(0.35, 0.78, 0.42, 1.0)
const COUNT_NEU := Color(0.55, 0.55, 0.55, 1.0)
const COUNT_NEG := Color(0.85, 0.32, 0.28, 1.0)
const BTN_PRIMARY := Color(0.22, 0.52, 0.30, 1.0)
const BTN_SECONDARY := Color(0.72, 0.58, 0.38, 1.0)
const TIP_BG := Color(0.18, 0.22, 0.16, 1.0)

static var _theme: Theme = null


static func get_theme_path() -> String:
	if ResourceLoader.exists(THEME_PATH):
		return THEME_PATH
	return THEME_PATH_ALIAS


static func load_theme() -> Theme:
	if _theme != null:
		return _theme
	var path := get_theme_path()
	if ResourceLoader.exists(path):
		_theme = load(path) as Theme
	if _theme == null:
		_theme = _build_fallback_theme()
	return _theme


static func apply_to(control: Control, screen_class: ScreenClass) -> void:
	var theme := load_theme()
	control.theme = theme
	if control is PanelContainer:
		match screen_class:
			ScreenClass.SIDEBAR:
				control.add_theme_stylebox_override("panel", theme.get_stylebox("panel_sidebar", "PanelContainer"))
			ScreenClass.OVERLAY:
				control.add_theme_stylebox_override("panel", theme.get_stylebox("panel_overlay", "PanelContainer"))
			_:
				control.add_theme_stylebox_override("panel", theme.get_stylebox("panel_menu", "PanelContainer"))


static func count_color(value: int) -> Color:
	if value > 0:
		return COUNT_POS
	if value < 0:
		return COUNT_NEG
	return COUNT_NEU


static func format_bankroll(amount: int) -> String:
	return "$%s" % _format_number(amount)


static func format_signed_count(value: int) -> String:
	if value > 0:
		return "+%d" % value
	return str(value)


static func _format_number(amount: int) -> String:
	var negative := amount < 0
	var digits := str(absi(amount))
	var parts: PackedStringArray = []
	while digits.length() > 3:
		parts.insert(0, digits.substr(digits.length() - 3, 3))
		digits = digits.substr(0, digits.length() - 3)
	parts.insert(0, digits)
	var formatted := ",".join(parts)
	return ("-%s" % formatted) if negative else formatted


static func _build_fallback_theme() -> Theme:
	var theme := Theme.new()
	theme.set_stylebox("panel_menu", "PanelContainer", _style_panel(PANEL_GREEN))
	theme.set_stylebox("panel_sidebar", "PanelContainer", _style_panel(PANEL_GREEN))
	theme.set_stylebox("panel_overlay", "PanelContainer", _style_panel(PANEL_BROWN))
	theme.set_stylebox("panel_tip", "PanelContainer", _style_panel(TIP_BG))
	theme.set_stylebox("stat_block", "PanelContainer", _style_panel(PANEL_BROWN, 6))
	theme.set_color("font_color", "Label", TEXT_CREAM)
	theme.set_color("font_color", "Button", TEXT_CREAM)
	theme.set_stylebox("normal", "Button", _style_button(BTN_PRIMARY))
	theme.set_stylebox("hover", "Button", _style_button(BTN_PRIMARY.lightened(0.08)))
	theme.set_stylebox("pressed", "Button", _style_button(BTN_PRIMARY.darkened(0.08)))
	theme.set_type_variation("secondary", "Button")
	theme.set_stylebox("normal", "secondary", _style_button(BTN_SECONDARY))
	theme.set_stylebox("hover", "secondary", _style_button(BTN_SECONDARY.lightened(0.08)))
	theme.set_stylebox("pressed", "secondary", _style_button(BTN_SECONDARY.darkened(0.08)))
	return theme


static func _style_panel(color: Color, radius: int = 8) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12
	box.content_margin_top = 12
	box.content_margin_right = 12
	box.content_margin_bottom = 12
	return box


static func _style_button(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(12)
	box.content_margin_left = 16
	box.content_margin_top = 10
	box.content_margin_right = 16
	box.content_margin_bottom = 10
	return box
