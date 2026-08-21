class_name SudokuModel
extends RefCounted

## Renderer-free Sudoku rules for the catalog's classic Sudoku entry.
##
## The model owns every gameplay mutation. Presentation code may consume the
## semantic event dictionaries and snapshots, but must not infer completion or
## correctness from a merely full board.

const SIZE := 9
const BOX := 3
const FULL_MASK := 0x3FE # Bits 1 through 9.
const PLAYING := "playing"
const WON := "won"
const MAX_HINTS := 3
const DEFAULT_GIVENS := 36

var board: Array = []
var solution: Array = []
var given: Array = []
var notes: Array = []
var wrong: Array = []
var selected := Vector2i(0, 0)
var notes_mode := false
var hints_remaining := MAX_HINTS
var mistakes := 0
var moves := 0
var score := 0
var status := PLAYING
var seed := 0
var history: Array[Dictionary] = []

var _initial_board: Array = []
var _rng := RandomNumberGenerator.new()


func reset(seed_value: int = 20260820, target_givens: int = DEFAULT_GIVENS) -> void:
	seed = seed_value
	_rng.seed = seed_value
	solution = _build_solution()
	board = _carve_unique_puzzle(solution, clampi(target_givens, 24, 60))
	given = board.duplicate(true)
	_initial_board = board.duplicate(true)
	notes = _int_grid(0)
	wrong = _bool_grid(false)
	selected = _first_editable_cell()
	notes_mode = false
	hints_remaining = MAX_HINTS
	mistakes = 0
	moves = 0
	score = 0
	status = PLAYING
	history.clear()


func select(cell: Vector2i) -> Dictionary:
	if status != PLAYING or not _in_bounds(cell):
		return _event("ignored", false, {"reason":"selection_unavailable"})
	var changed := selected != cell
	selected = cell
	return _event("selected", changed)


func move_selection(direction: Vector2i) -> Dictionary:
	if status != PLAYING:
		return _event("ignored", false, {"reason":"selection_unavailable"})
	var target := Vector2i(
		clampi(selected.x + direction.x, 0, SIZE - 1),
		clampi(selected.y + direction.y, 0, SIZE - 1)
	)
	return select(target)


func toggle_notes_mode() -> Dictionary:
	if status != PLAYING:
		return _event("ignored", false, {"reason":"game_finished"})
	notes_mode = not notes_mode
	return _event("notes_mode", true, {"enabled":notes_mode})


func place(value: int) -> Dictionary:
	if status != PLAYING:
		return _event("ignored", false, {"reason":"game_finished"})
	if value < 1 or value > 9:
		return _event("ignored", false, {"reason":"value_out_of_range"})
	if not _selected_is_editable():
		return _event("ignored", false, {"reason":"given"})
	if notes_mode:
		return _toggle_note(value)
	var x := selected.x
	var y := selected.y
	if int(board[y][x]) == value and int(notes[y][x]) == 0:
		return _event("ignored", false, {"reason":"unchanged"})
	var completed_before := block_complete(_block_index(selected))
	_push_history()
	board[y][x] = value
	notes[y][x] = 0
	var is_correct := value == int(solution[y][x])
	wrong[y][x] = not is_correct
	moves += 1
	if not is_correct:
		mistakes += 1
		return _event("error", true, {"value":value, "correct_value":int(solution[y][x])})
	_remove_peer_note(selected, value)
	return _finish_correct_action("place", completed_before, value)


func erase() -> Dictionary:
	if status != PLAYING:
		return _event("ignored", false, {"reason":"game_finished"})
	if not _selected_is_editable():
		return _event("ignored", false, {"reason":"given"})
	var x := selected.x
	var y := selected.y
	if int(board[y][x]) == 0 and int(notes[y][x]) == 0:
		return _event("ignored", false, {"reason":"empty"})
	_push_history()
	board[y][x] = 0
	notes[y][x] = 0
	wrong[y][x] = false
	moves += 1
	return _event("erase", true)


func hint() -> Dictionary:
	if status != PLAYING:
		return _event("ignored", false, {"reason":"game_finished"})
	if hints_remaining <= 0:
		return _event("ignored", false, {"reason":"no_hints"})
	if not _selected_is_editable():
		return _event("ignored", false, {"reason":"given"})
	var x := selected.x
	var y := selected.y
	var value := int(solution[y][x])
	if int(board[y][x]) == value and not bool(wrong[y][x]):
		return _event("ignored", false, {"reason":"already_solved"})
	var completed_before := block_complete(_block_index(selected))
	_push_history()
	board[y][x] = value
	notes[y][x] = 0
	wrong[y][x] = false
	hints_remaining -= 1
	moves += 1
	_remove_peer_note(selected, value)
	return _finish_correct_action("hint", completed_before, value)


func undo() -> Dictionary:
	if history.is_empty():
		return _event("ignored", false, {"reason":"history_empty"})
	var previous: Dictionary = history.pop_back()
	_restore_mutable(previous)
	return _event("undo", true)


func restart() -> Dictionary:
	board = _initial_board.duplicate(true)
	notes = _int_grid(0)
	wrong = _bool_grid(false)
	selected = _first_editable_cell()
	notes_mode = false
	hints_remaining = MAX_HINTS
	mistakes = 0
	moves = 0
	score = 0
	status = PLAYING
	history.clear()
	return _event("restart", true)


func block_complete(block_index: int) -> bool:
	if block_index < 0 or block_index >= SIZE or not _is_grid(board) or not _is_grid(solution):
		return false
	var start_x := (block_index % BOX) * BOX
	var start_y := int(block_index / BOX) * BOX
	for y in range(start_y, start_y + BOX):
		for x in range(start_x, start_x + BOX):
			if int(board[y][x]) != int(solution[y][x]):
				return false
	return true


func is_complete() -> bool:
	return board == solution and is_valid_solution(board)


func count_solutions(grid: Array, limit: int = 2) -> int:
	if limit <= 0 or not _is_grid(grid):
		return 0
	var working := grid.duplicate(true)
	var row_masks: Array[int] = []
	var col_masks: Array[int] = []
	var box_masks: Array[int] = []
	row_masks.resize(SIZE)
	col_masks.resize(SIZE)
	box_masks.resize(SIZE)
	for y in range(SIZE):
		for x in range(SIZE):
			var value := int(working[y][x])
			if value < 0 or value > 9:
				return 0
			if value == 0:
				continue
			var bit := 1 << value
			var box_index := int(y / BOX) * BOX + int(x / BOX)
			if (row_masks[y] & bit) != 0 or (col_masks[x] & bit) != 0 or (box_masks[box_index] & bit) != 0:
				return 0
			row_masks[y] |= bit
			col_masks[x] |= bit
			box_masks[box_index] |= bit
	return _count_recursive(working, row_masks, col_masks, box_masks, limit)


func is_valid_solution(grid: Array) -> bool:
	if not _is_grid(grid):
		return false
	for y in range(SIZE):
		var row_mask := 0
		var col_mask := 0
		for x in range(SIZE):
			var row_value := int(grid[y][x])
			var col_value := int(grid[x][y])
			if row_value < 1 or row_value > 9 or col_value < 1 or col_value > 9:
				return false
			row_mask |= 1 << row_value
			col_mask |= 1 << col_value
		if row_mask != FULL_MASK or col_mask != FULL_MASK:
			return false
	for block_index in range(SIZE):
		var mask := 0
		var start_x := (block_index % BOX) * BOX
		var start_y := int(block_index / BOX) * BOX
		for y in range(start_y, start_y + BOX):
			for x in range(start_x, start_x + BOX):
				mask |= 1 << int(grid[y][x])
		if mask != FULL_MASK:
			return false
	return true


func snapshot() -> Dictionary:
	return {
		"schema":"sudoku-state/v1",
		"board":board.duplicate(true),
		"solution":solution.duplicate(true),
		"given":given.duplicate(true),
		"notes":notes.duplicate(true),
		"wrong":wrong.duplicate(true),
		"selected":[selected.x, selected.y],
		"notes_mode":notes_mode,
		"hints_remaining":hints_remaining,
		"mistakes":mistakes,
		"moves":moves,
		"score":score,
		"status":status,
		"seed":seed,
		"puzzle_fingerprint":puzzle_fingerprint(given),
		"history_depth":history.size(),
	}


func restore(saved: Dictionary) -> bool:
	if str(saved.get("schema", "")) != "sudoku-state/v1":
		return false
	var saved_board: Variant = saved.get("board", null)
	var saved_solution: Variant = saved.get("solution", null)
	var saved_given: Variant = saved.get("given", null)
	var saved_notes: Variant = saved.get("notes", null)
	if not saved_board is Array or not saved_solution is Array or not saved_given is Array or not saved_notes is Array:
		return false
	if not _is_grid(saved_board) or not _is_grid(saved_solution) or not _is_grid(saved_given) or not _is_grid(saved_notes):
		return false
	if not is_valid_solution(saved_solution) or count_solutions(saved_given, 2) != 1:
		return false
	if str(saved.get("puzzle_fingerprint", "")) != puzzle_fingerprint(saved_given):
		return false
	for y in range(SIZE):
		for x in range(SIZE):
			var board_value := int(saved_board[y][x])
			var given_value := int(saved_given[y][x])
			var solution_value := int(saved_solution[y][x])
			var note_mask := int(saved_notes[y][x])
			if board_value < 0 or board_value > 9 or given_value < 0 or given_value > 9:
				return false
			if given_value != 0 and (given_value != solution_value or board_value != given_value):
				return false
			if note_mask < 0 or (note_mask & ~FULL_MASK) != 0:
				return false
			if note_mask != 0 and (given_value != 0 or board_value != 0):
				return false
	var selected_value: Variant = saved.get("selected", [])
	if not selected_value is Array or selected_value.size() != 2:
		return false
	var saved_selected := Vector2i(int(selected_value[0]), int(selected_value[1]))
	if not _in_bounds(saved_selected):
		return false
	var saved_status := str(saved.get("status", PLAYING))
	if saved_status != PLAYING and saved_status != WON:
		return false
	if saved_status == WON and (saved_board != saved_solution or not is_valid_solution(saved_board)):
		return false
	if saved_status == PLAYING and saved_board == saved_solution:
		return false
	var saved_hints := int(saved.get("hints_remaining", -1))
	var saved_mistakes := int(saved.get("mistakes", -1))
	var saved_moves := int(saved.get("moves", -1))
	var saved_score := int(saved.get("score", -1))
	if saved_hints < 0 or saved_hints > MAX_HINTS or saved_mistakes < 0 or saved_moves < 0 or saved_score < 0:
		return false
	board = saved_board.duplicate(true)
	solution = saved_solution.duplicate(true)
	given = saved_given.duplicate(true)
	_initial_board = given.duplicate(true)
	notes = saved_notes.duplicate(true)
	wrong = _bool_grid(false)
	for y in range(SIZE):
		for x in range(SIZE):
			wrong[y][x] = int(board[y][x]) != 0 and int(board[y][x]) != int(solution[y][x])
	selected = saved_selected
	notes_mode = bool(saved.get("notes_mode", false))
	hints_remaining = saved_hints
	mistakes = saved_mistakes
	moves = saved_moves
	score = saved_score
	status = saved_status
	seed = int(saved.get("seed", 0))
	history.clear()
	return true


func puzzle_fingerprint(grid: Array) -> String:
	if not _is_grid(grid):
		return ""
	var parts: PackedStringArray = []
	for row in grid:
		for value in row:
			parts.append(str(int(value)))
	return "".join(parts).sha256_text()


func _finish_correct_action(action: String, completed_before: bool, value: int) -> Dictionary:
	if is_complete():
		status = WON
		score = maxi(100, 1000 - mistakes * 25)
		return _event("complete", true, {"action":action, "value":value, "score":score})
	var block_now := block_complete(_block_index(selected))
	if block_now and not completed_before:
		return _event("block_complete", true, {"action":action, "value":value})
	return _event("hint" if action == "hint" else "correct", true, {"action":action, "value":value})


func _toggle_note(value: int) -> Dictionary:
	var x := selected.x
	var y := selected.y
	if int(board[y][x]) != 0:
		return _event("ignored", false, {"reason":"cell_filled"})
	_push_history()
	var bit := 1 << value
	notes[y][x] = int(notes[y][x]) ^ bit
	moves += 1
	return _event("note", true, {"value":value, "enabled":(int(notes[y][x]) & bit) != 0})


func _remove_peer_note(cell: Vector2i, value: int) -> void:
	var bit := 1 << value
	for index in range(SIZE):
		notes[cell.y][index] = int(notes[cell.y][index]) & ~bit
		notes[index][cell.x] = int(notes[index][cell.x]) & ~bit
	var start_x := int(cell.x / BOX) * BOX
	var start_y := int(cell.y / BOX) * BOX
	for y in range(start_y, start_y + BOX):
		for x in range(start_x, start_x + BOX):
			notes[y][x] = int(notes[y][x]) & ~bit


func _push_history() -> void:
	history.append({
		"board":board.duplicate(true),
		"notes":notes.duplicate(true),
		"wrong":wrong.duplicate(true),
		"selected":selected,
		"notes_mode":notes_mode,
		"hints_remaining":hints_remaining,
		"mistakes":mistakes,
		"moves":moves,
		"score":score,
		"status":status,
	})
	if history.size() > 128:
		history.pop_front()


func _restore_mutable(previous: Dictionary) -> void:
	board = previous["board"].duplicate(true)
	notes = previous["notes"].duplicate(true)
	wrong = previous["wrong"].duplicate(true)
	selected = previous["selected"]
	notes_mode = bool(previous["notes_mode"])
	hints_remaining = int(previous["hints_remaining"])
	mistakes = int(previous["mistakes"])
	moves = int(previous["moves"])
	score = int(previous["score"])
	status = str(previous["status"])


func _event(kind: String, changed: bool, extra: Dictionary = {}) -> Dictionary:
	var event := {
		"kind":kind,
		"changed":changed,
		"cell":selected,
		"block":_block_index(selected),
		"status":status,
	}
	event.merge(extra, true)
	return event


func _build_solution() -> Array:
	var digits: Array[int] = []
	for value in range(1, SIZE + 1):
		digits.append(value)
	_shuffle(digits)
	var rows := _shuffled_line_order()
	var columns := _shuffled_line_order()
	var result: Array = []
	for row_index in rows:
		var row: Array[int] = []
		for column_index in columns:
			var pattern := (int(row_index) * BOX + int(int(row_index) / BOX) + int(column_index)) % SIZE
			row.append(digits[pattern])
		result.append(row)
	return result


func _shuffled_line_order() -> Array[int]:
	var groups: Array[int] = [0, 1, 2]
	_shuffle(groups)
	var result: Array[int] = []
	for group in groups:
		var lines: Array[int] = [0, 1, 2]
		_shuffle(lines)
		for line in lines:
			result.append(group * BOX + line)
	return result


func _carve_unique_puzzle(full_solution: Array, target_givens: int) -> Array:
	var puzzle := full_solution.duplicate(true)
	var cells: Array[int] = []
	for index in range(SIZE * SIZE):
		cells.append(index)
	_shuffle(cells)
	var givens_count := SIZE * SIZE
	for index in cells:
		if givens_count <= target_givens:
			break
		var x := index % SIZE
		var y := int(index / SIZE)
		var previous := int(puzzle[y][x])
		puzzle[y][x] = 0
		if count_solutions(puzzle, 2) == 1:
			givens_count -= 1
		else:
			puzzle[y][x] = previous
	return puzzle


func _count_recursive(grid: Array, row_masks: Array[int], col_masks: Array[int], box_masks: Array[int], limit: int) -> int:
	var best := Vector2i(-1, -1)
	var best_mask := 0
	var best_count := SIZE + 1
	for y in range(SIZE):
		for x in range(SIZE):
			if int(grid[y][x]) != 0:
				continue
			var box_index := int(y / BOX) * BOX + int(x / BOX)
			var mask := FULL_MASK & ~(row_masks[y] | col_masks[x] | box_masks[box_index])
			var candidate_count := _bit_count(mask)
			if candidate_count == 0:
				return 0
			if candidate_count < best_count:
				best = Vector2i(x, y)
				best_mask = mask
				best_count = candidate_count
				if candidate_count == 1:
					break
		if best_count == 1:
			break
	if best.x < 0:
		return 1
	var total := 0
	var box_index := int(best.y / BOX) * BOX + int(best.x / BOX)
	for value in range(1, SIZE + 1):
		var bit := 1 << value
		if (best_mask & bit) == 0:
			continue
		grid[best.y][best.x] = value
		row_masks[best.y] |= bit
		col_masks[best.x] |= bit
		box_masks[box_index] |= bit
		total += _count_recursive(grid, row_masks, col_masks, box_masks, limit - total)
		row_masks[best.y] &= ~bit
		col_masks[best.x] &= ~bit
		box_masks[box_index] &= ~bit
		grid[best.y][best.x] = 0
		if total >= limit:
			return limit
	return total


func _bit_count(mask: int) -> int:
	var count := 0
	var value := mask
	while value != 0:
		value &= value - 1
		count += 1
	return count


func _shuffle(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := _rng.randi_range(0, index)
		var previous: Variant = values[index]
		values[index] = values[swap_index]
		values[swap_index] = previous


func _selected_is_editable() -> bool:
	return _in_bounds(selected) and int(given[selected.y][selected.x]) == 0


func _first_editable_cell() -> Vector2i:
	for y in range(SIZE):
		for x in range(SIZE):
			if int(given[y][x]) == 0:
				return Vector2i(x, y)
	return Vector2i.ZERO


func _block_index(cell: Vector2i) -> int:
	return int(cell.y / BOX) * BOX + int(cell.x / BOX)


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < SIZE and cell.y >= 0 and cell.y < SIZE


func _is_grid(value: Variant) -> bool:
	if not value is Array or value.size() != SIZE:
		return false
	for row in value:
		if not row is Array or row.size() != SIZE:
			return false
	return true


func _int_grid(value: int) -> Array:
	var result: Array = []
	for _y in range(SIZE):
		var row: Array[int] = []
		for _x in range(SIZE):
			row.append(value)
		result.append(row)
	return result


func _bool_grid(value: bool) -> Array:
	var result: Array = []
	for _y in range(SIZE):
		var row: Array[bool] = []
		for _x in range(SIZE):
			row.append(value)
		result.append(row)
	return result
