extends SceneTree

const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const LATIN_FONT: Font = preload("res://assets/fonts/DejaVuSans.ttf")
const NUMBER_FONT: Font = preload("res://assets/fonts/DejaVuSans.ttf")
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
	game.set_process(false)
	_test_stable_signature_visibility()
	_test_stock_deal_arc()
	_test_locked_reject()
	_test_rank_reject()
	_test_streak_ladder()
	_test_reveal_object_route()
	_test_peak_milestone()
	_test_terminal_win()
	_test_terminal_loss()
	_test_reduced_effects_authority()
	_test_gag_runtime_assets()
	_test_font_roles()
	print("TRIPEAKS_PRESENTATION_SMOKE=%d" % assertions)
	print("TRIPEAKS_PRESENTATION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	var exit_code := 0 if failures.is_empty() else 1
	for player in game.sfx_players:
		player.stop()
	game._clear_tripeaks_snapshot()
	game.queue_free()
	await process_frame
	quit(exit_code)


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)


func _latest_effect() -> Dictionary:
	return game.catalog_fx.back() if not game.catalog_fx.is_empty() else {}


func _find_effect(kind: String) -> Dictionary:
	for index in range(game.catalog_fx.size() - 1, -1, -1):
		var effect: Dictionary = game.catalog_fx[index]
		if str(effect.get("kind", "")) == kind:
			return effect
	return {}


func _expect_arc(effect: Dictionary, label: String) -> void:
	var started := float(effect.get("started", 0.0))
	var duration := float(effect.get("duration", 0.72))
	var expected := ["intent", "anticipation", "impact", "settle"]
	var samples := [0.06, 0.25, 0.55, 0.88]
	for index in range(samples.size()):
		_expect(game._card_event_phase_at(effect, started + duration * samples[index]) == expected[index], "%s:%s" % [label, expected[index]])


func _open_fresh() -> void:
	game._clear_tripeaks_snapshot()
	game.tripeaks_restart_requested = true
	game._open_game("tripeaks")
	game.tripeaks_restart_requested = false


func _cid(rank: int, suit: int = 0) -> int:
	return suit * 13 + rank - 1


func _fixture(active_slots: Dictionary, waste_top: int, stock_cards: Array = [], fixture_streak := 0) -> Dictionary:
	var used := {}
	var tableau: Array = []
	for slot in range(28):
		var card := int(active_slots.get(slot, -1))
		if card >= 0:
			used[card] = true
		tableau.append(card)
	used[waste_top] = true
	var stock: Array = []
	for value in stock_cards:
		used[int(value)] = true
		stock.append(int(value))
	var waste: Array = []
	for card in range(52):
		if not used.has(card):
			waste.append(card)
	waste.append(waste_top)
	var removed: Array = []
	for slot in range(28):
		if int(tableau[slot]) < 0:
			removed.append(slot)
	var saved: Dictionary = game.tripeaks_model.snapshot()
	saved["tableau"] = tableau
	saved["removed"] = removed
	saved["stock"] = stock
	saved["waste"] = waste
	saved["score"] = removed.size() * 30
	saved["moves"] = waste.size() - 1
	saved["streak"] = fixture_streak
	saved["status"] = "playing"
	saved["remaining"] = active_slots.size()
	return saved


func _test_stable_signature_visibility() -> void:
	_open_fresh()
	var locked_count := 0
	for slot in range(28):
		if int(game.tripeaks_model.tableau[slot]) >= 0 and not game.tripeaks_model.is_exposed(slot):
			locked_count += 1
	_expect(locked_count == 18, "stable:locked_back_count_18")
	_expect(game.state["stock"].size() == 23, "stable:stock_back_visible")
	_expect(locked_count + 1 == 19, "stable:gag_back_instances_19")


func _test_stock_deal_arc() -> void:
	_open_fresh()
	var before_card := int(game.state["stock"].back())
	game._tripeaks_next()
	var effect := _latest_effect()
	_expect(game.state["stock"].size() == 22 and int(game.state["waste"].back()) == before_card and int(game.state["moves"]) == 1, "draw:real_card_rules")
	_expect(str(effect.get("kind", "")) == "card_draw" and bool(effect.get("flip", false)), "draw:object_route")
	_expect_arc(effect, "draw_arc")


func _test_locked_reject() -> void:
	_open_fresh()
	var state_before := JSON.stringify(game.tripeaks_model.snapshot())
	game._tripeaks_tap(game._tripeaks_card_center(0))
	var effect := _latest_effect()
	_expect(JSON.stringify(game.tripeaks_model.snapshot()) == state_before, "locked:model_state_changed")
	_expect(str(effect.get("kind", "")) == "card_reject_locked" and int(effect.get("card_index", -1)) == 0, "locked:object_event")
	_expect_arc(effect, "locked_arc")


func _test_rank_reject() -> void:
	_open_fresh()
	var fixture := _fixture({0:_cid(12, 3), 3:_cid(11, 2), 9:_cid(10, 1), 18:_cid(9, 0)}, _cid(5, 2), [_cid(2, 3)], 3)
	var accepted: bool = game._restore_tripeaks_snapshot(fixture)
	var before := JSON.stringify(game.tripeaks_model.snapshot())
	game._tripeaks_tap(game._tripeaks_card_center(18))
	var effect := _latest_effect()
	_expect(accepted and JSON.stringify(game.tripeaks_model.snapshot()) == before and int(game.state["streak"]) == 3, "rank_reject:atomic_board_and_streak")
	_expect(str(effect.get("kind", "")) == "card_reject_rank_not_adjacent" and int(effect.get("card_index", -1)) == 18, "rank_reject:object_event")
	_expect_arc(effect, "rank_reject_arc")


func _test_streak_ladder() -> void:
	var starting_streaks := [0, 2, 4, 6]
	var expected_grades := [1, 2, 3, 4]
	for index in range(starting_streaks.size()):
		_open_fresh()
		var fixture := _fixture({0:_cid(12, 3), 3:_cid(11, 2), 9:_cid(7, 1), 18:_cid(6, 0)}, _cid(5, 2), [_cid(2, 3)], starting_streaks[index])
		game._restore_tripeaks_snapshot(fixture)
		game._tripeaks_tap(game._tripeaks_card_center(18))
		var expected_kind := "card_clear" if expected_grades[index] == 1 else "card_streak"
		var effect := _find_effect(expected_kind)
		_expect(not effect.is_empty(), "streak_%d:event" % expected_grades[index])
		_expect(int(effect.get("grade", 0)) == expected_grades[index], "streak_%d:grade" % expected_grades[index])
		_expect(effect.has("from") and effect.has("to") and int(effect.get("card_index", -1)) == 18, "streak_%d:object_route" % expected_grades[index])
		_expect(str(effect.get("font_role", "")) == "ui_cjk", "streak_%d:cjk_role" % expected_grades[index])
		if expected_grades[index] == 4:
			var intent_shake: Vector2 = game.catalog_art_director.shake_offset(effect, float(effect["started"]) + float(effect["duration"]) * 0.10)
			var impact_shake: Vector2 = game.catalog_art_director.shake_offset(effect, float(effect["started"]) + float(effect["duration"]) * 0.41)
			_expect(intent_shake == Vector2.ZERO and impact_shake.length() > 0.05, "streak_4:impact_only_camera")


func _test_reveal_object_route() -> void:
	_open_fresh()
	var fixture := _fixture({0:_cid(12, 3), 3:_cid(11, 2), 9:_cid(7, 1), 18:_cid(6, 0)}, _cid(5, 2), [_cid(2, 3)], 2)
	var accepted: bool = game._restore_tripeaks_snapshot(fixture)
	game._tripeaks_tap(game._tripeaks_card_center(18))
	var clear_effect := _find_effect("card_streak")
	var reveal_effect := _find_effect("card_reveal")
	_expect(accepted and not clear_effect.is_empty() and not reveal_effect.is_empty(), "reveal:paired_with_authoritative_clear")
	_expect(int(reveal_effect.get("card_index", -1)) == 9 and bool(reveal_effect.get("reveal", false)), "reveal:exact_new_exposed_slot")
	_expect(bool(reveal_effect.get("silent", false)) and float(reveal_effect.get("started", 0.0)) > float(clear_effect.get("started", 0.0)), "reveal:bounded_child_envelope")
	_expect_arc(reveal_effect, "reveal_arc")


func _test_peak_milestone() -> void:
	_open_fresh()
	var fixture := _fixture({0:_cid(6, 0), 1:_cid(9, 1), 2:_cid(11, 2)}, _cid(5, 3), [_cid(2, 3)])
	var accepted: bool = game._restore_tripeaks_snapshot(fixture)
	game._tripeaks_tap(game._tripeaks_card_center(0))
	var effect := _find_effect("peak_milestone")
	_expect(accepted and not effect.is_empty() and int(effect.get("grade", 0)) == 3, "milestone:event")
	_expect(int(effect.get("peak_count", 0)) == 1, "milestone:semantic_count")


func _test_terminal_win() -> void:
	_open_fresh()
	var fixture := _fixture({0:_cid(6, 0)}, _cid(5, 2), [], 2)
	var accepted: bool = game._restore_tripeaks_snapshot(fixture)
	game._tripeaks_tap(game._tripeaks_card_center(0))
	var effect := _latest_effect()
	_expect(accepted and str(game.state["status"]) == "won" and int(game.state["remaining"]) == 0, "win:frozen_result")
	_expect(str(effect.get("kind", "")) == "tripeaks_win" and int(effect.get("grade", 0)) == 4, "win:peak_event")
	_expect_arc(effect, "win_arc")


func _test_terminal_loss() -> void:
	_open_fresh()
	var fixture := _fixture({0:_cid(12, 0), 3:_cid(11, 1), 9:_cid(10, 2), 18:_cid(9, 0)}, _cid(5, 2), [_cid(2, 3)])
	var accepted: bool = game._restore_tripeaks_snapshot(fixture)
	game._tripeaks_next()
	var effect := _find_effect("tripeaks_loss")
	_expect(accepted and str(game.state["status"]) == "lost" and not effect.is_empty(), "loss:frozen_semantic_event")
	_expect(int(effect.get("grade", 0)) == 3 and game._catalog_event_sfx("tripeaks_loss", 3) == game.SFX_SNAKE_REJECT, "loss:non_celebration_route")
	_expect_arc(effect, "loss_arc")


func _test_reduced_effects_authority() -> void:
	_open_fresh()
	var fixture := _fixture({0:_cid(12, 3), 3:_cid(11, 2), 9:_cid(7, 1), 18:_cid(6, 0)}, _cid(5, 2), [_cid(2, 3)], 4)
	var accepted: bool = game._restore_tripeaks_snapshot(fixture)
	game._set_tripeaks_reduced_effects(true)
	var before_haptics: int = int(game.tripeaks_haptic_emissions)
	game._tripeaks_tap(game._tripeaks_card_center(18))
	_expect(accepted and int(game.tripeaks_model.tableau[18]) == -1 and int(game.state["score"]) == int(fixture["score"]) + 30, "reduced:authoritative_clear")
	_expect(game.catalog_fx.is_empty() and game._catalog_shake_offset() == Vector2.ZERO, "reduced:no_displacement_or_shake")
	_expect(game.tripeaks_haptic_emissions == before_haptics and int(game.state["haptic_emissions"]) == before_haptics, "reduced:no_haptic_emission")
	_expect(game.feedback_text == "连牌上升", "reduced:text_result_preserved")
	game._set_tripeaks_reduced_effects(false)


func _test_gag_runtime_assets() -> void:
	_open_fresh()
	var texture: Texture2D = game._card_back_texture()
	_expect(texture != null, "gag_card_back:loaded")
	_expect(texture.resource_path == "res://assets/art/cards/tripeaks_card_back_gag_v1.webp", "gag_card_back:runtime_path")
	_expect(texture.get_size() == Vector2(290, 400), "gag_card_back:dimensions")
	var stream: AudioStream = game._catalog_event_sfx("card_streak", 4)
	_expect(stream != null and stream.resource_path == "res://assets/audio/cards/tripeaks_streak_peak_gag_v1.ogg", "gag_sfx:runtime_path")
	game._start_catalog_event("card_streak", Vector2(270, 382), Color("f6c667"), 4, "连牌 ×8", 1.02)
	var player_index := posmod(game.sfx_cursor - 1, game.sfx_players.size())
	_expect(game.sfx_players[player_index].stream == stream, "gag_sfx:actual_event_route")


func _test_font_roles() -> void:
	for sample in ["新牌局已发好", "先清除压住它的两张牌", "点数需与当前牌相邻", "翻开牌库", "相邻收牌", "连牌上升", "峰顶点亮", "三峰全清", "牌库耗尽本局结束", "月影三峰牌桌", "只收未被压住的相邻点数", "首尾点数相接按键翻牌"]:
		for index in range(sample.length()):
			_expect(UI_FONT.has_char(sample.unicode_at(index)), "ui_font:U+%04X" % sample.unicode_at(index))
	for sample in ["A", "K", "Q", "J"]:
		_expect(LATIN_FONT.has_char(sample.unicode_at(0)), "latin_font:%s" % sample)
	for sample in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]:
		_expect(NUMBER_FONT.has_char(sample.unicode_at(0)), "number_font:%s" % sample)
	for sample in ["♠", "♥", "♣", "♦"]:
		_expect(SYMBOL_FONT.has_char(sample.unicode_at(0)), "symbol_font:%s" % sample)
