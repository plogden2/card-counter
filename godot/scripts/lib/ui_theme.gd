class_name UiTheme

const ChamferButtonStyle = preload("res://scripts/lib/chamfer_button_style.gd")

enum ScreenClass { MENU, SIDEBAR, ACTION, OVERLAY }

const THEME_PATH := "res://assets/themes/tutorial_shell.tres"
const THEME_PATH_ALIAS := "res://assets/themes/mix2_shell.tres"
const FONT_BODY := "res://assets/fonts/Nunito-Bold.ttf"
const FONT_HEAVY := "res://assets/fonts/Nunito-ExtraBold.ttf"

# Sampled from ref-2d-tutorial-sidebar-ui.png (see assets/textures/ui/sidebar_colors.json)
const PANEL_SIDEBAR := Color(0.141, 0.137, 0.118, 1.0)
const PANEL_GREEN := Color(0.173, 0.267, 0.165, 1.0)
const PANEL_BROWN := Color(0.329, 0.247, 0.141, 1.0)
const PANEL_CREAM := Color(0.949, 0.867, 0.745, 1.0)
const TEXT_CREAM := Color(0.953, 0.871, 0.757, 1.0)
const TEXT_MUTED := Color(0.847, 0.714, 0.525, 1.0)
const TEXT_DARK := Color(0.345, 0.251, 0.149, 1.0)
const COUNT_POS := Color(0.478, 0.690, 0.314, 1.0)
const COUNT_NEU := Color(0.478, 0.431, 0.376, 1.0)
const COUNT_NEG := Color(0.776, 0.376, 0.282, 1.0)
const BADGE_POS := Color(0.384, 0.604, 0.282, 1.0)
const BADGE_NEU := Color(0.478, 0.431, 0.376, 1.0)
const BADGE_NEG := Color(0.776, 0.376, 0.282, 1.0)
const TIP_YELLOW := Color(0.988, 0.741, 0.286, 1.0)
const BTN_PRIMARY := Color(0.42, 0.54, 0.36, 1.0)
const BTN_SECONDARY := Color(0.58, 0.46, 0.30, 1.0)
const BTN_OUTLINE := Color(0.10, 0.12, 0.08, 0.92)
const TIP_BG := Color(0.173, 0.267, 0.165, 1.0)
const STAT_BORDER := Color(0.255, 0.188, 0.110, 1.0)

const FONT_STAT_LABEL := 9
const FONT_STAT_VALUE := 36
const FONT_STAT_VALUE_SM := 24
const FONT_HILO_TITLE := 11
const FONT_HILO_RANGE := 12
const FONT_HEADER_LG := 14
const FONT_HEADER_SM := 11
const FONT_BADGE := 12

const ICON_PAW := "res://assets/textures/ui/icon_paw_header.png"
const ICON_DECK := "res://assets/textures/ui/icon_deck.png"
const ICON_CHIP := "res://assets/textures/ui/icon_chip.png"
const ICON_BULB := "res://assets/textures/ui/icon_bulb.png"
const ICON_HELP := "res://assets/textures/ui/icon_help.png"
const ICON_STAR := "res://assets/textures/ui/icon_star.png"
const ICON_BADGE_POS := "res://assets/textures/ui/badge_pos.png"
const ICON_BADGE_NEU := "res://assets/textures/ui/badge_neu.png"
const ICON_BADGE_NEG := "res://assets/textures/ui/badge_neg.png"

static var _theme: Theme = null
static var _font_body: FontFile = null
static var _font_heavy: FontFile = null


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
	_apply_button_styles(_theme)
	_apply_default_fonts(_theme)
	return _theme


static func get_body_font() -> Font:
	_ensure_fonts()
	return _font_body


static func get_heavy_font() -> Font:
	_ensure_fonts()
	return _font_heavy


static func apply_font(label: Control, heavy: bool = false, size: int = 14) -> void:
	_ensure_fonts()
	var font := _font_heavy if heavy else _font_body
	if font == null or label == null:
		return
	if label.has_method("add_theme_font_override"):
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", size)


static func style_button_glow() -> StyleBox:
	return _style_button(BTN_PRIMARY.lightened(0.06), "normal", 10.0, true)


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


static func apply_stat_label(label: Label) -> void:
	apply_font(label, false, FONT_STAT_LABEL)
	label.add_theme_color_override("font_color", TEXT_MUTED)


static func apply_hilo_dark_label(label: Label) -> void:
	apply_font(label, true, FONT_HILO_RANGE)
	label.add_theme_color_override("font_color", TEXT_DARK)


static func apply_hilo_title(label: Label) -> void:
	apply_font(label, true, FONT_HILO_TITLE)
	label.add_theme_color_override("font_color", TEXT_DARK)


static func count_color(value: int) -> Color:
	if value > 0:
		return COUNT_POS
	if value < 0:
		return COUNT_NEG
	return COUNT_NEU


static func hilo_badge_style(value: int) -> String:
	if value > 0:
		return "hilo_pos"
	if value < 0:
		return "hilo_neg"
	return "hilo_neu"


static func load_icon(path: String) -> Texture2D:
	var absolute := ProjectSettings.globalize_path(path)
	if ResourceLoader.exists(path):
		var imported: Texture2D = load(path) as Texture2D
		if imported != null:
			return imported
	if FileAccess.file_exists(absolute):
		var image := Image.load_from_file(absolute)
		if image != null:
			return ImageTexture.create_from_image(image)
	return null


static func format_bankroll(amount: int) -> String:
	return "$%s" % _format_number(amount)


static func format_signed_count(value: int) -> String:
	if value > 0:
		return "+%d" % value
	return str(value)


static func format_true_count(value: int) -> String:
	if value > 0:
		return "+%.1f" % float(value)
	if value < 0:
		return "%.1f" % float(value)
	return "0.0"


static func format_decks_remaining(decks: float) -> String:
	return "%.1f" % maxf(decks, 0.0)


static func _ensure_fonts() -> void:
	if _font_body != null:
		return
	_font_body = _load_font_file(FONT_BODY)
	_font_heavy = _load_font_file(FONT_HEAVY)
	if _font_body == null:
		_font_body = ThemeDB.fallback_font
	if _font_heavy == null:
		_font_heavy = _font_body


static func _load_font_file(path: String) -> FontFile:
	if ResourceLoader.exists(path):
		return load(path) as FontFile
	var absolute := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute):
		return null
	var font := FontFile.new()
	var err := font.load_dynamic_font(absolute)
	if err != OK:
		push_warning("Failed to load font %s (%s)" % [path, err])
		return null
	return font


static func _apply_default_fonts(theme: Theme) -> void:
	_ensure_fonts()
	theme.default_font = _font_body
	theme.set_font("font", "Label", _font_body)
	theme.set_font("font", "Button", _font_body)


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
	theme.set_stylebox("panel_sidebar", "PanelContainer", _style_panel(PANEL_SIDEBAR, 12, 8))
	theme.set_stylebox("panel_overlay", "PanelContainer", _style_panel(PANEL_BROWN))
	theme.set_stylebox("panel_tip", "PanelContainer", _style_panel(TIP_BG, 10, 10))
	theme.set_stylebox("panel_header", "PanelContainer", _style_panel(PANEL_GREEN, 10, 10))
	theme.set_stylebox("panel_cream", "PanelContainer", _style_panel(PANEL_CREAM, 10, 10))
	theme.set_stylebox("panel_bubble", "PanelContainer", _style_panel(PANEL_CREAM, 14, 12))
	theme.set_stylebox("panel_status", "PanelContainer", _style_panel(PANEL_CREAM, 12, 12))
	theme.set_stylebox("stat_block", "PanelContainer", _style_stat_block())
	theme.set_stylebox("hilo_pos", "PanelContainer", _style_hilo_badge(BADGE_POS))
	theme.set_stylebox("hilo_neu", "PanelContainer", _style_hilo_badge(BADGE_NEU))
	theme.set_stylebox("hilo_neg", "PanelContainer", _style_hilo_badge(BADGE_NEG))
	theme.set_color("font_color", "Label", TEXT_CREAM)
	theme.set_color("font_color", "Button", TEXT_CREAM)
	_apply_button_styles(theme)
	return theme


static func _style_panel(color: Color, radius: int = 8, margin: int = 10) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.content_margin_left = margin
	box.content_margin_top = margin
	box.content_margin_right = margin
	box.content_margin_bottom = margin
	return box


static func _style_stat_block() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_BROWN
	box.border_color = STAT_BORDER
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.shadow_color = Color(0, 0, 0, 0.25)
	box.shadow_size = 2
	box.shadow_offset = Vector2(0, 1)
	box.content_margin_left = 12
	box.content_margin_top = 6
	box.content_margin_right = 12
	box.content_margin_bottom = 8
	return box


static func _apply_button_styles(theme: Theme) -> void:
	theme.set_color("font_color", "Button", TEXT_CREAM)
	theme.set_color("font_hover_color", "Button", Color(1.0, 0.98, 0.94, 1.0))
	theme.set_color("font_pressed_color", "Button", Color(0.9, 0.88, 0.82, 1.0))
	theme.set_font_size("font_size", "Button", 16)
	theme.set_stylebox("normal", "Button", _style_button(BTN_PRIMARY, "normal"))
	theme.set_stylebox("hover", "Button", _style_button(BTN_PRIMARY, "hover"))
	theme.set_stylebox("pressed", "Button", _style_button(BTN_PRIMARY, "pressed"))
	theme.set_stylebox("disabled", "Button", _style_button(BTN_PRIMARY.darkened(0.18), "normal", 10.0, false, 0.45))
	theme.set_type_variation("secondary", "Button")
	theme.set_stylebox("normal", "secondary", _style_button(BTN_SECONDARY, "normal"))
	theme.set_stylebox("hover", "secondary", _style_button(BTN_SECONDARY, "hover"))
	theme.set_stylebox("pressed", "secondary", _style_button(BTN_SECONDARY, "pressed"))
	theme.set_stylebox("disabled", "secondary", _style_button(BTN_SECONDARY.darkened(0.18), "normal", 10.0, false, 0.45))


static func _style_button(
	face: Color,
	state: String = "normal",
	chamfer: float = 10.0,
	glow: bool = false,
	disabled_alpha: float = 1.0
) -> StyleBox:
	var box := ChamferButtonStyle.new()
	var tone := face
	match state:
		"hover":
			tone = face.lightened(0.08)
		"pressed":
			tone = face.darkened(0.08)
	box.face_color = Color(tone.r, tone.g, tone.b, disabled_alpha)
	box.highlight_color = tone.lightened(0.14)
	box.shadow_color = tone.darkened(0.16)
	box.outline_color = BTN_OUTLINE
	box.chamfer = chamfer
	box.bevel_width = 2.0
	box.pressed = state == "pressed"
	box.content_margin_left = 16.0
	box.content_margin_top = 10.0
	box.content_margin_right = 16.0
	box.content_margin_bottom = 10.0
	if glow:
		box.glow_border_color = Color(1.0, 0.85, 0.45, 1.0)
		box.glow_border_width = 3.0
	return box


static func _style_hilo_badge(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(11)
	box.content_margin_left = 10
	box.content_margin_top = 2
	box.content_margin_right = 10
	box.content_margin_bottom = 2
	return box
