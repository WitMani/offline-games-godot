extends SceneTree

const OUTPUT := "res://docs/audit/tileclub-v3/stage0"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	await _wait(0.18)
	_open(2)
	await _wait(0.15)
	await _save_frame("00-layered-stable")
	_save_state("00-layered-stable")
	game._tileclub_collect_id(0)
	await _wait(0.12)
	await _save_frame("01-covered-reject")
	_save_state("01-covered-reject")
	_open(2)
	for tile_id in [2, 0, 5, 8, 11, 14, 1]:
		game._tileclub_collect_id(tile_id)
	await _wait(0.14)
	await _save_frame("02-triple-impact")
	_save_state("02-triple-impact")
	_open()
	for tile_id in [2, 0, 1, 5, 3, 4, 8, 6, 7, 11]:
		game._tileclub_collect_id(tile_id)
	await _wait(0.14)
	await _save_frame("03-layer-clear")
	_save_state("03-layer-clear")
	_open(2)
	for tile_id in [2, 5, 8, 11, 14, 17]:
		game._tileclub_collect_id(tile_id)
	await _wait(0.14)
	await _save_frame("04-near-full")
	_save_state("04-near-full")
	game._tileclub_collect_id(20)
	await _wait(0.15)
	await _save_frame("05-full-impact")
	_save_state("05-full-impact")
	await _wait(0.92)
	await _save_frame("06-full-result")
	_open()
	for tile_id in game.tileclub_model.solution_for_level():
		game._tileclub_collect_id(tile_id)
	await _wait(0.16)
	await _save_frame("07-complete-impact")
	_save_state("07-complete-impact")
	await _wait(0.98)
	await _save_frame("08-complete-result")
	_save_state("08-complete-result")
	game._clear_tileclub_checkpoint()
	print("TILECLUB_STAGE0_VISUAL_AUDIT=%s" % ProjectSettings.globalize_path(OUTPUT))
	quit()


func _open(level := 0) -> void:
	game._clear_tileclub_checkpoint()
	game._open_game("tileclub")
	if level != 0:
		game.tileclub_level_index = level
		game._start_game_state()
		game._build_game_buttons()
	game.has_transitioned = false
	game.catalog_fx.clear()
	game.tileclub_object_fx.clear()
	game.motion_started = -10.0
	game.feedback_until = -10.0


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
		push_error("Tile Club Stage 0 visual capture failed: %s" % path)


func _save_state(stem: String) -> void:
	var event: Dictionary = {}
	if not game.catalog_fx.is_empty():
		var source: Dictionary = game.catalog_fx.back()
		for key in ["kind", "semantic", "grade", "label", "font_role", "tile_id", "value", "matched_indices", "newly_exposed", "cleared_layers", "tray_count", "remaining_slots"]:
			if source.has(key):
				event[key] = source[key]
	var report := {
		"game_id":"tileclub",
		"rules_version":game.state.get("rules_version", ""),
		"level_id":game.state.get("level_id", ""),
		"status":game.state.get("status", ""),
		"active_count":game.state.get("active_count", 0),
		"selectable_ids":game.state.get("selectable_ids", []),
		"tray":game.state.get("tray", []),
		"tray_capacity":game.state.get("tray_capacity", 0),
		"moves":game.state.get("moves", 0),
		"matches":game.state.get("matches", 0),
		"score":game.state.get("score", 0),
		"last_outcome":game.tileclub_last_outcome,
		"event":event,
	}
	var path := ProjectSettings.globalize_path("%s/%s.json" % [OUTPUT, stem])
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
