class_name SnakeGbModel
extends RefCounted

## Deterministic, renderer-free model for Offline Games 3.14.1 `79_SNAKE2`
## medium mode. It remains separate from the continuous `136_SNAKES` arena
## model. Presentation milestones are explicitly nonterminal.

const RUNNING := "running"
const LOST := "lost"
const SNAPSHOT_VERSION := 1
const FOOD_COUNT := 2
const GROWTH_PER_FOOD := 2
const MILESTONE_INTERVAL := 10
const FIELD_RECORD_LENGTH := 120
const CARDINALS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var width := 15
var height := 23
var segments: Array[Vector2i] = []
var direction := Vector2i.RIGHT
var turn_queue: Array[Vector2i] = []
var foods: Array[Vector2i] = []
# Compatibility alias for older shell/audit helpers. `foods` is authoritative.
var food := Vector2i.ZERO
var score := 0
var moves := 0
var pending_growth := 0
var phase := RUNNING
var terminal_reason := ""
var step_index := 0
var rng := RandomNumberGenerator.new()
var initial_seed := 0


func reset(seed_value: int) -> void:
	initial_seed = seed_value
	rng.seed = seed_value
	var center := Vector2i(width / 2, height / 2)
	segments.assign([
		center,
		center - Vector2i.RIGHT,
		center - Vector2i.RIGHT * 2,
		center - Vector2i.RIGHT * 3,
	])
	direction = Vector2i.RIGHT
	turn_queue.clear()
	foods.clear()
	_spawn_food_at_index(0)
	_spawn_food_at_index(1)
	_sync_food_alias()
	score = segments.size()
	moves = 0
	pending_growth = 0
	phase = RUNNING
	terminal_reason = ""
	step_index = 0


func request_turn(requested: Vector2i) -> Array[Dictionary]:
	if phase != RUNNING:
		return [{"kind":"turn_rejected", "reason":"terminal", "direction":requested}]
	if requested not in CARDINALS:
		return [{"kind":"turn_rejected", "reason":"invalid", "direction":requested}]
	if not turn_queue.is_empty():
		return [{"kind":"turn_rejected", "reason":"pending_turn", "direction":requested}]
	if requested == direction:
		return [{"kind":"turn_rejected", "reason":"duplicate", "direction":requested}]
	if requested + direction == Vector2i.ZERO:
		return [{"kind":"turn_rejected", "reason":"reverse", "direction":requested}]
	turn_queue.append(requested)
	return [{"kind":"turn_accepted", "direction":requested}]


func advance_step() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if phase != RUNNING:
		return events
	_ensure_food_population()
	if not turn_queue.is_empty():
		direction = turn_queue.pop_front()
	var head: Vector2i = segments[0]
	var next: Vector2i = head + direction
	if not _is_in_bounds(next):
		phase = LOST
		terminal_reason = "wall"
		return [{"kind":"wall_hit", "from":head, "to":next, "score":score, "step":step_index}]
	var grows_this_step: bool = pending_growth > 0
	var collision_limit: int = segments.size() if grows_this_step else segments.size() - 1
	for segment_index in range(collision_limit):
		if segments[segment_index] == next:
			phase = LOST
			terminal_reason = "self"
			return [{"kind":"self_hit", "from":head, "to":next, "score":score, "step":step_index}]
	var old_tail: Vector2i = segments.back()
	segments.push_front(next)
	events.append({
		"kind":"moved", "from":head, "to":next, "tail":old_tail,
		"tail_vacated":not grows_this_step, "step":step_index,
	})
	if grows_this_step:
		pending_growth -= 1
	else:
		segments.pop_back()
	score = segments.size()
	moves += 1
	step_index += 1
	if grows_this_step:
		events.append({
			"kind":"growth_materialized", "score":score,
			"at":segments.back(), "pending_growth":pending_growth, "step":step_index,
		})
		if score % MILESTONE_INTERVAL == 0:
			events.append({
				"kind":"length_milestone", "score":score,
				"interval":MILESTONE_INTERVAL, "nonterminal":true, "step":step_index,
			})
		if score == FIELD_RECORD_LENGTH:
			events.append({
				"kind":"field_record_complete", "score":score,
				"nonterminal":true, "step":step_index,
			})
	var eaten_index := foods.find(next)
	if eaten_index >= 0:
		var eaten: Vector2i = foods[eaten_index]
		pending_growth += GROWTH_PER_FOOD
		foods[eaten_index] = Vector2i(-1, -1)
		var spawned := _spawn_food_at_index(eaten_index)
		_sync_food_alias()
		events.append({
			"kind":"ate", "at":eaten, "food_index":eaten_index,
			"score":score, "growth_queued":GROWTH_PER_FOOD,
			"pending_growth":pending_growth, "step":step_index,
		})
		if spawned:
			events.append({
				"kind":"food_spawned", "at":foods[eaten_index],
				"food_index":eaten_index, "step":step_index,
			})
		else:
			events.append({"kind":"food_spawn_blocked", "food_index":eaten_index, "step":step_index})
	return events


func _spawn_food(food_index := 0) -> bool:
	# Compatibility hook for evaluator scripts. Normal spawning replaces the
	# requested slot and preserves the two-food population.
	if food_index < 0 or food_index >= FOOD_COUNT:
		return false
	while foods.size() <= food_index:
		foods.append(Vector2i(-1, -1))
	foods[food_index] = Vector2i(-1, -1)
	var spawned := _spawn_food_at_index(food_index)
	_ensure_food_population()
	_sync_food_alias()
	return spawned


func _spawn_food_at_index(food_index: int) -> bool:
	while foods.size() <= food_index:
		foods.append(Vector2i(-1, -1))
	for _attempt in range(width * height * 2):
		var candidate := Vector2i(rng.randi_range(0, width - 1), rng.randi_range(0, height - 1))
		if _is_food_cell_free(candidate, food_index):
			foods[food_index] = candidate
			return true
	for y in range(height):
		for x in range(width):
			var fallback := Vector2i(x, y)
			if _is_food_cell_free(fallback, food_index):
				foods[food_index] = fallback
				return true
	return false


func _ensure_food_population() -> void:
	var accepted: Array[Vector2i] = []
	for candidate in foods:
		if accepted.size() >= FOOD_COUNT:
			break
		if _is_in_bounds(candidate) and candidate not in segments and candidate not in accepted:
			accepted.append(candidate)
	foods = accepted
	while foods.size() < FOOD_COUNT:
		if not _spawn_food_at_index(foods.size()):
			break
	_sync_food_alias()


func _is_food_cell_free(candidate: Vector2i, replacing_index: int) -> bool:
	if not _is_in_bounds(candidate) or candidate in segments:
		return false
	for index in range(foods.size()):
		if index != replacing_index and foods[index] == candidate:
			return false
	return true


func _is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func _sync_food_alias() -> void:
	food = foods[0] if not foods.is_empty() else Vector2i.ZERO


func snapshot() -> Dictionary:
	var packed_segments: Array = []
	for segment in segments:
		packed_segments.append([segment.x, segment.y])
	var packed_queue: Array = []
	for queued in turn_queue:
		packed_queue.append([queued.x, queued.y])
	var packed_foods: Array = []
	for active_food in foods:
		packed_foods.append([active_food.x, active_food.y])
	var first_food: Array = packed_foods[0] if not packed_foods.is_empty() else []
	return {
		"snapshot_version":SNAPSHOT_VERSION,
		"width":width, "height":height,
		"segments":packed_segments, "snake":packed_segments.duplicate(true),
		"direction":[direction.x, direction.y], "turn_queue":packed_queue,
		"food":first_food, "foods":packed_foods,
		"score":score, "moves":moves,
		"pending_growth":pending_growth, "phase":phase,
		"terminal_reason":terminal_reason, "step_index":step_index,
		"rng_state":str(rng.state), "initial_seed":str(initial_seed),
		"endless":true, "started":true,
		"status":"over" if phase == LOST else "playing",
	}


func restore(candidate: Dictionary) -> bool:
	# Validate into local values first so malformed Web storage cannot partially
	# mutate the active run.
	if int(candidate.get("snapshot_version", -1)) != SNAPSHOT_VERSION:
		return false
	if int(candidate.get("width", -1)) != width or int(candidate.get("height", -1)) != height:
		return false
	var restored_segments := _decode_cells(candidate.get("segments", []))
	if restored_segments.size() < 4 or not _cells_unique_and_in_bounds(restored_segments):
		return false
	for index in range(1, restored_segments.size()):
		if _manhattan(restored_segments[index - 1], restored_segments[index]) != 1:
			return false
	var restored_direction := _decode_cell(candidate.get("direction", []))
	if restored_direction not in CARDINALS:
		return false
	var restored_queue := _decode_cells(candidate.get("turn_queue", []))
	if restored_queue.size() > 1:
		return false
	if not restored_queue.is_empty():
		if restored_queue[0] not in CARDINALS:
			return false
		if restored_queue[0] == restored_direction or restored_queue[0] + restored_direction == Vector2i.ZERO:
			return false
	var restored_foods := _decode_cells(candidate.get("foods", []))
	if restored_foods.size() != FOOD_COUNT or not _cells_unique_and_in_bounds(restored_foods):
		return false
	for restored_food in restored_foods:
		if restored_food in restored_segments:
			return false
	var restored_score := int(candidate.get("score", -1))
	var restored_moves := int(candidate.get("moves", -1))
	var restored_growth := int(candidate.get("pending_growth", -1))
	var restored_step := int(candidate.get("step_index", -1))
	if restored_score != restored_segments.size() or restored_moves < 0 or restored_growth < 0 or restored_step < 0:
		return false
	if restored_moves != restored_step:
		return false
	var restored_phase := str(candidate.get("phase", ""))
	var restored_reason := str(candidate.get("terminal_reason", ""))
	if restored_phase not in [RUNNING, LOST]:
		return false
	if restored_phase == RUNNING and not restored_reason.is_empty():
		return false
	if restored_phase == LOST and restored_reason not in ["wall", "self"]:
		return false
	var rng_text := str(candidate.get("rng_state", ""))
	var seed_text := str(candidate.get("initial_seed", ""))
	if not rng_text.is_valid_int() or not seed_text.is_valid_int():
		return false
	segments.assign(restored_segments)
	direction = restored_direction
	turn_queue.assign(restored_queue)
	foods.assign(restored_foods)
	_sync_food_alias()
	score = restored_score
	moves = restored_moves
	pending_growth = restored_growth
	phase = restored_phase
	terminal_reason = restored_reason
	step_index = restored_step
	initial_seed = int(seed_text)
	rng.seed = initial_seed
	rng.state = int(rng_text)
	return true


func _decode_cells(value: Variant) -> Array[Vector2i]:
	var decoded: Array[Vector2i] = []
	if not value is Array:
		return decoded
	for packed in value:
		var cell := _decode_cell(packed)
		if cell == Vector2i(-2147483648, -2147483648):
			decoded.clear()
			return decoded
		decoded.append(cell)
	return decoded


func _decode_cell(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Array and value.size() == 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i(-2147483648, -2147483648)


func _cells_unique_and_in_bounds(cells: Array[Vector2i]) -> bool:
	var seen: Dictionary = {}
	for cell in cells:
		if not _is_in_bounds(cell) or seen.has(cell):
			return false
		seen[cell] = true
	return true


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
