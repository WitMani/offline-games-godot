extends SceneTree

const OUTPUT := "res://docs/audit/solitaire-v2/candidate"
const PEAK_FRAME_ROOT := "user://solitaire-v2-frames"
const PEAK_FRAME_COUNT := 36

var game: Control
var evidence := {
	"viewport": [540, 960],
	"effects_mode": "full",
	"language": "zh-CN",
	"captures": [],
	"continuous_peak_frames": {},
	"continuous_peak_recording": "continuous/solitaire-win.webm",
	"web_stable_capture": "web/solitaire-web.png",
	"state_snapshots": {},
	"runtime_resources": {
		"card_back": "res://assets/art/cards/solitaire_card_back_gag_v1.webp",
		"sfx": "res://assets/audio/cards/solitaire_card_settle_gag_v1.ogg",
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
	await _capture_solitaire()
	_write_evidence()
	print("SOLITAIRE_VISUAL_AUDIT_DIR=%s" % ProjectSettings.globalize_path(OUTPUT))
	print("SOLITAIRE_VISUAL_AUDIT=%d" % evidence["captures"].size())
	for player in game.sfx_players:
		player.stop()
	game.queue_free()
	await process_frame
	quit()


func _capture_solitaire() -> void:
	_open_for_audit()
	await _render_frames(2)
	await _save_frame("00-stable")
	game._solitaire_tap(Vector2(63, 448))
	await _capture_latest_event("selection")

	_open_for_audit()
	game._solitaire_tap(Vector2(471, 448))
	await _capture_latest_event("reject-empty")

	_open_for_audit()
	game._solitaire_draw()
	await _capture_latest_event("deal")

	_open_for_audit()
	game.state["foundations"] = [1, 1, 1, 0]
	game.state["tableau"] = [1, 0, 0, 0, 0, 0, 0]
	game._solitaire_auto()
	evidence["state_snapshots"]["milestone"] = game.state.duplicate(true)
	await _capture_latest_event("foundation")

	_open_for_audit()
	game.state["foundations"] = [2, 2, 2, 1]
	game.state["tableau"] = [1, 0, 0, 0, 0, 0, 0]
	game._solitaire_auto()
	evidence["state_snapshots"]["win"] = game.state.duplicate(true)
	await _capture_latest_event("win")
	await _capture_continuous_peak()


func _open_for_audit() -> void:
	game._open_game("solitaire")
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
		push_error("Solitaire visual capture failed: %s" % relative_path)
	else:
		evidence["captures"].append(relative_path)


func _write_evidence() -> void:
	var path := ProjectSettings.globalize_path("%s/evidence.json" % OUTPUT)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(evidence, "  ") + "\n")
