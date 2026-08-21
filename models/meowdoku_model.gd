class_name MeowdokuModel
extends RefCounted

## Renderer-independent clean-room model for the Oakever-style region-cat
## puzzle. The model owns rules and persistence only; it has no CanvasItem,
## sound, timing, or input-device dependency.

const PLAYING := "playing"
const WON := "won"
const LOST := "lost"
const MAX_HEARTS := 3
const INVALID_CELL := Vector2i(-1, -1)

var puzzle_id := ""
var level := 0
var size := 0
var regions: Array = []
var solution: Array[Vector2i] = []
var given_cats: Array[Vector2i] = []
var cats: Array[Vector2i] = []
var manual_marks: Array[Vector2i] = []
var selected := INVALID_CELL
var hearts := MAX_HEARTS
var mistakes := 0
var moves := 0
var status := PLAYING

var _loaded_spec: Dictionary = {}


static func fixture(fixture_id: String) -> Dictionary:
	match fixture_id:
		"notebook_5":
			return {
				"id":"notebook_5", "level":1, "size":5,
				"regions":[
					[3, 4, 2, 2, 2],
					[3, 4, 4, 2, 2],
					[3, 4, 1, 1, 2],
					[0, 4, 4, 1, 2],
					[0, 0, 0, 1, 1],
				],
				"solution":[Vector2i(4, 0), Vector2i(2, 1), Vector2i(0, 2), Vector2i(3, 3), Vector2i(1, 4)],
				"given_cats":[],
			}
		"ribbon_6":
			return {
				"id":"ribbon_6", "level":10, "size":6,
				"regions":[
					[0, 0, 5, 1, 1, 1],
					[0, 0, 5, 5, 5, 1],
					[0, 5, 5, 5, 5, 2],
					[0, 0, 3, 2, 2, 2],
					[3, 0, 3, 3, 4, 2],
					[3, 3, 3, 4, 4, 4],
				],
				"solution":[Vector2i(1, 0), Vector2i(5, 1), Vector2i(2, 2), Vector2i(4, 3), Vector2i(0, 4), Vector2i(3, 5)],
				"given_cats":[],
			}
		"patchwork_7":
			return {
				"id":"patchwork_7", "level":24, "size":7,
				"regions":[
					[4, 2, 2, 2, 2, 5, 3],
					[4, 4, 2, 2, 5, 5, 3],
					[4, 4, 4, 2, 5, 3, 3],
					[4, 0, 0, 5, 5, 3, 3],
					[0, 0, 6, 1, 1, 3, 3],
					[6, 6, 6, 1, 1, 3, 3],
					[6, 1, 1, 1, 1, 1, 1],
				],
				"solution":[Vector2i(0, 0), Vector2i(5, 1), Vector2i(3, 2), Vector2i(1, 3), Vector2i(6, 4), Vector2i(2, 5), Vector2i(4, 6)],
				"given_cats":[Vector2i(0, 0)],
			}
	return {}


static func fixture_ids() -> Array[String]:
	return ["notebook_5", "ribbon_6", "patchwork_7"]


func load_puzzle(spec: Dictionary) -> Dictionary:
	var verdict := _validate_spec(spec)
	if not bool(verdict.get("ok", false)):
		return verdict
	_loaded_spec = spec.duplicate(true)
	puzzle_id = str(spec.id)
	level = int(spec.get("level", 0))
	size = int(spec.size)
	regions = spec.regions.duplicate(true)
	solution = _cell_array(spec.solution)
	given_cats = _cell_array(spec.get("given_cats", []))
	restart()
	return {"ok":true, "solution_count":1, "puzzle_id":puzzle_id}


func restart() -> Dictionary:
	if _loaded_spec.is_empty():
		return {"changed":false, "event":"no_puzzle"}
	cats = given_cats.duplicate()
	manual_marks.clear()
	selected = INVALID_CELL
	hearts = MAX_HEARTS
	mistakes = 0
	moves = 0
	status = PLAYING
	return {"changed":true, "event":"restart", "status":status}


func select(cell: Vector2i) -> bool:
	if status != PLAYING or not in_bounds(cell):
		return false
	selected = cell
	return true


func move_selection(delta: Vector2i) -> bool:
	if status != PLAYING or size <= 0:
		return false
	if not in_bounds(selected):
		selected = Vector2i.ZERO
		return true
	var origin := selected
	var destination := Vector2i(
		clampi(origin.x + delta.x, 0, size - 1),
		clampi(origin.y + delta.y, 0, size - 1)
	)
	selected = destination
	return destination != origin


func toggle_mark(cell: Vector2i = INVALID_CELL) -> Dictionary:
	cell = _resolved_cell(cell)
	if status != PLAYING or not in_bounds(cell):
		return {"changed":false, "event":"blocked", "reason":"inactive_or_out_of_bounds"}
	if cell in cats or cell in given_cats:
		return {"changed":false, "event":"given" if cell in given_cats else "occupied"}
	selected = cell
	if cell in manual_marks:
		manual_marks.erase(cell)
		moves += 1
		return {"changed":true, "event":"unmark", "cell":cell}
	manual_marks.append(cell)
	moves += 1
	return {"changed":true, "event":"mark", "cell":cell}


func attempt_cat(cell: Vector2i = INVALID_CELL) -> Dictionary:
	cell = _resolved_cell(cell)
	if status != PLAYING or not in_bounds(cell):
		return {"changed":false, "event":"blocked", "reason":"inactive_or_out_of_bounds", "status":status}
	selected = cell
	if cell in given_cats:
		return {"changed":false, "event":"given", "cell":cell, "hearts":hearts}
	if cell in cats:
		return {"changed":false, "event":"occupied", "cell":cell, "hearts":hearts}
	if cell not in solution:
		hearts -= 1
		mistakes += 1
		if hearts <= 0:
			hearts = 0
			status = LOST
		return {
			"changed":true, "event":"loss" if status == LOST else "error",
			"correct":false, "cell":cell, "hearts":hearts, "status":status,
		}
	manual_marks.erase(cell)
	cats.append(cell)
	moves += 1
	var complete := is_complete()
	if complete:
		status = WON
	return {
		"changed":true, "event":"complete" if complete else "cat",
		"correct":true, "cell":cell, "hearts":hearts, "status":status,
		"placed":cats.size(), "required":size,
	}


func erase(cell: Vector2i = INVALID_CELL) -> Dictionary:
	cell = _resolved_cell(cell)
	if status != PLAYING or not in_bounds(cell):
		return {"changed":false, "event":"blocked", "reason":"inactive_or_out_of_bounds"}
	selected = cell
	if cell in given_cats:
		return {"changed":false, "event":"given", "cell":cell}
	if cell in cats:
		cats.erase(cell)
		moves += 1
		return {"changed":true, "event":"erase_cat", "cell":cell}
	if cell in manual_marks:
		manual_marks.erase(cell)
		moves += 1
		return {"changed":true, "event":"erase_mark", "cell":cell}
	return {"changed":false, "event":"empty", "cell":cell}


func apply_command(command: String, cell: Vector2i = INVALID_CELL) -> Dictionary:
	match command:
		"select":
			return {"changed":select(cell), "event":"select", "cell":selected}
		"mark":
			return toggle_mark(cell)
		"cat":
			return attempt_cat(cell)
		"erase":
			return erase(cell)
		"restart":
			return restart()
	return {"changed":false, "event":"unknown_command", "command":command}


func is_derived_excluded(cell: Vector2i) -> bool:
	if not in_bounds(cell) or cell in cats:
		return false
	for cat in cats:
		if cell.x == cat.x or cell.y == cat.y:
			return true
		if region_at(cell) == region_at(cat):
			return true
		if abs(cell.x - cat.x) == 1 and abs(cell.y - cat.y) == 1:
			return true
	return false


func derived_exclusions() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(size):
		for x in range(size):
			var cell := Vector2i(x, y)
			if is_derived_excluded(cell):
				result.append(cell)
	return result


func is_complete() -> bool:
	if cats.size() != size:
		return false
	return _cats_are_legal(cats, regions, size) and _same_cells(cats, solution)


func solution_count(limit := 2) -> int:
	if size <= 0:
		return 0
	return _count_solutions(regions, size, given_cats, limit)


func region_at(cell: Vector2i) -> int:
	if not in_bounds(cell):
		return -1
	return int(regions[cell.y][cell.x])


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < size and cell.y >= 0 and cell.y < size


func snapshot() -> Dictionary:
	return {
		"puzzle_id":puzzle_id, "level":level, "size":size,
		"regions":regions.duplicate(true), "cats":_cells_to_data(cats),
		"given_cats":_cells_to_data(given_cats),
		"manual_marks":_cells_to_data(manual_marks),
		"derived_marks":_cells_to_data(derived_exclusions()),
		"selected":[selected.x, selected.y], "hearts":hearts,
		"mistakes":mistakes, "moves":moves, "status":status,
		"placed":cats.size(), "required":size,
	}


func checkpoint() -> Dictionary:
	return {
		"schema":"meowdoku-checkpoint-v1", "puzzle_id":puzzle_id,
		"cats":_cells_to_data(cats), "manual_marks":_cells_to_data(manual_marks),
		"selected":[selected.x, selected.y], "hearts":hearts,
		"mistakes":mistakes, "moves":moves, "status":status,
	}


func restore_checkpoint(data: Dictionary) -> Dictionary:
	if str(data.get("schema", "")) != "meowdoku-checkpoint-v1" or str(data.get("puzzle_id", "")) != puzzle_id:
		return {"ok":false, "error":"checkpoint_identity"}
	var parsed_cats := _parse_cells(data.get("cats", []), true, size)
	var parsed_marks := _parse_cells(data.get("manual_marks", []), true, size)
	var parsed_selection := _parse_cell(data.get("selected", []), true, size)
	if not bool(parsed_cats.ok) or not bool(parsed_marks.ok) or not bool(parsed_selection.ok):
		return {"ok":false, "error":"checkpoint_cells"}
	var next_cats: Array[Vector2i] = parsed_cats.cells
	var next_marks: Array[Vector2i] = parsed_marks.cells
	var next_selected: Vector2i = parsed_selection.cell
	var next_hearts := int(data.get("hearts", -1))
	var next_mistakes := int(data.get("mistakes", -1))
	var next_moves := int(data.get("moves", -1))
	var next_status := str(data.get("status", ""))
	if next_hearts < 0 or next_hearts > MAX_HEARTS or next_mistakes < 0 or next_moves < 0:
		return {"ok":false, "error":"checkpoint_counters"}
	for given in given_cats:
		if given not in next_cats:
			return {"ok":false, "error":"checkpoint_missing_given"}
	for cat in next_cats:
		if cat not in solution:
			return {"ok":false, "error":"checkpoint_wrong_cat"}
	for mark in next_marks:
		if mark in next_cats or mark in given_cats:
			return {"ok":false, "error":"checkpoint_mark_collision"}
	if not _cats_are_legal(next_cats, regions, size):
		return {"ok":false, "error":"checkpoint_illegal_cats"}
	var complete := next_cats.size() == size and _same_cells(next_cats, solution)
	if (next_status == WON) != complete:
		return {"ok":false, "error":"checkpoint_win_status"}
	if (next_status == LOST) != (next_hearts == 0):
		return {"ok":false, "error":"checkpoint_loss_status"}
	if next_status not in [PLAYING, WON, LOST]:
		return {"ok":false, "error":"checkpoint_status"}
	cats = next_cats
	manual_marks = next_marks
	selected = next_selected
	hearts = next_hearts
	mistakes = next_mistakes
	moves = next_moves
	status = next_status
	return {"ok":true, "status":status}


func _validate_spec(spec: Dictionary) -> Dictionary:
	var next_id := str(spec.get("id", ""))
	var next_size := int(spec.get("size", 0))
	var next_regions: Variant = spec.get("regions", [])
	var parsed_solution := _parse_cells(spec.get("solution", []), false, next_size)
	var parsed_givens := _parse_cells(spec.get("given_cats", []), false, next_size)
	if next_id.is_empty():
		return {"ok":false, "error":"missing_id"}
	if next_size < 4 or next_size > 12:
		return {"ok":false, "error":"invalid_size"}
	if not next_regions is Array or next_regions.size() != next_size:
		return {"ok":false, "error":"region_rows"}
	var counts: Dictionary = {}
	for row in next_regions:
		if not row is Array or row.size() != next_size:
			return {"ok":false, "error":"region_columns"}
		for value in row:
			var region := int(value)
			if region < 0 or region >= next_size:
				return {"ok":false, "error":"region_id"}
			counts[region] = int(counts.get(region, 0)) + 1
	if counts.size() != next_size:
		return {"ok":false, "error":"region_count"}
	for region in range(next_size):
		if not _region_connected(next_regions, next_size, region):
			return {"ok":false, "error":"region_disconnected", "region":region}
	if not bool(parsed_solution.ok) or parsed_solution.cells.size() != next_size:
		return {"ok":false, "error":"solution_cells"}
	if not bool(parsed_givens.ok):
		return {"ok":false, "error":"given_cells"}
	var next_solution: Array[Vector2i] = parsed_solution.cells
	var next_givens: Array[Vector2i] = parsed_givens.cells
	if not _cats_are_legal(next_solution, next_regions, next_size):
		return {"ok":false, "error":"solution_illegal"}
	for given in next_givens:
		if given not in next_solution:
			return {"ok":false, "error":"given_not_solution"}
	if _count_solutions(next_regions, next_size, next_givens, 2) != 1:
		return {"ok":false, "error":"solution_not_unique"}
	return {"ok":true}


func _resolved_cell(cell: Vector2i) -> Vector2i:
	return selected if cell == INVALID_CELL else cell


func _parse_cells(value: Variant, allow_invalid := false, board_size := -1) -> Dictionary:
	if not value is Array:
		return {"ok":false, "cells":[]}
	var result: Array[Vector2i] = []
	for item in value:
		var parsed := _parse_cell(item, allow_invalid, board_size)
		if not bool(parsed.ok):
			return {"ok":false, "cells":[]}
		var cell: Vector2i = parsed.cell
		if cell == INVALID_CELL and allow_invalid:
			return {"ok":false, "cells":[]}
		var bound := board_size if board_size > 0 else size
		if cell in result or (cell != INVALID_CELL and bound > 0 and not in_bounds_for(cell, bound)):
			return {"ok":false, "cells":[]}
		result.append(cell)
	return {"ok":true, "cells":result}


func _parse_cell(value: Variant, allow_invalid: bool, board_size := -1) -> Dictionary:
	var cell := INVALID_CELL
	if value is Vector2i:
		cell = value
	elif value is Array and value.size() == 2:
		cell = Vector2i(int(value[0]), int(value[1]))
	else:
		return {"ok":false, "cell":INVALID_CELL}
	if allow_invalid and cell == INVALID_CELL:
		return {"ok":true, "cell":cell}
	var bound := board_size if board_size > 0 else size
	if bound > 0 and not in_bounds_for(cell, bound):
		return {"ok":false, "cell":INVALID_CELL}
	return {"ok":true, "cell":cell}


func _cell_array(value: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for item in value:
		result.append(item if item is Vector2i else Vector2i(int(item[0]), int(item[1])))
	return result


func _cells_to_data(value: Array[Vector2i]) -> Array:
	var result: Array = []
	for cell in value:
		result.append([cell.x, cell.y])
	return result


func _same_cells(a: Array[Vector2i], b: Array[Vector2i]) -> bool:
	if a.size() != b.size():
		return false
	for cell in a:
		if cell not in b:
			return false
	return true


func _region_connected(grid: Array, board_size: int, region: int) -> bool:
	var start := INVALID_CELL
	var expected := 0
	for y in range(board_size):
		for x in range(board_size):
			if int(grid[y][x]) == region:
				expected += 1
				if start == INVALID_CELL:
					start = Vector2i(x, y)
	if start == INVALID_CELL:
		return false
	var queue: Array[Vector2i] = [start]
	var visited: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for delta: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + delta
			if in_bounds_for(neighbor, board_size) and neighbor not in visited and int(grid[neighbor.y][neighbor.x]) == region:
				visited.append(neighbor)
				queue.append(neighbor)
	return visited.size() == expected


func _cats_are_legal(value: Array[Vector2i], grid: Array, board_size: int) -> bool:
	var rows: Dictionary = {}
	var columns: Dictionary = {}
	var used_regions: Dictionary = {}
	for cell in value:
		if not in_bounds_for(cell, board_size):
			return false
		var region := int(grid[cell.y][cell.x])
		if rows.has(cell.y) or columns.has(cell.x) or used_regions.has(region):
			return false
		rows[cell.y] = true
		columns[cell.x] = true
		used_regions[region] = true
	for first_index in range(value.size()):
		for second_index in range(first_index + 1, value.size()):
			var first := value[first_index]
			var second := value[second_index]
			if abs(first.x - second.x) == 1 and abs(first.y - second.y) == 1:
				return false
	return true


func _count_solutions(grid: Array, board_size: int, givens: Array[Vector2i], limit: int) -> int:
	var given_by_row: Dictionary = {}
	for cell in givens:
		given_by_row[cell.y] = cell.x
	return _count_row(grid, board_size, 0, -99, {}, {}, given_by_row, maxi(1, limit))


func _count_row(grid: Array, board_size: int, row: int, previous_column: int, used_columns: Dictionary, used_regions: Dictionary, given_by_row: Dictionary, limit: int) -> int:
	if row == board_size:
		return 1
	var total := 0
	var candidates: Array = [int(given_by_row[row])] if given_by_row.has(row) else range(board_size)
	for column_value in candidates:
		var column := int(column_value)
		var region := int(grid[row][column])
		if used_columns.has(column) or used_regions.has(region):
			continue
		if row > 0 and abs(column - previous_column) == 1:
			continue
		var next_columns := used_columns.duplicate()
		var next_regions := used_regions.duplicate()
		next_columns[column] = true
		next_regions[region] = true
		total += _count_row(grid, board_size, row + 1, column, next_columns, next_regions, given_by_row, limit - total)
		if total >= limit:
			return total
	return total


static func in_bounds_for(cell: Vector2i, board_size: int) -> bool:
	return cell.x >= 0 and cell.x < board_size and cell.y >= 0 and cell.y < board_size
