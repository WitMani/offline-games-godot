class_name SnakeModel
extends RefCounted

## Deterministic, presentation-free Snake rules. This models the modern
## full-screen grid Snake: automatic start, a 15x23 arena, queued turns,
## two-step growth, multiple food items and an endless length score.

const READY := "ready"
const RUNNING := "running"
const WON := "won"
const LOST := "lost"
const CARDINALS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var width := 15
var height := 23
var wrap := false
var snake: Array[Vector2i] = []
var direction := Vector2i.RIGHT
var turn_queue: Array[Vector2i] = []
var foods: Array[Vector2i] = []
var food := Vector2i(11, 11)
var score := 0
var moves := 0
var phase := READY
var terminal_reason := ""
var step_index := 0
var pending_growth := 0
var food_target := 2
var rng := RandomNumberGenerator.new()

func reset(use_wrap: bool, seed: int) -> void:
	wrap = use_wrap
	rng.seed = seed
	var center := Vector2i(width / 2, height / 2)
	snake = [center, center - Vector2i.RIGHT, center - Vector2i.RIGHT * 2, center - Vector2i.RIGHT * 3]
	direction = Vector2i.RIGHT
	turn_queue.clear()
	foods = [center + Vector2i(4, 0), center + Vector2i(-3, -5)]
	food = foods[0]
	score = snake.size()
	moves = 0
	phase = RUNNING
	terminal_reason = ""
	step_index = 0
	pending_growth = 0

func request_turn(requested: Vector2i) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if phase == WON or phase == LOST:
		return [{"kind":"turn_rejected", "reason":"terminal", "direction":requested}]
	if requested not in CARDINALS:
		return [{"kind":"turn_rejected", "reason":"invalid", "direction":requested}]
	if requested == direction:
		return [{"kind":"turn_rejected", "reason":"duplicate", "direction":requested}]
	if requested + direction == Vector2i.ZERO:
		return [{"kind":"turn_rejected", "reason":"reverse", "direction":requested}]
	if not turn_queue.is_empty():
		return [{"kind":"turn_rejected", "reason":"pending_turn", "direction":requested}]
	if turn_queue.size() >= 4:
		return [{"kind":"turn_rejected", "reason":"queue_full", "direction":requested}]
	turn_queue.append(requested)
	events.append({"kind":"turn_accepted", "direction":requested})
	return events

func advance_step() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if phase != RUNNING:
		return events
	if not turn_queue.is_empty():
		direction = turn_queue.pop_front()
	var head := snake[0]
	var next := head + direction
	if wrap:
		next.x = posmod(next.x, width)
		next.y = posmod(next.y, height)
	elif next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
		phase = LOST
		terminal_reason = "wall"
		return [{"kind":"wall_hit", "from":head, "to":next, "step":step_index}]
	# Keep the scalar compatibility alias writable for evaluator fixtures.
	if foods.is_empty():
		foods.append(food)
	elif food != foods[0]:
		foods[0] = food
	var eaten_index := foods.find(next)
	var ate := eaten_index >= 0
	var old_tail: Vector2i = snake.back()
	var grows_this_step := pending_growth > 0
	# The tail vacates this step unless queued growth is being materialized.
	var collision_limit := snake.size() if grows_this_step else snake.size() - 1
	for index in range(collision_limit):
		if snake[index] == next:
			phase = LOST
			terminal_reason = "self"
			return [{"kind":"self_hit", "from":head, "to":next, "step":step_index}]
	snake.push_front(next)
	events.append({
		"kind":"moved", "from":head, "to":next, "step":step_index,
		"tail":old_tail, "tail_vacated":not grows_this_step
	})
	if grows_this_step:
		pending_growth -= 1
	else:
		snake.pop_back()
	score = snake.size()
	if ate:
		pending_growth += 2
		var eaten_position := foods[eaten_index]
		var surviving_foods := foods.duplicate()
		foods.remove_at(eaten_index)
		surviving_foods.remove_at(eaten_index)
		_refill_foods()
		food = foods[0] if not foods.is_empty() else Vector2i.ZERO
		events.append({"kind":"ate", "at":next, "score_delta":2, "score":score, "step":step_index})
		for spawned in foods:
			if spawned != eaten_position and spawned not in surviving_foods:
				events.append({"kind":"food_spawned", "at":spawned, "step":step_index})
				break
	moves += 1
	step_index += 1
	return events

func _spawn_food() -> void:
	for _attempt in range(200):
		var candidate := Vector2i(rng.randi_range(0, width - 1), rng.randi_range(0, height - 1))
		if candidate not in snake and candidate not in foods and not _adjacent_to_food(candidate):
			foods.append(candidate)
			food = candidate
			return
	for fallback_y in range(height):
		for fallback_x in range(width):
			var fallback := Vector2i(fallback_x, fallback_y)
			if fallback not in snake and fallback not in foods:
				foods.append(fallback)
				food = fallback
				return

func _refill_foods() -> void:
	while foods.size() < food_target:
		var before := foods.size()
		_spawn_food()
		if foods.size() == before:
			break

func _adjacent_to_food(candidate: Vector2i) -> bool:
	for existing in foods:
		if absi(existing.x - candidate.x) + absi(existing.y - candidate.y) <= 1:
			return true
	return false

func snapshot() -> Dictionary:
	var packed_snake: Array = []
	for segment in snake:
		packed_snake.append([segment.x, segment.y])
	var packed_queue: Array = []
	for queued in turn_queue:
		packed_queue.append([queued.x, queued.y])
	var planned: Vector2i = direction if turn_queue.is_empty() else turn_queue.front()
	var packed_foods: Array = []
	for item in foods:
		packed_foods.append([item.x, item.y])
	return {
		"width":width, "height":height, "snake":packed_snake,
		"direction":[direction.x, direction.y], "next_direction":[planned.x, planned.y],
		"turn_queue":packed_queue, "food":[food.x, food.y], "foods":packed_foods, "score":score,
		"moves":moves, "started":phase != READY, "phase":phase,
		"terminal_reason":terminal_reason, "step_index":step_index, "pending_growth":pending_growth,
		"status":"won" if phase == WON else ("over" if phase == LOST else "playing")
	}
