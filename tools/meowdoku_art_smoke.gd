extends SceneTree

const GAME_IDS := ["meowdoku"]
const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const MEOW_GAG_REWARD: Texture2D = preload("res://assets/art/logic/gag-v1/meowdoku_paw_reward.png")
const MEOW_GAG_COMPLETE: AudioStream = preload("res://assets/audio/logic/gag-v1/meowdoku_complete_reward.ogg")
const REQUIRED_COPY := ["猫爪提醒", "轻轻擦去", "猫爪确认", "猫爪盖章", "整册完成", "手账完成"]

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
	for id in GAME_IDS:
		_test_selection_intent(id)
		_test_given_is_immutable(id)
		_test_routine_correct(id)
		_test_erase(id)
		_test_error(id)
		_test_block_completion(id)
		_test_global_completion(id)
	print("MEOWDOKU_ART_SMOKE=%d" % assertions)
	print("MEOWDOKU_ART_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _test_font_role() -> void:
	for copy in REQUIRED_COPY:
		for index in range(copy.length()):
			_expect(UI_FONT.has_char(copy.unicode_at(index)), "font_U+%04X" % copy.unicode_at(index))


func _test_gag_resources() -> void:
	_expect(MEOW_GAG_REWARD.get_size() == Vector2(331, 297), "meowdoku_gag_texture_dimensions")
	_expect(MEOW_GAG_REWARD.get_image().detect_alpha() != Image.ALPHA_NONE, "meowdoku_gag_texture_alpha")
	_expect(MEOW_GAG_COMPLETE.get_length() >= 0.90, "meowdoku_gag_audio_duration")


func _test_selection_intent(id: String) -> void:
	game._open_game(id)
	var before: Array = game.state["board"].duplicate(true)
	var before_moves := int(game.state["moves"])
	game._sudoku_tap(game.logic_game_presenter.cell_center(Vector2i(2, 0)))
	_expect(game.state["selected"] == [2, 0], "%s_select_cell" % id)
	_expect(game.state["board"] == before, "%s_select_board" % id)
	_expect(int(game.state["moves"]) == before_moves, "%s_select_moves" % id)
	var presenter: Dictionary = game.logic_game_presenter.snapshot(game.elapsed)
	_expect(presenter["selected"] == [2, 0], "%s_select_presenter" % id)
	_expect(str(presenter["font_role"]) == "ui_cjk", "%s_select_font_role" % id)


func _test_given_is_immutable(id: String) -> void:
	game._open_game(id)
	game.state["selected"] = [1, 0]
	var before: Array = game.state["board"].duplicate(true)
	var before_moves := int(game.state["moves"])
	var before_mistakes := int(game.state["mistakes"])
	game._sudoku_place(9)
	_expect(game.state["board"] == before, "%s_given_board" % id)
	_expect(int(game.state["moves"]) == before_moves, "%s_given_moves" % id)
	_expect(int(game.state["mistakes"]) == before_mistakes, "%s_given_mistakes" % id)


func _test_routine_correct(id: String) -> void:
	game._open_game(id)
	var solution: Array = game.state["solution"]
	game.state["selected"] = [2, 0]
	game.logic_game_presenter.select(Vector2i(2, 0), game.elapsed)
	game._sudoku_place(int(solution[0][2]))
	_expect(int(game.state["board"][0][2]) == int(solution[0][2]), "%s_correct_value" % id)
	_expect(int(game.state["moves"]) == 1, "%s_correct_moves" % id)
	_expect_event(id, "logic_correct", 1, "猫爪确认" if id == "meowdoku" else "落笔正确")
	_expect_presenter(id, "logic_correct", 1, Vector2i(2, 0))


func _test_erase(id: String) -> void:
	game._open_game(id)
	var solution: Array = game.state["solution"]
	game.state["board"][0][0] = solution[0][0]
	game.state["selected"] = [0, 0]
	game._sudoku_place(0)
	_expect(int(game.state["board"][0][0]) == 0, "%s_erase_value" % id)
	_expect(int(game.state["moves"]) == 1, "%s_erase_moves" % id)
	_expect_event(id, "logic_erase", 1, "轻轻擦去")
	_expect_presenter(id, "logic_erase", 1, Vector2i(0, 0))


func _test_error(id: String) -> void:
	game._open_game(id)
	var before: Array = game.state["board"].duplicate(true)
	game.state["selected"] = [2, 0]
	game._sudoku_place(1)
	_expect(game.state["board"] == before, "%s_error_board" % id)
	_expect(int(game.state["moves"]) == 0, "%s_error_moves" % id)
	_expect(int(game.state["mistakes"]) == 1, "%s_error_mistakes" % id)
	_expect_event(id, "logic_error", 2, "猫爪提醒" if id == "meowdoku" else "红笔修正")
	_expect_presenter(id, "logic_error", 2, Vector2i(2, 0))


func _test_block_completion(id: String) -> void:
	game._open_game(id)
	var solution: Array = game.state["solution"]
	for y in range(3):
		for x in range(3):
			game.state["board"][y][x] = solution[y][x]
	game.state["board"][0][2] = 0
	game.state["selected"] = [2, 0]
	game._sudoku_place(int(solution[0][2]))
	_expect(game._sudoku_block_complete(0), "%s_block_state" % id)
	_expect(str(game.state["status"]) == "playing", "%s_block_not_terminal" % id)
	_expect_event(id, "logic_block_complete", 3, "猫爪盖章" if id == "meowdoku" else "九宫完成")
	_expect_presenter(id, "logic_block_complete", 3, Vector2i(2, 0))


func _test_global_completion(id: String) -> void:
	game._open_game(id)
	var solution: Array = game.state["solution"]
	game.state["board"] = solution.duplicate(true)
	game.state["board"][0][0] = 0
	game.state["selected"] = [0, 0]
	game._sudoku_place(int(solution[0][0]))
	_expect(str(game.state["status"]) == "won", "%s_complete_status" % id)
	_expect(int(game.state["score"]) == 1000, "%s_complete_score" % id)
	_expect(int(game.state["moves"]) == 1, "%s_complete_moves" % id)
	_expect_event(id, "logic_complete", 4, "整册完成")
	_expect_presenter(id, "logic_complete", 4, Vector2i(0, 0))
	var expected_audio := "res://assets/audio/logic/gag-v1/meowdoku_complete_reward.ogg" if id == "meowdoku" else "res://assets/audio/logic/gag-v1/sudoku_complete_reward.ogg"
	_expect(_audio_stream_was_routed(expected_audio), "%s_gag_complete_audio_route" % id)


func _audio_stream_was_routed(expected_path: String) -> bool:
	for player_variant in game.sfx_players:
		var player: AudioStreamPlayer = player_variant
		if player.stream != null and player.stream.resource_path == expected_path:
			return true
	return false


func _expect_event(id: String, kind: String, grade: int, label: String) -> void:
	if game.catalog_fx.is_empty():
		_expect(false, "%s_%s_event_missing" % [id, kind])
		return
	var effect: Dictionary = game.catalog_fx.back()
	_expect(str(effect.get("game_id", "")) == id, "%s_%s_event_game" % [id, kind])
	_expect(str(effect.get("kind", "")) == kind, "%s_%s_event_kind" % [id, kind])
	_expect(int(effect.get("grade", 0)) == grade, "%s_%s_event_grade" % [id, kind])
	_expect(str(effect.get("label", "")) == label, "%s_%s_event_label" % [id, kind])
	_expect(str(effect.get("font_role", "")) == "ui_cjk", "%s_%s_event_font" % [id, kind])


func _expect_presenter(id: String, kind: String, grade: int, cell: Vector2i) -> void:
	var presenter: Dictionary = game.logic_game_presenter.snapshot(game.elapsed)
	_expect(str(presenter.get("kind", "")) == kind, "%s_%s_presenter_kind" % [id, kind])
	_expect(int(presenter.get("grade", 0)) == grade, "%s_%s_presenter_grade" % [id, kind])
	_expect(presenter.get("cell", []) == [cell.x, cell.y], "%s_%s_presenter_cell" % [id, kind])


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
