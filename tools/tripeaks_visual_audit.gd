extends SceneTree

const OUTPUT := "res://docs/audit/tripeaks-v2/candidate"
const PEAK_FRAME_ROOT := "user://tripeaks-v2-frames"
const PEAK_FRAME_COUNT := 36

var game: Control
var evidence := {
	"viewport": [540, 960],
	"effects_mode": "full",
	"language": "zh-CN",
	"captures": [],
	"continuous_peak_frames": {},
	"continuous_peak_recording": "continuous/tripeaks-grade4-streak.webm",
	"web_stable_capture": "web/tripeaks-web.png",
	"state_snapshots": {},
	"runtime_resources": {
		"card_back": "res://assets/art/cards/tripeaks_card_back_gag_v1.webp",
		"sfx": "res://assets/audio/cards/tripeaks_streak_peak_gag_v1.ogg",
	},
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PEAK_FRAME_ROOT))
	await _render_frames(3)
	await _capture_tripeaks()
	_write_evidence()
	print("TRIPEAKS_VISUAL_AUDIT_DIR=%s" % ProjectSettings.globalize_path(OUTPUT))
	print("TRIPEAKS_VISUAL_AUDIT=%d" % evidence["captures"].size())
	for player in game.sfx_players:
		player.stop()
	game.queue_free()
	await process_frame
	quit()


func _capture_tripeaks() -> void:
	_open_for_audit()
	await _render_frames(2)
	await _save_frame("00-stable")

	_open_for_audit()
	game._tripeaks_tap(game._tripeaks_card_center(0))
	await _capture_latest_event("locked-reject")

	_open_for_audit()
	game._tripeaks_tap(game._tripeaks_card_center(5))
	await _capture_latest_event("rank-reject")

	_open_for_audit()
	game._tripeaks_next()
	await _capture_latest_event("deal")

	_open_for_audit()
	game.state["current"] = 8
	game._tripeaks_tap(game._tripeaks_card_center(5))
	await _capture_latest_event("streak-grade1")

	_open_for_audit()
	game.state["current"] = 8
	game.state["streak"] = 5
	game._tripeaks_tap(game._tripeaks_card_center(5))
	evidence["state_snapshots"]["grade4_streak"] = game.state.duplicate(true)
	await _capture_latest_event("streak-grade4")
	await _capture_continuous_peak()

	_open_for_audit()
	game.state["current"] = 8
	game.state["removed"] = [0, 1, 2, 3]
	game._tripeaks_tap(game._tripeaks_card_center(5))
	evidence["state_snapshots"]["milestone"] = game.state.duplicate(true)
	await _capture_latest_event("milestone")

	_open_for_audit()
	game.state["current"] = 8
	var removed: Array = []
	for index in range(game.state["cards"].size()):
		if index != 5:
			removed.append(index)
	game.state["removed"] = removed
	game._tripeaks_tap(game._tripeaks_card_center(5))
	evidence["state_snapshots"]["win"] = game.state.duplicate(true)
	await _capture_latest_event("win")


func _open_for_audit() -> void:
	game._open_game("tripeaks")
	game.has_transitioned = false


func _capture_latest_event(prefix: String) -> void:
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


func _capture_continuous_peak() -> void:
	if game.catalog_fx.is_empty():
		push_error("No continuous peak event available")
		return
	var frame_dir_absolute := ProjectSettings.globalize_path(PEAK_FRAME_ROOT)
	var effect: Dictionary = game.catalog_fx.back()
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
	}


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
		push_error("TriPeaks visual capture failed: %s" % relative_path)
	else:
		evidence["captures"].append(relative_path)


func _write_evidence() -> void:
	var path := ProjectSettings.globalize_path("%s/evidence.json" % OUTPUT)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(evidence, "  ") + "\n")
