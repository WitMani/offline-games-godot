class_name AmazeGoModel
extends RefCounted

## Renderer-free clean-room model for the evidence-bounded Amaze GO arrow
## extraction loop.  Runtime art consumes events and snapshots; it never owns
## arrow occupancy, clearance, hearts, completion or recovery.

const PLAYING := "playing"
const WON := "won"
const OVER := "over"
const LEVEL_ID := "bounded-orthogonal-v3-01"
const WIDTH := 12
const HEIGHT := 12
const MAX_HEARTS := 3

var arrows: Array[Dictionary] = []
var removed_ids: Array[String] = []
var hearts := MAX_HEARTS
var mistakes := 0
var moves := 0
var score := 0
var status := PLAYING
var focus_id := ""
var hint_id := ""
var last_event: Dictionary = {}


func reset() -> void:
	arrows = _canonical_arrows()
	removed_ids.clear()
	hearts = MAX_HEARTS
	mistakes = 0
	moves = 0
	score = 0
	status = PLAYING
	focus_id = str(arrows[0].id)
	hint_id = ""
	last_event = {"kind":"entry", "level_id":LEVEL_ID}
	assert(_topology_valid())


func arrow_ids() -> Array[String]:
	var result: Array[String] = []
	for arrow in arrows:
		result.append(str(arrow.id))
	return result


func live_ids() -> Array[String]:
	var result: Array[String] = []
	for arrow in arrows:
		var arrow_id := str(arrow.id)
		if arrow_id not in removed_ids:
			result.append(arrow_id)
	return result


func remaining_count() -> int:
	return arrows.size() - removed_ids.size()


func arrow_for_id(arrow_id: String) -> Dictionary:
	for arrow in arrows:
		if str(arrow.id) == arrow_id:
			return arrow
	return {}


func is_live(arrow_id: String) -> bool:
	return not arrow_for_id(arrow_id).is_empty() and arrow_id not in removed_ids


func direction_for(arrow_id: String) -> Vector2i:
	var arrow := arrow_for_id(arrow_id)
	if arrow.is_empty():
		return Vector2i.ZERO
	return arrow.direction


func head_for(arrow_id: String) -> Vector2i:
	var arrow := arrow_for_id(arrow_id)
	if arrow.is_empty():
		return Vector2i(-1, -1)
	var path: Array = arrow.path
	return path[-1]


func blockers_for(arrow_id: String) -> Array[String]:
	var blockers: Array[String] = []
	if not is_live(arrow_id):
		return blockers
	var head := head_for(arrow_id)
	var direction := direction_for(arrow_id)
	var cursor := head + direction
	while _in_bounds(cursor):
		for other in arrows:
			var other_id := str(other.id)
			if other_id == arrow_id or other_id in removed_ids:
				continue
			if cursor in other.path and other_id not in blockers:
				blockers.append(other_id)
		cursor += direction
	return blockers


func first_blocking_cell(arrow_id: String) -> Vector2i:
	if not is_live(arrow_id):
		return Vector2i(-1, -1)
	var head := head_for(arrow_id)
	var direction := direction_for(arrow_id)
	var cursor := head + direction
	while _in_bounds(cursor):
		for other in arrows:
			var other_id := str(other.id)
			if other_id != arrow_id and other_id not in removed_ids and cursor in other.path:
				return cursor
		cursor += direction
	return Vector2i(-1, -1)


func is_legal(arrow_id: String) -> bool:
	return status == PLAYING and is_live(arrow_id) and blockers_for(arrow_id).is_empty()


func legal_ids() -> Array[String]:
	var result: Array[String] = []
	if status != PLAYING:
		return result
	for arrow_id in live_ids():
		if blockers_for(arrow_id).is_empty():
			result.append(arrow_id)
	return result


func attempt(arrow_id: String) -> Dictionary:
	if status != PLAYING:
		return {"kind":"terminal_reject", "accepted":false, "reason":"terminal", "arrow_id":arrow_id, "status":status}
	var arrow := arrow_for_id(arrow_id)
	if arrow.is_empty():
		return {"kind":"invalid_reject", "accepted":false, "reason":"invalid_id", "arrow_id":arrow_id}
	if arrow_id in removed_ids:
		return {"kind":"removed_reject", "accepted":false, "reason":"already_removed", "arrow_id":arrow_id}
	var blockers := blockers_for(arrow_id)
	if not blockers.is_empty():
		var contact := first_blocking_cell(arrow_id)
		hearts -= 1
		mistakes += 1
		moves += 1
		hint_id = ""
		if hearts <= 0:
			hearts = 0
			status = OVER
		return _record({
			"kind":"loss" if status == OVER else "reject",
			"accepted":false,
			"reason":"blocked",
			"arrow_id":arrow_id,
			"blockers":blockers,
			"contact":[contact.x, contact.y],
			"hearts":hearts,
			"grade":4 if status == OVER else 2,
			"status":status,
		})
	removed_ids.append(arrow_id)
	moves += 1
	hint_id = ""
	var remaining := remaining_count()
	var kind := "extract"
	var grade := 1
	if remaining == 0:
		status = WON
		score += 120
		kind = "win"
		grade = 4
	elif remaining <= 2:
		kind = "near"
		grade = 3
	elif removed_ids.size() % 3 == 0:
		kind = "waypoint"
		grade = 2
	else:
		kind = "extract"
		grade = 1
	if status != WON:
		score += 20
	_focus_after_removal(arrow_id)
	return _record({
		"kind":kind,
		"accepted":true,
		"arrow_id":arrow_id,
		"direction":[direction_for(arrow_id).x, direction_for(arrow_id).y],
		"removed_count":removed_ids.size(),
		"remaining":remaining,
		"grade":grade,
		"status":status,
	})


func request_hint() -> Dictionary:
	if status != PLAYING:
		return {"kind":"hint_reject", "accepted":false, "reason":"terminal", "status":status}
	var legal := legal_ids()
	if legal.is_empty():
		return {"kind":"hint_reject", "accepted":false, "reason":"no_legal_arrow", "status":status}
	hint_id = legal[0]
	focus_id = hint_id
	return _record({"kind":"hint", "accepted":true, "arrow_id":hint_id, "grade":1})


func move_focus(direction: Vector2i) -> String:
	if status != PLAYING or direction not in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		return focus_id
	var live := live_ids()
	if live.is_empty():
		focus_id = ""
		return focus_id
	if focus_id not in live:
		focus_id = live[0]
		return focus_id
	var origin := _arrow_center(focus_id)
	var best_id := ""
	var best_score := INF
	for candidate_id in live:
		if candidate_id == focus_id:
			continue
		var delta := _arrow_center(candidate_id) - origin
		var primary := delta.dot(Vector2(direction))
		if primary <= 0.01:
			continue
		var perpendicular := absf(delta.cross(Vector2(direction)))
		var candidate_score := primary + perpendicular * 2.4
		if candidate_score < best_score:
			best_score = candidate_score
			best_id = candidate_id
	if not best_id.is_empty():
		focus_id = best_id
	hint_id = ""
	return focus_id


func snapshot() -> Dictionary:
	var exposed_arrows: Array[Dictionary] = []
	for arrow in arrows:
		var path_points: Array = []
		for point: Vector2i in arrow.path:
			path_points.append([point.x, point.y])
		var arrow_id := str(arrow.id)
		exposed_arrows.append({
			"id":arrow_id,
			"path":path_points,
			"direction":[int(arrow.direction.x), int(arrow.direction.y)],
			"removed":arrow_id in removed_ids,
			"legal":status == PLAYING and arrow_id not in removed_ids and blockers_for(arrow_id).is_empty(),
			"blockers":blockers_for(arrow_id),
		})
	return {
		"schema":"amaze-go-model/v1",
		"level_id":LEVEL_ID,
		"width":WIDTH,
		"height":HEIGHT,
		"arrows":exposed_arrows,
		"removed_ids":removed_ids.duplicate(),
		"removed_count":removed_ids.size(),
		"remaining":remaining_count(),
		"hearts":hearts,
		"max_hearts":MAX_HEARTS,
		"mistakes":mistakes,
		"moves":moves,
		"score":score,
		"status":status,
		"focus_id":focus_id,
		"hint_id":hint_id,
		"last_event":last_event.duplicate(true),
	}


func recovery_snapshot() -> Dictionary:
	return {
		"schema":"amaze-go-recovery/v1",
		"level_id":LEVEL_ID,
		"removed_ids":removed_ids.duplicate(),
		"hearts":hearts,
		"mistakes":mistakes,
		"moves":moves,
		"score":score,
		"status":status,
		"focus_id":focus_id,
		"hint_id":hint_id,
	}


func restore(payload: Dictionary) -> bool:
	if payload.get("schema") != "amaze-go-recovery/v1" or payload.get("level_id") != LEVEL_ID:
		return false
	if not payload.get("removed_ids") is Array:
		return false
	var canonical_ids := arrow_ids()
	var restored_removed: Array[String] = []
	for raw_id in payload.removed_ids:
		if not raw_id is String:
			return false
		var arrow_id := str(raw_id)
		if arrow_id not in canonical_ids or arrow_id in restored_removed:
			return false
		restored_removed.append(arrow_id)
	var restored_hearts := _strict_int(payload.get("hearts"), -1)
	var restored_mistakes := _strict_int(payload.get("mistakes"), -1)
	var restored_moves := _strict_int(payload.get("moves"), -1)
	var restored_score := _strict_int(payload.get("score"), -1)
	if restored_hearts < 0 or restored_hearts > MAX_HEARTS:
		return false
	if restored_mistakes != MAX_HEARTS - restored_hearts:
		return false
	if restored_moves != restored_removed.size() + restored_mistakes:
		return false
	var restored_status := str(payload.get("status", ""))
	var expected_status := PLAYING
	if restored_removed.size() == canonical_ids.size():
		expected_status = WON
	elif restored_hearts == 0:
		expected_status = OVER
	if restored_status != expected_status:
		return false
	var expected_score := restored_removed.size() * 20
	if expected_status == WON:
		expected_score = (restored_removed.size() - 1) * 20 + 120
	if restored_score != expected_score:
		return false
	var restored_focus := str(payload.get("focus_id", ""))
	var restored_hint := str(payload.get("hint_id", ""))
	if expected_status == PLAYING:
		if restored_focus.is_empty() or restored_focus not in canonical_ids or restored_focus in restored_removed:
			return false
		if not restored_hint.is_empty() and (restored_hint not in canonical_ids or restored_hint in restored_removed):
			return false
	else:
		if not restored_focus.is_empty() and restored_focus not in canonical_ids:
			return false
		if not restored_hint.is_empty():
			return false
	removed_ids = restored_removed
	hearts = restored_hearts
	mistakes = restored_mistakes
	moves = restored_moves
	score = restored_score
	status = restored_status
	focus_id = restored_focus
	hint_id = restored_hint
	if not hint_id.is_empty() and blockers_for(hint_id).size() > 0:
		return false
	last_event = {"kind":"recovered", "removed_count":removed_ids.size(), "status":status}
	return true


func _canonical_arrows() -> Array[Dictionary]:
	return [
		_arrow("a0", [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]),
		_arrow("a1", [Vector2i(7, 2), Vector2i(8, 2), Vector2i(8, 1), Vector2i(8, 0)]),
		_arrow("a2", [Vector2i(5, 4), Vector2i(5, 3), Vector2i(6, 3)]),
		_arrow("a3", [Vector2i(9, 5), Vector2i(10, 5), Vector2i(10, 4), Vector2i(10, 3)]),
		_arrow("a4", [Vector2i(2, 6), Vector2i(3, 6), Vector2i(3, 5)]),
		_arrow("a5", [Vector2i(0, 9), Vector2i(1, 9), Vector2i(1, 8), Vector2i(2, 8)]),
		_arrow("a6", [Vector2i(6, 10), Vector2i(6, 9), Vector2i(6, 8)]),
		_arrow("a7", [Vector2i(9, 11), Vector2i(9, 10), Vector2i(10, 10)]),
		_arrow("a8", [Vector2i(4, 11), Vector2i(3, 11), Vector2i(3, 10)]),
		_arrow("a9", [Vector2i(11, 7), Vector2i(10, 7), Vector2i(10, 6), Vector2i(9, 6)]),
		_arrow("a10", [Vector2i(11, 2), Vector2i(10, 2), Vector2i(9, 2)]),
		_arrow("a11", [Vector2i(4, 7), Vector2i(4, 8), Vector2i(4, 9)]),
	]


func _arrow(arrow_id: String, path: Array[Vector2i]) -> Dictionary:
	var direction := path[-1] - path[-2]
	return {"id":arrow_id, "path":path, "direction":direction}


func _topology_valid() -> bool:
	var ids: Array[String] = []
	var occupied: Dictionary = {}
	for arrow in arrows:
		var arrow_id := str(arrow.id)
		if arrow_id.is_empty() or arrow_id in ids:
			return false
		ids.append(arrow_id)
		var path: Array = arrow.path
		if path.size() < 2:
			return false
		for index in range(path.size()):
			var point: Vector2i = path[index]
			if not _in_bounds(point) or occupied.has(point):
				return false
			occupied[point] = arrow_id
			if index > 0:
				var delta: Vector2i = point - Vector2i(path[index - 1])
				if abs(delta.x) + abs(delta.y) != 1:
					return false
		var expected: Vector2i = Vector2i(path[-1]) - Vector2i(path[-2])
		if arrow.direction != expected or abs(expected.x) + abs(expected.y) != 1:
			return false
	return true


func _focus_after_removal(removed_id: String) -> void:
	var live := live_ids()
	if live.is_empty():
		focus_id = ""
		return
	var removed_index := arrow_ids().find(removed_id)
	for offset in range(1, arrows.size() + 1):
		var candidate := str(arrows[(removed_index + offset) % arrows.size()].id)
		if candidate in live:
			focus_id = candidate
			return


func _arrow_center(arrow_id: String) -> Vector2:
	var arrow := arrow_for_id(arrow_id)
	if arrow.is_empty():
		return Vector2.ZERO
	var center := Vector2.ZERO
	for point: Vector2i in arrow.path:
		center += Vector2(point)
	return center / float(arrow.path.size())


func _record(event: Dictionary) -> Dictionary:
	last_event = event.duplicate(true)
	return last_event


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < WIDTH and cell.y < HEIGHT


func _strict_int(value: Variant, fallback: int) -> int:
	if value is int:
		return int(value)
	if value is float and is_equal_approx(float(value), floorf(float(value))):
		return int(value)
	return fallback
