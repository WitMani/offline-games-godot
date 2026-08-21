extends SceneTree

const OUTPUT := "res://docs/audit/snakes-fidelity-v3/candidate/native/performance.json"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._open_game("snake_io")
	game.has_transitioned = false
	game.arena_reset_started = -10.0
	game.arena_tutorial_dismissed = true
	game.set_process(false)
	for _warmup in range(60):
		game.elapsed += 1.0 / 60.0
		game.queue_redraw()
		await process_frame
	var stable := await _collect(180, false)
	game.arena_fx.clear()
	game.arena_float_labels.clear()
	game.arena_knockout_started = -10.0
	var busy := await _collect(180, true)
	game.snakes_reduced_effects = true
	game._sync_snakes_arena_state()
	game.arena_fx.clear()
	game.arena_float_labels.clear()
	game.arena_knockout_started = -10.0
	var reduced_busy := await _collect(180, true)
	var report := {
		"schema":"offline-games.snakes-fidelity-v3.performance.v1",
		"game_id":"snake_io",
		"runtime":"Godot %s / Xvfb llvmpipe" % Engine.get_version_info().get("string", "4.6"),
		"renderer":RenderingServer.get_video_adapter_name(),
		"viewport":[int(game.size.x), int(game.size.y)],
		"stable":stable,
		"busy":busy,
		"reduced_busy":reduced_busy,
		"stable_case":"five live arena snakes, 96 frequent GAG prize beans and the persistent 50-58 px GAG player head",
		"busy_case":"same full arena plus the 144 px hollow GAG knockout subscriber, capped particles, float label and camera shake retriggered every 60 frames",
		"reduced_busy_case":"same semantic knockout retriggers with animated burst, particles, shake and haptic route suppressed; state and labels remain",
		"note":"Software-renderer regression trace; not a physical-device FPS claim.",
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(ProjectSettings.globalize_path(OUTPUT), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("SNAKES_GAG_PERFORMANCE=%s" % ProjectSettings.globalize_path(OUTPUT))
	quit()


func _collect(frame_count: int, busy: bool) -> Dictionary:
	var samples: Array[float] = []
	var peak_static_memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var previous := Time.get_ticks_usec()
	for frame in range(frame_count):
		if busy and frame % 60 == 0:
			_emit_busy_knockout(frame / 60)
		game.elapsed += 1.0 / 60.0
		game.tick += 1
		game._snakes_arena_prune_fx()
		game.queue_redraw()
		await process_frame
		var current := Time.get_ticks_usec()
		samples.append(float(current - previous) / 1000.0)
		previous = current
		peak_static_memory = maxi(peak_static_memory, int(Performance.get_monitor(Performance.MEMORY_STATIC)))
	var ordered := samples.duplicate()
	ordered.sort()
	var total := 0.0
	for sample in samples:
		total += sample
	return {
		"sample_count":samples.size(),
		"average_frame_ms":total / float(samples.size()),
		"p95_frame_ms":ordered[clampi(int(ceil(ordered.size() * 0.95)) - 1, 0, ordered.size() - 1)],
		"max_frame_ms":ordered.back(),
		"peak_static_memory_bytes":peak_static_memory,
	}


func _emit_busy_knockout(index: int) -> void:
	var world := Vector2(150 + index * 30, -30 + index * 45)
	var events: Array[Dictionary] = [{
		"kind":"bot_died", "id":index + 1, "reason":"performance_fixture",
		"killer_id":0, "at":world,
	}]
	game._snakes_arena_dispatch(events)
