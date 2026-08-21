extends SceneTree

## Stage-0 renderer-free contract probe for Offline Games / Snakes. The test
## names separate first-party-supported outcomes from bounded local decisions.

const MODEL_PATH := "res://models/snakes_arena_model.gd"
const TEST_SEED := 20260820
const EXPECTED_CASES := 10

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
	_test_offline_entry_is_live_and_service_free()
	_test_continuous_steer_changes_heading_and_position()
	_test_eat_food_grows_player()
	_test_local_boost_is_bounded_and_costly()
	_test_rival_body_contact_kills_player()
	_test_local_bot_respawn_is_bounded()
	_test_biggest_means_rank_one_without_terminal_win()
	_test_explicit_restart_recreates_clean_seeded_state()
	_test_json_roundtrip_restore_and_continuation()
	_test_corrupt_or_terminal_recovery_is_rejected_atomically()
	_finish()


func _fresh(bot_count: int = 5, pellet_count: int = 48):
	var model = model_script.new()
	model.reset(TEST_SEED, bot_count, pellet_count)
	return model


func _finish() -> void:
	if cases_run != EXPECTED_CASES:
		failures.append("case_count_%d_of_%d" % [cases_run, EXPECTED_CASES])
	print("SNAKES_V3_CONTRACT_CASES=%d" % cases_run)
	print("SNAKES_V3_CONTRACT_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
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


func _test_offline_entry_is_live_and_service_free() -> void:
	var model = _fresh()
	var saved: Dictionary = model.snapshot()
	var passed: bool = (
		str(saved.get("schema", "")) == "snakes-arena-state/v1"
		and str(saved.get("status", "")) == "playing"
		and saved.get("snakes", []).size() == 6
		and saved.get("pellets", []).size() == 48
		and not ("network" in saved)
		and not ("service" in saved)
	)
	_record("reference_offline_entry", passed, JSON.stringify(saved))


func _test_continuous_steer_changes_heading_and_position() -> void:
	var model = _fresh(0, 0)
	var before: Dictionary = model.snapshot()
	model.set_player_aim(Vector2(0.0, -420.0))
	var events: Array[Dictionary] = model.step(0.10)
	var after: Dictionary = model.snapshot()
	var before_position := Vector2(float(before["player"]["position"][0]), float(before["player"]["position"][1]))
	var after_position := Vector2(float(after["player"]["position"][0]), float(after["player"]["position"][1]))
	var heading := float(after["player"]["heading"])
	_record("inferred_continuous_steer", _has_event(events, "player_steered") and after_position != before_position and heading < -0.01 and heading > -0.55, JSON.stringify(after["player"]))


func _test_eat_food_grows_player() -> void:
	var model = _fresh(0, 0)
	var before_mass := float(model.snapshot()["mass"])
	model.target_pellet_count = 1
	model.pellets.assign([{
		"id":9001,
		"position":Vector2(8.0, 0.0),
		"value":4.0,
		"palette":1,
		"source":"ambient",
		"born_at":model.elapsed,
	}])
	var events: Array[Dictionary] = model.step(0.10)
	var after: Dictionary = model.snapshot()
	_record("reference_eat_grows", _has_event(events, "player_ate") and float(after["mass"]) >= before_mass + 3.9, JSON.stringify(events))


func _test_local_boost_is_bounded_and_costly() -> void:
	var boosted = _fresh(0, 0)
	var normal = _fresh(0, 0)
	boosted.set_player_boost(true)
	var events: Array[Dictionary] = []
	for _tick in range(30):
		events.append_array(boosted.step(1.0 / 60.0))
		normal.step(1.0 / 60.0)
	var boost_state: Dictionary = boosted.snapshot()
	var normal_state: Dictionary = normal.snapshot()
	var passed: bool = (
		_has_event(events, "boost_started")
		and _has_event(events, "boost_shed")
		and float(boost_state["mass"]) < float(normal_state["mass"])
		and float(boost_state["player"]["position"][0]) > float(normal_state["player"]["position"][0])
		and float(boost_state["mass"]) >= boosted.minimum_boost_mass
	)
	_record("decision_boost_cost_and_bound", passed, JSON.stringify(boost_state["player"]))


func _test_rival_body_contact_kills_player() -> void:
	var model = _fresh(1, 0)
	model.target_pellet_count = 0
	var player: Dictionary = model.snakes[0]
	player["position"] = Vector2.ZERO
	player["previous_position"] = Vector2.ZERO
	player["segments"] = [Vector2.ZERO, Vector2(-14.0, 0.0), Vector2(-28.0, 0.0)]
	player["heading"] = 0.0
	player["invulnerable"] = 0.0
	model.snakes[0] = player
	var bot: Dictionary = model.snakes[1]
	bot["position"] = Vector2(260.0, 260.0)
	bot["previous_position"] = bot["position"]
	bot["segments"] = [Vector2(260.0, 260.0), Vector2(28.0, -28.0), Vector2(28.0, -14.0), Vector2(28.0, 0.0), Vector2(28.0, 14.0)]
	bot["speed_scale"] = 0.0
	bot["invulnerable"] = 0.0
	model.snakes[1] = bot
	var events: Array[Dictionary] = model.step(0.18)
	var after: Dictionary = model.snapshot()
	_record("decision_rival_body_death", str(after["phase"]) == "lost" and _has_event(events, "player_died") and _has_event(events, "debris_dropped"), JSON.stringify(events))


func _test_local_bot_respawn_is_bounded() -> void:
	var model = _fresh(1, 0)
	model.target_pellet_count = 0
	model.snakes[0]["speed_scale"] = 0.0
	model.snakes[0]["invulnerable"] = 10.0
	model.kill_snake_for_test(1, "fixture")
	var dead_before: bool = not bool(model.snapshot()["snakes"][1]["alive"])
	var events: Array[Dictionary] = []
	for _tick in range(180):
		events.append_array(model.step(1.0 / 60.0))
	var alive_after: bool = bool(model.snapshot()["snakes"][1]["alive"])
	_record("decision_bot_respawn", dead_before and alive_after and _has_event(events, "bot_respawned"), JSON.stringify(events))


func _test_biggest_means_rank_one_without_terminal_win() -> void:
	var model = _fresh(3, 12)
	model.snakes[0]["mass"] = 240.0
	for index in range(1, model.snakes.size()):
		model.snakes[index]["mass"] = 20.0 + float(index)
	var saved: Dictionary = model.snapshot()
	var passed: bool = int(saved["rank"]) == 1 and int(saved["leaderboard"][0]["id"]) == 0 and str(saved["phase"]) == "running" and str(saved["status"]) == "playing"
	_record("reference_biggest_decision_nonterminal", passed, JSON.stringify(saved["leaderboard"]))


func _test_explicit_restart_recreates_clean_seeded_state() -> void:
	var model = _fresh(2, 16)
	model.set_player_aim(Vector2(0.0, -400.0))
	model.set_player_boost(true)
	model.step(0.42)
	model.reset(TEST_SEED, 2, 16)
	var fresh = _fresh(2, 16)
	_record("decision_explicit_restart", JSON.stringify(model.snapshot()) == JSON.stringify(fresh.snapshot()))


func _test_json_roundtrip_restore_and_continuation() -> void:
	var original = _fresh(3, 24)
	original.set_player_aim(Vector2(-240.0, 360.0))
	original.step(0.37)
	var serialized := JSON.stringify(original.snapshot())
	var parsed: Variant = JSON.parse_string(serialized)
	var restored = _fresh(0, 0)
	var accepted: bool = parsed is Dictionary and restored.restore(parsed)
	var before_matches := false
	var future_matches := false
	if accepted:
		var first: Dictionary = original.snapshot()
		var second: Dictionary = restored.snapshot()
		before_matches = (
			int(first["tick"]) == int(second["tick"])
			and is_equal_approx(float(first["mass"]), float(second["mass"]))
			and first["player"]["position"] == second["player"]["position"]
			and first["leaderboard"] == second["leaderboard"]
		)
		original.step(0.25)
		restored.step(0.25)
		future_matches = JSON.stringify(original.snapshot()) == JSON.stringify(restored.snapshot())
	_record("decision_json_restore_continue", accepted and before_matches and future_matches, JSON.stringify({"accepted":accepted, "before":before_matches, "future":future_matches}))


func _test_corrupt_or_terminal_recovery_is_rejected_atomically() -> void:
	var model = _fresh(2, 12)
	var pristine := JSON.stringify(model.snapshot())
	var wrong_schema: Dictionary = model.snapshot().duplicate(true)
	wrong_schema["schema"] = "snakes-arena-state/v0"
	var duplicate_id: Dictionary = model.snapshot().duplicate(true)
	duplicate_id["snakes"][1]["id"] = 0
	var invalid_position: Dictionary = model.snapshot().duplicate(true)
	invalid_position["snakes"][0]["position"] = [999999.0, 0.0]
	var terminal: Dictionary = model.snapshot().duplicate(true)
	terminal["phase"] = "lost"
	terminal["status"] = "over"
	var rejected: bool = (
		not model.restore(wrong_schema)
		and not model.restore(duplicate_id)
		and not model.restore(invalid_position)
		and not model.restore(terminal)
	)
	_record("decision_corrupt_restore_rejected", rejected and JSON.stringify(model.snapshot()) == pristine)
