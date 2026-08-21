extends SceneTree

const OUTPUT := "res://docs/audit/amaze-go-v3/candidate/performance.json"
const SOLVE_ORDER := ["a1", "a0", "a10", "a3", "a2", "a4", "a6", "a8", "a11", "a5", "a9", "a7"]

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.amaze_go_recovery_enabled = false
	root.add_child(game)
	game._set_amaze_go_reduced_effects(false)
	game._open_game("amaze_go")
	game.has_transitioned = false
	game.feedback_until = -1.0
	for _warmup in range(60):
		await process_frame
	game.catalog_fx.clear()
	game.amaze_go_object_fx = {}
	var stable := await _collect(180, "stable")
	_prepare_ordinary_event(false)
	var ordinary_busy := await _collect(240, "ordinary_busy")
	_prepare_final_arrow(false)
	var busy := await _collect(240, "busy")
	_prepare_final_arrow(true)
	var reduced_busy := await _collect(180, "reduced_busy")
	var report := {
		"schema":"amaze-go-performance/v3", "game_id":"amaze_go",
		"runtime":"Godot %s / Xvfb llvmpipe" % Engine.get_version_info().get("string", "4.6"),
		"renderer":RenderingServer.get_video_adapter_name(), "viewport":[int(game.size.x), int(game.size.y)],
		"stable":stable, "busy_ordinary":ordinary_busy, "busy_terminal":busy, "reduced_busy_terminal":reduced_busy,
		"p95_ordinary_over_stable":float(ordinary_busy.p95_frame_ms) / maxf(0.001, float(stable.p95_frame_ms)),
		"p95_terminal_over_stable":float(busy.p95_frame_ms) / maxf(0.001, float(stable.p95_frame_ms)),
		"p95_reduced_over_stable":float(reduced_busy.p95_frame_ms) / maxf(0.001, float(stable.p95_frame_ms)),
		"ordinary_busy_case":"Actual legal first extraction is restarted and retriggered every 60 frames, leaving eleven live arrows plus the ordinary ghost, GAG stations and catalog event.",
		"busy_case":"Authoritative final extraction already committed; grade-4 seal, generated surveyor/beacon, code-native arrow ghost and catalog event are retriggered every 60 frames.",
		"reduced_case":"Same terminal state and GAG assets; translation, shake, catalog particle travel and haptic are suppressed.",
		"catalog_effect_cap":12,
		"note":"Software-renderer regression comparison only; not a physical-device FPS or thermal claim.",
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(ProjectSettings.globalize_path(OUTPUT), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("AMAZE_GO_PERFORMANCE=%s" % ProjectSettings.globalize_path(OUTPUT))
	quit()


func _prepare_final_arrow(reduced: bool) -> void:
	game._set_amaze_go_reduced_effects(reduced)
	game._open_game("amaze_go")
	game.has_transitioned = false
	game.feedback_until = -1.0
	for arrow_id in SOLVE_ORDER.slice(0, 11):
		game._amaze_go_attempt(arrow_id, "perf_setup")
	game.catalog_fx.clear()
	game.amaze_go_object_fx = {}
	game._amaze_go_attempt(SOLVE_ORDER[11], "perf_terminal")


func _prepare_ordinary_event(reduced: bool) -> void:
	game._set_amaze_go_reduced_effects(reduced)
	game._open_game("amaze_go")
	game.has_transitioned = false
	game.feedback_until = -1.0
	game.catalog_fx.clear()
	game.amaze_go_object_fx = {}
	game._amaze_go_attempt("a1", "perf_ordinary")


func _collect(frame_count: int, mode: String) -> Dictionary:
	var samples: Array[float] = []
	var draw_calls: Array[int] = []
	var peak_static_memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var previous := Time.get_ticks_usec()
	for frame in range(frame_count):
		if mode != "stable" and frame > 0 and frame % 60 == 0:
			if mode == "ordinary_busy":
				_prepare_ordinary_event(false)
			else:
				_emit_busy_terminal()
		await process_frame
		var current := Time.get_ticks_usec()
		samples.append(float(current - previous) / 1000.0)
		previous = current
		draw_calls.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		peak_static_memory = maxi(peak_static_memory, int(Performance.get_monitor(Performance.MEMORY_STATIC)))
	var ordered := samples.duplicate()
	ordered.sort()
	var ordered_draws := draw_calls.duplicate()
	ordered_draws.sort()
	var total := 0.0
	for sample in samples:
		total += sample
	return {
		"sample_count":samples.size(), "average_frame_ms":total / samples.size(),
		"p95_frame_ms":ordered[clampi(int(ceil(ordered.size() * 0.95)) - 1, 0, ordered.size() - 1)],
		"max_frame_ms":ordered.back(), "median_draw_calls":ordered_draws[ordered_draws.size() / 2],
		"max_draw_calls":ordered_draws.back(), "peak_static_memory_bytes":peak_static_memory,
	}


func _emit_busy_terminal() -> void:
	var arrow: Dictionary = game.amaze_go_model.arrow_for_id("a7")
	var path: Array = []
	for point: Vector2i in arrow.get("path", []):
		path.append([point.x, point.y])
	var direction: Vector2i = arrow.get("direction", Vector2i.RIGHT)
	var head: Vector2i = arrow.get("path", [Vector2i.ZERO])[-1]
	var position: Vector2 = game._amaze_go_cell_center(head)
	game.catalog_fx.clear()
	game.amaze_go_object_fx = {
		"kind":"win", "started":game.elapsed, "duration":1.08, "grade":4,
		"arrow_id":"a7", "path":path, "direction":direction, "head":position,
		"removed_count":12, "remaining":0, "reduced":game.amaze_go_reduced_effects,
	}
	game._start_catalog_event("arrow_win", position, Color("f6c667"), 4, "全箭清空", 1.08, {
		"arrow_id":"a7", "semantic":"arrow_win", "label_position":Vector2(270, 788),
	})
