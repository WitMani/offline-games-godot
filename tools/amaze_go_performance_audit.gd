extends SceneTree

const OUTPUT := "res://docs/audit/amaze-go-v2/candidate/performance.json"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._open_game("amaze_go")
	game.has_transitioned = false
	for _warmup in range(60):
		await process_frame
	game.catalog_fx.clear()
	var stable := await _collect(120, false)
	game.catalog_fx.clear()
	game.amaze_go_object_fx = {}
	var busy := await _collect(180, true)
	var report := {
		"game_id":"amaze_go",
		"runtime":"Godot %s / Xvfb llvmpipe" % Engine.get_version_info().get("string", "4.6"),
		"renderer":RenderingServer.get_video_adapter_name(),
		"viewport":[int(game.size.x), int(game.size.y)],
		"stable":stable,
		"busy":busy,
		"busy_case":"grade-4 destination seal, generated beacon/surveyor, ordered route, wall materials, catalog burst, real GAG seal sound and haptic route retriggered every 60 frames",
		"catalog_effect_cap":12,
		"note":"Software-renderer regression trace; not a physical-device FPS claim.",
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(ProjectSettings.globalize_path(OUTPUT), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("AMAZE_GO_PERFORMANCE=%s" % ProjectSettings.globalize_path(OUTPUT))
	quit()


func _collect(frame_count: int, busy: bool) -> Dictionary:
	var samples: Array[float] = []
	var peak_static_memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var previous := Time.get_ticks_usec()
	for frame in range(frame_count):
		if busy and frame % 60 == 0:
			_emit_busy_completion()
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
	var goal: Vector2 = game._path_cell_center(5, 5, 6)
	var before_goal: Vector2 = game._path_cell_center(4, 5, 6)
	game.catalog_fx.clear()
	game.amaze_go_object_fx = {
		"kind":"complete", "from":before_goal, "to":goal,
		"direction":Vector2i.RIGHT, "grade":4,
		"started":game.elapsed, "duration":1.12,
	}
	game._start_motion("path", before_goal, goal, Color("74a8ff"), "", 0.24)
	game._start_catalog_event("path_complete", goal, Color("f6c667"), 4, "全域完成", 1.12)
