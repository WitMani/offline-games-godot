extends SceneTree

const OUTPUT := "res://docs/audit/mahjong-v2/candidate"
const MOTION_OUTPUT := "user://mahjong-v2-motion"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MOTION_OUTPUT))
	await _wait(0.30)
	await _capture_stable_and_selection()
	await _capture_mismatch()
	await _capture_pair()
	await _capture_completion()
	print("MAHJONG_VISUAL_AUDIT=%s" % ProjectSettings.globalize_path(OUTPUT))
	print("MAHJONG_MOTION_FRAMES=%s" % ProjectSettings.globalize_path(MOTION_OUTPUT))
	quit()


func _open() -> void:
	game._open_game("mahjong")
	game.has_transitioned = false


func _capture_stable_and_selection() -> void:
	_open()
	await _wait(0.28)
	await _save_frame("00-stable")
	game._mahjong_tap(game._mahjong_tile_center(0))
	await _wait(0.035)
	await _save_frame("01-select-intent")
	_save_state("select-state")
	await _wait(0.12)
	await _save_frame("02-select-impact")
	await _wait(0.31)
	await _save_frame("03-select-settle")


func _capture_mismatch() -> void:
	_open()
	game._mahjong_tap(game._mahjong_tile_center(0))
	await _wait(0.035)
	await _save_frame("04-mismatch-intent")
	game._mahjong_tap(game._mahjong_tile_center(1))
	_save_state("mismatch-state")
	await _wait(0.075)
	await _save_frame("05-mismatch-impact")
	await _wait(0.24)
	await _save_frame("06-mismatch-settle")
	await _wait(0.38)
	await _save_frame("07-mismatch-recovery")


func _capture_pair() -> void:
	_open()
	game._mahjong_tap(game._mahjong_tile_center(0))
	await _wait(0.035)
	await _save_frame("08-pair-intent")
	game._mahjong_tap(game._mahjong_tile_center(10))
	_save_state("pair-state")
	await _wait(0.075)
	await _save_frame("09-pair-anticipation")
	await _wait(0.18)
	await _save_frame("10-pair-impact")
	await _wait(0.26)
	await _save_frame("11-pair-settle")
	await _wait(0.40)
	await _save_frame("12-pair-recovery")


func _capture_completion() -> void:
	_open()
	var removed: Array = []
	for index in range(20):
		if index not in [0, 10]:
			removed.append(index)
	game.state["removed"] = removed
	game.state["selected"] = 0
	game.mahjong_object_fx = {"kind":"select", "indices":[0], "value":1, "grade":1, "started":game.elapsed, "duration":0.48}
	game.queue_redraw()
	await process_frame
	await _save_frame("13-clear-intent")
	game._mahjong_tap(game._mahjong_tile_center(10))
	_save_state("clear-state")
	var started: float = game.mahjong_object_fx.get("started", game.elapsed)
	game.set_process(false)
	for frame in range(36):
		game.elapsed = started + float(frame) / 30.0
		game._prune_catalog_fx()
		game.queue_redraw()
		await process_frame
		if frame == 3:
			await _save_frame("14-clear-impact")
		elif frame == 14:
			await _save_frame("15-clear-settle")
		elif frame == 25:
			await _save_frame("16-result-entrance")
		elif frame == 35:
			await _save_frame("17-result-stable")
		await _save_motion_frame(frame)
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
		push_error("Mahjong visual capture failed: %s" % path)


func _save_motion_frame(frame: int) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/frame_%02d.webp" % [MOTION_OUTPUT, frame])
	var error := image.save_webp(path, false, 0.92)
	if error != OK:
		push_error("Mahjong motion capture failed: %s" % path)


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
	var object_fx: Dictionary = game.mahjong_object_fx.duplicate(true)
	object_fx.erase("started")
	var report := {
		"game_id":game.game_id,
		"status":game.state.get("status", ""),
		"tiles":game.state.get("tiles", []),
		"removed":game.state.get("removed", []),
		"selected":game.state.get("selected", -1),
		"moves":game.state.get("moves", 0),
		"mistakes":game.state.get("mistakes", 0),
		"score":game.state.get("score", 0),
		"event":effect,
		"object_fx":object_fx,
	}
	var path := ProjectSettings.globalize_path("%s/%s.json" % [OUTPUT, stem])
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
