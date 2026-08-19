class_name Merge2248Model
extends RefCounted

## Clean-room model for the 5-column Number Connect / 2248 ruleset.

const RUNNING := "playing"
const OVER := "over"
const WON := "won"

var width := 5
var height := 8
var board: Array = []
var selected: Array[Vector2i] = []
var score := 0
var moves := 0
var status := RUNNING
var rng := RandomNumberGenerator.new()


func reset(seed_value: int = 2248, rows: int = 8) -> void:
	height = clampi(rows, 5, 8)
	rng.seed = seed_value
	score = 0
	moves = 0
	status = RUNNING
	selected.clear()
	board.clear()
	for y in range(height):
		var row: Array[int] = []
		for _x in range(width):
			row.append(_random_start_value())
		board.append(row)
	_ensure_opening_pair()


func begin(cell: Vector2i) -> bool:
	selected.clear()
	if not _in_bounds(cell) or status != RUNNING:
		return false
	selected.append(cell)
	return true


func extend(cell: Vector2i) -> bool:
	if not _in_bounds(cell) or selected.is_empty() or cell in selected:
		return false
	var previous := selected[-1]
	if maxi(abs(cell.x - previous.x), abs(cell.y - previous.y)) != 1:
		return false
	var value := int(board[cell.y][cell.x])
	var previous_value := int(board[previous.y][previous.x])
	if selected.size() == 1:
		if value != previous_value:
			return false
	elif value != previous_value and value != previous_value * 2:
		return false
	selected.append(cell)
	return true


func cancel() -> void:
	selected.clear()


func release() -> Dictionary:
	if selected.size() < 2:
		selected.clear()
		return {"changed":false, "gained":0, "result":0}
	var path := selected.duplicate()
	var total := 0
	for cell in path:
		total += int(board[cell.y][cell.x])
	var result := _next_power_of_two(total)
	var destination: Vector2i = path[-1]
	for cell in path:
		board[cell.y][cell.x] = 0
	board[destination.y][destination.x] = result
	_apply_gravity()
	_refill()
	score += total
	moves += 1
	selected.clear()
	if result >= 2048:
		status = WON
	elif not has_moves():
		status = OVER
	return {"changed":true, "gained":total, "result":result, "destination":destination, "path":path}


func preview_result() -> int:
	if selected.size() < 2:
		return 0
	var total := 0
	for cell in selected:
		total += int(board[cell.y][cell.x])
	return _next_power_of_two(total)


func has_moves() -> bool:
	for y in range(height):
		for x in range(width):
			var value := int(board[y][x])
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var other := Vector2i(x + dx, y + dy)
					if _in_bounds(other) and int(board[other.y][other.x]) == value:
						return true
	return false


func snapshot() -> Dictionary:
	return {
		"board":board.duplicate(true), "selected":selected.duplicate(),
		"score":score, "moves":moves, "status":status,
		"width":width, "height":height, "preview":preview_result()
	}


func _apply_gravity() -> void:
	for x in range(width):
		var write_y := height - 1
		for y in range(height - 1, -1, -1):
			var value := int(board[y][x])
			if value > 0:
				board[write_y][x] = value
				if write_y != y:
					board[y][x] = 0
				write_y -= 1


func _refill() -> void:
	var ceiling := _spawn_ceiling()
	for y in range(height):
		for x in range(width):
			if int(board[y][x]) == 0:
				board[y][x] = 1 << rng.randi_range(1, ceiling)


func _random_start_value() -> int:
	var roll := rng.randf()
	if roll < 0.50:
		return 2
	if roll < 0.82:
		return 4
	if roll < 0.96:
		return 8
	return 16


func _spawn_ceiling() -> int:
	var highest := 2
	for row in board:
		for value in row:
			highest = maxi(highest, int(value))
	var power := int(round(log(float(highest)) / log(2.0)))
	return clampi(power - 2, 2, 8)


func _ensure_opening_pair() -> void:
	if has_moves():
		return
	board[height - 1][0] = 2
	board[height - 1][1] = 2


func _next_power_of_two(value: int) -> int:
	var result := 2
	while result < value:
		result *= 2
	return result


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height
