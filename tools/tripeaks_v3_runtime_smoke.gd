extends SceneTree

## Shell/input/recovery probes around the authoritative renderer-free model.

const GAME_ID := "tripeaks"
const EXPECTED_CASES := 9

var game: Control
var failures: Array[String] = []
var cases_run := 0
var opening_snapshot := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate() as Control
	root.add_child(game)
	await process_frame
	game.set_process(false)
	_disable_shell_audio()
	_test_shell_exposes_complete_versioned_state()
	_test_mouse_touch_keyboard_stock_parity()
	_test_mouse_touch_keyboard_clear_parity()
	_test_mouse_touch_keyboard_locked_reject_atomicity()
	_test_shell_restore_binds_and_neutralizes_focus()
	_test_shell_rejects_corrupt_restore_atomically()
	_test_explicit_restart_clears_recovery()
	_test_terminal_win_freezes_until_restart()
	_test_terminal_loss_freezes_until_restart()
	_dispose_game()
	await process_frame
	await process_frame
	_finish()


func _finish() -> void:
	if cases_run != EXPECTED_CASES:
		failures.append("case_count_%d_of_%d" % [cases_run, EXPECTED_CASES])
	print("TRIPEAKS_V3_RUNTIME_CASES=%d" % cases_run)
	print("TRIPEAKS_V3_RUNTIME_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _record(name: String, passed: bool, evidence: String = "") -> void:
	cases_run += 1
	if not passed:
		failures.append(name + ("=" + evidence if not evidence.is_empty() else ""))


func _disable_shell_audio() -> void:
	for player in game.sfx_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
			player.free()
	game.sfx_players.clear()


func _dispose_game() -> void:
	game._clear_tripeaks_snapshot()
	game.free()


func _open_fresh() -> void:
	game._clear_tripeaks_snapshot()
	game.tripeaks_restart_requested = true
	game._open_game(GAME_ID)
	game.tripeaks_restart_requested = false


func _core_snapshot() -> String:
	return JSON.stringify(game.tripeaks_model.snapshot())


func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	event.echo = false
	return event


func _mouse_tap(position: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	game._gui_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	game._gui_input(release)


func _touch_tap(position: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = position
	game._unhandled_input(press)
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.position = position
	game._unhandled_input(release)


func _cid(rank: int, suit: int = 0) -> int:
	return suit * 13 + rank - 1


func _fixture(active_slots: Dictionary, waste_top: int, stock_cards: Array = [], fixture_streak: int = 0) -> Dictionary:
	var used := {}
	var tableau: Array = []
	for slot in range(28):
		var card := int(active_slots.get(slot, -1))
		if card >= 0:
			used[card] = true
		tableau.append(card)
	used[waste_top] = true
	var stock: Array = []
	for value in stock_cards:
		used[int(value)] = true
		stock.append(int(value))
	var waste: Array = []
	for card in range(52):
		if not used.has(card):
			waste.append(card)
	waste.append(waste_top)
	var removed: Array = []
	for slot in range(28):
		if int(tableau[slot]) < 0:
			removed.append(slot)
	var saved: Dictionary = game.tripeaks_model.snapshot()
	saved["tableau"] = tableau
	saved["removed"] = removed
	saved["stock"] = stock
	saved["waste"] = waste
	saved["score"] = removed.size() * 30
	saved["moves"] = waste.size() - 1
	saved["streak"] = fixture_streak
	saved["status"] = "playing"
	saved["remaining"] = active_slots.size()
	return saved


func _legal_fixture() -> Dictionary:
	return _fixture({
		0:_cid(12, 3), 3:_cid(11, 2), 9:_cid(7, 1), 18:_cid(6, 2),
	}, _cid(5, 0), [_cid(2, 3)])


func _test_shell_exposes_complete_versioned_state() -> void:
	_open_fresh()
	var saved: Dictionary = game.state.duplicate(true)
	opening_snapshot = _core_snapshot()
	var cards := {}
	for value in saved["tableau"]:
		if int(value) >= 0:
			cards[int(value)] = true
	for value in saved["stock"]:
		cards[int(value)] = true
	for value in saved["waste"]:
		cards[int(value)] = true
	var passed: bool = (
		str(saved.get("schema", "")) == "tripeaks-state/v3"
		and str(saved.get("game_id", "")) == GAME_ID
		and saved["tableau"].size() == 28 and saved["stock"].size() == 23 and saved["waste"].size() == 1
		and saved["exposed_slots"] == range(18, 28) and cards.size() == 52
		and not bool(saved.get("recovered", true))
	)
	_record("shell_complete_52_card_state", passed, JSON.stringify(saved))


func _test_mouse_touch_keyboard_stock_parity() -> void:
	_open_fresh()
	_mouse_tap(game._tripeaks_stock_rect().get_center())
	var mouse_state := _core_snapshot()
	_open_fresh()
	_touch_tap(game._tripeaks_stock_rect().get_center())
	var touch_state := _core_snapshot()
	_open_fresh()
	game._input(_key_event(KEY_M))
	var keyboard_state := _core_snapshot()
	var parsed: Dictionary = JSON.parse_string(mouse_state)
	var passed: bool = mouse_state == touch_state and touch_state == keyboard_state and parsed["stock"].size() == 22 and parsed["waste"].size() == 2 and int(parsed["moves"]) == 1
	_record("input_stock_mouse_touch_keyboard", passed, JSON.stringify({"mouse":mouse_state, "touch":touch_state, "keyboard":keyboard_state}))


func _test_mouse_touch_keyboard_clear_parity() -> void:
	_open_fresh()
	var fixture := _legal_fixture()
	var mouse_restore: bool = game._restore_tripeaks_snapshot(fixture)
	_mouse_tap(game._tripeaks_card_center(18))
	var mouse_state := _core_snapshot()

	_open_fresh()
	var touch_restore: bool = game._restore_tripeaks_snapshot(fixture)
	_touch_tap(game._tripeaks_card_center(18))
	var touch_state := _core_snapshot()

	_open_fresh()
	var keyboard_restore: bool = game._restore_tripeaks_snapshot(fixture)
	game.tripeaks_focus_slot = 18
	game._sync_tripeaks_state()
	game._input(_key_event(KEY_ENTER))
	var keyboard_state := _core_snapshot()
	var parsed: Dictionary = JSON.parse_string(mouse_state)
	var passed: bool = (
		mouse_restore and touch_restore and keyboard_restore
		and mouse_state == touch_state and touch_state == keyboard_state
		and int(parsed["tableau"][18]) == -1 and int(parsed["score"]) == int(fixture["score"]) + 30
		and int(parsed["waste"].back()) == _cid(6, 2)
	)
	_record("input_clear_mouse_touch_keyboard", passed, JSON.stringify({"mouse":mouse_state, "touch":touch_state, "keyboard":keyboard_state}))


func _test_mouse_touch_keyboard_locked_reject_atomicity() -> void:
	_open_fresh()
	var fixture := _legal_fixture()
	var mouse_restore: bool = game._restore_tripeaks_snapshot(fixture)
	var mouse_before := _core_snapshot()
	_mouse_tap(game._tripeaks_card_center(9))
	var mouse_atomic := _core_snapshot() == mouse_before

	_open_fresh()
	var touch_restore: bool = game._restore_tripeaks_snapshot(fixture)
	var touch_before := _core_snapshot()
	_touch_tap(game._tripeaks_card_center(9))
	var touch_atomic := _core_snapshot() == touch_before

	_open_fresh()
	var keyboard_restore: bool = game._restore_tripeaks_snapshot(fixture)
	game.tripeaks_focus_slot = 9
	game._sync_tripeaks_state()
	var keyboard_before := _core_snapshot()
	game._input(_key_event(KEY_ENTER))
	var keyboard_atomic := _core_snapshot() == keyboard_before
	_record("input_locked_reject_atomic_parity", mouse_restore and touch_restore and keyboard_restore and mouse_atomic and touch_atomic and keyboard_atomic)


func _test_shell_restore_binds_and_neutralizes_focus() -> void:
	_open_fresh()
	game._tripeaks_next()
	var saved: Dictionary = game.tripeaks_model.snapshot()
	game._tripeaks_next()
	var accepted: bool = game._restore_tripeaks_snapshot(saved)
	var passed: bool = (
		accepted and bool(game.state.get("recovered", false))
		and int(game.state.get("focus_slot", -1)) in game.state["exposed_slots"]
		and game.state["stock"].size() == 22 and game.state["waste"].size() == 2
	)
	_record("shell_restore_binding_input_neutral", passed, JSON.stringify(game.state))


func _test_shell_rejects_corrupt_restore_atomically() -> void:
	var pristine := JSON.stringify(game.state)
	var corrupt: Dictionary = game.tripeaks_model.snapshot()
	corrupt["stock"][0] = corrupt["waste"][0]
	var rejected: bool = not game._restore_tripeaks_snapshot(corrupt)
	_record("shell_corrupt_restore_atomic", rejected and JSON.stringify(game.state) == pristine)


func _test_explicit_restart_clears_recovery() -> void:
	game._reset_current()
	var saved: Dictionary = game.state.duplicate(true)
	var passed: bool = (
		_core_snapshot() == opening_snapshot and not bool(saved.get("recovered", true))
		and saved["stock"].size() == 23 and saved["waste"].size() == 1 and int(saved["moves"]) == 0
		and not game.tripeaks_restart_requested
	)
	_record("shell_explicit_restart", passed, JSON.stringify(saved))


func _test_terminal_win_freezes_until_restart() -> void:
	_open_fresh()
	var fixture := _fixture({0:_cid(6, 2)}, _cid(5, 0), [], 2)
	var accepted: bool = game._restore_tripeaks_snapshot(fixture)
	_mouse_tap(game._tripeaks_card_center(0))
	var terminal := _core_snapshot()
	_mouse_tap(game._tripeaks_stock_rect().get_center())
	game._input(_key_event(KEY_ENTER))
	var frozen := terminal == _core_snapshot() and str(game.state.get("status", "")) == "won"
	game._reset_current()
	var restarted := str(game.state.get("status", "")) == "playing" and _core_snapshot() == opening_snapshot
	_record("shell_win_freeze_restart", accepted and frozen and restarted, JSON.stringify({"terminal":terminal, "after":_core_snapshot()}))


func _test_terminal_loss_freezes_until_restart() -> void:
	_open_fresh()
	var fixture := _fixture({
		0:_cid(12, 3), 3:_cid(11, 2), 9:_cid(8, 1), 18:_cid(5, 2),
	}, _cid(2, 0), [_cid(10, 3)])
	var accepted: bool = game._restore_tripeaks_snapshot(fixture)
	_touch_tap(game._tripeaks_stock_rect().get_center())
	var terminal := _core_snapshot()
	_touch_tap(game._tripeaks_card_center(18))
	game._input(_key_event(KEY_M))
	var frozen := terminal == _core_snapshot() and str(game.state.get("status", "")) == "lost"
	game._reset_current()
	var restarted := str(game.state.get("status", "")) == "playing" and _core_snapshot() == opening_snapshot
	_record("shell_loss_freeze_restart", accepted and frozen and restarted, JSON.stringify({"terminal":terminal, "after":_core_snapshot()}))
