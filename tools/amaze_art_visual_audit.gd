extends SceneTree

const OUTPUT := "res://docs/audit/amaze-v3/art"
const CONTINUOUS_OUTPUT := "/tmp/offline-games-amaze-v3-long-roll-frames"
const PEAK_OUTPUT := "/tmp/offline-games-amaze-v3-peak-frames"
const LEVEL_THREE_SOLUTION := [
	Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN,
	Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP, Vector2i.RIGHT,
	Vector2i.DOWN, Vector2i.LEFT,
]

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(CONTINUOUS_OUTPUT)
	DirAccess.make_dir_recursive_absolute(PEAK_OUTPUT)
	await _wait(0.18)
	_open_level_three()
	await _wait(0.12)
	await _save_frame("00-stable-gag-visible")

	game._amaze_step(Vector2i.LEFT)
	await _wait(0.27)
	await _save_frame("01-blocked-impact")
	_save_state("01-blocked-impact")

	_open_level_three()
	game._amaze_step(Vector2i.RIGHT)
	var started: float = float(game.motion_started)
	await _sample_at(started + 0.035, "02-roll-intent")
	await _sample_at(started + 0.135, "03-roll-anticipation")
	await _sample_at(started + 0.315, "04-roll-impact")
	await _sample_at(started + 0.525, "05-roll-settle")
	_save_state("05-roll-settle")

	await _capture_continuous_long_roll()
	await _capture_continuous_peak()

	_open_level_three()
	game._amaze_step(Vector2i.RIGHT)
	game.catalog_fx.clear()
	game.motion_started = -10.0
	game.feedback_until = -10.0
	game._amaze_step(Vector2i.LEFT)
	await _wait(0.28)
	await _save_frame("06-revisit")
	_save_state("06-revisit")

	_open_level_three()
	for index in range(LEVEL_THREE_SOLUTION.size() - 1):
		game._amaze_step(LEVEL_THREE_SOLUTION[index])
		if index < LEVEL_THREE_SOLUTION.size() - 2:
			_clear_transient()
	await _wait(0.34)
	await _save_frame("07-near-complete")
	_save_state("07-near-complete")

	_clear_transient()
	game._amaze_step(LEVEL_THREE_SOLUTION.back())
	await _wait(0.32)
	await _save_frame("08-complete-impact")
	_save_state("08-complete-impact")
	await _wait(0.72)
	await _save_frame("09-complete-result")
	_save_state("09-complete-result")

	_open_level_three()
	game._set_reduced_effects(true)
	game._amaze_step(Vector2i.RIGHT)
	await _wait(0.08)
	await _save_frame("10-reduced-settled")
	_save_state("10-reduced-settled")
	game._set_reduced_effects(false)
	print("AMAZE_ART_VISUAL_AUDIT=%s" % ProjectSettings.globalize_path(OUTPUT))
	print("AMAZE_ART_CONTINUOUS_FRAMES=%s" % CONTINUOUS_OUTPUT)
	print("AMAZE_ART_PEAK_FRAMES=%s" % PEAK_OUTPUT)
	quit()


func _open_level_three() -> void:
	game._clear_amaze_checkpoint()
	game._open_game("amaze")
	game.amaze_level_index = 2
	game._start_game_state()
	game._build_game_buttons()
	game.has_transitioned = false
	game.catalog_fx.clear()
	game.motion_started = -10.0
	game.feedback_until = -10.0


func _clear_transient() -> void:
	game.catalog_fx.clear()
	game.motion_started = -10.0
	game.feedback_until = -10.0


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame
	await process_frame


func _sample_at(sample_time: float, stem: String) -> void:
	game.elapsed = sample_time
	game.queue_redraw()
	await process_frame
	await _save_frame(stem)


func _capture_continuous_long_roll() -> void:
	_open_level_three()
	game._amaze_step(Vector2i.RIGHT)
	var started: float = float(game.motion_started)
	var sequence: Array[Dictionary] = []
	for index in range(24):
		var sample_time: float = started + float(index) / 23.0 * 0.70
		game.elapsed = sample_time
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var image := game.get_viewport().get_texture().get_image()
		var frame_path := "%s/frame_%03d.png" % [CONTINUOUS_OUTPUT, index]
		image.save_png(frame_path)
		sequence.append({
			"frame":index,
			"time":sample_time - started,
			"phase":game._amaze_event_phase(game.amaze_object_fx, sample_time),
			"motion_progress":clampf((sample_time - started) / game.motion_duration, 0.0, 1.0),
		})
	var file := FileAccess.open(ProjectSettings.globalize_path("%s/continuous-long-roll.json" % OUTPUT), FileAccess.WRITE)
	file.store_string(JSON.stringify({"fps":24, "frames":sequence}, "  ") + "\n")
	file.close()


func _capture_continuous_peak() -> void:
	_open_level_three()
	for index in range(LEVEL_THREE_SOLUTION.size() - 1):
		game._amaze_step(LEVEL_THREE_SOLUTION[index])
		_clear_transient()
	game._amaze_step(LEVEL_THREE_SOLUTION.back())
	var started: float = float(game.amaze_object_fx.get("started", game.elapsed))
	var sequence: Array[Dictionary] = []
	for index in range(36):
		var sample_time: float = started + float(index) / 24.0
		game.elapsed = sample_time
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var image := game.get_viewport().get_texture().get_image()
		var frame_path := "%s/frame_%03d.png" % [PEAK_OUTPUT, index]
		image.save_png(frame_path)
		sequence.append({
			"frame":index,
			"time":sample_time - started,
			"phase":game._amaze_event_phase(game.amaze_object_fx, sample_time),
			"status":game.state.get("status", ""),
			"remaining":game.state.get("remaining", -1),
			"result_overlay_ready":game._catalog_result_overlay_ready(),
		})
	var file := FileAccess.open(ProjectSettings.globalize_path("%s/continuous-peak.json" % OUTPUT), FileAccess.WRITE)
	file.store_string(JSON.stringify({"fps":24, "frames":sequence, "semantic":"amaze_complete"}, "  ") + "\n")
	file.close()


func _save_frame(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.webp" % [OUTPUT, stem])
	var error := image.save_webp(path, false, 0.94)
	if error != OK:
		push_error("Amaze art visual capture failed: %s" % path)


func _save_state(stem: String) -> void:
	var event: Dictionary = {}
	if not game.catalog_fx.is_empty():
		var source: Dictionary = game.catalog_fx.back()
		event = {
			"kind":source.get("kind", ""),
			"semantic":source.get("semantic", ""),
			"grade":source.get("grade", 0),
			"label":source.get("label", ""),
			"font_role":source.get("font_role", ""),
			"direction":source.get("direction", []),
			"traversed":source.get("traversed", []),
			"newly_painted":source.get("newly_painted", []),
			"remaining":source.get("remaining", -1),
		}
	var object_phase: String = game._amaze_event_phase()
	var report := {
		"game_id":"amaze",
		"rules_version":game.state.get("rules_version", ""),
		"level_id":game.state.get("level_id", ""),
		"status":game.state.get("status", ""),
		"player":game.state.get("player", []),
		"painted_count":game.state.get("painted_count", 0),
		"walkable_count":game.state.get("walkable_count", 0),
		"remaining":game.state.get("remaining", 0),
		"moves":game.state.get("moves", 0),
		"last_traversal":game.state.get("last_traversal", []),
		"last_newly_painted":game.state.get("last_newly_painted", []),
		"object_phase":object_phase,
		"reduced_effects":game.reduced_effects,
		"haptic_emitted":game.haptic_emitted_count,
		"haptic_suppressed":game.haptic_suppressed_count,
		"gag_runtime_assets":[
			"res://assets/art/catalog/path_games/gag/amaze_paint_pod_gag_v2.png",
			"res://assets/audio/catalog/path_games/gag/amaze_wet_corridor_roll_gag_v2.ogg",
		],
		"event":event,
	}
	var path := ProjectSettings.globalize_path("%s/%s.json" % [OUTPUT, stem])
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
