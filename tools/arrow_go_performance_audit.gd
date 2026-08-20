extends SceneTree

const OUTPUT := "res://docs/audit/arrow-go-v2/candidate/performance.json"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._open_game("arrow_go")
	game.has_transitioned = false
	game.arrow_go_route.clear()
	for x in range(9):
		game.arrow_go_route.append(Vector2i(x, 0))
	for y in range(1, 9):
		game.arrow_go_route.append(Vector2i(8, y))
	for _warmup in range(60):
		await process_frame
	game.catalog_fx.clear()
	var stable := await _collect(120, false)
	game.catalog_fx.clear()
	game.arrow_go_object_fx = {}
	var busy := await _collect(180, true)
	var report := {
		"game_id":"arrow_go",
		"runtime":"Godot %s / Xvfb llvmpipe" % Engine.get_version_info().get("string", "4.6"),
		"renderer":RenderingServer.get_video_adapter_name(),
		"viewport":[int(game.size.x), int(game.size.y)],
		"stable":stable,
		"busy":busy,
		"busy_case":"grade-4 harbor docking, 81 generated wind plates, generated courier/harbor, ordered route, directional fins, catalog burst, real GAG dock sound and haptic route retriggered every 60 frames",
		"catalog_effect_cap":12,
		"note":"Software-renderer regression trace; not a physical-device FPS claim.",
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(ProjectSettings.globalize_path(OUTPUT), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("ARROW_GO_PERFORMANCE=%s" % ProjectSettings.globalize_path(OUTPUT))
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
	var goal: Vector2 = game._path_cell_center(8, 8, 9)
	var before_goal: Vector2 = game._path_cell_center(8, 7, 9)
	game.catalog_fx.clear()
	game.arrow_go_facing = Vector2i.DOWN
	game.arrow_go_object_fx = {
		"kind":"complete", "from":before_goal, "to":goal,
		"direction":Vector2i.DOWN, "grade":4,
		"started":game.elapsed, "duration":1.18,
	}
	game._start_motion("path", before_goal, goal, Color("b69cff"), "", 0.24)
	game._start_catalog_event("path_complete", goal, Color("f6c667"), 4, "全域完成", 1.18, {"direction":[0, 1], "label_position":Vector2(270, 711)})
