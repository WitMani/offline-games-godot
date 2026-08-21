extends RefCounted

## Renderer-free, deterministic Mahjong Solitaire rules for the bounded Vita
## Mahjong alignment slice. Coordinates are expressed in half-tile logical
## units: every tile owns a 2 x 2 footprint.

const SCHEMA_VERSION := 3
const TILE_FOOTPRINT := Vector2(2.0, 2.0)
const POINT_EPSILON := 0.001
const SCORE_PER_PAIR := 50
const FACE_COUNT := 18

const FACE_NAMES := [
	"wind_east", "wind_south", "wind_west", "wind_north",
	"dragon_red", "dragon_green", "dragon_white",
	"dot_1", "dot_2", "dot_3", "dot_4",
	"bamboo_1", "bamboo_2", "bamboo_3", "bamboo_4",
	"character_1", "character_2", "character_3",
]

var tiles: Array[Dictionary] = []
var removed: Array[int] = []
var selected := -1
var hint_pair: Array[int] = []
var last_pair: Array[int] = []
var status := "playing"
var score := 0
var moves := 0
var mistakes := 0
var blocked_attempts := 0
var reshuffles := 0
var history: Array[Dictionary] = []


func _init() -> void:
	reset()


func reset() -> void:
	tiles = _canonical_tiles()
	removed = []
	selected = -1
	hint_pair = []
	last_pair = []
	status = "playing"
	score = 0
	moves = 0
	mistakes = 0
	blocked_attempts = 0
	reshuffles = 0
	history = []


func _canonical_tiles() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var next_id := 0
	var next_face := 7
	# Four six-tile base rows peel from their open ends toward the center.
	for gy in [0, 2, 4, 6]:
		var row_faces := [next_face, next_face + 1, next_face + 2, next_face + 2, next_face + 1, next_face]
		for column in range(6):
			result.append(_tile(next_id, int(row_faces[column]), column * 2, gy, 0))
			next_id += 1
		next_face += 3
	# Two four-tile bridges form the visible second layer.
	for row_data in [[1, 3, 4], [5, 5, 6]]:
		var gy := int(row_data[0])
		var outer_face := int(row_data[1])
		var inner_face := int(row_data[2])
		for column in range(4):
			var face := outer_face if column in [0, 3] else inner_face
			result.append(_tile(next_id, face, 2 + column * 2, gy, 1))
			next_id += 1
	# The two cap pairs are initially free and unlock both bridges.
	for cap_data in [[2, 1], [4, 2]]:
		for gx in [3, 5]:
			result.append(_tile(next_id, int(cap_data[1]), gx, int(cap_data[0]), 2))
			next_id += 1
	return result


func _tile(id: int, face: int, gx: int, gy: int, layer: int) -> Dictionary:
	return {"id":id, "face":face, "gx":gx, "gy":gy, "layer":layer}


func tile_count() -> int:
	return tiles.size()


func remaining_count() -> int:
	return tiles.size() - removed.size()


func is_active(index: int) -> bool:
	return index >= 0 and index < tiles.size() and index not in removed


func logical_rect(index: int) -> Rect2:
	if index < 0 or index >= tiles.size():
		return Rect2()
	var tile_data: Dictionary = tiles[index]
	return Rect2(Vector2(float(tile_data["gx"]), float(tile_data["gy"])), TILE_FOOTPRINT)


func logical_center(index: int) -> Vector2:
	return logical_rect(index).get_center()


func _overlap_extent(a_start: float, a_end: float, b_start: float, b_end: float) -> float:
	return maxf(0.0, minf(a_end, b_end) - maxf(a_start, b_start))


func _rects_overlap(a: Rect2, b: Rect2) -> bool:
	return _overlap_extent(a.position.x, a.end.x, b.position.x, b.end.x) > POINT_EPSILON \
		and _overlap_extent(a.position.y, a.end.y, b.position.y, b.end.y) > POINT_EPSILON


func is_covered(index: int) -> bool:
	if not is_active(index):
		return false
	var own: Dictionary = tiles[index]
	var own_rect := logical_rect(index)
	for other_index in range(tiles.size()):
		if not is_active(other_index) or other_index == index:
			continue
		var other: Dictionary = tiles[other_index]
		if int(other["layer"]) <= int(own["layer"]):
			continue
		if _rects_overlap(own_rect, logical_rect(other_index)):
			return true
	return false


func side_blockers(index: int) -> Dictionary:
	var result := {"left":false, "right":false, "left_indices":[], "right_indices":[]}
	if not is_active(index):
		return result
	var own: Dictionary = tiles[index]
	var own_rect := logical_rect(index)
	for other_index in range(tiles.size()):
		if not is_active(other_index) or other_index == index:
			continue
		var other: Dictionary = tiles[other_index]
		if int(other["layer"]) != int(own["layer"]):
			continue
		var other_rect := logical_rect(other_index)
		var vertical_overlap := _overlap_extent(own_rect.position.y, own_rect.end.y, other_rect.position.y, other_rect.end.y)
		if vertical_overlap <= POINT_EPSILON:
			continue
		if absf(other_rect.end.x - own_rect.position.x) <= POINT_EPSILON:
			result["left"] = true
			result["left_indices"].append(other_index)
		if absf(other_rect.position.x - own_rect.end.x) <= POINT_EPSILON:
			result["right"] = true
			result["right_indices"].append(other_index)
	return result


func is_free(index: int) -> bool:
	if not is_active(index) or is_covered(index):
		return false
	var sides := side_blockers(index)
	return not bool(sides["left"]) or not bool(sides["right"])


func free_indices() -> Array[int]:
	var result: Array[int] = []
	for index in range(tiles.size()):
		if is_free(index):
			result.append(index)
	return result


func available_pairs() -> Array[Array]:
	var result: Array[Array] = []
	var free := free_indices()
	for left_offset in range(free.size()):
		var left := int(free[left_offset])
		for right_offset in range(left_offset + 1, free.size()):
			var right := int(free[right_offset])
			if int(tiles[left]["face"]) == int(tiles[right]["face"]):
				result.append([left, right])
	return result


func pair_multiset_is_valid() -> bool:
	if tiles.size() != FACE_COUNT * 2:
		return false
	var counts := {}
	for tile_data in tiles:
		var face := int(tile_data.get("face", 0))
		counts[face] = int(counts.get(face, 0)) + 1
	for face in range(1, FACE_COUNT + 1):
		if int(counts.get(face, 0)) != 2:
			return false
	return counts.size() == FACE_COUNT


func select_tile(index: int) -> Dictionary:
	if status in ["won", "stuck"]:
		return {"kind":"terminal_reject", "status":status, "index":index}
	if not is_active(index):
		return {"kind":"inert", "index":index}
	if not is_free(index):
		blocked_attempts += 1
		return {
			"kind":"blocked", "index":index, "covered":is_covered(index),
			"sides":side_blockers(index),
		}
	if selected < 0:
		selected = index
		hint_pair = []
		return {"kind":"selected", "index":index, "face":int(tiles[index]["face"])}
	if selected == index:
		selected = -1
		return {"kind":"deselected", "index":index}
	var first := selected
	if int(tiles[first]["face"]) != int(tiles[index]["face"]):
		selected = index
		mistakes += 1
		return {
			"kind":"mismatch", "indices":[first, index],
			"faces":[int(tiles[first]["face"]), int(tiles[index]["face"])],
		}
	history.append({
		"removed":removed.duplicate(), "moves":moves, "score":score,
		"last_pair":last_pair.duplicate(), "status":status,
	})
	removed.append(first)
	removed.append(index)
	removed.sort()
	selected = -1
	hint_pair = []
	last_pair = [first, index]
	moves += 1
	score += SCORE_PER_PAIR
	_refresh_status()
	return {
		"kind":"matched", "indices":[first, index],
		"face":int(tiles[index]["face"]), "remaining":remaining_count(),
		"status":status, "final":status == "won", "stuck":status == "stuck",
	}


func request_hint() -> Dictionary:
	if status == "won":
		return {"kind":"hint_reject", "status":status}
	var pairs := available_pairs()
	if pairs.is_empty():
		hint_pair = []
		_refresh_status()
		return {"kind":"no_hint", "status":status}
	hint_pair = [int(pairs[0][0]), int(pairs[0][1])]
	return {"kind":"hint", "indices":hint_pair.duplicate(), "face":int(tiles[hint_pair[0]]["face"])}


func reshuffle_remaining() -> Dictionary:
	if status == "won" or remaining_count() < 2:
		return {"kind":"shuffle_reject", "status":status}
	var active: Array[int] = []
	var face_pool: Array[int] = []
	for index in range(tiles.size()):
		if is_active(index):
			active.append(index)
			face_pool.append(int(tiles[index]["face"]))
	face_pool.sort()
	var free := free_indices()
	if free.size() < 2:
		return {"kind":"shuffle_reject", "status":"no_free_pair_slots"}
	var guaranteed_face := -1
	for face in face_pool:
		if face_pool.count(face) >= 2:
			guaranteed_face = face
			break
	if guaranteed_face < 0:
		return {"kind":"shuffle_reject", "status":"invalid_face_multiset"}
	var targets: Array[int] = [int(free[0]), int(free[1])]
	for _copy in range(2):
		face_pool.erase(guaranteed_face)
	tiles[targets[0]]["face"] = guaranteed_face
	tiles[targets[1]]["face"] = guaranteed_face
	var pool_index := 0
	for index in active:
		if index in targets:
			continue
		tiles[index]["face"] = int(face_pool[pool_index])
		pool_index += 1
	selected = -1
	hint_pair = targets.duplicate()
	last_pair = []
	history = []
	reshuffles += 1
	_refresh_status()
	return {"kind":"reshuffled", "indices":targets, "face":guaranteed_face, "status":status}


func undo_pair() -> Dictionary:
	if history.is_empty():
		return {"kind":"undo_reject"}
	var previous: Dictionary = history.pop_back()
	var restored_pair := last_pair.duplicate()
	removed = _int_array(previous["removed"])
	moves = int(previous["moves"])
	score = int(previous["score"])
	last_pair = _int_array(previous["last_pair"])
	selected = -1
	hint_pair = []
	status = "playing"
	return {"kind":"undone", "indices":restored_pair, "remaining":remaining_count()}


func _refresh_status() -> void:
	if remaining_count() == 0:
		status = "won"
		selected = -1
		hint_pair = []
	elif available_pairs().is_empty():
		status = "stuck"
		selected = -1
		hint_pair = []
	else:
		status = "playing"


func refresh_status_for_test() -> String:
	_refresh_status()
	return status


func topmost_at_logical(point: Vector2) -> int:
	var best := -1
	var best_key := Vector3(-1, -1, -1)
	for index in range(tiles.size()):
		if not is_active(index) or not logical_rect(index).has_point(point):
			continue
		var tile_data: Dictionary = tiles[index]
		var key := Vector3(float(tile_data["layer"]), float(tile_data["gy"]), float(tile_data["id"]))
		if best < 0 or _key_after(key, best_key):
			best = index
			best_key = key
	return best


func _key_after(a: Vector3, b: Vector3) -> bool:
	if a.x != b.x:
		return a.x > b.x
	if a.y != b.y:
		return a.y > b.y
	return a.z > b.z


func first_focus() -> int:
	var free := free_indices()
	return -1 if free.is_empty() else int(free[0])


func focus_neighbor(current: int, direction: Vector2) -> int:
	if direction.length_squared() <= POINT_EPSILON:
		return current
	if not is_active(current):
		return first_focus()
	var origin := logical_center(current)
	var unit := direction.normalized()
	var best := current
	var best_cost := INF
	for index in range(tiles.size()):
		if not is_active(index) or index == current:
			continue
		var delta := logical_center(index) - origin
		var forward := delta.dot(unit)
		if forward <= POINT_EPSILON:
			continue
		var sideways := absf(delta.cross(unit))
		var cost := forward + sideways * 2.4 + float(int(tiles[index]["layer"])) * 0.01
		if cost < best_cost:
			best_cost = cost
			best = index
	return best


func snapshot() -> Dictionary:
	return {
		"mahjong_schema":SCHEMA_VERSION,
		"tiles":tiles.duplicate(true),
		"removed":removed.duplicate(),
		"selected":selected,
		"hint_pair":hint_pair.duplicate(),
		"last_pair":last_pair.duplicate(),
		"status":status,
		"score":score,
		"moves":moves,
		"mistakes":mistakes,
		"blocked_attempts":blocked_attempts,
		"reshuffles":reshuffles,
	}


func restore(candidate: Dictionary) -> bool:
	var previous := snapshot()
	if int(candidate.get("mahjong_schema", -1)) != SCHEMA_VERSION:
		return false
	var candidate_tiles: Variant = candidate.get("tiles", null)
	var candidate_removed: Variant = candidate.get("removed", null)
	if not candidate_tiles is Array or not candidate_removed is Array:
		return false
	if candidate_tiles.size() != FACE_COUNT * 2:
		return false
	var canonical := _canonical_tiles()
	var ids := {}
	var face_counts := {}
	var clean_tiles: Array[Dictionary] = []
	for value in candidate_tiles:
		if not value is Dictionary:
			return false
		var tile_data: Dictionary = value
		var id := int(tile_data.get("id", -1))
		if id < 0 or id >= canonical.size() or ids.has(id):
			return false
		ids[id] = true
		var expected: Dictionary = canonical[id]
		for field in ["gx", "gy", "layer"]:
			if int(tile_data.get(field, -999)) != int(expected[field]):
				return false
		var face := int(tile_data.get("face", 0))
		if face < 1 or face > FACE_COUNT:
			return false
		face_counts[face] = int(face_counts.get(face, 0)) + 1
		clean_tiles.append(_tile(id, face, int(expected["gx"]), int(expected["gy"]), int(expected["layer"])))
	clean_tiles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["id"]) < int(b["id"]))
	for face in range(1, FACE_COUNT + 1):
		if int(face_counts.get(face, 0)) != 2:
			return false
	var clean_removed := _int_array(candidate_removed)
	if clean_removed.size() != candidate_removed.size() or clean_removed.size() % 2 != 0:
		return false
	var removed_set := {}
	var removed_face_counts := {}
	for index in clean_removed:
		if index < 0 or index >= clean_tiles.size() or removed_set.has(index):
			return false
		removed_set[index] = true
		var face := int(clean_tiles[index]["face"])
		removed_face_counts[face] = int(removed_face_counts.get(face, 0)) + 1
	for face in removed_face_counts:
		if int(removed_face_counts[face]) % 2 != 0:
			return false
	var candidate_moves := int(candidate.get("moves", -1))
	var candidate_score := int(candidate.get("score", -1))
	if candidate_moves != clean_removed.size() / 2 or candidate_score != candidate_moves * SCORE_PER_PAIR:
		return false
	for nonnegative_field in ["mistakes", "blocked_attempts", "reshuffles"]:
		if int(candidate.get(nonnegative_field, -1)) < 0:
			return false
	# Commit the validated structural data, then validate derived availability.
	tiles = clean_tiles
	removed = clean_removed
	removed.sort()
	selected = int(candidate.get("selected", -1))
	hint_pair = _int_array(candidate.get("hint_pair", []))
	last_pair = _int_array(candidate.get("last_pair", []))
	moves = candidate_moves
	score = candidate_score
	mistakes = int(candidate["mistakes"])
	blocked_attempts = int(candidate["blocked_attempts"])
	reshuffles = int(candidate["reshuffles"])
	history = []
	var expected_status := "won" if remaining_count() == 0 else ("stuck" if available_pairs().is_empty() else "playing")
	if str(candidate.get("status", "")) != expected_status:
		_restore_trusted(previous)
		return false
	status = expected_status
	if selected >= 0 and (status != "playing" or not is_free(selected)):
		_restore_trusted(previous)
		return false
	if hint_pair.size() not in [0, 2]:
		_restore_trusted(previous)
		return false
	if hint_pair.size() == 2:
		if not is_free(hint_pair[0]) or not is_free(hint_pair[1]) or int(tiles[hint_pair[0]]["face"]) != int(tiles[hint_pair[1]]["face"]):
			_restore_trusted(previous)
			return false
	return true


func _restore_trusted(data: Dictionary) -> void:
	tiles = data["tiles"].duplicate(true)
	removed = _int_array(data["removed"])
	selected = int(data["selected"])
	hint_pair = _int_array(data["hint_pair"])
	last_pair = _int_array(data["last_pair"])
	status = str(data["status"])
	score = int(data["score"])
	moves = int(data["moves"])
	mistakes = int(data["mistakes"])
	blocked_attempts = int(data["blocked_attempts"])
	reshuffles = int(data["reshuffles"])
	history = []


func _int_array(source: Variant) -> Array[int]:
	var result: Array[int] = []
	if not source is Array:
		return result
	for value in source:
		if not (value is int or value is float):
			return []
		var converted := int(value)
		if float(value) != float(converted):
			return []
		result.append(converted)
	return result
