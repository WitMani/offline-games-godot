extends SceneTree

const OUTPUT := "user://watermelon_gag_v3_physics_visual_audit"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await _settle(0.35)

	game._open_game("watermelon")
	await _settle(0.92)
	_seed_stable_free_pile()
	await _settle(0.22)
	await _save_frame("00_stable_family_and_tray")

	game._open_game("watermelon")
	await _settle(0.92)
	game._watermelon_aim_at(174.0)
	await _save_frame("10_continuous_aim")
	game._watermelon_drop_current()
	await _save_frame("11_release")
	await _settle(0.12)
	await _save_frame("12_visible_fall")
	await _settle(0.64)
	await _save_frame("13_physics_contact")
	await _settle(0.28)
	await _save_frame("14_contact_settle")

	game._open_game("watermelon")
	await _settle(0.92)
	_merge_pair_at(1, Vector2(250, 620), 201)
	_set_latest_effect_age(0.05)
	await _save_frame("20_grade2_gather")
	_set_latest_effect_age(0.19)
	await _save_frame("21_grade2_impact")
	_set_latest_effect_age(0.42)
	await _save_frame("22_grade2_settle")

	game._open_game("watermelon")
	await _settle(0.92)
	_merge_pair_at(1, Vector2(250, 618), 202)
	game.watermelon_model.inject_ball(2, _first_ball_position(), Vector2.ZERO, 202)
	game._watermelon_update(game.watermelon_model.FIXED_DT)
	_set_latest_effect_age(0.19)
	await _save_frame("25_grade3_chain_impact")
	_set_latest_effect_age(0.46)
	await _save_frame("26_grade3_chain_settle")

	game._open_game("watermelon")
	await _settle(0.92)
	for position in [Vector2(240, 600), Vector2(270, 600), Vector2(240, 600), Vector2(270, 600)]:
		game.watermelon_model.inject_ball(1, position, Vector2.ZERO, 203)
	game._watermelon_update(game.watermelon_model.FIXED_DT)
	_set_latest_effect_age(0.04)
	await _save_frame("30_grade4_cascade_gather")
	for frame in range(24):
		# PNG encoding on software rendering takes longer than one game frame.
		# Pin the semantic envelope to a true 60 Hz evidence trace.
		_set_latest_effect_age(0.04 + float(frame + 1) / 60.0)
		await process_frame
		await _save_frame("continuous/cascade_%02d" % frame)
		if frame == 4:
			await _save_frame("31_grade4_cascade_impact")
		elif frame == 10:
			await _save_frame("32_grade4_cascade_rebound")
		elif frame == 20:
			await _save_frame("33_grade4_cascade_settle")

	game._open_game("watermelon")
	await _settle(0.92)
	var aim_x := float(game.watermelon_model.aim_x)
	game.watermelon_model.inject_ball(1, Vector2(aim_x, game.watermelon_model.SPAWN_Y), Vector2.ZERO, 0)
	game._sync_watermelon_state()
	game._watermelon_drop_current()
	await _settle(0.12)
	await _save_frame("40_blocked_spawn_rejection")

	game._open_game("watermelon")
	await _settle(0.92)
	game.watermelon_model.inject_ball(7, Vector2(250, 610), Vector2.ZERO, 204)
	game.watermelon_model.inject_ball(7, Vector2(280, 610), Vector2.ZERO, 204)
	game._watermelon_update(game.watermelon_model.FIXED_DT)
	_set_latest_effect_age(0.20)
	await _save_frame("50_target_256_open_progress")

	_write_snapshot()
	print("WATERMELON_VISUAL_AUDIT_DIR=%s" % ProjectSettings.globalize_path(OUTPUT))
	game.queue_free()
	await process_frame
	await process_frame
	quit()


func _seed_stable_free_pile() -> void:
	var tiers := [1, 2, 3, 4, 5]
	for index in range(tiers.size()):
		var tier := int(tiers[index])
		var radius: float = game.watermelon_model.radius_for_tier(tier)
		game.watermelon_model.inject_ball(tier, Vector2(92.0 + float(index) * 86.0, game.watermelon_model.FLOOR_Y - radius), Vector2.ZERO, 180 + index)
	game._sync_watermelon_state()


func _merge_pair_at(tier: int, position: Vector2, shot_id: int) -> void:
	var radius: float = game.watermelon_model.radius_for_tier(tier)
	game.watermelon_model.inject_ball(tier, position - Vector2(radius * 0.72, 0), Vector2.ZERO, shot_id)
	game.watermelon_model.inject_ball(tier, position + Vector2(radius * 0.72, 0), Vector2.ZERO, shot_id)
	game._watermelon_update(game.watermelon_model.FIXED_DT)


func _first_ball_position() -> Vector2:
	return Vector2(game.watermelon_model.balls[0]["position"])


func _settle(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame
	await process_frame


func _save_frame(stem: String) -> void:
	var relative_dir := stem.get_base_dir()
	if relative_dir != ".":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/%s" % [OUTPUT, relative_dir]))
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [OUTPUT, stem]
	var error := image.save_png(path)
	if error != OK:
		push_error("2048 Balls visual audit capture failed: %s" % path)


func _set_latest_effect_age(age: float) -> void:
	if not game.catalog_fx.is_empty():
		game.catalog_fx.back()["started"] = game.elapsed - age


func _write_snapshot() -> void:
	var events: Array = []
	for effect in game.catalog_fx:
		events.append({
			"game_id": effect.get("game_id"),
			"kind": effect.get("kind"),
			"grade": effect.get("grade"),
			"label": effect.get("label"),
			"duration": effect.get("duration"),
			"result_id": effect.get("result_id", -1),
		})
	var snapshot := {
		"game_id": game.game_id,
		"viewport": [540, 960],
		"mechanics": "continuous aim, fixed-step falling circles, free collision, equal-contact merge, danger grace, open targets",
		"state": game.state,
		"events": events,
		"asset_family": [
			"fruit_01_lemon.png", "fruit_02_orange.png", "fruit_03_apple.png",
			"fruit_04_grape.png", "fruit_05_watermelon.png", "juice_merge_burst.png",
			"orchard_recipe_tray_gag_v3.webp"
		],
	}
	var file := FileAccess.open("%s/semantic-snapshot.json" % OUTPUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(snapshot, "  "))
