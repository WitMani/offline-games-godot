class_name Merge2248Model
extends RefCounted

## Renderer-independent clean-room model for Number Connect / 2248.
##
## Tiles are stored as power-of-two exponents (`1` means 2, `2` means 4).
## That keeps an endless run exact after ordinary 64-bit tile values would
## overflow. Score and all-time score are exact arbitrary-length binary values
## with decimal strings at the public boundary.

const CONTRACT_VERSION := 4
const SAVE_SCHEMA := "offline-games.merge2248-save.v4"
const RUNNING := "playing"
const OVER := "over"

const MODE_EASY := "easy"
const MODE_HARD := "hard"
const MODE_MEDIUM_COMPAT := "medium_compat"
const MODE_EXTRA_HARD_COMPAT := "extra_hard_compat"
const MODE_ROWS := {
	MODE_EASY: 8,
	MODE_MEDIUM_COMPAT: 7,
	MODE_HARD: 6,
	MODE_EXTRA_HARD_COMPAT: 5,
}
const VERIFIED_MODES := [MODE_EASY, MODE_HARD]
const METRIC_SUFFIXES := ["", "k", "M", "G", "T", "P", "E", "Z", "Y", "R", "Q"]

var width := 5
var height := 8
var mode := MODE_EASY
var board: Array = []
var selected: Array[Vector2i] = []
var score_bits: Array[int] = [0]
var best_bits: Array[int] = [0]
var score := "0"
var all_time := "0"
var moves := 0
var status := RUNNING
var rng := RandomNumberGenerator.new()
var undo_state: Dictionary = {}


func reset(seed_value: int = 2248, mode_or_rows: Variant = MODE_EASY, preserve_best := true) -> void:
	var retained_best: Array[int] = [0]
	if preserve_best:
		retained_best.assign(best_bits)
	mode = _normalize_mode(mode_or_rows)
	height = int(MODE_ROWS[mode])
	rng.seed = seed_value
	score_bits.clear()
	score_bits.append(0)
	best_bits.assign(retained_best)
	moves = 0
	status = RUNNING
	selected.clear()
	undo_state.clear()
	board.clear()
	for _y in range(height):
		var row: Array[int] = []
		for _x in range(width):
			row.append(_random_start_power())
		board.append(row)
	_ensure_opening_pair()
	_refresh_score_strings()


func set_mode(next_mode: String, seed_value: int = 2248) -> bool:
	if not MODE_ROWS.has(next_mode) or next_mode == mode:
		return false
	reset(seed_value, next_mode, true)
	return true


func is_mode_evidence_verified() -> bool:
	return mode in VERIFIED_MODES


func begin(cell: Vector2i) -> bool:
	selected.clear()
	if not _in_bounds(cell) or status != RUNNING:
		return false
	selected.append(cell)
	return true


func extend(cell: Vector2i) -> bool:
	# Repeated-cell rejection remains a labelled compatibility decision until a
	# reproducible original action trace settles backtracking behavior.
	if not _in_bounds(cell) or selected.is_empty() or cell in selected:
		return false
	var previous := selected[-1]
	if maxi(abs(cell.x - previous.x), abs(cell.y - previous.y)) != 1:
		return false
	var power := int(board[cell.y][cell.x])
	var previous_power := int(board[previous.y][previous.x])
	if selected.size() == 1:
		if power != previous_power:
			return false
	elif power != previous_power and power != previous_power + 1:
		return false
	selected.append(cell)
	return true


func cancel() -> void:
	selected.clear()


func release() -> Dictionary:
	if selected.size() < 2:
		selected.clear()
		return _unchanged_outcome()

	# One bounded undo restores the exact state and RNG position immediately
	# before the authoritative transition. Monetization is intentionally absent.
	undo_state = _core_payload()
	var path := selected.duplicate()
	var path_powers: Array[int] = []
	var gained_bits: Array[int] = [0]
	for cell in path:
		var power := int(board[cell.y][cell.x])
		path_powers.append(power)
		_add_power(gained_bits, power)
	var result_power := _result_power(path_powers)
	var destination: Vector2i = path[-1]
	for cell in path:
		board[cell.y][cell.x] = 0
	board[destination.y][destination.x] = result_power
	_apply_gravity()
	_refill()
	for power in path_powers:
		_add_power(score_bits, power)
	_normalize_bits(score_bits)
	if _compare_bits(score_bits, best_bits) > 0:
		best_bits.assign(score_bits)
	moves += 1
	selected.clear()
	# 2048 is deliberately not terminal. The no-pair boundary remains a named
	# compatibility fallback while the original loss/recovery flow is unknown.
	if not has_moves():
		status = OVER
	_refresh_score_strings()
	var gained_decimal := _bits_to_decimal(gained_bits)
	return {
		"changed": true,
		"gained": gained_decimal,
		"gained_label": format_score(gained_decimal),
		"result": power_value_or_zero(result_power),
		"result_power": result_power,
		"result_label": power_label(result_power),
		"destination": destination,
		"path": path,
		"path_powers": path_powers,
	}


func can_undo() -> bool:
	return not undo_state.is_empty()


func undo() -> bool:
	if undo_state.is_empty():
		return false
	var decoded := _decode_core(undo_state)
	if not bool(decoded.get("valid", false)):
		undo_state.clear()
		return false
	var retained_best: Array[int] = []
	retained_best.assign(best_bits)
	_apply_decoded(decoded)
	if _compare_bits(retained_best, best_bits) > 0:
		best_bits.assign(retained_best)
	undo_state.clear()
	selected.clear()
	_refresh_score_strings()
	return true


func preview_power() -> int:
	if selected.size() < 2:
		return 0
	var powers: Array[int] = []
	for cell in selected:
		powers.append(int(board[cell.y][cell.x]))
	return _result_power(powers)


func preview_result() -> int:
	return power_value_or_zero(preview_power())


func preview_label() -> String:
	var power := preview_power()
	return power_label(power) if power > 0 else ""


func has_moves() -> bool:
	for y in range(height):
		for x in range(width):
			var power := int(board[y][x])
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var other := Vector2i(x + dx, y + dy)
					if _in_bounds(other) and int(board[other.y][other.x]) == power:
						return true
	return false


func highest_power() -> int:
	var highest := 1
	for row in board:
		for power in row:
			highest = maxi(highest, int(power))
	return highest


func snapshot() -> Dictionary:
	var labels: Array = []
	for row in board:
		var label_row: Array[String] = []
		for power in row:
			label_row.append(power_label(int(power)))
		labels.append(label_row)
	var preview := preview_power()
	return {
		"contract_version": CONTRACT_VERSION,
		"board": board.duplicate(true),
		"board_encoding": "power_of_two_exponents",
		"board_labels": labels,
		"selected": selected.duplicate(),
		"score": score,
		"score_label": format_score(score),
		"all_time": all_time,
		"all_time_label": format_score(all_time),
		"score_bits": score_bits.duplicate(),
		"moves": moves,
		"status": status,
		"width": width,
		"height": height,
		"mode": mode,
		"mode_evidence_verified": is_mode_evidence_verified(),
		"preview": power_value_or_zero(preview),
		"preview_power": preview,
		"preview_label": power_label(preview) if preview > 0 else "",
		"highest_power": highest_power(),
		"highest_label": power_label(highest_power()),
		"can_undo": can_undo(),
	}


func serialize() -> Dictionary:
	return {
		"schema": SAVE_SCHEMA,
		"version": CONTRACT_VERSION,
		"core": _core_payload(),
		"best_bits": best_bits.duplicate(),
		"undo": undo_state.duplicate(true),
	}


func restore(payload: Dictionary) -> bool:
	if str(payload.get("schema", "")) != SAVE_SCHEMA or int(payload.get("version", -1)) != CONTRACT_VERSION:
		return false
	var decoded := _decode_core(payload.get("core", {}))
	if not bool(decoded.get("valid", false)):
		return false
	var decoded_best := _decode_bits(payload.get("best_bits", []))
	if not bool(decoded_best.get("valid", false)):
		return false
	var restored_undo: Dictionary = {}
	var undo_payload: Variant = payload.get("undo", {})
	if undo_payload is Dictionary and not undo_payload.is_empty():
		var decoded_undo := _decode_core(undo_payload)
		if not bool(decoded_undo.get("valid", false)):
			return false
		restored_undo = _decoded_core_payload(decoded_undo)
	_apply_decoded(decoded)
	best_bits.assign(decoded_best.bits)
	if _compare_bits(score_bits, best_bits) > 0:
		best_bits.assign(score_bits)
	undo_state = restored_undo
	selected.clear()
	_refresh_score_strings()
	return true


func power_value_or_zero(power: int) -> int:
	if power <= 0 or power > 62:
		return 0
	return 1 << power


func power_label(power: int) -> String:
	if power <= 0:
		return "0"
	if power > 4096:
		return "2^%d" % power
	var decimal := _power_decimal(power)
	if decimal.length() <= 4:
		return decimal
	return _compact_decimal(decimal, 3)


func format_score(decimal: String) -> String:
	var normalized := _normalize_decimal(decimal)
	if normalized.length() <= 6:
		return _comma_decimal(normalized)
	return _compact_decimal(normalized, 6)


func _unchanged_outcome() -> Dictionary:
	return {
		"changed": false,
		"gained": "0",
		"gained_label": "0",
		"result": 0,
		"result_power": 0,
		"result_label": "",
	}


func _apply_gravity() -> void:
	for x in range(width):
		var write_y := height - 1
		for y in range(height - 1, -1, -1):
			var power := int(board[y][x])
			if power > 0:
				board[write_y][x] = power
				if write_y != y:
					board[y][x] = 0
				write_y -= 1


func _refill() -> void:
	var ceiling := _spawn_ceiling()
	for y in range(height):
		for x in range(width):
			if int(board[y][x]) == 0:
				board[y][x] = rng.randi_range(1, ceiling)


func _random_start_power() -> int:
	var roll := rng.randf()
	if roll < 0.50:
		return 1
	if roll < 0.82:
		return 2
	if roll < 0.96:
		return 3
	return 4


func _spawn_ceiling() -> int:
	return clampi(highest_power() - 2, 2, 8)


func _ensure_opening_pair() -> void:
	if has_moves():
		return
	board[height - 1][0] = 1
	board[height - 1][1] = 1


func _result_power(powers: Array[int]) -> int:
	if powers.is_empty():
		return 0
	var minimum := powers[0]
	for power in powers:
		minimum = mini(minimum, power)
	var units := 0
	for power in powers:
		# A path contains at most 40 cells and each accepted step rises by at
		# most one exponent, so this exact integer sum cannot overflow int64.
		units += 1 << (power - minimum)
	var rounded_units := 1
	var extra_power := 0
	while rounded_units < units:
		rounded_units <<= 1
		extra_power += 1
	return minimum + extra_power


func _normalize_mode(mode_or_rows: Variant) -> String:
	if mode_or_rows is String and MODE_ROWS.has(mode_or_rows):
		return mode_or_rows
	match int(mode_or_rows) if mode_or_rows is int or mode_or_rows is float else 8:
		5: return MODE_EXTRA_HARD_COMPAT
		6: return MODE_HARD
		7: return MODE_MEDIUM_COMPAT
		_: return MODE_EASY


func _core_payload() -> Dictionary:
	return {
		"board": board.duplicate(true),
		"score_bits": score_bits.duplicate(),
		"moves": moves,
		"status": status,
		"mode": mode,
		"width": width,
		"height": height,
		"rng_seed": str(rng.seed),
		"rng_state": str(rng.state),
	}


func _decode_core(payload: Variant) -> Dictionary:
	if not payload is Dictionary:
		return {"valid": false}
	var restored_mode := str(payload.get("mode", ""))
	if not MODE_ROWS.has(restored_mode):
		return {"valid": false}
	var restored_height := int(payload.get("height", 0))
	if restored_height != int(MODE_ROWS[restored_mode]) or int(payload.get("width", 0)) != width:
		return {"valid": false}
	var restored_board: Variant = payload.get("board", [])
	if not restored_board is Array or restored_board.size() != restored_height:
		return {"valid": false}
	var clean_board: Array = []
	for row in restored_board:
		if not row is Array or row.size() != width:
			return {"valid": false}
		var clean_row: Array[int] = []
		for raw_power in row:
			var power := int(raw_power)
			if power <= 0 or power > 1000000:
				return {"valid": false}
			clean_row.append(power)
		clean_board.append(clean_row)
	var decoded_score := _decode_bits(payload.get("score_bits", []))
	if not bool(decoded_score.get("valid", false)):
		return {"valid": false}
	var restored_status := str(payload.get("status", ""))
	if restored_status not in [RUNNING, OVER]:
		return {"valid": false}
	var restored_moves := int(payload.get("moves", -1))
	if restored_moves < 0:
		return {"valid": false}
	var restored_seed_text := str(payload.get("rng_seed", ""))
	var restored_state_text := str(payload.get("rng_state", ""))
	if not restored_seed_text.is_valid_int() or not restored_state_text.is_valid_int():
		return {"valid": false}
	return {
		"valid": true,
		"board": clean_board,
		"score_bits": decoded_score.bits,
		"moves": restored_moves,
		"status": restored_status,
		"mode": restored_mode,
		"height": restored_height,
		"rng_seed": int(restored_seed_text),
		"rng_state": int(restored_state_text),
	}


func _apply_decoded(decoded: Dictionary) -> void:
	board = decoded.board.duplicate(true)
	score_bits.assign(decoded.score_bits)
	moves = int(decoded.moves)
	status = str(decoded.status)
	mode = str(decoded.mode)
	height = int(decoded.height)
	rng.seed = int(decoded.rng_seed)
	rng.state = int(decoded.rng_state)


func _decoded_core_payload(decoded: Dictionary) -> Dictionary:
	return {
		"board": decoded.board.duplicate(true),
		"score_bits": decoded.score_bits.duplicate(),
		"moves": int(decoded.moves),
		"status": str(decoded.status),
		"mode": str(decoded.mode),
		"width": width,
		"height": int(decoded.height),
		"rng_seed": str(decoded.rng_seed),
		"rng_state": str(decoded.rng_state),
	}


func _decode_bits(raw_bits: Variant) -> Dictionary:
	if not raw_bits is Array or raw_bits.is_empty() or raw_bits.size() > 1000000:
		return {"valid": false}
	var clean: Array[int] = []
	for raw_bit in raw_bits:
		var bit := int(raw_bit)
		if bit not in [0, 1]:
			return {"valid": false}
		clean.append(bit)
	_normalize_bits(clean)
	return {"valid": true, "bits": clean}


func _add_power(bits: Array[int], power: int) -> void:
	while bits.size() <= power:
		bits.append(0)
	var cursor := power
	while true:
		if cursor >= bits.size():
			bits.append(1)
			break
		if bits[cursor] == 0:
			bits[cursor] = 1
			break
		bits[cursor] = 0
		cursor += 1


func _normalize_bits(bits: Array[int]) -> void:
	while bits.size() > 1 and bits[-1] == 0:
		bits.pop_back()


func _compare_bits(left: Array[int], right: Array[int]) -> int:
	var left_size := left.size()
	while left_size > 1 and left[left_size - 1] == 0:
		left_size -= 1
	var right_size := right.size()
	while right_size > 1 and right[right_size - 1] == 0:
		right_size -= 1
	if left_size != right_size:
		return 1 if left_size > right_size else -1
	for index in range(left_size - 1, -1, -1):
		if left[index] != right[index]:
			return 1 if left[index] > right[index] else -1
	return 0


func _bits_to_decimal(bits: Array[int]) -> String:
	var decimal := "0"
	for index in range(bits.size() - 1, -1, -1):
		decimal = _decimal_double(decimal)
		if bits[index] == 1:
			decimal = _decimal_add_one(decimal)
	return _normalize_decimal(decimal)


func _power_decimal(power: int) -> String:
	var decimal := "1"
	for _step in range(power):
		decimal = _decimal_double(decimal)
	return decimal


func _decimal_double(decimal: String) -> String:
	var carry := 0
	var output := ""
	for index in range(decimal.length() - 1, -1, -1):
		var value := (decimal.unicode_at(index) - 48) * 2 + carry
		output = str(value % 10) + output
		carry = value / 10
	if carry > 0:
		output = str(carry) + output
	return output


func _decimal_add_one(decimal: String) -> String:
	var carry := 1
	var output := ""
	for index in range(decimal.length() - 1, -1, -1):
		var value := decimal.unicode_at(index) - 48 + carry
		output = str(value % 10) + output
		carry = value / 10
	if carry > 0:
		output = "1" + output
	return output


func _normalize_decimal(decimal: String) -> String:
	var cursor := 0
	while cursor < decimal.length() - 1 and decimal.unicode_at(cursor) == 48:
		cursor += 1
	return decimal.substr(cursor)


func _comma_decimal(decimal: String) -> String:
	var output := ""
	for index in range(decimal.length()):
		if index > 0 and (decimal.length() - index) % 3 == 0:
			output += ","
		output += decimal[index]
	return output


func _compact_decimal(decimal: String, significant_digits: int) -> String:
	var group := (decimal.length() - 1) / 3
	# The target's long-run HUD visibly keeps a six-digit coefficient (for
	# example `224,575P`) before promoting the suffix. Tile labels stay compact.
	var target_score_style := significant_digits >= 6
	if target_score_style and group > 1:
		group -= 1
	if group <= 0:
		return decimal
	var suffix := _metric_suffix(group)
	var leading_count := decimal.length() - group * 3
	if target_score_style:
		return _comma_decimal(decimal.substr(0, leading_count)) + suffix
	var fraction_budget := maxi(0, significant_digits - leading_count)
	var take := mini(leading_count + fraction_budget, decimal.length())
	var significant := decimal.substr(0, take)
	var label := significant.substr(0, leading_count)
	var fraction := significant.substr(leading_count)
	while fraction.ends_with("0"):
		fraction = fraction.trim_suffix("0")
	if not fraction.is_empty():
		label += "." + fraction
	return label + suffix


func _metric_suffix(group: int) -> String:
	if group < METRIC_SUFFIXES.size():
		return METRIC_SUFFIXES[group]
	var value := group - METRIC_SUFFIXES.size()
	var first := value / 26
	var second := value % 26
	return String.chr(97 + first % 26) + String.chr(97 + second)


func _refresh_score_strings() -> void:
	score = _bits_to_decimal(score_bits)
	all_time = _bits_to_decimal(best_bits)


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height
