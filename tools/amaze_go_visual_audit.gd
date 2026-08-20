extends SceneTree

const OUTPUT := "res://docs/audit/amaze-go-v2/candidate"
const STEP_MOTION_OUTPUT := "user://amaze-go-v2-step-motion"
const COMPLETE_MOTION_OUTPUT := "user://amaze-go-v2-complete-motion"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STEP_MOTION_OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(COMPLETE_MOTION_OUTPUT))
	await _wait(0.30)
	await _capture_stable_and_step()
	await _capture_wall_rejection()
	await _capture_waypoint()
	await _capture_completion()
	print("AMAZE_GO_VISUAL_AUDIT=%s" % ProjectSettings.globalize_path(OUTPUT))
	print("AMAZE_GO_STEP_MOTION=%s" % ProjectSettings.globalize_path(STEP_MOTION_OUTPUT))
	print("AMAZE_GO_COMPLETE_MOTION=%s" % ProjectSettings.globalize_path(COMPLETE_MOTION_OUTPUT))
	quit()


func _open() -> void:
	game._open_game("amaze_go")
	game.has_transitioned = false


func _capture_stable_and_step() -> void:
	_open()
	await _wait(0.30)
	await _save_frame("00-stable")
	game._amaze_step(Vector2i.RIGHT)
	_save_state("step-state")
	var started: float = game.motion_started
	game.set_process(false)
	for frame in range(20):
		game.elapsed = started + float(frame) / 30.0
		game._prune_catalog_fx()
		game.queue_redraw()
		await process_frame
		if frame == 1:
			await _save_frame("01-step-intent")
		elif frame == 4:
			await _save_frame("02-step-travel")
		elif frame == 8:
			await _save_frame("03-step-impact")
		elif frame == 13:
			await _save_frame("04-step-settle")
		elif frame == 19:
			await _save_frame("05-step-recovery")
		await _save_motion_frame(STEP_MOTION_OUTPUT, frame)
	game.set_process(true)


func _capture_wall_rejection() -> void:
	_open()
	game.state["player"] = [0, 4]
	game.amaze_go_route.clear()
	game.amaze_go_route.append(Vector2i(0, 4))
	game.queue_redraw()
	await process_frame
	await _save_frame("06-wall-intent")
	game._amaze_step(Vector2i.RIGHT)
	_save_state("wall-state")
	await _wait(0.055)
	await _save_frame("07-wall-impact")
	await _wait(0.14)
	await _save_frame("08-wall-recoil")
	await _wait(0.34)
	await _save_frame("09-wall-recovery")


func _capture_waypoint() -> void:
	_open()
	for _step in range(4):
		game._amaze_step(Vector2i.RIGHT)
	game.catalog_fx.clear()
	game.motion_started = -10.0
	game.amaze_go_object_fx = {}
	game.queue_redraw()
	await process_frame
	await _save_frame("10-waypoint-intent")
	game._amaze_step(Vector2i.RIGHT)
	_save_state("waypoint-state")
	await _wait(0.07)
	await _save_frame("11-waypoint-travel")
	await _wait(0.15)
	await _save_frame("12-waypoint-impact")
	await _wait(0.24)
	await _save_frame("13-waypoint-settle")
	await _wait(0.40)
	await _save_frame("14-waypoint-recovery")


func _capture_completion() -> void:
	_open()
	var route := [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(4, 0), Vector2i(5, 0), Vector2i(5, 1), Vector2i(5, 2),
		Vector2i(5, 3), Vector2i(5, 4), Vector2i(4, 4), Vector2i(4, 5),
	]
	game.amaze_go_route.clear()
	for point in route:
		game.amaze_go_route.append(point)
		game.state["painted"][point.y][point.x] = true
	game.state["player"] = [4, 5]
	game.state["moves"] = 11
	game.state["score"] = 55
	game.state["streak"] = 11
	game.amaze_go_facing = Vector2i.RIGHT
	game.queue_redraw()
	await process_frame
	await _save_frame("15-complete-intent")
	game._amaze_step(Vector2i.RIGHT)
	_save_state("complete-state")
	var started := float(game.amaze_go_object_fx.get("started", game.elapsed))
	game.set_process(false)
	for frame in range(42):
		game.elapsed = started + float(frame) / 30.0
		game._prune_catalog_fx()
		game.queue_redraw()
		await process_frame
		if frame == 2:
			await _save_frame("16-complete-anticipation")
		elif frame == 7:
			await _save_frame("17-complete-impact")
		elif frame == 16:
			await _save_frame("18-complete-seal")
		elif frame == 25:
			await _save_frame("19-result-entrance")
		elif frame == 34:
			await _save_frame("20-result-stable")
		elif frame == 41:
			await _save_frame("21-result-recovery")
		await _save_motion_frame(COMPLETE_MOTION_OUTPUT, frame)
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
		push_error("Amaze GO visual capture failed: %s" % path)


func _save_motion_frame(folder: String, frame: int) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/frame_%02d.webp" % [folder, frame])
	var error := image.save_webp(path, false, 0.92)
	if error != OK:
		push_error("Amaze GO motion capture failed: %s" % path)


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
	var object_fx: Dictionary = game.amaze_go_object_fx.duplicate(true)
	object_fx.erase("started")
	var route: Array = []
	for point in game.amaze_go_route:
		route.append([point.x, point.y])
	var report := {
		"game_id":game.game_id,
		"status":game.state.get("status", ""),
		"player":game.state.get("player", []),
		"painted_count":game._painted_count(),
		"moves":game.state.get("moves", 0),
		"score":game.state.get("score", 0),
		"route":route,
		"motion_kind":game.motion_kind,
		"event":effect,
		"object_fx":object_fx,
	}
	var path := ProjectSettings.globalize_path("%s/%s.json" % [OUTPUT, stem])
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
