extends SceneTree

const OUTPUT := "res://docs/audit/merge2048-fidelity-v4/candidate/performance.json"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	game = load("res://main.tscn").instantiate()
	game.merge2048_persistence_enabled = false
	root.add_child(game)
	game._open_game("merge2048")
	var full_board := [
		[512, 256, 128, 64], [32, 16, 8, 4],
		[2, 4, 8, 16], [32, 64, 128, 256],
	]
	for _warmup in range(24):
		await process_frame
	game._merge2048_load_fixture(game._new_grid(4, 4, 0))
	var empty_baseline := await _measure(90, false)
	game._merge2048_load_fixture(full_board)
	var full_baseline := await _measure(90, false)
	game.reduced_effects_enabled = false
	var busy := await _measure(180, true)
	game.reduced_effects_enabled = true
	var reduced_busy := await _measure(180, true)
	game.reduced_effects_enabled = false
	var regression_budget := {"p95_frame_ms":35.0, "max_frame_ms":80.0}
	var report := {
		"game_id":"merge2048",
		"sample_count":busy["sample_count"],
		"busy_effect_cap":6,
		"average_frame_ms":busy["average_frame_ms"],
		"p95_frame_ms":busy["p95_frame_ms"],
		"max_frame_ms":busy["max_frame_ms"],
		"regression_budget":regression_budget,
		"budget_result":"PASS" if float(busy.p95_frame_ms) <= 35.0 and float(busy.max_frame_ms) <= 80.0 else "FAIL",
		"phases":{
			"empty_board_baseline":empty_baseline,
			"full_material_board":full_baseline,
			"full_board_six_fx_plus_burst":busy,
			"reduced_effects_full_board":reduced_busy,
		},
		"renderer":RenderingServer.get_video_adapter_name(),
		"viewport":[int(game.size.x), int(game.size.y)],
		"note":"Xvfb/llvmpipe regression trace: full GAG material board, six capped grade-four catalog envelopes, one GAG wood-shaving burst, plus the reduced-effects fallback; budget is EC2 regression-only and not a device FPS claim",
	}
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("MERGE2048_PERFORMANCE=%s" % ProjectSettings.globalize_path(OUTPUT))
	game.queue_free()
	await process_frame
	quit()


func _measure(frame_count: int, busy_case: bool) -> Dictionary:
	game.catalog_fx.clear()
	game.merge2048_motion.clear()
	for _settle_frame in range(12):
		await process_frame
	var samples: Array[float] = []
	var previous := Time.get_ticks_usec()
	for frame in range(frame_count):
		if busy_case and frame % 34 == 0:
			_emit_busy_case()
		await process_frame
		var current := Time.get_ticks_usec()
		samples.append(float(current - previous) / 1000.0)
		previous = current
	samples.sort()
	var total := 0.0
	for sample in samples:
		total += sample
	return {
		"sample_count":samples.size(),
		"average_frame_ms":total / samples.size(),
		"p95_frame_ms":samples[clampi(int(ceil(samples.size() * 0.95)) - 1, 0, samples.size() - 1)],
		"max_frame_ms":samples.back(),
	}


func _emit_busy_case() -> void:
	game.merge2048_motion = {
		"started":game.elapsed,
		"duration":0.16 if game.reduced_effects_enabled else 0.78,
		"moves":[],
		"merges":[],
		"spawn":{},
		"grade":4,
		"peak_value":128,
		"merge_count":2,
		"impact_cell":Vector2i(1, 1),
		"reduced":game.reduced_effects_enabled,
	}
	for index in range(10):
		game._start_catalog_event(
			"merge",
			Vector2(104 + (index % 4) * 109, 298 + (index / 4) * 109),
			Color("f6c667"),
			4,
			"大师雕版 · 128 · 2 连合",
			0.94,
			{"semantic":"wood_masterpiece", "gained":256, "peak_value":128, "merge_count":2}
		)
