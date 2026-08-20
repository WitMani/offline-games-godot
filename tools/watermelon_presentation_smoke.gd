extends SceneTree

var game: Control
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_test_runtime_asset_family()
	_test_routine_drop()
	_test_grade_two_merge()
	_test_grade_three_chain()
	_test_grade_four_cascade()
	_test_blocked_spawn_rejection()
	_test_target_promotion_stays_open()
	_test_feedback_font_role()
	_test_effect_cap()
	print("WATERMELON_PRESENTATION_SMOKE=9")
	print("WATERMELON_PRESENTATION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _test_runtime_asset_family() -> void:
	for value in range(1, 6):
		var texture: Texture2D = game.watermelon_presenter.FRUIT_TEXTURES.get(value)
		_expect(texture != null, "asset_%d_missing" % value)
		if texture != null:
			_expect(texture.resource_path.begins_with("res://assets/art/2048balls/fruit_"), "asset_%d_wrong_path" % value)
			_expect(texture.get_width() >= 200 and texture.get_height() >= 200, "asset_%d_too_small" % value)
	var burst: Texture2D = game.watermelon_presenter.JUICE_BURST
	_expect(burst != null and burst.resource_path.ends_with("juice_merge_burst.png"), "burst_missing")
	var tray: Texture2D = game.watermelon_presenter.RECIPE_TRAY
	_expect(tray != null and tray.resource_path.ends_with("orchard_recipe_tray_gag_v3.webp"), "recipe_tray_missing")
	if tray != null:
		_expect(tray.get_width() == 792 and tray.get_height() == 239, "recipe_tray_dimensions")
		_expect(tray.resource_path.begins_with("res://assets/art/2048balls/"), "recipe_tray_wrong_path")


func _test_routine_drop() -> void:
	game._open_game("watermelon")
	game._watermelon_drop_at(170.0)
	_advance_model(1.25)
	_expect_event("routine", "fruit_drop", 1)
	_expect(int(game.state.get("balls", []).size()) == 1, "routine_ball_state")
	_expect(float(game.state["balls"][0]["position"][1]) > game.watermelon_model.SPAWN_Y, "routine_visible_travel")
	_expect(_any_stream_path("fruit_drop.ogg"), "routine_audio")


func _test_grade_two_merge() -> void:
	game._open_game("watermelon")
	game.watermelon_model.inject_ball(1, Vector2(198, 620), Vector2.ZERO, 7)
	game.watermelon_model.inject_ball(1, Vector2(230, 620), Vector2.ZERO, 7)
	game._watermelon_update(game.watermelon_model.FIXED_DT)
	_expect_event("merge", "fruit_merge", 2)
	_expect(game.state["balls"].size() == 1 and int(game.state["balls"][0]["tier"]) == 2, "merge_state")
	_expect(_any_stream_path("fruit_merge.ogg"), "merge_audio")


func _test_grade_three_chain() -> void:
	game._open_game("watermelon")
	_merge_pair_at(1, Vector2(250, 610), 9)
	var result_position := _first_ball_position()
	game.watermelon_model.inject_ball(2, result_position, Vector2.ZERO, 9)
	game._watermelon_update(game.watermelon_model.FIXED_DT)
	_expect_event("chain", "fruit_merge", 3)
	_expect(game.state["balls"].size() == 1 and int(game.state["balls"][0]["tier"]) == 3, "chain_state")
	_expect(_any_stream_path("fruit_cascade.ogg"), "chain_audio")


func _test_grade_four_cascade() -> void:
	game._open_game("watermelon")
	_merge_pair_at(1, Vector2(250, 610), 11)
	game.watermelon_model.inject_ball(2, _first_ball_position(), Vector2.ZERO, 11)
	game._watermelon_update(game.watermelon_model.FIXED_DT)
	game.watermelon_model.inject_ball(3, _first_ball_position(), Vector2.ZERO, 11)
	game._watermelon_update(game.watermelon_model.FIXED_DT)
	_expect_event("cascade", "fruit_merge", 4)
	_expect(game.state["balls"].size() == 1 and int(game.state["balls"][0]["tier"]) == 4, "cascade_state")
	_expect(int(game.catalog_fx.back().get("result_id", -1)) == int(game.state["balls"][0]["id"]), "cascade_result_identity")
	_expect(_any_stream_path("fruit_cascade.ogg"), "cascade_audio")


func _test_blocked_spawn_rejection() -> void:
	game._open_game("watermelon")
	var aim_x := float(game.watermelon_model.aim_x)
	game.watermelon_model.inject_ball(1, Vector2(aim_x, game.watermelon_model.SPAWN_Y), Vector2.ZERO, 0)
	game._sync_watermelon_state()
	var before_moves := int(game.state["moves"])
	var before_count := int(game.state["balls"].size())
	game._watermelon_drop_current()
	_expect_event("blocked", "fruit_error_drop", 2)
	_expect(int(game.state["balls"].size()) == before_count, "blocked_mutated_balls")
	_expect(int(game.state["moves"]) == before_moves, "blocked_mutated_moves")


func _test_target_promotion_stays_open() -> void:
	game._open_game("watermelon")
	game.watermelon_model.inject_ball(7, Vector2(250, 610), Vector2.ZERO, 13)
	game.watermelon_model.inject_ball(7, Vector2(280, 610), Vector2.ZERO, 13)
	game._watermelon_update(game.watermelon_model.FIXED_DT)
	_expect_event("target", "fruit_harvest_complete", 4)
	_expect(str(game.state["status"]) == "playing", "target_must_stay_open")
	_expect(int(game.state["target_value"]) == 2048, "target_must_advance")


func _test_feedback_font_role() -> void:
	for sample in ["左右拖动瞄准，松手投放", "8 连携×2 · +8", "目标 256 达成 · 继续挑战 2048", "果球越过危险线"]:
		for index in range(sample.length()):
			_expect(game.UI_FONT.has_char(sample.unicode_at(index)), "font_U+%04X" % sample.unicode_at(index))


func _test_effect_cap() -> void:
	game._open_game("watermelon")
	for index in range(12):
		game._start_catalog_event("fruit_merge", Vector2(70 + index % 7 * 62, 668), Color.WHITE, 4, "16 连携×3", 0.92)
	_expect(game.catalog_fx.size() == 6, "fruit_effect_cap")


func _merge_pair_at(tier: int, position: Vector2, shot_id: int) -> void:
	var radius: float = game.watermelon_model.radius_for_tier(tier)
	game.watermelon_model.inject_ball(tier, position - Vector2(radius * 0.72, 0), Vector2.ZERO, shot_id)
	game.watermelon_model.inject_ball(tier, position + Vector2(radius * 0.72, 0), Vector2.ZERO, shot_id)
	game._watermelon_update(game.watermelon_model.FIXED_DT)


func _first_ball_position() -> Vector2:
	return Vector2(game.watermelon_model.balls[0]["position"])


func _advance_model(seconds: float) -> void:
	var remaining := seconds
	while remaining > 0.0 and game.state.get("status") == "playing":
		var slice := minf(0.05, remaining)
		game._watermelon_update(slice)
		remaining -= slice


func _expect_event(test_name: String, kind: String, grade: int) -> void:
	if game.catalog_fx.is_empty():
		failures.append("%s_no_event" % test_name)
		return
	var effect: Dictionary = game.catalog_fx.back()
	_expect(str(effect.get("game_id", "")) == "watermelon", "%s_game" % test_name)
	_expect(str(effect.get("kind", "")) == kind, "%s_kind_%s" % [test_name, effect.get("kind", "")])
	_expect(int(effect.get("grade", 0)) == grade, "%s_grade_%s" % [test_name, effect.get("grade", 0)])
	_expect(not str(effect.get("label", "")).is_empty(), "%s_label" % test_name)


func _any_stream_path(suffix: String) -> bool:
	for player in game.sfx_players:
		if player.stream != null and player.stream.resource_path.ends_with(suffix):
			return true
	return false


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
