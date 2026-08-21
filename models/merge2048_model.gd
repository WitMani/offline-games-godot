class_name Merge2048Model
extends RefCounted

## Clean-room model for Gabriele Cirulli's classic 4 x 4 2048 ruleset.
##
## Presentation consumes the motion metadata returned by move(), but never
## owns the board.  That keeps animation timing, effects and input routing from
## changing the authoritative rules.

const SIZE := 4
const TARGET := 2048
const PLAYING := "playing"
const WON := "won"
const OVER := "over"

var board: Array = []
var score := 0
var best := 0
var moves := 0
var won := false
var over := false
var keep_playing := false
var rng := RandomNumberGenerator.new()


func reset(seed_value: int, preserved_best := 0) -> void:
	rng.seed = seed_value
	board = _empty_board()
	score = 0
	best = maxi(0, preserved_best)
	moves = 0
	won = false
	over = false
	keep_playing = false
	_spawn_tile()
	_spawn_tile()


func status() -> String:
	if over:
		return OVER
	if won and not keep_playing:
		return WON
	return PLAYING


func is_terminated() -> bool:
	return over or (won and not keep_playing)


func continue_after_win() -> bool:
	if not won or over or keep_playing:
		return false
	keep_playing = true
	return true


func move(direction: Vector2i) -> Dictionary:
	var result := {
		"changed":false,
		"gained":0,
		"moves":[],
		"merges":[],
		"spawn":{},
		"direction":direction,
		"board_before":board.duplicate(true),
		"board_after_slide":board.duplicate(true),
		"board_after":board.duplicate(true),
		"won_now":false,
		"over_now":false,
		"status":status(),
	}
	if is_terminated() or not _is_cardinal(direction):
		return result

	var next_board: Array = board.duplicate(true)
	var gained := 0
	var motion_moves: Array[Dictionary] = []
	var merge_results: Array[Dictionary] = []
	for line_index in range(SIZE):
		var coordinates := _line_coordinates(direction, line_index)
		var line: Array = []
		for cell in coordinates:
			line.append(int(board[cell.y][cell.x]))
		var resolved := resolve_line(line)
		gained += int(resolved.gained)
		for destination_index in range(SIZE):
			var destination: Vector2i = coordinates[destination_index]
			next_board[destination.y][destination.x] = int(resolved.line[destination_index])
		for line_move in resolved.moves:
			var source: Vector2i = coordinates[int(line_move.from_index)]
			var destination: Vector2i = coordinates[int(line_move.to_index)]
			if source != destination or bool(line_move.merged):
				motion_moves.append({
					"from":source,
					"to":destination,
					"source_value":int(line_move.source_value),
					"result_value":int(line_move.result_value),
					"merged":bool(line_move.merged),
				})
		for line_merge in resolved.merges:
			var destination: Vector2i = coordinates[int(line_merge.to_index)]
			var sources: Array[Vector2i] = []
			for source_index in line_merge.source_indices:
				sources.append(coordinates[int(source_index)])
			merge_results.append({
				"to":destination,
				"sources":sources,
				"source_value":int(line_merge.source_value),
				"result_value":int(line_merge.result_value),
			})

	if next_board == board:
		return result

	board = next_board
	result.changed = true
	result.gained = gained
	result.moves = motion_moves
	result.merges = merge_results
	result.board_after_slide = board.duplicate(true)
	score += gained
	best = maxi(best, score)
	moves += 1
	var reached_target := _contains_target(board)
	if reached_target and not won:
		won = true
		result.won_now = true
	result.spawn = _spawn_tile()
	if not has_moves():
		over = true
		result.over_now = true
	result.board_after = board.duplicate(true)
	result.status = status()
	return result


func resolve_line(line: Array) -> Dictionary:
	var compact: Array[Dictionary] = []
	for source_index in range(line.size()):
		var value := int(line[source_index])
		if value > 0:
			compact.append({"value":value, "sources":[source_index]})

	var resolved_groups: Array[Dictionary] = []
	var gained := 0
	var cursor := 0
	while cursor < compact.size():
		var current: Dictionary = compact[cursor]
		if cursor + 1 < compact.size() and int(current.value) == int(compact[cursor + 1].value):
			var result_value := int(current.value) * 2
			var sources: Array = current.sources.duplicate()
			sources.append_array(compact[cursor + 1].sources)
			resolved_groups.append({"value":result_value, "sources":sources})
			gained += result_value
			cursor += 2
		else:
			resolved_groups.append(current)
			cursor += 1

	var resolved_line: Array = []
	var line_moves: Array[Dictionary] = []
	var line_merges: Array[Dictionary] = []
	for destination_index in range(resolved_groups.size()):
		var group: Dictionary = resolved_groups[destination_index]
		var result_value := int(group.value)
		resolved_line.append(result_value)
		for source_index in group.sources:
			line_moves.append({
				"from_index":int(source_index),
				"to_index":destination_index,
				"source_value":int(line[int(source_index)]),
				"result_value":result_value,
				"merged":group.sources.size() > 1,
			})
		if group.sources.size() > 1:
			line_merges.append({
				"to_index":destination_index,
				"source_indices":group.sources.duplicate(),
				"source_value":result_value >> 1,
				"result_value":result_value,
			})
	while resolved_line.size() < line.size():
		resolved_line.append(0)
	return {
		"line":resolved_line,
		"gained":gained,
		"changed":resolved_line != line,
		"moves":line_moves,
		"merges":line_merges,
	}


func has_moves() -> bool:
	return _board_has_moves(board)


func _board_has_moves(candidate_board: Array) -> bool:
	for y in range(SIZE):
		for x in range(SIZE):
			var value := int(candidate_board[y][x])
			if value == 0:
				return true
			if x + 1 < SIZE and value == int(candidate_board[y][x + 1]):
				return true
			if y + 1 < SIZE and value == int(candidate_board[y + 1][x]):
				return true
	return false


func snapshot() -> Dictionary:
	return {
		"schema":1,
		"board":board.duplicate(true),
		"score":score,
		"best":best,
		"moves":moves,
		"won":won,
		"over":over,
		"keep_playing":keep_playing,
		"status":status(),
		"target":TARGET,
		# Store the 64-bit RNG state as text so JSON/browser number precision
		# cannot silently change the next spawn after a reload.
		"rng_state":str(rng.state),
	}


func restore(saved: Dictionary) -> bool:
	if int(saved.get("schema", 0)) != 1:
		return false
	var saved_board: Variant = saved.get("board")
	if not _valid_board(saved_board):
		return false
	var saved_score := int(saved.get("score", -1))
	var saved_best := int(saved.get("best", -1))
	var saved_moves := int(saved.get("moves", -1))
	if saved_score < 0 or saved_best < saved_score or saved_moves < 0:
		return false
	var saved_won := bool(saved.get("won", false))
	var saved_over := bool(saved.get("over", false))
	var saved_keep_playing := bool(saved.get("keep_playing", false))
	if saved_keep_playing and not saved_won:
		return false
	if saved_won != _contains_target(saved_board):
		return false
	if saved_over == _board_has_moves(saved_board):
		return false
	var rng_text := str(saved.get("rng_state", ""))
	if not rng_text.is_valid_int():
		return false
	board = _empty_board()
	for y in range(SIZE):
		for x in range(SIZE):
			board[y][x] = int(saved_board[y][x])
	score = saved_score
	best = saved_best
	moves = saved_moves
	won = saved_won
	over = saved_over
	keep_playing = saved_keep_playing
	rng.state = int(rng_text)
	return true


func load_fixture(
	fixture_board: Array,
	fixture_score := 0,
	fixture_moves := 0,
	fixture_won := false,
	fixture_keep_playing := false,
	fixture_over := false,
	fixture_best := -1
) -> bool:
	if not _valid_board(fixture_board):
		return false
	board = fixture_board.duplicate(true)
	score = maxi(0, fixture_score)
	best = maxi(score, fixture_best if fixture_best >= 0 else score)
	moves = maxi(0, fixture_moves)
	won = fixture_won
	keep_playing = fixture_keep_playing and fixture_won
	over = fixture_over
	return true


func _spawn_tile() -> Dictionary:
	var empty: Array[Vector2i] = []
	for y in range(SIZE):
		for x in range(SIZE):
			if int(board[y][x]) == 0:
				empty.append(Vector2i(x, y))
	if empty.is_empty():
		return {}
	var position: Vector2i = empty[rng.randi_range(0, empty.size() - 1)]
	var value := 2 if rng.randf() < 0.9 else 4
	board[position.y][position.x] = value
	return {"position":position, "value":value}


func _empty_board() -> Array:
	var result: Array = []
	for _y in range(SIZE):
		result.append([0, 0, 0, 0])
	return result


func _line_coordinates(direction: Vector2i, line_index: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in range(SIZE):
		if direction == Vector2i.LEFT:
			result.append(Vector2i(offset, line_index))
		elif direction == Vector2i.RIGHT:
			result.append(Vector2i(SIZE - 1 - offset, line_index))
		elif direction == Vector2i.UP:
			result.append(Vector2i(line_index, offset))
		else:
			result.append(Vector2i(line_index, SIZE - 1 - offset))
	return result


func _contains_target(candidate_board: Array) -> bool:
	for row in candidate_board:
		for value in row:
			if int(value) >= TARGET:
				return true
	return false


func _valid_board(candidate: Variant) -> bool:
	if not candidate is Array or candidate.size() != SIZE:
		return false
	for row in candidate:
		if not row is Array or row.size() != SIZE:
			return false
		for raw_value in row:
			var value := int(raw_value)
			if value < 0 or (value > 0 and (value & (value - 1)) != 0):
				return false
	return true


func _is_cardinal(direction: Vector2i) -> bool:
	return direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
