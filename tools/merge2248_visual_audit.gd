extends SceneTree

const OUTPUT := "user://merge2248_visual_audit"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Control = load("res://main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	await process_frame
	game._open_game("merge2248")
	game.set_process(false)
	game.has_transitioned = false
	await _save("01_baseline")
	var rect: Rect2 = game._merge2248_board_rect()
	var cell := Vector2(rect.size.x / 5.0, rect.size.y / 8.0)
	game.merge2248_model.board[7][0] = 2
	game.merge2248_model.board[7][1] = 2
	game.merge2248_model.board[6][2] = 4
	game._sync_merge2248_state()
	game._merge2248_begin_at(rect.position + Vector2(cell.x * 0.5, cell.y * 7.5))
	game._merge2248_extend_at(rect.position + Vector2(cell.x * 1.5, cell.y * 7.5))
	game._merge2248_extend_at(rect.position + Vector2(cell.x * 2.5, cell.y * 6.5))
	await _save("02_connection_preview")
	game._merge2248_release()
	await _save("03_merged")
	print("MERGE2248_VISUAL_AUDIT_DIR=%s" % ProjectSettings.globalize_path(OUTPUT))
	quit()

func _save(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_webp(ProjectSettings.globalize_path("%s/%s.webp" % [OUTPUT, label]), false, 0.94)
