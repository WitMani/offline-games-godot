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
	_test_generated_contract()
	_test_pointer_and_button_place()
	_test_wrong_retention_and_keyboard_erase()
	_test_notes_hint_and_undo_controls()
	_test_keyboard_selection()
	_test_restart_and_recovery()
	_test_reduced_effects_contract()
	_test_legal_completion()
	_test_meowdoku_isolation()
	print("SUDOKU_RUNTIME_SMOKE=%d" % assertions)
	print("SUDOKU_RUNTIME_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _open() -> void:
	game._open_game("sudoku")
	game.has_transitioned = false


func _test_generated_contract() -> void:
	_open()
	_expect(game.sudoku_model.is_valid_solution(game.state.solution), "runtime_solution_valid")
	_expect(game.sudoku_model.count_solutions(game.state.given, 2) == 1, "runtime_puzzle_unique")
	_expect(_given_count(game.state.given) == 36, "runtime_givens_36")
	_expect(game.state.puzzle_fingerprint == game.sudoku_model.puzzle_fingerprint(game.state.given), "runtime_fingerprint")


func _test_pointer_and_button_place() -> void:
	_open()
	var cell := _find_cell(game.state.given, false)
	game._sudoku_tap(game.logic_game_presenter.cell_center(cell))
	_expect(game.state.selected == [cell.x, cell.y], "pointer_select")
	var value := int(game.state.solution[cell.y][cell.x])
	var digit := game.get_node_or_null("SudokuDigit%d" % value) as Button
	_expect(digit != null, "digit_button_exists")
	if digit:
		digit.pressed.emit()
	_expect(int(game.state.board[cell.y][cell.x]) == value, "button_place")
	_expect(not bool(game.state.wrong[cell.y][cell.x]) and int(game.state.moves) == 1, "button_place_semantics")


func _test_wrong_retention_and_keyboard_erase() -> void:
	_open()
	var cell := _find_cell(game.state.given, false)
	game._sudoku_tap(game.logic_game_presenter.cell_center(cell))
	var wrong_value := (int(game.state.solution[cell.y][cell.x]) % 9) + 1
	_key(KEY_0 + wrong_value)
	_expect(int(game.state.board[cell.y][cell.x]) == wrong_value, "keyboard_wrong_retained")
	_expect(bool(game.state.wrong[cell.y][cell.x]), "keyboard_wrong_marked")
	_expect(int(game.state.mistakes) == 1 and int(game.state.moves) == 1, "keyboard_wrong_counters")
	_key(KEY_BACKSPACE)
	_expect(int(game.state.board[cell.y][cell.x]) == 0, "keyboard_erase")
	_expect(not bool(game.state.wrong[cell.y][cell.x]) and int(game.state.moves) == 2, "keyboard_erase_semantics")


func _test_notes_hint_and_undo_controls() -> void:
	_open()
	var cell := _find_cell(game.state.given, false)
	game._sudoku_tap(game.logic_game_presenter.cell_center(cell))
	var notes_button := game.get_node_or_null("SudokuNotes") as Button
	var hint_button := game.get_node_or_null("SudokuHint") as Button
	var undo_button := game.get_node_or_null("SudokuUndo") as Button
	_expect(notes_button != null and hint_button != null and undo_button != null, "tool_buttons_exist")
	if notes_button:
		notes_button.pressed.emit()
	var value := int(game.state.solution[cell.y][cell.x])
	_key(KEY_0 + value)
	_expect(bool(game.state.notes_mode), "notes_mode_enabled")
	_expect((int(game.state.notes[cell.y][cell.x]) & (1 << value)) != 0, "keyboard_note_added")
	if notes_button:
		notes_button.pressed.emit()
	if hint_button:
		hint_button.pressed.emit()
	_expect(int(game.state.board[cell.y][cell.x]) == value, "hint_places_value")
	_expect(int(game.state.hints_remaining) == 2 and int(game.state.notes[cell.y][cell.x]) == 0, "hint_budget_and_note_clear")
	if undo_button:
		undo_button.pressed.emit()
	_expect(int(game.state.board[cell.y][cell.x]) == 0, "button_undo_hint")
	_expect(int(game.state.hints_remaining) == 3, "button_undo_hint_budget")
	_key(KEY_Z, true)
	_expect((int(game.state.notes[cell.y][cell.x]) & (1 << value)) == 0, "keyboard_undo_note")


func _test_keyboard_selection() -> void:
	_open()
	var start := Vector2i(4, 4)
	game._sudoku_tap(game.logic_game_presenter.cell_center(start))
	_key(KEY_RIGHT)
	_expect(game.state.selected == [5, 4], "keyboard_select_right")
	_key(KEY_DOWN)
	_expect(game.state.selected == [5, 5], "keyboard_select_down")
	_key(KEY_LEFT)
	_key(KEY_UP)
	_expect(game.state.selected == [4, 4], "keyboard_selection_roundtrip")


func _test_restart_and_recovery() -> void:
	_open()
	var fingerprint := str(game.state.puzzle_fingerprint)
	var cell := _find_cell(game.state.given, false)
	game._sudoku_tap(game.logic_game_presenter.cell_center(cell))
	var wrong_value := (int(game.state.solution[cell.y][cell.x]) % 9) + 1
	_key(KEY_0 + wrong_value)
	var saved: Dictionary = game.state.duplicate(true)
	game._reset_current()
	_expect(game.state.board == game.state.given, "restart_clears_board")
	_expect(int(game.state.mistakes) == 0 and int(game.state.moves) == 0, "restart_clears_counters")
	_expect(str(game.state.puzzle_fingerprint) == fingerprint, "restart_same_puzzle_contract")
	_expect(game._restore_sudoku_snapshot(saved), "runtime_restore_accepts_valid")
	_expect(int(game.state.board[cell.y][cell.x]) == wrong_value and bool(game.state.wrong[cell.y][cell.x]), "runtime_restore_wrong_state")
	var corrupt := saved.duplicate(true)
	corrupt["given"][0][0] = 10
	_expect(not game._restore_sudoku_snapshot(corrupt), "runtime_restore_rejects_corrupt")


func _test_legal_completion() -> void:
	_open()
	var cell := _find_cell(game.sudoku_model.given, false)
	game.sudoku_model.board = game.sudoku_model.solution.duplicate(true)
	game.sudoku_model.board[cell.y][cell.x] = 0
	game.sudoku_model.wrong = _bool_grid(false)
	game.sudoku_model.notes = _int_grid(0)
	game.sudoku_model.history.clear()
	game.sudoku_model.status = "playing"
	game.sudoku_model.moves = 0
	game.sudoku_model.select(cell)
	game._sync_sudoku_state()
	game._sudoku_place(int(game.state.solution[cell.y][cell.x]))
	_expect(str(game.state.status) == "won", "runtime_complete_status")
	_expect(game._sudoku_complete() and game.sudoku_model.is_valid_solution(game.state.board), "runtime_complete_legal")
	_expect(str(game.catalog_fx.back().kind) == "logic_complete", "runtime_complete_semantic")


func _test_reduced_effects_contract() -> void:
	_open()
	game.sudoku_reduced_effects = true
	game._sync_sudoku_state()
	var cell := _find_cell(game.state.given, false)
	game.sudoku_model.select(cell)
	game._sync_sudoku_state()
	var wrong_value := (int(game.state.solution[cell.y][cell.x]) % 9) + 1
	game._sudoku_place(wrong_value)
	_expect(bool(game.state.reduced_effects), "reduced_state_exposed")
	_expect(game._catalog_shake_offset() == Vector2.ZERO, "reduced_no_camera_shake")
	_expect(game._catalog_result_overlay_ready(), "reduced_no_overlay_delay")
	_expect(int(game.state.board[cell.y][cell.x]) == wrong_value and bool(game.state.wrong[cell.y][cell.x]), "reduced_state_consequence")
	game.sudoku_reduced_effects = false


func _test_meowdoku_isolation() -> void:
	game._open_game("meowdoku")
	_expect(str(game.game_id) == "meowdoku", "meowdoku_open")
	_expect(_given_count(game.state.given) == 54, "meowdoku_legacy_unchanged")
	_expect(not game.state.has("notes"), "meowdoku_no_sudoku_v3_state")


func _key(keycode: Key, ctrl := false) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	event.ctrl_pressed = ctrl
	game._input(event)


func _find_cell(given: Array, want_given: bool) -> Vector2i:
	for y in range(9):
		for x in range(9):
			if (int(given[y][x]) != 0) == want_given:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func _given_count(grid: Array) -> int:
	var count := 0
	for row in grid:
		for value in row:
			if int(value) != 0:
				count += 1
	return count


func _int_grid(value: int) -> Array:
	var grid: Array = []
	for _y in range(9):
		grid.append([value, value, value, value, value, value, value, value, value])
	return grid


func _bool_grid(value: bool) -> Array:
	var grid: Array = []
	for _y in range(9):
		grid.append([value, value, value, value, value, value, value, value, value])
	return grid


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
