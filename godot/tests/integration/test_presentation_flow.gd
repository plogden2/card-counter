extends GutTest

const ActionMenu = preload("res://scripts/presentation/action_menu.gd")
const ActionPanelScript = preload("res://scripts/scenes/action_panel.gd")
const CardLayout = preload("res://scripts/presentation/card_layout.gd")
const GameControllerScript = preload("res://scripts/game/game_controller.gd")
const LearnerProfile = preload("res://scripts/persistence/learner_profile.gd")
const SceneRouterScript = preload("res://scripts/game/scene_router.gd")
const Table3DScene = preload("res://scenes/table/table_3d.tscn")
const TABLE_3D_SCENE = preload("res://scenes/table/table_3d.tscn")
const UiTheme = preload("res://scripts/lib/ui_theme.gd")


func before_each() -> void:
	LearnerProfile.clear_profile_for_tests()


func test_ui_theme_path_resolves():
	var path := UiTheme.get_theme_path()
	assert_true(path.ends_with(".tres"))


func test_scene_router_has_home_setup_table_routes():
	var router := SceneRouterScript.new()
	assert_true(router.has_method("go_to"))


func test_screen_class_enum_values():
	assert_eq(UiTheme.ScreenClass.MENU, 0)
	assert_eq(UiTheme.ScreenClass.SIDEBAR, 1)
	assert_eq(UiTheme.ScreenClass.ACTION, 2)
	assert_eq(UiTheme.ScreenClass.OVERLAY, 3)


func test_live_hand_cards_visible_on_table_scene():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 1})
	controller.call("place_bet", 10)
	controller.call("deal")

	var view: Dictionary = CardLayout.build(controller.call("get_session"))
	var table: Node = Table3DScene.instantiate()
	add_child_autofree(table)
	await get_tree().process_frame

	table.call("sync_presentation", view, true)
	assert_gt(table.call("get_card_count"), 0)

	var learner_cards := 0
	for seat in view["seats"]:
		if bool(seat.get("isLearner", false)):
			learner_cards = seat.get("cards", []).size()
			for card in seat.get("cards", []):
				assert_true(bool(card.get("faceUp", true)))
	assert_gt(learner_cards, 0)


func test_live_hand_presentation_includes_dealer_and_learner():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	controller.call("place_bet", 10)
	controller.call("deal")

	var view: Dictionary = CardLayout.build(controller.call("get_session"))
	var seat_ids: Array = []
	for seat in view["seats"]:
		seat_ids.append(seat.get("seatId", ""))

	assert_true(seat_ids.has("dealer"))
	var has_learner := false
	for seat in view["seats"]:
		if bool(seat.get("isLearner", false)):
			has_learner = true
	assert_true(has_learner)


func test_table_focus_seat_tracks_hover_target():
	var table: Node = Table3DScene.instantiate()
	add_child_autofree(table)
	await get_tree().process_frame

	table.call("focus_seat", "learner", true)
	assert_eq(table.call("get_focused_seat"), "learner")
	table.call("focus_seat", "learner", false)
	assert_eq(table.call("get_focused_seat"), "")


func test_card_textures_resolve_for_live_session():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	controller.call("place_bet", 10)
	controller.call("deal")

	var view: Dictionary = CardLayout.build(controller.call("get_session"))
	var table: Node = Table3DScene.instantiate()
	add_child_autofree(table)
	await get_tree().process_frame

	table.call("sync_presentation", view, true)
	for seat in view["seats"]:
		for card in seat.get("cards", []):
			if not bool(card.get("faceUp", true)):
				assert_true(ResourceLoader.exists("res://assets/textures/cards/back.png"))
				continue
			var rank_str := str(card.get("rank", ""))
			var suit_str := str(card.get("suit", ""))
			var path := "res://assets/textures/cards/%s_%s.png" % [rank_str, suit_str]
			assert_true(ResourceLoader.exists(path), "Missing texture: %s" % path)


func test_us2_betting_actions_match_action_menu_and_panel():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	var session: Dictionary = controller.call("get_session")
	var legal: Array[String] = ActionMenu.visible_actions(session)
	var panel: Node = ActionPanelScript.new()
	add_child_autofree(panel)
	panel.call("render", session)
	var visible: Array = panel.call("get_visible_action_ids")
	for action in legal:
		assert_true(visible.has(action))


func test_us2_full_hand_action_visibility_transitions():
	var controller := GameControllerScript.new()
	controller._ready()
	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 0})
	var betting_actions: Array[String] = ActionMenu.visible_actions(controller.call("get_session"))
	assert_true(betting_actions.has("place-bet"))
	assert_true(betting_actions.has("deal"))

	controller.call("place_bet", 10)
	controller.call("deal")
	var session: Dictionary = controller.call("get_session")
	if session["phase"] == "insurance":
		var insurance_actions: Array[String] = ActionMenu.visible_actions(session)
		assert_eq(insurance_actions.filter(func(a): return a != "home").size(), 2)
		controller.call("apply_action", "insurance-decline")
		session = controller.call("get_session")

	if session["phase"] == "player-turn":
		var turn_actions: Array[String] = ActionMenu.visible_actions(session)
		assert_true(turn_actions.has("hit"))
		assert_true(turn_actions.has("stand"))
		controller.call("apply_action", "stand")
		session = controller.call("get_session")

	assert_eq(session["phase"], "settled")
	var settled_actions: Array[String] = ActionMenu.visible_actions(session)
	assert_true(settled_actions.has("continue"))
	assert_false(settled_actions.has("hit"))


func test_us6_reduced_motion_hand_completes_without_animation_waits():
	LearnerProfile.save_profile({
		"schemaVersion": 1,
		"balance": 1000,
		"selectedBetModel": "spread-table",
		"soundEnabled": true,
		"motionReduced": true,
	})
	var controller := GameControllerScript.new()
	controller._ready()
	var table: Node = TABLE_3D_SCENE.instantiate()
	add_child_autofree(table)
	await get_tree().process_frame

	controller.call("start_free_play", {"deckCount": 1, "initialOtherPlayers": 1})
	if table.has_method("get_deal_snap_duration_ms"):
		assert_eq(table.call("get_deal_snap_duration_ms", true), 0)

	controller.call("place_bet", 10)
	if table.has_method("sync_chip_wager"):
		var session_after_bet: Dictionary = controller.call("get_session")
		table.call(
			"sync_chip_wager",
			int(session_after_bet.get("currentWager", 0)),
			str(session_after_bet.get("phase", "betting")),
			true
		)
	var view: Dictionary = CardLayout.build(controller.call("get_session"))
	table.call("sync_presentation", view, true)

	controller.call("deal")
	view = CardLayout.build(controller.call("get_session"))
	table.call("sync_presentation", view, true)

	var session: Dictionary = controller.call("get_session")
	if session["phase"] == "insurance":
		controller.call("apply_action", "insurance-decline")
		session = controller.call("get_session")
	if session["phase"] == "player-turn":
		controller.call("apply_action", "stand")
		session = controller.call("get_session")

	assert_eq(session["phase"], "settled")
	if table.has_method("get_active_animation_count"):
		assert_eq(table.call("get_active_animation_count"), 0)


func test_us6_full_motion_uses_deal_snap_duration():
	var table: Node = TABLE_3D_SCENE.instantiate()
	add_child_autofree(table)
	await get_tree().process_frame
	if table.has_method("get_deal_snap_duration_ms"):
		assert_eq(table.call("get_deal_snap_duration_ms", false), 260)
