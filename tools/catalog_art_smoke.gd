extends SceneTree

var game: Control
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_test_merge2048_peak()
	_test_watermelon_peak()
	_test_sudoku_roles()
	_test_solitaire_grade()
	_test_tripeaks_streak()
	_test_mahjong_completion()
	_test_tileclub_completion()
	_test_path_completion("amaze_go")
	_test_path_completion("arrow_go")
	_test_paint_completion()
	print("CATALOG_ART_SMOKE=%d" % 10)
	print("CATALOG_ART_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect_event(test_name: String, kind: String, minimum_grade: int) -> void:
	if game.catalog_fx.is_empty():
		failures.append("%s:no_event" % test_name)
		return
	var effect: Dictionary = {}
	for index in range(game.catalog_fx.size() - 1, -1, -1):
		var candidate: Dictionary = game.catalog_fx[index]
		if str(candidate.get("kind", "")) == kind:
			effect = candidate
			break
	if effect.is_empty():
		effect = game.catalog_fx.back()
	if str(effect.get("game_id", "")) != game.game_id:
		failures.append("%s:wrong_game" % test_name)
	if str(effect.get("kind", "")) != kind:
		failures.append("%s:kind_%s" % [test_name, effect.get("kind", "")])
	if int(effect.get("grade", 0)) < minimum_grade:
		failures.append("%s:grade_%s" % [test_name, effect.get("grade", 0)])
	if str(effect.get("label", "")).is_empty():
		failures.append("%s:empty_label" % test_name)


func _test_merge2048_peak() -> void:
	game._open_game("merge2048")
	game._merge2048_load_fixture([[64, 64, 64, 64], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
	game._merge_move(Vector2i.LEFT)
	_expect_event("merge2048", "merge", 4)


func _test_watermelon_peak() -> void:
	game._open_game("watermelon")
	for position in [Vector2(240, 600), Vector2(270, 600), Vector2(240, 600), Vector2(270, 600)]:
		game.watermelon_model.inject_ball(1, position, Vector2.ZERO, 77)
	game._watermelon_update(game.watermelon_model.FIXED_DT)
	_expect_event("watermelon", "fruit_merge", 4)


func _test_sudoku_roles() -> void:
	game._open_game("meowdoku")
	var wrong := Vector2i.ZERO
	if wrong in game.meowdoku_model.solution:
		wrong = Vector2i(1, 0)
	game._meowdoku_command("cat", wrong)
	_expect_event("meowdoku_error", "cat_error", 2)
	game._open_game("sudoku")
	var solution: Array = game.state["solution"]
	var cell := _first_sudoku_editable()
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
	_expect_event("sudoku_block", "logic_block_complete", 3)


func _first_sudoku_editable() -> Vector2i:
	for y in range(9):
		for x in range(9):
			if int(game.state.given[y][x]) == 0:
				return Vector2i(x, y)
	return Vector2i.ZERO


func _test_solitaire_grade() -> void:
	game._open_game("solitaire")
	var fixture: Dictionary = game.solitaire_model.snapshot()
	fixture["stock"] = range(13, 52)
	fixture["waste"] = [12]
	fixture["tableau"] = [[], [], [], [], [], [], []]
	fixture["foundations"] = [range(0, 12), [], [], []]
	fixture["score"] = 0
	fixture["moves"] = 0
	fixture["recycles_used"] = 0
	fixture["status"] = "playing"
	if not game._restore_solitaire_snapshot(fixture):
		failures.append("solitaire:fixture_restore")
		return
	game._solitaire_auto()
	_expect_event("solitaire", "foundation_place", 3)


func _test_tripeaks_streak() -> void:
	game._open_game("tripeaks")
	var active := {0:50, 3:36, 9:19, 18:31}
	var used := {50:true, 36:true, 19:true, 31:true, 4:true, 40:true}
	var tableau: Array = []
	var removed: Array = []
	for slot in range(28):
		tableau.append(int(active.get(slot, -1)))
		if not active.has(slot):
			removed.append(slot)
	var waste: Array = []
	for card in range(52):
		if not used.has(card):
			waste.append(card)
	waste.append(4)
	var saved: Dictionary = game.tripeaks_model.snapshot()
	saved["tableau"] = tableau
	saved["removed"] = removed
	saved["stock"] = [40]
	saved["waste"] = waste
	saved["score"] = removed.size() * 30
	saved["moves"] = waste.size() - 1
	saved["streak"] = 6
	saved["status"] = "playing"
	saved["remaining"] = active.size()
	game._restore_tripeaks_snapshot(saved)
	game._tripeaks_tap(game._tripeaks_card_center(18))
	_expect_event("tripeaks", "card_streak", 4)


func _test_mahjong_completion() -> void:
	game._open_game("mahjong")
	game.state["removed"] = range(1, 10) + range(11, 20)
	game.state["selected"] = 0
	game._mahjong_tap(Vector2(50, 242 + 2 * 112 + 10))
	_expect_event("mahjong", "jade_pair", 4)


func _test_tileclub_completion() -> void:
	game._open_game("tileclub")
	var empty_tiles: Array = []
	for _index in range(49):
		empty_tiles.append(0)
	game.state["tiles"] = empty_tiles
	game.state["tiles"][0] = 1
	game.state["tray"] = [1, 1]
	game._tileclub_tap(Vector2(44, 244))
	_expect_event("tileclub", "stitch_match", 4)


func _test_path_completion(id: String) -> void:
	game._open_game(id)
	var grid_size := int(game.state["size"])
	game.state["player"] = [grid_size - 2, grid_size - 1]
	if id == "arrow_go":
		game.state["arrows"][grid_size - 1][grid_size - 2] = [1, 0]
	game._amaze_step(Vector2i.RIGHT)
	_expect_event(id, "path_complete", 4)


func _test_paint_completion() -> void:
	game._open_game("amaze")
	var grid_size := int(game.state["size"])
	for y in range(grid_size):
		for x in range(grid_size):
			game.state["painted"][y][x] = true
	game.state["painted"][0][1] = false
	game.state["player"] = [0, 0]
	game._amaze_step(Vector2i.RIGHT)
	_expect_event("amaze", "path_complete", 4)
