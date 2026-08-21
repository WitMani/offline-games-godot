extends SceneTree

const OUTPUT := "res://docs/audit/solitaire-fidelity-v3/candidate"
const PEAK_FRAME_ROOT := "user://solitaire-fidelity-v3-frames"
const PEAK_FRAME_COUNT := 36

var game: Control
var evidence := {
	"schema": "offline-games-matched-visual-evidence/v1",
	"game": "solitaire",
	"viewport": [540, 960],
	"language": "zh-CN",
	"effects_modes": ["full", "reduced"],
	"matched_sequence": ["00-stable", "01-intent", "02-anticipation", "03-impact", "04-settle", "05-result"],
	"captures": [],
	"state_snapshots": {},
	"continuous_peak_frames": {},
	"runtime_resources": {
		"card_back": "res://assets/art/cards/solitaire_card_back_gag_v1.webp",
		"settle_sfx": "res://assets/audio/cards/solitaire_card_settle_gag_v1.ogg",
		"opening_visible_card_backs": 22,
	},
	"claim_boundary": {
		"first_party_solitaire_gameplay_visible": false,
		"target_fidelity": "PARTIAL",
		"surpass_reference": "NOT_CLAIMED",
		"deployed": false,
	},
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	# Phase positions are sampled deterministically; pause wall-clock mutation so
	# screenshot I/O cannot advance or prune an event between matched frames.
	game.set_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PEAK_FRAME_ROOT))
	await _render_frames(3)
	await _capture_full_sequences()
	await _capture_reduced_sequence()
	_write_evidence()
	print("SOLITAIRE_V3_VISUAL_AUDIT_DIR=%s" % ProjectSettings.globalize_path(OUTPUT))
	print("SOLITAIRE_V3_VISUAL_AUDIT=%d" % evidence["captures"].size())
	for player in game.sfx_players:
		player.stop()
	game.queue_free()
	await process_frame
	quit()


func _capture_full_sequences() -> void:
	game._set_solitaire_reduced_effects(false)

	_open_for_audit()
	await _save_frame("opening/00-stable")
	await _save_frame("opening-select/00-stable")
	game._solitaire_tap(Vector2(63, 448))
	await _capture_latest_event("opening-select", false)

	_open_for_audit()
	await _save_frame("draw/00-stable")
	game._solitaire_draw()
	evidence["state_snapshots"]["draw_result"] = game.state.duplicate(true)
	await _capture_latest_event("draw", false)

	_open_for_audit()
	var legal_fixture := _fixture([
		[{"card":_cid(9, 3), "face_up":true}],
		[{"card":_cid(10, 2), "face_up":true}],
	])
	game._restore_solitaire_snapshot(legal_fixture)
	await _save_frame("move/00-stable")
	game._solitaire_tap(Vector2(63, 448))
	game.catalog_fx.clear()
	game._solitaire_tap(Vector2(131, 448))
	evidence["state_snapshots"]["move_result"] = game.state.duplicate(true)
	await _capture_latest_event("move", false)

	_open_for_audit()
	var reject_fixture := _fixture([
		[{"card":_cid(9, 2), "face_up":true}],
		[{"card":_cid(10, 0), "face_up":true}],
	])
	game._restore_solitaire_snapshot(reject_fixture)
	await _save_frame("reject/00-stable")
	game._solitaire_tap(Vector2(63, 448))
	game.catalog_fx.clear()
	game._solitaire_tap(Vector2(131, 448))
	evidence["state_snapshots"]["reject_result"] = game.state.duplicate(true)
	await _capture_latest_event("reject", false)

	_open_for_audit()
	var milestone_fixture := _fixture([], [_cid(13, 0)], [12, 0, 0, 0])
	game._restore_solitaire_snapshot(milestone_fixture)
	await _save_frame("foundation/00-stable")
	game._solitaire_auto()
	evidence["state_snapshots"]["foundation_result"] = game.state.duplicate(true)
	await _capture_latest_event("foundation", false)

	_open_for_audit()
	var win_fixture := _fixture([], [_cid(13, 3)], [13, 13, 13, 12])
	game._restore_solitaire_snapshot(win_fixture)
	await _save_frame("win/00-stable")
	game._solitaire_auto()
	evidence["state_snapshots"]["win_result"] = game.state.duplicate(true)
	await _capture_latest_event("win", true)


func _capture_reduced_sequence() -> void:
	game._set_solitaire_reduced_effects(true)
	game.solitaire_haptic_emissions = 0
	_open_for_audit()
	var fixture := _fixture([], [_cid(13, 3)], [13, 13, 13, 12])
	game._restore_solitaire_snapshot(fixture)
	await _save_frame("reduced-win/00-stable")
	game._solitaire_auto()
	var effect: Dictionary = game.catalog_fx.back()
	evidence["state_snapshots"]["reduced_win_result"] = game.state.duplicate(true)
	evidence["reduced_event"] = {
		"duration": effect.get("duration"),
		"motion_mode": effect.get("motion_mode"),
		"haptic_emissions": game.solitaire_haptic_emissions,
	}
	game.catalog_fx.clear()
	game.queue_redraw()
	await _render_frames(1)
	await _save_frame("reduced-win/05-result")
	game._set_solitaire_reduced_effects(false)


func _open_for_audit() -> void:
	game.catalog_fx.clear()
	game._open_game("solitaire")
	game.has_transitioned = false
	game.feedback_until = -1.0


func _capture_latest_event(prefix: String, capture_continuous: bool) -> void:
	if game.catalog_fx.is_empty():
		push_error("No event available for %s" % prefix)
		return
	var effect: Dictionary = game.catalog_fx.back()
	var duration := float(effect.get("duration", 0.72))
	var samples := [
		["01-intent", 0.06],
		["02-anticipation", 0.25],
		["03-impact", 0.55],
		["04-settle", 0.88],
	]
	for sample in samples:
		effect["started"] = game.elapsed - duration * float(sample[1])
		game.queue_redraw()
		await _render_frames(1)
		await _save_frame("%s/%s" % [prefix, sample[0]])
	if capture_continuous:
		await _capture_continuous_peak(effect)
	game.catalog_fx.clear()
	game.queue_redraw()
	await _render_frames(1)
	await _save_frame("%s/05-result" % prefix)


func _capture_continuous_peak(effect: Dictionary) -> void:
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
			push_error("Continuous peak frame failed: %s" % frame_path)
	evidence["continuous_peak_frames"] = {
		"directory": frame_dir_absolute,
		"count": PEAK_FRAME_COUNT,
		"sampled_progress": [0.0, 0.98],
		"encoding_fps": 30,
		"recording": "continuous/solitaire-win.webm",
	}


func _cid(rank: int, suit: int) -> int:
	return suit * 13 + rank - 1


func _fixture(piles: Array, waste: Array = [], foundation_counts: Array = [0, 0, 0, 0]) -> Dictionary:
	var saved: Dictionary = game.solitaire_model.snapshot()
	var used := {}
	var foundations: Array = []
	for suit in range(4):
		var foundation: Array = []
		for rank in range(1, int(foundation_counts[suit]) + 1):
			var card := _cid(rank, suit)
			used[card] = true
			foundation.append(card)
		foundations.append(foundation)
	var tableau: Array = []
	for column in range(7):
		var pile: Array = piles[column].duplicate(true) if column < piles.size() else []
		for entry in pile:
			used[int(entry["card"])] = true
		tableau.append(pile)
	var normalized_waste: Array = []
	for value in waste:
		used[int(value)] = true
		normalized_waste.append(int(value))
	var stock: Array = []
	for card in range(52):
		if not used.has(card):
			stock.append(card)
	saved["stock"] = stock
	saved["waste"] = normalized_waste
	saved["tableau"] = tableau
	saved["foundations"] = foundations
	saved["score"] = 0
	saved["moves"] = 0
	saved["recycles_used"] = 0
	saved["status"] = "playing"
	return saved


func _render_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _save_frame(stem: String) -> void:
	var relative_path := "%s.png" % stem
	var absolute_path := ProjectSettings.globalize_path("%s/%s" % [OUTPUT, relative_path])
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	if image.save_png(absolute_path) != OK:
		push_error("Solitaire v3 visual capture failed: %s" % relative_path)
	else:
		evidence["captures"].append(relative_path)


func _write_evidence() -> void:
	var path := ProjectSettings.globalize_path("%s/evidence.json" % OUTPUT)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(evidence, "  ") + "\n")
