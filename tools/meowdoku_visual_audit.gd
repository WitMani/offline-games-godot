extends SceneTree

const OUTPUT := "user://meowdoku_v3_visual_audit"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.meowdoku_recovery_enabled = false
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	await _wait(0.20)
	await _audit_loop()
	print("MEOWDOKU_VISUAL_AUDIT=%s" % ProjectSettings.globalize_path(OUTPUT))
	game.queue_free()
	await process_frame
	quit()


func _audit_loop() -> void:
	game._open_game("meowdoku")
	game.has_transitioned = false
	await _wait(0.24)
	await _save_frame("01_stable")
	_save_state("01_stable")

	var selection := Vector2i(2, 2)
	game._meowdoku_command("select", selection)
	await _wait(0.05)
	await _save_frame("02_selection_intent")
	game._meowdoku_command("mark", selection)
	await _wait(0.10)
	await _save_frame("03_mark_impact")
	_save_state("03_mark")

	game._reset_current()
	var first: Vector2i = game.meowdoku_model.solution[0]
	game._meowdoku_command("cat", first)
	await _wait(0.10)
	await _save_frame("04_cat_impact")
	_save_state("04_cat")
	await _wait(0.58)
	await _save_frame("05_cat_settle")

	game._reset_current()
	var wrong := Vector2i.ZERO
	if wrong in game.meowdoku_model.solution:
		wrong = Vector2i(1, 0)
	game._meowdoku_command("cat", wrong)
	await _wait(0.09)
	await _save_frame("06_error_impact")
	_save_state("06_error")
	await _wait(0.62)
	await _save_frame("07_error_settle")

	game._meowdoku_command("cat", wrong)
	game._meowdoku_command("cat", wrong)
	await _wait(0.12)
	await _save_frame("08_loss_impact")
	_save_state("08_loss")
	await _wait(0.88)
	await _save_frame("09_loss_result")

	game._reset_current()
	var solution: Array[Vector2i] = game.meowdoku_model.solution.duplicate()
	for index in range(solution.size() - 1):
		game.meowdoku_model.attempt_cat(solution[index])
	game._sync_meowdoku_state()
	game.catalog_fx.clear()
	game.meowdoku_presenter.reset(game.elapsed, solution[-1])
	game._meowdoku_command("cat", solution[-1])
	_save_state("10_complete")
	var completion_started: float = game.meowdoku_presenter.event_started
	var motion_dir := "%s/complete_motion" % OUTPUT
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(motion_dir))
	game.set_process(false)
	for frame in range(30):
		game.elapsed = completion_started + float(frame) / 30.0
		game.queue_redraw()
		await process_frame
		if frame == 4:
			await _save_frame("10_complete_impact")
		elif frame == 20:
			await _save_frame("11_complete_settle")
		await _save_frame("complete_motion/frame_%02d" % frame)
	game.elapsed = completion_started + 1.10
	game.queue_redraw()
	await process_frame
	await _save_frame("12_complete_result")
	game.set_process(true)

	game._set_reduced_effects(true)
	game._reset_current()
	first = game.meowdoku_model.solution[0]
	game._meowdoku_command("cat", first)
	await _wait(0.10)
	await _save_frame("13_reduced_cat")
	_save_state("13_reduced")
	game._set_reduced_effects(false)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame
	await process_frame


func _save_frame(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := "%s/%s.webp" % [OUTPUT, stem]
	var error := image.save_webp(ProjectSettings.globalize_path(path), false, 0.94)
	if error != OK:
		push_error("Meowdoku v3 visual capture failed: %s" % path)


func _save_state(stem: String) -> void:
	var effect := {}
	if not game.catalog_fx.is_empty():
		var source: Dictionary = game.catalog_fx.back()
		effect = {
			"game_id":source.get("game_id", ""), "kind":source.get("kind", ""),
			"grade":source.get("grade", 0), "label":source.get("label", ""),
			"font_role":source.get("font_role", ""),
		}
	var report := {
		"game_id":game.game_id, "puzzle_id":game.state.get("puzzle_id", ""),
		"status":game.state.get("status", ""), "moves":game.state.get("moves", 0),
		"mistakes":game.state.get("mistakes", 0), "hearts":game.state.get("hearts", 0),
		"placed":game.state.get("placed", 0), "required":game.state.get("required", 0),
		"selected":game.state.get("selected", []), "cats":game.state.get("cats", []),
		"manual_marks":game.state.get("manual_marks", []), "derived_marks":game.state.get("derived_marks", []),
		"event":effect, "presenter":game.meowdoku_presenter.snapshot(game.elapsed),
		"reduced_effects":game.reduced_effects,
	}
	var file := FileAccess.open(ProjectSettings.globalize_path("%s/%s.json" % [OUTPUT, stem]), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
