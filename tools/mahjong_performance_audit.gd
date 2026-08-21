extends SceneTree

const OUTPUT := "res://docs/audit/mahjong-v3/candidate/performance.json"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._clear_mahjong_session()
	game._open_game("mahjong")
	game.has_transitioned = false
	for _warmup in range(90):
		await process_frame
	game.catalog_fx.clear()
	game.mahjong_object_fx = {}
	var stable := await _collect(180, false)
	_prepare_busy_peak()
	var busy := await _collect(240, true)
	var report := {
		"game_id":"mahjong",
		"engine":"Godot %s" % Engine.get_version_info().get("string", "4.6"),
		"renderer":RenderingServer.get_video_adapter_name(),
		"rendering_method":ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown"),
		"viewport":[int(game.size.x), int(game.size.y)],
		"stable":stable,
		"busy":busy,
		"comparison":{
			"average_frame_ms_delta":float(busy["average_frame_ms"]) - float(stable["average_frame_ms"]),
			"average_frame_ms_ratio":float(busy["average_frame_ms"]) / maxf(0.001, float(stable["average_frame_ms"])),
			"p95_frame_ms_delta":float(busy["p95_frame_ms"]) - float(stable["p95_frame_ms"]),
			"p95_frame_ms_ratio":float(busy["p95_frame_ms"]) / maxf(0.001, float(stable["p95_frame_ms"])),
		},
		"busy_case":"Synthetic bounded worst-case: 36-tile layered board, grade-4 pair gather, and the runtime cap of six simultaneous Mahjong catalog envelopes; refreshed every 72 frames.",
		"catalog_effect_cap":6,
		"claim_boundary":"Comparative software-renderer regression trace; not a physical-device FPS claim.",
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(ProjectSettings.globalize_path(OUTPUT), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	game._clear_mahjong_session()
	print("MAHJONG_PERFORMANCE=%s" % ProjectSettings.globalize_path(OUTPUT))
	quit()


func _collect(frame_count: int, busy: bool) -> Dictionary:
	var samples: Array[float] = []
	var draw_calls: Array[float] = []
	var objects: Array[float] = []
	var peak_static_memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var previous := Time.get_ticks_usec()
	for frame in range(frame_count):
		if busy and frame > 0 and frame % 72 == 0:
			_prepare_busy_peak()
		await process_frame
		var current := Time.get_ticks_usec()
		samples.append(float(current - previous) / 1000.0)
		previous = current
		draw_calls.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		objects.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
		peak_static_memory = maxi(peak_static_memory, int(Performance.get_monitor(Performance.MEMORY_STATIC)))
	return _statistics(samples, draw_calls, objects, peak_static_memory)


func _statistics(samples: Array[float], draw_calls: Array[float], objects: Array[float], peak_static_memory: int) -> Dictionary:
	var ordered := samples.duplicate()
	ordered.sort()
	var total := 0.0
	var total_draw_calls := 0.0
	var total_objects := 0.0
	var peak_draw_calls := 0.0
	var peak_objects := 0.0
	for index in range(samples.size()):
		total += samples[index]
		total_draw_calls += draw_calls[index]
		total_objects += objects[index]
		peak_draw_calls = maxf(peak_draw_calls, draw_calls[index])
		peak_objects = maxf(peak_objects, objects[index])
	return {
		"sample_count":samples.size(),
		"average_frame_ms":total / samples.size(),
		"p50_frame_ms":ordered[clampi(int(ceil(ordered.size() * 0.50)) - 1, 0, ordered.size() - 1)],
		"p95_frame_ms":ordered[clampi(int(ceil(ordered.size() * 0.95)) - 1, 0, ordered.size() - 1)],
		"max_frame_ms":ordered.back(),
		"average_draw_calls":total_draw_calls / draw_calls.size(),
		"peak_draw_calls":peak_draw_calls,
		"average_render_objects":total_objects / objects.size(),
		"peak_render_objects":peak_objects,
		"peak_static_memory_bytes":peak_static_memory,
	}


func _prepare_busy_peak() -> void:
	game.catalog_fx.clear()
	var pair: Array = game.mahjong_model.available_pairs()[0]
	game.mahjong_object_fx = {
		"kind":"clear", "indices":[int(pair[0]), int(pair[1])],
		"value":int(game.mahjong_model.tiles[int(pair[0])]["face"]),
		"grade":4, "started":game.elapsed, "duration":1.10,
	}
	for index in range(6):
		game._start_catalog_event(
			"jade_pair", Vector2(150 + index * 48, 420 + (index % 2) * 60),
			Color("f6d987"), 4, "牌阵清空 · 玉成", 1.10,
			{"semantic":"mahjong_pair", "stress_fixture":true}
		)
