extends SceneTree

const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const GAG_PLATE: Texture2D = preload("res://assets/art/catalog/path_games/gag/arrow_go_wind_plate_gag_v1.png")
const GAG_COURIER_RIGHT: Texture2D = preload("res://assets/art/catalog/path_games/gag/arrow_go_courier_right_gag_v1.png")
const GAG_COURIER_DOWN: Texture2D = preload("res://assets/art/catalog/path_games/gag/arrow_go_courier_down_gag_v1.png")
const GAG_HARBOR: Texture2D = preload("res://assets/art/catalog/path_games/gag/arrow_go_harbor_gag_v1.png")
const GAG_STEP: AudioStream = preload("res://assets/audio/catalog/path_games/gag/arrow_go_kite_step_gag_v1.ogg")
const GAG_DOCK: AudioStream = preload("res://assets/audio/catalog/path_games/gag/arrow_go_harbor_dock_gag_v1.ogg")
const PLATE_SHA := "7c94f74f1b6cc1d201d57bdd1e292e2d04ed73ba2c9ff62da390d8593770492b"
const COURIER_RIGHT_SHA := "2e726e25b6c295d3b948bef538b0227da3e4460767497e646db7033805f8f35e"
const COURIER_DOWN_SHA := "32a64feed8c0bd0d889714ba19412bfdc3985ffb8c4485683b241ef7f38b2604"
const HARBOR_SHA := "6ac5c0c32e5c22836625c1eb1e0bb5e7bbc9be9c91a2aa2634b6a3c8f026bf79"
const STEP_SHA := "af778d06bdbfe61e82c0a2c599a35e4c2f25da8cceba634ed6e54213333f358e"
const DOCK_SHA := "2fa028f08202076d7210c31af40c8c1597bd1f0dbeb9825d7b38a7cad051a07f"
const REQUIRED_COPY := [
	"午夜风筝邮局", "相邻格点击或方向键移动", "航线 17 格",
	"顺着每格风向，把纸翼信使送进星港", "星港在右下角",
	"箭流推进", "轨迹 ×5", "逆着箭流", "已到边界", "全域完成",
	"航信送达", "得分 180 · 步数 16", "点击右上角“重开”继续挑战",
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
	_test_initial_signature_contract()
	_test_direction_rejection()
	_test_step_feedback()
	_test_waypoint_feedback()
	_test_edge_rejection()
	_test_completion_feedback()
	_test_shared_path_games_isolation()
	print("ARROW_GO_ART_SMOKE=%d" % assertions)
	print("ARROW_GO_ART_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func _open() -> void:
	game._open_game("arrow_go")
	game.has_transitioned = false


func _last_event() -> Dictionary:
	return {} if game.catalog_fx.is_empty() else game.catalog_fx.back()


func _last_sfx() -> AudioStream:
	var player_index := posmod(game.sfx_cursor - 1, game.sfx_players.size())
	return game.sfx_players[player_index].stream


func _expect_event(kind: String, grade: int, label: String) -> void:
	var event := _last_event()
	_expect(str(event.get("game_id", "")) == "arrow_go", "%s_wrong_game" % kind)
	_expect(str(event.get("kind", "")) == kind, "%s_wrong_kind" % kind)
	_expect(int(event.get("grade", 0)) == grade, "%s_wrong_grade" % kind)
	_expect(str(event.get("label", "")) == label, "%s_wrong_label" % kind)
	_expect(str(event.get("font_role", "")) == "ui_cjk", "%s_wrong_font_role" % kind)


func _test_gag_runtime_assets() -> void:
	var textures := [
		[GAG_PLATE, "res://assets/art/catalog/path_games/gag/arrow_go_wind_plate_gag_v1.png", PLATE_SHA, "plate"],
		[GAG_COURIER_RIGHT, "res://assets/art/catalog/path_games/gag/arrow_go_courier_right_gag_v1.png", COURIER_RIGHT_SHA, "courier_right"],
		[GAG_COURIER_DOWN, "res://assets/art/catalog/path_games/gag/arrow_go_courier_down_gag_v1.png", COURIER_DOWN_SHA, "courier_down"],
		[GAG_HARBOR, "res://assets/art/catalog/path_games/gag/arrow_go_harbor_gag_v1.png", HARBOR_SHA, "harbor"],
	]
	for item in textures:
		var texture: Texture2D = item[0]
		var label: String = item[3]
		_expect(texture != null, "gag_%s_missing" % label)
		_expect(texture.get_size() == Vector2(192, 192), "gag_%s_dimensions" % label)
		_expect(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "gag_%s_alpha" % label)
		_expect(FileAccess.get_sha256(item[1]) == item[2], "gag_%s_hash" % label)
	_expect(GAG_STEP != null, "gag_step_missing")
	_expect(GAG_STEP.get_length() >= 0.48 and GAG_STEP.get_length() < 0.50, "gag_step_duration")
	_expect(FileAccess.get_sha256("res://assets/audio/catalog/path_games/gag/arrow_go_kite_step_gag_v1.ogg") == STEP_SHA, "gag_step_hash")
	_expect(GAG_DOCK != null, "gag_dock_missing")
	_expect(GAG_DOCK.get_length() >= 0.86 and GAG_DOCK.get_length() < 0.88, "gag_dock_duration")
	_expect(FileAccess.get_sha256("res://assets/audio/catalog/path_games/gag/arrow_go_harbor_dock_gag_v1.ogg") == DOCK_SHA, "gag_dock_hash")


func _test_dynamic_font_role() -> void:
	for sample in REQUIRED_COPY:
		for index in range(sample.length()):
			var codepoint: int = sample.unicode_at(index)
			_expect(UI_FONT.has_char(codepoint), "font_U+%04X" % codepoint)


func _test_initial_signature_contract() -> void:
	_open()
	_expect(game.arrow_go_route == [Vector2i.ZERO], "initial_route")
	_expect(game.arrow_go_facing == Vector2i.RIGHT, "initial_facing")
	_expect(game.arrow_go_object_fx.is_empty(), "initial_object_fx")
	_expect(game.ARROW_GO_GAG_WIND_PLATE_TEXTURE == GAG_PLATE, "plate_runtime_binding")
	_expect(game.ARROW_GO_GAG_COURIER_RIGHT_TEXTURE == GAG_COURIER_RIGHT, "courier_right_runtime_binding")
	_expect(game.ARROW_GO_GAG_COURIER_DOWN_TEXTURE == GAG_COURIER_DOWN, "courier_down_runtime_binding")
	_expect(game.ARROW_GO_GAG_HARBOR_TEXTURE == GAG_HARBOR, "harbor_runtime_binding")
	_expect(game._painted_count() == 1, "initial_painted")
	_expect(game._path_cell_center(0, 0, 9).is_equal_approx(Vector2(77.888885, 259.888885)), "initial_signature_position")


func _test_direction_rejection() -> void:
	_open()
	var before: Dictionary = game.state.duplicate(true)
	game._amaze_step(Vector2i.DOWN)
	_expect(game.state == before, "direction_reject_mutated_rules")
	_expect(game.arrow_go_route == [Vector2i.ZERO], "direction_reject_mutated_route")
	_expect(str(game.arrow_go_object_fx.get("kind", "")) == "crosswind_reject", "direction_object_kind")
	_expect(int(game.arrow_go_object_fx.get("grade", 0)) == 2, "direction_object_grade")
	_expect(game.arrow_go_object_fx.get("expected") == Vector2i.RIGHT, "direction_expected")
	_expect(game.arrow_go_object_fx.get("attempted") == Vector2i.DOWN, "direction_attempted")
	_expect_event("path_reject_arrow", 2, "逆着箭流")


func _test_step_feedback() -> void:
	_open()
	game._amaze_step(Vector2i.RIGHT)
	_expect(game.arrow_go_route == [Vector2i.ZERO, Vector2i.RIGHT], "step_route")
	_expect(game.arrow_go_facing == Vector2i.RIGHT, "step_facing")
	_expect(str(game.arrow_go_object_fx.get("kind", "")) == "step", "step_object_kind")
	_expect(int(game.arrow_go_object_fx.get("grade", 0)) == 1, "step_object_grade")
	_expect(game.motion_kind == "path", "step_motion_kind")
	_expect(game.motion_from != game.motion_to, "step_motion_span")
	_expect_event("path_step", 1, "箭流推进")
	_expect(_last_sfx() == GAG_STEP, "step_gag_sound_not_routed")


func _test_waypoint_feedback() -> void:
	_open()
	for _step in range(5):
		game._amaze_step(Vector2i.RIGHT)
	_expect(game.arrow_go_route.size() == 6, "waypoint_route_size")
	_expect(str(game.arrow_go_object_fx.get("kind", "")) == "waypoint", "waypoint_object_kind")
	_expect(int(game.arrow_go_object_fx.get("grade", 0)) == 2, "waypoint_object_grade")
	_expect_event("path_step", 2, "轨迹 ×5")
	_expect(_last_sfx() == GAG_STEP, "waypoint_gag_sound_not_routed")


func _test_edge_rejection() -> void:
	_open()
	game.state["player"] = [8, 8]
	var before: Dictionary = game.state.duplicate(true)
	game._amaze_step(Vector2i.DOWN)
	_expect(game.state == before, "edge_reject_mutated_rules")
	_expect(str(game.arrow_go_object_fx.get("kind", "")) == "edge_reject", "edge_object_kind")
	_expect(int(game.arrow_go_object_fx.get("grade", 0)) == 1, "edge_object_grade")
	_expect(game.arrow_go_route == [Vector2i.ZERO], "edge_reject_mutated_route")
	_expect_event("path_reject_edge", 1, "已到边界")


func _test_completion_feedback() -> void:
	_open()
	game.state["player"] = [8, 7]
	game.arrow_go_route.clear()
	game.arrow_go_route.append(Vector2i(8, 7))
	game._amaze_step(Vector2i.DOWN)
	_expect(str(game.state.get("status", "")) == "won", "complete_status")
	_expect(game.state["player"] == [8, 8], "complete_player")
	_expect(int(game.state["moves"]) == 1, "complete_moves")
	_expect(int(game.state["score"]) == 105, "complete_score")
	_expect(game.arrow_go_route == [Vector2i(8, 7), Vector2i(8, 8)], "complete_route")
	_expect(game.arrow_go_facing == Vector2i.DOWN, "complete_facing")
	_expect(str(game.arrow_go_object_fx.get("kind", "")) == "complete", "complete_object_kind")
	_expect(int(game.arrow_go_object_fx.get("grade", 0)) == 4, "complete_object_grade")
	_expect_event("path_complete", 4, "全域完成")
	_expect(_last_sfx() == GAG_DOCK, "complete_gag_sound_not_routed")


func _test_shared_path_games_isolation() -> void:
	game._open_game("amaze_go")
	game.has_transitioned = false
	_expect(game.arrow_go_route.is_empty(), "amaze_go_inherited_arrow_route")
	_expect(game.arrow_go_object_fx.is_empty(), "amaze_go_inherited_arrow_fx")
	game._amaze_step(Vector2i.RIGHT)
	_expect(game.arrow_go_route.is_empty(), "amaze_go_mutated_arrow_route")
	game._open_game("amaze")
	game.has_transitioned = false
	_expect(game.arrow_go_route.is_empty(), "amaze_inherited_arrow_route")
	game._amaze_step(Vector2i.RIGHT)
	_expect(game.arrow_go_route.is_empty(), "amaze_mutated_arrow_route")
