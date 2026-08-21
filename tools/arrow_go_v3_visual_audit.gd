extends SceneTree

const SOLUTION: Array[String] = ["b", "a", "d", "c", "k", "g", "f", "l", "i", "e", "j", "h"]

var game: Control
var output_dir := "user://arrow_go_v3_visual_audit"
var sequence_index := 0
var evidence_states: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	await process_frame
	game._arrow_go_clear_recovery()
	game._open_game("arrow_go")
	game.has_transitioned = false
	await _settle_frames(4)
	game.feedback_until = -1.0
	evidence_states["stable"] = _state_snapshot()
	await _save_frame("00_stable")

	game._arrow_go_attempt("a", "visual_audit")
	evidence_states["blocked"] = _state_snapshot()
	await _capture_event_beats("01_reject")

	game._reset_current()
	game.has_transitioned = false
	game._arrow_go_attempt("b", "visual_audit")
	evidence_states["legal_escape"] = _state_snapshot()
	await _capture_event_beats("02_turn_escape")

	game._reset_current()
	game.has_transitioned = false
	for index in range(8):
		game._arrow_go_attempt(SOLUTION[index], "visual_audit")
		game.elapsed = float(game.arrow_go_object_fx.get("started", game.elapsed)) + float(game.arrow_go_object_fx.get("duration", 0.8)) + 0.02
	evidence_states["progress_eight"] = _state_snapshot()
	await _save_frame("03_progress_eight")
	for index in range(8, SOLUTION.size()):
		game._arrow_go_attempt(SOLUTION[index], "visual_audit")
		var started := float(game.arrow_go_object_fx.get("started", game.elapsed))
		var duration := float(game.arrow_go_object_fx.get("duration", 0.8))
		for frame in range(12):
			game.elapsed = started + duration * float(frame) / 11.0
			await _save_sequence_frame()
		game.elapsed = started + duration + 0.02
	evidence_states["win"] = _state_snapshot()
	await _save_frame("04_win_result")

	game._reset_current()
	game._arrow_go_set_reduced_effects(true)
	game.has_transitioned = false
	game._arrow_go_attempt("b", "visual_audit")
	game.elapsed = float(game.arrow_go_object_fx.get("started", game.elapsed)) + float(game.arrow_go_object_fx.get("duration", 0.8)) * 0.42
	evidence_states["reduced_effects"] = _state_snapshot()
	await _save_frame("05_reduced_effects")
	game._arrow_go_set_reduced_effects(false)
	game.catalog_fx.clear()
	game.arrow_go_object_fx = {}
	var deadlock_arrows: Array[Dictionary] = [
		{"id":"x", "path":[Vector2i(0, 1), Vector2i(1, 1)], "direction":Vector2i.RIGHT},
		{"id":"y", "path":[Vector2i(3, 1), Vector2i(2, 1)], "direction":Vector2i.LEFT},
	]
	game.arrow_go_model.arrows = deadlock_arrows
	game.arrow_go_model.removed_ids.clear()
	game.arrow_go_model.moves = 0
	game.arrow_go_model.score = 0
	game.arrow_go_model.status = game.ARROW_GO_RULES.PLAYING
	game.arrow_go_model.terminal_reason = ""
	game.arrow_go_model.refresh_terminal()
	game._sync_arrow_go_state()
	game.feedback_until = -1.0
	evidence_states["local_loss"] = _state_snapshot()
	await _save_frame("06_local_loss")
	game._arrow_go_clear_recovery()
	_write_state_evidence()
	print("ARROW_GO_V3_VISUAL_AUDIT_DIR=%s" % ProjectSettings.globalize_path(output_dir))
	print("ARROW_GO_V3_VISUAL_SEQUENCE_FRAMES=%d" % sequence_index)
	quit()


func _capture_event_beats(stem: String) -> void:
	var started := float(game.arrow_go_object_fx.get("started", game.elapsed))
	var duration := float(game.arrow_go_object_fx.get("duration", 0.8))
	for beat in [["intent", 0.06], ["anticipation", 0.18], ["impact", 0.52], ["settle", 0.88]]:
		game.elapsed = started + duration * float(beat[1])
		await _save_frame("%s_%s" % [stem, str(beat[0])])
	game.elapsed = started + duration + 0.02


func _settle_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _save_frame(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var error := image.save_png("%s/%s.png" % [output_dir, stem])
	if error != OK:
		push_error("Arrow GO v3 frame failed: %s" % stem)


func _save_sequence_frame() -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var error := image.save_png("%s/sequence_%03d.png" % [output_dir, sequence_index])
	if error != OK:
		push_error("Arrow GO v3 sequence failed: %03d" % sequence_index)
	sequence_index += 1


func _state_snapshot() -> Dictionary:
	return {
		"game_id": str(game.game_id),
		"model": game.arrow_go_model.snapshot(),
		"last_event": game.arrow_go_model.last_event.duplicate(true),
		"object_fx": game.arrow_go_object_fx.duplicate(true),
		"reduced_effects": bool(game.arrow_go_reduced_effects),
	}


func _write_state_evidence() -> void:
	var path := ProjectSettings.globalize_path("res://docs/audit/arrow-go-v3/state-evidence.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Arrow GO v3 state evidence failed: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify({
		"schema": "offline-games.arrow-go-v3.state-evidence.v1",
		"states": evidence_states,
	}, "  "))
