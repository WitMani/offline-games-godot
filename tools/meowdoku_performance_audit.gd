extends SceneTree

const OUTPUT := "user://meowdoku_v3_visual_audit/performance.json"
const SAMPLE_COUNT := 180

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.meowdoku_recovery_enabled = false
	root.add_child(game)
	game._open_game("meowdoku")
	game.has_transitioned = false
	for cell in game.meowdoku_model.solution:
		game.meowdoku_model.attempt_cat(cell)
	game._sync_meowdoku_state()
	for _warmup in range(20):
		await process_frame

	var samples: Array[float] = []
	var peak_static_memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var previous := Time.get_ticks_usec()
	for frame in range(SAMPLE_COUNT):
		if frame % 60 == 0:
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
	var report := {
		"schema":"offline-games.meowdoku-performance.v3",
		"game":"meowdoku", "renderer":RenderingServer.get_video_adapter_name(),
		"viewport":[int(game.size.x), int(game.size.y)], "sample_count":SAMPLE_COUNT,
		"average_frame_ms":total / samples.size(),
		"p95_frame_ms":ordered[clampi(int(ceil(ordered.size() * 0.95)) - 1, 0, ordered.size() - 1)],
		"max_frame_ms":ordered.back(), "peak_static_memory_bytes":peak_static_memory,
		"busy_case":"full-board cat completion: dedicated GAG paw renderer plus semantic catalog event retriggered every 60 frames",
		"catalog_effect_cap":12,
		"note":"Xvfb/llvmpipe busy-event regression trace; not a physical-device FPS claim",
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://meowdoku_v3_visual_audit"))
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("MEOWDOKU_PERFORMANCE=%s" % ProjectSettings.globalize_path(OUTPUT))
	game.queue_free()
	await process_frame
	quit()


func _emit_busy_completion() -> void:
	game.catalog_fx.clear()
	game.meowdoku_presenter.present("complete", game.meowdoku_model.solution[-1], game.elapsed, {"status":"won"})
	game._start_catalog_event("cat_complete", game._meowdoku_board_rect().get_center(), Color("f4bf57"), 4, "全员到齐", 1.18, {"semantic":"cat_complete"})
