extends SceneTree

const OUTPUT := "res://docs/audit/tileclub-v3/art/performance.json"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._clear_tileclub_checkpoint()
	game._set_tileclub_reduced_effects(false)
	game._open_game("tileclub")
	game.has_transitioned = false
	for _warmup in range(90):
		await process_frame
	game.catalog_fx.clear()
	var stable := await _collect(180, "stable")
	var busy := await _collect(240, "busy")
	var reduced_busy := await _collect(240, "reduced_busy")
	var report := {
		"game_id":"tileclub",
		"runtime":"Godot %s / Xvfb llvmpipe" % Engine.get_version_info().get("string", "4.6"),
		"renderer":RenderingServer.get_video_adapter_name(),
		"viewport":[int(game.size.x), int(game.size.y)],
		"stable":stable,
		"busy":busy,
		"reduced_busy":reduced_busy,
		"comparison":{
			"busy_to_stable_average_ratio":float(busy["average_frame_ms"]) / maxf(0.001, float(stable["average_frame_ms"])),
			"reduced_to_busy_average_ratio":float(reduced_busy["average_frame_ms"]) / maxf(0.001, float(busy["average_frame_ms"])),
		},
		"busy_case":"authoritative four-nest restart plus its 12 legal selections, final triple, object gather, six-effect bounded catalog queue, generated GAG audio route and terminal result; repeated every 36 frames",
		"reduced_case":"the identical authoritative completion replay with Tile Club reduced-effects enabled; semantics/result persist while travel, object ghosts, shake, decorative catalog FX and haptics are suppressed",
		"catalog_effect_cap":6,
		"note":"Comparative software-renderer regression trace only; not a physical-device FPS or haptic claim.",
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(ProjectSettings.globalize_path(OUTPUT), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	game._set_tileclub_reduced_effects(false)
	game._clear_tileclub_checkpoint()
	print("TILECLUB_PERFORMANCE=%s" % ProjectSettings.globalize_path(OUTPUT))
	quit()


func _collect(frame_count: int, mode: String) -> Dictionary:
	var samples: Array[float] = []
	var draw_calls: Array[float] = []
	var peak_static_memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	game._set_tileclub_reduced_effects(mode == "reduced_busy")
	game._reset_current()
	var previous := Time.get_ticks_usec()
	for frame in range(frame_count):
		if mode != "stable" and frame % 36 == 0:
			_emit_real_completion()
		await process_frame
		var current := Time.get_ticks_usec()
		samples.append(float(current - previous) / 1000.0)
		previous = current
		draw_calls.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		peak_static_memory = maxi(peak_static_memory, int(Performance.get_monitor(Performance.MEMORY_STATIC)))
	return _summarize(samples, draw_calls, peak_static_memory)


func _summarize(samples: Array[float], draw_calls: Array[float], peak_static_memory: int) -> Dictionary:
	var ordered := samples.duplicate()
	ordered.sort()
	var ordered_draws := draw_calls.duplicate()
	ordered_draws.sort()
	var total := 0.0
	var draw_total := 0.0
	for sample in samples:
		total += sample
	for draw_count in draw_calls:
		draw_total += draw_count
	return {
		"sample_count":samples.size(),
		"average_frame_ms":total / samples.size(),
		"p95_frame_ms":ordered[clampi(int(ceil(ordered.size() * 0.95)) - 1, 0, ordered.size() - 1)],
		"max_frame_ms":ordered.back(),
		"average_draw_calls":draw_total / draw_calls.size(),
		"p95_draw_calls":ordered_draws[clampi(int(ceil(ordered_draws.size() * 0.95)) - 1, 0, ordered_draws.size() - 1)],
		"peak_static_memory_bytes":peak_static_memory,
	}


func _emit_real_completion() -> void:
	game._reset_current()
	for tile_id in game.tileclub_model.solution_for_level():
		game._tileclub_collect_id(tile_id)
