class_name SnakeGbModel
extends RefCounted

## Deterministic GB/LCD grid Snake. This is intentionally separate from the
## continuous arena model and from the archived Garden Snake2 model.

const RUNNING := "running"
const WON := "won"
const LOST := "lost"
const CARDINALS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var width := 15
var height := 23
var target_length := 120
var segments: Array[Vector2i] = []
var direction := Vector2i.RIGHT
var turn_queue: Array[Vector2i] = []
var food := Vector2i.ZERO
var foods: Array[Vector2i] = []
var score := 0
var moves := 0
var pending_growth := 0
var phase := RUNNING
var terminal_reason := ""
var step_index := 0
var rng := RandomNumberGenerator.new()


func reset(seed: int) -> void:
	rng.seed = seed
	var center := Vector2i(width / 2, height / 2)
	segments.assign([center, center - Vector2i.RIGHT, center - Vector2i.RIGHT * 2, center - Vector2i.RIGHT * 3])
	direction = Vector2i.RIGHT
	turn_queue.clear()
	food = center + Vector2i(4, 0)
	foods.assign([food])
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
	if not turn_queue.is_empty():
		direction = turn_queue.pop_front()
	if foods.is_empty() or foods[0] != food:
		foods.assign([food])
	var head: Vector2i = segments[0]
	var next: Vector2i = head + direction
	if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
		phase = LOST
		terminal_reason = "wall"
		return [{"kind":"wall_hit", "from":head, "to":next, "step":step_index}]
	var grows_this_step: bool = pending_growth > 0
	var collision_limit: int = segments.size() if grows_this_step else segments.size() - 1
	for segment_index in range(collision_limit):
		if segments[segment_index] == next:
			phase = LOST
			terminal_reason = "self"
			return [{"kind":"self_hit", "from":head, "to":next, "step":step_index}]
	var old_tail: Vector2i = segments.back()
	segments.push_front(next)
	events.append({"kind":"moved", "from":head, "to":next, "tail":old_tail, "tail_vacated":not grows_this_step, "step":step_index})
	if grows_this_step:
		pending_growth -= 1
	else:
		segments.pop_back()
	score = segments.size()
	moves += 1
	step_index += 1
	if grows_this_step:
		events.append({"kind":"growth_materialized", "score":score, "at":segments.back(), "step":step_index})
		if score >= target_length:
			phase = WON
			terminal_reason = "target"
			events.append({"kind":"length_won", "score":score, "target":target_length, "step":step_index})
			return events
	if next == food:
		pending_growth += 1
		var eaten: Vector2i = food
		_spawn_food()
		events.append({"kind":"ate", "at":eaten, "score":score, "pending_growth":pending_growth, "step":step_index})
		events.append({"kind":"food_spawned", "at":food, "step":step_index})
	return events


func _spawn_food() -> void:
	for _attempt in range(240):
		var candidate: Vector2i = Vector2i(rng.randi_range(0, width - 1), rng.randi_range(0, height - 1))
		if candidate not in segments:
			food = candidate
			foods.assign([food])
			return
	for y in range(height):
		for x in range(width):
			var fallback: Vector2i = Vector2i(x, y)
			if fallback not in segments:
				food = fallback
				foods.assign([food])
				return


func snapshot() -> Dictionary:
	var packed_segments: Array = []
	for segment in segments:
		packed_segments.append([segment.x, segment.y])
	var packed_queue: Array = []
	for queued in turn_queue:
		packed_queue.append([queued.x, queued.y])
	return {
		"width":width, "height":height,
		"segments":packed_segments, "snake":packed_segments.duplicate(true),
		"direction":[direction.x, direction.y], "turn_queue":packed_queue,
		"food":[food.x, food.y], "foods":[[food.x, food.y]],
		"score":score, "target_length":target_length, "moves":moves,
		"pending_growth":pending_growth, "phase":phase,
		"terminal_reason":terminal_reason, "step_index":step_index,
		"started":true,
		"status":"won" if phase == WON else ("over" if phase == LOST else "playing")
	}
