class_name AmazeModel
extends RefCounted

## Renderer-independent clean-room model for the Classic AMAZE!!! loop.
##
## A cardinal command rolls to the last traversable cell before a void or the
## board boundary. Every crossed cell is painted in travel order. Re-entering
## painted cells is legal and still changes position / consumes one move.

const RUNNING := "playing"
const WON := "won"
const CELL_VOID := "0"
const CELL_START := "S"
const CHECKPOINT_SCHEMA := "offline-games.amaze.checkpoint.v1"
const MAX_CHECKPOINT_COMMANDS := 10000

const LEVELS := [
	{
		"id":"corner_intro",
		"name":"折角入门",
		"rows":[
			"11111",
			"10000",
			"10000",
			"10000",
			"S0000",
		],
	},
	{
		"id":"ribbon_switchback",
		"name":"回形彩带",
		"rows":[
			"111111",
			"100001",
			"111111",
			"100000",
			"11111S",
		],
	},
	{
		"id":"nested_detour",
		"name":"嵌套回廊",
		"rows":[
			"1111111",
			"1000001",
			"1011101",
			"1010101",
			"1110111",
			"1000100",
			"S111100",
		],
	},
]

var level_index := 0
var level_id := ""
var level_name := ""
var topology_rows: Array = []
var width := 0
var height := 0
var walkable: Array = []
var painted: Array = []
var position := Vector2i.ZERO
var start_position := Vector2i.ZERO
var paint_order: Array[Vector2i] = []
var last_traversal: Array[Vector2i] = []
var last_newly_painted: Array[Vector2i] = []
var command_history: Array[Vector2i] = []
var score := 0
var moves := 0
var status := RUNNING


func reset(requested_level: int = 0) -> void:
	level_index = posmod(requested_level, LEVELS.size())
	var definition: Dictionary = LEVELS[level_index]
	level_id = str(definition["id"])
	level_name = str(definition["name"])
	topology_rows = definition["rows"].duplicate()
	height = topology_rows.size()
	width = str(topology_rows[0]).length() if height > 0 else 0
	walkable = _new_bool_grid(width, height, false)
	painted = _new_bool_grid(width, height, false)
	var starts := 0
	for y in range(height):
		var row := str(topology_rows[y])
		assert(row.length() == width, "Amaze topology rows must share a width")
		for x in range(width):
			var marker := row.substr(x, 1)
			var can_walk := marker != CELL_VOID
			walkable[y][x] = can_walk
			if marker == CELL_START:
				start_position = Vector2i(x, y)
				starts += 1
	assert(starts == 1, "Amaze topology must contain exactly one start cell")
	position = start_position
	painted[position.y][position.x] = true
	paint_order.assign([position])
	last_traversal.clear()
	last_newly_painted.clear()
	command_history.clear()
	score = 0
	moves = 0
	status = RUNNING


func restart() -> void:
	reset(level_index)


func advance_level() -> bool:
	if status != WON:
		return false
	reset(level_index + 1)
	return true


func command(direction: Vector2i) -> Dictionary:
	if status != RUNNING:
		return _rejected_outcome("terminal", direction)
	if abs(direction.x) + abs(direction.y) != 1:
		return _rejected_outcome("invalid_direction", direction)
	var traversed := trace(direction)
	if traversed.is_empty():
		return _rejected_outcome("blocked", direction)

	var from := position
	var newly_painted: Array[Vector2i] = []
	for cell in traversed:
		if not bool(painted[cell.y][cell.x]):
			painted[cell.y][cell.x] = true
			newly_painted.append(cell)
			paint_order.append(cell)
	position = traversed.back()
	last_traversal = traversed.duplicate()
	last_newly_painted = newly_painted.duplicate()
	command_history.append(direction)
	moves += 1
	var score_delta := newly_painted.size() * 5
	score += score_delta
	var completed := painted_count() == walkable_count()
	if completed:
		status = WON
		score += 100
		score_delta += 100
	return {
		"changed":true,
		"reason":"stopped_at_obstacle",
		"direction":[direction.x, direction.y],
		"from":[from.x, from.y],
		"to":[position.x, position.y],
		"traversed":_cells_to_arrays(traversed),
		"newly_painted":_cells_to_arrays(newly_painted),
		"revisit_count":traversed.size() - newly_painted.size(),
		"remaining":remaining_count(),
		"completed":completed,
		"score_delta":score_delta,
	}


func trace(direction: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if abs(direction.x) + abs(direction.y) != 1:
		return result
	var cursor := position
	while is_walkable(cursor + direction):
		cursor += direction
		result.append(cursor)
	return result


func legal_directions() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		if not trace(direction).is_empty():
			result.append(direction)
	return result


func hint_direction() -> Vector2i:
	var best := Vector2i.ZERO
	var best_new := -1
	var best_length := -1
	for direction in legal_directions():
		var path := trace(direction)
		var new_count := 0
		for cell in path:
			if not bool(painted[cell.y][cell.x]):
				new_count += 1
		if new_count > best_new or (new_count == best_new and path.size() > best_length):
			best = direction
			best_new = new_count
			best_length = path.size()
	return best


func is_walkable(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height and bool(walkable[cell.y][cell.x])


func walkable_count() -> int:
	var count := 0
	for row in walkable:
		for value in row:
			if bool(value):
				count += 1
	return count


func painted_count() -> int:
	var count := 0
	for row in painted:
		for value in row:
			if bool(value):
				count += 1
	return count


func remaining_count() -> int:
	return walkable_count() - painted_count()


func level_count() -> int:
	return LEVELS.size()


func checkpoint() -> Dictionary:
	# Persist the accepted command history as the canonical recovery input. On
	# restore we replay it against the authored topology, then compare the stored
	# summary. That makes corrupted/tampered payloads reject atomically instead of
	# trusting a loose painted bitmap.
	return {
		"schema":CHECKPOINT_SCHEMA,
		"rules_version":"amaze-stage0-v2",
		"level_index":level_index,
		"level_id":level_id,
		"commands":_cells_to_arrays(command_history),
		"player":[position.x, position.y],
		"paint_order":_cells_to_arrays(paint_order),
		"painted_count":painted_count(),
		"moves":moves,
		"score":score,
		"status":status,
	}


func restore(payload: Variant) -> bool:
	if not payload is Dictionary:
		return false
	var data: Dictionary = payload
	if str(data.get("schema", "")) != CHECKPOINT_SCHEMA:
		return false
	if not _is_exact_integer(data.get("level_index")):
		return false
	var requested_level := int(data["level_index"])
	if requested_level < 0 or requested_level >= LEVELS.size():
		return false
	if str(data.get("level_id", "")) != str(LEVELS[requested_level]["id"]):
		return false
	var raw_commands: Variant = data.get("commands")
	if not raw_commands is Array or raw_commands.size() > MAX_CHECKPOINT_COMMANDS:
		return false

	var candidate = get_script().new()
	candidate.reset(requested_level)
	for raw_direction in raw_commands:
		var direction: Variant = _decode_cell(raw_direction)
		if direction == null:
			return false
		var cardinal: Vector2i = direction
		if abs(cardinal.x) + abs(cardinal.y) != 1:
			return false
		var outcome: Dictionary = candidate.command(cardinal)
		if not bool(outcome.get("changed", false)):
			return false

	if not _checkpoint_matches_candidate(data, candidate):
		return false
	_adopt(candidate)
	return true


func snapshot() -> Dictionary:
	return {
		"rules_version":"amaze-stage0-v2",
		"level_index":level_index,
		"level_number":level_index + 1,
		"level_count":level_count(),
		"level_id":level_id,
		"level_name":level_name,
		"topology":topology_rows.duplicate(),
		"width":width,
		"height":height,
		"size":maxi(width, height),
		"walkable":walkable.duplicate(true),
		"walkable_count":walkable_count(),
		"painted":painted.duplicate(true),
		"painted_count":painted_count(),
		"remaining":remaining_count(),
		"player":[position.x, position.y],
		"start":[start_position.x, start_position.y],
		"paint_order":_cells_to_arrays(paint_order),
		"command_history":_cells_to_arrays(command_history),
		"last_traversal":_cells_to_arrays(last_traversal),
		"last_newly_painted":_cells_to_arrays(last_newly_painted),
		"score":score,
		"moves":moves,
		"status":status,
	}


func _rejected_outcome(reason: String, direction: Vector2i) -> Dictionary:
	return {
		"changed":false,
		"reason":reason,
		"direction":[direction.x, direction.y],
		"from":[position.x, position.y],
		"to":[position.x, position.y],
		"traversed":[],
		"newly_painted":[],
		"revisit_count":0,
		"remaining":remaining_count(),
		"completed":status == WON,
		"score_delta":0,
	}


func _new_bool_grid(grid_width: int, grid_height: int, value: bool) -> Array:
	var result: Array = []
	for _y in range(grid_height):
		var row: Array[bool] = []
		for _x in range(grid_width):
			row.append(value)
		result.append(row)
	return result


func _checkpoint_matches_candidate(data: Dictionary, candidate) -> bool:
	for field in ["painted_count", "moves", "score"]:
		if not _is_exact_integer(data.get(field)):
			return false
	var player: Variant = _decode_cell(data.get("player"))
	if player == null or player != candidate.position:
		return false
	var raw_order: Variant = data.get("paint_order")
	if not raw_order is Array:
		return false
	var decoded_order: Array[Vector2i] = []
	for raw_cell in raw_order:
		var cell: Variant = _decode_cell(raw_cell)
		if cell == null:
			return false
		decoded_order.append(cell)
	return (
		decoded_order == candidate.paint_order
		and int(data["painted_count"]) == candidate.painted_count()
		and int(data["moves"]) == candidate.moves
		and int(data["score"]) == candidate.score
		and str(data.get("status", "")) == candidate.status
	)


func _adopt(candidate) -> void:
	level_index = candidate.level_index
	level_id = candidate.level_id
	level_name = candidate.level_name
	topology_rows = candidate.topology_rows.duplicate()
	width = candidate.width
	height = candidate.height
	walkable = candidate.walkable.duplicate(true)
	painted = candidate.painted.duplicate(true)
	position = candidate.position
	start_position = candidate.start_position
	paint_order = candidate.paint_order.duplicate()
	last_traversal.clear()
	last_newly_painted.clear()
	command_history = candidate.command_history.duplicate()
	score = candidate.score
	moves = candidate.moves
	status = candidate.status


func _decode_cell(value: Variant) -> Variant:
	if not value is Array or value.size() != 2:
		return null
	if not _is_exact_integer(value[0]) or not _is_exact_integer(value[1]):
		return null
	return Vector2i(int(value[0]), int(value[1]))


func _is_exact_integer(value: Variant) -> bool:
	if value is int:
		return true
	return value is float and is_finite(value) and value == floor(value)


func _cells_to_arrays(cells: Array[Vector2i]) -> Array:
	var result: Array = []
	for cell in cells:
		result.append([cell.x, cell.y])
	return result
