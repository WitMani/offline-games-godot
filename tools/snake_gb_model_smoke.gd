extends SceneTree

const MODEL_PATH := "res://models/snake_gb_model.gd"
const TEST_SEED := 1201989
const EXPECTED_CASES := 16

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
	_test_entry_contract()
	_test_food_seed_is_deterministic()
	_test_automatic_tick()
	_test_turn_queue_uses_current_direction()
	_test_reverse_duplicate_invalid_rejection()
	_test_food_placement_is_legal_across_seeds()
	_test_either_food_slot_can_be_eaten()
	_test_food_queues_two_growth_steps()
	_test_wall_collision()
	_test_self_collision()
	_test_vacating_tail_collision_rule()
	_test_terminal_freezes()
	_test_restart_is_deterministic()
	_test_recovery_round_trip_and_rng_continuity()
	_test_recovery_rejects_atomically()
	_test_length_120_is_nonterminal_record()
	_finish()


func _fresh_model(seed_value := TEST_SEED):
	var model = model_script.new()
	model.reset(seed_value)
	return model


func _finish() -> void:
	if cases_run != EXPECTED_CASES:
		failures.append("case_count_%d_of_%d" % [cases_run, EXPECTED_CASES])
	print("SNAKE_GB_MODEL_CASES=%d" % cases_run)
	print("SNAKE_GB_MODEL_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _record(name: String, passed: bool, evidence: Variant = "") -> void:
	cases_run += 1
	if not passed:
		var packed: String = str(evidence) if evidence is String else JSON.stringify(evidence)
		failures.append(name + ("=" + packed if not packed.is_empty() else ""))


func _has_event(events: Array[Dictionary], kind: String) -> bool:
	return _event(events, kind) != {}


func _event(events: Array[Dictionary], kind: String) -> Dictionary:
	for event in events:
		if str(event.get("kind", "")) == kind:
			return event
	return {}


func _has_rejection(events: Array[Dictionary], reason: String) -> bool:
	var rejection: Dictionary = _event(events, "turn_rejected")
	return str(rejection.get("reason", "")) == reason


func _foods_are_legal(state: Dictionary) -> bool:
	var foods: Array = state.get("foods", [])
	if foods.size() != 2 or foods[0] == foods[1]:
		return false
	for packed in foods:
		if not packed is Array or packed.size() != 2:
			return false
		if int(packed[0]) < 0 or int(packed[0]) >= int(state.get("width", 0)):
			return false
		if int(packed[1]) < 0 or int(packed[1]) >= int(state.get("height", 0)):
			return false
		if state.get("segments", []).has(packed):
			return false
	return true


func _set_foods(model, first: Vector2i, second: Vector2i) -> void:
	model.foods.assign([first, second])
	model.food = first


func _test_entry_contract() -> void:
	var state: Dictionary = _fresh_model().snapshot()
	var passed: bool = (
		state.get("snapshot_version") == 1
		and state.get("phase") == "running" and state.get("status") == "playing"
		and int(state.get("width", 0)) == 15 and int(state.get("height", 0)) == 23
		and state.get("segments", []) == [[7, 11], [6, 11], [5, 11], [4, 11]]
		and state.get("direction", []) == [1, 0]
		and int(state.get("score", 0)) == 4
		and bool(state.get("endless", false))
		and not state.has("target_length") and state.get("status") != "won"
		and _foods_are_legal(state)
		and state.get("food", []) == state.get("foods", [])[0]
	)
	_record("entry_contract", passed, state)


func _test_food_seed_is_deterministic() -> void:
	var first: Dictionary = _fresh_model(TEST_SEED).snapshot()
	var second: Dictionary = _fresh_model(TEST_SEED).snapshot()
	var alternate: Dictionary = _fresh_model(TEST_SEED + 1).snapshot()
	var passed: bool = (
		first.get("foods", []) == second.get("foods", [])
		and first.get("rng_state", "") == second.get("rng_state", "")
		and first.get("foods", []) != alternate.get("foods", [])
	)
	_record("deterministic_food_seed", passed, {"first":first.get("foods"), "alternate":alternate.get("foods")})


func _test_automatic_tick() -> void:
	var model = _fresh_model()
	var events: Array[Dictionary] = model.advance_step()
	var state: Dictionary = model.snapshot()
	var moved: Dictionary = _event(events, "moved")
	var passed: bool = (
		moved.get("from") == Vector2i(7, 11) and moved.get("to") == Vector2i(8, 11)
		and bool(moved.get("tail_vacated", false))
		and state.get("segments", [])[0] == [8, 11]
		and state.get("segments", []).back() == [5, 11]
		and int(state.get("moves", -1)) == 1 and int(state.get("score", -1)) == 4
	)
	_record("automatic_tick", passed, {"events":events, "state":state})


func _test_turn_queue_uses_current_direction() -> void:
	var model = _fresh_model()
	var accepted: Array[Dictionary] = model.request_turn(Vector2i.UP)
	var pending_corner: Array[Dictionary] = model.request_turn(Vector2i.LEFT)
	var before: Dictionary = model.snapshot()
	model.advance_step()
	var after: Dictionary = model.snapshot()
	var accepted_after_tick: Array[Dictionary] = model.request_turn(Vector2i.LEFT)
	var passed: bool = (
		_has_event(accepted, "turn_accepted")
		and _has_rejection(pending_corner, "pending_turn")
		and before.get("turn_queue", []) == [[0, -1]]
		and after.get("direction", []) == [0, -1] and after.get("turn_queue", []).is_empty()
		and after.get("segments", [])[0] == [7, 10]
		and _has_event(accepted_after_tick, "turn_accepted")
	)
	_record("turn_queue_current_direction", passed, {"before":before, "after":after})


func _test_reverse_duplicate_invalid_rejection() -> void:
	var model = _fresh_model()
	var reverse: Array[Dictionary] = model.request_turn(Vector2i.LEFT)
	var duplicate: Array[Dictionary] = model.request_turn(Vector2i.RIGHT)
	var invalid: Array[Dictionary] = model.request_turn(Vector2i(1, 1))
	var passed: bool = (
		_has_rejection(reverse, "reverse")
		and _has_rejection(duplicate, "duplicate")
		and _has_rejection(invalid, "invalid")
		and model.snapshot().get("turn_queue", []).is_empty()
	)
	_record("turn_rejections", passed, {"reverse":reverse, "duplicate":duplicate, "invalid":invalid})


func _test_food_placement_is_legal_across_seeds() -> void:
	var passed: bool = true
	var evidence: Array = []
	for seed_value in range(64):
		var state: Dictionary = _fresh_model(TEST_SEED + seed_value).snapshot()
		if not _foods_are_legal(state):
			passed = false
			evidence.append({"seed":seed_value, "state":state})
			break
	_record("food_placement_64_seeds", passed, evidence)


func _test_either_food_slot_can_be_eaten() -> void:
	var slot_results: Array = []
	var passed: bool = true
	for slot in range(2):
		var model = _fresh_model(TEST_SEED + slot)
		var next: Vector2i = model.segments[0] + model.direction
		var untouched: Vector2i = Vector2i(2, 2)
		_set_foods(model, next if slot == 0 else untouched, untouched if slot == 0 else next)
		var before: Array = model.snapshot().get("foods", []).duplicate(true)
		var events: Array[Dictionary] = model.advance_step()
		var after: Dictionary = model.snapshot()
		var ate: Dictionary = _event(events, "ate")
		var spawned: Dictionary = _event(events, "food_spawned")
		var slot_passed: bool = (
			int(ate.get("food_index", -1)) == slot
			and int(spawned.get("food_index", -1)) == slot
			and int(ate.get("growth_queued", -1)) == 2
			and after.get("foods", []).size() == 2
			and after.get("foods", [])[1 - slot] == before[1 - slot]
			and after.get("foods", [])[slot] != before[slot]
			and _foods_are_legal(after)
		)
		passed = passed and slot_passed
		slot_results.append({"slot":slot, "events":events, "after":after})
	_record("either_food_slot_edible", passed, slot_results)


func _test_food_queues_two_growth_steps() -> void:
	var model = _fresh_model()
	var next: Vector2i = model.segments[0] + model.direction
	_set_foods(model, next, Vector2i(2, 2))
	var eat_events: Array[Dictionary] = model.advance_step()
	var after_eat: Dictionary = model.snapshot()
	var first_growth: Array[Dictionary] = model.advance_step()
	var after_first: Dictionary = model.snapshot()
	var second_growth: Array[Dictionary] = model.advance_step()
	var after_second: Dictionary = model.snapshot()
	var passed: bool = (
		_has_event(eat_events, "ate")
		and int(after_eat.get("score", -1)) == 4 and int(after_eat.get("pending_growth", -1)) == 2
		and _has_event(first_growth, "growth_materialized")
		and int(after_first.get("score", -1)) == 5 and int(after_first.get("pending_growth", -1)) == 1
		and _has_event(second_growth, "growth_materialized")
		and int(after_second.get("score", -1)) == 6 and int(after_second.get("pending_growth", -1)) == 0
		and after_second.get("status") == "playing"
	)
	_record("two_growth_steps", passed, {"eat":after_eat, "first":after_first, "second":after_second})


func _test_wall_collision() -> void:
	var model = _fresh_model()
	model.segments.assign([Vector2i(14, 11), Vector2i(13, 11), Vector2i(12, 11), Vector2i(11, 11)])
	model.direction = Vector2i.RIGHT
	model.score = 4
	_set_foods(model, Vector2i(2, 2), Vector2i(3, 3))
	var events: Array[Dictionary] = model.advance_step()
	var state: Dictionary = model.snapshot()
	var passed: bool = state.get("phase") == "lost" and state.get("terminal_reason") == "wall" and _has_event(events, "wall_hit")
	_record("wall_collision", passed, {"events":events, "state":state})


func _test_self_collision() -> void:
	var model = _fresh_model()
	model.segments.assign([Vector2i(2, 2), Vector2i(2, 3), Vector2i(1, 3), Vector2i(1, 2), Vector2i(1, 1)])
	model.direction = Vector2i.DOWN
	model.score = model.segments.size()
	_set_foods(model, Vector2i(8, 8), Vector2i(9, 9))
	var events: Array[Dictionary] = model.advance_step()
	var state: Dictionary = model.snapshot()
	var passed: bool = state.get("phase") == "lost" and state.get("terminal_reason") == "self" and _has_event(events, "self_hit")
	_record("self_collision", passed, {"events":events, "state":state})


func _test_vacating_tail_collision_rule() -> void:
	var legal = _fresh_model()
	legal.segments.assign([Vector2i(2, 2), Vector2i(2, 3), Vector2i(1, 3), Vector2i(1, 2)])
	legal.direction = Vector2i.LEFT
	legal.score = 4
	_set_foods(legal, Vector2i(8, 8), Vector2i(9, 9))
	var legal_events: Array[Dictionary] = legal.advance_step()
	var legal_state: Dictionary = legal.snapshot()
	var blocked = _fresh_model()
	blocked.segments.assign([Vector2i(2, 2), Vector2i(2, 3), Vector2i(1, 3), Vector2i(1, 2)])
	blocked.direction = Vector2i.LEFT
	blocked.score = 4
	blocked.pending_growth = 1
	_set_foods(blocked, Vector2i(8, 8), Vector2i(9, 9))
	var blocked_events: Array[Dictionary] = blocked.advance_step()
	var blocked_state: Dictionary = blocked.snapshot()
	var passed: bool = (
		legal_state.get("status") == "playing" and legal_state.get("segments", [])[0] == [1, 2]
		and _has_event(legal_events, "moved")
		and blocked_state.get("terminal_reason") == "self" and _has_event(blocked_events, "self_hit")
	)
	_record("vacating_tail_rule", passed, {"legal":legal_state, "blocked":blocked_state})


func _test_terminal_freezes() -> void:
	var model = _fresh_model()
	model.segments.assign([Vector2i(14, 11), Vector2i(13, 11), Vector2i(12, 11), Vector2i(11, 11)])
	model.direction = Vector2i.RIGHT
	model.score = 4
	_set_foods(model, Vector2i(2, 2), Vector2i(3, 3))
	model.advance_step()
	var before: String = JSON.stringify(model.snapshot())
	var events: Array[Dictionary] = model.advance_step()
	var rejection: Array[Dictionary] = model.request_turn(Vector2i.UP)
	var after: String = JSON.stringify(model.snapshot())
	var passed: bool = events.is_empty() and before == after and _has_rejection(rejection, "terminal")
	_record("terminal_freeze", passed, after)


func _test_restart_is_deterministic() -> void:
	var model = _fresh_model()
	var entry: Dictionary = model.snapshot()
	model.advance_step()
	model.reset(TEST_SEED)
	var restarted: Dictionary = model.snapshot()
	model.reset(TEST_SEED + 9)
	var alternate: Dictionary = model.snapshot()
	var passed: bool = (
		restarted == entry
		and alternate.get("status") == "playing"
		and alternate.get("segments", []) == entry.get("segments", [])
		and alternate.get("foods", []) != entry.get("foods", [])
		and _foods_are_legal(alternate)
	)
	_record("restart_deterministic", passed, {"entry":entry, "restarted":restarted, "alternate":alternate})


func _test_recovery_round_trip_and_rng_continuity() -> void:
	var original = _fresh_model()
	original.request_turn(Vector2i.UP)
	original.advance_step()
	var saved: Dictionary = original.snapshot()
	var restored = _fresh_model(TEST_SEED + 99)
	var accepted: bool = restored.restore(saved)
	var exact_round_trip: bool = restored.snapshot() == saved
	# Force an equal legal forage in both instances. Matching replacement cells
	# prove that the RNG state, not only the visible board, survived recovery.
	var next: Vector2i = original.segments[0] + original.direction
	_set_foods(original, next, Vector2i(2, 2))
	_set_foods(restored, next, Vector2i(2, 2))
	var original_events: Array[Dictionary] = original.advance_step()
	var restored_events: Array[Dictionary] = restored.advance_step()
	var passed: bool = (
		accepted and exact_round_trip
		and original.snapshot() == restored.snapshot()
		and _event(original_events, "food_spawned") == _event(restored_events, "food_spawned")
	)
	_record("recovery_round_trip_rng", passed, {"saved":saved, "original":original.snapshot(), "restored":restored.snapshot()})


func _test_recovery_rejects_atomically() -> void:
	var corruptions: Array[Dictionary] = []
	var source: Dictionary = _fresh_model().snapshot()
	var duplicate_food: Dictionary = source.duplicate(true)
	duplicate_food["foods"][1] = duplicate_food["foods"][0]
	corruptions.append(duplicate_food)
	var broken_body: Dictionary = source.duplicate(true)
	broken_body["segments"][1] = [14, 22]
	corruptions.append(broken_body)
	var broken_rng: Dictionary = source.duplicate(true)
	broken_rng["rng_state"] = "not-an-int"
	corruptions.append(broken_rng)
	var wrong_phase: Dictionary = source.duplicate(true)
	wrong_phase["phase"] = "won"
	wrong_phase["status"] = "won"
	corruptions.append(wrong_phase)
	var model = _fresh_model(TEST_SEED + 77)
	var before: String = JSON.stringify(model.snapshot())
	var passed: bool = true
	for corrupt in corruptions:
		if model.restore(corrupt) or JSON.stringify(model.snapshot()) != before:
			passed = false
			break
	_record("recovery_atomic_rejection", passed, corruptions)


func _test_length_120_is_nonterminal_record() -> void:
	var model = _fresh_model()
	var tail_to_head: Array[Vector2i] = []
	for y in range(7):
		if y % 2 == 0:
			for x in range(15):
				tail_to_head.append(Vector2i(x, y))
		else:
			for x in range(14, -1, -1):
				tail_to_head.append(Vector2i(x, y))
	for x in range(14, 0, -1):
		tail_to_head.append(Vector2i(x, 7))
	var head_to_tail: Array[Vector2i] = tail_to_head.duplicate()
	head_to_tail.reverse()
	model.segments.assign(head_to_tail)
	model.direction = Vector2i.DOWN
	model.turn_queue.clear()
	model.score = 119
	model.moves = 115
	model.step_index = 115
	model.pending_growth = 1
	_set_foods(model, Vector2i(12, 20), Vector2i(13, 21))
	var record_events: Array[Dictionary] = model.advance_step()
	var record_state: Dictionary = model.snapshot()
	model.pending_growth = 1
	var continued_events: Array[Dictionary] = model.advance_step()
	var continued_state: Dictionary = model.snapshot()
	var record_event: Dictionary = _event(record_events, "field_record_complete")
	var passed: bool = (
		int(record_state.get("score", -1)) == 120
		and record_state.get("status") == "playing" and record_state.get("phase") == "running"
		and _has_event(record_events, "length_milestone")
		and bool(record_event.get("nonterminal", false))
		and not _has_event(record_events, "length_won")
		and int(continued_state.get("score", -1)) == 121
		and continued_state.get("status") == "playing"
		and _has_event(continued_events, "growth_materialized")
	)
	_record("length_120_nonterminal_record", passed, {"record_events":record_events, "record_state":record_state, "continued_state":continued_state})
