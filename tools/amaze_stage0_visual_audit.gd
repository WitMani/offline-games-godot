extends SceneTree

const OUTPUT := "res://docs/audit/amaze-v3/stage0"
const LEVEL_THREE_SOLUTION := [
	Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN,
	Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP, Vector2i.RIGHT,
	Vector2i.DOWN, Vector2i.LEFT,
]

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	await _wait(0.20)
	_open_level_three()
	await _wait(0.18)
	await _save_frame("00-topology-stable")
	game._amaze_step(Vector2i.RIGHT)
	await _wait(0.12)
	await _save_frame("01-long-roll")
	_save_state("01-long-roll")
	game.catalog_fx.clear()
	game.motion_started = -10.0
	game.feedback_until = -10.0
	game._amaze_step(Vector2i.LEFT)
	await _wait(0.12)
	await _save_frame("02-revisit")
	_save_state("02-revisit")
	_open_level_three()
	for index in range(LEVEL_THREE_SOLUTION.size() - 1):
		game._amaze_step(LEVEL_THREE_SOLUTION[index])
		if index < LEVEL_THREE_SOLUTION.size() - 2:
			game.catalog_fx.clear()
			game.motion_started = -10.0
			game.feedback_until = -10.0
	await _wait(0.14)
	await _save_frame("03-near-complete")
	_save_state("03-near-complete")
	game.catalog_fx.clear()
	game.motion_started = -10.0
	game.feedback_until = -10.0
	game._amaze_step(LEVEL_THREE_SOLUTION.back())
	await _wait(0.18)
	await _save_frame("04-complete-impact")
	await _wait(0.82)
	await _save_frame("05-complete-result")
	_save_state("05-complete-result")
	print("AMAZE_STAGE0_VISUAL_AUDIT=%s" % ProjectSettings.globalize_path(OUTPUT))
	quit()


func _open_level_three() -> void:
	game._clear_amaze_checkpoint()
	game._open_game("amaze")
	game.amaze_level_index = 2
	game._start_game_state()
	game._build_game_buttons()
	game.has_transitioned = false
	game.catalog_fx.clear()
	game.motion_started = -10.0
	game.feedback_until = -10.0


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame
	await process_frame


func _save_frame(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.webp" % [OUTPUT, stem])
	var error := image.save_webp(path, false, 0.94)
	if error != OK:
		push_error("Amaze Stage 0 visual capture failed: %s" % path)


func _save_state(stem: String) -> void:
	var event: Dictionary = {}
	if not game.catalog_fx.is_empty():
		var source: Dictionary = game.catalog_fx.back()
		event = {
			"kind":source.get("kind", ""),
			"semantic":source.get("semantic", ""),
			"grade":source.get("grade", 0),
			"label":source.get("label", ""),
			"font_role":source.get("font_role", ""),
			"direction":source.get("direction", []),
			"traversed":source.get("traversed", []),
			"newly_painted":source.get("newly_painted", []),
			"remaining":source.get("remaining", -1),
		}
	var report := {
		"game_id":"amaze",
		"rules_version":game.state.get("rules_version", ""),
		"level_id":game.state.get("level_id", ""),
		"status":game.state.get("status", ""),
		"player":game.state.get("player", []),
		"painted_count":game.state.get("painted_count", 0),
		"walkable_count":game.state.get("walkable_count", 0),
		"remaining":game.state.get("remaining", 0),
		"moves":game.state.get("moves", 0),
		"last_traversal":game.state.get("last_traversal", []),
		"last_newly_painted":game.state.get("last_newly_painted", []),
		"event":event,
	}
	var path := ProjectSettings.globalize_path("%s/%s.json" % [OUTPUT, stem])
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
