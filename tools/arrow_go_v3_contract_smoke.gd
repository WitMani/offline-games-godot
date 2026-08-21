extends SceneTree

const ArrowRules = preload("res://models/arrow_go_model.gd")
const SOLUTION: Array[String] = ["b", "a", "d", "c", "k", "g", "f", "l", "i", "e", "j", "h"]

var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_entry_and_topology()
	_test_blocked_atomicity_and_rigid_sweep()
	_test_legal_turn_and_reveal_order()
	_test_milestones_near_clear_and_win()
	_test_terminal_freeze_and_restart()
	_test_hint_and_focus()
	_test_strict_recovery()
	_test_local_deadlock_contract()
	print("ARROW_GO_V3_CONTRACT_ASSERTIONS=%d" % assertions)
	print("ARROW_GO_V3_CONTRACT_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _new_model():
	var model = ArrowRules.new()
	model.reset()
	return model


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)


func _authoritative(model) -> Dictionary:
	return {
		"removed_ids":model.removed_ids.duplicate(),
		"moves":model.moves,
		"score":model.score,
		"status":model.status,
		"terminal_reason":model.terminal_reason,
		"focus_id":model.focus_id,
		"hint_id":model.hint_id,
	}


func _test_entry_and_topology() -> void:
	var model = _new_model()
	_expect(model.topology_valid(), "entry_topology")
	_expect(model.arrow_ids().size() == 12, "entry_arrow_count")
	_expect(model.arrow_ids() == ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l"], "entry_identity")
	_expect(model.live_ids() == model.arrow_ids(), "entry_all_live")
	_expect(model.legal_ids() == ["b", "d", "k"], "entry_legal_order")
	_expect(model.remaining_count() == 12, "entry_remaining")
	_expect(model.moves == 0 and model.score == 0, "entry_counters")
	_expect(model.status == ArrowRules.PLAYING, "entry_status")
	_expect(model.focus_id == "a" and model.hint_id.is_empty(), "entry_focus")
	for arrow_id in model.arrow_ids():
		var path = model.path_for(arrow_id)
		_expect(path.size() >= 2, "entry_path_%s" % arrow_id)
		_expect(model.direction_for(arrow_id) == path[-1] - path[-2], "entry_direction_%s" % arrow_id)
		for index in range(1, path.size()):
			var delta: Vector2i = path[index] - path[index - 1]
			_expect(abs(delta.x) + abs(delta.y) == 1, "entry_connected_%s_%d" % [arrow_id, index])


func _test_blocked_atomicity_and_rigid_sweep() -> void:
	var model = _new_model()
	var before := _authoritative(model)
	var blocked: Dictionary = model.attempt("a")
	_expect(not bool(blocked.accepted) and str(blocked.kind) == "blocked", "blocked_reject")
	_expect(blocked.blockers == ["b"], "blocked_identity")
	_expect(blocked.contact == {"cell":[7, 4], "blocker_id":"b", "distance":2}, "blocked_contact")
	_expect(_authoritative(model) == before, "blocked_authority_atomic")
	before = _authoritative(model)
	var invalid: Dictionary = model.attempt("unknown")
	_expect(str(invalid.kind) == "invalid_reject" and not bool(invalid.changed), "invalid_reject")
	_expect(_authoritative(model) == before, "invalid_authority_atomic")
	model.attempt("b")
	_expect(not model.is_legal("i"), "rigid_body_i_still_blocked")
	_expect("f" in model.blockers_for("i") and "l" in model.blockers_for("i"), "rigid_body_sweep_blockers")


func _test_legal_turn_and_reveal_order() -> void:
	var model = _new_model()
	var event: Dictionary = model.attempt("b")
	_expect(bool(event.accepted) and bool(event.changed), "turn_accept")
	_expect(str(event.kind) == "turn_escape", "turn_kind")
	_expect(int(event.bends) == 1 and int(event.score_delta) == 125, "turn_bend_score")
	_expect(model.removed_ids == ["b"], "turn_removed_order")
	_expect(model.moves == 1 and model.score == 125, "turn_counters")
	_expect("a" in event.newly_legal, "turn_reveals_a")
	_expect(model.is_legal("a"), "turn_a_legal")
	event = model.attempt("a")
	_expect(str(event.kind) == "escape" and int(event.score_delta) == 100, "straight_escape")
	_expect(model.removed_ids == ["b", "a"], "straight_removed_order")


func _test_milestones_near_clear_and_win() -> void:
	var model = _new_model()
	var seen_waypoints: Array[int] = []
	for index in range(SOLUTION.size()):
		var arrow_id := SOLUTION[index]
		_expect(model.is_legal(arrow_id), "solution_legal_%s" % arrow_id)
		var event: Dictionary = model.attempt(arrow_id)
		_expect(bool(event.accepted), "solution_accept_%s" % arrow_id)
		if bool(event.get("milestone", false)):
			seen_waypoints.append(int(event.removed_count))
		if index == 9:
			_expect(str(event.kind) == "near_clear" and int(event.remaining) == 2, "near_clear_two")
		if index == 10:
			_expect(str(event.kind) == "near_clear" and int(event.remaining) == 1, "near_clear_one")
		if index == 11:
			_expect(str(event.kind) == "win" and bool(event.animal_reveal), "win_reveal")
	_expect(seen_waypoints == [4, 8], "waypoint_thresholds")
	_expect(model.status == ArrowRules.WON and model.terminal_reason == "clear_all", "win_terminal")
	_expect(model.remaining_count() == 0 and model.moves == 12, "win_counts")
	_expect(model.score == 1275, "win_score")


func _test_terminal_freeze_and_restart() -> void:
	var model = _new_model()
	for arrow_id in SOLUTION:
		model.attempt(arrow_id)
	var before := _authoritative(model)
	var rejected: Dictionary = model.attempt("a")
	_expect(str(rejected.kind) == "terminal_reject" and not bool(rejected.changed), "terminal_reject")
	_expect(_authoritative(model) == before, "terminal_frozen")
	var restart: Dictionary = model.restart()
	_expect(str(restart.kind) == "restart" and bool(restart.accepted), "restart_event")
	_expect(model.legal_ids() == ["b", "d", "k"], "restart_legal")
	_expect(model.remaining_count() == 12 and model.moves == 0 and model.score == 0, "restart_authority")
	_expect(model.status == ArrowRules.PLAYING, "restart_status")


func _test_hint_and_focus() -> void:
	var model = _new_model()
	var before := _authoritative(model)
	var hint: Dictionary = model.request_hint()
	_expect(str(hint.kind) == "hint" and str(hint.arrow_id) == "b", "hint_first_legal")
	_expect(model.removed_ids == before.removed_ids and model.moves == before.moves and model.score == before.score, "hint_no_rule_mutation")
	_expect(model.focus_id == "b" and model.hint_id == "b", "hint_focus")
	var old_focus: String = model.focus_id
	model.move_focus(Vector2i.LEFT)
	_expect(model.focus_id != old_focus and model.focus_id in model.live_ids(), "focus_cardinal")
	var focus_after: String = model.focus_id
	model.move_focus(Vector2i.ZERO)
	_expect(model.focus_id == focus_after, "focus_invalid_ignored")


func _test_strict_recovery() -> void:
	var source = _new_model()
	for arrow_id in ["b", "a", "d"]:
		source.attempt(arrow_id)
	source.request_hint()
	var payload: Dictionary = source.recovery_snapshot()
	var restored = _new_model()
	_expect(restored.restore(payload), "recovery_valid")
	_expect(restored.removed_ids == source.removed_ids, "recovery_removed_order")
	_expect(restored.moves == source.moves and restored.score == source.score, "recovery_counters")
	_expect(restored.focus_id == source.focus_id and restored.hint_id == source.hint_id, "recovery_focus")
	var baseline := _authoritative(restored)
	var corruptions: Array[Dictionary] = []
	var wrong_schema := payload.duplicate(true)
	wrong_schema.schema = "wrong"
	corruptions.append(wrong_schema)
	var duplicate := payload.duplicate(true)
	duplicate.removed_ids = ["b", "b"]
	duplicate.moves = 2
	corruptions.append(duplicate)
	var impossible := payload.duplicate(true)
	impossible.removed_ids = ["a"]
	impossible.moves = 1
	impossible.score = 100
	impossible.focus_id = "b"
	impossible.hint_id = ""
	corruptions.append(impossible)
	var terminal := payload.duplicate(true)
	terminal.status = ArrowRules.WON
	corruptions.append(terminal)
	var bad_score := payload.duplicate(true)
	bad_score.score = int(payload.score) + 1
	corruptions.append(bad_score)
	for index in range(corruptions.size()):
		_expect(not restored.restore(corruptions[index]), "recovery_reject_%d" % index)
		_expect(_authoritative(restored) == baseline, "recovery_atomic_%d" % index)


func _test_local_deadlock_contract() -> void:
	var model = _new_model()
	var deadlock_arrows: Array[Dictionary] = [
		{"id":"x", "path":[Vector2i(0, 1), Vector2i(1, 1)], "direction":Vector2i.RIGHT},
		{"id":"y", "path":[Vector2i(3, 1), Vector2i(2, 1)], "direction":Vector2i.LEFT},
	]
	model.arrows = deadlock_arrows
	model.removed_ids.clear()
	model.moves = 0
	model.score = 0
	model.status = ArrowRules.PLAYING
	model.terminal_reason = ""
	_expect(model.topology_valid(), "deadlock_fixture_topology")
	_expect(model.legal_ids().is_empty(), "deadlock_no_legal")
	model.refresh_terminal()
	_expect(model.status == ArrowRules.OVER and model.terminal_reason == "local_deadlock", "deadlock_loss")
	var before := _authoritative(model)
	var rejected: Dictionary = model.attempt("x")
	_expect(str(rejected.kind) == "terminal_reject", "deadlock_terminal_reject")
	_expect(_authoritative(model) == before, "deadlock_terminal_frozen")
