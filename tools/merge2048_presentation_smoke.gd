extends SceneTree

var game: Control
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_test_runtime_assets()
	_test_material_tiers()
	_test_line_resolution_metadata()
	_test_slide_motion()
	_test_rejection_invariant()
	_test_feedback_grades()
	_test_target_promotion()
	print("MERGE2048_PRESENTATION_SMOKE=%d" % 7)
	print("MERGE2048_PRESENTATION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _test_runtime_assets() -> void:
	for path in [
		"res://assets/art/merge2048/tile_tier_1.png",
		"res://assets/art/merge2048/tile_tier_2.png",
		"res://assets/art/merge2048/tile_tier_3.png",
		"res://assets/art/merge2048/tile_tier_4.png",
		"res://assets/art/merge2048/wood_shaving_burst.png",
		"res://assets/audio/merge2048/tile_slide.ogg",
		"res://assets/audio/merge2048/tile_merge.ogg",
		"res://assets/audio/merge2048/tile_milestone.ogg",
	]:
		_expect(ResourceLoader.exists(path), "asset_missing_%s" % path.get_file())
		_expect(load(path) != null, "asset_load_%s" % path.get_file())


func _test_material_tiers() -> void:
	var presenter = game.merge2048_classic_presenter
	_expect(presenter.tier_for_value(2) == 1, "tier_2")
	_expect(presenter.tier_for_value(8) == 2, "tier_8")
	_expect(presenter.tier_for_value(64) == 3, "tier_64")
	_expect(presenter.tier_for_value(512) == 4, "tier_512")


func _test_line_resolution_metadata() -> void:
	var outcome: Dictionary = game._slide_line([2, 0, 2, 2])
	_expect(outcome["line"] == [4, 2, 0, 0], "line_result")
	_expect(int(outcome["gained"]) == 4, "line_score")
	_expect(bool(outcome["changed"]), "line_changed")
	var moves: Array = outcome["moves"]
	_expect(moves.size() == 3, "line_motion_count")
	_expect(int(moves[0]["from_index"]) == 0 and int(moves[0]["to_index"]) == 0, "line_motion_first")
	_expect(int(moves[1]["from_index"]) == 2 and int(moves[1]["to_index"]) == 0, "line_motion_merge")
	var merges: Array = outcome["merges"]
	_expect(merges.size() == 1 and int(merges[0]["result_value"]) == 4, "line_merge_semantics")
	var double_pair: Dictionary = game._slide_line([2, 2, 4, 4])
	_expect(double_pair["line"] == [4, 8, 0, 0] and int(double_pair["gained"]) == 12, "line_no_double_merge")
	_expect(double_pair["merges"].size() == 2, "line_parallel_merge_semantics")


func _test_slide_motion() -> void:
	game._open_game("merge2048")
	game._merge2048_load_fixture([[2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
	game._merge_move(Vector2i.RIGHT)
	_expect(int(game.state["moves"]) == 1 and int(game.state["score"]) == 0, "slide_state")
	_expect(not game.merge2048_motion.is_empty(), "slide_motion_missing")
	var moves: Array = game.merge2048_motion.get("moves", [])
	_expect(moves.size() == 1, "slide_motion_count")
	if moves.size() == 1:
		_expect(moves[0]["from"] == Vector2i(0, 0) and moves[0]["to"] == Vector2i(3, 0), "slide_mapping")
	var effect: Dictionary = game.catalog_fx.back()
	_expect(str(effect.get("kind")) == "merge" and str(effect.get("semantic")) == "wood_slide", "slide_semantic")


func _test_rejection_invariant() -> void:
	game._open_game("merge2048")
	game._merge2048_load_fixture([
		[2, 4, 8, 16], [32, 64, 128, 256],
		[4, 8, 16, 32], [64, 128, 256, 512],
	])
	var before: Dictionary = game.state.duplicate(true)
	game._merge_move(Vector2i.LEFT)
	_expect(game.state == before, "reject_mutated_state")
	var effect: Dictionary = game.catalog_fx.back()
	_expect(str(effect.get("kind")) == "merge_reject", "reject_kind")
	_expect(str(effect.get("semantic")) == "wood_reject", "reject_semantic")


func _test_feedback_grades() -> void:
	for sample in [
		{"value":4, "grade":2, "semantic":"wood_merge"},
		{"value":16, "grade":3, "semantic":"wood_milestone"},
		{"value":64, "grade":4, "semantic":"wood_masterpiece"},
	]:
		game._open_game("merge2048")
		var value := int(sample["value"])
		game._merge2048_load_fixture([[value, value, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
		game._merge_move(Vector2i.LEFT)
		var effect: Dictionary = game.catalog_fx.back()
		_expect(int(effect.get("grade")) == int(sample["grade"]), "grade_%d" % value)
		_expect(str(effect.get("semantic")) == str(sample["semantic"]), "semantic_%d" % value)
		_expect(int(game.merge2048_motion.get("grade")) == int(sample["grade"]), "motion_grade_%d" % value)


func _test_target_promotion() -> void:
	game._open_game("merge2048")
	game._merge2048_load_fixture([[1024, 1024, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
	game._merge_move(Vector2i.LEFT)
	_expect(str(game.state["status"]) == "won", "target_status")
	var effect: Dictionary = game.catalog_fx.back()
	_expect(int(effect.get("grade")) == 4 and str(effect.get("semantic")) == "wood_masterpiece", "target_grade")
