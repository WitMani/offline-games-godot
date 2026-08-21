extends SceneTree

const LEVEL_THREE_SOLUTION := [
	Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN,
	Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP, Vector2i.RIGHT,
	Vector2i.DOWN, Vector2i.LEFT,
]

var game: Control
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_probe_wall_contact()
	_probe_long_travel()
	_probe_short_travel()
	_probe_revisit()
	_probe_near_completion_and_completion()
	_probe_restart()
	print("AMAZE_ACTION_SMOKE=%d" % assertions)
	print("AMAZE_ACTION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _open_level(level: int) -> void:
	game._clear_amaze_checkpoint()
	game._open_game("amaze")
	game.amaze_level_index = level
	game._start_game_state()
	game._build_game_buttons()
	game.has_transitioned = false
	game.catalog_fx.clear()


func _last_event() -> Dictionary:
	return game.catalog_fx.back()


func _probe_wall_contact() -> void:
	_open_level(0)
	game._amaze_step(Vector2i.LEFT)
	var event := _last_event()
	_expect(str(event["semantic"]) == "amaze_blocked", "blocked_semantic")
	_expect(str(event["kind"]) == "path_reject_wall" and int(event["grade"]) == 1, "blocked_intensity")
	_expect(event["direction"] == [-1, 0] and int(event["remaining"]) == 8, "blocked_payload")
	_expect(str(event["font_role"]) == "ui_cjk", "blocked_font")


func _probe_long_travel() -> void:
	_open_level(2)
	game._amaze_step(Vector2i.RIGHT)
	var event := _last_event()
	_expect(str(event["semantic"]) == "amaze_long_roll", "long_semantic")
	_expect(str(event["kind"]) == "path_roll" and int(event["grade"]) == 2, "long_intensity")
	_expect(event["traversed"] == [[1, 6], [2, 6], [3, 6], [4, 6]], "long_order")
	_expect(event["newly_painted"] == event["traversed"], "long_newly_order")
	_expect(event["to_cell"] == [4, 6] and int(event["remaining"]) == 26, "long_stop_payload")


func _probe_short_travel() -> void:
	_open_level(2)
	for direction in [Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT]:
		game._amaze_step(direction)
	var event := _last_event()
	_expect(str(event["semantic"]) == "amaze_short_roll", "short_semantic")
	_expect(int(event["grade"]) == 1 and event["traversed"].size() == 2, "short_intensity")
	_expect(event["from_cell"] == [4, 2] and event["to_cell"] == [2, 2], "short_stops")


func _probe_revisit() -> void:
	_open_level(2)
	game._amaze_step(Vector2i.RIGHT)
	game._amaze_step(Vector2i.LEFT)
	var event := _last_event()
	_expect(str(event["semantic"]) == "amaze_revisit", "revisit_semantic")
	_expect(str(event["kind"]) == "path_revisit", "revisit_kind")
	_expect(event["newly_painted"].is_empty() and int(event["revisit_count"]) == 4, "revisit_payload")
	_expect(int(game.state["painted_count"]) == 5 and int(game.state["moves"]) == 2, "revisit_state")


func _probe_near_completion_and_completion() -> void:
	_open_level(2)
	for index in range(LEVEL_THREE_SOLUTION.size() - 1):
		game._amaze_step(LEVEL_THREE_SOLUTION[index])
	var near := _last_event()
	_expect(str(near["semantic"]) == "amaze_near_complete", "near_semantic")
	_expect(str(near["kind"]) == "path_near_complete" and int(near["grade"]) == 3, "near_intensity")
	_expect(int(near["remaining"]) == 1 and int(game.state["painted_count"]) == 30, "near_progress")
	game._amaze_step(LEVEL_THREE_SOLUTION.back())
	var complete := _last_event()
	_expect(str(complete["semantic"]) == "amaze_complete", "complete_semantic")
	_expect(str(complete["kind"]) == "path_complete" and int(complete["grade"]) == 4, "complete_intensity")
	_expect(int(complete["remaining"]) == 0 and bool(game.state["status"] == "won"), "complete_progress")
	_expect(str(near["font_role"]) == "ui_cjk" and str(complete["font_role"]) == "ui_cjk", "dynamic_cjk_roles")


func _probe_restart() -> void:
	_open_level(1)
	game._amaze_step(Vector2i.LEFT)
	game._reset_current()
	_expect(int(game.state["level_index"]) == 1 and game.state["player"] == [5, 4], "restart_level")
	_expect(int(game.state["moves"]) == 0 and int(game.state["painted_count"]) == 1, "restart_clean")
	_expect(game.amaze_last_outcome.is_empty() and game.catalog_fx.is_empty(), "restart_feedback_clean")


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
