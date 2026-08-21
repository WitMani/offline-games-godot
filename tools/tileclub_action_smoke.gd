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
	_test_blocked_and_collect()
	_test_match()
	_test_layer_clear()
	_test_near_full_grades()
	_test_tray_full()
	_test_completion()
	_test_restart_clears_transients()
	game._clear_tileclub_checkpoint()
	print("TILECLUB_ACTION_SMOKE=%d" % assertions)
	print("TILECLUB_ACTION_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _open(level := 0) -> void:
	game._clear_tileclub_checkpoint()
	game._open_game("tileclub")
	if level != 0:
		game.tileclub_level_index = level
		game._start_game_state()
	game.has_transitioned = false
	game.catalog_fx.clear()


func _latest() -> Dictionary:
	return {} if game.catalog_fx.is_empty() else game.catalog_fx.back()


func _expect_event(semantic: String, kind: String, grade: int, object_kind: String) -> void:
	var event := _latest()
	_expect(str(event.get("game_id", "")) == "tileclub", "%s_game" % semantic)
	_expect(str(event.get("semantic", "")) == semantic, "%s_semantic" % semantic)
	_expect(str(event.get("kind", "")) == kind, "%s_kind" % semantic)
	_expect(int(event.get("grade", 0)) == grade, "%s_grade" % semantic)
	_expect(str(event.get("font_role", "")) == "ui_cjk", "%s_font" % semantic)
	_expect(str(game.tileclub_object_fx.get("kind", "")) == object_kind, "%s_object_kind" % semantic)
	_expect(int(game.tileclub_object_fx.get("grade", 0)) == grade, "%s_object_grade" % semantic)


func _test_blocked_and_collect() -> void:
	_open()
	game._tileclub_collect_id(0)
	_expect_event("tileclub_blocked", "stitch_blocked", 1, "blocked")
	_expect(not bool(game.tileclub_last_outcome.get("changed", true)), "blocked_inert")
	game.catalog_fx.clear()
	game._tileclub_collect_id(2)
	_expect_event("tileclub_collect", "stitch_collect", 1, "collect")
	_expect(game.state["tray"] == [1], "collect_tray")


func _test_match() -> void:
	_open(2)
	for tile_id in [2, 0, 5, 8, 11, 14]:
		game._tileclub_collect_id(tile_id)
	game._tileclub_collect_id(1)
	_expect_event("tileclub_match", "stitch_match", 2, "match")
	_expect(game.state["tray"] == [2, 3, 4, 5], "match_compaction")


func _test_layer_clear() -> void:
	_open()
	# Clear the first three nests, then take the final upper-layer tile. That
	# action exposes the final lower pair without also producing a triple.
	for tile_id in [2, 0, 1, 5, 3, 4, 8, 6, 7, 11]:
		game._tileclub_collect_id(tile_id)
	_expect_event("tileclub_layer_clear", "stitch_layer_clear", 3, "layer")
	_expect(game.tileclub_last_outcome.get("cleared_layers", []) == [1], "layer_clear_payload")
	var exposed: Array = game.tileclub_last_outcome.get("newly_exposed", []).duplicate()
	exposed.sort()
	_expect(exposed == [9, 10], "layer_exposed_payload")


func _test_near_full_grades() -> void:
	_open(2)
	for tile_id in [2, 5, 8, 11, 14]:
		game._tileclub_collect_id(tile_id)
	_expect_event("tileclub_near_full", "stitch_risk", 2, "risk")
	_expect(int(_latest().get("remaining_slots", -1)) == 2, "risk_two_slots")
	game._tileclub_collect_id(17)
	_expect_event("tileclub_near_full", "stitch_risk", 3, "risk")
	_expect(int(_latest().get("remaining_slots", -1)) == 1, "risk_one_slot")


func _test_tray_full() -> void:
	_open(2)
	for tile_id in [2, 5, 8, 11, 14, 17, 20]:
		game._tileclub_collect_id(tile_id)
	_expect_event("tileclub_full", "stitch_tray_full", 4, "full")
	_expect(str(game.state["status"]) == "over" and game.state["tray"].size() == 7, "full_authoritative_state")


func _test_completion() -> void:
	_open()
	for tile_id in game.tileclub_model.solution_for_level():
		game._tileclub_collect_id(tile_id)
	_expect_event("tileclub_complete", "stitch_match", 4, "clear")
	_expect(str(game.state["status"]) == "won", "complete_authoritative_state")
	_expect(game.state["tray"].is_empty() and int(game.state["active_count"]) == 0, "complete_empty")


func _test_restart_clears_transients() -> void:
	_open()
	game._tileclub_collect_id(2)
	_expect(not game.catalog_fx.is_empty() and not game.tileclub_object_fx.is_empty(), "restart_setup_feedback")
	game._reset_current()
	_expect(game.catalog_fx.is_empty(), "restart_catalog_feedback_clear")
	_expect(game.tileclub_object_fx.is_empty() and game.tileclub_last_outcome.is_empty(), "restart_object_feedback_clear")
	_expect(game.state["tray"].is_empty() and int(game.state["moves"]) == 0, "restart_state_clean")


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
