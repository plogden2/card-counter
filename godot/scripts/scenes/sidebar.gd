extends VBoxContainer

const UiTheme = preload("res://scripts/lib/ui_theme.gd")

signal menu_requested
signal help_requested
signal bet_amount_changed(amount: int)

@onready var _running_count_value: Label = %RunningCountValue
@onready var _true_count_value: Label = %TrueCountValue
@onready var _decks_remaining_value: Label = %DecksRemainingValue
@onready var _bet_value: Label = %BetValue
@onready var _selected_bet_value: Label = %SelectedBetValue
@onready var _bet_decrease: Button = %BetDecrease
@onready var _bet_increase: Button = %BetIncrease
@onready var _bet_controls: HBoxContainer = %BetControls
@onready var _chip_row: HBoxContainer = %ChipRow
@onready var _button_row: HBoxContainer = %ButtonRow
@onready var _tip_label: Label = %TipLabel
@onready var _tip_header: Label = $TipPanel/TipVBox/TipHeaderRow/TipHeader
@onready var _paw_left: TextureRect = %PawLeft
@onready var _paw_right: TextureRect = %PawRight
@onready var _help_icon: TextureRect = %HelpIcon
@onready var _deck_icon: TextureRect = %DeckIcon
@onready var _chip_icon: TextureRect = %ChipIcon
@onready var _tip_bulb: TextureRect = %TipBulb

var _stats := {
	"runningCount": 0,
	"trueCount": 0,
	"decksRemaining": 2.0,
	"bet": 25,
	"tipText": "Positive counts are good! Consider increasing your bet.",
}
var _selected_bet := 25
var _min_bet := 5
var _max_bet := 500
var _betting_enabled := true
var _ref_display := false


func get_screen_class() -> int:
	return UiTheme.ScreenClass.SIDEBAR


func uses_shared_theme() -> bool:
	return theme != null


func get_selected_bet() -> int:
	return _selected_bet


func set_ref_display(enabled: bool) -> void:
	_ref_display = enabled
	_refresh_labels()


func _ready() -> void:
	var panel := _find_sidebar_panel()
	if panel != null:
		UiTheme.apply_to(panel, UiTheme.ScreenClass.SIDEBAR)
	theme = UiTheme.load_theme()
	_apply_icons()
	_apply_panel_styles()
	_apply_typography()
	_refresh_labels()


func _apply_icons() -> void:
	_set_icon(_paw_left, UiTheme.ICON_PAW)
	_set_icon(_paw_right, UiTheme.ICON_PAW)
	_set_icon(_help_icon, UiTheme.ICON_HELP)
	_set_icon(_deck_icon, UiTheme.ICON_DECK)
	_set_icon(_chip_icon, UiTheme.ICON_CHIP)
	_set_icon(_tip_bulb, UiTheme.ICON_BULB)
	_set_icon(get_node_or_null("HiLoPanel/HiLoVBox/HiLoGrid/Row26/Badge26") as TextureRect, UiTheme.ICON_BADGE_POS)
	_set_icon(get_node_or_null("HiLoPanel/HiLoVBox/HiLoGrid/Row79/Badge79") as TextureRect, UiTheme.ICON_BADGE_NEU)
	_set_icon(get_node_or_null("HiLoPanel/HiLoVBox/HiLoGrid/Row10A/Badge10A") as TextureRect, UiTheme.ICON_BADGE_NEG)


func _set_icon(target: TextureRect, path: String) -> void:
	if target == null:
		return
	var tex: Texture2D = UiTheme.load_icon(path)
	if tex != null:
		target.texture = tex
		target.visible = true


func _find_sidebar_panel() -> PanelContainer:
	var node: Node = self
	while node != null:
		if node is PanelContainer and str(node.name).contains("Sidebar"):
			return node
		node = node.get_parent()
	return get_parent() as PanelContainer if get_parent() is PanelContainer else null


func _apply_panel_styles() -> void:
	var title_panel: PanelContainer = get_node_or_null("TitlePanel")
	if title_panel:
		title_panel.add_theme_stylebox_override("panel", theme.get_stylebox("panel_header", "PanelContainer"))
	var hilo: PanelContainer = get_node_or_null("HiLoPanel")
	if hilo:
		hilo.add_theme_stylebox_override("panel", theme.get_stylebox("panel_cream", "PanelContainer"))
	for block_name in ["RunningCountBlock", "TrueCountBlock", "DecksBlock", "BetBlock"]:
		var block: PanelContainer = get_node_or_null(block_name)
		if block:
			block.add_theme_stylebox_override("panel", theme.get_stylebox("stat_block", "PanelContainer"))
	var tip: PanelContainer = get_node_or_null("TipPanel")
	if tip:
		tip.add_theme_stylebox_override("panel", theme.get_stylebox("panel_tip", "PanelContainer"))


func _apply_typography() -> void:
	var title1: Label = get_node_or_null("TitlePanel/TitleVBox/TitleLine1")
	if title1:
		UiTheme.apply_font(title1, true, UiTheme.FONT_HEADER_LG)
		title1.add_theme_color_override("font_color", UiTheme.TEXT_CREAM)
	var title2: Label = get_node_or_null("TitlePanel/TitleVBox/TitleLine2/TitleLine2Text")
	if title2:
		UiTheme.apply_font(title2, true, UiTheme.FONT_HEADER_SM)
		title2.add_theme_color_override("font_color", UiTheme.TEXT_CREAM)
	for label_name in ["RunningCountLabel", "TrueCountLabel", "DecksLabel", "BetLabel"]:
		var path := ""
		match label_name:
			"RunningCountLabel":
				path = "RunningCountBlock/RCVBox/RunningCountLabel"
			"TrueCountLabel":
				path = "TrueCountBlock/TCVBox/TrueCountLabel"
			"DecksLabel":
				path = "DecksBlock/DecksVBox/DecksLabel"
			"BetLabel":
				path = "BetBlock/BetVBox/BetLabel"
		var lbl: Label = get_node_or_null(path)
		if lbl:
			UiTheme.apply_stat_label(lbl)
	var hilo_title: Label = get_node_or_null("HiLoPanel/HiLoVBox/HiLoTitleRow/HiLoTitle")
	if hilo_title:
		UiTheme.apply_hilo_title(hilo_title)
	for range_path in [
		"HiLoPanel/HiLoVBox/HiLoGrid/Row26/Range26",
		"HiLoPanel/HiLoVBox/HiLoGrid/Row79/Range79",
		"HiLoPanel/HiLoVBox/HiLoGrid/Row10A/Range10A",
	]:
		var range_lbl: Label = get_node_or_null(range_path)
		if range_lbl:
			UiTheme.apply_hilo_dark_label(range_lbl)
	if _tip_header:
		UiTheme.apply_font(_tip_header, true, UiTheme.FONT_HILO_TITLE)
		_tip_header.add_theme_color_override("font_color", UiTheme.TIP_YELLOW)
	if _tip_label:
		UiTheme.apply_font(_tip_label, false, 11)
		_tip_label.add_theme_color_override("font_color", UiTheme.TEXT_CREAM)


func update_stats(next_stats: Dictionary) -> void:
	for key in _stats.keys():
		if next_stats.has(key):
			_stats[key] = next_stats[key]
	if next_stats.has("minBet"):
		_min_bet = maxi(1, int(next_stats["minBet"]))
	if next_stats.has("maxBet"):
		_max_bet = maxi(_min_bet, int(next_stats["maxBet"]))
	if next_stats.has("selectedBet"):
		_selected_bet = int(next_stats["selectedBet"])
	elif next_stats.has("bet"):
		_selected_bet = _clamp_bet(int(next_stats["bet"]))
	elif next_stats.has("recommendedBet"):
		_selected_bet = _clamp_bet(int(next_stats["recommendedBet"]))
	if next_stats.has("bettingEnabled"):
		_betting_enabled = bool(next_stats["bettingEnabled"])
	if next_stats.has("refDisplay"):
		_ref_display = bool(next_stats["refDisplay"])
	_refresh_labels()


func _refresh_labels() -> void:
	if _running_count_value == null:
		return
	var running: int = int(_stats["runningCount"])
	var true_count: int = int(_stats["trueCount"])
	_running_count_value.text = UiTheme.format_signed_count(running)
	_true_count_value.text = UiTheme.format_true_count(true_count)
	_decks_remaining_value.text = UiTheme.format_decks_remaining(float(_stats["decksRemaining"]))

	var display_bet: int = int(_stats.get("bet", _selected_bet))
	_bet_value.text = str(display_bet)
	_selected_bet_value.text = str(_selected_bet)

	UiTheme.apply_font(_running_count_value, true, UiTheme.FONT_STAT_VALUE)
	UiTheme.apply_font(_true_count_value, true, UiTheme.FONT_STAT_VALUE)
	UiTheme.apply_font(_decks_remaining_value, true, UiTheme.FONT_STAT_VALUE_SM)
	UiTheme.apply_font(_bet_value, true, UiTheme.FONT_STAT_VALUE_SM)
	_running_count_value.custom_minimum_size = Vector2(0, 42)
	_true_count_value.custom_minimum_size = Vector2(0, 42)
	_decks_remaining_value.custom_minimum_size = Vector2(48, 32)
	_bet_value.custom_minimum_size = Vector2(48, 32)

	_running_count_value.add_theme_color_override("font_color", UiTheme.count_color(running))
	_true_count_value.add_theme_color_override("font_color", UiTheme.count_color(true_count))
	_decks_remaining_value.add_theme_color_override("font_color", UiTheme.TEXT_CREAM)
	_bet_value.add_theme_color_override("font_color", UiTheme.TEXT_CREAM)

	var tip := str(_stats.get("tipText", _stats.get("tip", "")))
	if tip != "":
		_tip_label.text = tip

	var show_bet_controls := _betting_enabled and not _ref_display
	if _bet_controls != null:
		_bet_controls.visible = show_bet_controls
	if _chip_row != null:
		_chip_row.visible = show_bet_controls
	if _button_row != null:
		_button_row.visible = not _ref_display

	_bet_decrease.disabled = not _betting_enabled or _selected_bet <= _min_bet
	_bet_increase.disabled = not _betting_enabled or _selected_bet >= _clamp_bet(_max_bet)
	if _chip_row != null:
		for child in _chip_row.get_children():
			if child is Button:
				child.disabled = not _betting_enabled


func _set_selected_bet(amount: int) -> void:
	var clamped := _clamp_bet(amount)
	if clamped == _selected_bet:
		return
	_selected_bet = clamped
	_stats["bet"] = _selected_bet
	_refresh_labels()
	bet_amount_changed.emit(_selected_bet)


func _clamp_bet(amount: int) -> int:
	return clampi(amount, _min_bet, maxi(_min_bet, _max_bet))


func _on_bet_decrease_pressed() -> void:
	_set_selected_bet(_selected_bet - _min_bet)


func _on_bet_increase_pressed() -> void:
	_set_selected_bet(_selected_bet + _min_bet)


func _on_chip_preset_pressed(amount: int) -> void:
	_set_selected_bet(amount)


func _on_menu_pressed() -> void:
	menu_requested.emit()


func _on_help_pressed() -> void:
	help_requested.emit()
