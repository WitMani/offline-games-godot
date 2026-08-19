extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var model = load("res://models/merge2248_model.gd").new()
	model.reset(2248, 8)
	_expect(model.width == 5 and model.height == 8, "board_dimensions")
	model.board = _fixture_board()
	_expect(model.begin(Vector2i(0, 7)), "begin")
	_expect(not model.extend(Vector2i(1, 6)), "first_pair_must_match")
	_expect(model.extend(Vector2i(1, 7)), "same_value_pair")
	_expect(model.extend(Vector2i(2, 6)), "double_value_diagonal")
	_expect(model.extend(Vector2i(3, 6)), "same_value_after_double")
	_expect(not model.extend(Vector2i(4, 6)), "reject_non_same_or_double")
	_expect(model.preview_result() == 16, "preview_power")
	var outcome: Dictionary = model.release()
	_expect(bool(outcome.changed), "release_changed")
	_expect(int(outcome.gained) == 12 and int(outcome.result) == 16, "merge_result")
	_expect(model.score == 12 and model.moves == 1, "score_and_moves")

	model.board = _no_pair_board()
	_expect(not model.has_moves(), "terminal_detection")
	print("MERGE2248_MODEL_SMOKE=%d" % 10)
	print("MERGE2248_MODEL_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)

func _fixture_board() -> Array:
	var board: Array = []
	for y in range(8):
		var row: Array = []
		for x in range(5):
			row.append(2 if (x + y) % 2 == 0 else 4)
		board.append(row)
	board[7][0] = 2
	board[7][1] = 2
	board[6][1] = 4
	board[6][2] = 4
	board[6][3] = 4
	board[6][4] = 16
	return board

func _no_pair_board() -> Array:
	var board: Array = []
	for y in range(8):
		var row: Array = []
		for x in range(5):
			row.append(1 << (((x + 2 * y) % 5) + 1))
		board.append(row)
	return board

func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
