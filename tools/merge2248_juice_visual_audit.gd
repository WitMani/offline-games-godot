extends SceneTree

## Deterministic visual proof for the four semantic juicing grades. Every
## fixture uses real pointer selection and the authoritative model release.

const OUTPUT := "user://merge2248_juice_visual_audit"
const CHAIN_LENGTHS := [2, 3, 5, 8]
const MOTION_FRAMES := 30

var game: Control
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.merge2248_persistence_enabled = false
	game.merge2248_reduced_effects_override = false
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	await process_frame
	game._open_game("merge2248")
	game.set_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	game.has_transitioned = false
	for grade_index in range(CHAIN_LENGTHS.size()):
		var grade := grade_index + 1
		var chain_length: int = CHAIN_LENGTHS[grade_index]
		_prepare_chain(chain_length)
		_expect(game.merge2248_chain_grade == grade, "preview_grade_%d" % grade)
		await _save("grade_%d_preview" % grade)
		game._merge2248_release()
		game.merge2248_drag_active = false
		_expect(not game.merge2248_fx.is_empty() and int(game.merge2248_fx[-1].grade) == grade, "impact_grade_%d" % grade)
		game.elapsed += 0.16
		game.queue_redraw()
		await _save("grade_%d_impact" % grade)
		game.elapsed += 1.24
	await _capture_legendary_motion()
	print("MERGE2248_JUICE_VISUAL_AUDIT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	print("MERGE2248_JUICE_VISUAL_AUDIT_DIR=%s" % ProjectSettings.globalize_path(OUTPUT))
	quit(0 if failures.is_empty() else 1)


func _prepare_chain(chain_length: int) -> void:
	game._init_merge2248(true)
	for y in range(game.merge2248_model.height):
		for x in range(game.merge2248_model.width):
			game.merge2248_model.board[y][x] = 1
	game._sync_merge2248_state()
	var path: Array[Vector2i] = []
	for index in range(chain_length):
		var row := index / 5
		var column := index % 5 if row % 2 == 0 else 4 - index % 5
		path.append(Vector2i(column, game.merge2248_model.height - 1 - row))
	game._merge2248_begin_at(game._merge2248_cell_center(path[0]))
	game.merge2248_drag_active = true
	for index in range(1, path.size()):
		game._merge2248_extend_at(game._merge2248_cell_center(path[index]))
	game.merge2248_pointer = game._merge2248_cell_center(path[-1]) + Vector2(34, -24)
	game.queue_redraw()


func _save(label: String) -> void:
	# Software GL may upload newly reused glyph-atlas regions one frame after a
	# time-jump redraw. Two completed frames keep the retained evidence free of
	# partial text without advancing game time (processing is disabled above).
	for _settle_frame in range(2):
		await process_frame
		await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_webp(ProjectSettings.globalize_path("%s/%s.webp" % [OUTPUT, label]), false, 0.94)


func _capture_legendary_motion() -> void:
	_prepare_chain(8)
	game._merge2248_release()
	game.merge2248_drag_active = false
	var event_start: float = game.merge2248_juice_started
	for frame_index in range(MOTION_FRAMES):
		game.elapsed = event_start + float(frame_index) / 30.0
		game.queue_redraw()
		await _save("grade_4_motion_%02d" % frame_index)


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
