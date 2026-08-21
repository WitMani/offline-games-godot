extends SceneTree

const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const GAG_BADGE_ATLAS: Texture2D = preload("res://assets/art/catalog/tile_games/gag/tileclub_badge_atlas_gag_v1.png")
const GAG_SHELL: Texture2D = preload("res://assets/art/catalog/tile_games/gag/tileclub_shell_badge_gag_v1.png")
const GAG_MATCH_SFX: AudioStream = preload("res://assets/audio/catalog/tile_games/gag/fabric_triple_stitch_gag_v1.ogg")
const ATLAS_SHA := "7c34fff62346dce7ff0b9df3a49e8fad90bd06793c7223d81824b151b64d3002"
const SHELL_SHA := "08072a34d1170ecc0e6ccca9849436e98e881195d85b78495e923cbc5241da83"
const AUDIO_SHA := "66b4020ee32846cdfa86268b6de5136e47ded36823b1f9cb915d59296c29a8e3"
const REQUIRED_COPY := [
	"玩具俱乐部", "移开上层并收集三枚同图案", "剩余 21 枚 · 可选 7 枚",
	"被上层遮住", "上层方块尚未移开", "叶片入槽", "三枚缝合 · +100",
	"上层清开 · 新方块露出", "槽位吃紧 · 余 2 格", "只余一格 · 谨慎落片",
	"槽位绷满 · 本局结束", "织毯完成 · 清盘",
	"先移开上层 · 集齐三枚消除 · 七格满则结束",
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
	_test_stable_signature()
	_test_blocked_and_collect()
	_test_match()
	_test_layer_clear()
	_test_risk_hierarchy_and_full()
	_test_completion()
	_test_reduced_effects_contract()
	_test_restart_clears_transients()
	game._clear_tileclub_checkpoint()
	print("TILECLUB_ART_SMOKE=%d" % assertions)
	print("TILECLUB_ART_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func _open(level := 0) -> void:
	game._clear_tileclub_checkpoint()
	game._open_game("tileclub")
	if level != 0:
		game.tileclub_level_index = level
		game._start_game_state()
	game.has_transitioned = false
	game.catalog_fx.clear()


func _collect(ids: Array) -> void:
	for tile_id in ids:
		game._tileclub_collect_id(int(tile_id))


func _last_event() -> Dictionary:
	return {} if game.catalog_fx.is_empty() else game.catalog_fx.back()


func _last_sfx() -> AudioStream:
	var player_index := posmod(game.sfx_cursor - 1, game.sfx_players.size())
	return game.sfx_players[player_index].stream


func _expect_event(semantic: String, kind: String, grade: int, label: String) -> void:
	var event := _last_event()
	_expect(str(event.get("game_id", "")) == "tileclub", "%s_wrong_game" % semantic)
	_expect(str(event.get("semantic", "")) == semantic, "%s_wrong_semantic" % semantic)
	_expect(str(event.get("kind", "")) == kind, "%s_wrong_kind" % semantic)
	_expect(int(event.get("grade", 0)) == grade, "%s_wrong_grade" % semantic)
	_expect(str(event.get("label", "")) == label, "%s_wrong_label" % semantic)
	_expect(str(event.get("font_role", "")) == "ui_cjk", "%s_wrong_font_role" % semantic)


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


func _test_stable_signature() -> void:
	for level in range(3):
		_open(level)
		var expected_active: int = [12, 18, 21][level]
		var expected_selectable: int = [4, 6, 7][level]
		var presentation: Dictionary = game._tileclub_presentation_state()
		_expect(int(game.state["active_count"]) == expected_active, "level_%d_active" % level)
		_expect(game.state["selectable_ids"].size() == expected_selectable, "level_%d_selectable" % level)
		_expect(str(presentation.get("direction", "")) == "layered-keepsake-club-gag-v3", "level_%d_direction" % level)
		_expect(bool(presentation.get("signature_visible", false)), "level_%d_signature_hidden" % level)
		_expect(int(presentation.get("board_badge_instances", -1)) == expected_active, "level_%d_board_signature_count" % level)
		_expect(int(presentation.get("stable_visible_instances", -1)) == expected_active, "level_%d_total_signature_count" % level)
		_expect(presentation.get("gag_runtime_assets", []).size() == 3, "level_%d_gag_roles" % level)
	_open(2)
	var active_values: Array[int] = []
	for tile in game.state["tiles"]:
		if bool(tile["active"]) and int(tile["value"]) not in active_values:
			active_values.append(int(tile["value"]))
	active_values.sort()
	_expect(active_values == [1, 2, 3, 4, 5, 6, 7], "stable_family_not_complete")


func _test_blocked_and_collect() -> void:
	_open()
	game._tileclub_collect_id(0)
	_expect_event("tileclub_blocked", "stitch_blocked", 1, "被上层遮住")
	_expect(not bool(game.tileclub_last_outcome.get("changed", true)), "blocked_mutated")
	_expect(str(game.tileclub_object_fx.get("kind", "")) == "blocked", "blocked_object_fx")
	game.catalog_fx.clear()
	game._tileclub_collect_id(2)
	_expect_event("tileclub_collect", "stitch_collect", 1, "叶片入槽")
	_expect(game.state["tray"] == [1], "collect_tray")
	_expect(int(game.state["active_count"]) == 11, "collect_active_count")
	_expect(str(game.tileclub_object_fx.get("kind", "")) == "collect", "collect_object_fx")
	_expect(game.motion_kind == "tile" and game.motion_duration > 0.0, "collect_motion")
	var presentation: Dictionary = game._tileclub_presentation_state()
	_expect(int(presentation["board_badge_instances"]) == 11, "collect_board_signature")
	_expect(int(presentation["tray_badge_instances"]) == 1, "collect_tray_signature")
	_expect(int(presentation["stable_visible_instances"]) == 12, "collect_total_signature")


func _test_match() -> void:
	_open(2)
	_collect([2, 0, 5, 8, 11, 14])
	game._tileclub_collect_id(1)
	_expect_event("tileclub_match", "stitch_match", 2, "三枚缝合 · +100")
	_expect(game.state["tray"] == [2, 3, 4, 5], "match_compaction")
	_expect(int(game.state["score"]) == 100, "match_score")
	_expect(str(game.tileclub_object_fx.get("kind", "")) == "match", "match_object_fx")
	_expect(int(game.tileclub_object_fx.get("grade", 0)) == 2, "match_object_grade")
	_expect(game.tileclub_object_fx.get("positions", []).size() == 3, "match_ghost_count")
	_expect(_last_sfx() == GAG_MATCH_SFX, "match_gag_sfx_not_routed")


func _test_layer_clear() -> void:
	_open()
	_collect([2, 0, 1, 5, 3, 4, 8, 6, 7, 11])
	_expect_event("tileclub_layer_clear", "stitch_layer_clear", 3, "上层清开")
	_expect(game.tileclub_last_outcome.get("cleared_layers", []) == [1], "layer_clear_payload")
	_expect(str(game.tileclub_object_fx.get("kind", "")) == "layer", "layer_object_fx")
	_expect(int(game.tileclub_object_fx.get("grade", 0)) == 3, "layer_object_grade")


func _test_risk_hierarchy_and_full() -> void:
	_open(2)
	_collect([2, 5, 8, 11, 14])
	_expect_event("tileclub_near_full", "stitch_risk", 2, "槽位吃紧 · 余 2 格")
	_expect(int(_last_event().get("remaining_slots", -1)) == 2, "risk5_remaining")
	_expect(int(game.tileclub_object_fx.get("grade", 0)) == 2, "risk5_object_grade")
	game._tileclub_collect_id(17)
	_expect_event("tileclub_near_full", "stitch_risk", 3, "只余一格 · 谨慎落片")
	_expect(int(_last_event().get("remaining_slots", -1)) == 1, "risk6_remaining")
	_expect(int(game.tileclub_object_fx.get("grade", 0)) == 3, "risk6_object_grade")
	game._tileclub_collect_id(20)
	_expect_event("tileclub_full", "stitch_tray_full", 4, "槽位绷满 · 本局结束")
	_expect(str(game.state["status"]) == "over", "full_status")
	_expect(game.state["tray"].size() == 7, "full_tray")
	_expect(str(game.tileclub_object_fx.get("kind", "")) == "full", "full_object_fx")


func _test_completion() -> void:
	_open()
	_collect(game.tileclub_model.solution_for_level())
	_expect_event("tileclub_complete", "stitch_match", 4, "织毯完成 · 清盘")
	_expect(str(game.state["status"]) == "won", "complete_status")
	_expect(game.state["tray"].is_empty() and int(game.state["active_count"]) == 0, "complete_empty")
	_expect(str(game.tileclub_object_fx.get("kind", "")) == "clear", "complete_object_fx")
	_expect(_last_sfx() == GAG_MATCH_SFX, "complete_gag_sfx_not_routed")


func _test_reduced_effects_contract() -> void:
	game._set_tileclub_reduced_effects(false)
	game.tileclub_haptic_emitted_count = 0
	game.tileclub_haptic_suppressed_count = 0
	_open()
	game._tileclub_collect_id(2)
	var normal_state: Dictionary = game.state.duplicate(true)
	_expect(game.tileclub_haptic_emitted_count > 0, "normal_haptic_not_emitted")
	_expect(game.motion_duration > 0.0 and game.impact_strength > 0.0, "normal_motion_missing")

	game._set_tileclub_reduced_effects(true)
	_open()
	game._tileclub_collect_id(2)
	_expect(game.state == normal_state, "reduced_changed_authoritative_state")
	_expect(game.motion_duration == 0.0, "reduced_motion_not_suppressed")
	_expect(game.impact_strength == 0.0 and game.impact_until <= game.elapsed, "reduced_impact_not_suppressed")
	_expect(game._catalog_shake_offset() == Vector2.ZERO, "reduced_shake_not_suppressed")
	_expect(game.tileclub_object_fx.is_empty(), "reduced_object_motion_not_suppressed")
	_expect(game.tileclub_haptic_suppressed_count > 0, "reduced_haptic_not_suppressed")
	_expect_event("tileclub_collect", "stitch_collect", 1, "叶片入槽")
	_expect(bool(_last_event().get("reduced_effects", false)), "reduced_event_not_marked")
	var reduced_presentation: Dictionary = game._tileclub_presentation_state()
	_expect(bool(reduced_presentation.get("reduced_effects", false)), "reduced_presentation_not_marked")
	_expect(int(reduced_presentation.get("stable_visible_instances", -1)) == 12, "reduced_signature_missing")
	_expect(str(reduced_presentation.get("latest_event", {}).get("semantic", "")) == "tileclub_collect", "reduced_semantic_missing")
	game._set_tileclub_reduced_effects(false)


func _test_restart_clears_transients() -> void:
	_open()
	game._tileclub_collect_id(2)
	_expect(not game.catalog_fx.is_empty() and not game.tileclub_object_fx.is_empty(), "restart_setup_feedback")
	game._reset_current()
	_expect(game.catalog_fx.is_empty(), "restart_catalog_feedback_clear")
	_expect(game.tileclub_object_fx.is_empty() and game.tileclub_last_outcome.is_empty(), "restart_object_feedback_clear")
	_expect(game.state["tray"].is_empty() and int(game.state["moves"]) == 0, "restart_state_clean")
