extends SceneTree

const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const GAG_REWARD: Texture2D = preload("res://assets/art/logic/gag-v1/sudoku_compass_reward.png")
const GAG_COMPLETE: AudioStream = preload("res://assets/audio/logic/gag-v1/sudoku_complete_reward.ogg")
const REQUIRED_COPY := ["红笔修正", "轻轻擦去", "落笔正确", "九宫完成", "整册完成", "逻辑完成", "撤销", "擦除", "笔记", "开", "关", "提示", "提示落笔", "点击右上角“重开”继续挑战"]
const IMAGE_SHA := "a8980a0667e547c8c8b7486f29a65905126cac2da2af41bfca5ab96afe526c97"
const AUDIO_SHA := "4be425f00093f2dc47073c0d405f4d2332e32554bc433959ee0c460dff952d12"

var game: Control
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_test_font_role()
	_test_gag_resources()
	_test_selection_intent()
	_test_given_is_immutable()
	_test_routine_correct()
	_test_erase()
	_test_error()
	_test_note_hint_and_undo()
	_test_block_completion()
	_test_global_completion()
	print("SUDOKU_PRESENTATION_SMOKE=%d" % assertions)
	print("SUDOKU_PRESENTATION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _test_font_role() -> void:
	for copy in REQUIRED_COPY:
		for index in range(copy.length()):
			_expect(UI_FONT.has_char(copy.unicode_at(index)), "font_U+%04X" % copy.unicode_at(index))


func _test_gag_resources() -> void:
	_expect(GAG_REWARD.get_size() == Vector2(341, 344), "gag_texture_dimensions")
	_expect(GAG_REWARD.get_image().detect_alpha() != Image.ALPHA_NONE, "gag_texture_alpha")
	_expect(GAG_COMPLETE.get_length() >= 1.00, "gag_audio_duration")
	_expect(FileAccess.get_sha256("res://assets/art/logic/gag-v1/sudoku_compass_reward.png") == IMAGE_SHA, "gag_texture_hash")
	_expect(FileAccess.get_sha256("res://assets/audio/logic/gag-v1/sudoku_complete_reward.ogg") == AUDIO_SHA, "gag_audio_hash")


func _open() -> void:
	game._open_game("sudoku")
	game.has_transitioned = false


func _test_selection_intent() -> void:
	_open()
	var before: Array = game.state["board"].duplicate(true)
	var before_moves := int(game.state["moves"])
	game._sudoku_tap(game.logic_game_presenter.cell_center(Vector2i(2, 0)))
	_expect(game.state["selected"] == [2, 0], "select_cell")
	_expect(game.state["board"] == before, "select_board_unchanged")
	_expect(int(game.state["moves"]) == before_moves, "select_moves_unchanged")
	var presenter: Dictionary = game.logic_game_presenter.snapshot(game.elapsed)
	_expect(presenter["selected"] == [2, 0], "select_presenter")
	_expect(str(presenter["font_role"]) == "ui_cjk", "select_font_role")


func _test_given_is_immutable() -> void:
	_open()
	var cell := _find_cell(game.state.given, true)
	game.sudoku_model.select(cell)
	game._sync_sudoku_state()
	var before: Array = game.state["board"].duplicate(true)
	var before_moves := int(game.state["moves"])
	var before_mistakes := int(game.state["mistakes"])
	game._sudoku_place(9)
	_expect(game.state["board"] == before, "given_board_immutable")
	_expect(int(game.state["moves"]) == before_moves, "given_moves_immutable")
	_expect(int(game.state["mistakes"]) == before_mistakes, "given_mistakes_immutable")


func _test_routine_correct() -> void:
	_open()
	var solution: Array = game.state["solution"]
	var cell := _find_cell(game.state.given, false)
	game.sudoku_model.select(cell)
	game._sync_sudoku_state()
	game.logic_game_presenter.select(cell, game.elapsed)
	game._sudoku_place(int(solution[cell.y][cell.x]))
	_expect(int(game.state["board"][cell.y][cell.x]) == int(solution[cell.y][cell.x]), "correct_value")
	_expect(int(game.state["moves"]) == 1, "correct_moves")
	_expect_event("logic_correct", 1, "落笔正确")
	_expect_presenter("logic_correct", 1, cell)


func _test_erase() -> void:
	_open()
	var solution: Array = game.state["solution"]
	var cell := _find_cell(game.state.given, false)
	game.sudoku_model.board[cell.y][cell.x] = solution[cell.y][cell.x]
	game.sudoku_model.select(cell)
	game._sync_sudoku_state()
	game._sudoku_place(0)
	_expect(int(game.state["board"][cell.y][cell.x]) == 0, "erase_value")
	_expect(int(game.state["moves"]) == 1, "erase_moves")
	_expect_event("logic_erase", 1, "轻轻擦去")
	_expect_presenter("logic_erase", 1, cell)


func _test_error() -> void:
	_open()
	var cell := _find_cell(game.state.given, false)
	game.sudoku_model.select(cell)
	game._sync_sudoku_state()
	var wrong_value := (int(game.state.solution[cell.y][cell.x]) % 9) + 1
	game._sudoku_place(wrong_value)
	_expect(int(game.state.board[cell.y][cell.x]) == wrong_value, "error_board_retained")
	_expect(bool(game.state.wrong[cell.y][cell.x]), "error_board_marked")
	_expect(int(game.state["moves"]) == 1, "error_moves_incremented")
	_expect(int(game.state["mistakes"]) == 1, "error_mistake_increment")
	_expect_event("logic_error", 2, "红笔修正")
	_expect_presenter("logic_error", 2, cell)


func _test_note_hint_and_undo() -> void:
	_open()
	var cell := _find_cell(game.state.given, false)
	var value := int(game.state.solution[cell.y][cell.x])
	game.sudoku_model.select(cell)
	game._sync_sudoku_state()
	game._sudoku_toggle_notes()
	game._sudoku_place(value)
	_expect((int(game.state.notes[cell.y][cell.x]) & (1 << value)) != 0, "note_state")
	_expect_presenter("logic_note", 1, cell)
	game._sudoku_toggle_notes()
	game._sudoku_hint()
	_expect(int(game.state.board[cell.y][cell.x]) == value, "hint_state")
	_expect(int(game.state.hints_remaining) == 2, "hint_count")
	_expect_presenter("logic_hint", 2, cell)
	game._sudoku_undo()
	_expect(int(game.state.board[cell.y][cell.x]) == 0, "undo_state")
	_expect(int(game.state.hints_remaining) == 3, "undo_hint_count")
	_expect_presenter("logic_undo", 1, cell)


func _test_block_completion() -> void:
	_open()
	var solution: Array = game.state["solution"]
	var cell := _find_cell(game.state.given, false)
	var block := int(cell.y / 3) * 3 + int(cell.x / 3)
	var start_x := (block % 3) * 3
	var start_y := int(block / 3) * 3
	for y in range(start_y, start_y + 3):
		for x in range(start_x, start_x + 3):
			game.sudoku_model.board[y][x] = solution[y][x]
	game.sudoku_model.board[cell.y][cell.x] = 0
	game.sudoku_model.select(cell)
	game._sync_sudoku_state()
	game._sudoku_place(int(solution[cell.y][cell.x]))
	_expect(game._sudoku_block_complete(block), "block_state")
	_expect(str(game.state["status"]) == "playing", "block_not_terminal")
	_expect_event("logic_block_complete", 3, "九宫完成")
	_expect_presenter("logic_block_complete", 3, cell)


func _test_global_completion() -> void:
	_open()
	var solution: Array = game.state["solution"]
	var cell := _find_cell(game.state.given, false)
	game.sudoku_model.board = solution.duplicate(true)
	game.sudoku_model.board[cell.y][cell.x] = 0
	game.sudoku_model.select(cell)
	game._sync_sudoku_state()
	game._sudoku_place(int(solution[cell.y][cell.x]))
	_expect(str(game.state["status"]) == "won", "complete_status")
	_expect(int(game.state["score"]) == 1000, "complete_score")
	_expect(int(game.state["moves"]) == 1, "complete_moves")
	_expect_event("logic_complete", 4, "整册完成")
	_expect_presenter("logic_complete", 4, cell)
	_expect(_audio_stream_was_routed(), "gag_complete_audio_route")


func _audio_stream_was_routed() -> bool:
	for player_variant in game.sfx_players:
		var player: AudioStreamPlayer = player_variant
		if player.stream != null and player.stream.resource_path == "res://assets/audio/logic/gag-v1/sudoku_complete_reward.ogg":
			return true
	return false


func _expect_event(kind: String, grade: int, label: String) -> void:
	if game.catalog_fx.is_empty():
		_expect(false, "%s_event_missing" % kind)
		return
	var effect: Dictionary = game.catalog_fx.back()
	_expect(str(effect.get("game_id", "")) == "sudoku", "%s_event_game" % kind)
	_expect(str(effect.get("kind", "")) == kind, "%s_event_kind" % kind)
	_expect(int(effect.get("grade", 0)) == grade, "%s_event_grade" % kind)
	_expect(str(effect.get("label", "")) == label, "%s_event_label" % kind)
	_expect(str(effect.get("font_role", "")) == "ui_cjk", "%s_event_font" % kind)


func _expect_presenter(kind: String, grade: int, cell: Vector2i) -> void:
	var presenter: Dictionary = game.logic_game_presenter.snapshot(game.elapsed)
	_expect(str(presenter.get("kind", "")) == kind, "%s_presenter_kind" % kind)
	_expect(int(presenter.get("grade", 0)) == grade, "%s_presenter_grade" % kind)
	_expect(presenter.get("cell", []) == [cell.x, cell.y], "%s_presenter_cell" % kind)


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)


func _find_cell(given: Array, want_given: bool) -> Vector2i:
	for y in range(9):
		for x in range(9):
			if (int(given[y][x]) != 0) == want_given:
				return Vector2i(x, y)
	return Vector2i(-1, -1)
