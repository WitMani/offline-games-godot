extends SceneTree

const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const GAG_SURVEYOR: Texture2D = preload("res://assets/art/catalog/path_games/gag/amaze_go_surveyor_gag_v1.png")
const GAG_BEACON: Texture2D = preload("res://assets/art/catalog/path_games/gag/amaze_go_beacon_gag_v1.png")
const GAG_RATCHET: AudioStream = preload("res://assets/audio/catalog/path_games/gag/amaze_go_survey_ratchet_gag_v1.ogg")
const GAG_SEAL: AudioStream = preload("res://assets/audio/catalog/path_games/gag/amaze_go_destination_seal_gag_v1.ogg")
const SURVEYOR_SHA := "baeb571dcb42962905a0f7c8dd8ff15f71625e7954739fb57cba746e62d4eddc"
const BEACON_SHA := "15ac1714e7d0bce2331b6c5280d2b6366598453d7ea9cd4299ffbe7e0282e6c8"
const RATCHET_SHA := "84ebcbb7a852593d8a20ab983afdbeb6e99ec205d59ea74520ff1254cff2d442"
const SEAL_SHA := "7c6b5ae0487662e8e08b908ff5aaada815700b055e80f3acfbb38f9e5cf66c7b"
const REQUIRED_COPY := [
	"发条测绘局", "相邻格点击或方向键移动", "测绘 6 格",
	"发条测绘仪会把每一步钉进蓝图航路", "黄铜航标在右下角",
	"蓝图点亮", "轨迹 ×5", "蓝图有墙", "已到边界", "全域完成",
	"航路认证", "得分 125 · 步数 5", "点击右上角“重开”继续挑战",
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
	_test_step_feedback()
	_test_waypoint_feedback()
	_test_wall_rejection()
	_test_edge_rejection()
	_test_completion_feedback()
	_test_shared_path_games_isolation()
	print("AMAZE_GO_ART_SMOKE=%d" % assertions)
	print("AMAZE_GO_ART_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func _open() -> void:
	game._open_game("amaze_go")
	game.has_transitioned = false


func _last_event() -> Dictionary:
	return {} if game.catalog_fx.is_empty() else game.catalog_fx.back()


func _last_sfx() -> AudioStream:
	var player_index := posmod(game.sfx_cursor - 1, game.sfx_players.size())
	return game.sfx_players[player_index].stream


func _expect_event(kind: String, grade: int, label: String) -> void:
	var event := _last_event()
	_expect(str(event.get("game_id", "")) == "amaze_go", "%s_wrong_game" % kind)
	_expect(str(event.get("kind", "")) == kind, "%s_wrong_kind" % kind)
	_expect(int(event.get("grade", 0)) == grade, "%s_wrong_grade" % kind)
	_expect(str(event.get("label", "")) == label, "%s_wrong_label" % kind)
	_expect(str(event.get("font_role", "")) == "ui_cjk", "%s_wrong_font_role" % kind)


func _test_gag_runtime_assets() -> void:
	_expect(GAG_SURVEYOR != null, "gag_surveyor_missing")
	_expect(GAG_SURVEYOR.get_size() == Vector2(358, 347), "gag_surveyor_dimensions")
	_expect(GAG_SURVEYOR.get_image().detect_alpha() != Image.ALPHA_NONE, "gag_surveyor_alpha")
	_expect(FileAccess.get_sha256("res://assets/art/catalog/path_games/gag/amaze_go_surveyor_gag_v1.png") == SURVEYOR_SHA, "gag_surveyor_hash")
	_expect(GAG_BEACON != null, "gag_beacon_missing")
	_expect(GAG_BEACON.get_size() == Vector2(393, 398), "gag_beacon_dimensions")
	_expect(GAG_BEACON.get_image().detect_alpha() != Image.ALPHA_NONE, "gag_beacon_alpha")
	_expect(FileAccess.get_sha256("res://assets/art/catalog/path_games/gag/amaze_go_beacon_gag_v1.png") == BEACON_SHA, "gag_beacon_hash")
	_expect(GAG_RATCHET != null, "gag_ratchet_missing")
	_expect(GAG_RATCHET.get_length() >= 0.49 and GAG_RATCHET.get_length() < 0.51, "gag_ratchet_duration")
	_expect(FileAccess.get_sha256("res://assets/audio/catalog/path_games/gag/amaze_go_survey_ratchet_gag_v1.ogg") == RATCHET_SHA, "gag_ratchet_hash")
	_expect(GAG_SEAL != null, "gag_seal_missing")
	_expect(GAG_SEAL.get_length() >= 0.53 and GAG_SEAL.get_length() < 0.55, "gag_seal_duration")
	_expect(FileAccess.get_sha256("res://assets/audio/catalog/path_games/gag/amaze_go_destination_seal_gag_v1.ogg") == SEAL_SHA, "gag_seal_hash")


func _test_dynamic_font_role() -> void:
	for sample in REQUIRED_COPY:
		for index in range(sample.length()):
			var codepoint: int = sample.unicode_at(index)
			_expect(UI_FONT.has_char(codepoint), "font_U+%04X" % codepoint)


func _test_initial_signature_contract() -> void:
	_open()
	_expect(game.amaze_go_route == [Vector2i.ZERO], "initial_route")
	_expect(game.amaze_go_facing == Vector2i.RIGHT, "initial_facing")
	_expect(game.amaze_go_object_fx.is_empty(), "initial_object_fx")
	_expect(game.AMAZE_GO_GAG_SURVEYOR_TEXTURE == GAG_SURVEYOR, "surveyor_runtime_binding")
	_expect(game.AMAZE_GO_GAG_BEACON_TEXTURE == GAG_BEACON, "beacon_runtime_binding")
	_expect(game._painted_count() == 1, "initial_painted")
	_expect(game._path_cell_center(0, 0, 6) == Vector2(89.833333, 271.833333), "initial_signature_position")


func _test_step_feedback() -> void:
	_open()
	game._amaze_step(Vector2i.RIGHT)
	_expect(game.amaze_go_route == [Vector2i.ZERO, Vector2i.RIGHT], "step_route")
	_expect(game.amaze_go_facing == Vector2i.RIGHT, "step_facing")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "step", "step_object_kind")
	_expect(int(game.amaze_go_object_fx.get("grade", 0)) == 1, "step_object_grade")
	_expect(game.motion_kind == "path", "step_motion_kind")
	_expect(game.motion_from != game.motion_to, "step_motion_span")
	_expect_event("path_step", 1, "蓝图点亮")
	_expect(_last_sfx() == GAG_RATCHET, "step_gag_ratchet_not_routed")


func _test_waypoint_feedback() -> void:
	_open()
	for _step in range(5):
		game._amaze_step(Vector2i.RIGHT)
	_expect(game.amaze_go_route.size() == 6, "waypoint_route_size")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "waypoint", "waypoint_object_kind")
	_expect(int(game.amaze_go_object_fx.get("grade", 0)) == 2, "waypoint_object_grade")
	_expect_event("path_step", 2, "轨迹 ×5")
	_expect(_last_sfx() == GAG_RATCHET, "waypoint_gag_ratchet_not_routed")


func _test_wall_rejection() -> void:
	_open()
	game.state["player"] = [0, 4]
	var before: Dictionary = game.state.duplicate(true)
	game._amaze_step(Vector2i.RIGHT)
	_expect(game.state == before, "wall_reject_mutated_rules")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "wall_reject", "wall_object_kind")
	_expect(int(game.amaze_go_object_fx.get("grade", 0)) == 2, "wall_object_grade")
	_expect(game.amaze_go_object_fx.has("contact"), "wall_contact_missing")
	_expect(game.amaze_go_route == [Vector2i.ZERO], "wall_reject_route_mutated")
	_expect_event("path_reject_wall", 2, "蓝图有墙")


func _test_edge_rejection() -> void:
	_open()
	var before: Dictionary = game.state.duplicate(true)
	game._amaze_step(Vector2i.LEFT)
	_expect(game.state == before, "edge_reject_mutated_rules")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "edge_reject", "edge_object_kind")
	_expect(int(game.amaze_go_object_fx.get("grade", 0)) == 1, "edge_object_grade")
	_expect(game.amaze_go_route == [Vector2i.ZERO], "edge_reject_route_mutated")
	_expect_event("path_reject_edge", 1, "已到边界")


func _test_completion_feedback() -> void:
	_open()
	game.state["player"] = [4, 5]
	game.amaze_go_route.clear()
	game.amaze_go_route.append(Vector2i(4, 5))
	game._amaze_step(Vector2i.RIGHT)
	_expect(str(game.state.get("status", "")) == "won", "complete_status")
	_expect(game.state["player"] == [5, 5], "complete_player")
	_expect(int(game.state["moves"]) == 1, "complete_moves")
	_expect(int(game.state["score"]) == 105, "complete_score")
	_expect(game.amaze_go_route == [Vector2i(4, 5), Vector2i(5, 5)], "complete_route")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "complete", "complete_object_kind")
	_expect(int(game.amaze_go_object_fx.get("grade", 0)) == 4, "complete_object_grade")
	_expect_event("path_complete", 4, "全域完成")
	_expect(_last_sfx() == GAG_SEAL, "complete_gag_seal_not_routed")


func _test_shared_path_games_isolation() -> void:
	game._open_game("arrow_go")
	game.has_transitioned = false
	_expect(game.amaze_go_route.is_empty(), "arrow_go_inherited_route")
	_expect(game.amaze_go_object_fx.is_empty(), "arrow_go_inherited_object_fx")
	game._amaze_step(Vector2i.RIGHT)
	_expect(game.amaze_go_route.is_empty(), "arrow_go_mutated_route")
	game._open_game("amaze")
	game.has_transitioned = false
	_expect(game.amaze_go_route.is_empty(), "amaze_inherited_route")
	game._amaze_step(Vector2i.RIGHT)
	_expect(game.amaze_go_route.is_empty(), "amaze_mutated_route")
