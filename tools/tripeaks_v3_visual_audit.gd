extends SceneTree

## Deterministic 540x960 evidence for TriPeaks v3. Every captured effect is
## reached through the authoritative model/shell command, never by mutating the
## rendered card arrays.

const OUTPUT := "res://docs/audit/tripeaks-v3/candidate"
const PEAK_FRAME_ROOT := "user://tripeaks-v3-continuous-frames"
const PEAK_FRAME_COUNT := 42

var game: Control
var failures: Array[String] = []
var evidence := {
	"schema": "offline-games-visual-audit/v3",
	"game_id": "tripeaks",
	"viewport": [540, 960],
	"language": "zh-CN",
	"effects_modes": ["full", "reduced"],
	"captures": [],
	"state_snapshots": {},
	"continuous_peak_frames": {},
	"continuous_peak_recording": "continuous/tripeaks-grade4-streak.webm",
	"runtime_resources": {
		"card_back": "res://assets/art/cards/tripeaks_card_back_gag_v1.webp",
		"streak_sfx": "res://assets/audio/cards/tripeaks_streak_peak_gag_v1.ogg",
	},
	"claim_boundary": "local art/runtime evidence; not target-version fidelity proof",
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate() as Control
	root.add_child(game)
	game.set_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PEAK_FRAME_ROOT))
	await _render_frames(3)
	await _capture_suite()
	_write_evidence()
	print("TRIPEAKS_V3_VISUAL_AUDIT_DIR=%s" % ProjectSettings.globalize_path(OUTPUT))
	print("TRIPEAKS_V3_VISUAL_CAPTURE_COUNT=%d" % evidence["captures"].size())
	print("TRIPEAKS_V3_VISUAL_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	for player in game.sfx_players:
		player.stop()
	game._clear_tripeaks_snapshot()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _capture_suite() -> void:
	_open_for_audit()
	_snapshot("stable")
	await _render_frames(2)
	await _save_frame("00-stable", "stable", "settled")

	_open_for_audit()
	game._tripeaks_tap(game._tripeaks_card_center(0))
	await _capture_event("locked-reject", _find_effect("card_reject_locked"))

	_open_for_audit()
	var rank_fixture := _fixture({0:_cid(12, 3), 3:_cid(11, 2), 9:_cid(10, 1), 18:_cid(9, 0)}, _cid(5, 2), [_cid(2, 3)], 3)
	if not game._restore_tripeaks_snapshot(rank_fixture):
		failures.append("rank_fixture_restore")
	game._tripeaks_tap(game._tripeaks_card_center(18))
	await _capture_event("rank-reject", _find_effect("card_reject_rank_not_adjacent"))

	_open_for_audit()
	game._tripeaks_next()
	_snapshot("stock_draw")
	await _capture_event("stock-draw", _find_effect("card_draw"))

	_open_for_audit()
	var clear_fixture := _fixture({0:_cid(12, 3), 3:_cid(11, 2), 9:_cid(7, 1), 18:_cid(6, 0)}, _cid(5, 2), [_cid(2, 3)], 0)
	if not game._restore_tripeaks_snapshot(clear_fixture):
		failures.append("clear_fixture_restore")
	game._tripeaks_tap(game._tripeaks_card_center(18))
	_snapshot("legal_clear_and_reveal")
	await _capture_event("legal-clear", _find_effect("card_clear"))
	await _capture_event("reveal", _find_effect("card_reveal"))

	_open_for_audit()
	var streak_fixture := _fixture({0:_cid(12, 3), 3:_cid(11, 2), 9:_cid(7, 1), 18:_cid(6, 0)}, _cid(5, 2), [_cid(2, 3)], 6)
	if not game._restore_tripeaks_snapshot(streak_fixture):
		failures.append("streak_fixture_restore")
	game._tripeaks_tap(game._tripeaks_card_center(18))
	var streak_effect := _find_effect("card_streak")
	_snapshot("grade4_streak")
	await _capture_event("streak-grade4", streak_effect)
	await _capture_continuous_peak(streak_effect)

	_open_for_audit()
	var milestone_fixture := _fixture({0:_cid(6, 0), 1:_cid(9, 1), 2:_cid(11, 2)}, _cid(5, 3), [_cid(2, 3)], 2)
	if not game._restore_tripeaks_snapshot(milestone_fixture):
		failures.append("milestone_fixture_restore")
	game._tripeaks_tap(game._tripeaks_card_center(0))
	_snapshot("peak_milestone")
	await _capture_event("peak-milestone", _find_effect("peak_milestone"))

	_open_for_audit()
	var win_fixture := _fixture({0:_cid(6, 0)}, _cid(5, 2), [], 2)
	if not game._restore_tripeaks_snapshot(win_fixture):
		failures.append("win_fixture_restore")
	game._tripeaks_tap(game._tripeaks_card_center(0))
	_snapshot("final_peak_win")
	await _capture_event("final-peak-win", _find_effect("tripeaks_win"))

	_open_for_audit()
	var loss_fixture := _fixture({0:_cid(12, 0), 3:_cid(11, 1), 9:_cid(10, 2), 18:_cid(9, 0)}, _cid(5, 2), [_cid(2, 3)])
	if not game._restore_tripeaks_snapshot(loss_fixture):
		failures.append("loss_fixture_restore")
	game._tripeaks_next()
	_snapshot("loss")
	await _capture_event("loss", _find_effect("tripeaks_loss"))

	_open_for_audit()
	if not game._restore_tripeaks_snapshot(streak_fixture):
		failures.append("reduced_fixture_restore")
	game._set_tripeaks_reduced_effects(true)
	var reduced_haptics_before := int(game.tripeaks_haptic_emissions)
	game._tripeaks_tap(game._tripeaks_card_center(18))
	evidence["reduced_checks"] = {
		"catalog_effect_count": game.catalog_fx.size(),
		"shake_offset": [game._catalog_shake_offset().x, game._catalog_shake_offset().y],
		"haptic_before": reduced_haptics_before,
		"haptic_after": int(game.tripeaks_haptic_emissions),
		"haptic_delta": int(game.tripeaks_haptic_emissions) - reduced_haptics_before,
		"text_result": game.feedback_text,
	}
	if not game.catalog_fx.is_empty() or game._catalog_shake_offset() != Vector2.ZERO or int(game.tripeaks_haptic_emissions) != reduced_haptics_before:
		failures.append("reduced_effect_suppression")
	_snapshot("reduced_result")
	await _render_frames(2)
	await _save_frame("reduced/settled-result", "reduced", "result")
	game._set_tripeaks_reduced_effects(false)


func _open_for_audit() -> void:
	game._clear_tripeaks_snapshot()
	game.tripeaks_restart_requested = true
	game._open_game("tripeaks")
	game.tripeaks_restart_requested = false
	game.has_transitioned = false
	game.tripeaks_reduced_effects = false
	game.feedback_until = 0.0


func _cid(rank: int, suit: int = 0) -> int:
	return suit * 13 + rank - 1


func _fixture(active_slots: Dictionary, waste_top: int, stock_cards: Array = [], fixture_streak := 0) -> Dictionary:
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
	saved["streak"] = fixture_streak
	saved["status"] = "playing"
	saved["remaining"] = active_slots.size()
	return saved


func _find_effect(kind: String) -> Dictionary:
	for index in range(game.catalog_fx.size() - 1, -1, -1):
		var effect: Dictionary = game.catalog_fx[index]
		if str(effect.get("kind", "")) == kind:
			return effect
	return {}


func _capture_event(prefix: String, effect: Dictionary) -> void:
	if effect.is_empty():
		failures.append("missing_effect_%s" % prefix)
		return
	for other in game.catalog_fx:
		if other != effect:
			other["started"] = game.elapsed - float(other.get("duration", 0.72)) - 0.1
	var duration := float(effect.get("duration", 0.72))
	var samples := [
		["01-intent", 0.06],
		["02-anticipation", 0.25],
		["03-impact", 0.55],
		["04-settle", 0.88],
	]
	for sample in samples:
		var progress := float(sample[1])
		effect["started"] = game.elapsed - duration * progress
		game.queue_redraw()
		await _render_frames(1)
		await _save_frame("%s/%s" % [prefix, sample[0]], str(effect.get("kind", "")), game._card_event_phase_at(effect, game.elapsed))


func _capture_continuous_peak(effect: Dictionary) -> void:
	if effect.is_empty():
		failures.append("continuous_peak_missing")
		return
	var frame_dir_absolute := ProjectSettings.globalize_path(PEAK_FRAME_ROOT)
	var duration := float(effect.get("duration", 0.72))
	for frame_index in range(PEAK_FRAME_COUNT):
		var progress := float(frame_index) / float(PEAK_FRAME_COUNT - 1) * 0.98
		effect["started"] = game.elapsed - duration * progress
		game.queue_redraw()
		await _render_frames(1)
		await RenderingServer.frame_post_draw
		var image := game.get_viewport().get_texture().get_image()
		var frame_path := "%s/%04d.png" % [frame_dir_absolute, frame_index]
		if image.save_png(frame_path) != OK:
			failures.append("continuous_frame_%04d" % frame_index)
	evidence["continuous_peak_frames"] = {
		"directory": frame_dir_absolute,
		"count": PEAK_FRAME_COUNT,
		"sampled_progress": [0.0, 0.98],
		"encoding_fps": 30,
		"semantic_event": str(effect.get("kind", "")),
		"grade": int(effect.get("grade", 0)),
	}


func _snapshot(label: String) -> void:
	var locked_count := 0
	for slot in range(28):
		if int(game.tripeaks_model.tableau[slot]) >= 0 and not game.tripeaks_model.is_exposed(slot):
			locked_count += 1
	var semantics: Array = []
	for effect in game.catalog_fx:
		semantics.append({
			"kind": str(effect.get("kind", "")),
			"grade": int(effect.get("grade", 0)),
			"card_index": int(effect.get("card_index", -1)),
			"semantic": str(effect.get("semantic", "")),
		})
	evidence["state_snapshots"][label] = {
		"model": game.tripeaks_model.snapshot(),
		"locked_tableau_backs": locked_count,
		"stock_back_visible": not game.tripeaks_model.stock.is_empty(),
		"gag_back_instances": locked_count + (1 if not game.tripeaks_model.stock.is_empty() else 0),
		"effects": semantics,
		"haptic_emissions": int(game.tripeaks_haptic_emissions),
		"reduced_effects": bool(game.tripeaks_reduced_effects),
	}


func _render_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _save_frame(stem: String, event_kind: String, phase: String) -> void:
	var relative_path := "%s.png" % stem
	var absolute_path := ProjectSettings.globalize_path("%s/%s" % [OUTPUT, relative_path])
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	if image.save_png(absolute_path) != OK:
		failures.append("capture_%s" % stem)
	else:
		evidence["captures"].append({"path":relative_path, "event":event_kind, "phase":phase})


func _write_evidence() -> void:
	evidence["failures"] = failures.duplicate()
	var path := ProjectSettings.globalize_path("%s/evidence.json" % OUTPUT)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(evidence, "  ") + "\n")
