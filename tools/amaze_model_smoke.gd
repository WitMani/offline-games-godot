extends SceneTree

const SOLUTIONS := [
	[Vector2i.UP, Vector2i.RIGHT],
	[Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT],
	[
		Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN,
		Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP, Vector2i.RIGHT,
		Vector2i.DOWN, Vector2i.LEFT,
	],
]

var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	_test_topologies()
	_test_long_roll_and_order()
	_test_blocked_command()
	_test_revisit()
	_test_completion_excludes_voids()
	_test_all_levels_are_deterministically_solvable()
	_test_restart_and_progression()
	_test_json_safe_snapshot()
	_test_checkpoint_recovery()
	_test_checkpoint_rejects_corruption_atomically()
	print("AMAZE_MODEL_SMOKE=%d" % assertions)
	print("AMAZE_MODEL_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _model(level := 0):
	var model = load("res://models/amaze_model.gd").new()
	model.reset(level)
	return model


func _test_topologies() -> void:
	var expected_counts := [9, 21, 31]
	for level in range(3):
		var model = _model(level)
		_expect(model.level_count() == 3, "level_%d_count" % level)
		_expect(model.walkable_count() == expected_counts[level], "level_%d_walkable_count" % level)
		_expect(model.painted_count() == 1, "level_%d_start_painted" % level)
		_expect(_connected_count(model) == model.walkable_count(), "level_%d_connected" % level)
		_expect(str(model.level_id).length() > 0, "level_%d_id" % level)


func _test_long_roll_and_order() -> void:
	var model = _model(0)
	var outcome: Dictionary = model.command(Vector2i.UP)
	_expect(bool(outcome["changed"]), "long_changed")
	_expect(outcome["from"] == [0, 4] and outcome["to"] == [0, 0], "long_endpoints")
	_expect(outcome["traversed"] == [[0, 3], [0, 2], [0, 1], [0, 0]], "long_order")
	_expect(outcome["newly_painted"] == outcome["traversed"], "long_new_order")
	_expect(model.paint_order == [Vector2i(0, 4), Vector2i(0, 3), Vector2i(0, 2), Vector2i(0, 1), Vector2i(0, 0)], "paint_order")
	_expect(model.moves == 1 and model.score == 20, "one_command_one_move")
	_expect(str(outcome["reason"]) == "stopped_at_obstacle", "long_stop_reason")


func _test_blocked_command() -> void:
	var model = _model(0)
	var before := JSON.stringify(model.snapshot())
	var outcome: Dictionary = model.command(Vector2i.LEFT)
	_expect(not bool(outcome["changed"]), "blocked_changed")
	_expect(str(outcome["reason"]) == "blocked", "blocked_reason")
	_expect(JSON.stringify(model.snapshot()) == before, "blocked_mutated")
	var invalid: Dictionary = model.command(Vector2i(1, 1))
	_expect(not bool(invalid["changed"]) and str(invalid["reason"]) == "invalid_direction", "invalid_direction")


func _test_revisit() -> void:
	var model = _model(0)
	model.command(Vector2i.UP)
	var painted_before: int = model.painted_count()
	var score_before: int = int(model.score)
	var outcome: Dictionary = model.command(Vector2i.DOWN)
	_expect(bool(outcome["changed"]), "revisit_changed_position")
	_expect(outcome["to"] == [0, 4], "revisit_stop")
	_expect(int(outcome["revisit_count"]) == 4, "revisit_count")
	_expect(outcome["newly_painted"].is_empty(), "revisit_repainted")
	_expect(model.painted_count() == painted_before and model.score == score_before, "revisit_progress_changed")
	_expect(model.moves == 2, "revisit_move_count")


func _test_completion_excludes_voids() -> void:
	var model = _model(0)
	for direction in SOLUTIONS[0]:
		model.command(direction)
	_expect(model.status == "won", "complete_status")
	_expect(model.painted_count() == 9 and model.remaining_count() == 0, "complete_counts")
	_expect(model.painted_count() < model.width * model.height, "voids_not_required")
	var terminal_before := JSON.stringify(model.snapshot())
	var terminal: Dictionary = model.command(Vector2i.LEFT)
	_expect(not bool(terminal["changed"]) and str(terminal["reason"]) == "terminal", "terminal_reject")
	_expect(JSON.stringify(model.snapshot()) == terminal_before, "terminal_mutated")


func _test_all_levels_are_deterministically_solvable() -> void:
	for level in range(SOLUTIONS.size()):
		var first = _model(level)
		var second = _model(level)
		for direction in SOLUTIONS[level]:
			first.command(direction)
			second.command(direction)
		_expect(first.status == "won", "level_%d_solved" % level)
		_expect(first.remaining_count() == 0, "level_%d_remaining" % level)
		_expect(JSON.stringify(first.snapshot()) == JSON.stringify(second.snapshot()), "level_%d_deterministic" % level)
		_expect(first.moves == SOLUTIONS[level].size(), "level_%d_move_count" % level)


func _test_restart_and_progression() -> void:
	var model = _model(1)
	model.command(Vector2i.LEFT)
	model.restart()
	_expect(model.level_index == 1 and model.position == Vector2i(5, 4), "restart_same_level")
	_expect(model.moves == 0 and model.painted_count() == 1 and model.status == "playing", "restart_clean_state")
	_expect(model.command_history.is_empty(), "restart_clears_history")
	_expect(not model.advance_level(), "advance_while_playing")
	for direction in SOLUTIONS[1]:
		model.command(direction)
	_expect(model.advance_level(), "advance_after_win")
	_expect(model.level_index == 2 and model.status == "playing" and model.painted_count() == 1, "advance_next_level")
	for direction in SOLUTIONS[2]:
		model.command(direction)
	_expect(model.advance_level(), "advance_wrap")
	_expect(model.level_index == 0, "advance_wrap_index")


func _test_json_safe_snapshot() -> void:
	var model = _model(2)
	model.command(Vector2i.RIGHT)
	var encoded := JSON.stringify(model.snapshot())
	var decoded: Variant = JSON.parse_string(encoded)
	_expect(decoded is Dictionary, "snapshot_json_dictionary")
	_expect(decoded["last_traversal"] == [[1.0, 6.0], [2.0, 6.0], [3.0, 6.0], [4.0, 6.0]], "snapshot_json_order")


func _test_checkpoint_recovery() -> void:
	var source = _model(2)
	for direction in [Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.LEFT]:
		source.command(direction)
	var encoded := JSON.stringify(source.checkpoint())
	var restored = _model(0)
	_expect(restored.restore(JSON.parse_string(encoded)), "checkpoint_restore")
	_expect(JSON.stringify(restored.checkpoint()) == JSON.stringify(source.checkpoint()), "checkpoint_authoritative_parity")
	_expect(restored.last_traversal.is_empty() and restored.last_newly_painted.is_empty(), "checkpoint_transients_cleared")
	_expect(restored.command_history == source.command_history, "checkpoint_history_parity")
	for direction in SOLUTIONS[2].slice(5):
		restored.command(direction)
	_expect(restored.status == "won" and restored.remaining_count() == 0, "checkpoint_recovery_completes")
	var won_copy = _model(1)
	_expect(won_copy.restore(restored.checkpoint()), "checkpoint_won_restore")
	_expect(won_copy.status == "won" and won_copy.position == restored.position, "checkpoint_won_parity")


func _test_checkpoint_rejects_corruption_atomically() -> void:
	var model = _model(1)
	model.command(Vector2i.LEFT)
	var before := JSON.stringify(model.snapshot())
	var valid: Dictionary = model.checkpoint()
	var cases: Array[Dictionary] = []
	var wrong_id := valid.duplicate(true)
	wrong_id["level_id"] = "not-this-level"
	cases.append(wrong_id)
	var invalid_command := valid.duplicate(true)
	invalid_command["commands"] = [[-1, 0], [1, 1]]
	cases.append(invalid_command)
	var blocked_command := valid.duplicate(true)
	blocked_command["commands"] = [[0, 1]]
	cases.append(blocked_command)
	var tampered_player := valid.duplicate(true)
	tampered_player["player"] = [0, 0]
	cases.append(tampered_player)
	var tampered_score := valid.duplicate(true)
	tampered_score["score"] = 999
	cases.append(tampered_score)
	for index in range(cases.size()):
		_expect(not model.restore(cases[index]), "checkpoint_corrupt_%d_rejected" % index)
		_expect(JSON.stringify(model.snapshot()) == before, "checkpoint_corrupt_%d_atomic" % index)


func _connected_count(model) -> int:
	var pending: Array[Vector2i] = [model.start_position]
	var visited: Dictionary = {model.start_position:true}
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next: Vector2i = cell + direction
			if model.is_walkable(next) and not visited.has(next):
				visited[next] = true
				pending.append(next)
	return visited.size()


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
