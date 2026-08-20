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
	_test_stock_deal_arc()
	_test_locked_reject()
	_test_rank_reject()
	_test_streak_ladder()
	_test_peak_milestone()
	_test_terminal_win()
	_test_gag_runtime_assets()
	_test_font_roles()
	print("TRIPEAKS_PRESENTATION_SMOKE=%d" % assertions)
	print("TRIPEAKS_PRESENTATION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
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


func _test_stock_deal_arc() -> void:
	game._open_game("tripeaks")
	game._tripeaks_next()
	var effect := _latest_effect()
	_expect(int(game.state["stock"]) == 11 and int(game.state["current"]) == 12 and int(game.state["moves"]) == 1, "draw:frozen_rules")
	_expect(str(effect.get("kind", "")) == "card_draw" and bool(effect.get("flip", false)), "draw:object_route")
	_expect_arc(effect, "draw_arc")


func _test_locked_reject() -> void:
	game._open_game("tripeaks")
	var state_before := JSON.stringify(game.state)
	game._tripeaks_tap(game._tripeaks_card_center(0))
	var effect := _latest_effect()
	_expect(JSON.stringify(game.state) == state_before, "locked:state_changed")
	_expect(str(effect.get("kind", "")) == "card_reject_locked" and int(effect.get("card_index", -1)) == 0, "locked:object_event")
	_expect_arc(effect, "locked_arc")


func _test_rank_reject() -> void:
	game._open_game("tripeaks")
	game.state["streak"] = 3
	var removed_before: Array = game.state["removed"].duplicate()
	game._tripeaks_tap(game._tripeaks_card_center(5))
	var effect := _latest_effect()
	_expect(game.state["removed"] == removed_before and int(game.state["current"]) == 7, "rank_reject:frozen_board")
	_expect(int(game.state["streak"]) == 0, "rank_reject:existing_reset")
	_expect(str(effect.get("kind", "")) == "card_reject_rank" and int(effect.get("card_index", -1)) == 5, "rank_reject:object_event")
	_expect_arc(effect, "rank_reject_arc")


func _test_streak_ladder() -> void:
	var starting_streaks := [0, 1, 3, 5]
	var expected_grades := [1, 2, 3, 4]
	for index in range(starting_streaks.size()):
		game._open_game("tripeaks")
		game.state["current"] = 8
		game.state["streak"] = starting_streaks[index]
		game._tripeaks_tap(game._tripeaks_card_center(5))
		var effect := _find_effect("card_streak")
		_expect(not effect.is_empty(), "streak_%d:event" % expected_grades[index])
		_expect(int(effect.get("grade", 0)) == expected_grades[index], "streak_%d:grade" % expected_grades[index])
		_expect(effect.has("from") and effect.has("to") and int(effect.get("card_index", -1)) == 5, "streak_%d:object_route" % expected_grades[index])


func _test_peak_milestone() -> void:
	game._open_game("tripeaks")
	game.state["current"] = 8
	game.state["removed"] = [0, 1, 2, 3]
	game._tripeaks_tap(game._tripeaks_card_center(5))
	var effect := _find_effect("peak_milestone")
	_expect(not effect.is_empty() and int(effect.get("grade", 0)) == 3, "milestone:event")
	_expect(int(effect.get("cleared", 0)) == 5, "milestone:semantic_count")


func _test_terminal_win() -> void:
	game._open_game("tripeaks")
	game.state["current"] = 8
	var removed: Array = []
	for index in range(game.state["cards"].size()):
		if index != 5:
			removed.append(index)
	game.state["removed"] = removed
	game._tripeaks_tap(game._tripeaks_card_center(5))
	var effect := _latest_effect()
	_expect(str(game.state["status"]) == "won" and game.state["removed"].size() == game.state["cards"].size(), "win:frozen_result")
	_expect(str(effect.get("kind", "")) == "tripeaks_win" and int(effect.get("grade", 0)) == 4, "win:peak_event")
	_expect_arc(effect, "win_arc")


func _test_gag_runtime_assets() -> void:
	game._open_game("tripeaks")
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
	for sample in ["牌库已空", "三峰全清", "峰顶点亮", "连牌"]:
		for index in range(sample.length()):
			_expect(UI_FONT.has_char(sample.unicode_at(index)), "ui_font:U+%04X" % sample.unicode_at(index))
	for sample in ["♠", "♥", "♣", "♦"]:
		_expect(SYMBOL_FONT.has_char(sample.unicode_at(0)), "symbol_font:%s" % sample)
