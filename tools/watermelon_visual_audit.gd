extends SceneTree

const OUTPUT := "user://watermelon_v2_visual_audit"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await _settle(0.35)

	game._open_game("watermelon")
	await _settle(0.28)
	game.state["columns"] = [[1], [2], [3], [4], [5], [], []]
	game.state["next"] = 3
	await _settle(0.22)
	await _save_frame("00_stable_family")

	game._open_game("watermelon")
	await _settle(0.28)
	game.state["next"] = 2
	game._water_drop(3)
	await _settle(0.03)
	await _save_frame("10_drop_intent")
	await _settle(0.08)
	await _save_frame("11_drop_travel")
	await _settle(0.13)
	await _save_frame("12_drop_impact")
	await _settle(0.24)
	await _save_frame("13_drop_settle")

	game._open_game("watermelon")
	await _settle(0.28)
	game.state["columns"][2] = [1]
	game.state["next"] = 1
	game._water_drop(2)
	await _settle(0.05)
	await _save_frame("20_merge_gather")
	await _settle(0.11)
	await _save_frame("21_merge_impact")
	await _settle(0.14)
	await _save_frame("22_merge_rebound")
	await _settle(0.28)
	await _save_frame("23_merge_settle")

	game._open_game("watermelon")
	await _settle(0.28)
	game.state["columns"][5] = [2, 1]
	game.state["next"] = 1
	game._water_drop(5)
	await _settle(0.19)
	await _save_frame("25_chain_impact")
	await _settle(0.34)
	await _save_frame("26_chain_settle")

	game._open_game("watermelon")
	await _settle(0.28)
	game.state["columns"][3] = [3, 2, 2, 1]
	game.state["next"] = 1
	game._water_drop(3)
	await _settle(0.02)
	_set_latest_effect_age(0.04)
	await _save_frame("30_cascade_gather")
	for frame in range(24):
		# PNG encoding on a software-rendered CI host takes longer than a game
		# frame. Pin the event clock so the sequence remains a true 60 Hz sample
		# instead of accidentally aging out while evidence is written to disk.
		_set_latest_effect_age(0.04 + float(frame + 1) / 60.0)
		await process_frame
		await _save_frame("continuous/cascade_%02d" % frame)
		if frame == 4:
			await _save_frame("31_cascade_impact")
		elif frame == 10:
			await _save_frame("32_cascade_rebound")
		elif frame == 20:
			await _save_frame("33_cascade_settle")

	game._open_game("watermelon")
	await _settle(0.28)
	game.state["columns"][1] = [1, 2, 3, 4, 5, 1, 2]
	game._water_drop(1)
	await _settle(0.15)
	await _save_frame("40_full_rejection")

	_write_snapshot()
	print("WATERMELON_VISUAL_AUDIT_DIR=%s" % ProjectSettings.globalize_path(OUTPUT))
	game.queue_free()
	await process_frame
	await process_frame
	quit()


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
		})
	var snapshot := {
		"game_id": game.game_id,
		"viewport": [540, 960],
		"state": game.state,
		"events": events,
		"asset_family": [
			"fruit_01_lemon.png", "fruit_02_orange.png", "fruit_03_apple.png",
			"fruit_04_grape.png", "fruit_05_watermelon.png", "juice_merge_burst.png"
		],
	}
	var file := FileAccess.open("%s/semantic-snapshot.json" % OUTPUT, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(snapshot, "  "))
