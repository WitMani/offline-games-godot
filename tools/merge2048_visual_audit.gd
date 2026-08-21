extends SceneTree

const OUTPUT := "res://docs/audit/merge2048-fidelity-v4/candidate"

var game: Control
var stage_records: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/continuous" % OUTPUT))
	game = load("res://main.tscn").instantiate()
	game.merge2048_persistence_enabled = false
	game.merge2048_seed_override = 20482026
	root.add_child(game)
	await _settle(0.34)

	game._open_game("merge2048")
	await _settle(0.25)
	game._merge2048_load_fixture([
		[2, 8, 64, 512], [4, 16, 128, 1024],
		[0, 32, 256, 2048], [2, 8, 64, 512],
	], 0, 0, true, true)
	game.merge2048_motion.clear()
	game.feedback_until = -1.0
	await _settle(0.12)
	await _save_frame("00_stable_material_family")

	game._open_game("merge2048")
	await _settle(0.20)
	game._merge2048_load_fixture([[2, 0, 0, 0], [4, 0, 0, 0], [8, 0, 0, 0], [0, 0, 0, 0]])
	var routine_before: Dictionary = game.state.duplicate(true)
	game._merge_move(Vector2i.RIGHT)
	_record_stage("routine_slide", routine_before)
	await _pin_motion(0.06)
	await _save_frame("10_slide_intent")
	await _pin_motion(0.25)
	await _save_frame("11_slide_travel")
	await _pin_motion(0.40)
	await _save_frame("12_slide_impact")
	await _pin_motion(0.66)
	await _save_frame("13_slide_settle")

	await _capture_merge_grade(4, 2, "20_grade2_amber_merge")
	await _capture_merge_grade(16, 3, "30_grade3_blue_milestone")

	game._open_game("merge2048")
	await _settle(0.20)
	game._merge2048_load_fixture([[64, 64, 64, 64], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
	var masterpiece_before: Dictionary = game.state.duplicate(true)
	game._merge_move(Vector2i.LEFT)
	_record_stage("grade4_masterpiece", masterpiece_before)
	# A complete 0.82-second, 60 fps event trace: intent, anticipation,
	# directional travel, impact, rebound, spawn, and fully readable settle.
	for frame in range(49):
		var age := 0.02 + float(frame) / 60.0
		await _pin_motion(age)
		await _save_frame("continuous/masterpiece_%02d" % frame)
		if frame == 5:
			await _save_frame("40_grade4_gather")
		elif frame == 29:
			await _save_frame("41_grade4_wood_burst")
		elif frame == 39:
			await _save_frame("42_grade4_rebound")
	await _pin_motion(0.82)
	await _save_frame("43_grade4_settle")

	game._open_game("merge2048")
	await _settle(0.20)
	game._merge2048_load_fixture([
		[2, 4, 8, 16], [32, 64, 128, 256],
		[4, 8, 16, 32], [64, 128, 256, 512],
	])
	var rejection_before: Dictionary = game.state.duplicate(true)
	game._merge_move(Vector2i.LEFT)
	_record_stage("locked_rejection", rejection_before)
	await _pin_latest_effect(0.16)
	await _save_frame("50_locked_rejection")

	game._open_game("merge2048")
	await _settle(0.20)
	game._merge2048_load_fixture([[1024, 1024, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]], 8192, 44, false, false, false, 16384)
	var target_before: Dictionary = game.state.duplicate(true)
	game._merge_move(Vector2i.LEFT)
	_record_stage("target_2048_pause", target_before)
	await _pin_motion(0.88)
	await _save_frame("60_target_pause")
	var continue_before: Dictionary = game.state.duplicate(true)
	game.catalog_fx.clear()
	game._merge2048_continue()
	_record_stage("continue_after_target", continue_before)
	await _settle(0.12)
	await _save_frame("61_continue_controls")

	game._open_game("merge2048")
	await _settle(0.20)
	game.reduced_effects_enabled = true
	game._merge2048_load_fixture([[64, 64, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
	var reduced_before: Dictionary = game.state.duplicate(true)
	game._merge_move(Vector2i.LEFT)
	_record_stage("reduced_effects_merge", reduced_before)
	await _pin_motion(0.08)
	await _save_frame("70_reduced_effects")
	game.reduced_effects_enabled = false

	_write_snapshot()
	print("MERGE2048_VISUAL_AUDIT_DIR=%s" % ProjectSettings.globalize_path(OUTPUT))
	game.queue_free()
	await process_frame
	quit()


func _capture_merge_grade(source_value: int, expected_grade: int, stem: String) -> void:
	game._open_game("merge2048")
	await _settle(0.20)
	game._merge2048_load_fixture([[source_value, source_value, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
	var before: Dictionary = game.state.duplicate(true)
	game._merge_move(Vector2i.LEFT)
	_record_stage("grade%d_%d_merge" % [expected_grade, source_value], before)
	await _pin_motion(0.40 if expected_grade == 2 else 0.38)
	await _save_frame(stem)


func _settle(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame
	await process_frame


func _pin_motion(age: float) -> void:
	if not game.merge2048_motion.is_empty():
		game.merge2048_motion["started"] = game.elapsed - age
	await _pin_latest_effect(age)


func _pin_latest_effect(age: float) -> void:
	if not game.catalog_fx.is_empty():
		game.catalog_fx.back()["started"] = game.elapsed - age
	await process_frame


func _save_frame(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [OUTPUT, stem]
	var error := image.save_png(path)
	if error != OK:
		push_error("Classic 2048 visual audit capture failed: %s" % path)


func _record_stage(stage_name: String, before: Dictionary) -> void:
	var effect: Dictionary = game.catalog_fx.back().duplicate(true) if not game.catalog_fx.is_empty() else {}
	stage_records.append({
		"stage":stage_name,
		"before":before,
		"after":game.state.duplicate(true),
		"motion":game.merge2048_motion.duplicate(true),
		"effect":effect,
	})


func _write_snapshot() -> void:
	var events: Array = []
	for effect in game.catalog_fx:
		events.append({
			"kind":effect.get("kind"),
			"semantic":effect.get("semantic"),
			"grade":effect.get("grade"),
			"label":effect.get("label"),
		})
	var snapshot := {
		"game_id":"merge2048",
		"viewport":[540, 960],
		"state":game.state,
		"events":events,
		"stages":stage_records,
		"runtime_assets":[
			"tile_tier_1.png", "tile_tier_2.png", "tile_tier_3.png", "tile_tier_4.png",
			"wood_shaving_burst.png", "tile_slide.ogg", "tile_merge.ogg", "tile_milestone.ogg",
		],
	}
	var file := FileAccess.open("%s/evidence.json" % OUTPUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(snapshot, "  ") + "\n")
