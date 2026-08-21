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
	_test_entry_contract()
	_test_renderer_uses_authoritative_model()
	_test_covered_tile_is_inert()
	_test_mouse_touch_keyboard_parity()
	_test_keyboard_navigation()
	_test_match_and_tray_compaction()
	_test_full_failure_and_restart()
	_test_completion_and_progression()
	_test_checkpoint_reopen_recovery()
	game._clear_tileclub_checkpoint()
	print("TILECLUB_INTEGRATION_SMOKE=%d" % assertions)
	print("TILECLUB_INTEGRATION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _open(level := 0) -> void:
	game._clear_tileclub_checkpoint()
	game._open_game("tileclub")
	if level != 0:
		game.tileclub_level_index = level
		game._start_game_state()
		game._build_game_buttons()
	game.has_transitioned = false
	game.catalog_fx.clear()


func _test_entry_contract() -> void:
	_open()
	_expect(game.state["rules_version"] == "tileclub-stage0-v1", "entry_rules_version")
	_expect(game.state["level_id"] == "four_nests_intro", "entry_level")
	_expect(int(game.state["active_count"]) == 12 and int(game.state["layer_count"]) == 2, "entry_board")
	_expect(game.state["selectable_ids"].size() == 4, "entry_selectable")
	_expect(game.state["tray"].is_empty() and int(game.state["tray_capacity"]) == 7, "entry_tray")
	_expect(int(game.state["score"]) == 0 and int(game.state["moves"]) == 0, "entry_counters")
	_expect(str(game.state["status"]) == "playing" and game.tileclub_focus_id == 2, "entry_status_focus")
	_expect(game.buttons.size() == 3 and str(game.buttons[-1].text) == "槽位规则", "entry_controls")


func _test_renderer_uses_authoritative_model() -> void:
	_open()
	_expect(game.state["tiles"] == game.tileclub_model.snapshot()["tiles"], "renderer_tile_snapshot")
	_expect(game.state["tray"] == game.tileclub_model.tray, "renderer_tray_snapshot")
	var upper_rect: Rect2 = game._tileclub_tile_rect(2)
	var lower_rect: Rect2 = game._tileclub_tile_rect(0)
	_expect(upper_rect.has_point(lower_rect.get_center()), "renderer_overlap_visible")
	_expect(game._tileclub_tile_at(upper_rect.get_center()) == 2, "renderer_topmost_hit")
	_expect(game._tileclub_board_metrics()["rect"].encloses(upper_rect), "renderer_board_bounds")


func _test_covered_tile_is_inert() -> void:
	_open()
	var before := JSON.stringify(game.tileclub_model.checkpoint())
	game._tileclub_collect_id(0)
	_expect(JSON.stringify(game.tileclub_model.checkpoint()) == before, "covered_model_mutated")
	_expect(str(game.tileclub_last_outcome["reason"]) == "covered", "covered_reason")
	var event: Dictionary = game.catalog_fx.back()
	_expect(str(event["semantic"]) == "tileclub_blocked" and str(event["kind"]) == "stitch_blocked", "covered_semantic")
	_expect(int(event["grade"]) == 1 and event["blockers"] == [2], "covered_payload")
	_expect(str(event["font_role"]) == "ui_cjk", "covered_font_role")


func _test_mouse_touch_keyboard_parity() -> void:
	_open()
	var target: Vector2 = game._tileclub_tile_center(2)
	_mouse_click(target)
	var mouse_checkpoint := JSON.stringify(game.tileclub_model.checkpoint())
	_expect(game.state["tray"] == [1] and int(game.state["active_count"]) == 11, "mouse_collect")

	_open()
	target = game._tileclub_tile_center(2)
	_touch(target)
	var touch_checkpoint := JSON.stringify(game.tileclub_model.checkpoint())
	_expect(game.state["tray"] == [1] and game.pointer_down == Vector2(-1, -1), "touch_collect_release")

	_open()
	_key(KEY_ENTER)
	var keyboard_checkpoint := JSON.stringify(game.tileclub_model.checkpoint())
	_expect(game.state["tray"] == [1] and int(game.state["active_count"]) == 11, "keyboard_collect")
	_expect(mouse_checkpoint == touch_checkpoint and touch_checkpoint == keyboard_checkpoint, "input_authoritative_parity")


func _test_keyboard_navigation() -> void:
	_open()
	_key(KEY_RIGHT)
	_expect(game.tileclub_focus_id == 5, "keyboard_focus_right")
	_key(KEY_ENTER)
	_expect(game.state["tray"] == [2] and not bool(game.tileclub_model.tile_by_id(5)["active"]), "keyboard_focus_collect")
	_expect(game.tileclub_focus_id in game.tileclub_model.selectable_ids(), "keyboard_focus_recovers")


func _test_match_and_tray_compaction() -> void:
	_open(2)
	for tile_id in [2, 0, 5, 8, 11, 14]:
		game._tileclub_collect_id(tile_id)
	_expect(game.state["tray"] == [1, 1, 2, 3, 4, 5], "match_setup_order")
	game._tileclub_collect_id(1)
	_expect(game.state["tray"] == [2, 3, 4, 5], "match_compaction")
	_expect(int(game.state["matches"]) == 1 and int(game.state["score"]) == 100, "match_counters")
	_expect(str(game.state["status"]) == "playing", "match_before_full")
	var event: Dictionary = game.catalog_fx.back()
	_expect(str(event["semantic"]) == "tileclub_match" and int(event["grade"]) == 2, "match_semantic")
	_expect(event["matched_indices"] == [0, 1, 6], "match_indices")
	_expect(str(event["font_role"]) == "ui_cjk", "match_font_role")


func _test_full_failure_and_restart() -> void:
	_open(2)
	for tile_id in [2, 5, 8, 11, 14, 17]:
		game._tileclub_collect_id(tile_id)
	_expect(game.state["tray"] == [1, 2, 3, 4, 5, 6], "failure_near_full")
	game._tileclub_collect_id(20)
	_expect(str(game.state["status"]) == "over" and game.state["tray"].size() == 7, "failure_status")
	var event: Dictionary = game.catalog_fx.back()
	_expect(str(event["semantic"]) == "tileclub_full" and int(event["grade"]) == 4, "failure_semantic")
	var terminal_before := JSON.stringify(game.tileclub_model.checkpoint())
	game._tileclub_collect_id(0)
	_expect(JSON.stringify(game.tileclub_model.checkpoint()) == terminal_before, "failure_terminal_inert")
	game._reset_current()
	_expect(int(game.state["level_index"]) == 2 and int(game.state["active_count"]) == 21, "restart_same_level")
	_expect(game.state["tray"].is_empty() and int(game.state["moves"]) == 0, "restart_clean")
	_expect(str(game.state["status"]) == "playing" and game.tileclub_last_outcome.is_empty(), "restart_runtime_clean")


func _test_completion_and_progression() -> void:
	_open()
	for tile_id in game.tileclub_model.solution_for_level():
		game._tileclub_collect_id(tile_id)
	_expect(str(game.state["status"]) == "won" and int(game.state["active_count"]) == 0, "complete_status")
	_expect(game.state["tray"].is_empty() and int(game.state["matches"]) == 4, "complete_tray_matches")
	var event: Dictionary = game.catalog_fx.back()
	_expect(str(event["semantic"]) == "tileclub_complete" and int(event["grade"]) == 4, "complete_semantic")
	_expect(str(event["font_role"]) == "ui_cjk", "complete_font")
	_expect(str(game.buttons[-1].text) == "下一关", "complete_control")
	game._tileclub_next_level()
	_expect(int(game.state["level_index"]) == 1 and str(game.state["level_id"]) == "six_nests_ribbon", "progression_level")
	_expect(int(game.state["active_count"]) == 18 and str(game.state["status"]) == "playing", "progression_state")
	_expect(str(game.buttons[-1].text) == "槽位规则", "progression_control")


func _test_checkpoint_reopen_recovery() -> void:
	_open()
	game._tileclub_collect_id(2)
	var expected := JSON.stringify(game.tileclub_model.checkpoint())
	_expect(not game._load_tileclub_checkpoint_text().is_empty(), "checkpoint_saved")
	game._build_home()
	game._open_game("tileclub")
	_expect(game.tileclub_checkpoint_restored, "checkpoint_restore_flag")
	_expect(JSON.stringify(game.tileclub_model.checkpoint()) == expected, "checkpoint_reopen_parity")
	_expect(game.state["tray"] == [1] and int(game.state["active_count"]) == 11, "checkpoint_reopen_state")
	_expect(game.tileclub_last_outcome.is_empty() and game.tileclub_object_fx.is_empty(), "checkpoint_transients_cleared")
	game._reset_current()
	_expect(not game.tileclub_checkpoint_restored and game.state["tray"].is_empty(), "restart_replaces_checkpoint")
	game._build_home()
	game._open_game("tileclub")
	_expect(game.tileclub_checkpoint_restored and int(game.state["moves"]) == 0, "restart_checkpoint_reopens_clean")


func _mouse_click(position: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = position
	press.pressed = true
	game._gui_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = position
	release.pressed = false
	game._gui_input(release)


func _touch(position: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = position
	press.pressed = true
	game._unhandled_input(press)
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = position
	release.pressed = false
	game._unhandled_input(release)


func _key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	game._input(event)


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
