extends SceneTree

const OUTPUT := "res://docs/audit/gb-snake-v2/candidate"
const TURN_MOTION := "user://gb-snake-v2-turn-motion"
const FORAGE_MOTION := "user://gb-snake-v2-forage-motion"
const MILESTONE_MOTION := "user://gb-snake-v2-milestone-motion"
const COMPLETE_MOTION := "user://gb-snake-v2-complete-motion"
const FIXED_SEED := 1362026

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for folder in [OUTPUT, TURN_MOTION, FORAGE_MOTION, MILESTONE_MOTION, COMPLETE_MOTION]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	await _wait(0.30)
	game.set_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	await _capture_stable_and_turn()
	await _capture_rejection()
	await _capture_forage()
	await _capture_milestone()
	await _capture_crash()
	await _capture_completion()
	print("GB_SNAKE_VISUAL_AUDIT=%s" % ProjectSettings.globalize_path(OUTPUT))
	print("GB_SNAKE_TURN_MOTION=%s" % ProjectSettings.globalize_path(TURN_MOTION))
	print("GB_SNAKE_FORAGE_MOTION=%s" % ProjectSettings.globalize_path(FORAGE_MOTION))
	print("GB_SNAKE_MILESTONE_MOTION=%s" % ProjectSettings.globalize_path(MILESTONE_MOTION))
	print("GB_SNAKE_COMPLETE_MOTION=%s" % ProjectSettings.globalize_path(COMPLETE_MOTION))
	quit()


func _prepare() -> void:
	game._open_game("snake_classic")
	game.has_transitioned = false
	game.snake_gb_model.reset(FIXED_SEED)
	game._sync_snake_gb_state()
	game.snake_gb_object_fx.clear()
	game.snake_fx_kind = ""
	game.snake_pixels.clear()
	game.snake_float_labels.clear()
	game.snake_ghosts.clear()
	game.snake_previous_cells.clear()
	game.snake_result_ready_at = -1.0
	game.snake_lcd_flash_until = -1.0
	game.snake_score_bump_until = -1.0
	game.snake_button_until = -1.0
	game.snake_reject_until = -1.0
	game.snake_reset_started = -10.0
	game.queue_redraw()
	await process_frame


func _capture_stable_and_turn() -> void:
	await _prepare()
	await _save_frame("00-stable")
	game._set_snake_direction(Vector2i.UP)
	_save_state("turn-intent-state")
	var started := float(game.snake_gb_object_fx.get("started", game.elapsed))
	for frame in range(18):
		game.elapsed = started + float(frame) / 30.0
		if frame == 4:
			game._snake_gb_step()
		game._snake_prune_fx()
		game.queue_redraw()
		await process_frame
		if frame == 1:
			await _save_frame("01-turn-press")
		elif frame == 4:
			await _save_frame("02-turn-reorient")
		elif frame == 8:
			await _save_frame("03-turn-step")
		elif frame == 17:
			await _save_frame("04-turn-settle")
		await _save_motion_frame(TURN_MOTION, frame)
	_save_state("turn-settle-state")


func _capture_rejection() -> void:
	await _prepare()
	game._set_snake_direction(Vector2i.LEFT)
	_save_state("reject-state")
	var started := float(game.snake_gb_object_fx.get("started", game.elapsed))
	for frame in range(12):
		game.elapsed = started + float(frame) / 30.0
		game.queue_redraw()
		await process_frame
		if frame == 1:
			await _save_frame("05-reject-kick")
		elif frame == 5:
			await _save_frame("06-reject-ghost")
		elif frame == 11:
			await _save_frame("07-reject-recovery")


func _capture_forage() -> void:
	await _prepare()
	var head: Vector2i = game.snake_gb_model.segments[0]
	game.snake_gb_model.food = head + Vector2i.RIGHT
	game.snake_gb_model.foods.assign([game.snake_gb_model.food])
	game._sync_snake_gb_state()
	await _save_frame("08-forage-intent")
	game._snake_gb_step()
	_save_state("forage-contact-state")
	var started := float(game.snake_gb_object_fx.get("started", game.elapsed))
	for frame in range(20):
		game.elapsed = started + float(frame) / 30.0
		if frame == 6:
			game._snake_gb_step()
		game._snake_prune_fx()
		game.queue_redraw()
		await process_frame
		if frame == 1:
			await _save_frame("09-forage-lock")
		elif frame == 4:
			await _save_frame("10-forage-contract")
		elif frame == 8:
			await _save_frame("11-forage-scan")
		elif frame == 13:
			await _save_frame("12-forage-growth")
		elif frame == 19:
			await _save_frame("13-forage-settle")
		await _save_motion_frame(FORAGE_MOTION, frame)
	_save_state("forage-settle-state")


func _capture_milestone() -> void:
	await _prepare()
	var line: Array[Vector2i] = []
	for x in range(12, 3, -1):
		line.append(Vector2i(x, 11))
	game.snake_gb_model.segments = line
	game.snake_gb_model.direction = Vector2i.RIGHT
	game.snake_gb_model.turn_queue.clear()
	game.snake_gb_model.food = Vector2i(2, 2)
	game.snake_gb_model.foods.assign([game.snake_gb_model.food])
	game.snake_gb_model.pending_growth = 1
	game.snake_gb_model.score = 9
	game._sync_snake_gb_state()
	await _save_frame("14-milestone-intent")
	game._snake_gb_step()
	_save_state("milestone-state")
	var started := float(game.snake_gb_object_fx.get("started", game.elapsed))
	for frame in range(26):
		game.elapsed = started + float(frame) / 30.0
		game._snake_prune_fx()
		game.queue_redraw()
		await process_frame
		if frame == 2:
			await _save_frame("15-milestone-register")
		elif frame == 7:
			await _save_frame("16-milestone-sweep")
		elif frame == 13:
			await _save_frame("17-milestone-seal")
		elif frame == 20:
			await _save_frame("18-milestone-notch")
		elif frame == 25:
			await _save_frame("19-milestone-settle")
		await _save_motion_frame(MILESTONE_MOTION, frame)


func _capture_crash() -> void:
	await _prepare()
	game.snake_gb_model.segments.assign([Vector2i(14, 8), Vector2i(13, 8), Vector2i(12, 8), Vector2i(11, 8)])
	game.snake_gb_model.direction = Vector2i.RIGHT
	game.snake_gb_model.turn_queue.clear()
	game.snake_gb_model.food = Vector2i(3, 3)
	game.snake_gb_model.foods.assign([game.snake_gb_model.food])
	game.snake_gb_model.score = 4
	game._sync_snake_gb_state()
	await _save_frame("20-crash-intent")
	game._snake_gb_step()
	_save_state("crash-state")
	var started := float(game.snake_gb_object_fx.get("started", game.elapsed))
	for frame in range(28):
		game.elapsed = started + float(frame) / 30.0
		game._snake_prune_fx()
		game.queue_redraw()
		await process_frame
		if frame == 1:
			await _save_frame("21-crash-compress")
		elif frame == 4:
			await _save_frame("22-crash-smear")
		elif frame == 9:
			await _save_frame("23-crash-recoil")
		elif frame == 20:
			await _save_frame("24-crash-result")
		elif frame == 27:
			await _save_frame("25-crash-settle")


func _capture_completion() -> void:
	await _prepare()
	var win_segments: Array[Vector2i] = []
	for column in range(game.snake_gb_model.width):
		var start_y: int = 0 if column == 0 else 1
		var end_y: int = game.snake_gb_model.height - 1
		var step_y := 1
		if column % 2 == 1:
			start_y = game.snake_gb_model.height - 1
			end_y = 1
			step_y = -1
		var y := start_y
		while (y <= end_y if step_y > 0 else y >= end_y) and win_segments.size() < 119:
			win_segments.append(Vector2i(column, y))
			y += step_y
	game.snake_gb_model.segments = win_segments
	game.snake_gb_model.direction = Vector2i.RIGHT
	game.snake_gb_model.turn_queue.clear()
	game.snake_gb_model.food = Vector2i(1, 0)
	game.snake_gb_model.foods.assign([game.snake_gb_model.food])
	game.snake_gb_model.score = 119
	game.snake_gb_model.pending_growth = 0
	game.snake_gb_model.phase = game.snake_gb_model.RUNNING
	game.snake_gb_model.terminal_reason = ""
	game._sync_snake_gb_state()
	await _save_frame("26-complete-intent")
	game._snake_gb_step()
	game.elapsed += 0.18
	game._snake_gb_step()
	_save_state("complete-state")
	var started := float(game.snake_gb_object_fx.get("started", game.elapsed))
	for frame in range(48):
		game.elapsed = started + float(frame) / 30.0
		game._snake_prune_fx()
		game.queue_redraw()
		await process_frame
		if frame == 2:
			await _save_frame("27-complete-sweep")
		elif frame == 8:
			await _save_frame("28-complete-peak")
		elif frame == 17:
			await _save_frame("29-complete-seal")
		elif frame == 25:
			await _save_frame("30-complete-result")
		elif frame == 38:
			await _save_frame("31-complete-stable")
		elif frame == 47:
			await _save_frame("32-complete-recovery")
		await _save_motion_frame(COMPLETE_MOTION, frame)


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
		push_error("GB Snake visual capture failed: %s" % path)


func _save_motion_frame(folder: String, frame: int) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/frame_%02d.webp" % [folder, frame])
	var error := image.save_webp(path, false, 0.92)
	if error != OK:
		push_error("GB Snake motion capture failed: %s" % path)


func _save_state(stem: String) -> void:
	var object_fx: Dictionary = game.snake_gb_object_fx.duplicate(true)
	object_fx.erase("started")
	var report := {
		"game_id":game.game_id,
		"status":game.state.get("status", ""),
		"score":game.state.get("score", 0),
		"moves":game.state.get("moves", 0),
		"segments":game.state.get("segments", []),
		"direction":game.state.get("direction", []),
		"turn_queue":game.state.get("turn_queue", []),
		"food":game.state.get("food", []),
		"pending_growth":game.state.get("pending_growth", 0),
		"terminal_reason":game.state.get("terminal_reason", ""),
		"object_fx":object_fx,
		"visual_kind":game.snake_fx_kind,
	}
	var path := ProjectSettings.globalize_path("%s/%s.json" % [OUTPUT, stem])
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
