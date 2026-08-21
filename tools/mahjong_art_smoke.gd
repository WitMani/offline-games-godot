extends SceneTree

const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const GAG_TILE: Texture2D = preload("res://assets/art/catalog/tile_games/gag/mahjong_tile_blank_gag_v1.png")
const GAG_PAIR_SFX: AudioStream = preload("res://assets/audio/catalog/tile_games/gag/jade_pair_resonance_gag_v1.ogg")
const REQUIRED_COPY := [
	"静心牌阵", "自由牌配对", "亮牌可选", "暗牌仍被遮挡",
	"方向键移动", "回车配对", "提示", "洗牌", "撤销", "低动态",
	"玉牌抬起", "牌面受阻", "纹样不同", "可配一对", "玉牌归位",
	"牌路重开", "暂无可配 · 请洗牌", "同纹共鸣 · +50",
	"牌阵将清 · +50", "牌阵清空 · 玉成", "玉阵完成",
	"点击右上角“重开”继续挑战", "东南西北中发白一二三万",
]
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
	game._clear_mahjong_session()
	_test_gag_runtime_assets()
	_test_dynamic_font_role()
	_test_ordinary_stable_contract()
	_test_select_deselect_and_blocked()
	_test_mismatch()
	_test_routine_pair()
	_test_tools_and_deadlock()
	_test_near_clear()
	_test_final_clear()
	_test_reduced_effects_contract()
	_test_effect_cap()
	game._clear_mahjong_session()
	print("MAHJONG_ART_ASSERTIONS=%d" % assertions)
	print("MAHJONG_ART_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func _open() -> void:
	game._open_game("mahjong")
	game.has_transitioned = false
	game.catalog_fx.clear()


func _last_event() -> Dictionary:
	return {} if game.catalog_fx.is_empty() else game.catalog_fx.back()


func _expect_event(kind: String, grade: int, label: String, suffix: String) -> void:
	var event := _last_event()
	_expect(str(event.get("game_id", "")) == "mahjong", "%s_wrong_game" % suffix)
	_expect(str(event.get("kind", "")) == kind, "%s_wrong_kind" % suffix)
	_expect(int(event.get("grade", 0)) == grade, "%s_wrong_grade" % suffix)
	_expect(str(event.get("label", "")) == label, "%s_wrong_label" % suffix)
	_expect(str(event.get("font_role", "")) == "ui_cjk", "%s_wrong_font_role" % suffix)


func _last_sfx() -> AudioStream:
	var player_index := posmod(game.sfx_cursor - 1, game.sfx_players.size())
	return game.sfx_players[player_index].stream


func _pair() -> Array[int]:
	var pairs: Array = game.mahjong_model.available_pairs()
	if pairs.is_empty():
		return []
	return [int(pairs[0][0]), int(pairs[0][1])]


func _match_pair(pair: Array[int], route := "art_smoke") -> void:
	game._mahjong_resolve_index(pair[0], route)
	game._mahjong_resolve_index(pair[1], route)


func _solve_until_remaining(target: int) -> bool:
	var guard := 0
	while game.mahjong_model.remaining_count() > target and guard < 20:
		var pair := _pair()
		if pair.size() != 2:
			return false
		_match_pair(pair, "art_solve")
		guard += 1
	return game.mahjong_model.remaining_count() == target


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


func _test_ordinary_stable_contract() -> void:
	_open()
	_expect(game.state["mahjong_schema"] == 3, "stable_schema")
	_expect(game.state["tiles"].size() == 36, "stable_tile_count")
	_expect(int(game.state["remaining"]) == 36, "stable_remaining")
	_expect(game.mahjong_model.pair_multiset_is_valid(), "stable_pair_multiset")
	_expect(game._mahjong_draw_order().size() == 36, "stable_all_tiles_drawn")
	_expect(game.mahjong_model.free_indices().size() > 0, "stable_free_tiles")
	_expect(game.mahjong_model.free_indices().size() < 36, "stable_blocked_tiles")
	_expect(game.MAHJONG_GAG_TILE_TEXTURE == GAG_TILE, "stable_gag_runtime_binding")
	_expect(game.state["removed"].is_empty(), "stable_no_removed")
	_expect(int(game.state["selected"]) == -1, "stable_no_selection")
	_expect(str(game.state["status"]) == "playing", "stable_status")


func _test_select_deselect_and_blocked() -> void:
	_open()
	var pair := _pair()
	var first := pair[0]
	var before: Dictionary = game.state.duplicate(true)
	game._mahjong_resolve_index(first, "pointer")
	_expect(int(game.state["selected"]) == first, "select_authority")
	_expect(game.state["removed"] == before["removed"], "select_no_removal")
	_expect(str(game.mahjong_object_fx.get("kind", "")) == "select", "select_object_fx")
	_expect(game.mahjong_object_fx.get("indices", []) == [first], "select_object_index")
	_expect_event("jade_select", 1, "玉牌抬起", "select")
	game._mahjong_resolve_index(first, "pointer")
	_expect(int(game.state["selected"]) == -1, "deselect_authority")
	_expect(str(game.mahjong_object_fx.get("kind", "")) == "deselect", "deselect_object_fx")
	var blocked := -1
	for index in range(game.mahjong_model.tile_count()):
		if game.mahjong_model.is_active(index) and not game.mahjong_model.is_free(index):
			blocked = index
			break
	_expect(blocked >= 0, "blocked_fixture")
	before = game.state.duplicate(true)
	game._mahjong_resolve_index(blocked, "pointer")
	_expect(game.state["removed"] == before["removed"], "blocked_no_removal")
	_expect(int(game.state["selected"]) == int(before["selected"]), "blocked_no_selection_mutation")
	_expect(int(game.state["blocked_attempts"]) == int(before["blocked_attempts"]) + 1, "blocked_counter")
	_expect(str(game.mahjong_object_fx.get("kind", "")) == "blocked", "blocked_object_fx")
	_expect_event("jade_blocked_reject", 1, "牌面受阻", "blocked")


func _test_mismatch() -> void:
	_open()
	var free: Array[int] = game.mahjong_model.free_indices()
	var mismatch: Array[int] = []
	for left_offset in range(free.size()):
		for right_offset in range(left_offset + 1, free.size()):
			var left := int(free[left_offset])
			var right := int(free[right_offset])
			if int(game.mahjong_model.tiles[left]["face"]) != int(game.mahjong_model.tiles[right]["face"]):
				mismatch = [left, right]
				break
		if not mismatch.is_empty():
			break
	_expect(mismatch.size() == 2, "mismatch_fixture")
	game._mahjong_resolve_index(mismatch[0], "pointer")
	game._mahjong_resolve_index(mismatch[1], "pointer")
	_expect(int(game.state["selected"]) == mismatch[1], "mismatch_next_selection")
	_expect(int(game.state["mistakes"]) == 1, "mismatch_counter")
	_expect(game.state["removed"].is_empty(), "mismatch_no_removal")
	_expect(str(game.mahjong_object_fx.get("kind", "")) == "mismatch", "mismatch_object_fx")
	_expect(game.mahjong_object_fx.get("indices", []) == mismatch, "mismatch_object_indices")
	_expect_event("jade_mismatch", 1, "纹样不同", "mismatch")


func _test_routine_pair() -> void:
	_open()
	var pair := _pair()
	_match_pair(pair)
	_expect(game.state["removed"] == pair, "pair_removed")
	_expect(int(game.state["remaining"]) == 34, "pair_remaining")
	_expect(int(game.state["score"]) == 50, "pair_score")
	_expect(int(game.state["moves"]) == 1, "pair_moves")
	_expect(str(game.mahjong_object_fx.get("kind", "")) == "pair", "pair_object_fx")
	_expect(int(game.mahjong_object_fx.get("grade", 0)) == 2, "pair_object_grade")
	_expect(game.mahjong_object_fx.get("indices", []) == pair, "pair_object_indices")
	_expect_event("jade_pair", 2, "同纹共鸣 · +50", "pair")
	_expect(_last_sfx() == GAG_PAIR_SFX, "pair_gag_sfx_routing")


func _test_tools_and_deadlock() -> void:
	_open()
	game._mahjong_hint()
	_expect(game.state["hint_pair"].size() == 2, "hint_authority")
	_expect(str(game.mahjong_object_fx.get("kind", "")) == "hint", "hint_object_fx")
	_expect_event("jade_hint", 1, "可配一对", "hint")
	var before_faces: Array[int] = []
	for tile_data in game.mahjong_model.tiles:
		before_faces.append(int(tile_data["face"]))
	before_faces.sort()
	game._mahjong_shuffle()
	var after_faces: Array[int] = []
	for tile_data in game.mahjong_model.tiles:
		after_faces.append(int(tile_data["face"]))
	after_faces.sort()
	_expect(before_faces == after_faces, "shuffle_multiset")
	_expect(game.mahjong_model.available_pairs().size() > 0, "shuffle_guaranteed_pair")
	_expect(str(game.mahjong_object_fx.get("kind", "")) == "shuffle", "shuffle_object_fx")
	_expect_event("jade_shuffle", 3, "牌路重开", "shuffle")
	var pair := _pair()
	_match_pair(pair)
	game._mahjong_undo()
	_expect(game.state["removed"].is_empty(), "undo_restores_pair")
	_expect(int(game.state["moves"]) == 0 and int(game.state["score"]) == 0, "undo_restores_counters")
	_expect(str(game.mahjong_object_fx.get("kind", "")) == "undo", "undo_object_fx")
	_expect_event("jade_undo", 2, "玉牌归位", "undo")
	# Presentation-only deadlock fixture: give every currently free position a
	# unique face so request_hint has no legal pair. Model validity is covered by
	# mahjong_model_smoke; this fixture only exercises semantic routing.
	_open()
	var free: Array[int] = game.mahjong_model.free_indices()
	for offset in range(free.size()):
		game.mahjong_model.tiles[free[offset]]["face"] = 1 + offset
	_expect(game.mahjong_model.refresh_status_for_test() == "stuck", "deadlock_fixture")
	game._sync_mahjong_state(false)
	game._mahjong_hint()
	_expect(str(game.state["status"]) == "stuck", "deadlock_authority")
	_expect_event("jade_deadlock_reject", 3, "暂无可配 · 请洗牌", "deadlock")


func _test_near_clear() -> void:
	_open()
	_expect(_solve_until_remaining(6), "near_fixture_solvable")
	var pair := _pair()
	_match_pair(pair, "near")
	_expect(int(game.state["remaining"]) == 4, "near_remaining")
	_expect(str(game.mahjong_object_fx.get("kind", "")) == "near", "near_object_fx")
	_expect(int(game.mahjong_object_fx.get("grade", 0)) == 3, "near_object_grade")
	_expect_event("jade_pair", 3, "牌阵将清 · +50", "near")
	_expect(_last_sfx() == GAG_PAIR_SFX, "near_gag_sfx_routing")


func _test_final_clear() -> void:
	_open()
	_expect(_solve_until_remaining(2), "final_fixture_solvable")
	var pair := _pair()
	_match_pair(pair, "final")
	_expect(str(game.state["status"]) == "won", "final_status")
	_expect(int(game.state["remaining"]) == 0, "final_remaining")
	_expect(int(game.state["moves"]) == 18 and int(game.state["score"]) == 900, "final_counters")
	_expect(str(game.mahjong_object_fx.get("kind", "")) == "clear", "final_object_fx")
	_expect(int(game.mahjong_object_fx.get("grade", 0)) == 4, "final_object_grade")
	_expect_event("jade_pair", 4, "牌阵清空 · 玉成", "final")
	_expect(_last_sfx() == GAG_PAIR_SFX, "final_gag_sfx_routing")
	_expect(not game._catalog_result_overlay_ready(), "final_result_delayed_for_object_read")
	var event: Dictionary = _last_event()
	game.elapsed = float(event["started"]) + 0.83
	_expect(game._catalog_result_overlay_ready(), "final_result_enters_after_settle")


func _test_reduced_effects_contract() -> void:
	_open()
	game._toggle_mahjong_reduced()
	_expect(bool(game.state["reduced_effects"]), "reduced_state")
	var dispatch_before: int = game.haptic_dispatch_count
	game._start_catalog_event("jade_pair", Vector2(270, 458), Color.WHITE, 4, "低动态测试", 1.0)
	game._haptic(20)
	var reduced_pattern: Array[int] = [10, 10, 10]
	game._haptic_pattern(reduced_pattern)
	_expect(game.haptic_dispatch_count == dispatch_before, "reduced_haptic_suppressed")
	_expect(game._catalog_shake_offset() == Vector2.ZERO, "reduced_camera_shake_suppressed")
	var pair := _pair()
	_match_pair(pair, "reduced")
	_expect(int(game.state["remaining"]) == 34, "reduced_authoritative_removal")
	_expect(str(game.mahjong_object_fx.get("kind", "")) == "pair", "reduced_pair_semantic")
	_expect(bool(game.state["reduced_effects"]), "reduced_persists_through_pair")
	game._toggle_mahjong_reduced()
	_expect(not bool(game.state["reduced_effects"]), "reduced_toggle_off")


func _test_effect_cap() -> void:
	_open()
	for index in range(9):
		game._start_catalog_event("jade_hint", Vector2(100 + index, 400), Color.WHITE, 1, "可配一对", 2.0)
	_expect(game.catalog_fx.size() == 6, "mahjong_effect_cap")
	for event in game.catalog_fx:
		_expect(str(event.get("font_role", "")) == "ui_cjk", "effect_cap_cjk_role")
