extends GutTest

const UiTheme = preload("res://scripts/lib/ui_theme.gd")


func test_ref_b_palette_tokens():
	assert_eq(UiTheme.PANEL_GREEN, Color(0.12, 0.28, 0.16, 1.0))
	assert_eq(UiTheme.TEXT_CREAM, Color(0.96, 0.94, 0.88, 1.0))


func test_count_color_map():
	assert_eq(UiTheme.count_color(3), UiTheme.COUNT_POS)
	assert_eq(UiTheme.count_color(0), UiTheme.COUNT_NEU)
	assert_eq(UiTheme.count_color(-2), UiTheme.COUNT_NEG)


func test_format_signed_count():
	assert_eq(UiTheme.format_signed_count(4), "+4")
	assert_eq(UiTheme.format_signed_count(-1), "-1")
	assert_eq(UiTheme.format_signed_count(0), "0")


func test_format_bankroll_large_value():
	assert_eq(UiTheme.format_bankroll(1000000), "$1,000,000")


func test_format_bankroll_negative():
	assert_eq(UiTheme.format_bankroll(-250), "$-250")


func test_theme_loads_without_error():
	var theme := UiTheme.load_theme()
	assert_not_null(theme)
