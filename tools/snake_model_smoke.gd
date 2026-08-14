extends SceneTree

const MODEL_PATH := "res://snake_model.gd"
const RUNNING := "running"
const WON := "won"
const LOST := "lost"
const TEST_SEED := 20260813
const EXPECTED_CASES := 11

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

	_test_reset_is_running_and_advances_without_input()
	_test_same_direction_is_rejected_while_running()
	_test_only_one_turn_can_be_pending_per_step()
	_test_reverse_turn_is_rejected()
	_test_current_tail_cell_is_legal_when_not_eating()
	_test_wall_collision_loses_with_wall_reason()
	_test_self_collision_loses_with_self_reason()
	_test_eating_grows_scores_and_spawns_free_food()
	_test_growth_materializes_and_game_stays_endless()
	_test_terminal_states_reject_input_and_freeze_steps()
	_test_reset_restores_ready_defaults()

	_finish()


func _finish() -> void:
	if cases_run != EXPECTED_CASES:
		failures.append("case_count_%d_of_%d" % [cases_run, EXPECTED_CASES])
	print("SNAKE_MODEL_SMOKE_CASES=%d" % cases_run)
	print("SNAKE_MODEL_SMOKE_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _fresh_model():
	var model = model_script.new()
	model.reset(false, TEST_SEED)
	return model


func _record(case_name: String, passed: bool, evidence: String = "") -> void:
	cases_run += 1
	if passed:
		return
	var failure := case_name
	if not evidence.is_empty():
		failure += "=" + evidence
	failures.append(failure)


func _has_event(events: Array[Dictionary], kind: String) -> bool:
	for event in events:
		if str(event.get("kind", "")) == kind:
			return true
	return false


func _find_event(events: Array[Dictionary], kind: String) -> Dictionary:
	for event in events:
		if str(event.get("kind", "")) == kind:
			return event
	return {}


func _has_rejection(events: Array[Dictionary], reason: String) -> bool:
	for event in events:
		if str(event.get("kind", "")) == "turn_rejected" and str(event.get("reason", "")) == reason:
			return true
	return false


func _test_reset_is_running_and_advances_without_input() -> void:
	var model = _fresh_model()
	var events: Array[Dictionary] = model.advance_step()
	var after: Dictionary = model.snapshot()
	var passed: bool = str(after["phase"]) == "running" and bool(after["started"]) and _has_event(events, "moved") and after["snake"][0] == [8, 11]
	_record("reset_auto_starts", passed, JSON.stringify(after))


func _test_same_direction_is_rejected_while_running() -> void:
	var model = _fresh_model()
	var turn_events: Array[Dictionary] = model.request_turn(Vector2i.RIGHT)
	var after_turn: Dictionary = model.snapshot()
	var passed: bool = (
		_has_rejection(turn_events, "duplicate")
		and str(after_turn["phase"]) == "running"
		and after_turn["turn_queue"].is_empty()
	)
	_record("same_direction_rejected", passed, JSON.stringify(after_turn))


func _test_only_one_turn_can_be_pending_per_step() -> void:
	var model = _fresh_model()
	var start_events: Array[Dictionary] = model.request_turn(Vector2i.UP)
	var queue_events: Array[Dictionary] = model.request_turn(Vector2i.LEFT)
	var queued: Dictionary = model.snapshot()
	var first_events: Array[Dictionary] = model.advance_step()
	var after_first: Dictionary = model.snapshot()
	var next_turn_events: Array[Dictionary] = model.request_turn(Vector2i.LEFT)
	var second_events: Array[Dictionary] = model.advance_step()
	var after_second: Dictionary = model.snapshot()
	var passed: bool = (
		_has_event(start_events, "turn_accepted")
		and _has_rejection(queue_events, "reverse")
		and queued["turn_queue"] == [[0, -1]]
		and _has_event(first_events, "moved")
		and after_first["snake"][0] == [7, 10]
		and after_first["direction"] == [0, -1]
		and after_first["turn_queue"].is_empty()
		and _has_event(next_turn_events, "turn_accepted")
		and _has_event(second_events, "moved")
		and after_second["snake"][0] == [6, 10]
		and after_second["direction"] == [-1, 0]
		and after_second["turn_queue"].is_empty()
	)
	_record("one_pending_turn_per_step", passed, JSON.stringify(after_second))


func _test_reverse_turn_is_rejected() -> void:
	var model = _fresh_model()
	var immediate_events: Array[Dictionary] = model.request_turn(Vector2i.LEFT)
	var after_immediate: Dictionary = model.snapshot()
	var accepted_events: Array[Dictionary] = model.request_turn(Vector2i.UP)
	var queued_reverse_events: Array[Dictionary] = model.request_turn(Vector2i.DOWN)
	var after_queued_reverse: Dictionary = model.snapshot()
	var passed: bool = (
		_has_rejection(immediate_events, "reverse")
		and str(after_immediate["phase"]) == "running"
		and after_immediate["turn_queue"].is_empty()
		and _has_event(accepted_events, "turn_accepted")
		and _has_rejection(queued_reverse_events, "pending_turn")
		and after_queued_reverse["turn_queue"] == [[0, -1]]
	)
	_record("reverse_turn_rejected", passed, JSON.stringify(after_queued_reverse))


func _test_current_tail_cell_is_legal_when_not_eating() -> void:
	var model = _fresh_model()
	var fixture: Array[Vector2i] = [
		Vector2i(2, 2), Vector2i(2, 3), Vector2i(1, 3), Vector2i(1, 2)
	]
	model.snake.assign(fixture)
	model.direction = Vector2i.LEFT
	model.food = Vector2i(8, 8)
	model.phase = RUNNING
	var events: Array[Dictionary] = model.advance_step()
	var moved: Dictionary = _find_event(events, "moved")
	var after: Dictionary = model.snapshot()
	var passed: bool = (
		str(after["phase"]) == "running"
		and after["snake"] == [[1, 2], [2, 2], [2, 3], [1, 3]]
		and _has_event(events, "moved")
		and moved.get("tail") == Vector2i(1, 2)
		and bool(moved.get("tail_vacated", false))
		and not _has_event(events, "self_hit")
	)
	_record("tail_cell_is_legal", passed, JSON.stringify(after))


func _test_wall_collision_loses_with_wall_reason() -> void:
	var model = _fresh_model()
	var fixture: Array[Vector2i] = [Vector2i(14, 11), Vector2i(13, 11), Vector2i(12, 11)]
	model.snake.assign(fixture)
	model.direction = Vector2i.RIGHT
	model.phase = RUNNING
	var before: Dictionary = model.snapshot()
	var events: Array[Dictionary] = model.advance_step()
	var after: Dictionary = model.snapshot()
	var passed: bool = (
		str(after["phase"]) == "lost"
		and str(after["terminal_reason"]) == "wall"
		and _has_event(events, "wall_hit")
		and not _has_event(events, "moved")
		and after["snake"] == before["snake"]
		and int(after["moves"]) == 0
	)
	_record("wall_collision_reason", passed, JSON.stringify(after))


func _test_self_collision_loses_with_self_reason() -> void:
	var model = _fresh_model()
	var fixture: Array[Vector2i] = [
		Vector2i(2, 2), Vector2i(2, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)
	]
	model.snake.assign(fixture)
	model.direction = Vector2i.LEFT
	model.food = Vector2i(8, 8)
	model.phase = RUNNING
	var before: Dictionary = model.snapshot()
	var events: Array[Dictionary] = model.advance_step()
	var after: Dictionary = model.snapshot()
	var passed: bool = (
		str(after["phase"]) == "lost"
		and str(after["terminal_reason"]) == "self"
		and _has_event(events, "self_hit")
		and not _has_event(events, "moved")
		and after["snake"] == before["snake"]
		and int(after["moves"]) == 0
	)
	_record("self_collision_reason", passed, JSON.stringify(after))


func _test_eating_grows_scores_and_spawns_free_food() -> void:
	var model = _fresh_model()
	model.phase = RUNNING
	model.food = Vector2i(8, 11)
	var events: Array[Dictionary] = model.advance_step()
	var moved: Dictionary = _find_event(events, "moved")
	var after: Dictionary = model.snapshot()
	var passed: bool = (
		str(after["phase"]) == "running"
		and int(after["score"]) == 4
		and int(after["moves"]) == 1
		and after["snake"].size() == 4
		and after["snake"][0] == [8, 11]
		and _has_event(events, "moved")
		and moved.get("tail") == Vector2i(4, 11)
		and bool(moved.get("tail_vacated", false))
		and _has_event(events, "ate")
		and _has_event(events, "food_spawned")
		and int(after["pending_growth"]) == 2
		and after["foods"].size() == 2
		and not after["snake"].has(after["food"])
	)
	_record("eat_grows_scores_spawns_free_food", passed, JSON.stringify(after))


func _test_growth_materializes_and_game_stays_endless() -> void:
	var model = _fresh_model()
	model.phase = RUNNING
	model.food = Vector2i(8, 11)
	var eat_events: Array[Dictionary] = model.advance_step()
	var size_after_eat: int = model.snake.size()
	var score_after_eat: int = model.score
	var first_growth: Array[Dictionary] = model.advance_step()
	var size_after_first: int = model.snake.size()
	var score_after_first: int = model.score
	var second_growth: Array[Dictionary] = model.advance_step()
	var after: Dictionary = model.snapshot()
	var passed: bool = (
		str(after["phase"]) == "running"
		and str(after["terminal_reason"]).is_empty()
		and size_after_eat == 4
		and score_after_eat == 4
		and size_after_first == 5
		and score_after_first == 5
		and after["snake"].size() == 6
		and int(after["score"]) == 6
		and int(after["pending_growth"]) == 0
		and _has_event(eat_events, "ate")
		and _has_event(first_growth, "moved")
		and _has_event(second_growth, "moved")
		and not _has_event(eat_events, "won")
	)
	_record("queued_growth_endless_game", passed, JSON.stringify(after))


func _test_terminal_states_reject_input_and_freeze_steps() -> void:
	var passed: bool = true
	var evidence: Array[String] = []
	for terminal_phase in [WON, LOST]:
		var model = _fresh_model()
		model.phase = terminal_phase
		model.terminal_reason = "target" if terminal_phase == WON else "wall"
		var before: Dictionary = model.snapshot()
		var turn_events: Array[Dictionary] = model.request_turn(Vector2i.UP)
		var step_events: Array[Dictionary] = model.advance_step()
		var after: Dictionary = model.snapshot()
		passed = passed and _has_rejection(turn_events, "terminal") and step_events.is_empty() and after == before
		evidence.append(JSON.stringify(after))
	_record("terminal_states_are_frozen", passed, "|".join(evidence))


func _test_reset_restores_ready_defaults() -> void:
	var model = _fresh_model()
	model.request_turn(Vector2i.UP)
	model.advance_step()
	model.request_turn(Vector2i.LEFT)
	model.advance_step()
	model.score = 70
	model.terminal_reason = "self"
	model.phase = LOST
	model.reset(true, 77)
	var after: Dictionary = model.snapshot()
	var passed: bool = (
		model.wrap
		and str(after["phase"]) == "running"
		and str(after["terminal_reason"]).is_empty()
		and after["snake"] == [[7, 11], [6, 11], [5, 11], [4, 11]]
		and after["direction"] == [1, 0]
		and after["turn_queue"].is_empty()
		and after["food"] == [11, 11]
		and after["foods"] == [[11, 11], [4, 6]]
		and int(after["score"]) == 4
		and int(after["pending_growth"]) == 0
		and int(after["moves"]) == 0
		and int(after["step_index"]) == 0
		and bool(after["started"])
	)
	_record("reset_restores_ready_defaults", passed, JSON.stringify(after))
