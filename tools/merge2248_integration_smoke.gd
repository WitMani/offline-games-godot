extends SceneTree

const MODEL = preload("res://models/merge2248_model.gd")

var failures: Array[String] = []
var assertions := 0
var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.merge2248_persistence_enabled = false
	game.merge2248_reduced_effects_override = false
	root.add_child(game)
	await process_frame
	game._open_game("merge2248")
	_test_entry_and_controls()
	_test_direct_action_and_undo()
	_test_mouse_touch_parity()
	_test_observed_modes()
	_test_endless_and_reduced_effects()
	print("MERGE2248_INTEGRATION_SMOKE=%d" % assertions)
	print("MERGE2248_INTEGRATION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _test_entry_and_controls() -> void:
	_expect(game.state.board.size() == 8 and game.state.board[0].size() == 5, "entry_board")
	_expect(str(game.state.merge2248.board_encoding) == "power_of_two_exponents", "entry_encoding")
	_expect(str(game.state.mode) == MODEL.MODE_EASY and bool(game.state.mode_evidence_verified), "entry_easy_verified")
	_expect(game.buttons.size() == 4, "home_restart_mode_undo_controls")
	var labels: Array[String] = []
	for button in game.buttons:
		labels.append(str(button.text))
	_expect("首页" in labels and "重开" in labels and "撤销" in labels, "core_control_labels")
	_expect(labels.any(func(label: String) -> bool: return label.begins_with("难度")), "mode_control_label")
	var before_direction: Array = game.state.board.duplicate(true)
	game._direction_input(Vector2i.LEFT)
	_expect(game.state.board == before_direction, "direction_key_is_inert")
	_expect(game._merge2248_feedback_grade(2, 2) == 1, "juice_grade_light")
	_expect(game._merge2248_feedback_grade(3, 3) == 2, "juice_grade_combo")
	_expect(game._merge2248_feedback_grade(5, 4) == 3, "juice_grade_super")
	_expect(game._merge2248_feedback_grade(8, 5) == 4, "juice_grade_legendary")


func _test_direct_action_and_undo() -> void:
	_prepare_fixture(81, MODEL.MODE_EASY)
	var first: Vector2 = game._merge2248_cell_center(Vector2i(0, 7))
	var second: Vector2 = game._merge2248_cell_center(Vector2i(1, 7))
	_expect(game._merge2248_begin_at(first), "pointer_begin")
	game._merge2248_extend_at(second)
	_expect(game.merge2248_model.selected.size() == 2, "pointer_extend")
	game._merge2248_release()
	_expect(int(game.state.moves) == 1 and str(game.state.score) == "4", "release_sync")
	_expect(str(game.state.score_label) == "4" and bool(game.state.can_undo), "score_label_and_undo_sync")
	_expect(not game.merge2248_fx.is_empty() and int(game.merge2248_fx[-1].grade) == 1, "release_juice_grade")
	_expect(int(game.merge2248_fx[-1].result_power) == 2 and str(game.merge2248_fx[-1].result_label) == "4", "effect_uses_authoritative_power")
	game._merge2248_undo()
	_expect(int(game.state.moves) == 0 and str(game.state.score) == "0", "undo_sync")
	_expect(not bool(game.state.can_undo), "undo_consumed")


func _test_mouse_touch_parity() -> void:
	_prepare_fixture(313, MODEL.MODE_EASY)
	var first: Vector2 = game._merge2248_cell_center(Vector2i(0, 7))
	var second: Vector2 = game._merge2248_cell_center(Vector2i(1, 7))
	var mouse_press := InputEventMouseButton.new()
	mouse_press.button_index = MOUSE_BUTTON_LEFT
	mouse_press.pressed = true
	mouse_press.position = first
	game._gui_input(mouse_press)
	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.position = second
	game._gui_input(mouse_motion)
	var mouse_release := InputEventMouseButton.new()
	mouse_release.button_index = MOUSE_BUTTON_LEFT
	mouse_release.pressed = false
	mouse_release.position = second
	game._gui_input(mouse_release)
	var mouse_state: Dictionary = game.merge2248_model.serialize()
	_expect(int(game.state.moves) == 1, "mouse_action_committed")

	_prepare_fixture(313, MODEL.MODE_EASY)
	var touch_press := InputEventScreenTouch.new()
	touch_press.pressed = true
	touch_press.position = first
	game._unhandled_input(touch_press)
	var touch_drag := InputEventScreenDrag.new()
	touch_drag.position = second
	game._unhandled_input(touch_drag)
	var touch_release := InputEventScreenTouch.new()
	touch_release.pressed = false
	touch_release.position = second
	game._unhandled_input(touch_release)
	var touch_state: Dictionary = game.merge2248_model.serialize()
	_expect(int(game.state.moves) == 1, "touch_action_committed")
	_expect(touch_state == mouse_state, "mouse_touch_authoritative_parity")


func _test_observed_modes() -> void:
	_prepare_fixture(91, MODEL.MODE_EASY)
	game._merge2248_cycle_mode()
	_expect(game.merge2248_model.mode == MODEL.MODE_HARD and game.state.board.size() == 6, "hard_mode_5x6")
	_expect(bool(game.state.mode_evidence_verified), "hard_mode_verified_flag")
	game._merge2248_cycle_mode()
	_expect(game.merge2248_model.mode == MODEL.MODE_EASY and game.state.board.size() == 8, "easy_mode_5x8")
	_expect(bool(game.state.mode_evidence_verified), "easy_mode_verified_flag")


func _test_endless_and_reduced_effects() -> void:
	_prepare_fixture(2048, MODEL.MODE_EASY)
	game.merge2248_model.board[7][0] = 10
	game.merge2248_model.board[7][1] = 10
	game.merge2248_model.board[0][4] = 1
	game.merge2248_model.board[1][4] = 1
	game._sync_merge2248_state()
	var first: Vector2 = game._merge2248_cell_center(Vector2i(0, 7))
	var second: Vector2 = game._merge2248_cell_center(Vector2i(1, 7))
	_expect(game._merge2248_begin_at(first), "endless_begin")
	game._merge2248_extend_at(second)
	game._merge2248_release()
	_expect(str(game.state.status) == MODEL.RUNNING, "2048_stays_playing_integration")
	_expect(int(game.merge2248_fx[-1].result_power) == 11, "2048_power_effect")

	_prepare_fixture(777, MODEL.MODE_EASY)
	game.merge2248_reduced_effects_override = false
	game._sync_merge2248_state()
	game._merge2248_begin_at(first)
	game._merge2248_extend_at(second)
	game._merge2248_release()
	var normal_rules: Dictionary = game.merge2248_model.serialize()
	_expect(not bool(game.merge2248_fx[-1].reduced_effects), "normal_effect_route")
	game.elapsed += 0.04
	var normal_transform: Transform2D = game._merge2248_board_juice_transform(game._merge2248_board_rect())
	_expect(normal_transform != Transform2D.IDENTITY, "normal_board_property_animation")

	_prepare_fixture(777, MODEL.MODE_EASY)
	game.merge2248_reduced_effects_override = true
	game._sync_merge2248_state()
	game._merge2248_begin_at(first)
	game._merge2248_extend_at(second)
	game._merge2248_release()
	var reduced_rules: Dictionary = game.merge2248_model.serialize()
	_expect(bool(game.state.reduced_effects) and bool(game.merge2248_fx[-1].reduced_effects), "reduced_effect_route")
	_expect(game._merge2248_shake_offset() == Vector2.ZERO, "reduced_no_shake")
	_expect(game._merge2248_board_juice_transform(game._merge2248_board_rect()) == Transform2D.IDENTITY, "reduced_no_property_motion")
	_expect(reduced_rules == normal_rules, "reduced_rules_identical")
	_expect(float(game.merge2248_fx[-1].duration) <= 0.44, "reduced_duration_bounded")
	game.merge2248_reduced_effects_override = false


func _prepare_fixture(seed_value: int, mode: String) -> void:
	game.merge2248_model.reset(seed_value, mode, false)
	game.merge2248_model.board = _fixture_board(game.merge2248_model.height)
	game.merge2248_drag_active = false
	game.merge2248_fx.clear()
	game.merge2248_chain_grade = 0
	game.merge2248_juice_grade = 0
	game._sync_merge2248_state()


func _fixture_board(rows: int) -> Array:
	var board: Array = []
	for y in range(rows):
		var row: Array[int] = []
		for x in range(5):
			row.append(y * 5 + x + 1)
		board.append(row)
	board[rows - 1][0] = 1
	board[rows - 1][1] = 1
	return board


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
