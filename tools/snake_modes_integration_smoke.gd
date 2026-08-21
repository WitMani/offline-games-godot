extends SceneTree

const GB_ID := "snake_classic"
const ARENA_ID := "snake_io"
const EXPECTED_CASES := 7

var game: Control
var failures: Array[String] = []
var cases_run := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate() as Control
	root.add_child(game)
	await process_frame
	game.set_process(false)
	_disable_shell_audio()
	await process_frame

	_test_gb_shell_exposes_authoritative_contract()
	_test_gb_shell_ticks_at_medium_speed()
	_test_gb_food_materializes_exactly_two_growth()
	_test_gb_field_record_is_nonterminal_and_restart_recovers()
	_test_gb_shell_recovery_round_trip()
	_test_arena_shell_adapts_continuous_state()
	_test_arena_player_death_delays_result_and_regenerates()

	_dispose_game()
	await process_frame
	await process_frame
	_finish()


func _finish() -> void:
	if cases_run != EXPECTED_CASES:
		failures.append("case_count_%d_of_%d" % [cases_run, EXPECTED_CASES])
	print("SNAKE_MODES_INTEGRATION_CASES=%d" % cases_run)
	print("SNAKE_MODES_INTEGRATION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _record(case_name: String, passed: bool, evidence: String = "") -> void:
	cases_run += 1
	if passed:
		return
	failures.append(case_name + ("=" + evidence if not evidence.is_empty() else ""))


func _dispose_game() -> void:
	# Explicitly detach any still-playing samples before freeing the shell. The
	# dummy headless audio driver otherwise retains its playback for one tick.
	for player in game.sfx_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	game.free()


func _disable_shell_audio() -> void:
	# Audio behavior has its own smoke coverage. Keeping voices detached here
	# prevents asynchronous playback from outliving this short-lived SceneTree.
	for player in game.sfx_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
			player.free()
	game.sfx_players.clear()


func _open_mode(id: String) -> void:
	game._open_game(id)


func _test_gb_shell_exposes_authoritative_contract() -> void:
	_open_mode(GB_ID)
	var snapshot: Dictionary = game.state.duplicate(true)
	var passed: bool = (
		snapshot.get("game_id") == GB_ID
		and snapshot.get("status") == "playing"
		and bool(snapshot.get("started", false))
		and int(snapshot.get("width", 0)) == 15
		and int(snapshot.get("height", 0)) == 23
		and snapshot.get("segments", []).size() == 4
		and snapshot.get("foods", []).size() == 2
		and snapshot.get("foods", [])[0] != snapshot.get("foods", [])[1]
		and snapshot.get("foods", [])[0] == snapshot.get("food", [])
		and bool(snapshot.get("endless", false))
		and not snapshot.has("target_length")
		and is_equal_approx(float(game.SNAKE_GB_STEP_INTERVAL), 1.0 / 7.5)
	)
	_record("gb_authoritative_shell_contract", passed, JSON.stringify(snapshot))


func _test_gb_shell_ticks_at_medium_speed() -> void:
	_open_mode(GB_ID)
	var before: Dictionary = game.state.duplicate(true)
	game._snake_gb_update(float(game.SNAKE_GB_STEP_INTERVAL) - 0.001)
	var held: Dictionary = game.state.duplicate(true)
	game._snake_gb_update(0.0011)
	var advanced: Dictionary = game.state.duplicate(true)
	var passed: bool = (
		held.get("segments", []) == before.get("segments", [])
		and int(held.get("moves", -1)) == 0
		and advanced.get("segments", [])[0] == [8, 11]
		and int(advanced.get("moves", -1)) == 1
	)
	_record("gb_medium_tick_rate", passed, JSON.stringify({"before":before, "held":held, "advanced":advanced}))


func _test_gb_food_materializes_exactly_two_growth() -> void:
	_open_mode(GB_ID)
	var model = game.snake_gb_model
	var next: Vector2i = model.segments[0] + model.direction
	model.foods.assign([next, Vector2i(2, 2)])
	model.food = next
	game._sync_snake_gb_state()

	game._snake_gb_step()
	var after_eat: Dictionary = game.state.duplicate(true)
	var eat_feedback := ""
	if not game.snake_float_labels.is_empty():
		eat_feedback = str(game.snake_float_labels.back().get("text", ""))
	game._snake_gb_step()
	var after_growth_one: Dictionary = game.state.duplicate(true)
	game._snake_gb_step()
	var after_growth_two: Dictionary = game.state.duplicate(true)
	var passed: bool = (
		after_eat.get("status") == "playing"
		and after_eat.get("segments", []).size() == 4
		and int(after_eat.get("score", -1)) == 4
		and int(after_eat.get("pending_growth", -1)) == 2
		and after_eat.get("foods", []).size() == 2
		and eat_feedback == "+2"
		and after_growth_one.get("segments", []).size() == 5
		and int(after_growth_one.get("score", -1)) == 5
		and int(after_growth_one.get("pending_growth", -1)) == 1
		and after_growth_two.get("segments", []).size() == 6
		and int(after_growth_two.get("score", -1)) == 6
		and int(after_growth_two.get("pending_growth", -1)) == 0
	)
	_record("gb_two_growth_materialize", passed, JSON.stringify({"after_eat":after_eat, "after_growth_one":after_growth_one, "after_growth_two":after_growth_two, "feedback":eat_feedback}))


func _test_gb_field_record_is_nonterminal_and_restart_recovers() -> void:
	_open_mode(GB_ID)
	var model = game.snake_gb_model
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
	model.foods.assign([Vector2i(12, 20), Vector2i(13, 21)])
	model.food = model.foods[0]
	model.score = 119
	model.moves = 115
	model.step_index = 115
	model.pending_growth = 1
	game._sync_snake_gb_state()
	game._snake_gb_step()
	var record: Dictionary = game.state.duplicate(true)
	var record_fx_kind: String = str(game.snake_fx_kind)
	var record_object_fx: Dictionary = game.snake_gb_object_fx.duplicate(true)
	var record_result_ready: float = float(game.snake_result_ready_at)
	game._snake_gb_step()
	var continued: Dictionary = game.state.duplicate(true)

	var restart_button := _find_button_with_text("重开")
	if restart_button:
		restart_button.pressed.emit()
	var restarted: Dictionary = game.state.duplicate(true)
	var passed: bool = (
		record.get("phase") == "running"
		and record.get("status") == "playing"
		and int(record.get("score", -1)) == 120
		and record_fx_kind == "complete"
		and str(record_object_fx.get("kind", "")) == "complete"
		and bool(record_object_fx.get("nonterminal", false))
		and record_result_ready < 0.0
		and continued.get("status") == "playing"
		and int(continued.get("moves", -1)) == 117
		and restart_button != null
		and restarted.get("status") == "playing"
		and restarted.get("segments", []).size() == 4
		and restarted.get("foods", []).size() == 2
		and not restarted.has("target_length")
		and float(game.snake_result_ready_at) < 0.0
		and game.snake_fx_kind == ""
	)
	_record("gb_record_nonterminal_restart", passed, JSON.stringify({"record":record, "record_fx_kind":record_fx_kind, "record_object_fx":record_object_fx, "continued":continued, "restarted":restarted}))


func _test_gb_shell_recovery_round_trip() -> void:
	_open_mode(GB_ID)
	game._set_snake_direction(Vector2i.UP)
	game._snake_gb_step()
	var saved: Dictionary = game.state.duplicate(true)
	game._reset_current()
	var reset_state: Dictionary = game.state.duplicate(true)
	var accepted: bool = game._restore_snake_gb_snapshot(saved)
	var restored: Dictionary = game.state.duplicate(true)
	var passed: bool = (
		accepted
		and restored == saved
		and reset_state != saved
		and restored.get("direction", []) == [0, -1]
		and int(restored.get("moves", -1)) == 1
		and restored.get("foods", []).size() == 2
	)
	_record("gb_shell_recovery_round_trip", passed, JSON.stringify({"saved":saved, "reset":reset_state, "restored":restored}))


func _test_arena_shell_adapts_continuous_state() -> void:
	_open_mode(ARENA_ID)
	var before: Dictionary = game.state.duplicate(true)
	var before_position := _packed_vector(before.get("player", {}).get("position", []))
	game._snakes_arena_update(1.0 / 60.0)
	var after: Dictionary = game.state.duplicate(true)
	var after_position := _packed_vector(after.get("player", {}).get("position", []))
	var passed: bool = (
		before.get("game_id") == ARENA_ID
		and bool(before.get("started", false))
		and before.get("snakes", []).size() == 6
		and before.get("pellets", []).size() == 96
		and int(before.get("score", -1)) == roundi(float(before.get("mass", -2.0)))
		and int(before.get("moves", -1)) == int(before.get("tick", -2))
		and after_position.distance_to(before_position) > 1.0
		and int(after.get("moves", -1)) == int(after.get("tick", -2))
		and int(after.get("score", -1)) == roundi(float(after.get("mass", -2.0)))
	)
	_record("arena_shell_state_adapter", passed, JSON.stringify({"before":before, "after":after}))


func _test_arena_player_death_delays_result_and_regenerates() -> void:
	_open_mode(ARENA_ID)
	game._snakes_arena_begin_pointer(Vector2(270, 393))
	game._set_arena_boost(true)
	var model = game.snakes_arena_model
	var player_index: int = int(model.player_index)
	var player: Dictionary = model.snakes[player_index].duplicate(true)
	var original_position: Vector2 = player.get("position", Vector2.ZERO)
	var boundary_position := Vector2(float(model.arena_radius) - 2.0, 0.0)
	var offset := boundary_position - original_position
	var shifted_segments: Array[Vector2] = []
	for segment in player.get("segments", []):
		shifted_segments.append(Vector2(segment) + offset)
	player["position"] = boundary_position
	player["previous_position"] = boundary_position
	player["heading"] = 0.0
	player["desired_point"] = boundary_position + Vector2.RIGHT * 400.0
	player["segments"] = shifted_segments
	player["invulnerable"] = 0.0
	model.snakes[player_index] = player
	model.set_player_aim(boundary_position + Vector2.RIGHT * 400.0)
	game._sync_snakes_arena_state()
	var trigger_elapsed: float = game.elapsed
	game._snakes_arena_update(0.10)
	var dead: Dictionary = game.state.duplicate(true)
	var delay: float = float(game.arena_result_ready_at) - trigger_elapsed
	var has_death_fx := false
	for fx in game.arena_fx:
		if str(fx.get("kind", "")) == "death":
			has_death_fx = true
			break
	var pointer_cleared_on_death: bool = not bool(game.arena_pointer_active)
	var boost_cleared_on_death: bool = not bool(game.arena_boost_active)

	var restart_button := _find_button_with_text("再来")
	if restart_button:
		restart_button.pressed.emit()
	var regenerated: Dictionary = game.state.duplicate(true)
	var regenerated_position := _packed_vector(regenerated.get("player", {}).get("position", []))
	var passed: bool = (
		dead.get("phase") == "lost"
		and dead.get("status") == "over"
		and dead.get("terminal_reason") == "boundary"
		and not bool(dead.get("player", {}).get("alive", true))
		and pointer_cleared_on_death
		and boost_cleared_on_death
		and is_equal_approx(delay, 0.72)
		and has_death_fx
		and restart_button != null
		and regenerated.get("status") == "playing"
		and bool(regenerated.get("player", {}).get("alive", false))
		and regenerated_position == Vector2.ZERO
		and is_equal_approx(float(regenerated.get("mass", 0.0)), 38.0)
		and int(regenerated.get("score", -1)) == 38
		and int(regenerated.get("moves", -1)) == 0
		and float(game.arena_result_ready_at) < 0.0
		and not bool(game.arena_pointer_active)
		and not bool(game.arena_boost_active)
	)
	_record("arena_death_delay_regenerate", passed, JSON.stringify({"dead":dead, "pointer_cleared_on_death":pointer_cleared_on_death, "boost_cleared_on_death":boost_cleared_on_death, "delay":delay, "regenerated":regenerated}))


func _find_button_with_text(expected: String) -> Button:
	for candidate in game.buttons:
		if candidate is Button and candidate.text == expected:
			return candidate as Button
	return null


func _packed_vector(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
