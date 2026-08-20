extends SceneTree

const OUTPUT := "res://docs/audit/sudoku-v2/candidate/performance.json"
const SAMPLE_COUNT := 180

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._open_game("sudoku")
	game.has_transitioned = false
	var solution: Array = game.state["solution"]
	game.state["board"] = solution.duplicate(true)
	game.state["status"] = "won"
	game.state["score"] = 1000
	game.state["moves"] = 1
	game.state["selected"] = [0, 0]
	game.logic_game_presenter.select(Vector2i(0, 0), game.elapsed)
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
		"game_id": "sudoku",
		"renderer": RenderingServer.get_video_adapter_name(),
		"viewport": [int(game.size.x), int(game.size.y)],
		"sample_count": SAMPLE_COUNT,
		"average_frame_ms": total / samples.size(),
		"p95_frame_ms": ordered[clampi(int(ceil(ordered.size() * 0.95)) - 1, 0, ordered.size() - 1)],
		"max_frame_ms": ordered.back(),
		"peak_static_memory_bytes": peak_static_memory,
		"busy_case": "grade-4 full-board completion retriggered every 60 frames",
		"catalog_effect_cap": 12,
		"note": "Xvfb/llvmpipe busy-completion regression trace; not a physical-device FPS claim",
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(ProjectSettings.globalize_path(OUTPUT), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("SUDOKU_PERFORMANCE=%s" % ProjectSettings.globalize_path(OUTPUT))
	quit()


func _emit_busy_completion() -> void:
	game.catalog_fx.clear()
	var cell := Vector2i(0, 0)
	game.logic_game_presenter.present("logic_complete", cell, 0, int(game.state["solution"][0][0]), 4, game.elapsed)
	game._start_catalog_event("logic_complete", Vector2(270, 458), Color("f4bf57"), 4, "整册完成", 1.18, {"semantic":"logic_complete"})

