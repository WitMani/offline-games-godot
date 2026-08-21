extends SceneTree

const SudokuRules = preload("res://models/sudoku_model.gd")

var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	_test_generation_contract()
	_test_given_selection_and_immutability()
	_test_error_retention_and_undo()
	_test_notes_place_and_peer_cleanup()
	_test_hint_and_undo()
	_test_completion_legality()
	_test_restart_and_recovery()
	_test_invalid_restore_and_solution_counter()
	print("SUDOKU_MODEL_SMOKE=%d" % assertions)
	print("SUDOKU_MODEL_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _test_generation_contract() -> void:
	for seed in [31, 2248, 20260820, 991827]:
		var model = SudokuRules.new()
		model.reset(seed, 36)
		_expect(model.is_valid_solution(model.solution), "solution_valid_%d" % seed)
		_expect(model.count_solutions(model.given, 2) == 1, "puzzle_unique_%d" % seed)
		_expect(_given_count(model.given) == 36, "puzzle_givens_%d" % seed)
		_expect(_givens_match(model.given, model.solution), "givens_match_%d" % seed)
		var repeat = SudokuRules.new()
		repeat.reset(seed, 36)
		_expect(model.given == repeat.given and model.solution == repeat.solution, "seed_deterministic_%d" % seed)


func _test_given_selection_and_immutability() -> void:
	var model = _new_model()
	var cell := _find_cell(model.given, true)
	var before: Dictionary = model.snapshot()
	var selected: Dictionary = model.select(cell)
	var result: Dictionary = model.place((int(model.solution[cell.y][cell.x]) % 9) + 1)
	_expect(str(selected.kind) == "selected", "given_select_allowed")
	_expect(not bool(result.changed) and str(result.reason) == "given", "given_place_ignored")
	_expect(model.board == before.board, "given_board_immutable")
	_expect(model.moves == int(before.moves) and model.mistakes == int(before.mistakes), "given_counters_immutable")


func _test_error_retention_and_undo() -> void:
	var model = _new_model()
	var cell := _find_cell(model.given, false)
	model.select(cell)
	var wrong_value := (int(model.solution[cell.y][cell.x]) % 9) + 1
	var result: Dictionary = model.place(wrong_value)
	_expect(str(result.kind) == "error" and bool(result.changed), "wrong_event")
	_expect(int(model.board[cell.y][cell.x]) == wrong_value, "wrong_value_retained")
	_expect(bool(model.wrong[cell.y][cell.x]) and model.mistakes == 1 and model.moves == 1, "wrong_semantics")
	var undo: Dictionary = model.undo()
	_expect(str(undo.kind) == "undo" and int(model.board[cell.y][cell.x]) == 0, "wrong_undo_board")
	_expect(not bool(model.wrong[cell.y][cell.x]) and model.mistakes == 0 and model.moves == 0, "wrong_undo_counters")


func _test_notes_place_and_peer_cleanup() -> void:
	var model = _new_model()
	var cell := _find_cell(model.given, false)
	var peer := _find_empty_peer(model.given, cell)
	model.select(cell)
	_expect(bool(model.toggle_notes_mode().enabled), "notes_mode_on")
	var note_value := int(model.solution[cell.y][cell.x])
	var note_result: Dictionary = model.place(note_value)
	_expect(str(note_result.kind) == "note" and bool(note_result.enabled), "note_added")
	_expect((int(model.notes[cell.y][cell.x]) & (1 << note_value)) != 0, "note_bit_stored")
	model.select(peer)
	model.place(note_value)
	model.toggle_notes_mode()
	model.select(cell)
	var place_result: Dictionary = model.place(note_value)
	_expect(str(place_result.kind) in ["correct", "block_complete"], "final_place_after_note")
	_expect(int(model.notes[cell.y][cell.x]) == 0, "own_notes_cleared")
	_expect((int(model.notes[peer.y][peer.x]) & (1 << note_value)) == 0, "peer_note_cleared")


func _test_hint_and_undo() -> void:
	var model = _new_model()
	var cell := _find_cell(model.given, false)
	model.select(cell)
	var result: Dictionary = model.hint()
	_expect(str(result.kind) in ["hint", "block_complete"], "hint_event")
	_expect(int(model.board[cell.y][cell.x]) == int(model.solution[cell.y][cell.x]), "hint_places_solution")
	_expect(model.hints_remaining == 2 and model.moves == 1, "hint_budget")
	model.undo()
	_expect(int(model.board[cell.y][cell.x]) == 0, "hint_undo_board")
	_expect(model.hints_remaining == 3 and model.moves == 0, "hint_undo_budget")


func _test_completion_legality() -> void:
	var model = _new_model()
	var cell := _find_cell(model.given, false)
	model.board = model.solution.duplicate(true)
	model.board[cell.y][cell.x] = 0
	model.wrong = _bool_grid(false)
	model.notes = _int_grid(0)
	model.history.clear()
	model.moves = 0
	model.status = "playing"
	model.select(cell)
	var result: Dictionary = model.place(int(model.solution[cell.y][cell.x]))
	_expect(str(result.kind) == "complete" and model.status == "won", "complete_event")
	_expect(model.is_complete() and model.is_valid_solution(model.board), "complete_legality")
	_expect(model.score == 1000, "complete_score")
	model.undo()
	_expect(model.status == "playing" and int(model.board[cell.y][cell.x]) == 0, "complete_undo")


func _test_restart_and_recovery() -> void:
	var model = _new_model()
	var cell := _find_cell(model.given, false)
	model.select(cell)
	model.place((int(model.solution[cell.y][cell.x]) % 9) + 1)
	var saved: Dictionary = model.snapshot()
	var recovered = SudokuRules.new()
	_expect(recovered.restore(saved), "snapshot_restore")
	_expect(recovered.board == model.board and recovered.given == model.given, "recovery_board")
	_expect(recovered.selected == model.selected and recovered.mistakes == 1, "recovery_mutable_state")
	_expect(bool(recovered.wrong[cell.y][cell.x]), "recovery_recomputes_wrong")
	recovered.restart()
	_expect(recovered.board == recovered.given and recovered.mistakes == 0, "restart_board")
	_expect(recovered.hints_remaining == 3 and recovered.history.is_empty(), "restart_budget_history")


func _test_invalid_restore_and_solution_counter() -> void:
	var model = _new_model()
	var duplicate: Array = model.given.duplicate(true)
	duplicate[0][0] = int(model.solution[0][1])
	duplicate[0][1] = int(model.solution[0][1])
	_expect(model.count_solutions(duplicate, 2) == 0, "duplicate_rejected")
	_expect(model.count_solutions(_int_grid(0), 2) == 2, "multi_solution_cap")
	var corrupt: Dictionary = model.snapshot()
	corrupt["given"][0][0] = 10
	_expect(not SudokuRules.new().restore(corrupt), "corrupt_restore_rejected")
	var forged: Dictionary = model.snapshot()
	forged["puzzle_fingerprint"] = "forged"
	_expect(not SudokuRules.new().restore(forged), "fingerprint_restore_rejected")


func _new_model():
	var model = SudokuRules.new()
	model.reset(20260820, 36)
	return model


func _given_count(grid: Array) -> int:
	var count := 0
	for row in grid:
		for value in row:
			if int(value) != 0:
				count += 1
	return count


func _givens_match(given: Array, solution: Array) -> bool:
	for y in range(9):
		for x in range(9):
			if int(given[y][x]) != 0 and int(given[y][x]) != int(solution[y][x]):
				return false
	return true


func _find_cell(given: Array, want_given: bool) -> Vector2i:
	for y in range(9):
		for x in range(9):
			if (int(given[y][x]) != 0) == want_given:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func _find_empty_peer(given: Array, cell: Vector2i) -> Vector2i:
	for x in range(9):
		if x != cell.x and int(given[cell.y][x]) == 0:
			return Vector2i(x, cell.y)
	for y in range(9):
		if y != cell.y and int(given[y][cell.x]) == 0:
			return Vector2i(cell.x, y)
	return Vector2i(-1, -1)


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
