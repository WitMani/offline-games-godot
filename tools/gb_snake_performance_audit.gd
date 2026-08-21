extends SceneTree

const OUTPUT := "res://docs/audit/gb-snake-v3/candidate/performance.json"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._open_game("snake_classic")
	game.has_transitioned = false
	game.snake_reset_started = -10.0
	_pose_near_target_body()
	game.set_process(false)
	for _warmup in range(60):
		game.elapsed += 1.0 / 60.0
		game.queue_redraw()
		await process_frame
	var stable := await _collect(120, false)
	game.snake_pixels.clear()
	game.snake_float_labels.clear()
	game.snake_gb_object_fx.clear()
	game.snake_fx_kind = ""
	var busy := await _collect(180, true)
	game.reduced_effects = true
	game.snake_pixels.clear()
	game.snake_float_labels.clear()
	game.snake_gb_object_fx.clear()
	game.snake_fx_kind = ""
	var reduced_busy := await _collect(120, true)
	var report := {
		"game_id":"snake_classic",
		"runtime":"Godot %s / Xvfb llvmpipe" % Engine.get_version_info().get("string", "4.6"),
		"renderer":RenderingServer.get_video_adapter_name(),
		"viewport":[int(game.size.x), int(game.size.y)],
		"stable":stable,
		"busy":busy,
		"reduced_busy":reduced_busy,
		"stable_case":"119 authoritative body cells plus ordinary-visible GAG head, two food lures, and external field seal",
		"busy_case":"grade-4 nonterminal field-record sweep, pulsing GAG seal, 22 capped phosphor pixels and the same 119-cell board retriggered every 60 frames",
		"reduced_busy_case":"same semantic field record with zero pixels, zero shake and short bounded envelope",
		"note":"Software-renderer regression trace; not a physical-device FPS claim.",
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(ProjectSettings.globalize_path(OUTPUT), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("GB_SNAKE_PERFORMANCE=%s" % ProjectSettings.globalize_path(OUTPUT))
	for player in game.sfx_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	game.free()
	await process_frame
	await process_frame
	quit()


func _pose_near_target_body() -> void:
	var segments: Array[Vector2i] = []
	for column in range(game.snake_gb_model.width):
		var start_y: int = 0 if column == 0 else 1
		var end_y: int = game.snake_gb_model.height - 1
		var step_y := 1
		if column % 2 == 1:
			start_y = game.snake_gb_model.height - 1
			end_y = 1
			step_y = -1
		var y := start_y
		while (y <= end_y if step_y > 0 else y >= end_y) and segments.size() < 119:
			segments.append(Vector2i(column, y))
			y += step_y
	game.snake_gb_model.segments = segments
	game.snake_gb_model.direction = Vector2i.RIGHT
	game.snake_gb_model.food = Vector2i(14, 22)
	game.snake_gb_model.foods.assign([game.snake_gb_model.food, Vector2i(13, 22)])
	game.snake_gb_model.score = 119
	game.snake_gb_model.pending_growth = 0
	game.snake_gb_model.phase = game.snake_gb_model.RUNNING
	game._sync_snake_gb_state()
	game.snake_previous_cells = game.state.get("segments", []).duplicate(true)
	game.snake_move_started = game.elapsed - 1.0


func _collect(frame_count: int, busy: bool) -> Dictionary:
	var samples: Array[float] = []
	var peak_static_memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var previous := Time.get_ticks_usec()
	for frame in range(frame_count):
		if busy and frame % 60 == 0:
			_emit_busy_completion()
		game.elapsed += 1.0 / 60.0
		game._snake_prune_fx()
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
		"average_frame_ms":total / samples.size(),
		"p95_frame_ms":ordered[clampi(int(ceil(ordered.size() * 0.95)) - 1, 0, ordered.size() - 1)],
		"max_frame_ms":ordered.back(),
		"peak_static_memory_bytes":peak_static_memory,
	}


func _emit_busy_completion() -> void:
	game.snake_fx_kind = "complete"
	game.snake_fx_started = game.elapsed
	game.snake_fx_cell = game.snake_gb_model.segments[0]
	game.snake_gb_object_fx = {
		"kind":"complete", "grade":4, "started":game.elapsed,
		"duration":game._snake_gb_effect_duration(1.56, 0.26),
		"cell":game.snake_fx_cell, "score":120, "nonterminal":true,
	}
	game._snake_gb_emit_pixels(game.snake_fx_cell, 22, "complete")
