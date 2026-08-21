extends SceneTree

const MODEL = preload("res://models/merge2248_model.gd")
const SAVE_PATH := "user://merge2248_persistence_smoke_v4.json"

var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_test_save()
	var first := await _new_game()
	first.merge2248_model.reset(9182, MODEL.MODE_HARD, false)
	first.merge2248_model.board = _fixture_board(6)
	first._sync_merge2248_state()
	var a: Vector2 = first._merge2248_cell_center(Vector2i(0, 5))
	var b: Vector2 = first._merge2248_cell_center(Vector2i(1, 5))
	_expect(first._merge2248_begin_at(a), "first_begin")
	first._merge2248_extend_at(b)
	first._merge2248_release()
	_expect(FileAccess.file_exists(SAVE_PATH), "save_created_after_move")
	var moved_payload: Dictionary = first.merge2248_model.serialize()
	first.queue_free()
	await process_frame

	var restored := await _new_game()
	var restored_payload: Dictionary = restored.merge2248_model.serialize()
	if restored_payload != moved_payload:
		print("MERGE2248_PERSISTENCE_EXPECTED=%s" % JSON.stringify(moved_payload))
		print("MERGE2248_PERSISTENCE_ACTUAL=%s" % JSON.stringify(restored_payload))
	_expect(restored_payload == moved_payload, "disk_round_trip_exact")
	_expect(str(restored.state.mode) == MODEL.MODE_HARD and restored.state.board.size() == 6, "mode_and_rows_restored")
	_expect(str(restored.state.score) == "4" and int(restored.state.moves) == 1, "score_and_moves_restored")
	_expect(bool(restored.state.can_undo), "undo_restored")
	restored._merge2248_undo()
	var undone_payload: Dictionary = restored.merge2248_model.serialize()
	_expect(str(restored.state.score) == "0" and int(restored.state.moves) == 0, "disk_undo_applied")
	restored.queue_free()
	await process_frame

	var undo_reload := await _new_game()
	_expect(undo_reload.merge2248_model.serialize() == undone_payload, "undone_state_persisted")
	var best_before_restart := str(undo_reload.state.all_time)
	undo_reload._reset_current()
	_expect(str(undo_reload.state.mode) == MODEL.MODE_HARD and undo_reload.state.board.size() == 6, "restart_keeps_mode")
	_expect(str(undo_reload.state.score) == "0" and str(undo_reload.state.all_time) == best_before_restart, "restart_keeps_all_time")
	var restarted_payload: Dictionary = undo_reload.merge2248_model.serialize()
	undo_reload.queue_free()
	await process_frame

	var restart_reload := await _new_game()
	_expect(restart_reload.merge2248_model.serialize() == restarted_payload, "restart_persisted")
	restart_reload.queue_free()
	await process_frame

	_write_corrupt_save()
	var recovered := await _new_game()
	_expect(str(recovered.state.score) == "0" and int(recovered.state.moves) == 0, "corrupt_save_safe_reset")
	_expect(str(recovered.state.mode) == MODEL.MODE_EASY and recovered.state.board.size() == 8, "corrupt_save_default_mode")
	recovered.queue_free()
	await process_frame
	_remove_test_save()
	print("MERGE2248_PERSISTENCE_SMOKE=%d" % assertions)
	print("MERGE2248_PERSISTENCE_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _new_game() -> Control:
	var game: Control = load("res://main.tscn").instantiate()
	game.merge2248_save_path = SAVE_PATH
	game.merge2248_persistence_enabled = true
	game.merge2248_reduced_effects_override = false
	root.add_child(game)
	await process_frame
	game._open_game("merge2248")
	return game


func _fixture_board(rows: int) -> Array:
	var board: Array = []
	for y in range(rows):
		var row: Array[int] = []
		for x in range(5):
			row.append(y * 5 + x + 1)
		board.append(row)
	board[rows - 1][0] = 1
	board[rows - 1][1] = 1
	return board


func _write_corrupt_save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string('{"schema":"wrong","version":4}')
	file.flush()


func _remove_test_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
