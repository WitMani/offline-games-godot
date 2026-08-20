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
	_test_full_column_rejection()
	_test_harvest_promotion()
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


func _test_routine_drop() -> void:
	game._open_game("watermelon")
	game.state["next"] = 1
	game._water_drop(0)
	_expect_event("routine", "fruit_drop", 1)
	_expect(int(game.state["columns"][0].size()) == 1, "routine_state")
	_expect(_any_stream_path("fruit_drop.ogg"), "routine_audio")


func _test_grade_two_merge() -> void:
	game._open_game("watermelon")
	game.state["columns"][1] = [1]
	game.state["next"] = 1
	game._water_drop(1)
	_expect_event("merge", "fruit_merge", 2)
	_expect(game.state["columns"][1] == [2], "merge_state")
	_expect(_any_stream_path("fruit_merge.ogg"), "merge_audio")


func _test_grade_three_chain() -> void:
	game._open_game("watermelon")
	game.state["columns"][5] = [2, 1]
	game.state["next"] = 1
	game._water_drop(5)
	_expect_event("chain", "fruit_merge", 3)
	_expect(game.state["columns"][5] == [3], "chain_state")
	_expect(_any_stream_path("fruit_cascade.ogg"), "chain_audio")


func _test_grade_four_cascade() -> void:
	game._open_game("watermelon")
	game.state["columns"][3] = [3, 2, 2, 1]
	game.state["next"] = 1
	game._water_drop(3)
	_expect_event("cascade", "fruit_merge", 4)
	_expect(game.state["columns"][3] == [4, 2], "cascade_state")
	_expect(is_equal_approx(float(game.catalog_fx.back()["position"].y), 668.0), "cascade_wrong_contact")
	_expect(_any_stream_path("fruit_cascade.ogg"), "cascade_audio")


func _test_full_column_rejection() -> void:
	game._open_game("watermelon")
	game.state["columns"][2] = [1, 2, 3, 4, 5, 1, 2]
	var before: Dictionary = game.state.duplicate(true)
	game._water_drop(2)
	_expect_event("full", "fruit_error_full", 2)
	_expect(game.state["columns"] == before["columns"], "full_mutated_columns")
	_expect(int(game.state["moves"]) == int(before["moves"]), "full_mutated_moves")


func _test_harvest_promotion() -> void:
	game._open_game("watermelon")
	game.state["score"] = 990
	game.state["columns"][4] = [1]
	game.state["next"] = 1
	game._water_drop(4)
	_expect_event("harvest", "fruit_harvest_complete", 4)
	_expect(str(game.state["status"]) == "won", "harvest_status")


func _test_feedback_font_role() -> void:
	for sample in ["柠檬落箱", "葡萄连携 · +80", "丰收完成 · +20", "换一条轨道"]:
		for index in range(sample.length()):
			_expect(game.UI_FONT.has_char(sample.unicode_at(index)), "font_U+%04X" % sample.unicode_at(index))


func _test_effect_cap() -> void:
	game._open_game("watermelon")
	for index in range(12):
		game._start_catalog_event("fruit_merge", Vector2(70 + index % 7 * 62, 668), Color.WHITE, 4, "葡萄连携", 0.92)
	_expect(game.catalog_fx.size() == 6, "fruit_effect_cap")


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
