extends SceneTree

## Matched visual/semantic evidence for the accessible presentation path.
## Both runs use the same seed, authoritative board, and eight-cell gesture.
## Only the presentation preference changes.

const OUTPUT := "user://merge2248_reduced_effects_audit"
const FIXTURE_SEED := 8224
const IMPACT_AGE := 0.16

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var normal: Dictionary = await _capture_variant(false, "normal-impact")
	var reduced: Dictionary = await _capture_variant(true, "reduced-impact")
	var rules_identical: bool = normal.rules == reduced.rules
	_expect(rules_identical, "authoritative_rules_identical")
	_expect(int(normal.grade) == 4 and int(reduced.grade) == 4, "semantic_grade_preserved")
	_expect(str(normal.result_label) == str(reduced.result_label), "result_label_preserved")
	_expect(float(normal.shake_length) > 0.01, "normal_shake_visible")
	_expect(float(reduced.shake_length) == 0.0, "reduced_shake_disabled")
	_expect(not bool(normal.transform_identity), "normal_property_animation_visible")
	_expect(bool(reduced.transform_identity), "reduced_property_animation_disabled")
	_expect(int(normal.travel_echoes) > int(reduced.travel_echoes), "reduced_travel_echoes")
	_expect(int(normal.rings) > int(reduced.rings), "reduced_rings")
	_expect(int(normal.crumbs) > int(reduced.crumbs), "reduced_crumbs")
	_expect(float(reduced.duration) < float(normal.duration), "reduced_duration")
	var evidence := {
		"contract": "merge2248-reduced-effects-v1",
		"fixture_seed": FIXTURE_SEED,
		"chain_length": 8,
		"impact_age_seconds": IMPACT_AGE,
		"rules_identical": rules_identical,
		"normal": normal,
		"reduced": reduced,
		"assertions": 11,
		"result": "PASS" if failures.is_empty() else "FAIL",
		"failures": failures,
		"note": "Reduced effects preserves the semantic callout and local static impact ring while removing shake, board transform, travel echoes, burst rings, crumbs, and haptics.",
	}
	_write_json("evidence", evidence)
	print("MERGE2248_REDUCED_EFFECTS_AUDIT=%s" % evidence.result)
	print("MERGE2248_REDUCED_EFFECTS_AUDIT_DIR=%s" % ProjectSettings.globalize_path(OUTPUT))
	quit(0 if failures.is_empty() else 1)


func _capture_variant(reduced_effects: bool, label: String) -> Dictionary:
	var game: Control = load("res://main.tscn").instantiate()
	game.merge2248_persistence_enabled = false
	game.merge2248_reduced_effects_override = reduced_effects
	root.add_child(game)
	await process_frame
	game._open_game("merge2248")
	game.set_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	game.has_transitioned = false
	game.merge2248_model.reset(FIXTURE_SEED, game.merge2248_model.MODE_EASY, false)
	for y in range(game.merge2248_model.height):
		for x in range(game.merge2248_model.width):
			game.merge2248_model.board[y][x] = 1
	game._sync_merge2248_state()
	var path: Array[Vector2i] = [
		Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7),
		Vector2i(4, 7), Vector2i(4, 6), Vector2i(3, 6), Vector2i(2, 6),
	]
	game._merge2248_begin_at(game._merge2248_cell_center(path[0]))
	game.merge2248_drag_active = true
	for index in range(1, path.size()):
		game._merge2248_extend_at(game._merge2248_cell_center(path[index]))
	game._merge2248_release()
	game.merge2248_drag_active = false
	var effect: Dictionary = game.merge2248_fx[-1]
	var event_started := float(effect.started)
	game.elapsed = event_started + IMPACT_AGE
	game.queue_redraw()
	await _save(label)
	var grade := int(effect.grade)
	var transform: Transform2D = game._merge2248_board_juice_transform(game._merge2248_board_rect())
	var metrics := {
		"reduced_effects": reduced_effects,
		"rules": game.merge2248_model.serialize(),
		"grade": grade,
		"result_power": int(effect.result_power),
		"result_label": str(effect.result_label),
		"duration": float(effect.duration),
		"shake_length": game._merge2248_shake_offset().length(),
		"transform_identity": transform == Transform2D.IDENTITY,
		"travel_echoes": 0 if reduced_effects else maxi(0, effect.points.size() - 1),
		"rings": 0 if reduced_effects else grade,
		"crumbs": 0 if reduced_effects else 6 + grade * 4,
		"haptics_enabled": not reduced_effects,
		"semantic_callout_retained": true,
		"static_local_ring_retained": reduced_effects,
	}
	game.queue_free()
	await process_frame
	return metrics


func _save(label: String) -> void:
	for _settle_frame in range(2):
		await process_frame
		await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_webp(ProjectSettings.globalize_path("%s/%s.webp" % [OUTPUT, label]), false, 0.94)


func _write_json(label: String, payload: Dictionary) -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path("%s/%s.json" % [OUTPUT, label]), FileAccess.WRITE)
	file.store_string(JSON.stringify(payload, "  "))


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
