extends SceneTree

var game: Control
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.merge2048_persistence_enabled = false
	game.merge2048_seed_override = 8181
	root.add_child(game)
	await process_frame
	_test_entry_contract()
	await _test_keyboard_routes()
	_test_mouse_swipe_route()
	_test_touch_swipe_route()
	_test_rejection_and_feedback()
	_test_semantic_merge_feedback()
	_test_win_continue_and_restart()
	_test_reduced_effects()
	print("MERGE2048_INTEGRATION_ASSERTIONS=%d" % assertions)
	print("MERGE2048_INTEGRATION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _test_entry_contract() -> void:
	game._open_game("merge2048")
	_expect(game.game_id == "merge2048" and game.screen == "game", "entry_route")
	_expect(game.state.board.size() == 4 and game.state.board[0].size() == 4, "entry_dimensions")
	_expect(_occupied(game.state.board) == 2, "entry_two_tiles")
	_expect(int(game.state.target) == 2048 and str(game.state.status) == "playing", "entry_target_status")
	_expect(int(game.state.score) == 0 and int(game.state.moves) == 0, "entry_score_moves")
	_expect(game.state.has("best") and game.state.has("merge2048"), "entry_authoritative_snapshot")


func _test_keyboard_routes() -> void:
	for sample in [
		{"key":KEY_LEFT, "direction":Vector2i.LEFT, "board":[[0, 0, 0, 2], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]},
		{"key":KEY_A, "direction":Vector2i.LEFT, "board":[[0, 0, 0, 2], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]},
		{"key":KEY_H, "direction":Vector2i.LEFT, "board":[[0, 0, 0, 2], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]},
		{"key":KEY_RIGHT, "direction":Vector2i.RIGHT, "board":[[2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]},
		{"key":KEY_D, "direction":Vector2i.RIGHT, "board":[[2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]},
		{"key":KEY_L, "direction":Vector2i.RIGHT, "board":[[2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]},
		{"key":KEY_UP, "direction":Vector2i.UP, "board":[[0, 0, 0, 0], [2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]},
		{"key":KEY_W, "direction":Vector2i.UP, "board":[[0, 0, 0, 0], [2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]},
		{"key":KEY_K, "direction":Vector2i.UP, "board":[[0, 0, 0, 0], [2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]},
		{"key":KEY_DOWN, "direction":Vector2i.DOWN, "board":[[2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]},
		{"key":KEY_S, "direction":Vector2i.DOWN, "board":[[2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]},
		{"key":KEY_J, "direction":Vector2i.DOWN, "board":[[2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]},
	]:
		game._open_game("merge2048")
		game._merge2048_load_fixture(sample.board)
		var event := InputEventKey.new()
		event.keycode = int(sample.key)
		event.pressed = true
		Input.parse_input_event(event)
		await process_frame
		_expect(game.merge2048_motion.get("direction") == sample.direction, "key_route_%s" % sample.key)
		_expect(int(game.state.moves) == 1, "key_move_%s" % sample.key)


func _test_mouse_swipe_route() -> void:
	game._open_game("merge2048")
	game._merge2048_load_fixture([[2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(100, 400)
	game._gui_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(112, 400)
	game._gui_input(release)
	_expect(game.merge2048_motion.get("direction") == Vector2i.RIGHT, "mouse_threshold_route")
	_expect(int(game.state.moves) == 1, "mouse_move")


func _test_touch_swipe_route() -> void:
	game._open_game("merge2048")
	game._merge2048_load_fixture([[0, 0, 0, 0], [0, 0, 0, 0], [2, 0, 0, 0], [0, 0, 0, 0]])
	var press := InputEventScreenTouch.new()
	press.pressed = true
	press.position = Vector2(180, 450)
	game._unhandled_input(press)
	var release := InputEventScreenTouch.new()
	release.pressed = false
	release.position = Vector2(180, 440)
	game._unhandled_input(release)
	_expect(int(game.state.moves) == 0, "touch_threshold_ten_inert")
	press.position = Vector2(180, 450)
	game._unhandled_input(press)
	release.position = Vector2(180, 439)
	game._unhandled_input(release)
	_expect(game.merge2048_motion.get("direction") == Vector2i.UP, "touch_threshold_route")
	_expect(int(game.state.moves) == 1, "touch_move")


func _test_rejection_and_feedback() -> void:
	game._open_game("merge2048")
	game._merge2048_load_fixture([
		[2, 4, 8, 16], [32, 64, 128, 256],
		[4, 8, 16, 32], [64, 128, 256, 512],
	], 120, 9, false, false, false, 200)
	var before: Dictionary = game.state.duplicate(true)
	game._merge_move(Vector2i.LEFT)
	_expect(game.state == before, "reject_state_inert")
	_expect(not game.catalog_fx.is_empty(), "reject_effect")
	if not game.catalog_fx.is_empty():
		_expect(str(game.catalog_fx.back().semantic) == "wood_reject", "reject_semantic")
		_expect(str(game.catalog_fx.back().font_role) == "ui_cjk", "reject_cjk_font_role")


func _test_semantic_merge_feedback() -> void:
	game._open_game("merge2048")
	game._merge2048_load_fixture([
		[2, 2, 0, 0],
		[2, 2, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	game._merge_move(Vector2i.LEFT)
	_expect(int(game.merge2048_motion.get("merge_count", 0)) == 2, "semantic_parallel_merge_count")
	_expect(int(game.merge2048_motion.get("peak_value", 0)) == 4, "semantic_peak_not_aggregate")
	_expect(int(game.merge2048_motion.get("grade", 0)) == 1, "semantic_grade_not_aggregate")
	_expect(game.merge2048_motion.get("impact_cell") == Vector2i(0, 0), "semantic_primary_impact_cell")
	_expect(not game.catalog_fx.is_empty() and int(game.catalog_fx.back().merge_count) == 2, "semantic_event_metadata")
	_expect(str(game.catalog_fx.back().font_role) == "ui_cjk", "semantic_cjk_font_role")

	game._open_game("merge2048")
	game._merge2048_load_fixture([
		[0, 0, 0, 0],
		[0, 16, 16, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	game._merge_move(Vector2i.LEFT)
	_expect(int(game.merge2048_motion.get("peak_value", 0)) == 32, "semantic_milestone_value")
	_expect(int(game.merge2048_motion.get("grade", 0)) == 3, "semantic_milestone_grade")
	_expect(game.merge2048_motion.get("impact_cell") == Vector2i(0, 1), "semantic_milestone_impact")
	_expect(str(game.catalog_fx.back().semantic) == "wood_milestone", "semantic_milestone_audio_role")


func _test_win_continue_and_restart() -> void:
	game._open_game("merge2048")
	game._merge2048_load_fixture([[1024, 1024, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]], 100, 8, false, false, false, 300)
	game._merge_move(Vector2i.LEFT)
	_expect(str(game.state.status) == "won" and bool(game.state.can_continue), "win_pause")
	_expect(_has_button("继续挑战"), "continue_button")
	var paused: Dictionary = game.state.duplicate(true)
	game._merge_move(Vector2i.RIGHT)
	_expect(game.state == paused, "win_input_frozen")
	game._merge2048_continue()
	_expect(str(game.state.status) == "playing" and not bool(game.state.can_continue), "continue_state")
	_expect(_has_button("左") and not _has_button("继续挑战"), "continue_controls")
	var preserved_best := int(game.state.best)
	game._reset_current()
	_expect(_occupied(game.state.board) == 2 and int(game.state.score) == 0, "restart_fresh")
	_expect(int(game.state.best) == preserved_best, "restart_best")


func _test_reduced_effects() -> void:
	game._open_game("merge2048")
	game.reduced_effects_enabled = true
	game._merge2048_load_fixture([[64, 64, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
	game._merge_move(Vector2i.LEFT)
	_expect(bool(game.merge2048_motion.get("reduced", false)), "reduced_motion_marker")
	_expect(float(game.merge2048_motion.get("duration", 1.0)) <= 0.16, "reduced_motion_duration")
	_expect(not game.catalog_fx.is_empty() and bool(game.catalog_fx.back().get("reduced", false)), "reduced_effect_marker")
	_expect(game.catalog_art_director.shake_offset(game.catalog_fx.back(), game.elapsed) == Vector2.ZERO, "reduced_no_shake")
	_expect(game.impact_strength <= 0.28 and bool(game.state.reduced_effects), "reduced_impact_and_state")
	game.reduced_effects_enabled = false


func _has_button(label: String) -> bool:
	for button in game.buttons:
		if button.text == label:
			return true
	return false


func _occupied(candidate_board: Array) -> int:
	var count := 0
	for row in candidate_board:
		for value in row:
			count += 1 if int(value) > 0 else 0
	return count


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
