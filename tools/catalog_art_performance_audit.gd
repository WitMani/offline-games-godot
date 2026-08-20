extends SceneTree

const OUTPUT := "user://catalog_art_performance.json"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._open_game("tileclub")
	for _warmup in range(20):
		await process_frame
	var samples: Array[float] = []
	var previous := Time.get_ticks_usec()
	for frame in range(180):
		if frame % 42 == 0:
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
		"sample_count": samples.size(),
		"busy_effect_cap": 12,
		"average_frame_ms": total / samples.size(),
		"p95_frame_ms": samples[clampi(int(ceil(samples.size() * 0.95)) - 1, 0, samples.size() - 1)],
		"max_frame_ms": samples.back(),
		"renderer": RenderingServer.get_video_adapter_name(),
		"viewport": [int(game.size.x), int(game.size.y)],
		"note": "Xvfb/llvmpipe audit host; comparative regression trace, not a device FPS claim"
	}
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("CATALOG_ART_PERFORMANCE=%s" % ProjectSettings.globalize_path(OUTPUT))
	quit()


func _emit_busy_case() -> void:
	for index in range(12):
		var column := index % 4
		var row := index / 4
		game._start_catalog_event(
			"stitch_match",
			Vector2(108 + column * 108, 330 + row * 140),
			game._tile_color(1 + index % 7),
			4,
			"三枚缝合 · +100",
			0.96
		)
