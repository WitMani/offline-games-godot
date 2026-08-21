extends SceneTree

const OUTPUT := "res://docs/audit/tileclub-v3/art"
const MATCH_MOTION_OUTPUT := "user://tileclub-v3-match-motion"
const FULL_MOTION_OUTPUT := "user://tileclub-v3-full-motion"
const CLEAR_MOTION_OUTPUT := "user://tileclub-v3-clear-motion"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for folder in [MATCH_MOTION_OUTPUT, FULL_MOTION_OUTPUT, CLEAR_MOTION_OUTPUT]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	await _wait(0.30)
	await _capture_stable_and_blocked()
	await _capture_collect()
	await _capture_match()
	await _capture_layer_clear()
	await _capture_risk_and_full()
	await _capture_complete()
	await _capture_reduced_effects()
	game._clear_tileclub_checkpoint()
	print("TILECLUB_VISUAL_AUDIT=%s" % ProjectSettings.globalize_path(OUTPUT))
	print("TILECLUB_MATCH_MOTION=%s" % ProjectSettings.globalize_path(MATCH_MOTION_OUTPUT))
	print("TILECLUB_FULL_MOTION=%s" % ProjectSettings.globalize_path(FULL_MOTION_OUTPUT))
	print("TILECLUB_CLEAR_MOTION=%s" % ProjectSettings.globalize_path(CLEAR_MOTION_OUTPUT))
	quit()


func _open(level := 0, reduced := false) -> void:
	game._clear_tileclub_checkpoint()
	game._set_tileclub_reduced_effects(reduced)
	game._open_game("tileclub")
	if level != 0:
		game.tileclub_level_index = level
		game._start_game_state()
	game.has_transitioned = false
	game.catalog_fx.clear()


func _collect(ids: Array) -> void:
	for tile_id in ids:
		game._tileclub_collect_id(int(tile_id))


func _capture_stable_and_blocked() -> void:
	_open(2)
	await _wait(0.28)
	_save_state("00-stable-state")
	await _save_frame("00-stable-seven-family")
	_open()
	await _save_frame("01-blocked-intent")
	game._tileclub_collect_id(0)
	_save_state("blocked-state")
	await _wait(0.055)
	await _save_frame("02-blocked-impact")
	await _wait(0.17)
	await _save_frame("03-blocked-settle")
	await _wait(0.31)
	await _save_frame("04-blocked-recovery")


func _capture_collect() -> void:
	_open()
	await _save_frame("05-collect-intent")
	game._tileclub_collect_id(2)
	_save_state("collect-state")
	await _wait(0.035)
	await _save_frame("06-collect-lift")
	await _wait(0.14)
	await _save_frame("07-collect-travel")
	await _wait(0.23)
	await _save_frame("08-collect-settle")
	await _wait(0.30)
	await _save_frame("09-collect-recovery")


func _capture_match() -> void:
	_open(2)
	_collect([2, 0, 5, 8, 11, 14])
	game.catalog_fx.clear()
	game.tileclub_object_fx.clear()
	await _save_frame("10-match-intent")
	game._tileclub_collect_id(1)
	_save_state("match-state")
	await _capture_motion(MATCH_MOTION_OUTPUT, "match", 32)


func _capture_layer_clear() -> void:
	_open()
	_collect([2, 0, 1, 5, 3, 4, 8, 6, 7])
	game.catalog_fx.clear()
	game.tileclub_object_fx.clear()
	await _save_frame("16-layer-intent")
	game._tileclub_collect_id(11)
	_save_state("layer-state")
	await _wait(0.06)
	await _save_frame("17-layer-impact")
	await _wait(0.22)
	await _save_frame("18-layer-exposed")
	await _wait(0.48)
	await _save_frame("19-layer-recovery")


func _capture_risk_and_full() -> void:
	_open(2)
	_collect([2, 5, 8, 11])
	game.catalog_fx.clear()
	game.tileclub_object_fx.clear()
	await _save_frame("20-risk5-intent")
	game._tileclub_collect_id(14)
	_save_state("risk5-state")
	await _wait(0.07)
	await _save_frame("21-risk5-impact")
	await _wait(0.20)
	await _save_frame("22-risk5-settle")
	await _wait(0.40)
	game.catalog_fx.clear()
	game.tileclub_object_fx.clear()
	await _save_frame("23-risk6-intent")
	game._tileclub_collect_id(17)
	_save_state("risk6-state")
	await _wait(0.07)
	await _save_frame("24-risk6-impact")
	await _wait(0.22)
	await _save_frame("25-risk6-settle")
	await _wait(0.44)
	game.catalog_fx.clear()
	game.tileclub_object_fx.clear()
	await _save_frame("26-full-intent")
	game._tileclub_collect_id(20)
	_save_state("full-state")
	await _capture_motion(FULL_MOTION_OUTPUT, "full", 40)


func _capture_complete() -> void:
	_open()
	var solution: Array[int] = game.tileclub_model.solution_for_level()
	for index in range(solution.size() - 1):
		game._tileclub_collect_id(solution[index])
	game.catalog_fx.clear()
	game.tileclub_object_fx.clear()
	await _save_frame("32-clear-intent")
	game._tileclub_collect_id(solution.back())
	_save_state("clear-state")
	await _capture_motion(CLEAR_MOTION_OUTPUT, "clear", 44)


func _capture_reduced_effects() -> void:
	_open(2, true)
	await _save_frame("38-reduced-stable")
	game._tileclub_collect_id(2)
	_save_state("reduced-collect-state")
	await _wait(0.06)
	await _save_frame("39-reduced-authoritative-result")
	await _wait(0.30)
	await _save_frame("40-reduced-settled")
	game._set_tileclub_reduced_effects(false)


func _capture_motion(folder: String, kind: String, frame_count: int) -> void:
	var started: float = game.elapsed
	game.set_process(false)
	for frame in range(frame_count):
		game.elapsed = started + float(frame) / 30.0
		game._prune_catalog_fx()
		game.queue_redraw()
		await process_frame
		if kind == "match":
			if frame == 2: await _save_frame("11-match-anticipation")
			elif frame == 7: await _save_frame("12-match-impact")
			elif frame == 15: await _save_frame("13-match-cinch")
			elif frame == 24: await _save_frame("14-match-settle")
			elif frame == frame_count - 1: await _save_frame("15-match-recovery")
		elif kind == "full":
			if frame == 3: await _save_frame("27-full-impact")
			elif frame == 12: await _save_frame("28-full-tension")
			elif frame == 23: await _save_frame("29-full-result-entrance")
			elif frame == 32: await _save_frame("30-full-result-stable")
			elif frame == frame_count - 1: await _save_frame("31-full-recovery")
		else:
			if frame == 3: await _save_frame("33-clear-impact")
			elif frame == 13: await _save_frame("34-clear-cinch")
			elif frame == 25: await _save_frame("35-clear-result-entrance")
			elif frame == 35: await _save_frame("36-clear-result-stable")
			elif frame == frame_count - 1: await _save_frame("37-clear-recovery")
		await _save_motion_frame(folder, frame)
	game.set_process(true)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame
	await process_frame


func _save_frame(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.webp" % [OUTPUT, stem])
	var error := image.save_webp(path, false, 0.94)
	if error != OK:
		push_error("Tile Club visual capture failed: %s" % path)


func _save_motion_frame(folder: String, frame: int) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/frame_%02d.webp" % [folder, frame])
	var error := image.save_webp(path, false, 0.92)
	if error != OK:
		push_error("Tile Club motion capture failed: %s" % path)


func _save_state(stem: String) -> void:
	var effect := {}
	if not game.catalog_fx.is_empty():
		var source: Dictionary = game.catalog_fx.back()
		effect = {
			"game_id":source.get("game_id", ""),
			"kind":source.get("kind", ""),
			"semantic":source.get("semantic", ""),
			"grade":source.get("grade", 0),
			"label":source.get("label", ""),
			"font_role":source.get("font_role", ""),
			"duration":source.get("duration", 0.0),
			"reduced_effects":source.get("reduced_effects", false),
		}
	var object_fx: Dictionary = game.tileclub_object_fx.duplicate(true)
	object_fx.erase("started")
	var report := {
		"game_id":game.game_id,
		"status":game.state.get("status", ""),
		"level_id":game.state.get("level_id", ""),
		"active_count":game.state.get("active_count", 0),
		"selectable_ids":game.state.get("selectable_ids", []),
		"tray":game.state.get("tray", []),
		"moves":game.state.get("moves", 0),
		"score":game.state.get("score", 0),
		"event":effect,
		"object_fx":object_fx,
		"presentation":game._tileclub_presentation_state(),
	}
	var path := ProjectSettings.globalize_path("%s/%s.json" % [OUTPUT, stem])
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
