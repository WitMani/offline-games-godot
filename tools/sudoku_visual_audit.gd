extends SceneTree

const OUTPUT := "res://docs/audit/sudoku-v2/candidate"
const MOTION_OUTPUT := "res://docs/audit/sudoku-v2/candidate/continuous/frames"

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
	await _capture_correct()
	await _capture_erase()
	await _capture_error()
	await _capture_block()
	await _capture_completion()
	print("SUDOKU_VISUAL_AUDIT=%s" % ProjectSettings.globalize_path(OUTPUT))
	quit()


func _open() -> void:
	game._open_game("sudoku")
	game.has_transitioned = false


func _capture_stable_and_selection() -> void:
	_open()
	await _wait(0.24)
	await _save_frame("00-stable")
	var target := Vector2i(2, 0)
	game._sudoku_tap(game.logic_game_presenter.cell_center(target))
	await _wait(0.035)
	await _save_frame("01-selection-intent")
	await _wait(0.23)
	await _save_frame("02-selection-settle")
	_save_state("selection-state")


func _capture_correct() -> void:
	_open()
	var target := Vector2i(2, 0)
	var solution: Array = game.state["solution"]
	game._sudoku_tap(game.logic_game_presenter.cell_center(target))
	await _wait(0.035)
	await _save_frame("03-correct-intent")
	game._sudoku_place(int(solution[target.y][target.x]))
	await _wait(0.10)
	await _save_frame("04-correct-impact")
	_save_state("correct-state")
	await _wait(0.44)
	await _save_frame("05-correct-settle")
	await _wait(0.42)
	await _save_frame("06-correct-recovery")


func _capture_erase() -> void:
	_open()
	var target := Vector2i(0, 0)
	var solution: Array = game.state["solution"]
	game.state["board"][target.y][target.x] = solution[target.y][target.x]
	game.state["selected"] = [target.x, target.y]
	game.logic_game_presenter.select(target, game.elapsed)
	await _wait(0.035)
	await _save_frame("07-erase-intent")
	game._sudoku_place(0)
	await _wait(0.10)
	await _save_frame("08-erase-impact")
	_save_state("erase-state")
	await _wait(0.44)
	await _save_frame("09-erase-settle")
	await _wait(0.42)
	await _save_frame("10-erase-recovery")


func _capture_error() -> void:
	_open()
	var target := Vector2i(2, 0)
	game._sudoku_tap(game.logic_game_presenter.cell_center(target))
	await _wait(0.035)
	await _save_frame("11-error-intent")
	game._sudoku_place(1)
	await _wait(0.10)
	await _save_frame("12-error-impact")
	_save_state("error-state")
	await _wait(0.44)
	await _save_frame("13-error-settle")
	await _wait(0.42)
	await _save_frame("14-error-recovery")


func _capture_block() -> void:
	_open()
	var solution: Array = game.state["solution"]
	for y in range(3):
		for x in range(3):
			game.state["board"][y][x] = solution[y][x]
	game.state["board"][0][2] = 0
	game.state["selected"] = [2, 0]
	game.logic_game_presenter.select(Vector2i(2, 0), game.elapsed)
	await _wait(0.035)
	await _save_frame("15-block-intent")
	game._sudoku_place(int(solution[0][2]))
	await _wait(0.15)
	await _save_frame("16-block-impact")
	_save_state("block-state")
	await _wait(0.43)
	await _save_frame("17-block-settle")
	await _wait(0.46)
	await _save_frame("18-block-recovery")


func _capture_completion() -> void:
	_open()
	var solution: Array = game.state["solution"]
	game.state["board"] = solution.duplicate(true)
	game.state["board"][0][0] = 0
	game.state["selected"] = [0, 0]
	game.logic_game_presenter.select(Vector2i(0, 0), game.elapsed)
	await _wait(0.035)
	await _save_frame("19-complete-intent")
	game._sudoku_place(int(solution[0][0]))
	_save_state("complete-state")
	var started: float = game.logic_game_presenter.event_started
	game.set_process(false)
	for frame in range(36):
		game.elapsed = started + float(frame) / 30.0
		game._prune_catalog_fx()
		game.queue_redraw()
		await process_frame
		if frame == 3:
			await _save_frame("20-complete-impact")
		elif frame == 17:
			await _save_frame("21-complete-settle")
		elif frame == 28:
			await _save_frame("22-complete-recovery-result")
		await _save_motion_frame(frame)
	game.elapsed = started + 1.22
	game._prune_catalog_fx()
	game.queue_redraw()
	await process_frame
	await _save_frame("23-result-stable")
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
		push_error("Sudoku visual capture failed: %s" % path)


func _save_motion_frame(frame: int) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/frame_%02d.webp" % [MOTION_OUTPUT, frame])
	var error := image.save_webp(path, false, 0.92)
	if error != OK:
		push_error("Sudoku motion capture failed: %s" % path)


func _save_state(stem: String) -> void:
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
	var path := ProjectSettings.globalize_path("%s/%s.json" % [OUTPUT, stem])
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()

