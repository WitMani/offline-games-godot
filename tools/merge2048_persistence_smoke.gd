extends SceneTree

var failures: Array[String] = []
var assertions := 0
var save_path := "user://merge2048_persistence_probe_%d.json" % Time.get_ticks_usec()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_probe_file()
	var first := await _new_game(1212)
	first._open_game("merge2048")
	first._merge2048_load_fixture([[2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]], 16, 2, false, false, false, 40)
	first._merge_move(Vector2i.RIGHT)
	var saved: Dictionary = first.merge2048_model.snapshot()
	_expect(FileAccess.file_exists(save_path), "active_file_written")
	first.queue_free()
	await process_frame

	var second := await _new_game(3434)
	second._open_game("merge2048")
	_expect(second.merge2048_model.snapshot() == saved, "active_restored_exact")
	_expect(int(second.state.best) == int(saved.best), "best_restored")
	second._merge2048_load_fixture([
		[0, 8, 16, 32],
		[4, 2, 4, 64],
		[2, 4, 8, 16],
		[4, 2, 4, 8],
	], int(saved.score), int(saved.moves), false, false, false, int(saved.best))
	second._merge_move(Vector2i.LEFT)
	_expect(str(second.state.status) == "over", "terminal_state")
	var terminal_best := int(second.state.best)
	var persisted_terminal: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	_expect(persisted_terminal is Dictionary and persisted_terminal.get("active") == null, "terminal_clears_active")
	second.queue_free()
	await process_frame

	var third := await _new_game(5656)
	third._open_game("merge2048")
	_expect(str(third.state.status) == "playing" and _occupied(third.state.board) == 2, "terminal_starts_fresh")
	_expect(int(third.state.best) == terminal_best, "terminal_preserves_best")
	third.queue_free()
	await process_frame
	_remove_probe_file()
	print("MERGE2048_PERSISTENCE_ASSERTIONS=%d" % assertions)
	print("MERGE2048_PERSISTENCE_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _new_game(seed_value: int) -> Control:
	var instance: Control = load("res://main.tscn").instantiate()
	instance.merge2048_save_path = save_path
	instance.merge2048_persistence_enabled = true
	instance.merge2048_seed_override = seed_value
	root.add_child(instance)
	await process_frame
	return instance


func _remove_probe_file() -> void:
	var absolute := ProjectSettings.globalize_path(save_path)
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(absolute)


func _occupied(candidate_board: Array) -> int:
	var count := 0
	for row in candidate_board:
		for value in row:
			count += 1 if int(value) > 0 else 0
	return count


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
