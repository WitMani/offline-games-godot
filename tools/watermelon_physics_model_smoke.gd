extends SceneTree

const MODEL = preload("res://models/watermelon_physics_model.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	_test_reset_and_aim()
	_test_drop_travels_before_settle()
	_test_unequal_contact_does_not_merge()
	_test_equal_contact_merges_across_free_space()
	_test_four_ball_cascade()
	_test_tiers_continue_past_fruit_five()
	_test_transient_danger_does_not_fail()
	_test_sustained_danger_fails()
	_test_restart_preserves_best()
	_test_target_progression_stays_open()
	_test_determinism()
	print("WATERMELON_PHYSICS_MODEL_SMOKE=%d" % checks)
	print("WATERMELON_PHYSICS_MODEL_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _test_reset_and_aim() -> void:
	var model = MODEL.new()
	model.reset(1203, false)
	_expect(model.balls.is_empty(), "reset_balls")
	_expect(model.status == model.RUNNING, "reset_status")
	_expect(model.next_tier == 1, "reset_next")
	model.set_aim_x(-100.0)
	_expect(is_equal_approx(model.aim_x, model.LEFT_WALL + model.radius_for_tier(1)), "aim_left_clamp")
	model.set_aim_x(900.0)
	_expect(is_equal_approx(model.aim_x, model.RIGHT_WALL - model.radius_for_tier(1)), "aim_right_clamp")


func _test_drop_travels_before_settle() -> void:
	var model = MODEL.new()
	model.reset(44, false)
	model.set_aim_x(173.0)
	_expect(model.drop(1), "drop_accepted")
	var initial_y := float(model.balls[0]["position"].y)
	var release_events: Array = model.step(0.0)
	_expect(_has_kind(release_events, "ball_released"), "drop_release_event")
	var early_events: Array = model.step(0.10)
	_expect(float(model.balls[0]["position"].y) > initial_y, "drop_gravity_travel")
	_expect(not _has_kind(early_events, "ball_landed"), "drop_not_instant_settle")
	var events: Array = []
	for _index in range(14):
		events.append_array(model.step(0.10))
	_expect(_has_kind(events, "ball_landed"), "drop_landed_event")
	_expect(model.tick > 100, "drop_multiple_ticks")


func _test_unequal_contact_does_not_merge() -> void:
	var model = MODEL.new()
	model.reset(5, false)
	model.inject_ball(1, Vector2(250, 646), Vector2.ZERO, 1)
	model.inject_ball(2, Vector2(278, 646), Vector2.ZERO, 1)
	var events: Array = model.step(model.FIXED_DT)
	_expect(model.balls.size() == 2, "unequal_kept_both")
	_expect(not _has_kind(events, "balls_merged"), "unequal_no_merge")


func _test_equal_contact_merges_across_free_space() -> void:
	var model = MODEL.new()
	model.reset(6, false)
	model.inject_ball(1, Vector2(198, 620), Vector2.ZERO, 1)
	model.inject_ball(1, Vector2(230, 620), Vector2.ZERO, 1)
	var events: Array = model.step(model.FIXED_DT)
	_expect(model.balls.size() == 1, "equal_pair_consumed")
	_expect(int(model.balls[0]["tier"]) == 2, "equal_pair_promoted")
	_expect(model.score == 4, "equal_pair_score")
	_expect(_has_kind(events, "balls_merged"), "equal_pair_event")


func _test_four_ball_cascade() -> void:
	var model = MODEL.new()
	model.reset(7, false)
	for position in [Vector2(240, 600), Vector2(270, 600), Vector2(240, 600), Vector2(270, 600)]:
		model.inject_ball(1, position, Vector2.ZERO, 9)
	var events: Array = model.step(model.FIXED_DT)
	_expect(model.balls.size() == 1, "cascade_one_result")
	_expect(int(model.balls[0]["tier"]) == 3, "cascade_two_levels")
	_expect(_count_kind(events, "balls_merged") == 3, "cascade_three_merges")
	_expect(model.score == 16, "cascade_score")


func _test_tiers_continue_past_fruit_five() -> void:
	var model = MODEL.new()
	model.reset(8, false)
	model.inject_ball(5, Vector2(250, 610), Vector2.ZERO, 2)
	model.inject_ball(5, Vector2(280, 610), Vector2.ZERO, 2)
	model.step(model.FIXED_DT)
	_expect(int(model.balls[0]["tier"]) == 6, "tier_five_not_capped")
	_expect(model.value_for_tier(6) == 64, "tier_six_value")


func _test_transient_danger_does_not_fail() -> void:
	var model = MODEL.new()
	model.reset(9, false)
	model.inject_ball(1, Vector2(270, 338), Vector2(0, 180), 3)
	model.balls[0]["age"] = 1.0
	model.balls[0]["danger_time"] = model.DANGER_HOLD_SECONDS - 0.02
	model.step(model.FIXED_DT)
	_expect(model.status == model.RUNNING, "danger_transient_running")
	_expect(float(model.balls[0]["danger_time"]) < model.DANGER_HOLD_SECONDS - 0.02, "danger_transient_decays")


func _test_sustained_danger_fails() -> void:
	var model = MODEL.new()
	model.reset(10, false)
	model.inject_ball(1, Vector2(270, 338), Vector2.ZERO, 4)
	model.balls[0]["age"] = 1.0
	model.balls[0]["danger_time"] = model.DANGER_HOLD_SECONDS - model.FIXED_DT * 0.5
	var events: Array = model.step(model.FIXED_DT)
	_expect(model.status == model.OVER, "danger_sustained_over")
	_expect(_has_kind(events, "danger_overflow"), "danger_overflow_event")


func _test_restart_preserves_best() -> void:
	var model = MODEL.new()
	model.reset(11, false)
	model.inject_ball(5, Vector2(250, 610), Vector2.ZERO, 5)
	model.inject_ball(5, Vector2(280, 610), Vector2.ZERO, 5)
	model.step(model.FIXED_DT)
	var retained: int = model.best_score
	_expect(retained == 64, "best_recorded")
	model.reset(12, true)
	_expect(model.score == 0 and model.balls.is_empty(), "restart_clears_run")
	_expect(model.best_score == retained, "restart_preserves_best")


func _test_target_progression_stays_open() -> void:
	var model = MODEL.new()
	model.reset(13, false)
	model.inject_ball(7, Vector2(250, 610), Vector2.ZERO, 6)
	model.inject_ball(7, Vector2(280, 610), Vector2.ZERO, 6)
	var events: Array = model.step(model.FIXED_DT)
	_expect(_has_kind(events, "target_reached"), "target_event")
	_expect(model.status == model.RUNNING, "target_keeps_running")
	_expect(model.target_tier == 11, "target_advances_to_2048")


func _test_determinism() -> void:
	var first = MODEL.new()
	var second = MODEL.new()
	for model in [first, second]:
		model.reset(818, false)
		model.set_aim_x(311.0)
		model.drop()
		for _index in range(16):
			model.step(0.07)
	_expect(first.snapshot() == second.snapshot(), "deterministic_snapshot")


func _has_kind(events: Array, kind: String) -> bool:
	for event in events:
		if str(event.get("kind", "")) == kind:
			return true
	return false


func _count_kind(events: Array, kind: String) -> int:
	var count := 0
	for event in events:
		if str(event.get("kind", "")) == kind:
			count += 1
	return count


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
