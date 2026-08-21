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
const SOLVE_ORDER := ["a1", "a0", "a10", "a3", "a2", "a4", "a6", "a8", "a11", "a5", "a9", "a7"]
const REQUIRED_COPY := [
	"发条清箭局", "点按清路箭头", "方向键选择", "回车抽取",
	"清路箭头可以滑出", "受阻会失去一滴水", "提示", "重开", "余箭",
	"箭头滑出", "路线展开", "即将清空", "路径受阻", "水滴耗尽", "全箭清空",
	"点击右上角“重开”继续挑战",
]

var game: Control
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.amaze_go_recovery_enabled = false
	root.add_child(game)
	await process_frame
	_test_gag_runtime_assets()
	_test_dynamic_font_role()
	_test_stable_signature_binding()
	_test_extract_feedback()
	_test_waypoint_feedback()
	_test_near_feedback()
	_test_reject_feedback()
	_test_loss_feedback()
	_test_hint_and_focus_feedback()
	_test_completion_feedback()
	_test_reduced_effects_authority()
	_test_shared_path_games_isolation()
	print("AMAZE_GO_ART_SMOKE=%d" % assertions)
	print("AMAZE_GO_ART_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func _open() -> void:
	game._set_amaze_go_reduced_effects(false)
	game._open_game("amaze_go")
	game.has_transitioned = false
	game.catalog_fx.clear()
	game.amaze_go_object_fx = {}


func _last_event() -> Dictionary:
	return {} if game.catalog_fx.is_empty() else game.catalog_fx.back()


func _last_sfx() -> AudioStream:
	var player_index := posmod(game.sfx_cursor - 1, game.sfx_players.size())
	return game.sfx_players[player_index].stream


func _arrow(arrow_id: String) -> Dictionary:
	for arrow in game.state.get("arrows", []):
		if str(arrow.get("id", "")) == arrow_id:
			return arrow
	return {}


func _expect_event(kind: String, grade: int, label: String, audio: AudioStream) -> void:
	var event := _last_event()
	_expect(str(event.get("game_id", "")) == "amaze_go", "%s_wrong_game" % kind)
	_expect(str(event.get("kind", "")) == kind, "%s_wrong_kind" % kind)
	_expect(str(event.get("semantic", "")) == kind, "%s_wrong_semantic" % kind)
	_expect(int(event.get("grade", 0)) == grade, "%s_wrong_grade" % kind)
	_expect(str(event.get("label", "")) == label, "%s_wrong_label" % kind)
	_expect(str(event.get("font_role", "")) == "ui_cjk", "%s_wrong_font_role" % kind)
	_expect(event.get("label_position", Vector2.ZERO) == Vector2(270, 788), "%s_label_position" % kind)
	_expect(float(event.get("duration", 0.0)) >= 0.46, "%s_duration" % kind)
	_expect(_last_sfx() == audio, "%s_audio_route" % kind)


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


func _test_stable_signature_binding() -> void:
	_open()
	_expect(game.AMAZE_GO_GAG_SURVEYOR_TEXTURE == GAG_SURVEYOR, "surveyor_runtime_binding")
	_expect(game.AMAZE_GO_GAG_BEACON_TEXTURE == GAG_BEACON, "beacon_runtime_binding")
	_expect(game.SFX_AMAZE_GO_GAG_RATCHET == GAG_RATCHET, "ratchet_runtime_binding")
	_expect(game.SFX_AMAZE_GO_GAG_SEAL == GAG_SEAL, "seal_runtime_binding")
	_expect(game.state.get("gag_visible_roles", []) == ["surveyor_clearance_station", "beacon_progress_seal"], "stable_gag_roles")
	_expect(game.state.get("arrows", []).size() == 12, "stable_live_arrows")
	_expect(int(game.state.get("removed_count", -1)) == 0, "stable_progress_zero")
	_expect(str(game.state.get("focus_id", "")) == "a0", "stable_focus")
	_expect(not bool(game.state.get("reduced_effects", true)), "stable_normal_effects")
	_expect(not game.state.has("player") and not game.state.has("target") and not game.state.has("walls"), "no_old_maze_authority")


func _test_extract_feedback() -> void:
	_open()
	var haptics_before: int = int(game.haptic_dispatch_count)
	var event: Dictionary = game._amaze_go_attempt("a1", "pointer")
	_expect(bool(event.get("accepted", false)), "extract_accepted")
	_expect("a1" in game.state.get("removed_ids", []), "extract_authority_removed")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "extract", "extract_object_kind")
	_expect(game.amaze_go_object_fx.get("path", []).size() >= 2, "extract_object_path")
	_expect(str(game.amaze_go_object_fx.get("input", "")) == "pointer", "extract_input")
	_expect(int(game.amaze_go_object_fx.get("remaining", -1)) == 11, "extract_remaining")
	_expect(not bool(game.amaze_go_object_fx.get("reduced", true)), "extract_normal_mode")
	_expect(game.haptic_dispatch_count == haptics_before + 1, "extract_haptic_grade1")
	_expect_event("arrow_extract", 1, "箭头滑出", GAG_RATCHET)


func _test_waypoint_feedback() -> void:
	_open()
	for arrow_id in SOLVE_ORDER.slice(0, 3):
		game._amaze_go_attempt(arrow_id, "probe")
	_expect(int(game.state.get("removed_count", 0)) == 3, "waypoint_removed_count")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "waypoint", "waypoint_object_kind")
	_expect(int(game.amaze_go_object_fx.get("grade", 0)) == 2, "waypoint_object_grade")
	_expect(int(game.amaze_go_object_fx.get("remaining", -1)) == 9, "waypoint_remaining")
	_expect_event("arrow_waypoint", 2, "路线展开", GAG_RATCHET)


func _test_near_feedback() -> void:
	_open()
	for arrow_id in SOLVE_ORDER.slice(0, 10):
		game._amaze_go_attempt(arrow_id, "probe")
	_expect(int(game.state.get("remaining", -1)) == 2, "near_remaining")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "near", "near_object_kind")
	_expect(int(game.amaze_go_object_fx.get("grade", 0)) == 3, "near_object_grade")
	_expect(float(game.amaze_go_object_fx.get("duration", 0.0)) == 0.72, "near_duration")
	_expect_event("arrow_near", 3, "即将清空", GAG_RATCHET)


func _test_reject_feedback() -> void:
	_open()
	var before := _arrow("a0").duplicate(true)
	var haptics_before: int = int(game.haptic_dispatch_count)
	var event: Dictionary = game._amaze_go_attempt("a0", "touch")
	_expect(not bool(event.get("accepted", true)), "reject_not_accepted")
	_expect(_arrow("a0").get("path", []) == before.get("path", []), "reject_path_authoritative")
	_expect(not bool(_arrow("a0").get("removed", true)), "reject_not_removed")
	_expect(int(game.state.get("hearts", 0)) == 2, "reject_heart_delta")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "reject", "reject_object_kind")
	_expect(game.amaze_go_object_fx.get("contact", Vector2.ZERO) != Vector2.ZERO, "reject_contact")
	_expect(str(game.amaze_go_object_fx.get("input", "")) == "touch", "reject_input")
	_expect(game.haptic_dispatch_count == haptics_before + 1, "reject_haptic")
	_expect_event("arrow_reject", 2, "路径受阻", game.SFX_SNAKE_REJECT)


func _test_loss_feedback() -> void:
	_open()
	for _attempt in range(3):
		game._amaze_go_attempt("a0", "probe")
	_expect(str(game.state.get("status", "")) == "over", "loss_status")
	_expect(int(game.state.get("hearts", -1)) == 0, "loss_hearts")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "loss", "loss_object_kind")
	_expect(int(game.amaze_go_object_fx.get("grade", 0)) == 4, "loss_object_grade")
	_expect(float(game.amaze_go_object_fx.get("duration", 0.0)) == 0.84, "loss_duration")
	_expect_event("arrow_loss", 4, "水滴耗尽", game.SFX_SNAKE_REJECT)


func _test_hint_and_focus_feedback() -> void:
	_open()
	game._amaze_hint()
	_expect(str(game.state.get("hint_id", "")) == "a1", "hint_authoritative_legal")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "hint", "hint_object_kind")
	_expect(int(game.state.get("moves", -1)) == 0, "hint_rule_inert")
	_expect_event("arrow_hint", 1, "清路箭头", GAG_RATCHET)
	var focus_before := str(game.state.get("focus_id", ""))
	game._direction_input(Vector2i.DOWN)
	_expect(str(game.state.get("focus_id", "")) != focus_before, "focus_changed")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "focus", "focus_object_kind")
	_expect(int(game.state.get("moves", -1)) == 0, "focus_rule_inert")


func _test_completion_feedback() -> void:
	_open()
	for arrow_id in SOLVE_ORDER:
		game._amaze_go_attempt(arrow_id, "probe")
	_expect(str(game.state.get("status", "")) == "won", "win_status")
	_expect(int(game.state.get("remaining", -1)) == 0, "win_remaining")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "win", "win_object_kind")
	_expect(int(game.amaze_go_object_fx.get("grade", 0)) == 4, "win_object_grade")
	_expect(float(game.amaze_go_object_fx.get("duration", 0.0)) == 1.08, "win_duration")
	_expect(int(game.amaze_go_object_fx.get("removed_count", 0)) == 12, "win_removed_count")
	_expect_event("arrow_win", 4, "全箭清空", GAG_SEAL)
	var frozen: Dictionary = game.state.duplicate(true)
	game._amaze_go_attempt("a0", "probe")
	_expect(game.state == frozen, "win_terminal_freeze")


func _test_reduced_effects_authority() -> void:
	_open()
	game._set_amaze_go_reduced_effects(true)
	_expect(bool(game.state.get("reduced_effects", false)), "reduced_state_exposed")
	var haptics_before: int = int(game.haptic_dispatch_count)
	game._amaze_go_attempt("a1", "probe")
	_expect("a1" in game.state.get("removed_ids", []), "reduced_extract_authority")
	_expect(game.haptic_dispatch_count == haptics_before, "reduced_extract_haptic_suppressed")
	_expect(game._catalog_shake_offset() == Vector2.ZERO, "reduced_shake_suppressed")
	_expect(bool(game.amaze_go_object_fx.get("reduced", false)), "reduced_object_tag")
	_expect(_last_sfx() == GAG_RATCHET, "reduced_audio_preserved")
	game._open_game("amaze_go")
	game.has_transitioned = false
	game.catalog_fx.clear()
	game._amaze_go_attempt("a0", "probe")
	_expect(game._amaze_go_arrow_event_offset("a0") == Vector2.ZERO, "reduced_recoil_suppressed")
	_expect(game.haptic_dispatch_count == haptics_before, "reduced_reject_haptic_suppressed")
	game._impact(Vector2(200, 300), Color.RED, 1.0)
	_expect(game.impact_until == game.elapsed, "reduced_impact_motion_suppressed")
	game._set_amaze_go_reduced_effects(false)


func _test_shared_path_games_isolation() -> void:
	game._arrow_go_clear_recovery()
	game._open_game("arrow_go")
	game.has_transitioned = false
	_expect(not game.state.has("gag_visible_roles"), "arrow_go_no_amaze_gag_roles")
	var arrow_before: Dictionary = game.state.duplicate(true)
	game._arrow_go_attempt("b", "sibling_isolation")
	_expect(game.state != arrow_before, "arrow_go_still_moves")
	game._clear_amaze_checkpoint()
	game.amaze_level_index = 0
	game._open_game("amaze")
	game.has_transitioned = false
	_expect(not game.state.has("gag_visible_roles"), "amaze_no_amaze_gag_roles")
	var amaze_before: Dictionary = game.state.duplicate(true)
	game._amaze_step(Vector2i.UP)
	_expect(game.state != amaze_before, "amaze_still_moves")
