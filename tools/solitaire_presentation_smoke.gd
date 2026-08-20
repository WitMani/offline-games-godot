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
	_test_tableau_move_arc()
	_test_foundation_milestone()
	_test_terminal_win()
	_test_gag_runtime_assets()
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


func _test_selection_intent() -> void:
	game._open_game("solitaire")
	var score_before := int(game.state["score"])
	var moves_before := int(game.state["moves"])
	game._solitaire_tap(Vector2(63, 448))
	var effect := _latest_effect()
	_expect(int(game.state["selected_col"]) == 0, "select:column")
	_expect(int(game.state["score"]) == score_before and int(game.state["moves"]) == moves_before, "select:mechanics_changed")
	_expect(str(effect.get("kind", "")) == "card_select" and int(effect.get("column", -1)) == 0, "select:object_event")
	_expect_arc(effect, "select_arc")


func _test_empty_column_reject() -> void:
	game._open_game("solitaire")
	var state_before := JSON.stringify(game.state)
	game._solitaire_tap(Vector2(471, 448))
	var effect := _latest_effect()
	_expect(JSON.stringify(game.state) == state_before, "reject:state_changed")
	_expect(str(effect.get("kind", "")) == "card_reject_empty", "reject:kind")
	_expect(int(effect.get("column", -1)) == 6, "reject:object")
	_expect_arc(effect, "reject_arc")


func _test_stock_deal_arc() -> void:
	game._open_game("solitaire")
	game._solitaire_draw()
	var effect := _latest_effect()
	_expect(int(game.state["stock"]) == 23 and int(game.state["waste"]) == 1 and int(game.state["moves"]) == 1, "draw:frozen_rules")
	_expect(str(effect.get("kind", "")) == "card_draw", "draw:kind")
	_expect(effect.has("from") and effect.has("to") and bool(effect.get("flip", false)), "draw:object_route")
	_expect_arc(effect, "draw_arc")


func _test_tableau_move_arc() -> void:
	game._open_game("solitaire")
	game._solitaire_tap(Vector2(63, 448))
	game._solitaire_tap(Vector2(131, 448))
	var effect := _latest_effect()
	_expect(game.state["tableau"] == [4, 5, 3, 2, 1, 0, 0], "move:tableau")
	_expect(int(game.state["score"]) == 10 and int(game.state["moves"]) == 1, "move:score")
	_expect(str(effect.get("kind", "")) == "card_move" and effect.has("from") and effect.has("to"), "move:object_route")
	_expect_arc(effect, "move_arc")


func _test_foundation_milestone() -> void:
	game._open_game("solitaire")
	game.state["foundations"] = [1, 1, 1, 0]
	game.state["tableau"] = [1, 0, 0, 0, 0, 0, 0]
	game._solitaire_auto()
	var effect := _latest_effect()
	_expect(str(effect.get("kind", "")) == "foundation_place", "milestone:kind")
	_expect(int(effect.get("grade", 0)) == 3 and int(effect.get("foundation_total", 0)) == 4, "milestone:intensity")
	_expect(int(game.state["score"]) == 25 and int(game.state["moves"]) == 1, "milestone:frozen_rules")


func _test_terminal_win() -> void:
	game._open_game("solitaire")
	game.state["foundations"] = [2, 2, 2, 1]
	game.state["tableau"] = [1, 0, 0, 0, 0, 0, 0]
	game._solitaire_auto()
	var effect := _latest_effect()
	_expect(str(game.state["status"]) == "won", "win:status")
	_expect(str(effect.get("kind", "")) == "solitaire_win" and int(effect.get("grade", 0)) == 4, "win:peak_event")
	_expect_arc(effect, "win_arc")


func _test_gag_runtime_assets() -> void:
	game._open_game("solitaire")
	var texture: Texture2D = game._card_back_texture()
	_expect(texture != null, "gag_card_back:loaded")
	_expect(texture.resource_path == "res://assets/art/cards/solitaire_card_back_gag_v1.webp", "gag_card_back:runtime_path")
	_expect(texture.get_size() == Vector2(290, 400), "gag_card_back:dimensions")
	var stream: AudioStream = game._catalog_event_sfx("card_move", 1)
	_expect(stream != null and stream.resource_path == "res://assets/audio/cards/solitaire_card_settle_gag_v1.ogg", "gag_sfx:runtime_path")
	game._start_catalog_event("card_move", Vector2(270, 440), Color("f6c667"), 2, "牌列衔接", 0.72)
	var player_index := posmod(game.sfx_cursor - 1, game.sfx_players.size())
	_expect(game.sfx_players[player_index].stream == stream, "gag_sfx:actual_event_route")


func _test_font_roles() -> void:
	for sample in ["这里没有可移动的牌", "空牌列", "四牌归位", "牌局完成"]:
		for index in range(sample.length()):
			_expect(UI_FONT.has_char(sample.unicode_at(index)), "ui_font:U+%04X" % sample.unicode_at(index))
	for sample in ["♠", "♥", "♣", "♦", "↻"]:
		_expect(SYMBOL_FONT.has_char(sample.unicode_at(0)), "symbol_font:%s" % sample)
