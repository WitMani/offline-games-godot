class_name ArrowGoModel
extends RefCounted

## Renderer-free clean-room model for the evidence-bounded Arrow GO slice.
##
## The first-party listing establishes tap-to-launch, own-direction movement,
## blocking/order, clear-all and animal reveal. Exact target collision, score,
## failure and level data remain unknown; the canonical square board and sweep
## kernel below are explicitly local decisions and must not be cited as target
## version facts.

const SCHEMA := "arrow-go-state/v3"
const RECOVERY_SCHEMA := "arrow-go-recovery/v3"
const GAME_ID := "arrow_go"
const LEVEL_ID := "local-square-sweep-v3-01"
const PLAYING := "playing"
const WON := "won"
const OVER := "over"
const WIDTH := 9
const HEIGHT := 9
const BASE_CLEAR_SCORE := 100
const BEND_BONUS := 25

var arrows: Array[Dictionary] = []
var removed_ids: Array[String] = []
var moves := 0
var score := 0
var status := PLAYING
var terminal_reason := ""
var focus_id := ""
var hint_id := ""
var last_event: Dictionary = {}


func reset() -> Dictionary:
	arrows = _canonical_arrows()
	removed_ids.clear()
	moves = 0
	score = 0
	status = PLAYING
	terminal_reason = ""
	focus_id = str(arrows[0].id)
	hint_id = ""
	last_event = {
		"kind":"entry",
		"level_id":LEVEL_ID,
		"remaining":arrows.size(),
		"legal_ids":legal_ids(),
	}
	assert(topology_valid())
	return last_event.duplicate(true)


func restart() -> Dictionary:
	reset()
	last_event = {
		"kind":"restart",
		"accepted":true,
		"level_id":LEVEL_ID,
		"remaining":remaining_count(),
		"legal_ids":legal_ids(),
		"status":status,
	}
	return last_event.duplicate(true)


func arrow_ids() -> Array[String]:
	var result: Array[String] = []
	for arrow in arrows:
		result.append(str(arrow.id))
	return result


func live_ids() -> Array[String]:
	var result: Array[String] = []
	for arrow_id in arrow_ids():
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
	return Vector2i.ZERO if arrow.is_empty() else Vector2i(arrow.direction)


func path_for(arrow_id: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var arrow := arrow_for_id(arrow_id)
	if arrow.is_empty():
		return result
	for point in arrow.path:
		result.append(Vector2i(point))
	return result


func head_for(arrow_id: String) -> Vector2i:
	var path := path_for(arrow_id)
	return Vector2i(-1, -1) if path.is_empty() else path.back()


func bend_count(arrow_id: String) -> int:
	var path := path_for(arrow_id)
	var bends := 0
	for index in range(2, path.size()):
		if path[index] - path[index - 1] != path[index - 1] - path[index - 2]:
			bends += 1
	return bends


func blockers_for(arrow_id: String) -> Array[String]:
	var blockers: Array[String] = []
	if not is_live(arrow_id):
		return blockers
	var path := path_for(arrow_id)
	var direction := direction_for(arrow_id)
	var occupied := _live_occupancy(arrow_id)
	var offset := 1
	while offset <= maxi(WIDTH, HEIGHT) + path.size():
		var any_in_bounds := false
		for point in path:
			var translated := point + direction * offset
			if not _in_bounds(translated):
				continue
			any_in_bounds = true
			if occupied.has(translated):
				var blocker_id := str(occupied[translated])
				if blocker_id not in blockers:
					blockers.append(blocker_id)
		if not any_in_bounds:
			break
		offset += 1
	return blockers


func first_contact(arrow_id: String) -> Dictionary:
	if not is_live(arrow_id):
		return {}
	var path := path_for(arrow_id)
	var direction := direction_for(arrow_id)
	var occupied := _live_occupancy(arrow_id)
	var offset := 1
	while offset <= maxi(WIDTH, HEIGHT) + path.size():
		var any_in_bounds := false
		for point in path:
			var translated := point + direction * offset
			if not _in_bounds(translated):
				continue
			any_in_bounds = true
			if occupied.has(translated):
				return {
					"cell":[translated.x, translated.y],
					"blocker_id":str(occupied[translated]),
					"distance":offset,
				}
		if not any_in_bounds:
			break
		offset += 1
	return {}


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
		return _record({
			"kind":"terminal_reject",
			"accepted":false,
			"changed":false,
			"reason":"terminal",
			"arrow_id":arrow_id,
			"status":status,
		})
	if not is_live(arrow_id):
		return _record({
			"kind":"invalid_reject",
			"accepted":false,
			"changed":false,
			"reason":"invalid_or_removed",
			"arrow_id":arrow_id,
			"status":status,
		})
	var blockers := blockers_for(arrow_id)
	if not blockers.is_empty():
		return _record({
			"kind":"blocked",
			"accepted":false,
			"changed":false,
			"reason":"occupied_sweep",
			"arrow_id":arrow_id,
			"path":_packed_path(path_for(arrow_id)),
			"direction":_packed_vector(direction_for(arrow_id)),
			"blockers":blockers,
			"contact":first_contact(arrow_id),
			"remaining":remaining_count(),
			"grade":2,
			"status":status,
		})

	var legal_before := legal_ids()
	var path := path_for(arrow_id)
	var bends := bend_count(arrow_id)
	removed_ids.append(arrow_id)
	moves += 1
	score += BASE_CLEAR_SCORE + bends * BEND_BONUS
	hint_id = ""
	var remaining := remaining_count()
	var legal_after := legal_ids()
	var newly_legal: Array[String] = []
	for candidate in legal_after:
		if candidate not in legal_before and candidate != arrow_id:
			newly_legal.append(candidate)

	var event_kind := "turn_escape" if bends > 0 else "escape"
	var grade := 2 if bends > 0 else 1
	var milestone := removed_ids.size() == 4 or removed_ids.size() == 8
	var near := remaining > 0 and remaining <= 2
	if milestone:
		event_kind = "waypoint"
		grade = 2
	if near:
		event_kind = "near_clear"
		grade = 3
	if remaining == 0:
		status = WON
		terminal_reason = "clear_all"
		event_kind = "win"
		grade = 4
	else:
		refresh_terminal()
		if status == OVER:
			event_kind = "loss"
			grade = 4
	_focus_after_removal(arrow_id)
	return _record({
		"kind":event_kind,
		"accepted":true,
		"changed":true,
		"arrow_id":arrow_id,
		"path":_packed_path(path),
		"direction":_packed_vector(direction_for(arrow_id)),
		"bends":bends,
		"removed_count":removed_ids.size(),
		"remaining":remaining_count(),
		"newly_legal":newly_legal,
		"milestone":milestone,
		"near":near,
		"animal_reveal":status == WON,
		"score_delta":BASE_CLEAR_SCORE + bends * BEND_BONUS,
		"score":score,
		"moves":moves,
		"grade":grade,
		"status":status,
	})


func request_hint() -> Dictionary:
	if status != PLAYING:
		return _record({"kind":"hint_reject", "accepted":false, "changed":false, "reason":"terminal", "status":status})
	var legal := legal_ids()
	if legal.is_empty():
		return _record({"kind":"hint_reject", "accepted":false, "changed":false, "reason":"no_legal_arrow", "status":status})
	hint_id = legal[0]
	focus_id = hint_id
	return _record({"kind":"hint", "accepted":true, "changed":false, "arrow_id":hint_id, "grade":1, "status":status})


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
	var origin := arrow_center(focus_id)
	var best_id := ""
	var best_score := INF
	for candidate_id in live:
		if candidate_id == focus_id:
			continue
		var delta := arrow_center(candidate_id) - origin
		var primary := delta.dot(Vector2(direction))
		if primary <= 0.01:
			continue
		var perpendicular := absf(delta.cross(Vector2(direction)))
		var candidate_score := primary + perpendicular * 2.2
		if candidate_score < best_score:
			best_score = candidate_score
			best_id = candidate_id
	if not best_id.is_empty():
		focus_id = best_id
	hint_id = ""
	return focus_id


func arrow_center(arrow_id: String) -> Vector2:
	var path := path_for(arrow_id)
	if path.is_empty():
		return Vector2.ZERO
	var center := Vector2.ZERO
	for point in path:
		center += Vector2(point)
	return center / float(path.size())


func refresh_terminal() -> String:
	if remaining_count() == 0:
		status = WON
		terminal_reason = "clear_all"
	elif status == PLAYING and legal_ids().is_empty():
		status = OVER
		terminal_reason = "local_deadlock"
		focus_id = ""
		hint_id = ""
	return status


func snapshot() -> Dictionary:
	var exposed: Array[Dictionary] = []
	for arrow in arrows:
		var arrow_id := str(arrow.id)
		exposed.append({
			"id":arrow_id,
			"path":_packed_path(path_for(arrow_id)),
			"direction":_packed_vector(direction_for(arrow_id)),
			"bends":bend_count(arrow_id),
			"removed":arrow_id in removed_ids,
			"legal":status == PLAYING and is_live(arrow_id) and blockers_for(arrow_id).is_empty(),
			"blockers":blockers_for(arrow_id),
		})
	return {
		"schema":SCHEMA,
		"game_id":GAME_ID,
		"level_id":LEVEL_ID,
		"width":WIDTH,
		"height":HEIGHT,
		"arrows":exposed,
		"removed_ids":removed_ids.duplicate(),
		"removed_count":removed_ids.size(),
		"remaining":remaining_count(),
		"moves":moves,
		"score":score,
		"status":status,
		"terminal_reason":terminal_reason,
		"focus_id":focus_id,
		"hint_id":hint_id,
		"legal_ids":legal_ids(),
		"last_event":last_event.duplicate(true),
	}


func recovery_snapshot() -> Dictionary:
	return {
		"schema":RECOVERY_SCHEMA,
		"game_id":GAME_ID,
		"level_id":LEVEL_ID,
		"removed_ids":removed_ids.duplicate(),
		"moves":moves,
		"score":score,
		"status":status,
		"focus_id":focus_id,
		"hint_id":hint_id,
	}


func restore(payload: Dictionary) -> bool:
	var normalized := _validated_recovery(payload)
	if normalized.is_empty():
		return false
	removed_ids.assign(normalized["removed_ids"])
	moves = int(normalized["moves"])
	score = int(normalized["score"])
	status = PLAYING
	terminal_reason = ""
	focus_id = str(normalized["focus_id"])
	hint_id = str(normalized["hint_id"])
	last_event = {"kind":"recovered", "removed_count":removed_ids.size(), "remaining":remaining_count(), "status":status}
	return true


func topology_valid() -> bool:
	var ids: Array[String] = []
	var occupied := {}
	for arrow in arrows:
		var arrow_id := str(arrow.get("id", ""))
		if arrow_id.is_empty() or arrow_id in ids:
			return false
		ids.append(arrow_id)
		if not arrow.get("path", null) is Array:
			return false
		var path: Array = arrow.path
		if path.size() < 2:
			return false
		for index in range(path.size()):
			var point := Vector2i(path[index])
			if not _in_bounds(point) or occupied.has(point):
				return false
			occupied[point] = arrow_id
			if index > 0:
				var delta := point - Vector2i(path[index - 1])
				if abs(delta.x) + abs(delta.y) != 1:
					return false
		var expected := Vector2i(path[-1]) - Vector2i(path[-2])
		if Vector2i(arrow.get("direction", Vector2i.ZERO)) != expected or abs(expected.x) + abs(expected.y) != 1:
			return false
	return true


func _validated_recovery(payload: Dictionary) -> Dictionary:
	if str(payload.get("schema", "")) != RECOVERY_SCHEMA or str(payload.get("game_id", "")) != GAME_ID or str(payload.get("level_id", "")) != LEVEL_ID:
		return {}
	if str(payload.get("status", "")) != PLAYING or not payload.get("removed_ids", null) is Array:
		return {}
	var all_ids := arrow_ids()
	var candidate_removed: Array[String] = []
	for value in payload.removed_ids:
		if not value is String:
			return {}
		var arrow_id := str(value)
		if arrow_id not in all_ids or arrow_id in candidate_removed:
			return {}
		candidate_removed.append(arrow_id)
	if candidate_removed.size() >= all_ids.size():
		return {}

	# Replay the ordered history against the canonical sweep kernel. A plausible
	# set with an impossible removal order is rejected rather than normalized.
	var saved_removed := removed_ids.duplicate()
	var saved_status := status
	removed_ids.clear()
	status = PLAYING
	for arrow_id in candidate_removed:
		if not is_legal(arrow_id):
			removed_ids = saved_removed
			status = saved_status
			return {}
		removed_ids.append(arrow_id)
	var candidate_has_legal := not legal_ids().is_empty()
	removed_ids = saved_removed
	status = saved_status
	if not candidate_has_legal:
		return {}

	var candidate_moves := _strict_nonnegative_int(payload.get("moves", null))
	var candidate_score := _strict_nonnegative_int(payload.get("score", null))
	if candidate_moves != candidate_removed.size() or candidate_score != _score_for(candidate_removed):
		return {}
	var candidate_focus := str(payload.get("focus_id", ""))
	var candidate_hint := str(payload.get("hint_id", ""))
	var live_after: Array[String] = []
	for arrow_id in all_ids:
		if arrow_id not in candidate_removed:
			live_after.append(arrow_id)
	if candidate_focus not in live_after:
		return {}
	if not candidate_hint.is_empty() and candidate_hint not in live_after:
		return {}
	return {
		"removed_ids":candidate_removed,
		"moves":candidate_moves,
		"score":candidate_score,
		"focus_id":candidate_focus,
		"hint_id":candidate_hint,
	}


func _score_for(ids: Array[String]) -> int:
	var result := 0
	for arrow_id in ids:
		result += BASE_CLEAR_SCORE + bend_count(arrow_id) * BEND_BONUS
	return result


func _live_occupancy(except_id := "") -> Dictionary:
	var occupied := {}
	for arrow in arrows:
		var arrow_id := str(arrow.id)
		if arrow_id == except_id or arrow_id in removed_ids:
			continue
		for point in arrow.path:
			occupied[Vector2i(point)] = arrow_id
	return occupied


func _focus_after_removal(removed_id: String) -> void:
	var live := live_ids()
	if live.is_empty():
		focus_id = ""
		return
	var all_ids := arrow_ids()
	var removed_index := all_ids.find(removed_id)
	for offset in range(1, all_ids.size() + 1):
		var candidate := all_ids[(removed_index + offset) % all_ids.size()]
		if candidate in live:
			focus_id = candidate
			return


func _canonical_arrows() -> Array[Dictionary]:
	return [
		_arrow("a", [Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4)]),
		_arrow("b", [Vector2i(7, 4), Vector2i(7, 3), Vector2i(8, 3)]),
		_arrow("c", [Vector2i(2, 2), Vector2i(2, 3), Vector2i(2, 4)]),
		_arrow("d", [Vector2i(2, 6), Vector2i(3, 6)]),
		_arrow("e", [Vector2i(5, 2), Vector2i(5, 1), Vector2i(6, 1)]),
		_arrow("f", [Vector2i(8, 7), Vector2i(7, 7), Vector2i(6, 7)]),
		_arrow("g", [Vector2i(4, 7), Vector2i(4, 8), Vector2i(3, 8)]),
		_arrow("h", [Vector2i(1, 6), Vector2i(1, 5)]),
		_arrow("i", [Vector2i(8, 0), Vector2i(8, 1)]),
		_arrow("j", [Vector2i(0, 0), Vector2i(1, 0)]),
		_arrow("k", [Vector2i(0, 7), Vector2i(0, 8)]),
		_arrow("l", [Vector2i(8, 8), Vector2i(7, 8)]),
	]


func _arrow(arrow_id: String, path: Array[Vector2i]) -> Dictionary:
	return {"id":arrow_id, "path":path, "direction":path[-1] - path[-2]}


func _packed_path(path: Array[Vector2i]) -> Array:
	var result: Array = []
	for point in path:
		result.append([point.x, point.y])
	return result


func _packed_vector(vector: Vector2i) -> Array:
	return [vector.x, vector.y]


func _record(event: Dictionary) -> Dictionary:
	last_event = event.duplicate(true)
	return last_event.duplicate(true)


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < WIDTH and cell.y < HEIGHT


func _strict_nonnegative_int(value: Variant) -> int:
	if value is int and int(value) >= 0:
		return int(value)
	if value is float and is_finite(float(value)) and float(value) == floorf(float(value)) and float(value) >= 0.0:
		return int(value)
	return -1
