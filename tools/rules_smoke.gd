extends SceneTree

var game: Control
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.merge2248_persistence_enabled = false
	root.add_child(game)
	await process_frame
	_test_arrow_rule()
	_test_maze_wall_rule()
	_test_paint_completion_rule()
	_test_tileclub_clearability()
	_test_tripeaks_lock_rule()
	_test_merge_contrast()
	print("RULES_SMOKE=%d" % 6)
	print("RULES_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)

func _test_arrow_rule() -> void:
	game._open_game("arrow_go")
	var before: Array = game.state["player"].duplicate()
	game._amaze_step(Vector2i.DOWN)
	if game.state["player"] != before:
		failures.append("arrow_reject")
	game._amaze_step(Vector2i.RIGHT)
	if game.state["player"] != [1, 0]:
		failures.append("arrow_accept")

func _test_maze_wall_rule() -> void:
	game._open_game("amaze_go")
	var checked := false
	var grid_size := int(game.state["size"])
	for y in range(grid_size):
		for x in range(grid_size):
			for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
				if game._maze_blocks(x, y, direction):
					game.state["player"] = [x, y]
					game._amaze_step(direction)
					if game.state["player"] != [x, y]:
						failures.append("maze_wall")
					checked = true
					break
			if checked: break
		if checked: break
	if not checked:
		failures.append("maze_wall_missing")

func _test_paint_completion_rule() -> void:
	game._clear_amaze_checkpoint()
	game._open_game("amaze")
	game._amaze_step(Vector2i.UP)
	if game.state["status"] != "playing":
		failures.append("paint_early_win")
	game._amaze_step(Vector2i.RIGHT)
	if game.state["status"] != "won":
		failures.append("paint_full_win")
	if int(game.state.get("painted_count", 0)) != int(game.state.get("walkable_count", -1)):
		failures.append("paint_walkable_completion")
	if int(game.state.get("painted_count", 0)) >= int(game.state.get("width", 0)) * int(game.state.get("height", 0)):
		failures.append("paint_voids_counted")

func _test_tileclub_clearability() -> void:
	game._open_game("tileclub")
	if int(game.state["tray_capacity"]) != 7 or int(game.state["layer_count"]) < 2:
		failures.append("tile_contract")
	for level in range(game.tileclub_model.level_count()):
		var model = game.TILECLUB_RULES.new()
		model.reset(level)
		var counts := {}
		for tile in model.tiles:
			var number := int(tile["value"])
			counts[number] = int(counts.get(number, 0)) + 1
		for number in counts:
			if int(counts[number]) % 3 != 0:
				failures.append("tile_count_%d_%s" % [level, number])
		if model.selectable_ids().is_empty():
			failures.append("tile_selectable_%d" % level)
		for tile_id in model.solution_for_level():
			var outcome: Dictionary = model.collect(tile_id)
			if not bool(outcome.get("changed", false)):
				failures.append("tile_solution_%d_%d" % [level, tile_id])
				break
		if model.status != "won" or not model.tray.is_empty():
			failures.append("tile_clear_%d" % level)

func _test_tripeaks_lock_rule() -> void:
	game._open_game("tripeaks")
	game.state["current"] = 1
	var before: Array = game.state["removed"].duplicate()
	game._tripeaks_tap(game._tripeaks_card_center(0))
	if game.state["removed"] != before:
		failures.append("tripeaks_lock")

func _test_merge_contrast() -> void:
	for id in ["merge2248", "merge2048"]:
		game._open_game(id)
		for value in [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096]:
			# Test the actual pixel color beneath the digits, including 2248's
			# translucent energy halo, so the assertion matches final rendering.
			var fill: Color = game._merge_number_background(value)
			var ink: Color = game._readable_number_color(fill)
			if game._contrast_ratio(fill, ink) < 4.5:
				failures.append("contrast_%s_%d" % [id, value])
