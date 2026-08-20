extends SceneTree

const OUTPUT := "user://watermelon_gag_v3_physics_performance.json"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._open_game("watermelon")
	var tiers := [1, 2, 3, 4, 5, 2, 3, 4, 1, 3, 5, 2, 4, 1, 5, 3, 2, 4]
	for index in range(tiers.size()):
		var row := index / 6
		var column := index % 6
		game.watermelon_model.inject_ball(
			int(tiers[index]),
			Vector2(92.0 + float(column) * 69.0, 648.0 - float(row) * 59.0),
			Vector2.ZERO,
			100 + index
		)
	game._sync_watermelon_state()
	for _warmup in range(24):
		await process_frame

	var samples: Array[float] = []
	var previous := Time.get_ticks_usec()
	for frame in range(180):
		if frame % 38 == 0:
			_emit_busy_case()
		await process_frame
		var current := Time.get_ticks_usec()
		samples.append(float(current - previous) / 1000.0)
		previous = current

	samples.sort()
	var total := 0.0
	for sample in samples:
		total += sample
	var report := {
		"game_id": "watermelon",
		"sample_count": samples.size(),
		"busy_effect_cap": 6,
		"average_frame_ms": total / samples.size(),
		"p95_frame_ms": samples[clampi(int(ceil(samples.size() * 0.95)) - 1, 0, samples.size() - 1)],
		"max_frame_ms": samples.back(),
		"renderer": RenderingServer.get_video_adapter_name(),
		"viewport": [int(game.size.x), int(game.size.y)],
		"note": "Xvfb/llvmpipe comparative trace with an 18-ball free-physics pile, GAG fruit textures, stable GAG tray and six capped grade-four events; not a device FPS claim",
	}
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("WATERMELON_PERFORMANCE=%s" % ProjectSettings.globalize_path(OUTPUT))
	game.queue_free()
	await process_frame
	await process_frame
	quit()


func _emit_busy_case() -> void:
	for index in range(12):
		var column := index % 7
		var row := index % 3
		game._start_catalog_event(
			"fruit_merge",
			Vector2(70 + column * 62, 668 - row * 50),
			game._fruit_color(4),
			4,
			"葡萄连携 · +90",
			0.92
		)
