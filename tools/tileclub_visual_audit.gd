extends SceneTree

const OUTPUT := "res://docs/audit/tileclub-v2/candidate"
const CLEAR_MOTION_OUTPUT := "user://tileclub-v2-clear-motion"
const FULL_MOTION_OUTPUT := "user://tileclub-v2-full-motion"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CLEAR_MOTION_OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FULL_MOTION_OUTPUT))
	await _wait(0.30)
	await _capture_stable_and_collect()
	await _capture_risk(5)
	await _capture_risk(6)
	await _capture_match()
	await _capture_full()
	await _capture_clear()
	print("TILECLUB_VISUAL_AUDIT=%s" % ProjectSettings.globalize_path(OUTPUT))
	print("TILECLUB_CLEAR_MOTION=%s" % ProjectSettings.globalize_path(CLEAR_MOTION_OUTPUT))
	print("TILECLUB_FULL_MOTION=%s" % ProjectSettings.globalize_path(FULL_MOTION_OUTPUT))
	quit()


func _open() -> void:
	game._open_game("tileclub")
	game.has_transitioned = false


func _capture_stable_and_collect() -> void:
	_open()
	await _wait(0.28)
	await _save_frame("00-stable")
	game.state["tiles"][0] = 1
	game._tileclub_tap(game._tileclub_tile_center(0))
	_save_state("collect-state")
	await _wait(0.035)
	await _save_frame("01-collect-intent")
	await _wait(0.14)
	await _save_frame("02-collect-travel")
	await _wait(0.23)
	await _save_frame("03-collect-settle")
	await _wait(0.32)
	await _save_frame("04-collect-recovery")


func _capture_risk(tray_count: int) -> void:
	_open()
	game.state["tray"] = [1, 2, 3, 4] if tray_count == 5 else [1, 2, 3, 4, 5]
	game.state["tiles"][0] = tray_count
	game.queue_redraw()
	await process_frame
	await _save_frame("05-risk5-intent" if tray_count == 5 else "09-risk6-intent")
	game._tileclub_tap(game._tileclub_tile_center(0))
	_save_state("risk5-state" if tray_count == 5 else "risk6-state")
	await _wait(0.07)
	await _save_frame("06-risk5-impact" if tray_count == 5 else "10-risk6-impact")
	await _wait(0.19)
	await _save_frame("07-risk5-settle" if tray_count == 5 else "11-risk6-settle")
	await _wait(0.42)
	await _save_frame("08-risk5-recovery" if tray_count == 5 else "12-risk6-recovery")


func _capture_match() -> void:
	_open()
	game.state["tray"] = [1, 1]
	game.state["tiles"][0] = 1
	game.queue_redraw()
	await process_frame
	await _save_frame("13-match-intent")
	game._tileclub_tap(game._tileclub_tile_center(0))
	_save_state("match-state")
	await _wait(0.055)
	await _save_frame("14-match-anticipation")
	await _wait(0.16)
	await _save_frame("15-match-impact")
	await _wait(0.25)
	await _save_frame("16-match-settle")
	await _wait(0.52)
	await _save_frame("17-match-recovery")


func _capture_full() -> void:
	_open()
	game.state["tray"] = [1, 2, 3, 4, 5, 6]
	game.state["tiles"][0] = 7
	game.queue_redraw()
	await process_frame
	await _save_frame("18-full-intent")
	game._tileclub_tap(game._tileclub_tile_center(0))
	_save_state("full-state")
	await _capture_terminal_motion(FULL_MOTION_OUTPUT, "full")


func _capture_clear() -> void:
	_open()
	var tiles: Array = []
	for _index in range(49):
		tiles.append(0)
	tiles[0] = 1
	game.state["tiles"] = tiles
	game.state["tray"] = [1, 1]
	game.queue_redraw()
	await process_frame
	await _save_frame("23-clear-intent")
	game._tileclub_tap(game._tileclub_tile_center(0))
	_save_state("clear-state")
	await _capture_terminal_motion(CLEAR_MOTION_OUTPUT, "clear")


func _capture_terminal_motion(folder: String, kind: String) -> void:
	var started: float = game.tileclub_object_fx.get("started", game.elapsed)
	game.set_process(false)
	for frame in range(42):
		game.elapsed = started + float(frame) / 30.0
		game._prune_catalog_fx()
		game.queue_redraw()
		await process_frame
		if frame == 3:
			await _save_frame("19-full-impact" if kind == "full" else "24-clear-impact")
		elif frame == 14:
			await _save_frame("20-full-settle" if kind == "full" else "25-clear-settle")
		elif frame == 25:
			await _save_frame("21-full-result-entrance" if kind == "full" else "26-clear-result-entrance")
		elif frame == 35:
			await _save_frame("22-full-result-stable" if kind == "full" else "27-clear-result-stable")
		elif frame == 41 and kind == "clear":
			await _save_frame("28-clear-recovery")
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
			"grade":source.get("grade", 0),
			"label":source.get("label", ""),
			"font_role":source.get("font_role", ""),
			"duration":source.get("duration", 0.0),
		}
	var object_fx: Dictionary = game.tileclub_object_fx.duplicate(true)
	object_fx.erase("started")
	var report := {
		"game_id":game.game_id,
		"status":game.state.get("status", ""),
		"tiles":game.state.get("tiles", []),
		"tray":game.state.get("tray", []),
		"moves":game.state.get("moves", 0),
		"score":game.state.get("score", 0),
		"motion_value":game.motion_value,
		"event":effect,
		"object_fx":object_fx,
	}
	var path := ProjectSettings.globalize_path("%s/%s.json" % [OUTPUT, stem])
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
