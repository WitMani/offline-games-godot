extends SceneTree

const OUTPUT := "res://docs/audit/arrow-go-v3/performance.json"
const SOLUTION: Array[String] = ["b", "a", "d", "c", "k", "g", "f", "l", "i", "e", "j", "h"]

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._arrow_go_clear_recovery()
	game._open_game("arrow_go")
	game.has_transitioned = false
	for _warmup in range(60):
		await process_frame
	game.catalog_fx.clear()
	var stable := await _collect(120, false)
	game.catalog_fx.clear()
	game.arrow_go_object_fx = {}
	var busy := await _collect(180, true)
	game._arrow_go_set_reduced_effects(true)
	game.catalog_fx.clear()
	var reduced_busy := await _collect(120, true)
	game._arrow_go_set_reduced_effects(false)
	game._arrow_go_clear_recovery()
	var report := {
		"game_id":"arrow_go",
		"runtime":"Godot %s / Xvfb llvmpipe" % Engine.get_version_info().get("string", "4.6"),
		"renderer":RenderingServer.get_video_adapter_name(),
		"viewport":[int(game.size.x), int(game.size.y)],
		"stable":stable,
		"busy":busy,
		"reduced_busy":reduced_busy,
		"busy_case":"Repeated authoritative final-arrow clear: 256px GAG fox, 12-arrow live vector family, whole-arrow ghost, grade-4 semantic catalog event, GAG reveal sound route and result plate retriggered every 60 frames",
		"reduced_case":"Same authoritative clear with displacement, board shake, catalog particles and haptics suppressed",
		"catalog_effect_cap":12,
		"note":"Software-renderer regression trace; not a physical-device FPS claim.",
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(ProjectSettings.globalize_path(OUTPUT), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("ARROW_GO_V3_PERFORMANCE=%s" % ProjectSettings.globalize_path(OUTPUT))
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
	game.catalog_fx.clear()
	game.arrow_go_object_fx = {}
	game.arrow_go_model.reset()
	for index in range(SOLUTION.size() - 1):
		game.arrow_go_model.attempt(SOLUTION[index])
	game._sync_arrow_go_state()
	game._arrow_go_attempt(SOLUTION.back(), "performance_audit")
