extends SceneTree

var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	_test_authored_topologies()
	_test_layer_blocking_and_reveal()
	_test_ordered_tray_and_triple()
	_test_match_resolves_before_capacity()
	_test_full_tray_failure()
	_test_all_levels_solve_deterministically()
	_test_restart_and_progression()
	_test_json_safe_snapshot()
	_test_checkpoint_recovery()
	_test_checkpoint_rejects_corruption_atomically()
	print("TILECLUB_MODEL_SMOKE=%d" % assertions)
	print("TILECLUB_MODEL_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _model(level := 0):
	var model = load("res://models/tileclub_model.gd").new()
	model.reset(level)
	return model


func _test_authored_topologies() -> void:
	var expected_counts := [12, 18, 21]
	var expected_selectable := [4, 6, 7]
	for level in range(3):
		var model = _model(level)
		_expect(model.level_count() == 3, "level_%d_count" % level)
		_expect(model.active_tile_count() == expected_counts[level], "level_%d_tile_count" % level)
		_expect(model.selectable_ids().size() == expected_selectable[level], "level_%d_exposed_count" % level)
		_expect(model.layer_count() == 2, "level_%d_layer_count" % level)
		_expect(model.tray.is_empty() and model.status == "playing", "level_%d_initial_state" % level)
		_expect(model.solution_for_level().size() == expected_counts[level], "level_%d_solution_size" % level)
		var counts := {}
		for tile in model.tiles:
			counts[int(tile["value"])] = int(counts.get(int(tile["value"]), 0)) + 1
		var divisible := true
		for value in counts:
			divisible = divisible and int(counts[value]) % 3 == 0
		_expect(divisible, "level_%d_value_counts" % level)


func _test_layer_blocking_and_reveal() -> void:
	var model = _model(0)
	_expect(not model.is_selectable(0) and not model.is_selectable(1), "lower_pair_initially_blocked")
	_expect(model.blockers_for(0) == [2] and model.blockers_for(1) == [2], "lower_pair_blocker")
	var before := JSON.stringify(model.checkpoint())
	var rejected: Dictionary = model.collect(0)
	_expect(not bool(rejected["changed"]) and str(rejected["reason"]) == "covered", "covered_rejected")
	_expect(rejected["blockers"] == [2], "covered_payload")
	_expect(JSON.stringify(model.checkpoint()) == before, "covered_mutated_state")
	var outcome: Dictionary = model.collect(2)
	_expect(bool(outcome["changed"]) and int(outcome["value"]) == 1, "upper_collected")
	var revealed: Array = outcome["newly_exposed"].duplicate()
	revealed.sort()
	_expect(revealed == [0, 1], "lower_pair_revealed")
	_expect(model.is_selectable(0) and model.is_selectable(1), "revealed_selectable")


func _test_ordered_tray_and_triple() -> void:
	var model = _model(1)
	model.collect(2)
	model.collect(0)
	_expect(model.tray == [1, 1], "tray_preserves_click_order")
	var outcome: Dictionary = model.collect(1)
	_expect(bool(outcome["matched"]), "third_identical_matches")
	_expect(outcome["matched_indices"] == [0, 1, 2], "matched_slot_indices")
	_expect(model.tray.is_empty(), "triple_removed")
	_expect(model.matches == 1 and model.score == 100 and model.moves == 3, "match_counters")
	_expect(model.active_tile_count() == 15 and model.status == "playing", "match_board_state")
	var removed: Dictionary = model.collect(2)
	_expect(not bool(removed["changed"]) and str(removed["reason"]) == "removed", "removed_tile_inert")


func _test_match_resolves_before_capacity() -> void:
	var model = _model(2)
	for tile_id in [2, 0, 5, 8, 11, 14]:
		var step: Dictionary = model.collect(tile_id)
		_expect(bool(step["changed"]), "capacity_setup_%d" % tile_id)
	_expect(model.tray == [1, 1, 2, 3, 4, 5], "capacity_setup_tray")
	var outcome: Dictionary = model.collect(1)
	_expect(bool(outcome["matched"]), "capacity_third_matches")
	_expect(model.tray == [2, 3, 4, 5], "capacity_match_compacts")
	_expect(model.status == "playing" and not bool(outcome["failed"]), "match_before_full_check")


func _test_full_tray_failure() -> void:
	var model = _model(2)
	for tile_id in [2, 5, 8, 11, 14, 17]:
		model.collect(tile_id)
	_expect(model.tray == [1, 2, 3, 4, 5, 6] and model.status == "playing", "near_full_state")
	var outcome: Dictionary = model.collect(20)
	_expect(bool(outcome["failed"]) and model.status == "over", "seventh_slot_failure")
	_expect(model.tray == [1, 2, 3, 4, 5, 6, 7], "full_tray_order")
	var before := JSON.stringify(model.checkpoint())
	var terminal: Dictionary = model.collect(0)
	_expect(not bool(terminal["changed"]) and str(terminal["reason"]) == "terminal", "loss_terminal_reject")
	_expect(JSON.stringify(model.checkpoint()) == before, "loss_terminal_mutated")


func _test_all_levels_solve_deterministically() -> void:
	for level in range(3):
		var first = _model(level)
		var second = _model(level)
		var solution: Array[int] = first.solution_for_level()
		var saw_layer_clear := false
		for tile_id in solution:
			var first_outcome: Dictionary = first.collect(tile_id)
			var second_outcome: Dictionary = second.collect(tile_id)
			_expect(bool(first_outcome["changed"]) and bool(second_outcome["changed"]), "level_%d_solution_action_%d" % [level, tile_id])
			saw_layer_clear = saw_layer_clear or not first_outcome["cleared_layers"].is_empty()
		_expect(first.status == "won" and first.active_tile_count() == 0, "level_%d_won" % level)
		_expect(first.tray.is_empty(), "level_%d_won_empty_tray" % level)
		_expect(first.matches * 3 == solution.size(), "level_%d_match_count" % level)
		_expect(saw_layer_clear, "level_%d_layer_clear" % level)
		_expect(JSON.stringify(first.checkpoint()) == JSON.stringify(second.checkpoint()), "level_%d_deterministic" % level)
		var terminal_before := JSON.stringify(first.checkpoint())
		var terminal: Dictionary = first.collect(0)
		_expect(not bool(terminal["changed"]) and JSON.stringify(first.checkpoint()) == terminal_before, "level_%d_win_terminal" % level)


func _test_restart_and_progression() -> void:
	var model = _model(1)
	model.collect(2)
	model.restart()
	_expect(model.level_index == 1 and model.level_id == "six_nests_ribbon", "restart_same_level")
	_expect(model.moves == 0 and model.matches == 0 and model.tray.is_empty(), "restart_clean_state")
	_expect(model.active_tile_count() == 18 and model.action_history.is_empty(), "restart_full_board")
	_expect(not model.advance_level(), "advance_while_playing")
	for tile_id in model.solution_for_level():
		model.collect(tile_id)
	_expect(model.advance_level(), "advance_after_win")
	_expect(model.level_index == 2 and model.status == "playing" and model.active_tile_count() == 21, "advance_next_level")
	for tile_id in model.solution_for_level():
		model.collect(tile_id)
	_expect(model.advance_level() and model.level_index == 0, "advance_wrap")


func _test_json_safe_snapshot() -> void:
	var model = _model(0)
	model.collect(2)
	var encoded := JSON.stringify(model.snapshot())
	var decoded: Variant = JSON.parse_string(encoded)
	_expect(decoded is Dictionary, "snapshot_json_dictionary")
	_expect(decoded["rules_version"] == "tileclub-stage0-v1", "snapshot_rules_version")
	_expect(int(decoded["active_count"]) == 11 and decoded["tray"] == [1.0], "snapshot_progress")
	_expect(decoded["selectable_ids"].size() == 5, "snapshot_reveal_count")


func _test_checkpoint_recovery() -> void:
	var source = _model(1)
	for tile_id in [2, 0, 1, 5]:
		source.collect(tile_id)
	var encoded := JSON.stringify(source.checkpoint())
	var restored = _model(0)
	_expect(restored.restore(JSON.parse_string(encoded)), "checkpoint_restore_partial")
	_expect(JSON.stringify(restored.checkpoint()) == JSON.stringify(source.checkpoint()), "checkpoint_partial_parity")
	for tile_id in source.solution_for_level().slice(4):
		# Continue only when the action has not already been consumed by the
		# deliberately chosen partial sequence.
		if restored.tile_by_id(tile_id)["active"]:
			restored.collect(tile_id)
	_expect(restored.status == "won" and restored.tray.is_empty(), "checkpoint_partial_completes")

	var lost = _model(2)
	for tile_id in [2, 5, 8, 11, 14, 17, 20]:
		lost.collect(tile_id)
	var lost_copy = _model(0)
	_expect(lost_copy.restore(lost.checkpoint()), "checkpoint_restore_loss")
	_expect(lost_copy.status == "over" and lost_copy.tray.size() == 7, "checkpoint_loss_parity")

	var won = _model(0)
	for tile_id in won.solution_for_level():
		won.collect(tile_id)
	var won_copy = _model(2)
	_expect(won_copy.restore(won.checkpoint()), "checkpoint_restore_win")
	_expect(won_copy.status == "won" and won_copy.active_tile_count() == 0, "checkpoint_win_parity")


func _test_checkpoint_rejects_corruption_atomically() -> void:
	var model = _model(0)
	model.collect(2)
	var before := JSON.stringify(model.checkpoint())
	var valid: Dictionary = model.checkpoint()
	var cases: Array[Variant] = []
	var wrong_schema := valid.duplicate(true)
	wrong_schema["schema"] = "other"
	cases.append(wrong_schema)
	var wrong_id := valid.duplicate(true)
	wrong_id["level_id"] = "not-this-level"
	cases.append(wrong_id)
	var blocked_action := valid.duplicate(true)
	blocked_action["actions"] = [0]
	cases.append(blocked_action)
	var tampered_tray := valid.duplicate(true)
	tampered_tray["tray"] = [7]
	cases.append(tampered_tray)
	var tampered_status := valid.duplicate(true)
	tampered_status["status"] = "won"
	cases.append(tampered_status)
	var bad_action_type := valid.duplicate(true)
	bad_action_type["actions"] = ["2"]
	cases.append(bad_action_type)
	cases.append([])
	for index in range(cases.size()):
		_expect(not model.restore(cases[index]), "checkpoint_corrupt_%d_rejected" % index)
		_expect(JSON.stringify(model.checkpoint()) == before, "checkpoint_corrupt_%d_atomic" % index)


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
