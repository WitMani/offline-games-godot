extends SceneTree

const RULES = preload("res://models/mahjong_solitaire_model.gd")

var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	_test_canonical_contract()
	_test_layer_and_side_rules()
	_test_selection_and_match()
	_test_deadlock_hint_shuffle_undo()
	_test_full_clear_and_terminal_freeze()
	_test_restart_and_strict_recovery()
	_test_keyboard_focus_geometry()
	print("MAHJONG_MODEL_ASSERTIONS=%d" % assertions)
	print("MAHJONG_MODEL_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func _new_model():
	return RULES.new()


func _test_canonical_contract() -> void:
	var model = _new_model()
	_expect(model.tile_count() == 36, "canonical_tile_count")
	_expect(model.remaining_count() == 36, "canonical_remaining")
	_expect(model.pair_multiset_is_valid(), "canonical_pair_multiset")
	_expect(model.moves == 0 and model.score == 0, "canonical_counters")
	_expect(model.selected == -1 and model.hint_pair.is_empty(), "canonical_selection")
	_expect(model.status == "playing", "canonical_status")
	var ids := {}
	for tile_data in model.tiles:
		ids[int(tile_data["id"])] = true
	_expect(ids.size() == 36, "canonical_unique_ids")
	_expect(model.available_pairs().size() > 0, "canonical_available_pair")


func _test_layer_and_side_rules() -> void:
	var model = _new_model()
	# Base-row center tile 2 is both laterally enclosed and covered by a bridge.
	_expect(model.is_covered(2), "base_center_covered")
	var sides: Dictionary = model.side_blockers(2)
	_expect(bool(sides["left"]) and bool(sides["right"]), "base_center_side_blocked")
	_expect(not model.is_free(2), "base_center_not_free")
	# The top cap owns a point that overlaps lower layers.
	var cap_index := 32
	_expect(model.is_free(cap_index), "cap_free")
	_expect(model.topmost_at_logical(model.logical_center(cap_index)) == cap_index, "topmost_cap_owns_hit")
	var before := model.snapshot()
	var blocked: Dictionary = model.select_tile(2)
	_expect(blocked["kind"] == "blocked", "blocked_kind")
	_expect(model.removed == before["removed"], "blocked_removed_mutation")
	_expect(model.moves == 0 and model.score == 0 and model.selected == -1, "blocked_rule_mutation")
	_expect(model.blocked_attempts == 1, "blocked_attempt_counter")


func _test_selection_and_match() -> void:
	var model = _new_model()
	var pairs := model.available_pairs()
	var pair: Array = pairs[0]
	var first := int(pair[0])
	var second := int(pair[1])
	var selected: Dictionary = model.select_tile(first)
	_expect(selected["kind"] == "selected" and model.selected == first, "select_free")
	var deselected: Dictionary = model.select_tile(first)
	_expect(deselected["kind"] == "deselected" and model.selected == -1, "deselect_same")
	model.select_tile(first)
	var mismatch_index := -1
	for index in model.free_indices():
		if int(model.tiles[index]["face"]) != int(model.tiles[first]["face"]):
			mismatch_index = index
			break
	_expect(mismatch_index >= 0, "mismatch_fixture")
	var mismatch: Dictionary = model.select_tile(mismatch_index)
	_expect(mismatch["kind"] == "mismatch", "mismatch_kind")
	_expect(model.removed.is_empty() and model.moves == 0 and model.score == 0, "mismatch_non_removing")
	_expect(model.selected == mismatch_index and model.mistakes == 1, "mismatch_selection_policy")
	model.select_tile(mismatch_index)
	model.select_tile(first)
	var matched: Dictionary = model.select_tile(second)
	_expect(matched["kind"] == "matched", "matched_kind")
	_expect(first in model.removed and second in model.removed and model.removed.size() == 2, "matched_exact_two")
	_expect(model.moves == 1 and model.score == 50 and model.selected == -1, "matched_counters")
	var frozen := model.snapshot()
	var inert: Dictionary = model.select_tile(first)
	_expect(inert["kind"] == "inert", "removed_inert_kind")
	_expect(model.snapshot() == frozen, "removed_inert_state")


func _make_stuck(model) -> void:
	var free: Array[int] = model.free_indices()
	var pool: Array[int] = []
	for face in range(1, 19):
		pool.append(face)
		pool.append(face)
	for offset in range(free.size()):
		var face := offset + 1
		model.tiles[free[offset]]["face"] = face
		pool.erase(face)
	var rest: Array[int] = []
	for index in range(model.tiles.size()):
		if index not in free:
			rest.append(index)
	for offset in range(rest.size()):
		model.tiles[rest[offset]]["face"] = pool[offset]
	model.refresh_status_for_test()


func _test_deadlock_hint_shuffle_undo() -> void:
	var model = _new_model()
	var hint: Dictionary = model.request_hint()
	_expect(hint["kind"] == "hint" and model.hint_pair.size() == 2, "hint_pair")
	_expect(model.is_free(model.hint_pair[0]) and model.is_free(model.hint_pair[1]), "hint_free")
	_expect(int(model.tiles[model.hint_pair[0]]["face"]) == int(model.tiles[model.hint_pair[1]]["face"]), "hint_equal")
	var pair: Array[int] = model.hint_pair.duplicate()
	model.select_tile(pair[0])
	model.select_tile(pair[1])
	var undo: Dictionary = model.undo_pair()
	_expect(undo["kind"] == "undone", "undo_kind")
	_expect(model.removed.is_empty() and model.moves == 0 and model.score == 0, "undo_restores_pair")
	_expect(model.status == "playing", "undo_status")
	_make_stuck(model)
	_expect(model.pair_multiset_is_valid(), "stuck_preserves_multiset")
	_expect(model.status == "stuck" and model.available_pairs().is_empty(), "deadlock_detected")
	var frozen := model.snapshot()
	var terminal: Dictionary = model.select_tile(model.free_indices()[0])
	_expect(terminal["kind"] == "terminal_reject", "stuck_selection_frozen")
	_expect(model.snapshot() == frozen, "stuck_selection_non_mutating")
	var reshuffled: Dictionary = model.reshuffle_remaining()
	_expect(reshuffled["kind"] == "reshuffled", "reshuffle_kind")
	_expect(model.pair_multiset_is_valid(), "reshuffle_multiset")
	_expect(model.status == "playing" and not model.available_pairs().is_empty(), "reshuffle_recovers")
	_expect(model.reshuffles == 1, "reshuffle_counter")


func _test_full_clear_and_terminal_freeze() -> void:
	var model = _new_model()
	var guard := 0
	while model.status == "playing" and guard < 24:
		var pairs := model.available_pairs()
		_expect(not pairs.is_empty(), "solve_pair_%d" % guard)
		if pairs.is_empty():
			break
		model.select_tile(int(pairs[0][0]))
		model.select_tile(int(pairs[0][1]))
		guard += 1
	_expect(model.status == "won", "full_clear_won")
	_expect(model.remaining_count() == 0 and model.removed.size() == 36, "full_clear_removed")
	_expect(model.moves == 18 and model.score == 900, "full_clear_counters")
	var frozen := model.snapshot()
	var rejected: Dictionary = model.select_tile(0)
	_expect(rejected["kind"] == "terminal_reject", "won_terminal_reject")
	_expect(model.snapshot() == frozen, "won_terminal_frozen")
	_expect(model.request_hint()["kind"] == "hint_reject", "won_hint_frozen")
	_expect(model.reshuffle_remaining()["kind"] == "shuffle_reject", "won_shuffle_frozen")


func _test_restart_and_strict_recovery() -> void:
	var model = _new_model()
	var initial := model.snapshot()
	var pair: Array = model.available_pairs()[0]
	model.select_tile(pair[0])
	model.select_tile(pair[1])
	var saved := model.snapshot()
	var restored = _new_model()
	_expect(restored.restore(saved), "strict_restore_valid")
	_expect(restored.snapshot() == saved, "strict_restore_roundtrip")
	var invalid_status := saved.duplicate(true)
	invalid_status["status"] = "won"
	var before_invalid := restored.snapshot()
	_expect(not restored.restore(invalid_status), "strict_reject_status")
	_expect(restored.snapshot() == before_invalid, "strict_reject_non_mutating")
	var invalid_geometry := saved.duplicate(true)
	invalid_geometry["tiles"][0]["gx"] = 99
	_expect(not restored.restore(invalid_geometry), "strict_reject_geometry")
	var invalid_removed := saved.duplicate(true)
	invalid_removed["removed"] = [int(saved["removed"][0])]
	invalid_removed["moves"] = 0
	invalid_removed["score"] = 0
	_expect(not restored.restore(invalid_removed), "strict_reject_odd_removed")
	restored.reset()
	_expect(restored.snapshot() == initial, "restart_deterministic")


func _test_keyboard_focus_geometry() -> void:
	var model = _new_model()
	var focus := model.first_focus()
	_expect(focus >= 0 and model.is_free(focus), "first_focus_free")
	var right := model.focus_neighbor(focus, Vector2.RIGHT)
	_expect(right != focus and model.logical_center(right).x > model.logical_center(focus).x, "focus_right")
	var down := model.focus_neighbor(focus, Vector2.DOWN)
	_expect(down != focus and model.logical_center(down).y > model.logical_center(focus).y, "focus_down")
