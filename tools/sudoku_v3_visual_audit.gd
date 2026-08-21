extends SceneTree

const OUTPUT := "res://docs/audit/sudoku-v3/candidate"
const ERROR_FRAMES := "user://sudoku-v3-error-frames"
const COMPLETE_FRAMES := "user://sudoku-v3-complete-frames"
const ERROR_FRAME_COUNT := 24
const COMPLETE_FRAME_COUNT := 42

var game: Control
var captures: Array[String] = []
var snapshots: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ERROR_FRAMES))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(COMPLETE_FRAMES))
	await _render(3)
	await _capture_stable_selection()
	await _capture_correct()
	await _capture_notes_hint_undo()
	await _capture_error_continuous()
	await _capture_repeated_error_boundary()
	await _capture_block_completion()
	await _capture_completion_continuous()
	await _capture_reduced_effects()
	_capture_restart_recovery_state()
	_write_evidence()
	print("SUDOKU_V3_VISUAL_AUDIT=%s" % ProjectSettings.globalize_path(OUTPUT))
	print("SUDOKU_V3_ERROR_FRAMES=%s" % ProjectSettings.globalize_path(ERROR_FRAMES))
	print("SUDOKU_V3_COMPLETE_FRAMES=%s" % ProjectSettings.globalize_path(COMPLETE_FRAMES))
	for player in game.sfx_players:
		player.stop()
	game.queue_free()
	await process_frame
	quit()


func _open() -> void:
	game.sudoku_reduced_effects = false
	game._open_game("sudoku")
	game.has_transitioned = false
	game.catalog_fx.clear()


func _capture_stable_selection() -> void:
	_open()
	await _render(2)
	await _save_frame("00-stable-ordinary")
	var cell := _event_safe_editable()
	game._sudoku_tap(game.logic_game_presenter.cell_center(cell))
	var started: float = game.logic_game_presenter.selected_started
	await _pin_time(started + 0.035)
	await _save_frame("01-selection-intent")
	await _pin_time(started + 0.13)
	await _save_frame("02-selection-impact")
	await _pin_time(started + 0.34)
	await _save_frame("03-selection-settle")
	_save_state("selection", {"cell":[cell.x, cell.y]})
	game.set_process(true)


func _capture_correct() -> void:
	_open()
	var cell := _event_safe_editable()
	game._sudoku_tap(game.logic_game_presenter.cell_center(cell))
	await _render(1)
	await _save_frame("04-correct-intent")
	game._sudoku_place(int(game.state.solution[cell.y][cell.x]))
	_save_state("correct", {"cell":[cell.x, cell.y]})
	var started: float = game.logic_game_presenter.event_started
	await _pin_time(started + 0.10)
	await _save_frame("05-correct-impact")
	await _pin_time(started + 0.46)
	await _save_frame("06-correct-settle")
	await _pin_time(started + 0.82)
	await _save_frame("07-correct-recovery")
	game.set_process(true)


func _capture_notes_hint_undo() -> void:
	_open()
	var cell := _event_safe_editable()
	var value := int(game.state.solution[cell.y][cell.x])
	game._sudoku_tap(game.logic_game_presenter.cell_center(cell))
	game._sudoku_toggle_notes()
	game._sudoku_place(value)
	var note_started: float = game.logic_game_presenter.event_started
	await _pin_time(note_started + 0.10)
	await _save_frame("08-note-impact")
	await _pin_time(note_started + 0.58)
	await _save_frame("09-note-stable")
	_save_state("note", {"cell":[cell.x, cell.y], "value":value})
	game.set_process(true)
	game._sudoku_toggle_notes()
	game._sudoku_hint()
	_save_state("hint", {"cell":[cell.x, cell.y], "value":value})
	var hint_started: float = game.logic_game_presenter.event_started
	await _pin_time(hint_started + 0.13)
	await _save_frame("10-hint-impact")
	await _pin_time(hint_started + 0.76)
	await _save_frame("11-hint-settle")
	game.set_process(true)
	game._sudoku_undo()
	_save_state("undo", {"cell":[cell.x, cell.y]})
	var undo_started: float = game.logic_game_presenter.event_started
	await _pin_time(undo_started + 0.12)
	await _save_frame("12-undo-impact")
	await _pin_time(undo_started + 0.60)
	await _save_frame("13-undo-settle")
	game.set_process(true)


func _capture_error_continuous() -> void:
	_open()
	var cell := _event_safe_editable()
	var wrong_value := (int(game.state.solution[cell.y][cell.x]) % 9) + 1
	game._sudoku_tap(game.logic_game_presenter.cell_center(cell))
	await _render(1)
	await _save_frame("14-error-intent")
	game._sudoku_place(wrong_value)
	_save_state("error", {"cell":[cell.x, cell.y], "wrong_value":wrong_value})
	var started: float = game.logic_game_presenter.event_started
	game.set_process(false)
	for frame in range(ERROR_FRAME_COUNT):
		await _pin_time(started + float(frame) / 30.0)
		await _save_motion_frame(ERROR_FRAMES, frame)
		if frame == 3:
			await _save_frame("15-error-impact")
		elif frame == 10:
			await _save_frame("16-error-settle")
		elif frame == 23:
			await _save_frame("17-error-persistent")
	game.set_process(true)


func _capture_repeated_error_boundary() -> void:
	_open()
	var cell := _event_safe_editable()
	var correct := int(game.state.solution[cell.y][cell.x])
	var wrong_a := (correct % 9) + 1
	var wrong_b := ((correct + 1) % 9) + 1
	game.sudoku_model.select(cell)
	game._sync_sudoku_state()
	game._sudoku_place(wrong_a)
	game.elapsed += 0.11
	game._sudoku_place(wrong_b)
	_save_state("repeated-error", {"cell":[cell.x, cell.y], "mistakes_expected":2, "effect_cap":12})
	var started: float = game.logic_game_presenter.event_started
	await _pin_time(started + 0.12)
	await _save_frame("18-repeated-error-impact")
	await _pin_time(started + 0.74)
	await _save_frame("19-repeated-error-stable")
	game.set_process(true)


func _capture_block_completion() -> void:
	_open()
	var cell := _event_safe_editable()
	var block := int(cell.y / 3) * 3 + int(cell.x / 3)
	var start_x := (block % 3) * 3
	var start_y := int(block / 3) * 3
	for y in range(start_y, start_y + 3):
		for x in range(start_x, start_x + 3):
			game.sudoku_model.board[y][x] = game.sudoku_model.solution[y][x]
	game.sudoku_model.board[cell.y][cell.x] = 0
	game.sudoku_model.select(cell)
	game._sync_sudoku_state()
	game.logic_game_presenter.select(cell, game.elapsed)
	await _render(1)
	await _save_frame("20-block-intent")
	game._sudoku_place(int(game.state.solution[cell.y][cell.x]))
	_save_state("block", {"cell":[cell.x, cell.y], "block":block})
	var started: float = game.logic_game_presenter.event_started
	await _pin_time(started + 0.15)
	await _save_frame("21-block-impact")
	await _pin_time(started + 0.58)
	await _save_frame("22-block-settle")
	await _pin_time(started + 1.02)
	await _save_frame("23-block-persistent")
	game.set_process(true)


func _capture_completion_continuous() -> void:
	_open()
	var cell := _event_safe_editable()
	game.sudoku_model.board = game.sudoku_model.solution.duplicate(true)
	game.sudoku_model.board[cell.y][cell.x] = 0
	game.sudoku_model.wrong = _bool_grid(false)
	game.sudoku_model.notes = _int_grid(0)
	game.sudoku_model.history.clear()
	game.sudoku_model.status = "playing"
	game.sudoku_model.moves = 0
	game.sudoku_model.select(cell)
	game._sync_sudoku_state()
	game.logic_game_presenter.select(cell, game.elapsed)
	await _render(1)
	await _save_frame("24-complete-intent")
	game._sudoku_place(int(game.state.solution[cell.y][cell.x]))
	_save_state("complete", {"cell":[cell.x, cell.y]})
	var started: float = game.logic_game_presenter.event_started
	game.set_process(false)
	for frame in range(COMPLETE_FRAME_COUNT):
		await _pin_time(started + float(frame) / 30.0)
		await _save_motion_frame(COMPLETE_FRAMES, frame)
		if frame == 3:
			await _save_frame("25-complete-impact")
		elif frame == 16:
			await _save_frame("26-complete-settle")
		elif frame == 27:
			await _save_frame("27-result-entrance")
		elif frame == 41:
			await _save_frame("28-result-stable")
	game.set_process(true)


func _capture_reduced_effects() -> void:
	_open()
	game.sudoku_reduced_effects = true
	game._sync_sudoku_state()
	var cell := _event_safe_editable()
	var wrong_value := (int(game.state.solution[cell.y][cell.x]) % 9) + 1
	game.sudoku_model.select(cell)
	game._sync_sudoku_state()
	game._sudoku_place(wrong_value)
	var started: float = game.logic_game_presenter.event_started
	await _pin_time(started + 0.10)
	await _save_frame("29-reduced-error")
	_save_state("reduced-error", {"cell":[cell.x, cell.y], "wrong_value":wrong_value})
	game.sudoku_reduced_effects = false
	game.set_process(true)


func _capture_restart_recovery_state() -> void:
	_open()
	var cell := _event_safe_editable()
	var wrong_value := (int(game.state.solution[cell.y][cell.x]) % 9) + 1
	game.sudoku_model.select(cell)
	game._sync_sudoku_state()
	game._sudoku_place(wrong_value)
	var saved: Dictionary = game.state.duplicate(true)
	game._reset_current()
	var restarted: Dictionary = game.state.duplicate(true)
	var restored: bool = game._restore_sudoku_snapshot(saved)
	snapshots["restart-recovery"] = {
		"saved_wrong":int(saved.board[cell.y][cell.x]),
		"restart_board_equals_given":restarted.board == restarted.given,
		"restart_moves":restarted.moves,
		"restore_accepted":restored,
		"restored_wrong":int(game.state.board[cell.y][cell.x]),
		"restored_wrong_mark":bool(game.state.wrong[cell.y][cell.x]),
	}


func _event_safe_editable() -> Vector2i:
	for block in range(9):
		var candidates: Array[Vector2i] = []
		var start_x := (block % 3) * 3
		var start_y := int(block / 3) * 3
		for y in range(start_y, start_y + 3):
			for x in range(start_x, start_x + 3):
				if int(game.state.given[y][x]) == 0:
					candidates.append(Vector2i(x, y))
		if candidates.size() >= 2:
			return candidates[0]
	return Vector2i.ZERO


func _pin_time(value: float) -> void:
	game.set_process(false)
	game.elapsed = value
	game._prune_catalog_fx()
	game.queue_redraw()
	await _render(1)


func _render(count: int) -> void:
	for _index in range(count):
		await process_frame


func _save_frame(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var relative := "%s.webp" % stem
	var path := ProjectSettings.globalize_path("%s/%s" % [OUTPUT, relative])
	if image.save_webp(path, false, 0.94) != OK:
		push_error("Sudoku v3 visual capture failed: %s" % path)
	else:
		captures.append(relative)


func _save_motion_frame(folder: String, frame: int) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/frame_%03d.webp" % [folder, frame])
	if image.save_webp(path, false, 0.92) != OK:
		push_error("Sudoku v3 motion capture failed: %s" % path)


func _save_state(key: String, extra: Dictionary = {}) -> void:
	var event := {}
	if not game.catalog_fx.is_empty():
		var source: Dictionary = game.catalog_fx.back()
		event = {
			"kind":source.get("kind", ""),
			"grade":source.get("grade", 0),
			"label":source.get("label", ""),
			"font_role":source.get("font_role", ""),
		}
	var snapshot := {
		"status":game.state.get("status", ""),
		"moves":game.state.get("moves", 0),
		"mistakes":game.state.get("mistakes", 0),
		"hints_remaining":game.state.get("hints_remaining", 0),
		"notes_mode":game.state.get("notes_mode", false),
		"reduced_effects":game.state.get("reduced_effects", false),
		"selected":game.state.get("selected", []),
		"board":game.state.get("board", []),
		"wrong":game.state.get("wrong", []),
		"notes":game.state.get("notes", []),
		"event":event,
		"presenter":game.logic_game_presenter.snapshot(game.elapsed),
	}
	snapshot.merge(extra, true)
	snapshots[key] = snapshot


func _write_evidence() -> void:
	var evidence := {
		"schema":"sudoku-v3-visual-evidence/v1",
		"scope":"sudoku only",
		"viewport":[540, 960],
		"language":"zh-CN",
		"effects_modes":["full", "prefers-reduced-motion fallback"],
		"captures":captures,
		"matched_events":{
			"ordinary_stable":["00-stable-ordinary.webp"],
			"selection":["01-selection-intent.webp", "02-selection-impact.webp", "03-selection-settle.webp"],
			"correct":["04-correct-intent.webp", "05-correct-impact.webp", "06-correct-settle.webp", "07-correct-recovery.webp"],
			"notes_hint_undo":["08-note-impact.webp", "09-note-stable.webp", "10-hint-impact.webp", "11-hint-settle.webp", "12-undo-impact.webp", "13-undo-settle.webp"],
			"error":["14-error-intent.webp", "15-error-impact.webp", "16-error-settle.webp", "17-error-persistent.webp"],
			"repeated_error":["18-repeated-error-impact.webp", "19-repeated-error-stable.webp"],
			"block_complete":["20-block-intent.webp", "21-block-impact.webp", "22-block-settle.webp", "23-block-persistent.webp"],
			"board_complete":["24-complete-intent.webp", "25-complete-impact.webp", "26-complete-settle.webp", "27-result-entrance.webp", "28-result-stable.webp"],
			"reduced_effects":["29-reduced-error.webp"],
		},
		"continuous":{
			"error":{"frames":ERROR_FRAME_COUNT, "fps":30, "source":ProjectSettings.globalize_path(ERROR_FRAMES)},
			"completion":{"frames":COMPLETE_FRAME_COUNT, "fps":30, "source":ProjectSettings.globalize_path(COMPLETE_FRAMES)},
		},
		"signature_asset":{
			"path":"res://assets/art/logic/gag-v1/sudoku_compass_reward.png",
			"sha256":FileAccess.get_sha256("res://assets/art/logic/gag-v1/sudoku_compass_reward.png"),
			"ordinary_runtime_binding":"logic_game_presenter.draw_header_badge",
		},
		"completion_audio":{
			"path":"res://assets/audio/logic/gag-v1/sudoku_complete_reward.ogg",
			"sha256":FileAccess.get_sha256("res://assets/audio/logic/gag-v1/sudoku_complete_reward.ogg"),
			"runtime_binding":"_play_logic_event_sfx(logic_complete grade 4)",
		},
		"state_snapshots":snapshots,
	}
	var path := ProjectSettings.globalize_path("%s/evidence.json" % OUTPUT)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(evidence, "  ") + "\n")
		file.close()


func _int_grid(value: int) -> Array:
	var grid: Array = []
	for _y in range(9):
		grid.append([value, value, value, value, value, value, value, value, value])
	return grid


func _bool_grid(value: bool) -> Array:
	var grid: Array = []
	for _y in range(9):
		grid.append([value, value, value, value, value, value, value, value, value])
	return grid
