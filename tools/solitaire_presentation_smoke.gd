extends SceneTree

const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const SYMBOL_FONT: Font = preload("res://assets/fonts/Unifont.otf")

var game: Control
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_test_selection_intent()
	_test_empty_column_reject()
	_test_stock_deal_arc()
	_test_legal_tableau_move_arc()
	_test_foundation_suit_milestone()
	_test_terminal_win()
	_test_gag_runtime_assets()
	_test_reduced_effects_contract()
	_test_font_roles()
	print("SOLITAIRE_PRESENTATION_SMOKE=%d" % assertions)
	print("SOLITAIRE_PRESENTATION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	var exit_code := 0 if failures.is_empty() else 1
	for player in game.sfx_players:
		player.stop()
	game.queue_free()
	await process_frame
	quit(exit_code)


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)


func _latest_effect() -> Dictionary:
	return game.catalog_fx.back() if not game.catalog_fx.is_empty() else {}


func _expect_arc(effect: Dictionary, label: String) -> void:
	var started := float(effect.get("started", 0.0))
	var duration := float(effect.get("duration", 0.72))
	var expected := ["intent", "anticipation", "impact", "settle"]
	var samples := [0.06, 0.25, 0.55, 0.88]
	for index in range(samples.size()):
		_expect(game._card_event_phase_at(effect, started + duration * samples[index]) == expected[index], "%s:%s" % [label, expected[index]])


func _cid(rank: int, suit: int) -> int:
	return suit * 13 + rank - 1


func _fixture(piles: Array, waste: Array = [], foundation_counts: Array = [0, 0, 0, 0]) -> Dictionary:
	var saved: Dictionary = game.solitaire_model.snapshot()
	var used := {}
	var foundations: Array = []
	for suit in range(4):
		var foundation: Array = []
		for rank in range(1, int(foundation_counts[suit]) + 1):
			var card := _cid(rank, suit)
			used[card] = true
			foundation.append(card)
		foundations.append(foundation)
	var tableau: Array = []
	for column in range(7):
		var pile: Array = piles[column].duplicate(true) if column < piles.size() else []
		for entry in pile:
			used[int(entry["card"])] = true
		tableau.append(pile)
	var normalized_waste: Array = []
	for value in waste:
		used[int(value)] = true
		normalized_waste.append(int(value))
	var stock: Array = []
	for card in range(52):
		if not used.has(card):
			stock.append(card)
	saved["stock"] = stock
	saved["waste"] = normalized_waste
	saved["tableau"] = tableau
	saved["foundations"] = foundations
	saved["score"] = 0
	saved["moves"] = 0
	saved["recycles_used"] = 0
	saved["status"] = "playing"
	return saved


func _test_selection_intent() -> void:
	game._open_game("solitaire")
	var score_before := int(game.state["score"])
	var moves_before := int(game.state["moves"])
	game._solitaire_tap(Vector2(63, 448))
	var effect := _latest_effect()
	_expect(str(game.state.get("selection", {}).get("kind", "")) == "tableau", "select:kind")
	_expect(int(game.state.get("selection", {}).get("column", -1)) == 0, "select:column")
	_expect(int(game.state["score"]) == score_before and int(game.state["moves"]) == moves_before, "select:mechanics_changed")
	_expect(str(effect.get("kind", "")) == "card_select" and int(effect.get("column", -1)) == 0, "select:object_event")
	_expect_arc(effect, "select_arc")


func _test_empty_column_reject() -> void:
	game._open_game("solitaire")
	var fixture := _fixture([])
	_expect(game._restore_solitaire_snapshot(fixture), "reject:fixture")
	var state_before := JSON.stringify(game.solitaire_model.snapshot())
	game._solitaire_tap(Vector2(471, 448))
	var effect := _latest_effect()
	_expect(JSON.stringify(game.solitaire_model.snapshot()) == state_before, "reject:model_changed")
	_expect(str(effect.get("kind", "")) == "card_reject_tableau_empty", "reject:kind")
	_expect(int(effect.get("column", -1)) == 6, "reject:object")
	_expect_arc(effect, "reject_arc")


func _test_stock_deal_arc() -> void:
	game._open_game("solitaire")
	var top_before := int(game.state["stock"].back())
	game._solitaire_draw()
	var effect := _latest_effect()
	_expect(game.state["stock"].size() == 23 and game.state["waste"].size() == 1 and int(game.state["moves"]) == 1, "draw:legal_state")
	_expect(int(game.state["waste"].back()) == top_before, "draw:card_identity")
	_expect(str(effect.get("kind", "")) == "card_draw", "draw:kind")
	_expect(effect.has("from") and effect.has("to") and bool(effect.get("flip", false)), "draw:object_route")
	_expect_arc(effect, "draw_arc")


func _test_legal_tableau_move_arc() -> void:
	game._open_game("solitaire")
	var fixture := _fixture([
		[{"card":_cid(9, 3), "face_up":true}],
		[{"card":_cid(10, 2), "face_up":true}],
	])
	_expect(game._restore_solitaire_snapshot(fixture), "move:fixture")
	game._solitaire_tap(Vector2(63, 448))
	game._solitaire_tap(Vector2(131, 448))
	var effect := _latest_effect()
	_expect(game.state["tableau"][0].is_empty() and game.state["tableau"][1].size() == 2, "move:tableau")
	_expect(int(game.state["score"]) == 5 and int(game.state["moves"]) == 1, "move:score")
	_expect(str(effect.get("kind", "")) == "card_move" and effect.has("from") and effect.has("to"), "move:object_route")
	_expect_arc(effect, "move_arc")


func _test_foundation_suit_milestone() -> void:
	game._open_game("solitaire")
	var king_spades := _cid(13, 0)
	var fixture := _fixture([], [king_spades], [12, 0, 0, 0])
	_expect(game._restore_solitaire_snapshot(fixture), "milestone:fixture")
	game._solitaire_auto()
	var effect := _latest_effect()
	_expect(str(effect.get("kind", "")) == "foundation_place", "milestone:kind")
	_expect(int(effect.get("grade", 0)) == 3 and int(effect.get("foundation_total", 0)) == 13, "milestone:intensity")
	_expect(int(game.state["score"]) == 10 and int(game.state["moves"]) == 1, "milestone:legal_state")
	_expect_arc(effect, "milestone_arc")


func _test_terminal_win() -> void:
	game._open_game("solitaire")
	var king_diamonds := _cid(13, 3)
	var fixture := _fixture([], [king_diamonds], [13, 13, 13, 12])
	_expect(game._restore_solitaire_snapshot(fixture), "win:fixture")
	game._solitaire_auto()
	var effect := _latest_effect()
	_expect(str(game.state["status"]) == "won" and int(game.state["foundation_total"]) == 52, "win:status")
	_expect(str(effect.get("kind", "")) == "solitaire_win" and int(effect.get("grade", 0)) == 4, "win:peak_event")
	_expect_arc(effect, "win_arc")


func _test_gag_runtime_assets() -> void:
	game._open_game("solitaire")
	var texture: Texture2D = game._card_back_texture()
	_expect(texture != null, "gag_card_back:loaded")
	_expect(texture.resource_path == "res://assets/art/cards/solitaire_card_back_gag_v1.webp", "gag_card_back:runtime_path")
	_expect(texture.get_size() == Vector2(290, 400), "gag_card_back:dimensions")
	var opening_back_count := 1 if not game.solitaire_model.stock.is_empty() else 0
	for pile in game.solitaire_model.tableau:
		for entry in pile:
			if not bool(entry.get("face_up", false)):
				opening_back_count += 1
	_expect(opening_back_count == 22, "gag_card_back:ordinary_opening_instances")
	var stream: AudioStream = game._catalog_event_sfx("card_move", 1)
	_expect(stream != null and stream.resource_path == "res://assets/audio/cards/solitaire_card_settle_gag_v1.ogg", "gag_sfx:runtime_path")
	for event_kind in ["card_draw", "card_recycle", "card_move", "foundation_place", "solitaire_win"]:
		var grade := 4 if event_kind == "solitaire_win" else (2 if event_kind == "foundation_place" else 1)
		var routed: AudioStream = game._catalog_event_sfx(event_kind, grade)
		_expect(routed == stream, "gag_sfx:%s_route" % event_kind)
		game._start_catalog_event(event_kind, Vector2(270, 440), Color("f6c667"), grade, "牌桌反馈", 0.72)
		var player_index := posmod(game.sfx_cursor - 1, game.sfx_players.size())
		_expect(game.sfx_players[player_index].stream == stream, "gag_sfx:%s_actual_player" % event_kind)
	_expect(game._catalog_event_sfx("card_select", 1) != stream, "gag_sfx:selection_not_overpromoted")


func _test_reduced_effects_contract() -> void:
	game._set_solitaire_reduced_effects(false)
	game._open_game("solitaire")
	game.catalog_fx.clear()
	game.solitaire_haptic_emissions = 0
	game._solitaire_draw()
	var full_snapshot := JSON.stringify(game.solitaire_model.snapshot())
	_expect(game.solitaire_haptic_emissions == 1, "reduced:full_haptic_baseline")

	game._set_solitaire_reduced_effects(true)
	game._open_game("solitaire")
	game.catalog_fx.clear()
	game.solitaire_haptic_emissions = 0
	game._solitaire_draw()
	var reduced_snapshot := JSON.stringify(game.solitaire_model.snapshot())
	var reduced_effect := _latest_effect()
	_expect(reduced_snapshot == full_snapshot, "reduced:mechanics_identical")
	_expect(bool(game.state.get("reduced_effects", false)), "reduced:state_exposed")
	_expect(bool(reduced_effect.get("reduced_effects", false)), "reduced:event_tag")
	_expect(str(reduced_effect.get("motion_mode", "")) == "static_result", "reduced:static_result_mode")
	_expect(float(reduced_effect.get("duration", 1.0)) <= 0.24, "reduced:duration_bounded")
	_expect(game.solitaire_haptic_emissions == 0, "reduced:haptic_suppressed")
	game._start_catalog_event("card_reject_tableau_rule", Vector2(270, 440), Color("ff708b"), 3, "", 0.72, {"column":2, "card_index":2})
	_expect(game._catalog_shake_offset() == Vector2.ZERO, "reduced:global_shake_suppressed")
	_expect(game._card_object_reject_offset(2) == Vector2.ZERO, "reduced:object_shake_suppressed")
	_expect(game.solitaire_haptic_emissions == 0, "reduced:reject_haptic_suppressed")
	game._set_solitaire_reduced_effects(false)


func _test_font_roles() -> void:
	game._open_game("solitaire")
	game._start_catalog_event("foundation_place", Vector2(374, 289), Color("f6c667"), 2, "归位 · +10", 0.72)
	_expect(str(_latest_effect().get("font_role", "")) == "ui_cjk", "ui_font:dynamic_event_role")
	for sample in ["这里没有牌", "牌库重整", "整组归位", "四组归位", "牌局完成", "新牌局已发好"]:
		for index in range(sample.length()):
			_expect(UI_FONT.has_char(sample.unicode_at(index)), "ui_font:U+%04X" % sample.unicode_at(index))
	for sample in ["♠", "♥", "♣", "♦", "↻"]:
		_expect(SYMBOL_FONT.has_char(sample.unicode_at(0)), "symbol_font:%s" % sample)
