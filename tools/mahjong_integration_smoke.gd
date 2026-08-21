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
	game._clear_mahjong_session()
	_test_open_and_runtime_binding()
	_test_blocked_pointer_route()
	_test_mouse_touch_keyboard_parity()
	_test_tools_and_reduced_effects()
	_test_completion_terminal_restart()
	await _test_strict_reload_recovery()
	game._clear_mahjong_session()
	print("MAHJONG_INTEGRATION_ASSERTIONS=%d" % assertions)
	print("MAHJONG_INTEGRATION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func _open() -> void:
	game._open_game("mahjong")
	game.has_transitioned = false


func _last_event() -> Dictionary:
	return {} if game.catalog_fx.is_empty() else game.catalog_fx.back()


func _point_for_index(index: int) -> Vector2:
	var rect: Rect2 = game._mahjong_tile_rect(index)
	for y_offset in range(4, int(rect.size.y) - 3, 4):
		for x_offset in range(4, int(rect.size.x) - 3, 4):
			var point := rect.position + Vector2(x_offset, y_offset)
			if game._mahjong_hit_test(point) == index:
				return point
	return Vector2(-1, -1)


func _visible_pair() -> Array[int]:
	for value in game.mahjong_model.available_pairs():
		var pair: Array = value
		if _point_for_index(int(pair[0])).x >= 0.0 and _point_for_index(int(pair[1])).x >= 0.0:
			return [int(pair[0]), int(pair[1])]
	return []


func _test_open_and_runtime_binding() -> void:
	_open()
	_expect(game.game_id == "mahjong" and game.screen == "game", "open_identity")
	_expect(game.state["mahjong_schema"] == 3, "model_schema_bound")
	_expect(game.state["tiles"].size() == 36 and int(game.state["remaining"]) == 36, "runtime_tile_count")
	_expect(game.mahjong_model.pair_multiset_is_valid(), "runtime_pair_multiset")
	_expect(game._mahjong_draw_order().size() == 36, "runtime_draw_order")
	var cap := 32
	_expect(game._mahjong_hit_test(game._mahjong_tile_center(cap)) == cap, "runtime_topmost_cap")
	_expect(game.MAHJONG_GAG_TILE_TEXTURE != null, "gag_tile_preloaded")
	_expect(game.MAHJONG_GAG_TILE_TEXTURE.get_size() == Vector2(275, 408), "gag_tile_dimensions")


func _test_blocked_pointer_route() -> void:
	_open()
	var blocked_index := 2
	var point := _point_for_index(blocked_index)
	_expect(point.x >= 0.0, "blocked_visible_hit_fixture")
	var before_removed: Array = game.state["removed"].duplicate()
	var before_score := int(game.state["score"])
	game._mahjong_tap(point)
	_expect(game.mahjong_object_fx["kind"] == "blocked", "blocked_object_fx")
	_expect(game.state["removed"] == before_removed and int(game.state["score"]) == before_score, "blocked_board_non_mutating")
	_expect(_last_event()["kind"] == "jade_blocked_reject", "blocked_semantic_event")
	_expect(str(_last_event()["font_role"]) == "ui_cjk", "blocked_cjk_role")


func _test_mouse_touch_keyboard_parity() -> void:
	# Mouse click-release route.
	_open()
	var pair := _visible_pair()
	_expect(pair.size() == 2, "mouse_pair_fixture")
	for index in pair:
		var point := _point_for_index(index)
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = point
		game._gui_input(press)
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		release.position = point
		game._gui_input(release)
	_expect(game.state["removed"].size() == 2 and int(game.state["moves"]) == 1, "mouse_match")
	# Touch press-release route reaches the same topmost resolver.
	_open()
	pair = _visible_pair()
	for index in pair:
		var point := _point_for_index(index)
		var press := InputEventScreenTouch.new()
		press.pressed = true
		press.position = point
		game._unhandled_input(press)
		var release := InputEventScreenTouch.new()
		release.pressed = false
		release.position = point
		game._unhandled_input(release)
	_expect(game.state["removed"].size() == 2 and int(game.state["moves"]) == 1, "touch_match")
	# Keyboard focus + Enter resolves the same indices.
	_open()
	pair = _visible_pair()
	game.mahjong_focus = pair[0]
	game._mahjong_keyboard_input(KEY_ENTER)
	game.mahjong_focus = pair[1]
	game._mahjong_keyboard_input(KEY_ENTER)
	_expect(game.state["removed"].size() == 2 and int(game.state["moves"]) == 1, "keyboard_match")
	_expect(_last_event()["kind"] == "jade_pair", "parity_pair_event")
	_expect(int(_last_event()["grade"]) == 2, "routine_pair_grade")


func _test_tools_and_reduced_effects() -> void:
	_open()
	game._mahjong_hint()
	_expect(game.state["hint_pair"].size() == 2, "runtime_hint_pair")
	_expect(game.mahjong_object_fx["kind"] == "hint", "runtime_hint_fx")
	var before_faces: Array[int] = []
	for tile_data in game.mahjong_model.tiles:
		before_faces.append(int(tile_data["face"]))
	before_faces.sort()
	game._mahjong_shuffle()
	var after_faces: Array[int] = []
	for tile_data in game.mahjong_model.tiles:
		after_faces.append(int(tile_data["face"]))
	after_faces.sort()
	_expect(before_faces == after_faces, "runtime_shuffle_multiset")
	_expect(game.mahjong_model.available_pairs().size() > 0, "runtime_shuffle_pair")
	var pair := _visible_pair()
	game._mahjong_resolve_index(pair[0], "test")
	game._mahjong_resolve_index(pair[1], "test")
	game._mahjong_undo()
	_expect(game.state["removed"].is_empty() and int(game.state["moves"]) == 0, "runtime_undo")
	game._toggle_mahjong_reduced()
	_expect(bool(game.state["reduced_effects"]), "reduced_state_authority")
	game._start_catalog_event("jade_pair", Vector2(270, 450), Color.WHITE, 4, "低动态测试", 1.0)
	_expect(game._catalog_shake_offset() == Vector2.ZERO, "reduced_shake_suppressed")
	var haptics_before: int = game.haptic_dispatch_count
	game._haptic(20)
	var reduced_pattern: Array[int] = [10, 10, 10]
	game._haptic_pattern(reduced_pattern)
	_expect(game.haptic_dispatch_count == haptics_before, "reduced_haptic_suppressed")
	game._toggle_mahjong_reduced()
	_expect(not bool(game.state["reduced_effects"]), "reduced_toggle_off")


func _test_completion_terminal_restart() -> void:
	_open()
	var guard := 0
	while game.mahjong_model.status == "playing" and guard < 20:
		var pairs: Array = game.mahjong_model.available_pairs()
		if pairs.is_empty():
			break
		game._mahjong_resolve_index(int(pairs[0][0]), "solve")
		game._mahjong_resolve_index(int(pairs[0][1]), "solve")
		guard += 1
	_expect(game.state["status"] == "won", "runtime_completion")
	_expect(int(game.state["remaining"]) == 0 and int(game.state["moves"]) == 18, "runtime_completion_counts")
	_expect(_last_event()["kind"] == "jade_pair" and int(_last_event()["grade"]) == 4, "runtime_final_peak")
	_expect(game.mahjong_object_fx["kind"] == "clear", "runtime_final_object_fx")
	var frozen: Dictionary = game.state.duplicate(true)
	game._mahjong_resolve_index(0, "terminal")
	_expect(game.state == frozen, "runtime_terminal_freeze")
	game._reset_current()
	_expect(game.state["status"] == "playing" and int(game.state["remaining"]) == 36, "runtime_restart")
	_expect(int(game.state["moves"]) == 0 and int(game.state["score"]) == 0, "runtime_restart_counters")


func _test_strict_reload_recovery() -> void:
	_open()
	var pair := _visible_pair()
	game._mahjong_resolve_index(pair[0], "recovery")
	game._mahjong_resolve_index(pair[1], "recovery")
	var expected: Dictionary = game.state.duplicate(true)
	game._persist_mahjong_session()
	var recovered: Control = load("res://main.tscn").instantiate()
	root.add_child(recovered)
	await process_frame
	_expect(recovered.game_id == "mahjong" and recovered.screen == "game", "reload_restores_game")
	_expect(recovered.state["removed"] == expected["removed"], "reload_restores_removed")
	_expect(int(recovered.state["moves"]) == 1 and int(recovered.state["remaining"]) == 34, "reload_restores_counters")
	var corrupt: Dictionary = recovered.state.duplicate(true)
	corrupt["tiles"][0]["layer"] = 99
	var before: Dictionary = recovered.mahjong_model.snapshot()
	_expect(not recovered.mahjong_model.restore(corrupt), "runtime_rejects_corrupt_recovery")
	_expect(recovered.mahjong_model.snapshot() == before, "runtime_corrupt_non_mutating")
	recovered.queue_free()
	await process_frame
