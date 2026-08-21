extends SceneTree

const OUTPUT := "res://docs/audit/solitaire-fidelity-v3/candidate/performance.json"
const SAMPLE_COUNT := 180

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var full := await _measure(false)
	var reduced := await _measure(true)
	var report := {
		"schema": "offline-games-busy-frame-audit/v1",
		"game": "solitaire",
		"viewport": [int(game.size.x), int(game.size.y)],
		"renderer": RenderingServer.get_video_adapter_name(),
		"rendering_method": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"static_memory_bytes": OS.get_static_memory_usage(),
		"runtime_asset_dimensions": [int(game.SOLITAIRE_CARD_BACK_TEXTURE.get_width()), int(game.SOLITAIRE_CARD_BACK_TEXTURE.get_height())],
		"full_effects": full,
		"reduced_effects": reduced,
		"thresholds": {"p95_frame_ms_max": 25.0, "max_frame_ms_max": 50.0, "effect_cap": 12},
		"result": "PASS" if _passes(full) and _passes(reduced) else "FAIL",
		"note": "Xvfb/llvmpipe comparative trace; not a physical-device FPS claim",
	}
	var absolute_path := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "  ") + "\n")
	print("SOLITAIRE_V3_PERFORMANCE=%s" % absolute_path)
	print("SOLITAIRE_V3_PERFORMANCE_RESULT=%s" % report["result"])
	for player in game.sfx_players:
		player.stop()
	game.queue_free()
	await process_frame
	quit(0 if report["result"] == "PASS" else 1)


func _passes(result: Dictionary) -> bool:
	return float(result["p95_frame_ms"]) <= 25.0 and float(result["max_frame_ms"]) <= 50.0 and int(result["active_effects_observed_max"]) <= 12


func _measure(reduced: bool) -> Dictionary:
	game._set_solitaire_reduced_effects(reduced)
	game._open_game("solitaire")
	game.has_transitioned = false
	game.catalog_fx.clear()
	game.solitaire_haptic_emissions = 0
	_emit_busy_case()
	for _warmup in range(24):
		await process_frame
	var samples: Array[float] = []
	var active_max := 0
	var previous := Time.get_ticks_usec()
	var refresh_interval := 12 if reduced else 54
	for frame in range(SAMPLE_COUNT):
		if frame % refresh_interval == 0:
			_emit_busy_case()
		await process_frame
		var current := Time.get_ticks_usec()
		samples.append(float(current - previous) / 1000.0)
		previous = current
		active_max = maxi(active_max, game.catalog_fx.size())
	samples.sort()
	var total := 0.0
	for sample in samples:
		total += sample
	return {
		"mode": "reduced" if reduced else "full",
		"sample_count": samples.size(),
		"average_frame_ms": total / float(samples.size()),
		"p95_frame_ms": samples[clampi(int(ceil(samples.size() * 0.95)) - 1, 0, samples.size() - 1)],
		"max_frame_ms": samples.back(),
		"active_effect_cap": 12,
		"active_effects_observed_max": active_max,
		"haptic_emissions": game.solitaire_haptic_emissions,
	}


func _emit_busy_case() -> void:
	for index in range(12):
		var suit := index % 4
		var grade := 4 if index % 5 == 0 else (3 if index % 3 == 0 else 2)
		var position := Vector2(72 + (index % 6) * 78, 286 + (index / 6) * 250)
		game._start_catalog_event("solitaire_win" if grade == 4 else "foundation_place", position, Color("f6c667"), grade, "牌桌反馈", 1.18, {
			"from": Vector2(62 + (index % 7) * 68, 624),
			"to": position,
			"rank": 13 - index % 5,
			"suit": suit,
			"card_size": Vector2(58, 80),
		})
