extends SceneTree

const MODEL_PATH := "res://models/snakes_arena_model.gd"
const TEST_SEED := 1362026
const EXPECTED_CASES := 18

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

	_test_reset_builds_live_competition()
	_test_seed_is_deterministic()
	_test_steering_is_continuous_and_bounded()
	_test_boost_trades_mass_for_speed_and_trail_food()
	_test_low_mass_cannot_boost()
	_test_eating_food_grows_mass_and_replenishes()
	_test_leaderboard_is_sorted_and_ranks_player()
	_test_body_collision_kills_and_drops_loot()
	_test_own_body_and_tail_are_nonlethal()
	_test_bots_scavenge_debris_and_leader_reorders()
	_test_head_to_head_is_symmetric_and_mass_based()
	_test_head_collision_chain_is_order_independent()
	_test_simultaneous_body_collisions_are_atomic()
	_test_food_does_not_bias_same_tick_head_collision()
	_test_pellet_population_is_bounded()
	_test_boundary_collision_kills_player()
	_test_dead_bot_respawns()
	_test_snapshot_is_json_safe_and_reset_recovers()
	_finish()


func _fresh_model(bot_count: int = 5, pellet_count: int = 72):
	var model = model_script.new()
	model.reset(TEST_SEED, bot_count, pellet_count)
	return model


func _finish() -> void:
	if cases_run != EXPECTED_CASES:
		failures.append("case_count_%d_of_%d" % [cases_run, EXPECTED_CASES])
	print("SNAKES_ARENA_MODEL_CASES=%d" % cases_run)
	print("SNAKES_ARENA_MODEL_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _record(case_name: String, passed: bool, evidence: String = "") -> void:
	cases_run += 1
	if passed:
		return
	failures.append(case_name + ("=" + evidence if not evidence.is_empty() else ""))


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


func _test_reset_builds_live_competition() -> void:
	var model = _fresh_model()
	var state: Dictionary = model.snapshot()
	var passed: bool = (
		state.get("phase") == "running"
		and state.get("status") == "playing"
		and int(state.get("player_id", -1)) == 0
		and state.get("snakes", []).size() == 6
		and state.get("pellets", []).size() == 72
		and state.get("leaderboard", []).size() == 6
		and int(state.get("rank", 0)) >= 1
	)
	_record("reset_live_competition", passed, JSON.stringify(state))


func _test_seed_is_deterministic() -> void:
	var first = _fresh_model()
	var second = _fresh_model()
	for _tick in range(30):
		first.step(1.0 / 60.0)
		second.step(1.0 / 60.0)
	var passed: bool = JSON.stringify(first.snapshot()) == JSON.stringify(second.snapshot())
	_record("seed_deterministic", passed)


func _test_steering_is_continuous_and_bounded() -> void:
	var model = _fresh_model()
	var before: Dictionary = model.snapshot()
	model.set_player_aim(Vector2(0.0, -400.0))
	var events: Array[Dictionary] = model.step(0.1)
	var after: Dictionary = model.snapshot()
	var before_pos: Vector2 = Vector2(float(before["player"]["position"][0]), float(before["player"]["position"][1]))
	var after_pos: Vector2 = Vector2(float(after["player"]["position"][0]), float(after["player"]["position"][1]))
	var heading: float = float(after["player"]["heading"])
	var passed: bool = (
		_has_event(events, "player_steered")
		and after_pos.distance_to(before_pos) > 4.0
		and heading < -0.01
		and heading > -0.55
	)
	_record("continuous_bounded_steering", passed, JSON.stringify(after["player"]))


func _test_boost_trades_mass_for_speed_and_trail_food() -> void:
	var boosted = _fresh_model()
	var normal = _fresh_model()
	boosted.set_player_boost(true)
	var boost_events: Array[Dictionary] = []
	for _tick in range(30):
		boost_events.append_array(boosted.step(1.0 / 60.0))
		normal.step(1.0 / 60.0)
	var boost_state: Dictionary = boosted.snapshot()
	var normal_state: Dictionary = normal.snapshot()
	var boost_x: float = float(boost_state["player"]["position"][0])
	var normal_x: float = float(normal_state["player"]["position"][0])
	var passed: bool = (
		boost_x > normal_x + 12.0
		and float(boost_state["mass"]) < float(normal_state["mass"])
		and _has_event(boost_events, "boost_started")
		and _has_event(boost_events, "boost_shed")
		and boost_state.get("pellets", []).size() > normal_state.get("pellets", []).size()
	)
	_record("boost_cost_speed_trail", passed, JSON.stringify(boost_state["player"]))


func _test_low_mass_cannot_boost() -> void:
	var model = _fresh_model()
	model.snakes[model.player_index]["mass"] = model.minimum_boost_mass - 0.1
	model.set_player_boost(true)
	var events: Array[Dictionary] = model.step(0.1)
	var state: Dictionary = model.snapshot()
	var passed: bool = not bool(state["player"]["boosting"]) and _has_event(events, "boost_rejected")
	_record("low_mass_boost_rejected", passed, JSON.stringify(state["player"]))


func _test_eating_food_grows_mass_and_replenishes() -> void:
	var model = _fresh_model()
	var player: Dictionary = model.snakes[model.player_index]
	var before_mass: float = float(player["mass"])
	var before_count: int = model.pellets.size()
	model.pellets.assign([{"id":9001, "position":player["position"] + Vector2(9.0, 0.0), "value":4.5, "palette":1, "source":"fixture"}])
	model.target_pellet_count = before_count
	var events: Array[Dictionary] = model.step(0.1)
	var state: Dictionary = model.snapshot()
	var ate: Dictionary = _find_event(events, "player_ate")
	var passed: bool = (
		not ate.is_empty()
		and float(state["mass"]) >= before_mass + 4.4
		and model.pellets.size() == before_count
		and int(ate.get("pellet_id", -1)) == 9001
	)
	_record("eat_grows_replenishes", passed, JSON.stringify(ate))


func _test_leaderboard_is_sorted_and_ranks_player() -> void:
	var model = _fresh_model(3, 20)
	model.snakes[0]["mass"] = 55.0
	model.snakes[1]["mass"] = 120.0
	model.snakes[2]["mass"] = 80.0
	model.snakes[3]["mass"] = 30.0
	var state: Dictionary = model.snapshot()
	var board: Array = state["leaderboard"]
	var passed: bool = (
		int(board[0]["id"]) == int(model.snakes[1]["id"])
		and float(board[0]["mass"]) >= float(board[1]["mass"])
		and float(board[1]["mass"]) >= float(board[2]["mass"])
		and int(state["rank"]) == 3
	)
	_record("leaderboard_sorted", passed, JSON.stringify(board))


func _test_body_collision_kills_and_drops_loot() -> void:
	var model = _fresh_model(1, 0)
	model.target_pellet_count = 0
	var player: Dictionary = model.snakes[0]
	player["position"] = Vector2.ZERO
	player["heading"] = 0.0
	player["invulnerable"] = 0.0
	player["segments"] = [Vector2.ZERO, Vector2(-12, 0), Vector2(-24, 0)]
	model.snakes[0] = player
	var bot: Dictionary = model.snakes[1]
	bot["position"] = Vector2(280, 280)
	bot["speed_scale"] = 0.0
	bot["invulnerable"] = 0.0
	bot["segments"] = [Vector2(280, 280), Vector2(28, -30), Vector2(28, -15), Vector2(28, 0), Vector2(28, 15), Vector2(28, 30)]
	model.snakes[1] = bot
	var events: Array[Dictionary] = model.step(0.18)
	var state: Dictionary = model.snapshot()
	var death: Dictionary = _find_event(events, "player_died")
	var passed: bool = (
		state.get("phase") == "lost"
		and death.get("reason") == "body"
		and model.pellets.size() >= 3
		and _has_event(events, "debris_dropped")
	)
	_record("body_collision_loot", passed, JSON.stringify(death))


func _test_own_body_and_tail_are_nonlethal() -> void:
	var survived_all := true
	var evidence: Array[Dictionary] = []
	for overlap_index in [5, 7]:
		var model = _fresh_model(0, 0)
		model.target_pellet_count = 0
		var head := Vector2.ZERO
		var player: Dictionary = model.snakes[0]
		var segments: Array[Vector2] = [
			head,
			Vector2(-80, 80),
			Vector2(-160, 80),
			Vector2(-240, 80),
			Vector2(-320, 80),
			Vector2(-400, 80),
			Vector2(-480, 80),
			Vector2(-560, 80),
		]
		segments[overlap_index] = head
		player["position"] = head
		player["previous_position"] = head
		player["segments"] = segments
		player["speed_scale"] = 0.0
		player["invulnerable"] = 0.0
		model.snakes[0] = player
		var events: Array[Dictionary] = model.step(1.0 / 60.0)
		var snapshot: Dictionary = model.snapshot()
		var survived: bool = (
			snapshot.get("status") == "playing"
			and bool(snapshot["player"]["alive"])
			and not _has_event(events, "player_died")
		)
		survived_all = survived_all and survived
		evidence.append({"segment":overlap_index, "survived":survived, "events":events})
	_record("own_body_and_tail_nonlethal", survived_all, JSON.stringify(evidence))


func _test_bots_scavenge_debris_and_leader_reorders() -> void:
	var model = _fresh_model(3, 0)
	model.target_pellet_count = 0
	model.snakes[0]["mass"] = 38.0
	var fallen: Dictionary = model.snakes[1]
	fallen["mass"] = 110.0
	fallen["position"] = Vector2(130.0, 0.0)
	var fallen_segments: Array[Vector2] = []
	for index in range(18):
		fallen_segments.append(Vector2(130.0 - float(index) * 14.0, 0.0))
	fallen["segments"] = fallen_segments
	model.snakes[1] = fallen
	var scavenger: Dictionary = model.snakes[2]
	scavenger["mass"] = 72.0
	scavenger["position"] = Vector2(330.0, 170.0)
	scavenger["previous_position"] = scavenger["position"]
	scavenger["heading"] = 0.0
	scavenger["desired_point"] = scavenger["position"] + Vector2.RIGHT * 300.0
	var scavenger_segments: Array[Vector2] = []
	for index in range(18):
		scavenger_segments.append(Vector2(scavenger["position"]) - Vector2.RIGHT * float(index) * 14.0)
	scavenger["segments"] = scavenger_segments
	scavenger["decision_at"] = 0.0
	model.snakes[2] = scavenger
	model.snakes[3]["mass"] = 52.0
	var leader_before: int = int(model.snapshot()["leaderboard"][0]["id"])
	model.kill_snake_for_test(1, "fixture")
	var after_death: Dictionary = model.snapshot()
	var heading_before: float = float(model.snakes[2]["heading"])
	model.step(0.34)
	var after_pursuit: Dictionary = model.snapshot()
	var heading_after: float = float(model.snakes[2]["heading"])
	var passed: bool = (
		leader_before == int(fallen["id"])
		and int(after_death["leaderboard"][0]["id"]) == int(scavenger["id"])
		and str(model.snakes[2].get("state", "")) == "scavenging"
		and absf(wrapf(heading_after - heading_before, -PI, PI)) > 0.20
		and after_pursuit.get("pellets", []).size() > 0
	)
	_record("debris_scavenging_leader_reorder", passed, JSON.stringify({
		"leader_before":leader_before,
		"leader_after":int(after_death["leaderboard"][0]["id"]),
		"state":str(model.snakes[2].get("state", "")),
		"heading_before":heading_before,
		"heading_after":heading_after
	}))


func _test_head_to_head_is_symmetric_and_mass_based() -> void:
	var equal_model = _fresh_model(1, 0)
	equal_model.target_pellet_count = 0
	for index in range(2):
		var snake: Dictionary = equal_model.snakes[index]
		var head := Vector2(-7.0, 0.0) if index == 0 else Vector2(7.0, 0.0)
		var heading := 0.0 if index == 0 else PI
		snake["position"] = head
		snake["previous_position"] = head
		snake["heading"] = heading
		snake["desired_point"] = head + Vector2.from_angle(heading) * 300.0
		snake["segments"] = [head, head - Vector2.from_angle(heading) * 14.0, head - Vector2.from_angle(heading) * 28.0]
		snake["mass"] = 48.0
		snake["invulnerable"] = 0.0
		snake["speed_scale"] = 0.0
		equal_model.snakes[index] = snake
	var equal_events: Array[Dictionary] = equal_model.step(1.0 / 60.0)
	var equal_state: Dictionary = equal_model.snapshot()

	var weighted_model = _fresh_model(1, 0)
	weighted_model.target_pellet_count = 0
	for index in range(2):
		var snake: Dictionary = weighted_model.snakes[index]
		var head := Vector2(-7.0, 0.0) if index == 0 else Vector2(7.0, 0.0)
		var heading := 0.0 if index == 0 else PI
		snake["position"] = head
		snake["previous_position"] = head
		snake["heading"] = heading
		snake["desired_point"] = head + Vector2.from_angle(heading) * 300.0
		snake["segments"] = [head, head - Vector2.from_angle(heading) * 14.0, head - Vector2.from_angle(heading) * 28.0]
		snake["mass"] = 72.0 if index == 0 else 32.0
		snake["invulnerable"] = 0.0
		snake["speed_scale"] = 0.0
		weighted_model.snakes[index] = snake
	var weighted_events: Array[Dictionary] = weighted_model.step(1.0 / 60.0)
	var weighted_state: Dictionary = weighted_model.snapshot()
	var passed: bool = (
		not bool(equal_state["snakes"][0]["alive"])
		and not bool(equal_state["snakes"][1]["alive"])
		and _has_event(equal_events, "player_died")
		and _has_event(equal_events, "bot_died")
		and bool(weighted_state["snakes"][0]["alive"])
		and not bool(weighted_state["snakes"][1]["alive"])
		and not _has_event(weighted_events, "player_died")
		and _has_event(weighted_events, "bot_died")
	)
	_record("head_collision_symmetric_mass_based", passed, JSON.stringify({"equal":equal_state["snakes"], "weighted":weighted_state["snakes"]}))


func _test_head_collision_chain_is_order_independent() -> void:
	var model = _fresh_model(2, 0)
	model.target_pellet_count = 0
	var positions := [Vector2(-20.0, 0.0), Vector2.ZERO, Vector2(20.0, 0.0)]
	var masses := [100.0, 50.0, 20.0]
	for index in range(3):
		var snake: Dictionary = model.snakes[index]
		var head: Vector2 = positions[index]
		snake["position"] = head
		snake["previous_position"] = head
		snake["heading"] = -PI * 0.5
		snake["desired_point"] = head + Vector2.UP * 300.0
		snake["segments"] = [head, head + Vector2.DOWN * 18.0, head + Vector2.DOWN * 36.0]
		snake["mass"] = masses[index]
		snake["invulnerable"] = 0.0
		snake["speed_scale"] = 0.0
		model.snakes[index] = snake
	model.step(1.0 / 60.0)
	var state: Dictionary = model.snapshot()
	var alive_masses: Array[float] = []
	for snake in state["snakes"]:
		if bool(snake["alive"]):
			alive_masses.append(float(snake["mass"]))
	_record("head_collision_chain_atomic", alive_masses.size() == 1 and alive_masses[0] >= 100.0, JSON.stringify(alive_masses))


func _test_simultaneous_body_collisions_are_atomic() -> void:
	var model = _fresh_model(1, 0)
	model.target_pellet_count = 0
	var player: Dictionary = model.snakes[0]
	player["position"] = Vector2.ZERO
	player["previous_position"] = Vector2.ZERO
	player["segments"] = [Vector2.ZERO, Vector2(-30, 0), Vector2(100, 0)]
	player["mass"] = 48.0
	player["invulnerable"] = 0.0
	player["speed_scale"] = 0.0
	model.snakes[0] = player
	var bot: Dictionary = model.snakes[1]
	bot["position"] = Vector2(100, 0)
	bot["previous_position"] = Vector2(100, 0)
	bot["segments"] = [Vector2(100, 0), Vector2(130, 0), Vector2.ZERO]
	bot["mass"] = 48.0
	bot["invulnerable"] = 0.0
	bot["speed_scale"] = 0.0
	model.snakes[1] = bot
	var events: Array[Dictionary] = model.step(1.0 / 60.0)
	var state: Dictionary = model.snapshot()
	var passed := not bool(state["snakes"][0]["alive"]) and not bool(state["snakes"][1]["alive"]) and _has_event(events, "player_died") and _has_event(events, "bot_died")
	_record("simultaneous_body_collision_atomic", passed, JSON.stringify(state["snakes"]))


func _test_food_does_not_bias_same_tick_head_collision() -> void:
	var model = _fresh_model(1, 0)
	model.target_pellet_count = 0
	for index in range(2):
		var snake: Dictionary = model.snakes[index]
		var head := Vector2(-7.0, 0.0) if index == 0 else Vector2(7.0, 0.0)
		var heading := 0.0 if index == 0 else PI
		snake["position"] = head
		snake["previous_position"] = head
		snake["heading"] = heading
		snake["desired_point"] = head + Vector2.from_angle(heading) * 300.0
		snake["segments"] = [head, head - Vector2.from_angle(heading) * 18.0, head - Vector2.from_angle(heading) * 36.0]
		snake["mass"] = 30.0
		snake["invulnerable"] = 0.0
		snake["speed_scale"] = 0.0
		model.snakes[index] = snake
	model.pellets.assign([{"id":8801, "position":Vector2(-7.0, 0.0), "value":3.0, "palette":1, "source":"fixture", "born_at":0.0}])
	model.step(1.0 / 60.0)
	var state: Dictionary = model.snapshot()
	var passed := not bool(state["snakes"][0]["alive"]) and not bool(state["snakes"][1]["alive"]) and is_equal_approx(float(state["snakes"][0]["mass"]), 30.0)
	_record("food_does_not_bias_head_collision", passed, JSON.stringify(state["snakes"]))


func _test_pellet_population_is_bounded() -> void:
	var model = _fresh_model(0, 0)
	model.target_pellet_count = 0
	for index in range(420):
		model._spawn_pellet_at(Vector2(float(index % 21) * 5.0, float(index / 21) * 5.0), 0.7, index % 5, "boost")
	model.step(1.0 / 60.0)
	var capped_count: int = model.pellets.size()
	model._spawn_pellet_at(Vector2(700, 0), 0.7, 0, "boost")
	var immediate_count: int = model.pellets.size()
	model.pellets.clear()
	model.target_pellet_count = int(model.maximum_pellet_count) + 1
	model._refill_pellets()
	var clamped_refill_count: int = model.pellets.size()
	model.pellets.assign([{"id":9901, "position":Vector2.ZERO, "value":0.7, "palette":0, "source":"boost", "born_at":-20.0}])
	model.target_pellet_count = 0
	var mass_before_expiry := float(model.snakes[model.player_index]["mass"])
	model.step(1.0 / 60.0)
	var mass_after_expiry := float(model.snakes[model.player_index]["mass"])
	var passed: bool = capped_count <= int(model.maximum_pellet_count) and immediate_count <= int(model.maximum_pellet_count) and clamped_refill_count == int(model.maximum_pellet_count) and model.pellets.is_empty() and is_equal_approx(mass_before_expiry, mass_after_expiry)
	_record("pellet_population_bounded", passed, "count=%d immediate=%d refill=%d cap=%d expired_remaining=%d mass=%.1f→%.1f" % [capped_count, immediate_count, clamped_refill_count, int(model.maximum_pellet_count), model.pellets.size(), mass_before_expiry, mass_after_expiry])


func _test_boundary_collision_kills_player() -> void:
	var model = _fresh_model(0, 0)
	var player: Dictionary = model.snakes[0]
	player["position"] = Vector2(model.arena_radius - 2.0, 0.0)
	player["heading"] = 0.0
	player["invulnerable"] = 0.0
	player["segments"] = [player["position"], player["position"] - Vector2(12, 0)]
	model.snakes[0] = player
	var events: Array[Dictionary] = model.step(0.1)
	var state: Dictionary = model.snapshot()
	var death: Dictionary = _find_event(events, "player_died")
	var passed: bool = state.get("phase") == "lost" and death.get("reason") == "boundary"
	_record("boundary_collision", passed, JSON.stringify(death))


func _test_dead_bot_respawns() -> void:
	var model = _fresh_model(1, 10)
	model.kill_snake_for_test(1, "fixture")
	var death_state: Dictionary = model.snapshot()
	for _tick in range(220):
		model.step(1.0 / 60.0)
	var after: Dictionary = model.snapshot()
	var passed: bool = not bool(death_state["snakes"][1]["alive"]) and bool(after["snakes"][1]["alive"])
	_record("bot_respawns", passed, JSON.stringify(after["snakes"][1]))


func _test_snapshot_is_json_safe_and_reset_recovers() -> void:
	var model = _fresh_model(2, 16)
	model.kill_snake_for_test(0, "fixture")
	model.reset(TEST_SEED, 2, 16)
	var state: Dictionary = model.snapshot()
	var encoded: String = JSON.stringify(state)
	var decoded: Variant = JSON.parse_string(encoded)
	var passed: bool = (
		decoded is Dictionary
		and decoded.get("phase") == "running"
		and decoded.get("snakes", []).size() == 3
		and bool(decoded["player"]["alive"])
	)
	_record("json_safe_reset_recovers", passed, encoded)
