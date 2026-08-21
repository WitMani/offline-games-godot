extends SceneTree

const SOLUTION: Array[String] = ["b", "a", "d", "c", "k", "g", "f", "l", "i", "e", "j", "h"]

var game: Control
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._arrow_go_clear_recovery()
	_test_entry_shell()
	_test_mouse_reject_and_accept()
	_test_touch_parity()
	_test_keyboard_parity()
	_test_reduced_effects_authority()
	_test_recovery_and_restart()
	_test_runtime_win_and_freeze()
	game._arrow_go_clear_recovery()
	print("ARROW_GO_V3_RUNTIME_ASSERTIONS=%d" % assertions)
	print("ARROW_GO_V3_RUNTIME_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)


func _reset_arrow() -> void:
	game._open_game("arrow_go")
	game._reset_current()
	game.catalog_fx.clear()
	game.arrow_go_object_fx = {}


func _authority() -> Dictionary:
	return {
		"removed_ids":game.state.get("removed_ids", []).duplicate(),
		"remaining":int(game.state.get("remaining", -1)),
		"moves":int(game.state.get("moves", -1)),
		"score":int(game.state.get("score", -1)),
		"status":str(game.state.get("status", "")),
	}


func _last_event() -> Dictionary:
	return {} if game.catalog_fx.is_empty() else game.catalog_fx.back()


func _test_entry_shell() -> void:
	_reset_arrow()
	_expect(str(game.state.get("schema", "")) == "arrow-go-state/v3", "entry_schema")
	_expect(str(game.state.get("level_id", "")) == "local-square-sweep-v3-01", "entry_level")
	_expect(int(game.state.get("remaining", 0)) == 12, "entry_remaining")
	_expect(game.state.get("legal_ids", []) == ["b", "d", "k"], "entry_legal")
	_expect(game._arrow_go_id_at(game._arrow_go_cell_center(Vector2i(4, 4))) == "a", "entry_hit_a")
	_expect(game._arrow_go_id_at(game._arrow_go_cell_center(Vector2i(8, 3))) == "b", "entry_hit_b")


func _mouse_click(position: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	game._gui_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	game._gui_input(release)


func _test_mouse_reject_and_accept() -> void:
	_reset_arrow()
	var before := _authority()
	_mouse_click(game._arrow_go_cell_center(Vector2i(4, 4)))
	_expect(_authority() == before, "mouse_blocked_atomic")
	_expect(str(game.arrow_go_object_fx.get("kind", "")) == "blocked", "mouse_blocked_object")
	_expect(str(_last_event().get("kind", "")) == "arrow_reject", "mouse_blocked_event")
	_mouse_click(game._arrow_go_cell_center(Vector2i(8, 3)))
	_expect(game.state.get("removed_ids", []) == ["b"], "mouse_accept_removed")
	_expect(int(game.state.get("moves", 0)) == 1 and int(game.state.get("score", 0)) == 125, "mouse_accept_counters")
	_expect(str(game.arrow_go_object_fx.get("kind", "")) == "turn_escape", "mouse_accept_object")
	_expect(str(_last_event().get("kind", "")) == "arrow_turn_escape", "mouse_accept_event")


func _touch_tap(position: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.pressed = true
	press.position = position
	game._unhandled_input(press)
	var release := InputEventScreenTouch.new()
	release.pressed = false
	release.position = position
	game._unhandled_input(release)


func _test_touch_parity() -> void:
	_reset_arrow()
	_touch_tap(game._arrow_go_cell_center(Vector2i(8, 3)))
	_expect(game.state.get("removed_ids", []) == ["b"], "touch_accept_removed")
	_expect(int(game.state.get("moves", 0)) == 1 and int(game.state.get("score", 0)) == 125, "touch_accept_counters")
	_expect(str(_last_event().get("kind", "")) == "arrow_turn_escape", "touch_event_parity")


func _test_keyboard_parity() -> void:
	_reset_arrow()
	game.arrow_go_model.focus_id = "b"
	game._sync_arrow_go_state()
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_ENTER
	game._input(key)
	_expect(game.state.get("removed_ids", []) == ["b"], "keyboard_accept_removed")
	_expect(int(game.state.get("moves", 0)) == 1 and int(game.state.get("score", 0)) == 125, "keyboard_accept_counters")
	_expect(str(_last_event().get("kind", "")) == "arrow_turn_escape", "keyboard_event_parity")
	var old_focus := str(game.state.get("focus_id", ""))
	game._direction_input(Vector2i.LEFT)
	_expect(str(game.state.get("focus_id", "")) != old_focus, "keyboard_direction_focus")


func _test_reduced_effects_authority() -> void:
	_reset_arrow()
	game._arrow_go_set_reduced_effects(true)
	game.arrow_go_model.focus_id = "b"
	game._sync_arrow_go_state()
	game._arrow_go_activate_focus()
	_expect(game.state.get("removed_ids", []) == ["b"], "reduced_same_authority")
	_expect(bool(game.state.get("reduced_effects", false)), "reduced_exposed")
	_expect(game._catalog_shake_offset() == Vector2.ZERO, "reduced_no_shake")
	game._arrow_go_set_reduced_effects(false)


func _test_recovery_and_restart() -> void:
	_reset_arrow()
	for arrow_id in ["b", "a", "d"]:
		game._arrow_go_attempt(arrow_id, "probe")
	var expected := _authority()
	var restored: Control = load("res://main.tscn").instantiate()
	root.add_child(restored)
	await process_frame
	restored._open_game("arrow_go")
	_expect(restored.state.get("removed_ids", []) == expected.removed_ids, "recovery_removed")
	_expect(int(restored.state.get("moves", -1)) == int(expected.moves), "recovery_moves")
	_expect(int(restored.state.get("score", -1)) == int(expected.score), "recovery_score")
	restored._reset_current()
	_expect(restored.state.get("removed_ids", []) == [] and int(restored.state.get("remaining", 0)) == 12, "restart_fresh")
	_expect(not FileAccess.file_exists(restored.ARROW_GO_RECOVERY_PATH), "restart_clears_file")
	restored.queue_free()


func _test_runtime_win_and_freeze() -> void:
	_reset_arrow()
	for arrow_id in SOLUTION:
		game._arrow_go_attempt(arrow_id, "probe")
	_expect(str(game.state.get("status", "")) == "won", "runtime_win")
	_expect(int(game.state.get("remaining", -1)) == 0, "runtime_clear")
	_expect(str(game.arrow_go_object_fx.get("kind", "")) == "win", "runtime_win_object")
	_expect(str(_last_event().get("kind", "")) == "arrow_win", "runtime_win_event")
	var before := _authority()
	game._arrow_go_attempt("a", "probe")
	_expect(_authority() == before, "runtime_terminal_freeze")
	_expect(not FileAccess.file_exists(game.ARROW_GO_RECOVERY_PATH), "runtime_terminal_clears_recovery")
