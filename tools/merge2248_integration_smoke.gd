extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Control = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._open_game("merge2248")
	_expect(game.state.board.size() == 8 and game.state.board[0].size() == 5, "entry_board")
	_expect(game.buttons.size() == 2, "no_direction_controls")
	var before_direction: Array = game.state.board.duplicate(true)
	game._direction_input(Vector2i.LEFT)
	_expect(game.state.board == before_direction, "direction_key_is_inert")
	_expect(game._merge2248_feedback_grade(2, 4) == 1, "juice_grade_light")
	_expect(game._merge2248_feedback_grade(3, 8) == 2, "juice_grade_combo")
	_expect(game._merge2248_feedback_grade(5, 16) == 3, "juice_grade_super")
	_expect(game._merge2248_feedback_grade(8, 16) == 4, "juice_grade_legendary")
	var rect: Rect2 = game._merge2248_board_rect()
	var cell := Vector2(rect.size.x / 5.0, rect.size.y / 8.0)
	game.merge2248_model.board[7][0] = 2
	game.merge2248_model.board[7][1] = 2
	game._sync_merge2248_state()
	var first := rect.position + Vector2(cell.x * 0.5, cell.y * 7.5)
	var second := rect.position + Vector2(cell.x * 1.5, cell.y * 7.5)
	_expect(game._merge2248_begin_at(first), "pointer_begin")
	game._merge2248_extend_at(second)
	_expect(game.merge2248_model.selected.size() == 2, "pointer_extend")
	game._merge2248_release()
	_expect(int(game.state.moves) == 1 and int(game.state.score) == 4, "release_sync")
	_expect(not game.merge2248_fx.is_empty() and int(game.merge2248_fx[-1].grade) == 1, "release_juice_grade")
	print("MERGE2248_INTEGRATION_SMOKE=%d" % 10)
	print("MERGE2248_INTEGRATION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
