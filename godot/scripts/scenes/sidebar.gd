extends VBoxContainer

const UiTheme = preload("res://scripts/lib/ui_theme.gd")

signal analytics_requested
signal options_requested
signal bet_amount_changed(amount: int)

@onready var _running_count_value: Label = %RunningCountValue
@onready var _true_count_value: Label = %TrueCountValue
@onready var _bankroll_value: Label = %BankrollValue
@onready var _recommended_bet_value: Label = %RecommendedBetValue
@onready var _selected_bet_value: Label = %SelectedBetValue
@onready var _bet_decrease: Button = %BetDecrease
@onready var _bet_increase: Button = %BetIncrease
@onready var _chip_row: HBoxContainer = %ChipRow
@onready var _shoe_remaining_value: Label = %ShoeRemainingValue
@onready var _tip_label: Label = %TipLabel

var _stats := {
	"runningCount": 0,
	"trueCount": 0,
	"bankroll": 1000,
	"recommendedBet": 0,
	"shoeRemaining": "312",
	"tipText": "Watch the running count as cards are dealt.",
}
var _selected_bet := 25
var _min_bet := 5
var _max_bet := 500
var _betting_enabled := true


func get_screen_class() -> int:
	return UiTheme.ScreenClass.SIDEBAR


func uses_shared_theme() -> bool:
	return theme != null


func get_selected_bet() -> int:
	return _selected_bet


func _ready() -> void:
	var panel := get_parent()
	if panel is PanelContainer:
		UiTheme.apply_to(panel, UiTheme.ScreenClass.SIDEBAR)
	theme = UiTheme.load_theme()
	_refresh_labels()


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
	elif next_stats.has("recommendedBet"):
		_selected_bet = _clamp_bet(int(next_stats["recommendedBet"]))
	if next_stats.has("bettingEnabled"):
		_betting_enabled = bool(next_stats["bettingEnabled"])
	_refresh_labels()


func _refresh_labels() -> void:
	_running_count_value.text = UiTheme.format_signed_count(int(_stats["runningCount"]))
	_true_count_value.text = UiTheme.format_signed_count(int(_stats["trueCount"]))
	_bankroll_value.text = UiTheme.format_bankroll(int(_stats["bankroll"]))
	_recommended_bet_value.text = UiTheme.format_bankroll(int(_stats["recommendedBet"]))
	_selected_bet_value.text = UiTheme.format_bankroll(_selected_bet)
	_shoe_remaining_value.text = str(_stats["shoeRemaining"])
	_tip_label.text = str(_stats.get("tipText", _stats.get("tip", "")))

	_running_count_value.add_theme_color_override("font_color", UiTheme.count_color(int(_stats["runningCount"])))
	_true_count_value.add_theme_color_override("font_color", UiTheme.count_color(int(_stats["trueCount"])))

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
	_refresh_labels()
	bet_amount_changed.emit(_selected_bet)


func _clamp_bet(amount: int) -> int:
	var bankroll_cap: int = mini(_max_bet, int(_stats["bankroll"]))
	return clampi(amount, _min_bet, maxi(_min_bet, bankroll_cap))


func _on_bet_decrease_pressed() -> void:
	_set_selected_bet(_selected_bet - _min_bet)


func _on_bet_increase_pressed() -> void:
	_set_selected_bet(_selected_bet + _min_bet)


func _on_chip_preset_pressed(amount: int) -> void:
	_set_selected_bet(amount)


func _on_analytics_pressed() -> void:
	analytics_requested.emit()


func _on_options_pressed() -> void:
	options_requested.emit()
