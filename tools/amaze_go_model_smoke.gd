extends SceneTree

const RULES = preload("res://models/amaze_go_model.gd")

var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	var model = RULES.new()
	model.reset()
	_test_topology(model)
	_test_clearance_and_reject(model)
	_test_extraction_order(model)
	_test_loss_and_freeze(model)
	_test_hint_and_focus(model)
	_test_restart(model)
	_test_recovery(model)
	print("AMAZE_GO_MODEL_SMOKE=%d" % assertions)
	print("AMAZE_GO_MODEL_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func _fresh():
	var model = RULES.new()
	model.reset()
	return model


func _test_topology(model) -> void:
	var snapshot: Dictionary = model.snapshot()
	_expect(snapshot.level_id == RULES.LEVEL_ID, "level_id")
	_expect(int(snapshot.width) == 12 and int(snapshot.height) == 12, "dimensions")
	_expect(snapshot.arrows.size() == 12, "arrow_count")
	_expect(int(snapshot.remaining) == 12 and int(snapshot.removed_count) == 0, "entry_counts")
	_expect(int(snapshot.hearts) == 3 and int(snapshot.max_hearts) == 3, "entry_hearts")
	_expect(int(snapshot.moves) == 0 and int(snapshot.mistakes) == 0 and int(snapshot.score) == 0, "entry_counters")
	_expect(str(snapshot.status) == RULES.PLAYING, "entry_status")
	_expect(str(snapshot.focus_id) == "a0", "entry_focus")
	var occupied: Dictionary = {}
	for arrow in snapshot.arrows:
		_expect(not str(arrow.id).is_empty(), "nonempty_id")
		_expect(arrow.path.size() >= 2, "%s_path_size" % arrow.id)
		var previous := Vector2i(-99, -99)
		for raw in arrow.path:
			var point := Vector2i(int(raw[0]), int(raw[1]))
			_expect(point.x >= 0 and point.y >= 0 and point.x < 12 and point.y < 12, "%s_in_bounds" % arrow.id)
			_expect(not occupied.has(point), "%s_no_overlap" % arrow.id)
			occupied[point] = arrow.id
			if previous.x > -90:
				_expect(abs(point.x - previous.x) + abs(point.y - previous.y) == 1, "%s_orthogonal" % arrow.id)
			previous = point
		var last := Vector2i(int(arrow.path[-1][0]), int(arrow.path[-1][1]))
		var before := Vector2i(int(arrow.path[-2][0]), int(arrow.path[-2][1]))
		_expect(Vector2i(int(arrow.direction[0]), int(arrow.direction[1])) == last - before, "%s_head_direction" % arrow.id)
	_expect(occupied.size() == 40, "occupied_cell_count")


func _test_clearance_and_reject(_model) -> void:
	var model = _fresh()
	_expect(model.legal_ids() == ["a1", "a7"], "initial_legal_set")
	_expect(not model.is_legal("a0"), "a0_initial_blocked")
	_expect(model.blockers_for("a0") == ["a1"], "a0_blocker")
	_expect(model.first_blocking_cell("a0") == Vector2i(8, 1), "a0_contact")
	var before := model.snapshot()
	var event: Dictionary = model.attempt("a0")
	_expect(not bool(event.accepted) and str(event.kind) == "reject", "blocked_event")
	_expect(int(event.grade) == 2 and str(event.reason) == "blocked", "blocked_semantic")
	_expect(model.removed_ids.is_empty(), "blocked_no_removal")
	_expect(int(model.hearts) == 2 and int(model.mistakes) == 1 and int(model.moves) == 1, "blocked_cost")
	_expect(int(model.score) == int(before.score), "blocked_score_inert")
	var invalid := model.attempt("missing")
	_expect(str(invalid.reason) == "invalid_id", "invalid_reason")
	_expect(int(model.hearts) == 2 and int(model.moves) == 1, "invalid_inert")


func _test_extraction_order(_model) -> void:
	var model = _fresh()
	var event: Dictionary = model.attempt("a1")
	_expect(bool(event.accepted) and str(event.kind) == "extract", "first_extract")
	_expect(model.is_legal("a0") and model.is_legal("a10"), "first_opens_lanes")
	_expect(model.removed_ids == ["a1"], "first_exact_removal")
	_expect(int(model.remaining_count()) == 11 and int(model.score) == 20 and int(model.moves) == 1, "first_counters")
	var removed_retry := model.attempt("a1")
	_expect(str(removed_retry.reason) == "already_removed", "removed_inert")
	_expect(int(model.hearts) == 3 and int(model.moves) == 1, "removed_retry_inert")
	var order := ["a0", "a10", "a3", "a2", "a4", "a6", "a8", "a11", "a5", "a9", "a7"]
	var kinds: Array[String] = []
	for arrow_id in order:
		_expect(model.is_legal(arrow_id), "%s_legal_in_order" % arrow_id)
		event = model.attempt(arrow_id)
		_expect(bool(event.accepted), "%s_extract_accepted" % arrow_id)
		kinds.append(str(event.kind))
	_expect(kinds.count("waypoint") >= 2, "waypoint_events")
	_expect(kinds.count("near") == 2, "near_events")
	_expect(kinds[-1] == "win", "final_win_event")
	_expect(model.removed_ids.size() == 12 and model.remaining_count() == 0, "clear_all")
	_expect(model.status == RULES.WON and model.score == 340 and model.moves == 12, "win_counters")
	var frozen := model.snapshot()
	var terminal := model.attempt("a0")
	_expect(str(terminal.reason) == "terminal", "won_terminal_reject")
	_expect(model.snapshot().removed_ids == frozen.removed_ids and model.score == int(frozen.score), "won_frozen")


func _test_loss_and_freeze(_model) -> void:
	var model = _fresh()
	for expected_hearts in [2, 1, 0]:
		var event: Dictionary = model.attempt("a0")
		_expect(int(event.hearts) == expected_hearts, "heart_cost_%d" % expected_hearts)
	_expect(model.status == RULES.OVER and model.mistakes == 3 and model.moves == 3, "loss_state")
	_expect(model.removed_ids.is_empty() and model.score == 0, "loss_no_extraction")
	var frozen := model.snapshot()
	var terminal := model.attempt("a1")
	_expect(str(terminal.reason) == "terminal", "loss_terminal_reject")
	_expect(model.snapshot().removed_ids == frozen.removed_ids and model.hearts == int(frozen.hearts), "loss_frozen")
	_expect(model.legal_ids().is_empty(), "loss_no_legal_actions")


func _test_hint_and_focus(_model) -> void:
	var model = _fresh()
	var hint: Dictionary = model.request_hint()
	_expect(bool(hint.accepted) and str(hint.arrow_id) == "a1", "entry_hint")
	_expect(model.focus_id == "a1" and model.hint_id == "a1", "hint_focus")
	model.attempt("a1")
	hint = model.request_hint()
	_expect(str(hint.arrow_id) == "a0", "opened_hint")
	var before: String = str(model.focus_id)
	var after: String = str(model.move_focus(Vector2i.DOWN))
	_expect(not after.is_empty() and after != before, "focus_moves")
	_expect(model.hint_id.is_empty(), "focus_clears_hint")
	var unchanged: String = str(model.move_focus(Vector2i(1, 1)))
	_expect(unchanged == model.focus_id, "invalid_focus_direction_inert")


func _test_restart(_model) -> void:
	var model = _fresh()
	model.attempt("a1")
	model.attempt("a0")
	model.request_hint()
	model.reset()
	var snapshot: Dictionary = model.snapshot()
	_expect(snapshot.removed_ids.is_empty() and int(snapshot.remaining) == 12, "restart_arrows")
	_expect(int(snapshot.hearts) == 3 and int(snapshot.mistakes) == 0, "restart_hearts")
	_expect(int(snapshot.moves) == 0 and int(snapshot.score) == 0, "restart_counters")
	_expect(str(snapshot.status) == RULES.PLAYING and str(snapshot.focus_id) == "a0", "restart_state")


func _test_recovery(_model) -> void:
	var source = _fresh()
	source.attempt("a1")
	source.attempt("a0")
	source.attempt("a10")
	source.request_hint()
	var payload: Dictionary = source.recovery_snapshot()
	var restored = _fresh()
	_expect(restored.restore(payload), "valid_restore")
	_expect(restored.recovery_snapshot() == payload, "restore_roundtrip")
	_expect(restored.snapshot().arrows == source.snapshot().arrows, "restore_authority")
	var invalid_cases: Array[Dictionary] = []
	var bad := payload.duplicate(true)
	bad.schema = "wrong"
	invalid_cases.append(bad)
	bad = payload.duplicate(true)
	bad.level_id = "other"
	invalid_cases.append(bad)
	bad = payload.duplicate(true)
	bad.removed_ids.append("missing")
	invalid_cases.append(bad)
	bad = payload.duplicate(true)
	bad.removed_ids.append(bad.removed_ids[0])
	invalid_cases.append(bad)
	bad = payload.duplicate(true)
	bad.hearts = 9
	invalid_cases.append(bad)
	bad = payload.duplicate(true)
	bad.mistakes = 2
	invalid_cases.append(bad)
	bad = payload.duplicate(true)
	bad.moves = 99
	invalid_cases.append(bad)
	bad = payload.duplicate(true)
	bad.score = 99
	invalid_cases.append(bad)
	bad = payload.duplicate(true)
	bad.status = RULES.WON
	invalid_cases.append(bad)
	bad = payload.duplicate(true)
	bad.focus_id = "missing"
	invalid_cases.append(bad)
	bad = payload.duplicate(true)
	bad.hint_id = "a1"
	invalid_cases.append(bad)
	for index in range(invalid_cases.size()):
		var target = _fresh()
		var before: Dictionary = target.recovery_snapshot()
		_expect(not target.restore(invalid_cases[index]), "invalid_restore_%d" % index)
		_expect(target.recovery_snapshot() == before, "invalid_restore_%d_inert" % index)
