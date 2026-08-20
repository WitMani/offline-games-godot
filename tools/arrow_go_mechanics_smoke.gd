extends SceneTree

var game: Control
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_test_entry()
	_test_wrong_direction_rejects()
	_test_legal_step()
	_test_tap_contract()
	_test_turn_at_last_column()
	_test_edge_reject()
	_test_five_step_waypoint()
	_test_complete_route()
	_test_restart()
	print("ARROW_GO_MECHANICS_SMOKE=%d" % assertions)
	print("ARROW_GO_MECHANICS_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func _open() -> void:
	game._open_game("arrow_go")
	game.has_transitioned = false


func _last_event() -> Dictionary:
	return {} if game.catalog_fx.is_empty() else game.catalog_fx.back()


func _expect_event(kind: String, grade: int, label: String) -> void:
	var event := _last_event()
	_expect(str(event.get("game_id", "")) == "arrow_go", "%s_wrong_game" % kind)
	_expect(str(event.get("kind", "")) == kind, "%s_wrong_kind" % kind)
	_expect(int(event.get("grade", 0)) == grade, "%s_wrong_grade" % kind)
	_expect(str(event.get("label", "")) == label, "%s_wrong_label" % kind)


func _test_entry() -> void:
	_open()
	_expect(int(game.state["size"]) == 9, "entry_size")
	_expect(game.state["player"] == [0, 0], "entry_player")
	_expect(game.state["target"] == [8, 8], "entry_target")
	_expect(int(game._painted_count()) == 1, "entry_painted")
	_expect(bool(game.state["painted"][0][0]), "entry_start_unpainted")
	_expect(int(game.state["score"]) == 0, "entry_score")
	_expect(int(game.state["moves"]) == 0, "entry_moves")
	_expect(int(game.state["streak"]) == 0, "entry_streak")
	_expect(game.state["hint"] == [1, 0], "entry_hint")
	_expect(str(game.state["status"]) == "playing", "entry_status")
	_expect(int(game.state["walls"].size()) == 21, "entry_wall_payload")
	for y in range(9):
		for x in range(9):
			var expected := [1, 0] if x < 8 else [0, 1]
			_expect(game.state["arrows"][y][x] == expected, "entry_arrow_%d_%d" % [x, y])


func _test_wrong_direction_rejects() -> void:
	for direction in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
		_open()
		var before: Dictionary = game.state.duplicate(true)
		game._amaze_step(direction)
		_expect(game.state == before, "reject_%s_mutated" % direction)
		_expect_event("path_reject_arrow", 2, "逆着箭流")
		_expect(game.feedback_text == "箭流只允许向右", "reject_feedback_%s" % direction)


func _test_legal_step() -> void:
	_open()
	game._amaze_step(Vector2i.RIGHT)
	_expect(game.state["player"] == [1, 0], "step_player")
	_expect(bool(game.state["painted"][0][1]), "step_painted")
	_expect(int(game._painted_count()) == 2, "step_painted_count")
	_expect(int(game.state["score"]) == 5, "step_score")
	_expect(int(game.state["moves"]) == 1, "step_moves")
	_expect(int(game.state["streak"]) == 1, "step_streak")
	_expect(str(game.state["status"]) == "playing", "step_status")
	_expect_event("path_step", 1, "箭流推进")


func _test_tap_contract() -> void:
	_open()
	var before: Dictionary = game.state.duplicate(true)
	game._amaze_tap(game._path_cell_center(2, 0, 9))
	_expect(game.state == before, "tap_non_adjacent_mutated")
	game._amaze_tap(game._path_cell_center(0, 1, 9))
	_expect(game.state == before, "tap_wrong_adjacent_mutated")
	_expect_event("path_reject_arrow", 2, "逆着箭流")
	game._amaze_tap(game._path_cell_center(1, 0, 9))
	_expect(game.state["player"] == [1, 0], "tap_legal_player")
	_expect(int(game.state["moves"]) == 1, "tap_legal_moves")


func _test_turn_at_last_column() -> void:
	_open()
	game.state["player"] = [8, 0]
	var before: Dictionary = game.state.duplicate(true)
	game._amaze_step(Vector2i.RIGHT)
	_expect(game.state == before, "turn_wrong_direction_mutated")
	_expect_event("path_reject_arrow", 2, "逆着箭流")
	game._amaze_step(Vector2i.DOWN)
	_expect(game.state["player"] == [8, 1], "turn_down_player")
	_expect(int(game.state["score"]) == 5, "turn_down_score")
	_expect(int(game.state["moves"]) == 1, "turn_down_moves")
	_expect_event("path_step", 1, "箭流推进")


func _test_edge_reject() -> void:
	_open()
	game.state["player"] = [8, 8]
	var before: Dictionary = game.state.duplicate(true)
	game._amaze_step(Vector2i.DOWN)
	_expect(game.state == before, "edge_mutated_state")
	_expect_event("path_reject_edge", 1, "已到边界")


func _test_five_step_waypoint() -> void:
	_open()
	for _index in range(5):
		game._amaze_step(Vector2i.RIGHT)
	_expect(game.state["player"] == [5, 0], "waypoint_player")
	_expect(int(game._painted_count()) == 6, "waypoint_painted")
	_expect(int(game.state["score"]) == 25, "waypoint_score")
	_expect(int(game.state["moves"]) == 5, "waypoint_moves")
	_expect(int(game.state["streak"]) == 5, "waypoint_streak")
	_expect(str(game.state["status"]) == "playing", "waypoint_status")
	_expect_event("path_step", 2, "轨迹 ×5")


func _test_complete_route() -> void:
	_open()
	for _index in range(8):
		game._amaze_step(Vector2i.RIGHT)
	for _index in range(8):
		game._amaze_step(Vector2i.DOWN)
	_expect(game.state["player"] == [8, 8], "goal_player")
	_expect(bool(game.state["painted"][8][8]), "goal_painted")
	_expect(int(game._painted_count()) == 17, "goal_painted_count")
	_expect(int(game.state["score"]) == 180, "goal_score")
	_expect(int(game.state["moves"]) == 16, "goal_moves")
	_expect(int(game.state["streak"]) == 16, "goal_streak")
	_expect(str(game.state["status"]) == "won", "goal_status")
	_expect_event("path_complete", 4, "全域完成")
	var won_state: Dictionary = game.state.duplicate(true)
	game._amaze_step(Vector2i.DOWN)
	_expect(game.state == won_state, "post_win_mutated")


func _test_restart() -> void:
	_open()
	game._amaze_step(Vector2i.RIGHT)
	game._reset_current()
	_expect(game.state["player"] == [0, 0], "restart_player")
	_expect(int(game._painted_count()) == 1, "restart_painted")
	_expect(int(game.state["score"]) == 0, "restart_score")
	_expect(int(game.state["moves"]) == 0, "restart_moves")
	_expect(int(game.state["streak"]) == 0, "restart_streak")
	_expect(game.state["hint"] == [1, 0], "restart_hint")
	_expect(str(game.state["status"]) == "playing", "restart_status")
