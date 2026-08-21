extends SceneTree

## Comparative llvmpipe trace for one matched authoritative two-reveal state.
## This is a regression/budget signal, not a physical-device FPS claim.

const OUTPUT := "res://docs/audit/tripeaks-v3/candidate/performance.json"
const SAMPLE_COUNT := 180

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate() as Control
	root.add_child(game)
	await process_frame
	for player in game.sfx_players:
		player.stop()
		player.stream = null
		player.free()
	game.sfx_players.clear()
	var full := await _measure_mode(false)
	var reduced := await _measure_mode(true)
	var report := {
		"schema": "offline-games-performance-audit/v3",
		"game_id": "tripeaks",
		"renderer": RenderingServer.get_video_adapter_name(),
		"rendering_method": ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown"),
		"viewport": [int(game.size.x), int(game.size.y)],
		"runtime_asset_dimensions": [int(game.TRIPEAKS_CARD_BACK_TEXTURE.get_width()), int(game.TRIPEAKS_CARD_BACK_TEXTURE.get_height())],
		"full": full,
		"reduced": reduced,
		"matched_authoritative_state": str(full["model_sha256"]) == str(reduced["model_sha256"]),
		"p95_ratio_full_over_reduced": float(full["p95_frame_ms"]) / maxf(0.001, float(reduced["p95_frame_ms"])),
		"note": "Comparative software-renderer trace; synthetic event age is held at impact for the bounded two-reveal busy case; not a physical-device FPS claim",
	}
	var absolute_path := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "  ") + "\n")
	print("TRIPEAKS_V3_PERFORMANCE=%s" % absolute_path)
	print("TRIPEAKS_V3_PERFORMANCE_MATCHED=%s" % str(report["matched_authoritative_state"]))
	game._clear_tripeaks_snapshot()
	game.queue_free()
	await process_frame
	quit(0 if bool(report["matched_authoritative_state"]) else 1)


func _measure_mode(reduced: bool) -> Dictionary:
	game._clear_tripeaks_snapshot()
	game.tripeaks_restart_requested = true
	game._open_game("tripeaks")
	game.tripeaks_restart_requested = false
	game.has_transitioned = false
	var fixture := _busy_fixture()
	if not game._restore_tripeaks_snapshot(fixture):
		return {"error":"fixture_restore_failed", "model_sha256":""}
	game._set_tripeaks_reduced_effects(reduced)
	var haptic_before := int(game.tripeaks_haptic_emissions)
	game._tripeaks_tap(game._tripeaks_card_center(19))
	var haptic_after := int(game.tripeaks_haptic_emissions)
	var model_json := JSON.stringify(game.tripeaks_model.snapshot())
	var semantic_effects: Array = []
	for effect in game.catalog_fx:
		semantic_effects.append({
			"kind":str(effect.get("kind", "")),
			"grade":int(effect.get("grade", 0)),
			"card_index":int(effect.get("card_index", -1)),
		})
	for _warmup in range(24):
		_hold_busy_impact()
		await process_frame
	var samples: Array[float] = []
	var previous := Time.get_ticks_usec()
	for _frame in range(SAMPLE_COUNT):
		_hold_busy_impact()
		await process_frame
		var current := Time.get_ticks_usec()
		samples.append(float(current - previous) / 1000.0)
		previous = current
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
		"active_effects_observed": game.catalog_fx.size(),
		"semantic_effects": semantic_effects,
		"model_sha256": model_json.sha256_text(),
		"model_remaining": int(game.tripeaks_model.remaining_tableau_count()),
		"revealed_slots": game.tripeaks_model.exposed_slots(),
		"haptic_before": haptic_before,
		"haptic_after": haptic_after,
		"haptic_delta": haptic_after - haptic_before,
		"static_memory_bytes": OS.get_static_memory_usage(),
	}


func _hold_busy_impact() -> void:
	for effect in game.catalog_fx:
		effect["started"] = game.elapsed - float(effect.get("duration", 0.72)) * 0.55


func _cid(rank: int, suit: int = 0) -> int:
	return suit * 13 + rank - 1


func _busy_fixture() -> Dictionary:
	# Clearing shared blocker 19 reveals slots 9 and 10 together, producing the
	# maximum local clear + two exact reveal envelopes from one legal action.
	var active_slots := {
		0:_cid(12, 0), 3:_cid(11, 1), 4:_cid(10, 2),
		9:_cid(7, 1), 10:_cid(8, 2), 19:_cid(6, 0),
	}
	var waste_top := _cid(5, 3)
	var stock_cards := [_cid(2, 3)]
	var used := {}
	var tableau: Array = []
	for slot in range(28):
		var card := int(active_slots.get(slot, -1))
		if card >= 0:
			used[card] = true
		tableau.append(card)
	used[waste_top] = true
	var stock: Array = []
	for value in stock_cards:
		used[int(value)] = true
		stock.append(int(value))
	var waste: Array = []
	for card in range(52):
		if not used.has(card):
			waste.append(card)
	waste.append(waste_top)
	var removed: Array = []
	for slot in range(28):
		if int(tableau[slot]) < 0:
			removed.append(slot)
	var saved: Dictionary = game.tripeaks_model.snapshot()
	saved["tableau"] = tableau
	saved["removed"] = removed
	saved["stock"] = stock
	saved["waste"] = waste
	saved["score"] = removed.size() * 30
	saved["moves"] = waste.size() - 1
	saved["streak"] = 6
	saved["status"] = "playing"
	saved["remaining"] = active_slots.size()
	return saved
