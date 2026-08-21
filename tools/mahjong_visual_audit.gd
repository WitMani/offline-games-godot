extends SceneTree

const OUTPUT := "res://docs/audit/mahjong-v3/candidate"
const FRAME_OUTPUT := OUTPUT + "/frames"
const STATE_OUTPUT := OUTPUT + "/states"
const PAIR_MOTION_OUTPUT := "user://mahjong-v3-pair-motion"
const FINAL_MOTION_OUTPUT := "user://mahjong-v3-final-motion"

var game: Control
var captured_frames: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._clear_mahjong_session()
	for path in [FRAME_OUTPUT, STATE_OUTPUT, PAIR_MOTION_OUTPUT, FINAL_MOTION_OUTPUT]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	await _wait(0.18)
	await _capture_stable_select_blocked()
	await _capture_mismatch_hint_shuffle()
	await _capture_routine_pair()
	await _capture_near_clear()
	await _capture_final_clear()
	await _capture_reduced_and_deadlock()
	_write_manifest()
	game._clear_mahjong_session()
	print("MAHJONG_VISUAL_AUDIT=%s" % ProjectSettings.globalize_path(OUTPUT))
	print("MAHJONG_PAIR_MOTION=%s" % ProjectSettings.globalize_path(PAIR_MOTION_OUTPUT))
	print("MAHJONG_FINAL_MOTION=%s" % ProjectSettings.globalize_path(FINAL_MOTION_OUTPUT))
	quit()


func _open() -> void:
	game._open_game("mahjong")
	game.has_transitioned = false
	game.catalog_fx.clear()
	game.feedback_until = -1.0


func _pair() -> Array[int]:
	var pairs: Array = game.mahjong_model.available_pairs()
	if pairs.is_empty():
		return []
	return [int(pairs[0][0]), int(pairs[0][1])]


func _match_pair(pair: Array[int], route := "visual_audit") -> void:
	game._mahjong_resolve_index(pair[0], route)
	game._mahjong_resolve_index(pair[1], route)


func _solve_until_remaining(target: int) -> bool:
	var guard := 0
	while game.mahjong_model.remaining_count() > target and guard < 20:
		var pair := _pair()
		if pair.size() != 2:
			return false
		_match_pair(pair, "visual_setup")
		guard += 1
	return game.mahjong_model.remaining_count() == target


func _blocked_index() -> int:
	for index in range(game.mahjong_model.tile_count()):
		if game.mahjong_model.is_active(index) and not game.mahjong_model.is_free(index):
			return index
	return -1


func _mismatch_pair() -> Array[int]:
	var free: Array[int] = game.mahjong_model.free_indices()
	for left_offset in range(free.size()):
		for right_offset in range(left_offset + 1, free.size()):
			var left := int(free[left_offset])
			var right := int(free[right_offset])
			if int(game.mahjong_model.tiles[left]["face"]) != int(game.mahjong_model.tiles[right]["face"]):
				return [left, right]
	return []


func _capture_stable_select_blocked() -> void:
	_open()
	await _wait(0.22)
	await _save_frame("00-ordinary-stable")
	_save_state("ordinary-stable")
	var pair := _pair()
	game._mahjong_resolve_index(pair[0], "visual_select")
	await _wait(0.06)
	await _save_frame("01-select-intent")
	await _wait(0.34)
	await _save_frame("02-select-settle")
	_save_state("select")
	_open()
	var blocked := _blocked_index()
	game._mahjong_resolve_index(blocked, "visual_blocked")
	await _wait(0.08)
	await _save_frame("03-blocked-impact")
	await _wait(0.38)
	await _save_frame("04-blocked-settle")
	_save_state("blocked")


func _capture_mismatch_hint_shuffle() -> void:
	_open()
	var mismatch := _mismatch_pair()
	game._mahjong_resolve_index(mismatch[0], "visual_mismatch")
	await _wait(0.04)
	game._mahjong_resolve_index(mismatch[1], "visual_mismatch")
	await _wait(0.08)
	await _save_frame("05-mismatch-impact")
	await _wait(0.42)
	await _save_frame("06-mismatch-settle")
	_save_state("mismatch")
	_open()
	game._mahjong_hint()
	await _wait(0.10)
	await _save_frame("07-hint-stable")
	_save_state("hint")
	game._mahjong_shuffle()
	await _wait(0.14)
	await _save_frame("08-shuffle-impact")
	await _wait(0.70)
	await _save_frame("09-shuffle-result")
	_save_state("shuffle")


func _capture_routine_pair() -> void:
	_open()
	var pair := _pair()
	game._mahjong_resolve_index(pair[0], "visual_pair")
	await _wait(0.06)
	await _save_frame("10-pair-intent")
	game._mahjong_resolve_index(pair[1], "visual_pair")
	_save_state("routine-pair")
	var started := float(game.mahjong_object_fx["started"])
	game.set_process(false)
	for frame in range(30):
		game.elapsed = started + float(frame) / 30.0
		game._prune_catalog_fx()
		game.queue_redraw()
		await process_frame
		if frame == 3:
			await _save_frame("11-pair-gather")
		elif frame == 9:
			await _save_frame("12-pair-impact")
		elif frame == 18:
			await _save_frame("13-pair-settle")
		elif frame == 27:
			await _save_frame("14-pair-result")
		await _save_motion_frame(PAIR_MOTION_OUTPUT, frame)
	game.set_process(true)


func _capture_near_clear() -> void:
	_open()
	if not _solve_until_remaining(6):
		push_error("Mahjong near-clear setup did not reach six tiles")
		return
	game.catalog_fx.clear()
	var pair := _pair()
	game._mahjong_resolve_index(pair[0], "visual_near")
	await _wait(0.04)
	await _save_frame("15-near-intent")
	game._mahjong_resolve_index(pair[1], "visual_near")
	await _wait(0.18)
	await _save_frame("16-near-impact")
	await _wait(0.56)
	await _save_frame("17-near-result")
	_save_state("near-clear")


func _capture_final_clear() -> void:
	_open()
	if not _solve_until_remaining(2):
		push_error("Mahjong final setup did not reach two tiles")
		return
	game.catalog_fx.clear()
	var pair := _pair()
	game._mahjong_resolve_index(pair[0], "visual_final")
	await _wait(0.05)
	await _save_frame("18-final-intent")
	game._mahjong_resolve_index(pair[1], "visual_final")
	_save_state("final-clear")
	var started := float(game.mahjong_object_fx["started"])
	game.set_process(false)
	for frame in range(45):
		game.elapsed = started + float(frame) / 30.0
		game._prune_catalog_fx()
		game.queue_redraw()
		await process_frame
		if frame == 4:
			await _save_frame("19-final-gather")
		elif frame == 11:
			await _save_frame("20-final-impact")
		elif frame == 22:
			await _save_frame("21-final-settle")
		elif frame == 27:
			await _save_frame("22-result-entrance")
		elif frame == 42:
			await _save_frame("23-result-stable")
		await _save_motion_frame(FINAL_MOTION_OUTPUT, frame)
	game.set_process(true)


func _capture_reduced_and_deadlock() -> void:
	_open()
	game._toggle_mahjong_reduced()
	await _wait(0.08)
	await _save_frame("24-reduced-stable")
	var pair := _pair()
	game._mahjong_resolve_index(pair[0], "visual_reduced")
	game._mahjong_resolve_index(pair[1], "visual_reduced")
	await _wait(0.14)
	await _save_frame("25-reduced-pair-fixed-seal")
	await _wait(0.58)
	await _save_frame("26-reduced-pair-result")
	_save_state("reduced-pair")
	game._toggle_mahjong_reduced()
	_open()
	var free: Array[int] = game.mahjong_model.free_indices()
	for offset in range(free.size()):
		game.mahjong_model.tiles[free[offset]]["face"] = 1 + offset
	game.mahjong_model.refresh_status_for_test()
	game._sync_mahjong_state(false)
	game._mahjong_hint()
	await _wait(0.14)
	await _save_frame("27-deadlock-reject")
	_save_state("deadlock")


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame
	await process_frame


func _save_frame(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var relative := "frames/%s.webp" % stem
	var path := ProjectSettings.globalize_path("%s/%s.webp" % [FRAME_OUTPUT, stem])
	var error := image.save_webp(path, false, 0.94)
	if error != OK:
		push_error("Mahjong visual capture failed: %s" % path)
	else:
		captured_frames.append(relative)


func _save_motion_frame(directory: String, frame: int) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/frame_%03d.webp" % [directory, frame])
	var error := image.save_webp(path, false, 0.92)
	if error != OK:
		push_error("Mahjong motion capture failed: %s" % path)


func _save_state(stem: String) -> void:
	var effect := {}
	if not game.catalog_fx.is_empty():
		var source: Dictionary = game.catalog_fx.back()
		effect = {
			"game_id":source.get("game_id", ""),
			"kind":source.get("kind", ""),
			"grade":source.get("grade", 0),
			"label":source.get("label", ""),
			"font_role":source.get("font_role", ""),
			"semantic":source.get("semantic", ""),
			"duration":source.get("duration", 0.0),
		}
	var object_fx: Dictionary = game.mahjong_object_fx.duplicate(true)
	object_fx.erase("started")
	var report := {
		"game_id":game.game_id,
		"status":game.state.get("status", ""),
		"remaining":game.state.get("remaining", 0),
		"removed":game.state.get("removed", []),
		"selected":game.state.get("selected", -1),
		"free_indices":game.mahjong_model.free_indices(),
		"hint_pair":game.state.get("hint_pair", []),
		"last_pair":game.state.get("last_pair", []),
		"moves":game.state.get("moves", 0),
		"mistakes":game.state.get("mistakes", 0),
		"blocked_attempts":game.state.get("blocked_attempts", 0),
		"reshuffles":game.state.get("reshuffles", 0),
		"score":game.state.get("score", 0),
		"reduced_effects":game.state.get("reduced_effects", false),
		"event":effect,
		"object_fx":object_fx,
	}
	_write_json("%s/%s.json" % [STATE_OUTPUT, stem], report)


func _write_manifest() -> void:
	_write_json(OUTPUT + "/visual-capture.json", {
		"game_id":"mahjong",
		"viewport":[int(game.size.x), int(game.size.y)],
		"candidate_frame_count":captured_frames.size(),
		"candidate_frames":captured_frames,
		"continuous_pair":{"frames":30, "fps":30, "path":"continuous/mahjong-pair.webm"},
		"continuous_final":{"frames":45, "fps":30, "path":"continuous/mahjong-final.webm"},
		"covered_states":["ordinary stable", "select", "blocked", "mismatch", "hint", "shuffle", "ordinary pair", "near clear", "final clear", "result", "reduced pair", "deadlock"],
	})


func _write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	if file == null:
		push_error("Cannot write Mahjong audit JSON: %s" % path)
		return
	file.store_string(JSON.stringify(value, "  ") + "\n")
	file.close()
