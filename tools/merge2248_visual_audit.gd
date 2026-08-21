extends SceneTree

const OUTPUT := "user://merge2248_visual_audit"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Control = load("res://main.tscn").instantiate()
	game.merge2248_persistence_enabled = false
	game.merge2248_reduced_effects_override = false
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	await process_frame
	game._open_game("merge2248")
	game.set_process(false)
	game.has_transitioned = false
	await _save("01_idle")
	game.merge2248_model.board[0] = [1, 2, 3, 4, 5]
	game.merge2248_model.board[1] = [6, 7, 8, 9, 10]
	game._sync_merge2248_state()
	game.queue_redraw()
	await _save("01b_tier_gallery")
	var rect: Rect2 = game._merge2248_board_rect()
	var cell := Vector2(rect.size.x / 5.0, rect.size.y / 8.0)
	game.merge2248_model.board[7][0] = 1
	game.merge2248_model.board[7][1] = 1
	game.merge2248_model.board[6][2] = 2
	game._sync_merge2248_state()
	game._merge2248_begin_at(rect.position + Vector2(cell.x * 0.5, cell.y * 7.5))
	game.merge2248_drag_active = true
	game._merge2248_extend_at(rect.position + Vector2(cell.x * 1.5, cell.y * 7.5))
	game._merge2248_extend_at(rect.position + Vector2(cell.x * 2.5, cell.y * 6.5))
	game.merge2248_pointer = rect.position + Vector2(cell.x * 3.25, cell.y * 5.95)
	await _save("02_connection_preview")
	_write_snapshot("before_release", game.merge2248_model.snapshot())
	game._merge2248_release()
	game.merge2248_drag_active = false
	_write_snapshot("after_release", game.merge2248_model.snapshot())
	for frame_index in range(30):
		game.elapsed += 1.0 / 30.0
		game.queue_redraw()
		await _save("motion/frame_%03d" % frame_index)
		if frame_index == 5:
			await _save("03_merge_impact")
		elif frame_index == 16:
			await _save("04_merge_settle")
	await _save("05_final")
	game._merge2248_cycle_mode()
	_write_snapshot("hard_mode", game.merge2248_model.snapshot())
	await _save("06_hard_mode")
	game._merge2248_cycle_mode()
	for y in range(game.merge2248_model.height):
		for x in range(game.merge2248_model.width):
			game.merge2248_model.board[y][x] = y * game.merge2248_model.width + x + 1
	game.merge2248_model.board[7][0] = 70
	game.merge2248_model.board[7][1] = 70
	game.merge2248_model.board[0][3] = 1
	game.merge2248_model.board[0][4] = 1
	game._sync_merge2248_state()
	game._merge2248_begin_at(game._merge2248_cell_center(Vector2i(0, 7)))
	game.merge2248_drag_active = true
	game._merge2248_extend_at(game._merge2248_cell_center(Vector2i(1, 7)))
	game._merge2248_release()
	game.merge2248_drag_active = false
	game.elapsed = float(game.merge2248_fx[-1].started) + 0.18
	game.queue_redraw()
	_write_snapshot("long_run", game.merge2248_model.snapshot())
	await _save("07_long_run_exact")
	game._merge2248_undo()
	_write_snapshot("undo_restored", game.merge2248_model.snapshot())
	await _save("08_undo_restored")
	print("MERGE2248_VISUAL_AUDIT_DIR=%s" % ProjectSettings.globalize_path(OUTPUT))
	quit()

func _save(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var output_path := ProjectSettings.globalize_path("%s/%s.webp" % [OUTPUT, label])
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	image.save_webp(output_path, false, 0.94)

func _write_snapshot(label: String, snapshot: Dictionary) -> void:
	var output_path := ProjectSettings.globalize_path("%s/%s.json" % [OUTPUT, label])
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(snapshot, "  "))
