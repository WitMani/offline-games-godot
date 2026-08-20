extends SceneTree

const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const GAG_TILE: Texture2D = preload("res://assets/art/catalog/tile_games/gag/mahjong_tile_blank_gag_v1.png")
const GAG_PAIR_SFX: AudioStream = preload("res://assets/audio/catalog/tile_games/gag/jade_pair_resonance_gag_v1.ogg")
const REQUIRED_COPY := ["玉牌抬起", "纹样不同", "同纹共鸣 · +50", "牌阵清空 · 玉成", "玉阵完成", "点击右上角“重开”继续挑战"]
const IMAGE_SHA := "7ddfb512f1bde4c9c46447d92121b2e3c766e19e6d13a5a332cc52ba0ed1cdbc"
const AUDIO_SHA := "fe213b4ff0241ff6b3936adc02cd1830f2b9ff7563161b1ce25d85fc0a511472"
const SUPPORT_SHA := "88ae2dba64f3c832a20f3c086ed94219d2b6939c5a693fb7c94427dfaafc9fbd"

var game: Control
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_test_gag_runtime_assets()
	_test_dynamic_font_role()
	_test_initial_contract()
	_test_select_and_deselect()
	_test_mismatch()
	_test_pair()
	_test_removed_tile_is_inert()
	_test_clear()
	print("MAHJONG_ART_SMOKE=%d" % assertions)
	print("MAHJONG_ART_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func _open() -> void:
	game._open_game("mahjong")
	game.has_transitioned = false


func _last_event() -> Dictionary:
	return {} if game.catalog_fx.is_empty() else game.catalog_fx.back()


func _expect_event(kind: String, grade: int, label: String) -> void:
	var event := _last_event()
	_expect(str(event.get("game_id", "")) == "mahjong", "%s_wrong_game" % kind)
	_expect(str(event.get("kind", "")) == kind, "%s_wrong_kind" % kind)
	_expect(int(event.get("grade", 0)) == grade, "%s_wrong_grade" % kind)
	_expect(str(event.get("label", "")) == label, "%s_wrong_label" % kind)
	_expect(str(event.get("font_role", "")) == "ui_cjk", "%s_wrong_font_role" % kind)


func _last_sfx() -> AudioStream:
	var player_index := posmod(game.sfx_cursor - 1, game.sfx_players.size())
	return game.sfx_players[player_index].stream


func _test_gag_runtime_assets() -> void:
	_expect(GAG_TILE != null, "gag_tile_missing")
	_expect(GAG_TILE.get_size() == Vector2(275, 408), "gag_tile_dimensions")
	_expect(GAG_TILE.get_image().detect_alpha() != Image.ALPHA_NONE, "gag_tile_alpha")
	_expect(FileAccess.get_sha256("res://assets/art/catalog/tile_games/gag/mahjong_tile_blank_gag_v1.png") == IMAGE_SHA, "gag_tile_hash")
	_expect(GAG_PAIR_SFX != null, "gag_sfx_missing")
	_expect(GAG_PAIR_SFX.get_length() >= 0.69 and GAG_PAIR_SFX.get_length() < 0.72, "gag_sfx_duration")
	_expect(FileAccess.get_sha256("res://assets/audio/catalog/tile_games/gag/jade_pair_resonance_gag_v1.ogg") == AUDIO_SHA, "gag_sfx_hash")
	_expect(FileAccess.get_sha256("res://assets/art/catalog/tile_games/mahjong_tile_base.svg") == SUPPORT_SHA, "support_svg_hash")


func _test_dynamic_font_role() -> void:
	for sample in REQUIRED_COPY:
		for index in range(sample.length()):
			var codepoint: int = sample.unicode_at(index)
			_expect(UI_FONT.has_char(codepoint), "font_U+%04X" % codepoint)


func _test_initial_contract() -> void:
	_open()
	_expect(game.state["tiles"] == [1,2,3,4,5,6,7,8,9,10,1,2,3,4,5,6,7,8,9,10], "initial_tile_order")
	_expect(game.state["removed"].is_empty(), "initial_removed")
	_expect(int(game.state["selected"]) == -1, "initial_selected")
	_expect(int(game.state["score"]) == 0, "initial_score")
	_expect(int(game.state["moves"]) == 0, "initial_moves")
	_expect(int(game.state.get("mistakes", 0)) == 0, "initial_mistakes")
	_expect(str(game.state["status"]) == "playing", "initial_status")


func _test_select_and_deselect() -> void:
	_open()
	var frozen_tiles: Array = game.state["tiles"].duplicate(true)
	game._mahjong_tap(game._mahjong_tile_center(0))
	_expect(int(game.state["selected"]) == 0, "select_selected")
	_expect(game.state["tiles"] == frozen_tiles, "select_tiles_mutated")
	_expect(game.state["removed"].is_empty(), "select_removed")
	_expect(int(game.state["score"]) == 0, "select_score")
	_expect(int(game.state["moves"]) == 0, "select_moves")
	_expect(str(game.mahjong_object_fx.get("kind", "")) == "select", "select_object_fx")
	_expect(game.mahjong_object_fx.get("indices", []) == [0], "select_object_index")
	_expect_event("jade_select", 1, "玉牌抬起")
	game._mahjong_tap(game._mahjong_tile_center(0))
	_expect(int(game.state["selected"]) == -1, "deselect_selected")
	_expect(str(game.mahjong_object_fx.get("kind", "")) == "deselect", "deselect_object_fx")
	_expect(game.state["tiles"] == frozen_tiles, "deselect_tiles_mutated")
	_expect(int(game.state["moves"]) == 0, "deselect_moves")


func _test_mismatch() -> void:
	_open()
	var frozen_tiles: Array = game.state["tiles"].duplicate(true)
	game._mahjong_tap(game._mahjong_tile_center(0))
	game._mahjong_tap(game._mahjong_tile_center(1))
	_expect(int(game.state["selected"]) == 1, "mismatch_selected")
	_expect(int(game.state["mistakes"]) == 1, "mismatch_mistake")
	_expect(game.state["tiles"] == frozen_tiles, "mismatch_tiles_mutated")
	_expect(game.state["removed"].is_empty(), "mismatch_removed")
	_expect(int(game.state["moves"]) == 0, "mismatch_moves")
	_expect(int(game.state["score"]) == 0, "mismatch_score")
	_expect(str(game.mahjong_object_fx.get("kind", "")) == "mismatch", "mismatch_object_fx")
	_expect(game.mahjong_object_fx.get("indices", []) == [0, 1], "mismatch_object_indices")
	_expect_event("jade_mismatch", 2, "纹样不同")


func _test_pair() -> void:
	_open()
	game._mahjong_tap(game._mahjong_tile_center(0))
	game._mahjong_tap(game._mahjong_tile_center(10))
	_expect(game.state["removed"] == [0, 10], "pair_removed")
	_expect(int(game.state["selected"]) == -1, "pair_selected")
	_expect(int(game.state["score"]) == 50, "pair_score")
	_expect(int(game.state["moves"]) == 1, "pair_moves")
	_expect(int(game.state.get("mistakes", 0)) == 0, "pair_mistakes")
	_expect(str(game.state["status"]) == "playing", "pair_status")
	_expect(str(game.mahjong_object_fx.get("kind", "")) == "pair", "pair_object_fx")
	_expect(int(game.mahjong_object_fx.get("grade", 0)) == 2, "pair_object_grade")
	_expect(game.mahjong_object_fx.get("indices", []) == [0, 10], "pair_object_indices")
	_expect_event("jade_pair", 2, "同纹共鸣 · +50")
	_expect(_last_sfx() == GAG_PAIR_SFX, "pair_gag_sfx_not_routed")


func _test_removed_tile_is_inert() -> void:
	_open()
	game.state["removed"] = [0]
	var before: Dictionary = game.state.duplicate(true)
	game._mahjong_tap(game._mahjong_tile_center(0))
	_expect(game.state == before, "removed_tile_mutated_state")


func _test_clear() -> void:
	_open()
	var removed: Array = []
	for index in range(20):
		if index not in [0, 10]:
			removed.append(index)
	game.state["removed"] = removed
	game.state["selected"] = 0
	game._mahjong_tap(game._mahjong_tile_center(10))
	_expect(str(game.state["status"]) == "won", "clear_status")
	_expect(game.state["removed"].size() == 20, "clear_removed")
	_expect(int(game.state["score"]) == 50, "clear_score")
	_expect(int(game.state["moves"]) == 1, "clear_moves")
	_expect(str(game.mahjong_object_fx.get("kind", "")) == "clear", "clear_object_fx")
	_expect(int(game.mahjong_object_fx.get("grade", 0)) == 4, "clear_object_grade")
	_expect_event("jade_pair", 4, "牌阵清空 · 玉成")
	_expect(_last_sfx() == GAG_PAIR_SFX, "clear_gag_sfx_not_routed")
