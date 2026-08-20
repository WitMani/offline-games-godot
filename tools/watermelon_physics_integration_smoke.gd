extends SceneTree

var game: Control
var failures: Array[String] = []
var checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_test_contract_state()
	_test_mouse_release_route()
	_test_touch_drag_route()
	_test_free_collision_route()
	_test_danger_and_restart()
	_test_open_target_route()
	print("WATERMELON_PHYSICS_INTEGRATION_SMOKE=%d" % checks)
	print("WATERMELON_PHYSICS_INTEGRATION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _test_contract_state() -> void:
	game._open_game("watermelon")
	_expect(game.state.has("balls"), "state_balls")
	_expect(not game.state.has("columns"), "state_no_columns")
	_expect(int(game.state["next_value"]) == 2, "state_next_value")
	_expect(int(game.state["target_value"]) == 256, "state_first_target")
	_expect(str(game.state["status"]) == "playing", "state_running")
	_expect(JSON.stringify(game.state).contains("aim_x"), "state_json_safe")


func _test_mouse_release_route() -> void:
	game._open_game("watermelon")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(144, 500)
	game._gui_input(press)
	_expect(is_equal_approx(float(game.state["aim_x"]), 144.0), "mouse_press_aim")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(337, 500)
	game._gui_input(release)
	_expect(int(game.state["moves"]) == 1, "mouse_release_drop")
	_expect(game.state["balls"].size() == 1, "mouse_ball_created")
	_expect(is_equal_approx(float(game.state["balls"][0]["position"][0]), 337.0), "mouse_continuous_x")
	var initial_y := float(game.state["balls"][0]["position"][1])
	game._watermelon_update(0.10)
	_expect(float(game.state["balls"][0]["position"][1]) > initial_y, "mouse_visible_fall")
	_expect(float(game.state["balls"][0]["position"][1]) < game.watermelon_model.FLOOR_Y, "mouse_not_instant_floor")


func _test_touch_drag_route() -> void:
	game._open_game("watermelon")
	var press := InputEventScreenTouch.new()
	press.pressed = true
	press.position = Vector2(110, 480)
	game._unhandled_input(press)
	var drag := InputEventScreenDrag.new()
	drag.position = Vector2(405, 480)
	game._unhandled_input(drag)
	_expect(is_equal_approx(float(game.state["aim_x"]), 405.0), "touch_drag_aim")
	var release := InputEventScreenTouch.new()
	release.pressed = false
	release.position = Vector2(405, 480)
	game._unhandled_input(release)
	_expect(int(game.state["moves"]) == 1, "touch_release_drop")
	_expect(is_equal_approx(float(game.state["balls"][0]["position"][0]), 405.0), "touch_continuous_x")


func _test_free_collision_route() -> void:
	game._open_game("watermelon")
	game.watermelon_model.inject_ball(1, Vector2(202, 614), Vector2.ZERO, 21)
	game.watermelon_model.inject_ball(1, Vector2(233, 614), Vector2.ZERO, 21)
	game._watermelon_update(game.watermelon_model.FIXED_DT)
	_expect(game.state["balls"].size() == 1, "free_contact_consumes_pair")
	_expect(int(game.state["balls"][0]["tier"]) == 2, "free_contact_promotes")
	_expect(int(game.state["score"]) == 4, "free_contact_scores")
	_expect(str(game.catalog_fx.back().get("kind", "")) == "fruit_merge", "free_contact_event")
	_expect(int(game.catalog_fx.back().get("result_id", -1)) == int(game.state["balls"][0]["id"]), "free_contact_identity")


func _test_danger_and_restart() -> void:
	game._open_game("watermelon")
	game.watermelon_model.inject_ball(5, Vector2(250, 610), Vector2.ZERO, 30)
	game.watermelon_model.inject_ball(5, Vector2(280, 610), Vector2.ZERO, 30)
	game._watermelon_update(game.watermelon_model.FIXED_DT)
	var retained_best := int(game.state["best"])
	_expect(retained_best == 64, "restart_best_setup")
	game.watermelon_model.inject_ball(1, Vector2(270, 338), Vector2.ZERO, 31)
	var danger_ball: Dictionary = game.watermelon_model.balls.back()
	danger_ball["age"] = 1.0
	danger_ball["danger_time"] = game.watermelon_model.DANGER_HOLD_SECONDS - game.watermelon_model.FIXED_DT * 0.5
	game.watermelon_model.balls[game.watermelon_model.balls.size() - 1] = danger_ball
	game._watermelon_update(game.watermelon_model.FIXED_DT)
	_expect(str(game.state["status"]) == "over", "danger_over")
	_expect(str(game.catalog_fx.back().get("kind", "")) == "fruit_error_overflow", "danger_event")
	game._reset_current()
	_expect(str(game.state["status"]) == "playing", "restart_running")
	_expect(game.state["balls"].is_empty(), "restart_clears_balls")
	_expect(int(game.state["best"]) == retained_best, "restart_preserves_best")


func _test_open_target_route() -> void:
	game._open_game("watermelon")
	game.watermelon_model.inject_ball(7, Vector2(250, 610), Vector2.ZERO, 40)
	game.watermelon_model.inject_ball(7, Vector2(280, 610), Vector2.ZERO, 40)
	game._watermelon_update(game.watermelon_model.FIXED_DT)
	_expect(str(game.state["status"]) == "playing", "target_not_terminal")
	_expect(int(game.state["target_value"]) == 2048, "target_advances")
	_expect(str(game.catalog_fx.back().get("kind", "")) == "fruit_harvest_complete", "target_event_promoted")
	_expect(not game.state.has("win"), "target_no_hidden_win")


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
