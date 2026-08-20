extends SceneTree

const OUTPUT := "res://docs/audit/merge2048-v2"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/continuous" % OUTPUT))
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await _settle(0.34)

	game._open_game("merge2048")
	await _settle(0.25)
	game.state["board"] = [
		[2, 8, 64, 512], [4, 16, 128, 1024],
		[0, 32, 256, 2048], [2, 8, 64, 512],
	]
	game.merge2048_motion.clear()
	await _settle(0.12)
	await _save_frame("00_stable_material_family")

	game._open_game("merge2048")
	await _settle(0.20)
	game.state["board"] = [[2, 0, 0, 0], [4, 0, 0, 0], [8, 0, 0, 0], [0, 0, 0, 0]]
	game._merge_move(Vector2i.RIGHT)
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
	game.state["board"] = [[64, 64, 64, 64], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
	game._merge_move(Vector2i.LEFT)
	for frame in range(24):
		var age := 0.04 + float(frame) / 60.0
		await _pin_motion(age)
		await _save_frame("continuous/masterpiece_%02d" % frame)
		if frame == 3:
			await _save_frame("40_grade4_gather")
		elif frame == 10:
			await _save_frame("41_grade4_wood_burst")
		elif frame == 18:
			await _save_frame("42_grade4_rebound")
	await _pin_motion(0.72)
	await _save_frame("43_grade4_settle")

	game._open_game("merge2048")
	await _settle(0.20)
	game.state["board"] = [
		[2, 4, 8, 16], [32, 64, 128, 256],
		[4, 8, 16, 32], [64, 128, 256, 512],
	]
	game._merge_move(Vector2i.LEFT)
	await _pin_latest_effect(0.16)
	await _save_frame("50_locked_rejection")

	_write_snapshot()
	print("MERGE2048_VISUAL_AUDIT_DIR=%s" % ProjectSettings.globalize_path(OUTPUT))
	game.queue_free()
	await process_frame
	quit()


func _capture_merge_grade(source_value: int, expected_grade: int, stem: String) -> void:
	game._open_game("merge2048")
	await _settle(0.20)
	game.state["board"] = [[source_value, source_value, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
	game._merge_move(Vector2i.LEFT)
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
		"runtime_assets":[
			"tile_tier_1.png", "tile_tier_2.png", "tile_tier_3.png", "tile_tier_4.png",
			"wood_shaving_burst.png", "tile_slide.ogg", "tile_merge.ogg", "tile_milestone.ogg",
		],
	}
	var file := FileAccess.open("%s/semantic-snapshot.json" % OUTPUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(snapshot, "  ") + "\n")
