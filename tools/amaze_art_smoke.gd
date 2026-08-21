extends SceneTree

const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const GAG_PAINT_POD: Texture2D = preload("res://assets/art/catalog/path_games/gag/amaze_paint_pod_gag_v2.png")
const GAG_WET_ROLL: AudioStream = preload("res://assets/audio/catalog/path_games/gag/amaze_wet_corridor_roll_gag_v2.ogg")
const PAINT_POD_SHA := "c071616ed85c15c394f644b90329bdd8c4c302ede5ec4c378aa19ae17872ee36"
const WET_ROLL_SHA := "fe90d0137f851fe2da8614f2d362bda298acfc5f18a82f479338094306bc6330"
const LEVEL_THREE_SOLUTION := [
	Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN,
	Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP, Vector2i.RIGHT,
	Vector2i.DOWN, Vector2i.LEFT,
]
const REQUIRED_COPY := [
	"彩漆工坊", "滑动到底 · 让轨道吸满颜色", "滚动颜料舱，经过的每格都会依次吸满彩漆",
	"前方受阻", "长廊涂色", "短廊涂色", "重访通道", "只差 1 格", "全域完成",
	"彩漆封版", "第 3 关 · 10 步 · 轨道全满", "点击下方“下一迷宫”继续",
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
	_test_stable_signature_contract()
	_test_blocked_object_response()
	_test_ordered_long_roll_response()
	_test_intensity_hierarchy()
	_test_effects_disabled_fallback()
	_test_reduced_effects_and_haptic_suppression()
	_test_restart_and_path_game_isolation()
	print("AMAZE_ART_SMOKE=%d" % assertions)
	print("AMAZE_ART_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)


func _open_level(level: int) -> void:
	game._clear_amaze_checkpoint()
	game._open_game("amaze")
	game.amaze_level_index = level
	game._start_game_state()
	game._build_game_buttons()
	game.has_transitioned = false
	game.catalog_fx.clear()
	game.motion_started = -10.0
	game.feedback_until = -10.0


func _last_event() -> Dictionary:
	return {} if game.catalog_fx.is_empty() else game.catalog_fx.back()


func _last_sfx() -> AudioStream:
	var player_index := posmod(game.sfx_cursor - 1, game.sfx_players.size())
	return game.sfx_players[player_index].stream


func _test_gag_runtime_assets() -> void:
	_expect(GAG_PAINT_POD != null, "gag_paint_pod_missing")
	_expect(GAG_PAINT_POD.get_size() == Vector2(324, 354), "gag_paint_pod_dimensions")
	_expect(GAG_PAINT_POD.get_image().detect_alpha() != Image.ALPHA_NONE, "gag_paint_pod_alpha")
	_expect(FileAccess.get_sha256("res://assets/art/catalog/path_games/gag/amaze_paint_pod_gag_v2.png") == PAINT_POD_SHA, "gag_paint_pod_hash")
	_expect(GAG_WET_ROLL != null, "gag_wet_roll_missing")
	_expect(GAG_WET_ROLL.get_length() >= 0.44 and GAG_WET_ROLL.get_length() < 0.46, "gag_wet_roll_duration")
	_expect(FileAccess.get_sha256("res://assets/audio/catalog/path_games/gag/amaze_wet_corridor_roll_gag_v2.ogg") == WET_ROLL_SHA, "gag_wet_roll_hash")


func _test_dynamic_font_role() -> void:
	for sample in REQUIRED_COPY:
		for index in range(sample.length()):
			var codepoint: int = sample.unicode_at(index)
			_expect(UI_FONT.has_char(codepoint), "font_U+%04X" % codepoint)


func _test_stable_signature_contract() -> void:
	_open_level(0)
	_expect(game.AMAZE_GAG_PAINT_POD_TEXTURE == GAG_PAINT_POD, "paint_pod_runtime_binding")
	_expect(game.SFX_AMAZE_GAG_WET_ROLL == GAG_WET_ROLL, "wet_roll_runtime_binding")
	_expect(game.amaze_object_fx.is_empty(), "initial_object_fx")
	_expect(not game._amaze_motion_active(), "initial_motion_active")
	_expect(game.state["player"] == [0, 4], "initial_player")
	_expect(game._amaze_cell_center(0, 4).is_equal_approx(Vector2(97, 623)), "initial_signature_position")
	_expect(game._amaze_visual_cell_painted(0, 4), "start_not_visibly_painted")
	_expect(not game._amaze_visual_cell_painted(0, 3), "unpainted_cell_visibly_painted")
	var palette: Dictionary = game._amaze_paint_palette()
	_expect(palette.has("paint") and palette.has("secondary"), "paint_palette_roles")


func _test_blocked_object_response() -> void:
	_open_level(0)
	var before := JSON.stringify(game.state)
	game._amaze_step(Vector2i.LEFT)
	_expect(JSON.stringify(game.state) == before, "blocked_mutated_model")
	_expect(str(game.amaze_object_fx.get("kind", "")) == "wall_reject", "blocked_object_kind")
	_expect(str(game.amaze_object_fx.get("semantic", "")) == "amaze_blocked", "blocked_object_semantic")
	_expect(int(game.amaze_object_fx.get("grade", 0)) == 1, "blocked_object_grade")
	_expect(game.amaze_object_fx.get("direction") == Vector2i.LEFT, "blocked_direction")
	var started := float(game.amaze_object_fx["started"])
	var duration := float(game.amaze_object_fx["duration"])
	_expect(game._amaze_event_phase(game.amaze_object_fx, started + duration * 0.05) == "intent", "blocked_intent_phase")
	_expect(game._amaze_event_phase(game.amaze_object_fx, started + duration * 0.28) == "anticipation", "blocked_anticipation_phase")
	_expect(game._amaze_event_phase(game.amaze_object_fx, started + duration * 0.60) == "impact", "blocked_impact_phase")
	_expect(game._amaze_event_phase(game.amaze_object_fx, started + duration * 0.90) == "settle", "blocked_settle_phase")
	_expect(str(_last_event().get("font_role", "")) == "ui_cjk", "blocked_font_role")
	_expect(_last_sfx() != GAG_WET_ROLL, "blocked_used_success_audio")


func _test_ordered_long_roll_response() -> void:
	_open_level(2)
	game._amaze_step(Vector2i.RIGHT)
	var event := _last_event()
	_expect(str(event.get("semantic", "")) == "amaze_long_roll", "long_semantic")
	_expect(int(event.get("grade", 0)) == 2, "long_grade")
	_expect(event.get("traversed") == [[1, 6], [2, 6], [3, 6], [4, 6]], "long_traversal_order")
	_expect(game.amaze_object_fx.get("newly_painted") == event.get("newly_painted"), "object_event_order_parity")
	_expect(_last_sfx() == GAG_WET_ROLL, "long_gag_audio_not_routed")
	game.elapsed = game.motion_started + game.motion_duration * 0.30
	_expect(game._amaze_motion_active(), "long_motion_not_active")
	_expect(game._amaze_visual_cell_painted(1, 6), "first_cell_not_revealed")
	_expect(not game._amaze_visual_cell_painted(2, 6), "later_cell_revealed_out_of_order")
	game.elapsed = game.motion_started + game.motion_duration * 0.80
	_expect(game._amaze_visual_cell_painted(3, 6), "third_cell_not_revealed")
	_expect(not game._amaze_visual_cell_painted(4, 6), "last_cell_revealed_out_of_order")


func _test_intensity_hierarchy() -> void:
	_open_level(2)
	game._amaze_step(Vector2i.RIGHT)
	var long_event := _last_event().duplicate(true)
	game.catalog_fx.clear()
	game.motion_started = -10.0
	game._amaze_step(Vector2i.LEFT)
	var revisit := _last_event().duplicate(true)
	_expect(str(revisit.get("semantic", "")) == "amaze_revisit" and int(revisit.get("grade", 0)) == 1, "revisit_grade")
	_expect(int(long_event.get("grade", 0)) == 2, "long_hierarchy_grade")
	_open_level(2)
	for index in range(LEVEL_THREE_SOLUTION.size() - 1):
		game._amaze_step(LEVEL_THREE_SOLUTION[index])
		if index < LEVEL_THREE_SOLUTION.size() - 2:
			game.catalog_fx.clear()
			game.motion_started = -10.0
	var near := _last_event().duplicate(true)
	_expect(str(near.get("semantic", "")) == "amaze_near_complete" and int(near.get("grade", 0)) == 3, "near_grade")
	game.catalog_fx.clear()
	game.motion_started = -10.0
	game._amaze_step(LEVEL_THREE_SOLUTION.back())
	var complete := _last_event()
	_expect(str(complete.get("semantic", "")) == "amaze_complete" and int(complete.get("grade", 0)) == 4, "complete_grade")
	_expect([int(revisit["grade"]), int(long_event["grade"]), int(near["grade"]), int(complete["grade"])] == [1, 2, 3, 4], "intensity_order")
	_expect(_last_sfx() == GAG_WET_ROLL, "complete_gag_audio_not_routed")
	_expect(str(complete.get("font_role", "")) == "ui_cjk", "complete_font_role")


func _test_effects_disabled_fallback() -> void:
	_open_level(2)
	game._amaze_step(Vector2i.RIGHT)
	var authoritative: Dictionary = game.state.duplicate(true)
	game.catalog_fx.clear()
	game.amaze_object_fx = {}
	game.motion_started = -10.0
	game.motion_duration = 0.0
	game.impact_until = -10.0
	_expect(game.state == authoritative, "effects_fallback_mutated_state")
	_expect(game.state["player"] == [4, 6], "effects_fallback_player")
	_expect(int(game.state["painted_count"]) == 5, "effects_fallback_progress")
	for cell in [[0, 6], [1, 6], [2, 6], [3, 6], [4, 6]]:
		_expect(game._amaze_visual_cell_painted(int(cell[0]), int(cell[1])), "effects_fallback_cell_%s" % str(cell))
	_expect(not game._amaze_motion_active(), "effects_fallback_motion")


func _test_reduced_effects_and_haptic_suppression() -> void:
	_open_level(2)
	game._set_reduced_effects(true)
	var emitted_before: int = game.haptic_emitted_count
	var suppressed_before: int = game.haptic_suppressed_count
	game._amaze_step(Vector2i.RIGHT)
	var event := _last_event()
	_expect(game.reduced_effects, "reduced_mode_not_enabled")
	_expect(bool(event.get("reduced_effects", false)), "reduced_event_not_marked")
	_expect(game.motion_duration == 0.0 and not game._amaze_motion_active(), "reduced_motion_not_suppressed")
	_expect(game._catalog_shake_offset() == Vector2.ZERO, "reduced_shake_not_suppressed")
	_expect(game._amaze_settle_scale() == Vector2.ONE, "reduced_property_motion_not_suppressed")
	_expect(game.haptic_emitted_count == emitted_before, "reduced_haptic_emitted")
	_expect(game.haptic_suppressed_count == suppressed_before + 1, "reduced_haptic_not_recorded")
	_expect(game.state["player"] == [4, 6] and int(game.state["painted_count"]) == 5, "reduced_state_consequence")
	for x in range(5):
		_expect(game._amaze_visual_cell_painted(x, 6), "reduced_settled_cell_%d" % x)
	game._set_reduced_effects(false)
	_open_level(2)
	emitted_before = game.haptic_emitted_count
	game._amaze_step(Vector2i.RIGHT)
	_expect(game.haptic_emitted_count == emitted_before + 1, "normal_haptic_not_emitted")
	_expect(game.motion_duration > 0.0 and game._amaze_motion_active(), "normal_motion_not_restored")


func _test_restart_and_path_game_isolation() -> void:
	_open_level(1)
	game._amaze_step(Vector2i.LEFT)
	game._reset_current()
	_expect(game.amaze_object_fx.is_empty(), "restart_object_fx_not_cleared")
	_expect(game.amaze_last_outcome.is_empty(), "restart_outcome_not_cleared")
	game._open_game("amaze_go")
	game.has_transitioned = false
	_expect(game.amaze_object_fx.is_empty(), "amaze_go_inherited_amaze_fx")
	game._amaze_step(Vector2i.RIGHT)
	_expect(game.amaze_object_fx.is_empty(), "amaze_go_mutated_amaze_fx")
	game._open_game("arrow_go")
	game.has_transitioned = false
	game._amaze_step(Vector2i.RIGHT)
	_expect(game.amaze_object_fx.is_empty(), "arrow_go_mutated_amaze_fx")
