extends SceneTree

var failures: Array[String] = []
var assertions := 0
var Model = preload("res://models/merge2048_model.gd")


func _init() -> void:
	_test_opening_and_randomness()
	_test_ordered_line_merges()
	_test_four_direction_traversal()
	_test_directional_move_and_spawn()
	_test_invalid_move_is_inert()
	_test_score_best_and_restart()
	_test_win_pause_and_continue()
	_test_loss_detection()
	_test_snapshot_restore()
	print("MERGE2048_MODEL_ASSERTIONS=%d" % assertions)
	print("MERGE2048_MODEL_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _test_opening_and_randomness() -> void:
	var four_count := 0
	var spawn_count := 0
	for seed_value in range(1, 1001):
		var model = Model.new()
		model.reset(seed_value)
		var occupied := 0
		for row in model.board:
			for value in row:
				if int(value) > 0:
					occupied += 1
					spawn_count += 1
					four_count += 1 if int(value) == 4 else 0
					_expect(int(value) in [2, 4], "opening_value_%d" % seed_value)
		_expect(occupied == 2, "opening_count_%d" % seed_value)
	var four_ratio := float(four_count) / float(spawn_count)
	_expect(four_ratio >= 0.075 and four_ratio <= 0.125, "spawn_ratio_%.4f" % four_ratio)
	var first = Model.new()
	var second = Model.new()
	first.reset(987654)
	second.reset(987654)
	_expect(first.snapshot() == second.snapshot(), "deterministic_seed")


func _test_ordered_line_merges() -> void:
	var model = Model.new()
	for sample in [
		{"input":[2, 2, 2, 2], "output":[4, 4, 0, 0], "score":8},
		{"input":[2, 2, 4, 4], "output":[4, 8, 0, 0], "score":12},
		{"input":[4, 4, 4, 0], "output":[8, 4, 0, 0], "score":8},
		{"input":[2, 0, 2, 2], "output":[4, 2, 0, 0], "score":4},
		{"input":[2, 4, 8, 16], "output":[2, 4, 8, 16], "score":0},
	]:
		var resolved: Dictionary = model.resolve_line(sample.input)
		_expect(resolved.line == sample.output, "line_%s" % str(sample.input))
		_expect(int(resolved.gained) == int(sample.score), "line_score_%s" % str(sample.input))
	var paired: Dictionary = model.resolve_line([2, 2, 2, 2])
	_expect(paired.merges.size() == 2, "line_merge_metadata_count")
	_expect(int(paired.merges[0].to_index) == 0 and int(paired.merges[1].to_index) == 1, "line_merge_destinations")
	_expect(int(paired.merges[0].source_value) == 2 and int(paired.merges[0].result_value) == 4, "line_merge_values")
	_expect(paired.merges[0].source_indices == [0, 1] and paired.merges[1].source_indices == [2, 3], "line_merge_sources")


func _test_directional_move_and_spawn() -> void:
	var model = Model.new()
	model.reset(77)
	model.load_fixture([
		[2, 0, 2, 2],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var outcome: Dictionary = model.move(Vector2i.LEFT)
	_expect(bool(outcome.changed), "move_changed")
	_expect(outcome.board_after_slide[0] == [4, 2, 0, 0], "move_after_slide")
	_expect(int(outcome.gained) == 4 and model.score == 4 and model.moves == 1, "move_score_count")
	_expect(outcome.moves.size() == 3, "move_metadata_count")
	_expect(outcome.merges.size() == 1, "move_merge_metadata_count")
	if outcome.merges.size() == 1:
		_expect(outcome.merges[0].to == Vector2i(0, 0), "move_merge_destination")
		_expect(outcome.merges[0].sources == [Vector2i(0, 0), Vector2i(2, 0)], "move_merge_sources")
		_expect(int(outcome.merges[0].result_value) == 4, "move_merge_value")
	var spawned: Dictionary = outcome.spawn
	_expect(not spawned.is_empty() and int(spawned.value) in [2, 4], "move_spawn_payload")
	_expect(_occupied(outcome.board_after) == _occupied(outcome.board_after_slide) + 1, "move_exactly_one_spawn")
	_expect(model.board == outcome.board_after, "move_authoritative_board")

	model.load_fixture([
		[2, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	var right: Dictionary = model.move(Vector2i.RIGHT)
	_expect(right.moves.size() == 1, "right_motion_count")
	if right.moves.size() == 1:
		_expect(right.moves[0].from == Vector2i(0, 0), "right_motion_from")
		_expect(right.moves[0].to == Vector2i(3, 0), "right_motion_to")


func _test_four_direction_traversal() -> void:
	for sample in [
		{"direction":Vector2i.LEFT, "expected":[4, 8, 0, 0]},
		{"direction":Vector2i.RIGHT, "expected":[0, 0, 4, 8]},
	]:
		var model = Model.new()
		model.reset(100 + int(sample.direction.x))
		model.load_fixture([[2, 2, 4, 4], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
		var outcome: Dictionary = model.move(sample.direction)
		_expect(outcome.board_after_slide[0] == sample.expected, "horizontal_%s" % sample.direction)
		_expect(int(outcome.gained) == 12, "horizontal_score_%s" % sample.direction)
	for sample in [
		{"direction":Vector2i.UP, "expected":[4, 8, 0, 0]},
		{"direction":Vector2i.DOWN, "expected":[0, 0, 4, 8]},
	]:
		var model = Model.new()
		model.reset(200 + int(sample.direction.y))
		model.load_fixture([[2, 0, 0, 0], [2, 0, 0, 0], [4, 0, 0, 0], [4, 0, 0, 0]])
		var outcome: Dictionary = model.move(sample.direction)
		var column: Array = []
		for row in outcome.board_after_slide:
			column.append(int(row[0]))
		_expect(column == sample.expected, "vertical_%s" % sample.direction)
		_expect(int(outcome.gained) == 12, "vertical_score_%s" % sample.direction)


func _test_invalid_move_is_inert() -> void:
	var model = Model.new()
	model.reset(31337)
	model.load_fixture([
		[2, 4, 8, 16],
		[32, 64, 128, 256],
		[4, 8, 16, 32],
		[64, 128, 256, 512],
	], 128, 7, false, false, false, 512)
	var before := model.snapshot()
	var outcome: Dictionary = model.move(Vector2i.LEFT)
	_expect(not bool(outcome.changed), "invalid_changed")
	_expect(model.snapshot() == before, "invalid_mutated_model")
	_expect(outcome.spawn.is_empty(), "invalid_spawned")
	_expect(outcome.merges.is_empty(), "invalid_merge_metadata")
	var diagonal: Dictionary = model.move(Vector2i(1, 1))
	_expect(not bool(diagonal.changed) and model.snapshot() == before, "invalid_direction")


func _test_score_best_and_restart() -> void:
	var model = Model.new()
	model.reset(91, 24)
	model.load_fixture([
		[4, 4, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	], 20, 3, false, false, false, 24)
	model.move(Vector2i.LEFT)
	_expect(model.score == 28 and model.best == 28, "score_updates_best")
	model.reset(92, model.best)
	_expect(model.score == 0 and model.moves == 0 and model.best == 28, "restart_preserves_best")
	_expect(_occupied(model.board) == 2, "restart_two_tiles")


func _test_win_pause_and_continue() -> void:
	var model = Model.new()
	model.reset(2048)
	model.load_fixture([
		[1024, 1024, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	], 1000, 20, false, false, false, 1000)
	var win: Dictionary = model.move(Vector2i.LEFT)
	_expect(bool(win.won_now) and model.won, "win_flag")
	_expect(model.status() == Model.WON and model.is_terminated(), "win_pauses")
	var paused := model.snapshot()
	var rejected: Dictionary = model.move(Vector2i.RIGHT)
	_expect(not bool(rejected.changed) and model.snapshot() == paused, "win_blocks_move")
	_expect(model.continue_after_win(), "continue_accept")
	_expect(model.status() == Model.PLAYING and not model.is_terminated(), "continue_resumes")
	var continued: Dictionary = model.move(Vector2i.RIGHT)
	_expect(bool(continued.changed), "continued_move")

	model.load_fixture([
		[2048, 2048, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	], 4000, 30, true, true, false, 4000)
	var beyond: Dictionary = model.move(Vector2i.LEFT)
	_expect(bool(beyond.changed) and int(beyond.board_after_slide[0][0]) == 4096, "beyond_2048_merge")
	_expect(model.status() == Model.PLAYING and model.keep_playing, "beyond_2048_playing")


func _test_loss_detection() -> void:
	var model = Model.new()
	model.reset(616)
	model.load_fixture([
		[0, 8, 16, 32],
		[4, 2, 4, 64],
		[2, 4, 8, 16],
		[4, 2, 4, 8],
	])
	var loss: Dictionary = model.move(Vector2i.LEFT)
	_expect(bool(loss.changed) and bool(loss.over_now), "loss_on_final_spawn")
	_expect(model.over and model.status() == Model.OVER and not model.has_moves(), "loss_status")
	var terminal := model.snapshot()
	_expect(not bool(model.move(Vector2i.RIGHT).changed) and model.snapshot() == terminal, "loss_freezes_input")

	model.load_fixture([
		[2, 4, 8, 16],
		[32, 64, 128, 256],
		[4, 8, 16, 32],
		[64, 128, 256, 256],
	])
	_expect(model.has_moves(), "adjacent_pair_available")


func _test_snapshot_restore() -> void:
	var source = Model.new()
	source.reset(444, 32)
	source.move(Vector2i.LEFT)
	var saved := source.snapshot()
	var restored = Model.new()
	_expect(restored.restore(saved), "restore_accept")
	_expect(restored.snapshot() == saved, "restore_exact")
	var source_move: Dictionary = source.move(Vector2i.DOWN)
	var restored_move: Dictionary = restored.move(Vector2i.DOWN)
	_expect(source_move == restored_move, "restore_rng_continuity")
	var malformed := saved.duplicate(true)
	malformed.board = [[3]]
	_expect(not restored.restore(malformed), "restore_reject_board")


func _occupied(candidate_board: Array) -> int:
	var count := 0
	for row in candidate_board:
		for value in row:
			count += 1 if int(value) > 0 else 0
	return count


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
