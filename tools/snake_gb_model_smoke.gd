extends SceneTree

const MODEL_PATH := "res://models/snake_gb_model.gd"
const TEST_SEED := 1201989
const EXPECTED_CASES := 9

var failures: Array[String] = []
var cases_run := 0
var model_script: Script


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	model_script = load(MODEL_PATH)
	if model_script == null or not model_script.can_instantiate():
		failures.append("model_script_not_instantiable")
		_finish()
		return
	_test_reset_contract()
	_test_automatic_step()
	_test_turn_queue_and_reverse_rejection()
	_test_food_queues_one_growth_and_stays_single()
	_test_growth_materializes_before_score_and_win()
	_test_wall_collision()
	_test_self_collision()
	_test_terminal_freezes()
	_test_reset_recovers()
	_finish()


func _fresh_model():
	var model = model_script.new()
	model.reset(TEST_SEED)
	return model


func _finish() -> void:
	if cases_run != EXPECTED_CASES:
		failures.append("case_count_%d_of_%d" % [cases_run, EXPECTED_CASES])
	print("SNAKE_GB_MODEL_CASES=%d" % cases_run)
	print("SNAKE_GB_MODEL_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _record(name: String, passed: bool, evidence: String = "") -> void:
	cases_run += 1
	if not passed:
		failures.append(name + ("=" + evidence if not evidence.is_empty() else ""))


func _has_event(events: Array[Dictionary], kind: String) -> bool:
	for event in events:
		if str(event.get("kind", "")) == kind:
			return true
	return false


func _has_rejection(events: Array[Dictionary], reason: String) -> bool:
	for event in events:
		if str(event.get("kind", "")) == "turn_rejected" and str(event.get("reason", "")) == reason:
			return true
	return false


func _test_reset_contract() -> void:
	var model = _fresh_model()
	var state: Dictionary = model.snapshot()
	var passed: bool = (
		state.get("phase") == "running" and state.get("status") == "playing"
		and int(state.get("width", 0)) == 15 and int(state.get("height", 0)) == 23
		and state.get("segments", []).size() == 4 and int(state.get("score", 0)) == 4
		and int(state.get("target_length", 0)) == 120
		and state.get("foods", []).size() == 1
	)
	_record("reset_contract", passed, JSON.stringify(state))


func _test_automatic_step() -> void:
	var model = _fresh_model()
	var events: Array[Dictionary] = model.advance_step()
	var state: Dictionary = model.snapshot()
	var passed: bool = _has_event(events, "moved") and state["segments"][0] == [8, 11] and int(state["moves"]) == 1
	_record("automatic_step", passed, JSON.stringify(state))


func _test_turn_queue_and_reverse_rejection() -> void:
	var model = _fresh_model()
	var accepted: Array[Dictionary] = model.request_turn(Vector2i.UP)
	var pending: Array[Dictionary] = model.request_turn(Vector2i.LEFT)
	model.advance_step()
	var after: Dictionary = model.snapshot()
	var reverse: Array[Dictionary] = model.request_turn(Vector2i.DOWN)
	var passed: bool = (
		_has_event(accepted, "turn_accepted") and _has_rejection(pending, "pending_turn")
		and after["direction"] == [0, -1] and after["turn_queue"].is_empty()
		and _has_rejection(reverse, "reverse")
	)
	_record("turn_contract", passed, JSON.stringify(after))


func _test_food_queues_one_growth_and_stays_single() -> void:
	var model = _fresh_model()
	model.food = Vector2i(8, 11)
	var events: Array[Dictionary] = model.advance_step()
	var state: Dictionary = model.snapshot()
	var passed: bool = (
		_has_event(events, "ate") and _has_event(events, "food_spawned")
		and state["segments"].size() == 4 and int(state["score"]) == 4
		and int(state["pending_growth"]) == 1 and state["foods"].size() == 1
		and not state["segments"].has(state["food"])
	)
	_record("one_growth_one_food", passed, JSON.stringify(state))


func _test_growth_materializes_before_score_and_win() -> void:
	var model = _fresh_model()
	model.target_length = 5
	model.food = Vector2i(8, 11)
	model.advance_step()
	var before: Dictionary = model.snapshot()
	var events: Array[Dictionary] = model.advance_step()
	var after: Dictionary = model.snapshot()
	var passed: bool = (
		int(before["score"]) == 4 and before.get("phase") == "running"
		and int(after["score"]) == 5 and after["segments"].size() == 5
		and after.get("phase") == "won" and after.get("status") == "won"
		and _has_event(events, "length_won")
	)
	_record("materialized_win", passed, JSON.stringify(after))


func _test_wall_collision() -> void:
	var model = _fresh_model()
	model.segments.assign([Vector2i(14, 11), Vector2i(13, 11), Vector2i(12, 11), Vector2i(11, 11)])
	model.direction = Vector2i.RIGHT
	var events: Array[Dictionary] = model.advance_step()
	var state: Dictionary = model.snapshot()
	var passed: bool = state.get("phase") == "lost" and state.get("terminal_reason") == "wall" and _has_event(events, "wall_hit")
	_record("wall_collision", passed, JSON.stringify(state))


func _test_self_collision() -> void:
	var model = _fresh_model()
	model.segments.assign([Vector2i(2, 2), Vector2i(2, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)])
	model.direction = Vector2i.LEFT
	model.food = Vector2i(8, 8)
	var events: Array[Dictionary] = model.advance_step()
	var state: Dictionary = model.snapshot()
	var passed: bool = state.get("phase") == "lost" and state.get("terminal_reason") == "self" and _has_event(events, "self_hit")
	_record("self_collision", passed, JSON.stringify(state))


func _test_terminal_freezes() -> void:
	var model = _fresh_model()
	model.segments.assign([Vector2i(14, 11), Vector2i(13, 11), Vector2i(12, 11), Vector2i(11, 11)])
	model.direction = Vector2i.RIGHT
	model.advance_step()
	var before: String = JSON.stringify(model.snapshot())
	var events: Array[Dictionary] = model.advance_step()
	var after: String = JSON.stringify(model.snapshot())
	var passed: bool = events.is_empty() and before == after and _has_rejection(model.request_turn(Vector2i.UP), "terminal")
	_record("terminal_freeze", passed, after)


func _test_reset_recovers() -> void:
	var model = _fresh_model()
	model.segments.assign([Vector2i(14, 11), Vector2i(13, 11), Vector2i(12, 11), Vector2i(11, 11)])
	model.direction = Vector2i.RIGHT
	model.advance_step()
	model.reset(TEST_SEED)
	var state: Dictionary = model.snapshot()
	var passed: bool = state.get("phase") == "running" and int(state["score"]) == 4 and state["foods"].size() == 1
	_record("reset_recovers", passed, JSON.stringify(state))
