extends SceneTree

const OUTPUT := "res://docs/audit/sudoku-v3/candidate/performance.json"
const STABLE_SAMPLES := 120
const BUSY_SAMPLES := 180
const REDUCED_SAMPLES := 120

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._open_game("sudoku")
	game.has_transitioned = false
	for _warmup in range(24):
		await process_frame
	var stable := await _sample(STABLE_SAMPLES, false, false)
	_prepare_completed_board()
	var busy := await _sample(BUSY_SAMPLES, true, false)
	game.sudoku_reduced_effects = true
	game._sync_sudoku_state()
	var reduced := await _sample(REDUCED_SAMPLES, true, true)
	var passed := float(busy.p95_frame_ms) < 50.0 and float(busy.max_frame_ms) < 100.0 and int(busy.max_draw_calls) < 2500
	var report := {
		"schema":"sudoku-v3-performance/v1",
		"game_id":"sudoku",
		"renderer":RenderingServer.get_video_adapter_name(),
		"viewport":[int(game.size.x), int(game.size.y)],
		"stable":stable,
		"busy":busy,
		"reduced_effects":reduced,
		"thresholds":{"busy_p95_frame_ms_lt":50.0, "busy_max_frame_ms_lt":100.0, "busy_draw_calls_lt":2500},
		"catalog_effect_cap":12,
		"note":"Xvfb/llvmpipe comparative regression trace; not a physical-device FPS claim.",
		"result":"PASS" if passed else "FAIL",
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(ProjectSettings.globalize_path(OUTPUT), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "  ") + "\n")
		file.close()
	print("SUDOKU_V3_PERFORMANCE=%s" % ProjectSettings.globalize_path(OUTPUT))
	print("SUDOKU_V3_PERFORMANCE_RESULT=%s" % report.result)
	for player in game.sfx_players:
		player.stop()
	game.queue_free()
	await process_frame
	quit(0 if passed else 1)


func _prepare_completed_board() -> void:
	game.sudoku_model.board = game.sudoku_model.solution.duplicate(true)
	game.sudoku_model.status = "won"
	game.sudoku_model.score = 1000
	game.sudoku_model.moves = 1
	game._sync_sudoku_state()
	game.logic_game_presenter.present("logic_complete", Vector2i(0, 0), 0, int(game.state.solution[0][0]), 4, game.elapsed)
	game._start_catalog_event("logic_complete", Vector2(270, 458), Color("f4bf57"), 4, "整册完成", 1.18, {"semantic":"logic_complete"})


func _sample(count: int, retrigger: bool, reduced: bool) -> Dictionary:
	var samples: Array[float] = []
	var max_draw_calls := 0
	var peak_static_memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var previous := Time.get_ticks_usec()
	for frame in range(count):
		if retrigger and frame % 12 == 0:
			game.logic_game_presenter.present("logic_complete", Vector2i(frame % 9, int(frame / 9) % 9), int(frame / 12) % 9, int(game.state.solution[0][0]), 4, game.elapsed)
			game._start_catalog_event("logic_complete", Vector2(270, 458), Color("f4bf57"), 4, "整册完成", 1.18, {"semantic":"logic_complete", "busy":true})
		await process_frame
		var current := Time.get_ticks_usec()
		samples.append(float(current - previous) / 1000.0)
		previous = current
		max_draw_calls = maxi(max_draw_calls, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		peak_static_memory = maxi(peak_static_memory, int(Performance.get_monitor(Performance.MEMORY_STATIC)))
	var ordered := samples.duplicate()
	ordered.sort()
	var total := 0.0
	for sample in samples:
		total += sample
	return {
		"sample_count":count,
		"average_frame_ms":total / samples.size(),
		"p95_frame_ms":ordered[clampi(int(ceil(ordered.size() * 0.95)) - 1, 0, ordered.size() - 1)],
		"max_frame_ms":ordered.back(),
		"max_draw_calls":max_draw_calls,
		"peak_static_memory_bytes":peak_static_memory,
		"effects_mode":"reduced" if reduced else "full",
		"busy_case":"grade-4 completion retriggered every 12 frames" if retrigger else "ordinary stable board",
	}
