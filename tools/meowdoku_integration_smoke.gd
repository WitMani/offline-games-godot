extends SceneTree

var failures: Array[String] = []
var probes := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Control = load("res://main.tscn").instantiate()
	game.meowdoku_recovery_enabled = false
	root.add_child(game)
	await process_frame
	game._open_game("meowdoku")
	await process_frame
	_expect(game.game_id == "meowdoku" and game.state.puzzle_id == "notebook_5", "entry_identity")
	_expect(int(game.state.size) == 5 and game.state.regions.size() == 5, "entry_topology")
	_expect(int(game.state.hearts) == 3 and int(game.state.required) == 5, "entry_hud_state")
	_expect(game.buttons.size() == 5, "meowdoku_controls")
	_expect(not game.state.has("board") and not game.state.has("solution"), "no_numeric_sudoku_state")

	var first: Vector2i = game.meowdoku_model.solution[0]
	var first_position: Vector2 = game._meowdoku_cell_center(first)
	var select_result: Dictionary = game._meowdoku_pointer_action(first_position, false)
	_expect(select_result.event == "select" and game.meowdoku_model.selected == first, "pointer_select")
	var mark_result: Dictionary = game._meowdoku_pointer_action(first_position, false)
	_expect(mark_result.event == "mark" and first in game.meowdoku_model.manual_marks, "second_pointer_marks")
	var cat_result: Dictionary = game._meowdoku_pointer_action(first_position, true)
	_expect(cat_result.event == "cat" and first in game.meowdoku_model.cats, "pointer_double_cat")
	_expect(first not in game.meowdoku_model.manual_marks, "cat_clears_manual_mark")

	game._reset_current()
	first = game.meowdoku_model.solution[0]
	first_position = game._meowdoku_cell_center(first)
	var mouse_press := InputEventMouseButton.new()
	mouse_press.button_index = MOUSE_BUTTON_LEFT
	mouse_press.position = first_position
	mouse_press.pressed = true
	mouse_press.double_click = true
	game._gui_input(mouse_press)
	var mouse_release := InputEventMouseButton.new()
	mouse_release.button_index = MOUSE_BUTTON_LEFT
	mouse_release.position = first_position
	mouse_release.pressed = false
	game._gui_input(mouse_release)
	_expect(first in game.meowdoku_model.cats and game.meowdoku_model.cats.size() == 1, "mouse_double_routing_once")

	# A browser reports the first click before tagging the second press as a
	# double-click. The preliminary same-cell mark must be rolled back so the
	# physical gesture maps to exactly one cat attempt.
	game._reset_current()
	var wrong := Vector2i.ZERO
	if wrong in game.meowdoku_model.solution:
		wrong = Vector2i(1, 0)
	var wrong_position: Vector2 = game._meowdoku_cell_center(wrong)
	game._meowdoku_pointer_action(wrong_position, false)
	_mouse_action(game, wrong_position, false)
	_mouse_action(game, wrong_position, true)
	_expect(int(game.state.hearts) == 2, "browser_mouse_double_attempt_once")
	_expect(game.state.manual_marks.is_empty() and int(game.state.moves) == 0, "browser_mouse_double_atomic")

	game._reset_current()
	first = game.meowdoku_model.solution[0]
	first_position = game._meowdoku_cell_center(first)
	var touch_press := InputEventScreenTouch.new()
	touch_press.position = first_position
	touch_press.pressed = true
	touch_press.double_tap = true
	game._unhandled_input(touch_press)
	var touch_release := InputEventScreenTouch.new()
	touch_release.position = first_position
	touch_release.pressed = false
	game._unhandled_input(touch_release)
	_expect(first in game.meowdoku_model.cats and game.meowdoku_model.cats.size() == 1, "touch_double_routing_once")

	game._reset_current()
	wrong = Vector2i.ZERO
	if wrong in game.meowdoku_model.solution:
		wrong = Vector2i(1, 0)
	wrong_position = game._meowdoku_cell_center(wrong)
	game._meowdoku_pointer_action(wrong_position, false)
	_touch_action(game, wrong_position, false)
	_touch_action(game, wrong_position, true)
	_expect(int(game.state.hearts) == 2, "browser_touch_double_attempt_once")
	_expect(game.state.manual_marks.is_empty() and int(game.state.moves) == 0, "browser_touch_double_atomic")

	game._reset_current()
	first = game.meowdoku_model.solution[0]
	game._meowdoku_command("select", first)
	game._input(_key(KEY_ENTER))
	_expect(first in game.meowdoku_model.cats, "keyboard_cat_parity")
	var second: Vector2i = game.meowdoku_model.solution[1]
	game._meowdoku_command("select", second)
	game._input(_key(KEY_X))
	_expect(second in game.meowdoku_model.manual_marks, "keyboard_mark_parity")
	game._input(_key(KEY_DELETE))
	_expect(second not in game.meowdoku_model.manual_marks, "keyboard_erase_parity")
	game._meowdoku_command("select", Vector2i.ZERO)
	game._input(_key(KEY_LEFT))
	game._input(_key(KEY_UP))
	_expect(game.meowdoku_model.selected == Vector2i.ZERO, "keyboard_navigation_clamps")
	game._input(_key(KEY_RIGHT))
	_expect(game.meowdoku_model.selected == Vector2i.RIGHT, "keyboard_navigation_moves")

	game._reset_current()
	wrong = Vector2i.ZERO
	if wrong in game.meowdoku_model.solution:
		wrong = Vector2i(1, 0)
	for expected_hearts in [2, 1, 0]:
		var error: Dictionary = game._meowdoku_command("cat", wrong)
		_expect(int(game.state.hearts) == expected_hearts, "integration_heart_%d" % expected_hearts)
		_expect(error.event == ("loss" if expected_hearts == 0 else "error"), "integration_error_event_%d" % expected_hearts)
	_expect(game.state.status == "lost", "integration_loss")
	var locked_cats: Array = game.meowdoku_model.cats.duplicate()
	game._meowdoku_command("cat", game.meowdoku_model.solution[0])
	_expect(game.meowdoku_model.cats == locked_cats, "integration_loss_lock")
	game._reset_current()
	_expect(game.state.status == "playing" and int(game.state.hearts) == 3, "integration_restart")

	first = game.meowdoku_model.solution[0]
	game._meowdoku_command("cat", first)
	game._meowdoku_command("select", Vector2i(2, 2))
	var checkpoint: Dictionary = game.meowdoku_model.checkpoint()
	game._reset_current()
	_expect(game._meowdoku_restore_checkpoint(checkpoint).ok, "integration_restore")
	_expect(first in game.meowdoku_model.cats and game.state.selected == [2, 2], "integration_restore_state")
	var atomic_before: Dictionary = game.meowdoku_model.checkpoint()
	var invalid_checkpoint: Dictionary = checkpoint.duplicate(true)
	invalid_checkpoint.puzzle_id = "wrong"
	_expect(not game._meowdoku_restore_checkpoint(invalid_checkpoint).ok, "integration_restore_reject")
	_expect(game.meowdoku_model.checkpoint() == atomic_before, "integration_restore_atomic")

	game._reset_current()
	for cell in game.meowdoku_model.solution:
		game._meowdoku_command("cat", cell)
	_expect(game.state.status == "won" and int(game.state.placed) == int(game.state.required), "integration_completion")

	game._open_game("sudoku")
	await process_frame
	_expect(game.state.board.size() == 9 and game.state.solution.size() == 9, "classic_sudoku_board_retained")
	game.state.selected = [2, 0]
	var classic_solution: Array = game.state.solution
	game._sudoku_place(int(classic_solution[0][2]))
	_expect(int(game.state.board[0][2]) == int(classic_solution[0][2]), "classic_sudoku_input_retained")

	print("MEOWDOKU_INTEGRATION_SMOKE=%d" % probes)
	print("MEOWDOKU_INTEGRATION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	game.free()
	quit(0 if failures.is_empty() else 1)


func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event


func _mouse_action(game: Control, position: Vector2, double_action: bool) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = position
	press.pressed = true
	press.double_click = double_action
	game._gui_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = position
	release.pressed = false
	game._gui_input(release)


func _touch_action(game: Control, position: Vector2, double_action: bool) -> void:
	var press := InputEventScreenTouch.new()
	press.position = position
	press.pressed = true
	press.double_tap = double_action
	game._unhandled_input(press)
	var release := InputEventScreenTouch.new()
	release.position = position
	release.pressed = false
	game._unhandled_input(release)


func _expect(condition: bool, label: String) -> void:
	probes += 1
	if not condition:
		failures.append(label)
