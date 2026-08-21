extends SceneTree

var game: Control
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_test_entry_contract()
	_test_renderer_uses_authoritative_model()
	_test_keyboard_long_roll()
	_test_mouse_swipe_parity()
	_test_touch_swipe_parity()
	_test_tap_and_short_gesture_are_inert()
	_test_blocked_feedback()
	_test_completion_and_progression()
	_test_restart_recovery()
	_test_checkpoint_reopen_recovery()
	game._clear_amaze_checkpoint()
	print("AMAZE_INTEGRATION_SMOKE=%d" % assertions)
	print("AMAZE_INTEGRATION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _open() -> void:
	game._clear_amaze_checkpoint()
	game._open_game("amaze")
	game.has_transitioned = false


func _test_entry_contract() -> void:
	_open()
	_expect(game.state["rules_version"] == "amaze-stage0-v2", "entry_rules_version")
	_expect(game.state["level_id"] == "corner_intro", "entry_level")
	_expect(game.state["player"] == [0, 4], "entry_player")
	_expect(int(game.state["width"]) == 5 and int(game.state["height"]) == 5, "entry_dimensions")
	_expect(int(game.state["walkable_count"]) == 9, "entry_walkable")
	_expect(int(game.state["painted_count"]) == 1 and int(game.state["remaining"]) == 8, "entry_progress")
	_expect(int(game.state["moves"]) == 0 and str(game.state["status"]) == "playing", "entry_status")
	_expect(game.buttons.size() == 3 and str(game.buttons[-1].text) == "路线提示", "entry_controls")


func _test_renderer_uses_authoritative_model() -> void:
	_open()
	var metrics: Dictionary = game._amaze_board_metrics()
	_expect(int(metrics["width"]) == 5 and int(metrics["height"]) == 5, "metrics_dimensions")
	_expect(game._amaze_cell_center(0, 4).is_equal_approx(Vector2(97, 623)), "metrics_start_center")
	_expect(game.state["walkable"] == game.amaze_model.walkable, "walkable_model_parity")
	_expect(game.state["painted"] == game.amaze_model.painted, "painted_model_parity")


func _test_keyboard_long_roll() -> void:
	_open()
	var key := InputEventKey.new()
	key.keycode = KEY_UP
	key.pressed = true
	game._input(key)
	_expect(game.state["player"] == [0, 0], "keyboard_stop")
	_expect(game.state["last_traversal"] == [[0, 3], [0, 2], [0, 1], [0, 0]], "keyboard_order")
	_expect(int(game.state["painted_count"]) == 5 and int(game.state["moves"]) == 1, "keyboard_progress")
	_expect(game.amaze_model.position == Vector2i(0, 0), "keyboard_model_parity")


func _test_mouse_swipe_parity() -> void:
	_open()
	_mouse_swipe(Vector2(270, 600), Vector2(270, 500))
	_expect(game.state["player"] == [0, 0], "mouse_stop")
	_expect(game.state["last_traversal"] == [[0, 3], [0, 2], [0, 1], [0, 0]], "mouse_order")
	_expect(int(game.state["painted_count"]) == 5 and int(game.state["moves"]) == 1, "mouse_progress")


func _test_touch_swipe_parity() -> void:
	_open()
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = Vector2(270, 600)
	press.pressed = true
	game._unhandled_input(press)
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = Vector2(270, 500)
	release.pressed = false
	game._unhandled_input(release)
	_expect(game.state["player"] == [0, 0], "touch_stop")
	_expect(game.state["last_traversal"] == [[0, 3], [0, 2], [0, 1], [0, 0]], "touch_order")
	_expect(int(game.state["painted_count"]) == 5 and int(game.state["moves"]) == 1, "touch_progress")
	_expect(game.pointer_down == Vector2(-1, -1), "touch_pointer_released")


func _test_tap_and_short_gesture_are_inert() -> void:
	_open()
	var before := JSON.stringify(game.state)
	game._handle_tap(game._amaze_cell_center(0, 3))
	_expect(JSON.stringify(game.state) == before, "tap_mutated")
	_mouse_swipe(Vector2(270, 600), Vector2(270, 575))
	_expect(JSON.stringify(game.state) == before, "short_gesture_mutated")


func _test_blocked_feedback() -> void:
	_open()
	var before := JSON.stringify(game.state)
	game._amaze_step(Vector2i.LEFT)
	_expect(JSON.stringify(game.state) == before, "blocked_state_mutated")
	var effect: Dictionary = game.catalog_fx.back()
	_expect(str(effect["kind"]) == "path_reject_wall", "blocked_kind")
	_expect(str(effect["semantic"]) == "amaze_blocked", "blocked_semantic")
	_expect(str(effect["font_role"]) == "ui_cjk", "blocked_font_role")
	_expect(str(game.feedback_text) == "前方没有通路", "blocked_feedback")


func _test_completion_and_progression() -> void:
	_open()
	game._amaze_step(Vector2i.UP)
	game._amaze_step(Vector2i.RIGHT)
	_expect(str(game.state["status"]) == "won", "complete_status")
	_expect(int(game.state["painted_count"]) == 9 and int(game.state["remaining"]) == 0, "complete_progress")
	_expect(int(game.state["moves"]) == 2, "complete_moves")
	var effect: Dictionary = game.catalog_fx.back()
	_expect(str(effect["kind"]) == "path_complete" and str(effect["semantic"]) == "amaze_complete", "complete_semantic")
	_expect(str(effect["font_role"]) == "ui_cjk" and int(effect["grade"]) == 4, "complete_feedback_contract")
	_expect(str(game.buttons[-1].text) == "下一迷宫", "complete_next_button")
	game._amaze_next_level()
	_expect(int(game.state["level_index"]) == 1 and str(game.state["level_id"]) == "ribbon_switchback", "progression_level")
	_expect(game.state["player"] == [5, 4] and int(game.state["painted_count"]) == 1, "progression_reset")
	_expect(str(game.state["status"]) == "playing" and str(game.buttons[-1].text) == "路线提示", "progression_controls")


func _test_restart_recovery() -> void:
	_open()
	game._amaze_step(Vector2i.UP)
	game._reset_current()
	_expect(int(game.state["level_index"]) == 0 and game.state["player"] == [0, 4], "restart_level_player")
	_expect(int(game.state["moves"]) == 0 and int(game.state["painted_count"]) == 1, "restart_progress")
	_expect(str(game.state["status"]) == "playing" and game.amaze_last_outcome.is_empty(), "restart_status")
	_expect(game.amaze_model.command_history.is_empty(), "restart_history")


func _test_checkpoint_reopen_recovery() -> void:
	_open()
	game._amaze_step(Vector2i.UP)
	var expected_player: Array = game.state["player"].duplicate()
	var expected_order: Array = game.state["paint_order"].duplicate(true)
	var expected_moves := int(game.state["moves"])
	_expect(not game._load_amaze_checkpoint_text().is_empty(), "checkpoint_saved")
	game._build_home()
	game._open_game("amaze")
	_expect(game.amaze_checkpoint_restored, "checkpoint_restore_flag")
	_expect(game.state["player"] == expected_player and int(game.state["moves"]) == expected_moves, "checkpoint_reopen_position")
	_expect(game.state["paint_order"] == expected_order and int(game.state["painted_count"]) == 5, "checkpoint_reopen_paint")
	_expect(game.state["last_traversal"].is_empty(), "checkpoint_transient_cleared")
	game._reset_current()
	_expect(not game.amaze_checkpoint_restored and int(game.state["moves"]) == 0, "restart_replaces_checkpoint")
	game._build_home()
	game._open_game("amaze")
	_expect(game.amaze_checkpoint_restored and int(game.state["moves"]) == 0, "restart_checkpoint_reopens_clean")


func _mouse_swipe(from: Vector2, to: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = from
	press.pressed = true
	game._gui_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = to
	release.pressed = false
	game._gui_input(release)


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
