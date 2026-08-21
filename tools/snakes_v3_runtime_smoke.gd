extends SceneTree

const ARENA_ID := "snake_io"
const EXPECTED_CASES := 4

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
	_test_shell_exposes_versioned_model_state()
	_test_shell_restore_binds_state_and_neutralizes_held_boost()
	_test_shell_rejects_corrupt_restore_atomically()
	_test_explicit_shell_restart_clears_recovered_run()
	_dispose_game()
	await process_frame
	await process_frame
	_finish()


func _finish() -> void:
	if cases_run != EXPECTED_CASES:
		failures.append("case_count_%d_of_%d" % [cases_run, EXPECTED_CASES])
	print("SNAKES_V3_RUNTIME_CASES=%d" % cases_run)
	print("SNAKES_V3_RUNTIME_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _record(name: String, passed: bool, evidence: String = "") -> void:
	cases_run += 1
	if not passed:
		failures.append(name + ("=" + evidence if not evidence.is_empty() else ""))


func _disable_shell_audio() -> void:
	for player in game.sfx_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
			player.free()
	game.sfx_players.clear()


func _dispose_game() -> void:
	for player in game.sfx_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	game.free()


func _test_shell_exposes_versioned_model_state() -> void:
	game._open_game(ARENA_ID)
	var saved: Dictionary = game.state.duplicate(true)
	var passed: bool = (
		str(saved.get("game_id", "")) == ARENA_ID
		and str(saved.get("schema", "")) == "snakes-arena-state/v1"
		and str(saved.get("status", "")) == "playing"
		and bool(saved.get("started", false))
		and not bool(saved.get("recovered", true))
	)
	_record("shell_versioned_state", passed, JSON.stringify(saved))


func _test_shell_restore_binds_state_and_neutralizes_held_boost() -> void:
	game.snakes_arena_model.set_player_aim(Vector2(-300.0, 260.0))
	game.snakes_arena_model.step(0.24)
	var saved: Dictionary = game.snakes_arena_model.snapshot()
	saved["snakes"][0]["mass"] = 91.25
	saved["snakes"][0]["boost_requested"] = true
	saved["snakes"][0]["boosting"] = true
	saved["player_boost_requested"] = true
	var accepted: bool = game._restore_snakes_snapshot(saved)
	var passed: bool = (
		accepted
		and bool(game.state.get("recovered", false))
		and is_equal_approx(float(game.state.get("mass", 0.0)), 91.25)
		and not bool(game.state["player"].get("boosting", true))
		and not bool(game.snakes_arena_model.player_boost_requested)
		and not bool(game.arena_boost_active)
	)
	_record("shell_restore_binding", passed, JSON.stringify(game.state["player"]))


func _test_shell_rejects_corrupt_restore_atomically() -> void:
	var pristine := JSON.stringify(game.state)
	var corrupt: Dictionary = game.snakes_arena_model.snapshot()
	corrupt["snakes"][0]["position"] = [999999.0, 0.0]
	var rejected: bool = not bool(game._restore_snakes_snapshot(corrupt))
	_record("shell_corrupt_restore_atomic", rejected and JSON.stringify(game.state) == pristine)


func _test_explicit_shell_restart_clears_recovered_run() -> void:
	game._reset_current()
	var saved: Dictionary = game.state.duplicate(true)
	var passed: bool = (
		str(saved.get("status", "")) == "playing"
		and int(saved.get("tick", -1)) == 0
		and is_equal_approx(float(saved.get("mass", 0.0)), 38.0)
		and not bool(saved.get("recovered", true))
		and not bool(game.arena_restart_requested)
	)
	_record("shell_explicit_restart", passed, JSON.stringify(saved["player"]))
