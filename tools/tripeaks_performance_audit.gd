extends SceneTree

const OUTPUT := "res://docs/audit/tripeaks-v2/candidate/performance.json"

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	var report := await _measure()
	report["renderer"] = RenderingServer.get_video_adapter_name()
	report["viewport"] = [int(game.size.x), int(game.size.y)]
	report["static_memory_bytes"] = OS.get_static_memory_usage()
	report["runtime_asset_dimensions"] = [int(game.TRIPEAKS_CARD_BACK_TEXTURE.get_width()), int(game.TRIPEAKS_CARD_BACK_TEXTURE.get_height())]
	report["note"] = "Xvfb/llvmpipe comparative trace; not a physical-device FPS claim"
	var absolute_path := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "  ") + "\n")
	print("TRIPEAKS_PERFORMANCE=%s" % absolute_path)
	for player in game.sfx_players:
		player.stop()
	game.queue_free()
	await process_frame
	quit()


func _measure() -> Dictionary:
	game._open_game("tripeaks")
	game.has_transitioned = false
	_emit_busy_case()
	for _warmup in range(24):
		await process_frame
	var samples: Array[float] = []
	var previous := Time.get_ticks_usec()
	for frame in range(180):
		if frame % 54 == 0:
			_emit_busy_case()
		await process_frame
		var current := Time.get_ticks_usec()
		samples.append(float(current - previous) / 1000.0)
		previous = current
	samples.sort()
	var total := 0.0
	for sample in samples:
		total += sample
	return {
		"sample_count": samples.size(),
		"average_frame_ms": total / float(samples.size()),
		"p95_frame_ms": samples[clampi(int(ceil(samples.size() * 0.95)) - 1, 0, samples.size() - 1)],
		"max_frame_ms": samples.back(),
		"active_effect_cap": 12,
		"active_effects_observed": game.catalog_fx.size(),
	}


func _emit_busy_case() -> void:
	game._start_catalog_event("card_streak", Vector2(270, 382), Color("f6c667"), 4, "连牌 ×8", 1.02, {
		"from": Vector2(270, 382), "to": Vector2(76, 748),
		"rank": 8, "suit": 3, "card_size": Vector2(58, 78),
	})
	game._start_catalog_event("peak_milestone", Vector2(270, 340), Color("f6c667"), 3, "峰顶点亮", 0.96)
