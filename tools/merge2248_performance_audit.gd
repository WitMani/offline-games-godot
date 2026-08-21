extends SceneTree

## Matched busy-event traces for normal and reduced presentation. The frame is
## pinned to legendary impact so the audit measures the expensive authored
## state instead of letting the effect expire during sampling.

const OUTPUT := "user://merge2248_visual_audit/performance-v4.json"
const SAMPLE_COUNT := 180
const WARMUP_COUNT := 12
const BUSY_AGE := 0.16
const P95_BUDGET_MS := 33.34
const MAX_BUDGET_MS := 66.68


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var normal: Dictionary = await _measure_variant(false)
	var reduced: Dictionary = await _measure_variant(true)
	var passed := (
		float(normal.p95_ms) <= P95_BUDGET_MS
		and float(normal.max_ms) <= MAX_BUDGET_MS
		and float(reduced.p95_ms) <= P95_BUDGET_MS
		and float(reduced.max_ms) <= MAX_BUDGET_MS
	)
	var result := {
		"contract": "merge2248-performance-v4",
		"renderer": RenderingServer.get_current_rendering_method(),
		"sample_count_per_variant": SAMPLE_COUNT,
		"busy_age_seconds": BUSY_AGE,
		"budget": {
			"p95_ms": P95_BUDGET_MS,
			"max_ms": MAX_BUDGET_MS,
			"rationale": "EC2 llvmpipe 30fps regression guard with one-frame maximum allowance; not end-user GPU telemetry",
		},
		"normal": normal,
		"reduced": reduced,
		"result": "PASS" if passed else "FAIL",
	}
	var output_path := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	print("MERGE2248_PERFORMANCE=%s" % JSON.stringify(result))
	quit(0 if passed else 1)


func _measure_variant(reduced_effects: bool) -> Dictionary:
	var game: Control = load("res://main.tscn").instantiate()
	game.merge2248_persistence_enabled = false
	game.merge2248_reduced_effects_override = reduced_effects
	root.add_child(game)
	for _frame in range(12):
		await process_frame
	game._open_game("merge2248")
	game.set_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	game.has_transitioned = false
	for y in range(game.merge2248_model.height):
		for x in range(game.merge2248_model.width):
			game.merge2248_model.board[y][x] = 1
	game._sync_merge2248_state()
	var chain: Array[Vector2i] = [
		Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7),
		Vector2i(4, 7), Vector2i(4, 6), Vector2i(3, 6), Vector2i(2, 6),
	]
	game._merge2248_begin_at(game._merge2248_cell_center(chain[0]))
	game.merge2248_drag_active = true
	for index in range(1, chain.size()):
		game._merge2248_extend_at(game._merge2248_cell_center(chain[index]))
	game._merge2248_release()
	game.merge2248_drag_active = false
	var effect: Dictionary = game.merge2248_fx[-1]
	var pinned_time := float(effect.started) + BUSY_AGE
	for _warmup in range(WARMUP_COUNT):
		game.elapsed = pinned_time
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
	var samples_ms: Array[float] = []
	for _sample in range(SAMPLE_COUNT):
		var started := Time.get_ticks_usec()
		game.elapsed = pinned_time
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		samples_ms.append(float(Time.get_ticks_usec() - started) / 1000.0)
	samples_ms.sort()
	var total := 0.0
	for sample in samples_ms:
		total += sample
	var metrics := {
		"reduced_effects": reduced_effects,
		"average_ms": total / float(SAMPLE_COUNT),
		"p50_ms": samples_ms[int(SAMPLE_COUNT * 0.50)],
		"p95_ms": samples_ms[int(SAMPLE_COUNT * 0.95)],
		"max_ms": samples_ms[-1],
		"event_grade": int(effect.grade),
		"chain_length": chain.size(),
		"effect_duration": float(effect.duration),
	}
	game.queue_free()
	await process_frame
	return metrics
