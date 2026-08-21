extends SceneTree

const GAME_ID := "solitaire"
const MODEL_PATH := "res://models/solitaire_model.gd"
const EXPECTED_CASES := 8

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
	await process_frame
	_test_shell_exposes_complete_versioned_state()
	_test_mouse_touch_keyboard_draw_parity()
	_test_mouse_touch_keyboard_tableau_move_parity()
	_test_shell_reject_is_model_atomic()
	_test_shell_restore_binds_and_neutralizes_selection()
	_test_shell_rejects_corrupt_restore_atomically()
	_test_explicit_restart_clears_recovery()
	_test_terminal_shell_freezes_until_restart()
	_dispose_game()
	await process_frame
	await process_frame
	_finish()


func _finish() -> void:
	if cases_run != EXPECTED_CASES:
		failures.append("case_count_%d_of_%d" % [cases_run, EXPECTED_CASES])
	print("SOLITAIRE_V3_RUNTIME_CASES=%d" % cases_run)
	print("SOLITAIRE_V3_RUNTIME_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
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
	for player in game.sfx_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	game.free()


func _open_fresh() -> void:
	game._open_game(GAME_ID)


func _core_snapshot() -> String:
	return JSON.stringify(game.solitaire_model.snapshot())


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


func _cid(rank: int, suit: int) -> int:
	return suit * 13 + rank - 1


func _fixture(piles: Array, waste: Array = [], foundation_counts: Array = [0, 0, 0, 0]) -> Dictionary:
	var saved: Dictionary = game.solitaire_model.snapshot()
	var used := {}
	var foundations: Array = []
	for suit in range(4):
		var foundation: Array = []
		for rank in range(1, int(foundation_counts[suit]) + 1):
			var card := _cid(rank, suit)
			used[card] = true
			foundation.append(card)
		foundations.append(foundation)
	var tableau: Array = []
	for column in range(7):
		var pile: Array = piles[column].duplicate(true) if column < piles.size() else []
		for entry in pile:
			used[int(entry["card"])] = true
		tableau.append(pile)
	var normalized_waste: Array = []
	for value in waste:
		used[int(value)] = true
		normalized_waste.append(int(value))
	var stock: Array = []
	for card in range(52):
		if not used.has(card):
			stock.append(card)
	saved["stock"] = stock
	saved["waste"] = normalized_waste
	saved["tableau"] = tableau
	saved["foundations"] = foundations
	saved["score"] = 0
	saved["moves"] = 0
	saved["recycles_used"] = 0
	saved["status"] = "playing"
	return saved


func _test_shell_exposes_complete_versioned_state() -> void:
	_open_fresh()
	var saved: Dictionary = game.state.duplicate(true)
	opening_snapshot = _core_snapshot()
	var cards := {}
	for value in saved["stock"]:
		cards[int(value)] = true
	for pile in saved["tableau"]:
		for entry in pile:
			cards[int(entry["card"])] = true
	var passed: bool = (
		str(saved.get("schema", "")) == "solitaire-state/v1"
		and str(saved.get("game_id", "")) == GAME_ID
		and saved["stock"].size() == 24
		and saved["tableau"].size() == 7
		and cards.size() == 52
		and not bool(saved.get("recovered", true))
	)
	_record("shell_versioned_complete_state", passed, JSON.stringify(saved))


func _test_mouse_touch_keyboard_draw_parity() -> void:
	_open_fresh()
	_mouse_tap(Vector2(74, 306))
	var mouse_state := _core_snapshot()
	_open_fresh()
	_touch_tap(Vector2(74, 306))
	var touch_state := _core_snapshot()
	_open_fresh()
	game._input(_key_event(KEY_ENTER))
	var keyboard_state := _core_snapshot()
	var parsed: Dictionary = JSON.parse_string(mouse_state)
	var passed: bool = mouse_state == touch_state and touch_state == keyboard_state and parsed["stock"].size() == 23 and parsed["waste"].size() == 1 and int(parsed["moves"]) == 1
	_record("input_draw_mouse_touch_keyboard", passed, JSON.stringify({"mouse":mouse_state, "touch":touch_state, "keyboard":keyboard_state}))


func _test_mouse_touch_keyboard_tableau_move_parity() -> void:
	_open_fresh()
	var fixture := _fixture([
		[{"card":_cid(9, 3), "face_up":true}],
		[{"card":_cid(10, 2), "face_up":true}],
	])
	var accepted_mouse: bool = game._restore_solitaire_snapshot(fixture)
	_mouse_tap(Vector2(63, 448))
	_mouse_tap(Vector2(131, 448))
	var mouse_state := _core_snapshot()

	_open_fresh()
	var accepted_touch: bool = game._restore_solitaire_snapshot(fixture)
	_touch_tap(Vector2(63, 448))
	_touch_tap(Vector2(131, 448))
	var touch_state := _core_snapshot()

	_open_fresh()
	var accepted_keyboard: bool = game._restore_solitaire_snapshot(fixture)
	game._input(_key_event(KEY_DOWN))
	game._input(_key_event(KEY_ENTER))
	game._input(_key_event(KEY_RIGHT))
	game._input(_key_event(KEY_ENTER))
	var keyboard_state := _core_snapshot()
	var parsed: Dictionary = JSON.parse_string(mouse_state)
	var passed: bool = (
		accepted_mouse and accepted_touch and accepted_keyboard
		and mouse_state == touch_state and touch_state == keyboard_state
		and parsed["tableau"][0].is_empty() and parsed["tableau"][1].size() == 2
	)
	_record("input_move_mouse_touch_keyboard", passed, JSON.stringify({"mouse":mouse_state, "touch":touch_state, "keyboard":keyboard_state}))


func _test_shell_reject_is_model_atomic() -> void:
	_open_fresh()
	var fixture := _fixture([
		[{"card":_cid(9, 1), "face_up":true}],
		[{"card":_cid(10, 3), "face_up":true}],
	])
	var accepted: bool = game._restore_solitaire_snapshot(fixture)
	_mouse_tap(Vector2(63, 448))
	var before := _core_snapshot()
	_mouse_tap(Vector2(131, 448))
	var passed: bool = accepted and _core_snapshot() == before and str(game.solitaire_selection.get("kind", "")) == "tableau"
	_record("shell_illegal_move_atomic", passed, JSON.stringify(game.solitaire_selection))


func _test_shell_restore_binds_and_neutralizes_selection() -> void:
	_open_fresh()
	game._solitaire_draw()
	game._solitaire_activate_waste()
	var saved: Dictionary = game.solitaire_model.snapshot()
	game._solitaire_draw()
	var accepted: bool = game._restore_solitaire_snapshot(saved)
	var passed: bool = (
		accepted and bool(game.state.get("recovered", false))
		and game.solitaire_selection.is_empty()
		and str(game.state.get("keyboard_zone", "")) == "top"
		and int(game.state.get("keyboard_index", -1)) == 0
		and game.state["waste"].size() == 1
	)
	_record("shell_restore_binding_input_neutral", passed, JSON.stringify(game.state))


func _test_shell_rejects_corrupt_restore_atomically() -> void:
	var pristine := JSON.stringify(game.state)
	var corrupt: Dictionary = game.solitaire_model.snapshot()
	corrupt["stock"][0] = corrupt["stock"][1]
	var rejected: bool = not game._restore_solitaire_snapshot(corrupt)
	_record("shell_corrupt_restore_atomic", rejected and JSON.stringify(game.state) == pristine)


func _test_explicit_restart_clears_recovery() -> void:
	game._reset_current()
	var saved: Dictionary = game.state.duplicate(true)
	var passed: bool = (
		_core_snapshot() == opening_snapshot
		and not bool(saved.get("recovered", true))
		and saved["stock"].size() == 24
		and saved["waste"].is_empty()
		and int(saved["moves"]) == 0
		and not game.solitaire_restart_requested
	)
	_record("shell_explicit_restart", passed, JSON.stringify(saved))


func _test_terminal_shell_freezes_until_restart() -> void:
	_open_fresh()
	var fixture := _fixture([], [_cid(13, 3)], [13, 13, 13, 12])
	# The fixture helper fills all unassigned cards into stock. For this terminal
	# edge there are no unassigned cards, so the stock remains empty.
	var accepted: bool = game._restore_solitaire_snapshot(fixture)
	_mouse_tap(Vector2(168, 306))
	_mouse_tap(game._solitaire_foundation_rect(3).get_center())
	var terminal := _core_snapshot()
	_mouse_tap(Vector2(74, 306))
	game._input(_key_event(KEY_F))
	var frozen: bool = terminal == _core_snapshot() and str(game.state.get("status", "")) == "won"
	game._reset_current()
	var restarted: bool = str(game.state.get("status", "")) == "playing" and _core_snapshot() == opening_snapshot
	_record("shell_terminal_freeze_restart", accepted and frozen and restarted, JSON.stringify({"terminal":terminal, "after":_core_snapshot()}))
