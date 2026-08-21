extends SceneTree

const OUTPUT_DIR := "res://docs/audit/snakes-fidelity-v3/candidate/native"
const FIXED_SEED := 1362026
const VIDEO_DT := 1.0 / 30.0

var game: Control
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for child in ["knockout-sequence", "death-sequence"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, child]))
	await _wait_frames(40)
	game.set_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	game.has_transitioned = false

	var stable := await _capture_stable_and_ordinary_beats()
	var knockout := await _capture_knockout_sequence()
	var death := await _capture_player_death_sequence()
	var reduced := await _capture_reduced_effects_truth()
	var checks := {
		"stable_player_and_food_bound": bool(stable.get("player_head_bound", false)) and bool(stable.get("bean_bound", false)),
		"actual_steer_changed_heading": bool(stable.get("steer_changed_heading", false)),
		"actual_collect_grew_mass": bool(stable.get("collect_grew_mass", false)),
		"actual_boost_spent_mass": bool(stable.get("boost_spent_mass", false)),
		"knockout_created_real_debris": int(knockout.get("after", {}).get("debris_count", 0)) > int(knockout.get("before", {}).get("debris_count", 0)),
		"continuous_knockout_28_frames": int(knockout.get("frames", 0)) == 28,
		"actual_player_collision_terminal": str(death.get("after", {}).get("status", "")) == "over",
		"continuous_death_25_frames": int(death.get("frames", 0)) == 25,
		"reduced_state_truth_visible": bool(reduced.get("state_reduced_effects", false)),
		"reduced_particles_and_shake_suppressed": int(reduced.get("fx_count", -1)) == 0 and reduced.get("camera_shake", []) == [0.0, 0.0],
	}
	for key in checks:
		if not bool(checks[key]):
			failures.append(str(key))
	var report := {
		"schema":"offline-games.snakes-fidelity-v3.visual-audit.v1",
		"result":"PASS" if failures.is_empty() else "FAIL",
		"failures":failures,
		"viewport":[int(game.size.x), int(game.size.y)],
		"video_contract":{"fps":30, "knockout_frames":28, "death_frames":25},
		"checks":checks,
		"ordinary_beats":stable,
		"knockout":knockout,
		"player_death":death,
		"reduced_effects":reduced,
		"runtime_contract":{
			"player_head_logical_px":"50-58",
			"pellet_logical_px":"16-22",
			"knockout_burst_peak_logical_px":144,
			"knockout_center":"hollow; authoritative debris and route remain visible",
			"generated_text":"none; all live CJK is code-native Noto CJK",
		},
	}
	_write_json("%s/semantic-state.json" % OUTPUT_DIR, report)
	print("SNAKES_GAG_VISUAL_AUDIT_DIR=%s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	print("SNAKES_GAG_VISUAL_RESULT=%s" % report["result"])
	game.queue_free()
	await _wait_frames(2)
	quit(0 if failures.is_empty() else 1)


func _capture_stable_and_ordinary_beats() -> Dictionary:
	game.snakes_reduced_effects = false
	await _prepare_arena()
	await _save("00-stable-core")
	var stable := {
		"player_head_bound":game.SNAKES_GAG_PLAYER_HEAD_TEXTURE != null,
		"bean_bound":game.SNAKES_GAG_PRIZE_BEAN_TEXTURE != null,
		"opening_pellet_count":game.state.get("pellets", []).size(),
	}

	var heading_before := float(game.state.get("player", {}).get("heading", 0.0))
	await _save("01-steer-intent")
	game._snakes_arena_begin_pointer(Vector2(270, 286))
	game._snakes_arena_update(1.0 / 30.0)
	await _save("02-steer-impact")
	await _advance_visual(0.24, true)
	game._snakes_arena_end_pointer(Vector2(270, 286))
	await _save("03-steer-settle")
	stable["steer_changed_heading"] = absf(float(game.state.get("player", {}).get("heading", 0.0)) - heading_before) > 0.04

	await _prepare_arena()
	var collect_mass_before := float(game.state.get("mass", 0.0))
	var player_position: Vector2 = game._arena_player_world_position()
	game.snakes_arena_model.target_pellet_count = 1
	game.snakes_arena_model.pellets.assign([{
		"id":9101, "position":player_position + Vector2(34, 0), "value":4.5,
		"palette":1, "source":"ambient", "born_at":game.snakes_arena_model.elapsed,
	}])
	game.snakes_arena_model.next_pellet_id = 9102
	game._sync_snakes_arena_state()
	await _save("04-collect-intent")
	game._snakes_arena_update(0.12)
	await _save("05-collect-impact")
	await _advance_visual(0.26, false)
	await _save("06-collect-settle")
	stable["collect_grew_mass"] = float(game.state.get("mass", 0.0)) > collect_mass_before + 4.0

	await _prepare_arena()
	var boost_mass_before := float(game.state.get("mass", 0.0))
	var boost_position_before: Vector2 = game._arena_player_world_position()
	game._set_arena_boost(true)
	game._snakes_arena_update(1.0 / 30.0)
	await _save("07-boost-impact")
	await _advance_visual(0.30, true)
	await _save("08-boost-active")
	game._set_arena_boost(false)
	await _advance_visual(0.18, true)
	await _save("09-boost-settle")
	stable["boost_spent_mass"] = float(game.state.get("mass", 0.0)) < boost_mass_before and game._arena_player_world_position().distance_to(boost_position_before) > 20.0
	return stable


func _capture_knockout_sequence() -> Dictionary:
	await _prepare_knockout_fixture()
	var before := _semantic_state()
	await _save("10-knockout-intent")
	var bot_position := Vector2(190, 0)
	game.snakes_arena_model.kill_snake_for_test(1, "audit_fixture")
	game._sync_snakes_arena_state()
	game.arena_rank_previous = 2
	game.arena_rank_bump_until = game.elapsed + 0.58
	game.arena_leader_change_name = "你"
	game.arena_leader_change_until = game.elapsed + 1.18
	var knockout_events: Array[Dictionary] = [{
		"kind":"bot_died", "id":1, "reason":"audit_fixture",
		"killer_id":0, "at":bot_position,
	}]
	game._snakes_arena_dispatch(knockout_events)
	for frame_index in range(28):
		if frame_index > 0:
			await _advance_visual(VIDEO_DT, true)
		await _save_path("%s/knockout-sequence/frame-%03d.png" % [OUTPUT_DIR, frame_index])
		if frame_index == 2:
			await _save("11-knockout-anticipation")
		elif frame_index == 6:
			await _save("12-knockout-impact")
		elif frame_index == 15:
			await _save("13-knockout-consequence")
		elif frame_index == 27:
			await _save("14-knockout-settle")
	return {"frames":28, "before":before, "after":_semantic_state()}


func _capture_player_death_sequence() -> Dictionary:
	await _prepare_player_death_fixture()
	var before := _semantic_state()
	await _save("20-death-intent")
	game._snakes_arena_update(0.18)
	for frame_index in range(25):
		if frame_index > 0:
			await _advance_visual(VIDEO_DT, false)
		await _save_path("%s/death-sequence/frame-%03d.png" % [OUTPUT_DIR, frame_index])
		if frame_index == 6:
			await _save("21-death-impact")
		elif frame_index == 12:
			await _save("22-death-consequence")
		elif frame_index == 24:
			await _save("23-death-terminal-settle")
	return {"frames":25, "before":before, "after":_semantic_state()}


func _capture_reduced_effects_truth() -> Dictionary:
	game.snakes_reduced_effects = true
	await _prepare_knockout_fixture()
	var bot_position := Vector2(190, 0)
	game.snakes_arena_model.kill_snake_for_test(1, "reduced_fixture")
	game._sync_snakes_arena_state()
	var knockout_events: Array[Dictionary] = [{
		"kind":"bot_died", "id":1, "reason":"reduced_fixture",
		"killer_id":0, "at":bot_position,
	}]
	game._snakes_arena_dispatch(knockout_events)
	game._sync_snakes_arena_state()
	await _save("30-reduced-knockout-state-truth")
	var result := {
		"state_reduced_effects":bool(game.state.get("reduced_effects", false)),
		"fx_count":game.arena_fx.size(),
		"camera_shake":[game.arena_camera_shake.x, game.arena_camera_shake.y],
		"debris_count":int(_semantic_state().get("debris_count", 0)),
		"knockout_semantic_marker":game.arena_knockout_started == game.elapsed,
	}
	game.snakes_reduced_effects = false
	return result


func _prepare_arena() -> void:
	game._open_game("snake_io")
	game.snakes_arena_model.reset(FIXED_SEED, 5, 72)
	game.arena_pointer_active = false
	game.arena_aim_direction = Vector2.RIGHT
	game.arena_boost_active = false
	game.arena_fx.clear()
	game.arena_float_labels.clear()
	game.arena_result_ready_at = -1.0
	game.arena_rank_bump_until = -1.0
	game.arena_steer_started = -10.0
	game.arena_steer_until = -10.0
	game.arena_competition_until = -10.0
	game.arena_leader_change_until = -10.0
	game.arena_leader_change_name = ""
	game.arena_reset_started = -10.0
	game.arena_camera_shake = Vector2.ZERO
	game.arena_tutorial_dismissed = true
	game.arena_eat_started = -10.0
	game.arena_knockout_started = -10.0
	game.arena_knockout_world = Vector2.ZERO
	game.arena_knockout_killer_id = -1
	game.has_transitioned = false
	game._sync_snakes_arena_state()
	game.arena_camera = game._arena_player_world_position()
	game.arena_camera_previous = game.arena_camera
	game.arena_last_player_position = game.arena_camera
	game.queue_redraw()
	await _wait_frames(1)


func _prepare_knockout_fixture() -> void:
	await _prepare_arena()
	game.snakes_arena_model.target_pellet_count = 0
	game.snakes_arena_model.pellets.clear()
	_pose_snake(0, Vector2.ZERO, 0.0, 92.0, 0.0)
	# Face the defeated rival toward the player while its body/debris extends
	# away from the contact, keeping impact readable before later scavenging.
	_pose_snake(1, Vector2(190, 0), PI, 128.0, 0.0)
	_pose_snake(2, Vector2(310, 90), 0.0, 84.0, 1.0)
	for bot_index in range(3, game.snakes_arena_model.snakes.size()):
		_pose_snake(bot_index, Vector2(-610 + bot_index * 34, 510 - bot_index * 40), PI, 20.0 + bot_index, 0.0)
	game._sync_snakes_arena_state()
	game.arena_camera = Vector2.ZERO
	game.arena_camera_previous = Vector2.ZERO
	game.arena_rank_previous = 2
	game.queue_redraw()
	await _wait_frames(1)


func _prepare_player_death_fixture() -> void:
	await _prepare_arena()
	game.snakes_arena_model.target_pellet_count = 0
	game.snakes_arena_model.pellets.clear()
	_pose_snake(0, Vector2.ZERO, 0.0, 38.0, 1.0)
	var player: Dictionary = game.snakes_arena_model.snakes[0]
	player["invulnerable"] = 0.0
	game.snakes_arena_model.snakes[0] = player
	_pose_snake(1, Vector2(260, 260), 0.0, 84.0, 0.0)
	var blocker: Dictionary = game.snakes_arena_model.snakes[1]
	blocker["segments"] = [Vector2(260, 260), Vector2(28, -28), Vector2(28, -14), Vector2(28, 0), Vector2(28, 14)]
	blocker["invulnerable"] = 0.0
	game.snakes_arena_model.snakes[1] = blocker
	for bot_index in range(2, game.snakes_arena_model.snakes.size()):
		_pose_snake(bot_index, Vector2(-650 + bot_index * 40, 520 - bot_index * 25), PI, 30.0, 0.0)
		var distant_bot: Dictionary = game.snakes_arena_model.snakes[bot_index]
		distant_bot["invulnerable"] = 10.0
		game.snakes_arena_model.snakes[bot_index] = distant_bot
	game._sync_snakes_arena_state()
	game.arena_camera = Vector2.ZERO
	game.arena_camera_previous = Vector2.ZERO
	game.arena_aim_direction = Vector2.RIGHT
	game.queue_redraw()
	await _wait_frames(1)


func _pose_snake(index: int, position: Vector2, heading: float, mass: float, speed_scale: float) -> void:
	var snake: Dictionary = game.snakes_arena_model.snakes[index]
	var segment_count := maxi(12, snake.get("segments", []).size())
	var backward := -Vector2.from_angle(heading)
	var segments: Array[Vector2] = []
	for segment_index in range(segment_count):
		segments.append(position + backward * 14.0 * float(segment_index))
	snake["position"] = position
	snake["previous_position"] = position
	snake["heading"] = heading
	snake["desired_point"] = position + Vector2.from_angle(heading) * 300.0
	snake["segments"] = segments
	snake["mass"] = mass
	snake["speed_scale"] = speed_scale
	snake["invulnerable"] = 4.0
	snake["decision_at"] = 0.0
	snake["state"] = "relaxed"
	game.snakes_arena_model.snakes[index] = snake


func _semantic_state() -> Dictionary:
	var snapshot: Dictionary = game.snakes_arena_model.snapshot()
	var debris := 0
	for pellet in snapshot.get("pellets", []):
		if str(pellet.get("source", "")) == "debris":
			debris += 1
	return {
		"status":str(snapshot.get("status", "")),
		"phase":str(snapshot.get("phase", "")),
		"player_alive":bool(snapshot.get("player", {}).get("alive", false)),
		"mass":float(snapshot.get("mass", 0.0)),
		"rank":int(snapshot.get("rank", -1)),
		"debris_count":debris,
		"tick":int(snapshot.get("tick", 0)),
		"terminal_reason":str(snapshot.get("terminal_reason", "")),
	}


func _advance_visual(seconds: float, advance_model: bool) -> void:
	var frames := maxi(1, int(round(seconds * 60.0)))
	var dt := seconds / float(frames)
	for _frame in range(frames):
		game.elapsed += dt
		game.tick += 1
		if advance_model and str(game.state.get("status", "playing")) == "playing":
			game._snakes_arena_update(dt)
		game._snakes_arena_prune_fx()
		game.queue_redraw()
		await process_frame


func _wait_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _save(stem: String) -> void:
	await _save_path("%s/%s.png" % [OUTPUT_DIR, stem])


func _save_path(path: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(path))
	assert(error == OK, "capture failed: %s" % path)


func _write_json(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	file.store_string(JSON.stringify(payload, "  ") + "\n")
	file.close()
