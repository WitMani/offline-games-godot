extends SceneTree

const GB_ID := "snake_classic"
const ARENA_ID := "snake_io"
const EXPECTED_CASES := 11

var game: Control
var failures: Array[String] = []
var cases_run := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate() as Control
	root.add_child(game)
	await process_frame
	# Both modes advance automatically. Freeze the frame loop so every assertion
	# below is driven by exactly one user input and the explicit shell update.
	game.set_process(false)
	_disable_shell_audio()
	await process_frame

	_test_gb_hardware_dpad_routes_a_turn()
	_test_gb_keyboard_routes_a_turn()
	_test_gb_touch_swipe_routes_before_release()
	_test_gb_held_finger_does_not_prebuffer_future_corner()
	_test_gb_held_finger_can_turn_again_after_tick()
	_test_arena_moves_continuously_through_shell_update()
	_test_arena_screen_pointer_steers_and_releases()
	_test_arena_keyboard_sets_a_cardinal_aim()
	_test_arena_cardinal_aim_remains_directional()
	_test_arena_boost_sources_do_not_cancel_each_other()
	_test_arena_boost_button_holds_and_releases()

	_dispose_game()
	await process_frame
	await process_frame
	_finish()


func _finish() -> void:
	if cases_run != EXPECTED_CASES:
		failures.append("case_count_%d_of_%d" % [cases_run, EXPECTED_CASES])
	print("SNAKE_INPUT_SMOKE_CASES=%d" % cases_run)
	print("SNAKE_INPUT_SMOKE_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _record(case_name: String, passed: bool, evidence: String = "") -> void:
	cases_run += 1
	if passed:
		return
	failures.append(case_name + ("=" + evidence if not evidence.is_empty() else ""))


func _dispose_game() -> void:
	# Explicitly detach any still-playing samples before freeing the shell. The
	# dummy headless audio driver otherwise retains its playback for one tick.
	for player in game.sfx_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	game.free()


func _disable_shell_audio() -> void:
	# Audio behavior has its own smoke coverage. Keeping voices detached here
	# prevents asynchronous playback from outliving this short-lived SceneTree.
	for player in game.sfx_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
			player.free()
	game.sfx_players.clear()


func _open_mode(id: String) -> void:
	game._open_game(id)
	# _open_game replaces game.buttons synchronously. We intentionally do not
	# await a frame here because the game process is frozen.


func _test_gb_hardware_dpad_routes_a_turn() -> void:
	_open_mode(GB_ID)
	var up_button := _find_direction_button(Vector2i.UP)
	if up_button:
		up_button.pressed.emit()
	var queued: Dictionary = game.state.duplicate(true)
	game._snake_gb_step()
	var applied: Dictionary = game.state.duplicate(true)
	var passed: bool = (
		up_button != null
		and up_button.size == Vector2(54, 54)
		and queued.get("turn_queue", []) == [[0, -1]]
		and applied.get("direction", []) == [0, -1]
		and applied.get("segments", [])[0] == [7, 10]
		and game.snake_button_direction == Vector2i.UP
	)
	_record("gb_hardware_dpad_turn", passed, JSON.stringify({"queued":queued, "applied":applied}))


func _test_gb_keyboard_routes_a_turn() -> void:
	_open_mode(GB_ID)
	game._input(_key_event(KEY_UP, true))
	var queued: Dictionary = game.state.duplicate(true)
	game._snake_gb_step()
	var applied: Dictionary = game.state.duplicate(true)
	var passed: bool = (
		queued.get("turn_queue", []) == [[0, -1]]
		and applied.get("direction", []) == [0, -1]
		and int(applied.get("moves", -1)) == 1
	)
	_record("gb_keyboard_turn", passed, JSON.stringify({"queued":queued, "applied":applied}))


func _test_gb_touch_swipe_routes_before_release() -> void:
	_open_mode(GB_ID)
	game._unhandled_input(_touch_event(Vector2(300, 500), true))
	game._unhandled_input(_drag_event(Vector2(300, 454), Vector2(0, -46)))
	var before_release: Dictionary = game.state.duplicate(true)
	var active_before_release: bool = bool(game.snake_drag_active)
	game._unhandled_input(_touch_event(Vector2(300, 454), false))
	game._snake_gb_step()
	var applied: Dictionary = game.state.duplicate(true)
	var passed: bool = (
		active_before_release
		and before_release.get("turn_queue", []) == [[0, -1]]
		and not bool(game.snake_drag_active)
		and applied.get("direction", []) == [0, -1]
		and applied.get("segments", [])[0] == [7, 10]
	)
	_record("gb_touch_before_release", passed, JSON.stringify({"before_release":before_release, "applied":applied}))


func _test_gb_held_finger_does_not_prebuffer_future_corner() -> void:
	_open_mode(GB_ID)
	game._unhandled_input(_touch_event(Vector2(300, 500), true))
	game._unhandled_input(_drag_event(Vector2(300, 454), Vector2(0, -46)))
	var first_queue: Array = game.state.get("turn_queue", []).duplicate(true)
	game.elapsed += 0.10
	game._unhandled_input(_drag_event(Vector2(249, 454), Vector2(-51, 0)))
	var after_future_corner: Dictionary = game.state.duplicate(true)
	game._unhandled_input(_touch_event(Vector2(249, 454), false))
	var passed: bool = (
		first_queue == [[0, -1]]
		and after_future_corner.get("turn_queue", []) == [[0, -1]]
		and after_future_corner.get("direction", []) == [1, 0]
	)
	_record("gb_no_future_corner_prebuffer", passed, JSON.stringify(after_future_corner))


func _test_gb_held_finger_can_turn_again_after_tick() -> void:
	_open_mode(GB_ID)
	game._unhandled_input(_touch_event(Vector2(300, 500), true))
	game._unhandled_input(_drag_event(Vector2(300, 454), Vector2(0, -46)))
	game._snake_gb_step()
	var after_first: Dictionary = game.state.duplicate(true)
	game.elapsed += 0.10
	game._unhandled_input(_drag_event(Vector2(249, 454), Vector2(-51, 0)))
	var second_queue: Dictionary = game.state.duplicate(true)
	game._unhandled_input(_touch_event(Vector2(249, 454), false))
	game._snake_gb_step()
	var after_second: Dictionary = game.state.duplicate(true)
	var passed: bool = (
		after_first.get("direction", []) == [0, -1]
		and second_queue.get("turn_queue", []) == [[-1, 0]]
		and after_second.get("direction", []) == [-1, 0]
		and after_second.get("segments", [])[0] == [6, 10]
	)
	_record("gb_held_finger_second_turn", passed, JSON.stringify({"after_first":after_first, "second_queue":second_queue, "after_second":after_second}))


func _test_arena_moves_continuously_through_shell_update() -> void:
	_open_mode(ARENA_ID)
	var before: Dictionary = game.state.duplicate(true)
	game._snakes_arena_update(1.0 / 60.0)
	var after: Dictionary = game.state.duplicate(true)
	var before_position := _packed_vector(before.get("player", {}).get("position", []))
	var after_position := _packed_vector(after.get("player", {}).get("position", []))
	var passed: bool = (
		after_position.distance_to(before_position) > 1.0
		and int(after.get("tick", -1)) == 1
		and int(after.get("moves", -1)) == 1
		and bool(after.get("started", false))
		and int(after.get("score", -1)) == roundi(float(after.get("mass", -1.0)))
	)
	_record("arena_continuous_shell_update", passed, JSON.stringify({"before":before_position, "after":after}))


func _test_arena_screen_pointer_steers_and_releases() -> void:
	_open_mode(ARENA_ID)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(270, 393)
	game._gui_input(press)
	var active_after_press: bool = bool(game.arena_pointer_active)
	game._snakes_arena_update(0.10)
	var steered: Dictionary = game.state.duplicate(true)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(270, 393)
	game._gui_input(release)
	var passed: bool = (
		active_after_press
		and not bool(game.arena_pointer_active)
		and float(steered.get("player", {}).get("heading", 0.0)) < -0.01
		and int(steered.get("moves", 0)) >= 5
	)
	_record("arena_screen_pointer_steers", passed, JSON.stringify(steered.get("player", {})))


func _test_arena_keyboard_sets_a_cardinal_aim() -> void:
	_open_mode(ARENA_ID)
	game._input(_key_event(KEY_DOWN, true))
	game._snakes_arena_update(0.10)
	var after: Dictionary = game.state.duplicate(true)
	var passed: bool = (
		float(after.get("player", {}).get("heading", 0.0)) > 0.01
		and bool(game.arena_tutorial_dismissed)
		and int(after.get("moves", 0)) >= 5
	)
	_record("arena_keyboard_cardinal_aim", passed, JSON.stringify(after.get("player", {})))


func _test_arena_cardinal_aim_remains_directional() -> void:
	_open_mode(ARENA_ID)
	game.snakes_arena_model.reset(1362026, 0, 0)
	game.snakes_arena_model.target_pellet_count = 0
	game._sync_snakes_arena_state()
	game._set_snake_direction(Vector2i.RIGHT)
	for _tick in range(260):
		game._snakes_arena_update(1.0 / 60.0)
	var after: Dictionary = game.state.duplicate(true)
	var heading := float(after.get("player", {}).get("heading", 99.0))
	var position := _packed_vector(after.get("player", {}).get("position", []))
	var passed: bool = (
		after.get("status") == "playing"
		and position.x > 450.0
		and absf(heading) < 0.05
		and absf(position.y) < 1.0
	)
	_record("arena_cardinal_aim_stays_directional", passed, JSON.stringify({"position":position, "heading":heading}))


func _test_arena_boost_sources_do_not_cancel_each_other() -> void:
	_open_mode(ARENA_ID)
	game._input(_key_event(KEY_SPACE, true))
	game._input(_key_event(KEY_SHIFT, true))
	game._input(_key_event(KEY_SHIFT, false))
	var active_after_shift_release := bool(game.arena_boost_active)
	game._input(_key_event(KEY_SPACE, false))
	var inactive_after_all_release := not bool(game.arena_boost_active)
	var passed := active_after_shift_release and inactive_after_all_release
	_record("arena_boost_sources_are_independent", passed, JSON.stringify({"after_shift_release":active_after_shift_release, "after_all_release":not inactive_after_all_release}))


func _test_arena_boost_button_holds_and_releases() -> void:
	_open_mode(ARENA_ID)
	var boost_button := _find_arena_boost_button()
	if boost_button:
		boost_button.button_down.emit()
	var request_active: bool = bool(game.arena_boost_active)
	game._snakes_arena_update(0.14)
	var during: Dictionary = game.state.duplicate(true)
	if boost_button:
		boost_button.button_up.emit()
	var request_released: bool = not bool(game.arena_boost_active)
	game._snakes_arena_update(1.0 / 60.0)
	var after: Dictionary = game.state.duplicate(true)
	var passed: bool = (
		boost_button != null
		and bool(boost_button.get_meta("arena_boost", false))
		and boost_button.tooltip_text == "按住冲刺"
		and boost_button.size == Vector2(92, 92)
		and request_active
		and bool(during.get("player", {}).get("boosting", false))
		and request_released
		and not bool(after.get("player", {}).get("boosting", true))
	)
	_record("arena_boost_hold_release", passed, JSON.stringify({
		"button_found":boost_button != null,
		"button_name":str(boost_button.name) if boost_button else "",
		"button_size":[boost_button.size.x, boost_button.size.y] if boost_button else [],
		"request_active":request_active,
		"request_released":request_released,
		"during":during.get("player", {}),
		"after":after.get("player", {})
	}))


func _find_direction_button(direction: Vector2i) -> Button:
	for candidate in game.buttons:
		if candidate is Button and candidate.has_meta("snake_direction") and candidate.get_meta("snake_direction") == direction:
			return candidate as Button
	return null


func _find_arena_boost_button() -> Button:
	for candidate in game.buttons:
		if candidate is Button and bool(candidate.get_meta("arena_boost", false)):
			return candidate as Button
	return null


func _key_event(keycode: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = pressed
	event.echo = false
	return event


func _touch_event(position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = position
	event.pressed = pressed
	return event


func _drag_event(position: Vector2, relative: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = position
	event.relative = relative
	return event


func _packed_vector(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
