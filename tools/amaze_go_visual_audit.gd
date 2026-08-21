extends SceneTree

const OUTPUT := "res://docs/audit/amaze-go-v3/candidate"
const EXTRACT_SEQUENCE := "user://amaze-go-v3-extract-sequence"
const REJECT_SEQUENCE := "user://amaze-go-v3-reject-sequence"
const WIN_SEQUENCE := "user://amaze-go-v3-win-sequence"
const REDUCED_SEQUENCE := "user://amaze-go-v3-reduced-sequence"
const SOLVE_ORDER := ["a1", "a0", "a10", "a3", "a2", "a4", "a6", "a8", "a11", "a5", "a9", "a7"]

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.amaze_go_recovery_enabled = false
	root.add_child(game)
	for folder in [OUTPUT, EXTRACT_SEQUENCE, REJECT_SEQUENCE, WIN_SEQUENCE, REDUCED_SEQUENCE]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	await _wait(0.20)
	await _capture_stable()
	await _capture_extract()
	await _capture_reject()
	await _capture_waypoint()
	await _capture_near()
	await _capture_win()
	await _capture_reduced()
	_write_manifest()
	print("AMAZE_GO_VISUAL_AUDIT=%s" % ProjectSettings.globalize_path(OUTPUT))
	print("AMAZE_GO_EXTRACT_SEQUENCE=%s" % ProjectSettings.globalize_path(EXTRACT_SEQUENCE))
	print("AMAZE_GO_REJECT_SEQUENCE=%s" % ProjectSettings.globalize_path(REJECT_SEQUENCE))
	print("AMAZE_GO_WIN_SEQUENCE=%s" % ProjectSettings.globalize_path(WIN_SEQUENCE))
	print("AMAZE_GO_REDUCED_SEQUENCE=%s" % ProjectSettings.globalize_path(REDUCED_SEQUENCE))
	quit()


func _open(reduced := false) -> void:
	game.set_process(true)
	game._set_amaze_go_reduced_effects(reduced)
	game._open_game("amaze_go")
	game.has_transitioned = false
	game.feedback_until = -1.0
	game.catalog_fx.clear()
	game.amaze_go_object_fx = {}
	game.queue_redraw()


func _capture_stable() -> void:
	_open(false)
	await _wait(0.08)
	await _save_frame("00-stable-entry")
	_save_state("00-stable-entry", "ordinary_stable")
	game._amaze_hint()
	await _wait(0.12)
	await _save_frame("01-hint-impact")
	_save_state("01-hint-impact", "hint")


func _capture_extract() -> void:
	_open(false)
	game._amaze_go_attempt("a1", "visual")
	_save_state("02-extract-state", "extract")
	await _capture_sequence(EXTRACT_SEQUENCE, 18, {
		0:"02-extract-intent", 3:"03-extract-lift", 7:"04-extract-travel",
		11:"05-extract-impact", 17:"06-extract-settle",
	})


func _capture_reject() -> void:
	_open(false)
	game._amaze_go_attempt("a0", "visual")
	_save_state("07-reject-state", "reject")
	await _capture_sequence(REJECT_SEQUENCE, 18, {
		0:"07-reject-intent", 3:"08-reject-contact", 7:"09-reject-impact",
		12:"10-reject-recoil", 17:"11-reject-settle",
	})


func _capture_waypoint() -> void:
	_open(false)
	game._amaze_go_attempt("a1", "setup")
	game._amaze_go_attempt("a0", "setup")
	game.catalog_fx.clear()
	game.amaze_go_object_fx = {}
	game._amaze_go_attempt("a10", "visual")
	_save_state("12-waypoint-state", "waypoint")
	await _capture_keyframes({0:"12-waypoint-intent", 5:"13-waypoint-impact", 13:"14-waypoint-settle"}, 14)


func _capture_near() -> void:
	_open(false)
	for arrow_id in SOLVE_ORDER.slice(0, 9):
		game._amaze_go_attempt(arrow_id, "setup")
	game.catalog_fx.clear()
	game.amaze_go_object_fx = {}
	game._amaze_go_attempt(SOLVE_ORDER[9], "visual")
	_save_state("15-near-state", "near")
	await _capture_keyframes({0:"15-near-intent", 6:"16-near-impact", 16:"17-near-settle"}, 17)


func _capture_win() -> void:
	_open(false)
	for arrow_id in SOLVE_ORDER.slice(0, 11):
		game._amaze_go_attempt(arrow_id, "setup")
	game.catalog_fx.clear()
	game.amaze_go_object_fx = {}
	game._amaze_go_attempt(SOLVE_ORDER[11], "visual")
	_save_state("18-win-state", "win")
	await _capture_sequence(WIN_SEQUENCE, 40, {
		0:"18-win-intent", 4:"19-win-travel", 9:"20-win-impact",
		16:"21-win-seal", 24:"22-win-settle", 31:"23-result-entrance", 39:"24-result-stable",
	})


func _capture_reduced() -> void:
	_open(true)
	await _wait(0.08)
	await _save_frame("25-reduced-stable")
	_save_state("25-reduced-stable", "reduced_stable")
	game._amaze_go_attempt("a1", "visual_reduced")
	await _capture_sequence(REDUCED_SEQUENCE, 14, {
		0:"26-reduced-extract-intent", 5:"27-reduced-extract-impact", 13:"28-reduced-extract-settle",
	})
	_open(true)
	game._amaze_go_attempt("a0", "visual_reduced")
	await _capture_keyframes({0:"29-reduced-reject-intent", 6:"30-reduced-reject-impact", 15:"31-reduced-reject-settle"}, 16)
	_save_state("31-reduced-reject-state", "reduced_reject")
	game._set_amaze_go_reduced_effects(false)


func _capture_keyframes(keyframes: Dictionary, frame_count: int) -> void:
	var started := float(game.amaze_go_object_fx.get("started", game.elapsed))
	game.set_process(false)
	for frame in range(frame_count):
		game.elapsed = started + float(frame) / 30.0
		game._prune_catalog_fx()
		game.queue_redraw()
		await process_frame
		if keyframes.has(frame):
			await _save_frame(str(keyframes[frame]))
	game.set_process(true)


func _capture_sequence(folder: String, frame_count: int, keyframes: Dictionary) -> void:
	var started := float(game.amaze_go_object_fx.get("started", game.elapsed))
	game.set_process(false)
	for frame in range(frame_count):
		game.elapsed = started + float(frame) / 30.0
		game._prune_catalog_fx()
		game.queue_redraw()
		await process_frame
		await _save_motion_frame(folder, frame)
		if keyframes.has(frame):
			await _save_frame(str(keyframes[frame]))
	game.set_process(true)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame
	await process_frame


func _save_frame(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.webp" % [OUTPUT, stem])
	var error := image.save_webp(path, false, 0.94)
	if error != OK:
		push_error("Amaze GO visual capture failed: %s" % path)


func _save_motion_frame(folder: String, frame: int) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/frame_%02d.webp" % [folder, frame])
	var error := image.save_webp(path, false, 0.92)
	if error != OK:
		push_error("Amaze GO motion capture failed: %s" % path)


func _save_state(stem: String, beat: String) -> void:
	var effect := {}
	if not game.catalog_fx.is_empty():
		var source: Dictionary = game.catalog_fx.back()
		effect = {
			"game_id":source.get("game_id", ""), "kind":source.get("kind", ""),
			"grade":source.get("grade", 0), "label":source.get("label", ""),
			"font_role":source.get("font_role", ""), "duration":source.get("duration", 0.0),
		}
	var object_fx: Dictionary = game.amaze_go_object_fx.duplicate(true)
	object_fx.erase("started")
	for key in ["head", "contact", "direction"]:
		if object_fx.get(key) is Vector2:
			var value: Vector2 = object_fx[key]
			object_fx[key] = [value.x, value.y]
		elif object_fx.get(key) is Vector2i:
			var value_i: Vector2i = object_fx[key]
			object_fx[key] = [value_i.x, value_i.y]
	var report := {
		"game_id":game.game_id, "beat":beat,
		"status":game.state.get("status", ""), "remaining":game.state.get("remaining", -1),
		"removed_count":game.state.get("removed_count", -1), "hearts":game.state.get("hearts", -1),
		"moves":game.state.get("moves", 0), "score":game.state.get("score", 0),
		"focus_id":game.state.get("focus_id", ""), "reduced_effects":game.state.get("reduced_effects", false),
		"gag_visible_roles":game.state.get("gag_visible_roles", []), "event":effect, "object_fx":object_fx,
	}
	var path := ProjectSettings.globalize_path("%s/%s.json" % [OUTPUT, stem])
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()


func _write_manifest() -> void:
	var report := {
		"schema":"amaze-go-visual-sequences/v3", "game_id":"amaze_go", "viewport":[540, 960], "fps":30,
		"stable":{"normal":"00-stable-entry.webp", "reduced":"25-reduced-stable.webp"},
		"continuous_sequences":[
			{"id":"ordinary_extract", "folder":ProjectSettings.globalize_path(EXTRACT_SEQUENCE), "frames":18, "beats":["intent", "lift", "travel", "impact", "settle"]},
			{"id":"blocked_reject", "folder":ProjectSettings.globalize_path(REJECT_SEQUENCE), "frames":18, "beats":["intent", "contact", "impact", "recoil", "settle"]},
			{"id":"terminal_win", "folder":ProjectSettings.globalize_path(WIN_SEQUENCE), "frames":40, "beats":["intent", "travel", "impact", "seal", "settle", "result"]},
			{"id":"reduced_extract", "folder":ProjectSettings.globalize_path(REDUCED_SEQUENCE), "frames":14, "beats":["intent", "static impact", "settle"]},
		],
		"matched_state_note":"Normal and reduced stable frames use the same authoritative opening level; reduced extraction keeps the same immediate removal while suppressing translation, shake, and haptic.",
	}
	var file := FileAccess.open(ProjectSettings.globalize_path("%s/sequence-manifest.json" % OUTPUT), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
