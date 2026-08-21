extends SceneTree

const SOLVE_ORDER := ["a1", "a0", "a10", "a3", "a2", "a4", "a6", "a8", "a11", "a5", "a9", "a7"]

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
	_test_entry()
	_test_pointer_legal()
	_test_touch_blocked()
	_test_keyboard_route()
	_test_hint()
	_test_win_and_freeze()
	_test_loss_and_freeze()
	_test_restart()
	_test_recovery()
	_test_sibling_isolation()
	print("AMAZE_GO_MECHANICS_SMOKE=%d" % assertions)
	print("AMAZE_GO_MECHANICS_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func _open() -> void:
	game._open_game("amaze_go")
	game.has_transitioned = false


func _arrow(arrow_id: String) -> Dictionary:
	for arrow in game.state.get("arrows", []):
		if str(arrow.get("id", "")) == arrow_id:
			return arrow
	return {}


func _arrow_point(arrow_id: String, index := -1) -> Vector2:
	var arrow := _arrow(arrow_id)
	var path: Array = arrow.get("path", [])
	var resolved := index if index >= 0 else path.size() - 1
	var raw: Array = path[resolved]
	return game._amaze_go_cell_center(Vector2i(int(raw[0]), int(raw[1])))


func _last_event() -> Dictionary:
	return {} if game.catalog_fx.is_empty() else game.catalog_fx.back()


func _test_entry() -> void:
	_open()
	_expect(str(game.state.get("schema", "")) == "amaze-go-model/v1", "entry_schema")
	_expect(str(game.state.get("level_id", "")) == "bounded-orthogonal-v3-01", "entry_level")
	_expect(int(game.state.get("width", 0)) == 12 and int(game.state.get("height", 0)) == 12, "entry_dimensions")
	_expect(game.state.get("arrows", []).size() == 12, "entry_arrows")
	_expect(int(game.state.get("remaining", -1)) == 12 and int(game.state.get("removed_count", -1)) == 0, "entry_counts")
	_expect(int(game.state.get("hearts", -1)) == 3 and int(game.state.get("max_hearts", -1)) == 3, "entry_hearts")
	_expect(int(game.state.get("score", -1)) == 0 and int(game.state.get("moves", -1)) == 0, "entry_counters")
	_expect(str(game.state.get("status", "")) == "playing", "entry_status")
	_expect(str(game.state.get("focus_id", "")) == "a0", "entry_focus")
	_expect(not game.state.has("player") and not game.state.has("target") and not game.state.has("walls") and not game.state.has("painted"), "old_maze_state_absent")
	_expect(game.amaze_go_route.is_empty(), "old_route_absent")
	_expect(game._amaze_go_hit_test(_arrow_point("a1")) == "a1", "head_hit_owner")
	_expect(game._amaze_go_hit_test(_arrow_point("a1", 1)) == "a1", "body_hit_owner")
	_expect(game._amaze_go_hit_test(Vector2(20, 200)).is_empty(), "outside_hit_empty")


func _test_pointer_legal() -> void:
	_open()
	game._amaze_go_tap_v3(_arrow_point("a1"), "pointer")
	_expect("a1" in game.state.get("removed_ids", []), "pointer_removed")
	_expect(int(game.state.get("remaining", 0)) == 11, "pointer_remaining")
	_expect(int(game.state.get("moves", 0)) == 1 and int(game.state.get("score", 0)) == 20, "pointer_counters")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "extract", "pointer_object_kind")
	_expect(str(game.amaze_go_object_fx.get("input", "")) == "pointer", "pointer_input_tag")
	_expect(str(_last_event().get("kind", "")) == "arrow_extract", "pointer_semantic_event")
	_expect(bool(_arrow("a0").get("legal", false)), "pointer_opens_lane")


func _test_touch_blocked() -> void:
	_open()
	var before_arrow := _arrow("a0").duplicate(true)
	game._amaze_go_tap_v3(_arrow_point("a0"), "touch")
	_expect(not bool(_arrow("a0").get("removed", true)), "touch_blocked_not_removed")
	_expect(_arrow("a0").path == before_arrow.path, "touch_blocked_topology_inert")
	_expect(int(game.state.get("hearts", 0)) == 2, "touch_heart_cost")
	_expect(int(game.state.get("mistakes", 0)) == 1 and int(game.state.get("moves", 0)) == 1, "touch_reject_counters")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "reject", "touch_object_kind")
	_expect(str(game.amaze_go_object_fx.get("input", "")) == "touch", "touch_input_tag")
	_expect(str(_last_event().get("kind", "")) == "arrow_reject", "touch_semantic_event")
	_expect(str(game.state.get("status", "")) == "playing", "touch_status")


func _test_keyboard_route() -> void:
	_open()
	game.amaze_go_model.focus_id = "a1"
	game._sync_amaze_go_state()
	game._amaze_go_attempt(str(game.state.focus_id), "keyboard")
	_expect("a1" in game.state.removed_ids, "keyboard_removed")
	_expect(str(game.amaze_go_object_fx.get("input", "")) == "keyboard", "keyboard_input_tag")
	var before_focus := str(game.state.focus_id)
	game._direction_input(Vector2i.DOWN)
	_expect(not str(game.state.focus_id).is_empty() and str(game.state.focus_id) != before_focus, "keyboard_focus_move")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "focus", "keyboard_focus_feedback")


func _test_hint() -> void:
	_open()
	game._amaze_hint()
	_expect(str(game.state.get("hint_id", "")) == "a1", "hint_legal_arrow")
	_expect(str(game.state.get("focus_id", "")) == "a1", "hint_focus")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "hint", "hint_object_kind")
	_expect(str(_last_event().get("kind", "")) == "arrow_hint", "hint_semantic_event")
	_expect(int(game.state.get("hearts", 0)) == 3 and int(game.state.get("moves", 0)) == 0, "hint_rule_inert")


func _test_win_and_freeze() -> void:
	_open()
	for arrow_id in SOLVE_ORDER:
		var event: Dictionary = game._amaze_go_attempt(arrow_id, "probe")
		_expect(bool(event.get("accepted", false)), "%s_solve_accept" % arrow_id)
	_expect(int(game.state.get("remaining", -1)) == 0 and game.state.removed_ids.size() == 12, "win_clear")
	_expect(str(game.state.get("status", "")) == "won", "win_status")
	_expect(int(game.state.get("score", 0)) == 340 and int(game.state.get("moves", 0)) == 12, "win_counters")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "win", "win_object_kind")
	_expect(int(game.amaze_go_object_fx.get("grade", 0)) == 4, "win_grade")
	_expect(str(_last_event().get("kind", "")) == "arrow_win", "win_semantic_event")
	var frozen: Dictionary = game.state.duplicate(true)
	game._amaze_go_attempt("a0", "probe")
	_expect(game.state == frozen, "win_terminal_freeze")


func _test_loss_and_freeze() -> void:
	_open()
	for _attempt_index in range(3):
		game._amaze_go_attempt("a0", "probe")
	_expect(int(game.state.get("hearts", -1)) == 0, "loss_hearts")
	_expect(int(game.state.get("mistakes", -1)) == 3 and int(game.state.get("moves", -1)) == 3, "loss_counters")
	_expect(str(game.state.get("status", "")) == "over", "loss_status")
	_expect(str(game.amaze_go_object_fx.get("kind", "")) == "loss", "loss_object_kind")
	_expect(int(game.amaze_go_object_fx.get("grade", 0)) == 4, "loss_grade")
	var frozen: Dictionary = game.state.duplicate(true)
	game._amaze_go_attempt("a1", "probe")
	_expect(game.state == frozen, "loss_terminal_freeze")


func _test_restart() -> void:
	_open()
	game._amaze_go_attempt("a1", "probe")
	game._amaze_go_attempt("a0", "probe")
	game._reset_current()
	_expect(game.state.removed_ids.is_empty() and int(game.state.remaining) == 12, "restart_arrows")
	_expect(int(game.state.hearts) == 3 and int(game.state.mistakes) == 0, "restart_hearts")
	_expect(int(game.state.moves) == 0 and int(game.state.score) == 0, "restart_counters")
	_expect(str(game.state.status) == "playing" and str(game.state.focus_id) == "a0", "restart_state")


func _test_recovery() -> void:
	_open()
	game._amaze_go_attempt("a1", "probe")
	game._amaze_go_attempt("a0", "probe")
	var payload: Dictionary = game.amaze_go_model.recovery_snapshot()
	game._reset_current()
	_expect(game._restore_amaze_go_payload(payload), "runtime_restore_valid")
	_expect(game.amaze_go_model.recovery_snapshot() == payload, "runtime_restore_roundtrip")
	var bad := payload.duplicate(true)
	bad.status = "won"
	var before: Dictionary = game.state.duplicate(true)
	_expect(not game._restore_amaze_go_payload(bad), "runtime_restore_invalid")
	_expect(game.state == before, "runtime_restore_invalid_inert")


func _test_sibling_isolation() -> void:
	game._open_game("arrow_go")
	_expect(int(game.state.get("size", 0)) == 9 and game.state.has("arrows"), "arrow_go_legacy_state")
	var arrow_before: Dictionary = game.state.duplicate(true)
	game._amaze_step(Vector2i.RIGHT)
	_expect(game.state != arrow_before, "arrow_go_still_moves")
	_expect(game.amaze_go_model.removed_ids.size() == 2, "arrow_go_did_not_touch_amaze_go_model")
	game._clear_amaze_checkpoint()
	game.amaze_level_index = 0
	game._open_game("amaze")
	_expect(str(game.state.get("rules_version", "")) == "amaze-stage0-v2" and game.state.has("painted"), "amaze_faithful_state")
	var amaze_before: Dictionary = game.state.duplicate(true)
	game._amaze_step(Vector2i.UP)
	_expect(game.state != amaze_before, "amaze_still_moves")
