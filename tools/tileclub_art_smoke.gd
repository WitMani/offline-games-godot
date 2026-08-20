extends SceneTree

const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const GAG_BADGE_ATLAS: Texture2D = preload("res://assets/art/catalog/tile_games/gag/tileclub_badge_atlas_gag_v1.png")
const GAG_SHELL: Texture2D = preload("res://assets/art/catalog/tile_games/gag/tileclub_shell_badge_gag_v1.png")
const GAG_MATCH_SFX: AudioStream = preload("res://assets/audio/catalog/tile_games/gag/fabric_triple_stitch_gag_v1.ogg")
const ATLAS_SHA := "7c34fff62346dce7ff0b9df3a49e8fad90bd06793c7223d81824b151b64d3002"
const SHELL_SHA := "08072a34d1170ecc0e6ccca9849436e98e881195d85b78495e923cbc5241da83"
const AUDIO_SHA := "66b4020ee32846cdfa86268b6de5136e47ded36823b1f9cb915d59296c29a8e3"
const REQUIRED_COPY := [
	"叶片入槽", "三枚缝合 · +100", "织毯完成 · 清盘",
	"槽位吃紧 · 余 2 格", "只余一格 · 谨慎落片", "槽位绷满 · 本局结束",
	"玩具俱乐部", "三枚同图案自动消除", "集齐三枚自动消除 · 七格满则结束",
]

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
	_test_inert_inputs()
	_test_collect()
	_test_risk_hierarchy()
	_test_match()
	_test_full_tray()
	_test_clear_match()
	_test_clear_without_match()
	print("TILECLUB_ART_SMOKE=%d" % assertions)
	print("TILECLUB_ART_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func _open() -> void:
	game._open_game("tileclub")
	game.has_transitioned = false


func _last_event() -> Dictionary:
	return {} if game.catalog_fx.is_empty() else game.catalog_fx.back()


func _last_sfx() -> AudioStream:
	var player_index := posmod(game.sfx_cursor - 1, game.sfx_players.size())
	return game.sfx_players[player_index].stream


func _expect_event(kind: String, grade: int, label: String) -> void:
	var event := _last_event()
	_expect(str(event.get("game_id", "")) == "tileclub", "%s_wrong_game" % kind)
	_expect(str(event.get("kind", "")) == kind, "%s_wrong_kind" % kind)
	_expect(int(event.get("grade", 0)) == grade, "%s_wrong_grade" % kind)
	_expect(str(event.get("label", "")) == label, "%s_wrong_label" % kind)
	_expect(str(event.get("font_role", "")) == "ui_cjk", "%s_wrong_font_role" % kind)


func _tap_first_tile(value: int) -> void:
	game.state["tiles"][0] = value
	game._tileclub_tap(game._tileclub_tile_center(0))


func _test_gag_runtime_assets() -> void:
	_expect(GAG_BADGE_ATLAS != null, "gag_atlas_missing")
	_expect(GAG_BADGE_ATLAS.get_size() == Vector2(500, 500), "gag_atlas_dimensions")
	_expect(GAG_BADGE_ATLAS.get_image().detect_alpha() != Image.ALPHA_NONE, "gag_atlas_alpha")
	_expect(FileAccess.get_sha256("res://assets/art/catalog/tile_games/gag/tileclub_badge_atlas_gag_v1.png") == ATLAS_SHA, "gag_atlas_hash")
	_expect(GAG_SHELL != null, "gag_shell_missing")
	_expect(GAG_SHELL.get_size() == Vector2(378, 377), "gag_shell_dimensions")
	_expect(GAG_SHELL.get_image().detect_alpha() != Image.ALPHA_NONE, "gag_shell_alpha")
	_expect(FileAccess.get_sha256("res://assets/art/catalog/tile_games/gag/tileclub_shell_badge_gag_v1.png") == SHELL_SHA, "gag_shell_hash")
	_expect(GAG_MATCH_SFX != null, "gag_sfx_missing")
	_expect(GAG_MATCH_SFX.get_length() >= 0.40 and GAG_MATCH_SFX.get_length() < 0.43, "gag_sfx_duration")
	_expect(FileAccess.get_sha256("res://assets/audio/catalog/tile_games/gag/fabric_triple_stitch_gag_v1.ogg") == AUDIO_SHA, "gag_sfx_hash")
	var regions: Array[Rect2] = []
	for value in [1, 2, 3, 4, 5, 7]:
		var region: Rect2 = game._tileclub_gag_badge_region(value)
		_expect(region.position.x >= 0 and region.position.y >= 0, "gag_region_origin_%d" % value)
		_expect(region.end.x <= 500 and region.end.y <= 500, "gag_region_bounds_%d" % value)
		_expect(region not in regions, "gag_region_duplicate_%d" % value)
		regions.append(region)


func _test_dynamic_font_role() -> void:
	for sample in REQUIRED_COPY:
		for index in range(sample.length()):
			var codepoint: int = sample.unicode_at(index)
			_expect(UI_FONT.has_char(codepoint), "font_U+%04X" % codepoint)


func _test_initial_contract() -> void:
	_open()
	var tiles: Array = game.state["tiles"]
	_expect(tiles.size() == 49, "initial_tile_count")
	var zero_count := 0
	for value in range(1, 8):
		var count := tiles.count(value)
		_expect(count > 0, "initial_missing_value_%d" % value)
		_expect(count % 3 == 0, "initial_non_triple_count_%d" % value)
	zero_count = tiles.count(0)
	_expect(zero_count == 1, "initial_open_slot_count")
	_expect(game.state["tray"].is_empty(), "initial_tray")
	_expect(int(game.state["score"]) == 0, "initial_score")
	_expect(int(game.state["moves"]) == 0, "initial_moves")
	_expect(str(game.state["status"]) == "playing", "initial_status")


func _test_inert_inputs() -> void:
	_open()
	var before: Dictionary = game.state.duplicate(true)
	game._tileclub_tap(Vector2(-100, -100))
	_expect(game.state == before, "outside_input_mutated_state")
	var empty_index: int = game.state["tiles"].find(0)
	before = game.state.duplicate(true)
	game._tileclub_tap(game._tileclub_tile_center(empty_index))
	_expect(game.state == before, "empty_tile_mutated_state")


func _test_collect() -> void:
	_open()
	_tap_first_tile(1)
	_expect(int(game.state["tiles"][0]) == 0, "collect_source_not_removed")
	_expect(game.state["tray"] == [1], "collect_tray")
	_expect(int(game.state["moves"]) == 1, "collect_moves")
	_expect(int(game.state["score"]) == 0, "collect_score")
	_expect(str(game.state["status"]) == "playing", "collect_status")
	_expect(str(game.tileclub_object_fx.get("kind", "")) == "collect", "collect_object_fx")
	_expect(int(game.tileclub_object_fx.get("grade", 0)) == 1, "collect_object_grade")
	_expect(int(game.motion_value) == 1, "collect_motion_value")
	_expect(game.motion_kind == "tile", "collect_motion_kind")
	_expect_event("stitch_collect", 1, "叶片入槽")


func _test_risk_hierarchy() -> void:
	_open()
	game.state["tray"] = [1, 2, 3, 4]
	_tap_first_tile(5)
	_expect(game.state["tray"].size() == 5, "risk2_tray")
	_expect(int(game.state["tiles"][0]) == 0, "risk2_source")
	_expect(int(game.state["moves"]) == 1, "risk2_moves")
	_expect(str(game.tileclub_object_fx.get("kind", "")) == "risk", "risk2_object_fx")
	_expect(int(game.tileclub_object_fx.get("grade", 0)) == 2, "risk2_object_grade")
	_expect_event("stitch_risk", 2, "槽位吃紧 · 余 2 格")
	_open()
	game.state["tray"] = [1, 2, 3, 4, 5]
	_tap_first_tile(6)
	_expect(game.state["tray"].size() == 6, "risk3_tray")
	_expect(int(game.state["tiles"][0]) == 0, "risk3_source")
	_expect(int(game.state["moves"]) == 1, "risk3_moves")
	_expect(str(game.tileclub_object_fx.get("kind", "")) == "risk", "risk3_object_fx")
	_expect(int(game.tileclub_object_fx.get("grade", 0)) == 3, "risk3_object_grade")
	_expect_event("stitch_risk", 3, "只余一格 · 谨慎落片")


func _test_match() -> void:
	_open()
	game.state["tray"] = [1, 1]
	_tap_first_tile(1)
	_expect(game.state["tray"].is_empty(), "match_tray")
	_expect(int(game.state["tiles"][0]) == 0, "match_source")
	_expect(int(game.state["score"]) == 100, "match_score")
	_expect(int(game.state["moves"]) == 1, "match_moves")
	_expect(str(game.state["status"]) == "playing", "match_status")
	_expect(str(game.tileclub_object_fx.get("kind", "")) == "match", "match_object_fx")
	_expect(int(game.tileclub_object_fx.get("grade", 0)) == 3, "match_object_grade")
	_expect(game.tileclub_object_fx.get("positions", []).size() == 3, "match_ghost_count")
	_expect_event("stitch_match", 3, "三枚缝合 · +100")
	_expect(_last_sfx() == GAG_MATCH_SFX, "match_gag_sfx_not_routed")


func _test_full_tray() -> void:
	_open()
	game.state["tray"] = [1, 2, 3, 4, 5, 6]
	_tap_first_tile(7)
	_expect(str(game.state["status"]) == "over", "full_status")
	_expect(game.state["tray"] == [1, 2, 3, 4, 5, 6, 7], "full_tray")
	_expect(int(game.state["tiles"][0]) == 0, "full_source")
	_expect(int(game.state["score"]) == 0, "full_score")
	_expect(int(game.state["moves"]) == 1, "full_moves")
	_expect(str(game.tileclub_object_fx.get("kind", "")) == "full", "full_object_fx")
	_expect(int(game.tileclub_object_fx.get("grade", 0)) == 4, "full_object_grade")
	_expect_event("stitch_tray_full", 4, "槽位绷满 · 本局结束")


func _test_clear_match() -> void:
	_open()
	var tiles: Array = []
	for _index in range(49):
		tiles.append(0)
	tiles[0] = 1
	game.state["tiles"] = tiles
	game.state["tray"] = [1, 1]
	game._tileclub_tap(game._tileclub_tile_center(0))
	_expect(str(game.state["status"]) == "won", "clear_match_status")
	_expect(game.state["tray"].is_empty(), "clear_match_tray")
	_expect(int(game.state["score"]) == 100, "clear_match_score")
	_expect(int(game.state["moves"]) == 1, "clear_match_moves")
	_expect(str(game.tileclub_object_fx.get("kind", "")) == "clear", "clear_match_object_fx")
	_expect(int(game.tileclub_object_fx.get("grade", 0)) == 4, "clear_match_object_grade")
	_expect_event("stitch_match", 4, "织毯完成 · 清盘")
	_expect(_last_sfx() == GAG_MATCH_SFX, "clear_match_gag_sfx_not_routed")


func _test_clear_without_match() -> void:
	_open()
	var tiles: Array = []
	for _index in range(49):
		tiles.append(0)
	tiles[0] = 2
	game.state["tiles"] = tiles
	game.state["tray"] = []
	game._tileclub_tap(game._tileclub_tile_center(0))
	_expect(str(game.state["status"]) == "won", "clear_collect_status")
	_expect(game.state["tray"] == [2], "clear_collect_tray")
	_expect(int(game.state["score"]) == 0, "clear_collect_score")
	_expect(int(game.state["moves"]) == 1, "clear_collect_moves")
	_expect(str(game.tileclub_object_fx.get("kind", "")) == "clear", "clear_collect_object_fx")
	_expect_event("stitch_clear", 4, "织毯完成 · 清盘")
	_expect(_last_sfx() == GAG_MATCH_SFX, "clear_collect_gag_sfx_not_routed")
