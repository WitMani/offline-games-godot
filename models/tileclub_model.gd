class_name TileClubModel
extends RefCounted

## Renderer-independent clean-room model for the bounded Tile Club loop.
##
## Tiles have authored positions and layers. A live tile is selectable only
## when no live tile on a higher layer overlaps it. Selecting an exposed tile
## appends its value to the ordered seven-slot tray. Three identical values
## resolve before the full-tray check, preserving the ordering of all others.

const RUNNING := "playing"
const WON := "won"
const OVER := "over"
const TRAY_CAPACITY := 7
const TILE_FOOTPRINT := Vector2(1.0, 1.0)
const BLOCKING_OVERLAP_FRACTION := 0.18
const CHECKPOINT_SCHEMA := "offline-games.tileclub.checkpoint.v1"
const RULES_VERSION := "tileclub-stage0-v1"
const MAX_CHECKPOINT_ACTIONS := 10000

# The layouts are original deterministic mechanics fixtures. They reproduce
# no reference level data. Each "nest" becomes two lower tiles and one upper
# tile of the same value, which makes every fixture solvable while exercising
# overlap, reveal, ordered tray, triple resolution, and terminal states.
const LEVELS := [
	{
		"id":"four_nests_intro",
		"name":"四组入门",
		"nests":[
			[0.00, 0.00, 1], [1.55, 0.00, 2],
			[0.78, 1.55, 3], [2.33, 1.55, 4],
		],
	},
	{
		"id":"six_nests_ribbon",
		"name":"六组彩带",
		"nests":[
			[0.00, 0.00, 1], [1.55, 0.00, 2], [3.10, 0.00, 3],
			[0.00, 1.55, 4], [1.55, 1.55, 5], [3.10, 1.55, 6],
		],
	},
	{
		"id":"seven_nests_fan",
		"name":"七组扇面",
		"nests":[
			[0.00, 0.00, 1], [1.55, 0.00, 2], [3.10, 0.00, 3], [4.65, 0.00, 4],
			[0.78, 1.55, 5], [2.33, 1.55, 6], [3.88, 1.55, 7],
		],
	},
]

var level_index := 0
var level_id := ""
var level_name := ""
var tiles: Array[Dictionary] = []
var tray: Array[int] = []
var action_history: Array[int] = []
var score := 0
var moves := 0
var matches := 0
var status := RUNNING


func reset(requested_level: int = 0) -> void:
	level_index = posmod(requested_level, LEVELS.size())
	var definition: Dictionary = LEVELS[level_index]
	level_id = str(definition["id"])
	level_name = str(definition["name"])
	tiles.clear()
	tray.clear()
	action_history.clear()
	score = 0
	moves = 0
	matches = 0
	status = RUNNING
	var next_id := 0
	for raw_nest in definition["nests"]:
		var nest: Array = raw_nest
		var center := Vector2(float(nest[0]), float(nest[1]))
		var value := int(nest[2])
		# Lower pair first: draw order remains back-to-front, while the upper
		# member is the only initially selectable tile in this nest.
		tiles.append(_new_tile(next_id, value, center + Vector2(-0.32, 0.20), 0))
		next_id += 1
		tiles.append(_new_tile(next_id, value, center + Vector2(0.32, -0.20), 0))
		next_id += 1
		tiles.append(_new_tile(next_id, value, center, 1))
		next_id += 1
	_validate_level()


func restart() -> void:
	reset(level_index)


func advance_level() -> bool:
	if status != WON:
		return false
	reset(level_index + 1)
	return true


func collect(tile_id: int) -> Dictionary:
	if status != RUNNING:
		return _rejected_outcome("terminal", tile_id)
	var tile: Dictionary = tile_by_id(tile_id)
	if tile.is_empty():
		return _rejected_outcome("invalid_tile", tile_id)
	if not bool(tile["active"]):
		return _rejected_outcome("removed", tile_id)
	var blockers := blockers_for(tile_id)
	if not blockers.is_empty():
		var blocked := _rejected_outcome("covered", tile_id)
		blocked["blockers"] = blockers
		return blocked

	var selectable_before := selectable_ids()
	var layers_before := _active_counts_by_layer()
	var value := int(tile["value"])
	var insert_index := tray.size()
	tile["active"] = false
	tray.append(value)
	action_history.append(tile_id)
	moves += 1

	var matched_indices: Array[int] = []
	for index in range(tray.size()):
		if tray[index] == value:
			matched_indices.append(index)
	var matched := matched_indices.size() >= 3
	if matched:
		matched_indices = matched_indices.slice(0, 3)
		for index in range(matched_indices.size() - 1, -1, -1):
			tray.remove_at(matched_indices[index])
		matches += 1
		score += 100
	else:
		matched_indices.clear()

	var selectable_after := selectable_ids()
	var newly_exposed: Array[int] = []
	for available_id in selectable_after:
		if available_id not in selectable_before:
			newly_exposed.append(available_id)
	var layers_after := _active_counts_by_layer()
	var cleared_layers: Array[int] = []
	for layer in layers_before:
		if int(layers_before[layer]) > 0 and int(layers_after.get(layer, 0)) == 0:
			cleared_layers.append(int(layer))
	cleared_layers.sort()

	var completed := active_tile_count() == 0 and tray.is_empty()
	if completed:
		status = WON
	elif tray.size() >= TRAY_CAPACITY:
		status = OVER
	return {
		"changed":true,
		"reason":"matched" if matched else "collected",
		"tile_id":tile_id,
		"value":value,
		"insert_index":insert_index,
		"matched":matched,
		"matched_indices":matched_indices.duplicate(),
		"newly_exposed":newly_exposed,
		"cleared_layers":cleared_layers,
		"tray":tray.duplicate(),
		"tray_count":tray.size(),
		"remaining_slots":TRAY_CAPACITY - tray.size(),
		"remaining_tiles":active_tile_count(),
		"completed":completed,
		"failed":status == OVER,
		"status":status,
		"score_delta":100 if matched else 0,
		"moves":moves,
		"matches":matches,
	}


func tile_by_id(tile_id: int) -> Dictionary:
	for tile in tiles:
		if int(tile["id"]) == tile_id:
			return tile
	return {}


func blockers_for(tile_id: int) -> Array[int]:
	var result: Array[int] = []
	var tile := tile_by_id(tile_id)
	if tile.is_empty() or not bool(tile["active"]):
		return result
	for other in tiles:
		if not bool(other["active"]) or int(other["layer"]) <= int(tile["layer"]):
			continue
		if _overlap_fraction(tile, other) >= BLOCKING_OVERLAP_FRACTION:
			result.append(int(other["id"]))
	result.sort()
	return result


func is_selectable(tile_id: int) -> bool:
	var tile := tile_by_id(tile_id)
	return not tile.is_empty() and bool(tile["active"]) and blockers_for(tile_id).is_empty() and status == RUNNING


func selectable_ids() -> Array[int]:
	var result: Array[int] = []
	if status != RUNNING:
		return result
	for tile in tiles:
		if bool(tile["active"]) and blockers_for(int(tile["id"])).is_empty():
			result.append(int(tile["id"]))
	result.sort_custom(func(a: int, b: int) -> bool:
		var first := tile_by_id(a)
		var second := tile_by_id(b)
		if not is_equal_approx(float(first["y"]), float(second["y"])):
			return float(first["y"]) < float(second["y"])
		if not is_equal_approx(float(first["x"]), float(second["x"])):
			return float(first["x"]) < float(second["x"])
		return a < b
	)
	return result


func active_tiles_draw_order() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for tile in tiles:
		if bool(tile["active"]):
			result.append(tile.duplicate())
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["layer"]) != int(b["layer"]):
			return int(a["layer"]) < int(b["layer"])
		if not is_equal_approx(float(a["y"]), float(b["y"])):
			return float(a["y"]) < float(b["y"])
		return int(a["id"]) < int(b["id"])
	)
	return result


func active_tile_count() -> int:
	var result := 0
	for tile in tiles:
		if bool(tile["active"]):
			result += 1
	return result


func layer_count() -> int:
	var highest := -1
	for tile in tiles:
		highest = maxi(highest, int(tile["layer"]))
	return highest + 1


func board_bounds() -> Rect2:
	if tiles.is_empty():
		return Rect2()
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for tile in tiles:
		var center := Vector2(float(tile["x"]), float(tile["y"]))
		minimum = minimum.min(center - TILE_FOOTPRINT * 0.5)
		maximum = maximum.max(center + TILE_FOOTPRINT * 0.5)
	return Rect2(minimum, maximum - minimum)


func level_count() -> int:
	return LEVELS.size()


func solution_for_level(requested_level: int = -1) -> Array[int]:
	var index := level_index if requested_level < 0 else posmod(requested_level, LEVELS.size())
	var result: Array[int] = []
	var nest_count: int = LEVELS[index]["nests"].size()
	for nest_index in range(nest_count):
		var base := nest_index * 3
		result.append(base + 2)
		result.append(base)
		result.append(base + 1)
	return result


func checkpoint() -> Dictionary:
	return {
		"schema":CHECKPOINT_SCHEMA,
		"rules_version":RULES_VERSION,
		"level_index":level_index,
		"level_id":level_id,
		"actions":action_history.duplicate(),
		"tray":tray.duplicate(),
		"active_ids":_active_ids(),
		"moves":moves,
		"matches":matches,
		"score":score,
		"status":status,
	}


func restore(payload: Variant) -> bool:
	if not payload is Dictionary:
		return false
	var data: Dictionary = payload
	if str(data.get("schema", "")) != CHECKPOINT_SCHEMA or str(data.get("rules_version", "")) != RULES_VERSION:
		return false
	if not _is_exact_integer(data.get("level_index")):
		return false
	var requested_level := int(data["level_index"])
	if requested_level < 0 or requested_level >= LEVELS.size():
		return false
	if str(data.get("level_id", "")) != str(LEVELS[requested_level]["id"]):
		return false
	var raw_actions: Variant = data.get("actions")
	if not raw_actions is Array or raw_actions.size() > MAX_CHECKPOINT_ACTIONS:
		return false

	var candidate = get_script().new()
	candidate.reset(requested_level)
	for raw_id in raw_actions:
		if not _is_exact_integer(raw_id):
			return false
		var outcome: Dictionary = candidate.collect(int(raw_id))
		if not bool(outcome.get("changed", false)):
			return false
	if not _checkpoint_matches_candidate(data, candidate):
		return false
	_adopt(candidate)
	return true


func snapshot() -> Dictionary:
	var snapshot_tiles: Array[Dictionary] = []
	for tile in tiles:
		var entry := tile.duplicate()
		entry["selectable"] = is_selectable(int(tile["id"]))
		entry["blockers"] = blockers_for(int(tile["id"])) if bool(tile["active"]) else []
		snapshot_tiles.append(entry)
	var bounds := board_bounds()
	return {
		"rules_version":RULES_VERSION,
		"level_index":level_index,
		"level_number":level_index + 1,
		"level_count":level_count(),
		"level_id":level_id,
		"level_name":level_name,
		"tiles":snapshot_tiles,
		"tray":tray.duplicate(),
		"tray_capacity":TRAY_CAPACITY,
		"remaining_slots":TRAY_CAPACITY - tray.size(),
		"active_count":active_tile_count(),
		"selectable_ids":selectable_ids(),
		"layer_count":layer_count(),
		"bounds":[bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y],
		"score":score,
		"moves":moves,
		"matches":matches,
		"status":status,
	}


func _new_tile(tile_id: int, value: int, center: Vector2, layer: int) -> Dictionary:
	return {
		"id":tile_id,
		"value":value,
		"x":center.x,
		"y":center.y,
		"layer":layer,
		"active":true,
	}


func _overlap_fraction(first: Dictionary, second: Dictionary) -> float:
	var delta := Vector2(absf(float(first["x"]) - float(second["x"])), absf(float(first["y"]) - float(second["y"])))
	var overlap := Vector2(maxf(0.0, TILE_FOOTPRINT.x - delta.x), maxf(0.0, TILE_FOOTPRINT.y - delta.y))
	return overlap.x * overlap.y / (TILE_FOOTPRINT.x * TILE_FOOTPRINT.y)


func _active_ids() -> Array[int]:
	var result: Array[int] = []
	for tile in tiles:
		if bool(tile["active"]):
			result.append(int(tile["id"]))
	return result


func _active_counts_by_layer() -> Dictionary:
	var counts := {}
	for tile in tiles:
		if bool(tile["active"]):
			var layer := int(tile["layer"])
			counts[layer] = int(counts.get(layer, 0)) + 1
	return counts


func _rejected_outcome(reason: String, tile_id: int) -> Dictionary:
	return {
		"changed":false,
		"reason":reason,
		"tile_id":tile_id,
		"value":0,
		"insert_index":tray.size(),
		"matched":false,
		"matched_indices":[],
		"newly_exposed":[],
		"cleared_layers":[],
		"blockers":[],
		"tray":tray.duplicate(),
		"tray_count":tray.size(),
		"remaining_slots":TRAY_CAPACITY - tray.size(),
		"remaining_tiles":active_tile_count(),
		"completed":status == WON,
		"failed":status == OVER,
		"status":status,
		"score_delta":0,
		"moves":moves,
		"matches":matches,
	}


func _checkpoint_matches_candidate(data: Dictionary, candidate) -> bool:
	for field in ["moves", "matches", "score"]:
		if not _is_exact_integer(data.get(field)):
			return false
	var raw_tray: Variant = data.get("tray")
	var raw_active: Variant = data.get("active_ids")
	if not raw_tray is Array or not raw_active is Array:
		return false
	var decoded_tray: Array[int] = []
	for raw_value in raw_tray:
		if not _is_exact_integer(raw_value):
			return false
		decoded_tray.append(int(raw_value))
	var decoded_active: Array[int] = []
	for raw_id in raw_active:
		if not _is_exact_integer(raw_id):
			return false
		decoded_active.append(int(raw_id))
	return (
		decoded_tray == candidate.tray
		and decoded_active == candidate._active_ids()
		and int(data["moves"]) == candidate.moves
		and int(data["matches"]) == candidate.matches
		and int(data["score"]) == candidate.score
		and str(data.get("status", "")) == candidate.status
	)


func _adopt(candidate) -> void:
	level_index = candidate.level_index
	level_id = candidate.level_id
	level_name = candidate.level_name
	tiles = candidate.tiles.duplicate(true)
	tray = candidate.tray.duplicate()
	action_history = candidate.action_history.duplicate()
	score = candidate.score
	moves = candidate.moves
	matches = candidate.matches
	status = candidate.status


func _is_exact_integer(value: Variant) -> bool:
	return value is int or (value is float and is_equal_approx(value, roundf(value)))


func _validate_level() -> void:
	assert(not tiles.is_empty(), "Tile Club fixture must contain tiles")
	var ids := {}
	var counts := {}
	for tile in tiles:
		var tile_id := int(tile["id"])
		assert(not ids.has(tile_id), "Tile Club tile ids must be unique")
		ids[tile_id] = true
		var value := int(tile["value"])
		assert(value > 0, "Tile Club values must be positive")
		counts[value] = int(counts.get(value, 0)) + 1
	for value in counts:
		assert(int(counts[value]) % 3 == 0, "Tile Club value counts must be divisible by three")
	assert(not selectable_ids().is_empty(), "Tile Club fixture must begin with an exposed tile")
