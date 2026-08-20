extends SceneTree

## Lightweight busy-event trace for the 2248 presentation slice. Run under
## Xvfb so CanvasItem drawing uses the same compatibility renderer as desktop.

const OUTPUT := "user://merge2248_visual_audit/performance.json"
const SAMPLE_COUNT := 120


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Control = load("res://main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(12):
		await process_frame
	game._open_game("merge2248")
	game.has_transitioned = false
	var rect: Rect2 = game._merge2248_board_rect()
	var cell := Vector2(rect.size.x / 5.0, rect.size.y / 8.0)
	game.merge2248_model.board[7][0] = 2
	game.merge2248_model.board[7][1] = 2
	game.merge2248_model.board[6][2] = 4
	game._sync_merge2248_state()
	game._merge2248_begin_at(rect.position + Vector2(cell.x * 0.5, cell.y * 7.5))
	game.merge2248_drag_active = true
	game._merge2248_extend_at(rect.position + Vector2(cell.x * 1.5, cell.y * 7.5))
	game._merge2248_extend_at(rect.position + Vector2(cell.x * 2.5, cell.y * 6.5))
	game._merge2248_release()
	game.merge2248_drag_active = false

	var samples_ms: Array[float] = []
	for _sample in range(SAMPLE_COUNT):
		var started := Time.get_ticks_usec()
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		samples_ms.append(float(Time.get_ticks_usec() - started) / 1000.0)
	samples_ms.sort()
	var total := 0.0
	for sample in samples_ms:
		total += sample
	var result := {
		"renderer": RenderingServer.get_current_rendering_method(),
		"samples": SAMPLE_COUNT,
		"average_ms": total / float(SAMPLE_COUNT),
		"p50_ms": samples_ms[int(SAMPLE_COUNT * 0.50)],
		"p95_ms": samples_ms[int(SAMPLE_COUNT * 0.95)],
		"max_ms": samples_ms[-1],
		"note": "EC2 Xvfb software-GL trace; regression guard, not end-user GPU telemetry",
	}
	var output_path := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	print("MERGE2248_PERFORMANCE=%s" % JSON.stringify(result))
	quit()
