extends SceneTree

var failures: Array[String] = []
var probes := 0


func _init() -> void:
	var model = load("res://models/meowdoku_model.gd").new()
	for fixture_id in model.fixture_ids():
		var result: Dictionary = model.load_puzzle(model.fixture(fixture_id))
		_expect(bool(result.get("ok", false)), "fixture_load_%s" % fixture_id)
		_expect(model.solution_count() == 1, "fixture_unique_%s" % fixture_id)
		_expect(model.is_complete() == (model.given_cats.size() == model.size), "fixture_initial_incomplete_%s" % fixture_id)

	_expect(model.load_puzzle(model.fixture("notebook_5")).ok, "load_primary")
	_expect(model.move_selection(Vector2i.RIGHT) and model.selected == Vector2i.ZERO, "first_keyboard_move_selects_origin")
	_expect(model.move_selection(Vector2i.RIGHT) and model.selected == Vector2i.RIGHT, "next_keyboard_move_advances")
	model.restart()
	var stable_id: String = model.puzzle_id
	var malformed: Dictionary = model.fixture("notebook_5")
	malformed.regions[0] = [0, 1]
	_expect(not model.load_puzzle(malformed).ok, "reject_non_square")
	_expect(model.puzzle_id == stable_id, "invalid_load_atomic")
	var disconnected: Dictionary = model.fixture("notebook_5")
	disconnected.regions[0][0] = 0
	_expect(not model.load_puzzle(disconnected).ok, "reject_disconnected_or_count")
	var diagonal: Dictionary = model.fixture("notebook_5")
	diagonal.solution = [Vector2i(0, 0), Vector2i(1, 1), Vector2i(4, 2), Vector2i(2, 3), Vector2i(3, 4)]
	_expect(not model.load_puzzle(diagonal).ok, "reject_diagonal_solution")
	var wrong_given: Dictionary = model.fixture("notebook_5")
	wrong_given.given_cats = [Vector2i(0, 0)]
	_expect(not model.load_puzzle(wrong_given).ok, "reject_wrong_given")

	model.load_puzzle(model.fixture("notebook_5"))
	var first: Vector2i = model.solution[0]
	_expect(model.select(first), "select")
	var mark_result: Dictionary = model.toggle_mark()
	_expect(mark_result.event == "mark" and first in model.manual_marks, "mark_selected")
	var cat_result: Dictionary = model.attempt_cat(first)
	_expect(cat_result.event == "cat" and first in model.cats and first not in model.manual_marks, "correct_cat")
	_expect(model.is_derived_excluded(Vector2i(0, first.y)), "derived_row_exclusion")
	_expect(model.is_derived_excluded(Vector2i(first.x - 1, first.y + 1)), "derived_diagonal_exclusion")
	_expect(model.erase(first).event == "erase_cat" and first not in model.cats, "erase_cat")

	var wrong := Vector2i(0, 0)
	if wrong in model.solution:
		wrong = Vector2i(1, 0)
	model.toggle_mark(wrong)
	var before_cats: Array = model.cats.duplicate()
	var before_marks: Array = model.manual_marks.duplicate()
	var before_moves: int = model.moves
	for expected_hearts in [2, 1, 0]:
		var error_result: Dictionary = model.attempt_cat(wrong)
		_expect(model.hearts == expected_hearts and model.cats == before_cats and model.manual_marks == before_marks and model.moves == before_moves, "wrong_cat_atomic_%d" % expected_hearts)
		_expect(error_result.event == ("loss" if expected_hearts == 0 else "error"), "wrong_cat_event_%d" % expected_hearts)
	_expect(model.status == model.LOST, "third_error_loses")
	_expect(not model.toggle_mark(Vector2i(2, 2)).changed, "loss_locks_mutation")
	_expect(model.restart().changed and model.status == model.PLAYING and model.hearts == 3, "restart_after_loss")
	_expect(model.cats.is_empty() and model.manual_marks.is_empty(), "restart_primary_state")

	model.load_puzzle(model.fixture("patchwork_7"))
	var given: Vector2i = model.given_cats[0]
	_expect(model.erase(given).event == "given", "given_erase_blocked")
	_expect(model.toggle_mark(given).event == "given", "given_mark_blocked")
	_expect(model.attempt_cat(given).event == "given" and model.hearts == 3, "given_cat_safe")
	var restore_cat: Vector2i = model.solution[1]
	model.attempt_cat(restore_cat)
	model.toggle_mark(Vector2i(1, 0))
	model.select(Vector2i(2, 2))
	var saved: Dictionary = model.checkpoint()
	model.restart()
	_expect(model.restore_checkpoint(saved).ok, "checkpoint_restore")
	_expect(restore_cat in model.cats and Vector2i(1, 0) in model.manual_marks and model.selected == Vector2i(2, 2), "checkpoint_roundtrip")
	var before_bad: Dictionary = model.checkpoint()
	var bad: Dictionary = saved.duplicate(true)
	bad.puzzle_id = "another_puzzle"
	_expect(not model.restore_checkpoint(bad).ok, "checkpoint_identity_reject")
	_expect(model.checkpoint() == before_bad, "checkpoint_reject_atomic")
	bad = saved.duplicate(true)
	bad.cats.append([6, 6])
	_expect(not model.restore_checkpoint(bad).ok, "checkpoint_wrong_cat_reject")

	model.load_puzzle(model.fixture("notebook_5"))
	for cell in model.solution:
		var outcome: Dictionary = model.attempt_cat(cell)
		_expect(bool(outcome.get("correct", false)), "completion_cat_%d_%d" % [cell.x, cell.y])
	_expect(model.status == model.WON and model.is_complete(), "completion_status")
	var won_snapshot: Dictionary = model.checkpoint()
	_expect(not model.attempt_cat(Vector2i.ZERO).changed, "win_locks_mutation")
	_expect(model.checkpoint() == won_snapshot, "win_lock_atomic")

	print("MEOWDOKU_MODEL_SMOKE=%d" % probes)
	print("MEOWDOKU_MODEL_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, label: String) -> void:
	probes += 1
	if not condition:
		failures.append(label)
