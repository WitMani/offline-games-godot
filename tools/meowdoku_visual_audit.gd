extends SceneTree

const GAME_IDS := ["meowdoku"]
const OUTPUT := "user://meowdoku_visual_audit"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	await _wait(0.30)
	for id in GAME_IDS:
		await _audit_game(id)
	print("MEOWDOKU_VISUAL_AUDIT=%s" % ProjectSettings.globalize_path(OUTPUT))
	quit()


func _audit_game(id: String) -> void:
	var dir := "%s/%s" % [OUTPUT, id]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	game._open_game(id)
	game.has_transitioned = false
	await _wait(0.24)
	await _save_frame(dir, "01_stable")

	var target := Vector2i(2, 0)
	game._sudoku_tap(game.logic_game_presenter.cell_center(target))
	await _wait(0.04)
	await _save_frame(dir, "02_selection_intent")
	await _wait(0.24)
	await _save_frame(dir, "03_selection_settle")

	var solution: Array = game.state["solution"]
	game._sudoku_place(int(solution[target.y][target.x]))
	await _wait(0.10)
	await _save_frame(dir, "04_correct_impact")
	_save_state(dir, "correct_state")
	await _wait(0.54)
	await _save_frame(dir, "05_correct_settle")

	game._open_game(id)
	game.has_transitioned = false
	game.state["selected"] = [target.x, target.y]
	game.logic_game_presenter.select(target, game.elapsed)
	game._sudoku_place(1)
	await _wait(0.10)
	await _save_frame(dir, "06_error_impact")
	_save_state(dir, "error_state")
	await _wait(0.54)
	await _save_frame(dir, "07_error_settle")

	game._open_game(id)
	game.has_transitioned = false
	solution = game.state["solution"]
	for y in range(3):
		for x in range(3):
			game.state["board"][y][x] = solution[y][x]
	game.state["board"][0][2] = 0
	game.state["selected"] = [2, 0]
	game.logic_game_presenter.select(Vector2i(2, 0), game.elapsed)
	game._sudoku_place(int(solution[0][2]))
	await _wait(0.15)
	await _save_frame(dir, "08_block_impact")
	_save_state(dir, "block_state")
	await _wait(0.68)
	await _save_frame(dir, "09_block_settle")

	game._open_game(id)
	game.has_transitioned = false
	solution = game.state["solution"]
	game.state["board"] = solution.duplicate(true)
	game.state["board"][0][0] = 0
	game.state["selected"] = [0, 0]
	game.logic_game_presenter.select(Vector2i(0, 0), game.elapsed)
	game._sudoku_place(int(solution[0][0]))
	_save_state(dir, "complete_state")
	var motion_dir := "%s/complete_motion" % dir
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(motion_dir))
	# Drive the completion clock explicitly while encoding frames. Screenshot
	# compression is much slower than a render tick and must not advance the
	# event into the result card before the named impact/settle probes.
	var completion_started: float = game.logic_game_presenter.event_started
	game.set_process(false)
	for frame in range(30):
		game.elapsed = completion_started + float(frame) / 30.0
		game.queue_redraw()
		await process_frame
		if frame == 4:
			await _save_frame(dir, "10_complete_impact")
		elif frame == 20:
			await _save_frame(dir, "11_complete_settle")
		await _save_frame(motion_dir, "frame_%02d" % frame)
	game.elapsed = completion_started + 1.10
	game.queue_redraw()
	await process_frame
	await _save_frame(dir, "12_complete_result")
	game.set_process(true)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame
	await process_frame


func _save_frame(dir: String, stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := "%s/%s.webp" % [dir, stem]
	var error := image.save_webp(ProjectSettings.globalize_path(path), false, 0.94)
	if error != OK:
		push_error("Logic visual capture failed: %s" % path)


func _save_state(dir: String, stem: String) -> void:
	var effect := {}
	if not game.catalog_fx.is_empty():
		var source: Dictionary = game.catalog_fx.back()
		effect = {
			"game_id": source.get("game_id", ""),
			"kind": source.get("kind", ""),
			"grade": source.get("grade", 0),
			"label": source.get("label", ""),
			"font_role": source.get("font_role", ""),
		}
	var report := {
		"game_id": game.game_id,
		"status": game.state.get("status", ""),
		"moves": game.state.get("moves", 0),
		"mistakes": game.state.get("mistakes", 0),
		"score": game.state.get("score", 0),
		"selected": game.state.get("selected", []),
		"board": game.state.get("board", []),
		"event": effect,
		"presenter": game.logic_game_presenter.snapshot(game.elapsed),
	}
	var file := FileAccess.open(ProjectSettings.globalize_path("%s/%s.json" % [dir, stem]), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
