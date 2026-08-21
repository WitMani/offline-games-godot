extends SceneTree

const OUTPUT := "res://docs/audit/amaze-v3/stage0/performance.json"
const SOLUTION := [
	Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN,
	Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP, Vector2i.RIGHT,
	Vector2i.DOWN, Vector2i.LEFT,
]

var game: Control
var action_cursor := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	_open_level_three()
	for _warmup in range(60):
		await process_frame
	game.catalog_fx.clear()
	var stable := await _collect(180, false)
	_open_level_three()
	var busy := await _collect(240, true)
	var report := {
		"game_id":"amaze",
		"rules_version":game.state.get("rules_version", ""),
		"runtime":"Godot %s / software-renderer audit" % Engine.get_version_info().get("string", "4.6"),
		"renderer":RenderingServer.get_video_adapter_name(),
		"viewport":[int(game.size.x), int(game.size.y)],
		"stable":stable,
		"busy":busy,
		"busy_case":"deterministic level-three solution loop; long/short/revisit/near-complete/complete model actions with bounded catalog effects",
		"catalog_effect_cap":12,
		"note":"Regression trace for this environment; not a physical-device FPS claim.",
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(ProjectSettings.globalize_path(OUTPUT), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("AMAZE_STAGE0_PERFORMANCE=%s" % ProjectSettings.globalize_path(OUTPUT))
	quit()


func _open_level_three() -> void:
	game._clear_amaze_checkpoint()
	game._open_game("amaze")
	game.amaze_level_index = 2
	game._start_game_state()
	game._build_game_buttons()
	game.has_transitioned = false
	game.catalog_fx.clear()
	action_cursor = 0


func _collect(frame_count: int, busy: bool) -> Dictionary:
	var samples: Array[float] = []
	var peak_static_memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var previous := Time.get_ticks_usec()
	for frame in range(frame_count):
		if busy and frame % 12 == 0:
			_emit_action()
		await process_frame
		var current := Time.get_ticks_usec()
		samples.append(float(current - previous) / 1000.0)
		previous = current
		peak_static_memory = maxi(peak_static_memory, int(Performance.get_monitor(Performance.MEMORY_STATIC)))
	var ordered := samples.duplicate()
	ordered.sort()
	var total := 0.0
	for sample in samples:
		total += sample
	return {
		"sample_count":samples.size(),
		"average_frame_ms":total / samples.size(),
		"p95_frame_ms":ordered[clampi(int(ceil(ordered.size() * 0.95)) - 1, 0, ordered.size() - 1)],
		"max_frame_ms":ordered.back(),
		"peak_static_memory_bytes":peak_static_memory,
	}


func _emit_action() -> void:
	if str(game.state.get("status", "playing")) == "won":
		game.amaze_model.reset(2)
		game.amaze_level_index = 2
		game.amaze_last_outcome = {}
		game._sync_amaze_state()
		game._build_game_buttons()
		game.catalog_fx.clear()
		action_cursor = 0
	game._amaze_step(SOLUTION[action_cursor])
	action_cursor = (action_cursor + 1) % SOLUTION.size()
