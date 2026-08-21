extends SceneTree

const MODEL = preload("res://models/merge2248_model.gd")

var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	_test_modes_and_seed()
	_test_path_and_release()
	_test_endless_2048_boundary()
	_test_long_number_domain()
	_test_power_and_formatter_matrix()
	_test_undo_and_rng()
	_test_versioned_restore()
	_test_terminal_compatibility_boundary()
	print("MERGE2248_MODEL_SMOKE=%d" % assertions)
	print("MERGE2248_MODEL_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _test_modes_and_seed() -> void:
	var easy = MODEL.new()
	easy.reset(2248, MODEL.MODE_EASY, false)
	_expect(easy.width == 5 and easy.height == 8, "easy_dimensions")
	_expect(easy.mode == MODEL.MODE_EASY and easy.is_mode_evidence_verified(), "easy_verified")
	_expect(easy.board.size() == 8 and easy.board[0].size() == 5, "easy_board_shape")
	_expect(easy.has_moves(), "opening_pair_guaranteed")
	for row in easy.board:
		for power in row:
			_expect(int(power) >= 1 and int(power) <= 4, "opening_power_range")

	var duplicate = MODEL.new()
	duplicate.reset(2248, 8, false)
	_expect(duplicate.board == easy.board, "seed_deterministic")
	var hard = MODEL.new()
	hard.reset(99, MODEL.MODE_HARD, false)
	_expect(hard.height == 6 and hard.mode == MODEL.MODE_HARD, "hard_dimensions")
	_expect(hard.is_mode_evidence_verified(), "hard_verified")
	var medium = MODEL.new()
	medium.reset(99, 7, false)
	_expect(medium.height == 7 and medium.mode == MODEL.MODE_MEDIUM_COMPAT, "medium_compat_mapping")
	_expect(not medium.is_mode_evidence_verified(), "medium_not_overclaimed")
	var extra = MODEL.new()
	extra.reset(99, 5, false)
	_expect(extra.height == 5 and extra.mode == MODEL.MODE_EXTRA_HARD_COMPAT, "extra_compat_mapping")
	_expect(not extra.is_mode_evidence_verified(), "extra_not_overclaimed")


func _test_path_and_release() -> void:
	var model = MODEL.new()
	model.reset(2248, MODEL.MODE_EASY, false)
	model.board = _fixture_board(8)
	_expect(model.begin(Vector2i(0, 7)), "begin")
	_expect(not model.extend(Vector2i(1, 6)), "first_pair_must_match")
	_expect(model.extend(Vector2i(1, 7)), "same_value_pair")
	_expect(not model.extend(Vector2i(0, 7)), "repeat_rejected_compat")
	_expect(model.extend(Vector2i(2, 6)), "double_value_diagonal")
	_expect(model.extend(Vector2i(3, 6)), "same_value_after_double")
	_expect(not model.extend(Vector2i(4, 6)), "reject_non_same_or_double")
	_expect(not model.extend(Vector2i(4, 4)), "reject_non_adjacent")
	_expect(model.preview_power() == 4, "preview_power_exponent")
	_expect(model.preview_result() == 16 and model.preview_label() == "16", "preview_public_value")
	var outcome: Dictionary = model.release()
	_expect(bool(outcome.changed), "release_changed")
	_expect(str(outcome.gained) == "12" and str(outcome.gained_label) == "12", "gained_exact")
	_expect(int(outcome.result_power) == 4 and int(outcome.result) == 16 and str(outcome.result_label) == "16", "merge_result")
	_expect(str(model.score) == "12" and model.moves == 1, "score_and_moves")
	_expect(str(model.all_time) == "12", "all_time_tracks_score")
	_expect(model.can_undo(), "undo_armed_after_legal_release")
	_expect(model.selected.is_empty(), "selection_consumed")
	_expect(model.release() == model._unchanged_outcome(), "empty_release_inert")


func _test_endless_2048_boundary() -> void:
	var model = MODEL.new()
	model.reset(7, MODEL.MODE_EASY, false)
	model.board = _unique_board(8)
	model.board[7][0] = 10 # 1024
	model.board[7][1] = 10 # 1024
	_expect(model.begin(Vector2i(0, 7)) and model.extend(Vector2i(1, 7)), "2048_pair_selected")
	var outcome: Dictionary = model.release()
	_expect(int(outcome.result_power) == 11 and int(outcome.result) == 2048, "2048_created")
	_expect(model.status == MODEL.RUNNING, "2048_is_not_terminal")
	_expect(not model.snapshot().has("won"), "no_false_win_payload")


func _test_long_number_domain() -> void:
	var model = MODEL.new()
	model.reset(71, MODEL.MODE_EASY, false)
	model.board = _unique_board(8)
	model.board[7][0] = 70
	model.board[7][1] = 70
	_expect(model.begin(Vector2i(0, 7)) and model.extend(Vector2i(1, 7)), "large_pair_selected")
	var outcome: Dictionary = model.release()
	_expect(int(outcome.result_power) == 71, "large_result_power")
	_expect(int(outcome.result) == 0, "large_value_never_overflows_int_boundary")
	_expect(str(outcome.result_label).contains("Z"), "large_tile_target_style_suffix")
	_expect(str(model.score) == "2361183241434822606848", "large_score_exact_decimal")
	_expect(str(model.all_time) == str(model.score), "large_best_exact_decimal")
	_expect(str(model.snapshot().score_label) == "2,361E", "large_score_target_style_label")
	_expect(model.power_value_or_zero(62) > 0 and model.power_value_or_zero(63) == 0, "safe_int_boundary")
	_expect(model.power_label(5000) == "2^5000", "extreme_power_symbolic_fallback")


func _test_power_and_formatter_matrix() -> void:
	var model = MODEL.new()
	for base_power in range(1, 21):
		for chain_length in range(2, 41):
			var powers: Array[int] = []
			for _cell in range(chain_length):
				powers.append(base_power)
			var expected_extra := 0
			var capacity := 1
			while capacity < chain_length:
				capacity <<= 1
				expected_extra += 1
			_expect(model._result_power(powers) == base_power + expected_extra, "equal_chain_%d_%d" % [base_power, chain_length])
	_expect(model._power_decimal(100) == "1267650600228229401496703205376", "power_100_exact")
	_expect(model.format_score("224575000000000000000") == "224,575P", "target_style_p_score")
	_expect(model.format_score("156600000000000000") == "156,600T", "target_style_t_score")
	_expect(model.format_score("999999") == "999,999", "comma_score")


func _test_undo_and_rng() -> void:
	var model = MODEL.new()
	model.reset(3001, MODEL.MODE_HARD, false)
	model.board = _fixture_board(6)
	var before := model.serialize()
	_expect(model.begin(Vector2i(0, 5)), "undo_begin")
	_expect(model.extend(Vector2i(1, 5)), "undo_extend")
	var first: Dictionary = model.release()
	var after_board: Array = model.board.duplicate(true)
	var after_score: String = str(model.score)
	var retained_best: String = str(model.all_time)
	_expect(model.undo(), "undo_success")
	_expect(model.board == before.core.board, "undo_board_exact")
	_expect(str(model.score) == "0" and model.moves == 0 and model.status == MODEL.RUNNING, "undo_core_exact")
	_expect(str(model.all_time) == str(retained_best), "undo_preserves_all_time")
	_expect(not model.can_undo() and not model.undo(), "undo_one_level_bounded")
	_expect(model.begin(Vector2i(0, 5)) and model.extend(Vector2i(1, 5)), "replay_selection")
	var replay: Dictionary = model.release()
	_expect(model.board == after_board, "undo_rng_replay_board")
	_expect(str(model.score) == str(after_score), "undo_rng_replay_score")
	_expect(str(first.gained) == str(replay.gained) and int(first.result_power) == int(replay.result_power), "undo_rng_replay_outcome")
	model.reset(1, MODEL.MODE_EASY, true)
	_expect(str(model.score) == "0" and str(model.all_time) == str(retained_best), "restart_preserves_all_time")
	_expect(not model.can_undo(), "restart_clears_undo")


func _test_versioned_restore() -> void:
	var source = MODEL.new()
	source.reset(811, MODEL.MODE_HARD, false)
	source.board = _fixture_board(6)
	_expect(source.begin(Vector2i(0, 5)) and source.extend(Vector2i(1, 5)), "save_move_selection")
	source.release()
	var payload := source.serialize()
	var restored = MODEL.new()
	_expect(restored.restore(payload), "restore_valid")
	_expect(restored.serialize() == payload, "restore_round_trip_exact")
	_expect(restored.snapshot().board_encoding == "power_of_two_exponents", "snapshot_encoding_explicit")
	_expect(restored.snapshot().board_labels.size() == 6, "snapshot_labels_shape")
	_expect(restored.can_undo(), "undo_persisted")

	var wrong_version := payload.duplicate(true)
	wrong_version.version = 3
	_expect(not MODEL.new().restore(wrong_version), "reject_wrong_version")
	var bad_shape := payload.duplicate(true)
	bad_shape.core.board.pop_back()
	_expect(not MODEL.new().restore(bad_shape), "reject_bad_shape")
	var bad_power := payload.duplicate(true)
	bad_power.core.board[0][0] = 0
	_expect(not MODEL.new().restore(bad_power), "reject_bad_power")
	var bad_bits := payload.duplicate(true)
	bad_bits.best_bits = [0, 2]
	_expect(not MODEL.new().restore(bad_bits), "reject_bad_score_bits")
	var bad_seed := payload.duplicate(true)
	bad_seed.core.rng_seed = "not-an-integer"
	_expect(not MODEL.new().restore(bad_seed), "reject_bad_rng_seed")
	var bad_state := payload.duplicate(true)
	bad_state.core.rng_state = "1.5"
	_expect(not MODEL.new().restore(bad_state), "reject_bad_rng_state")


func _test_terminal_compatibility_boundary() -> void:
	var model = MODEL.new()
	model.reset(1, MODEL.MODE_EASY, false)
	model.board = _unique_board(8)
	_expect(not model.has_moves(), "no_pair_detection")
	_expect(model.status == MODEL.RUNNING, "inspection_does_not_mutate_terminal_state")
	var snap := model.snapshot()
	_expect(bool(snap.mode_evidence_verified), "verified_mode_flag_boolean")
	_expect(int(snap.highest_power) == 40, "highest_power_snapshot")
	_expect(str(snap.highest_label) == model.power_label(40), "highest_label_snapshot")


func _fixture_board(rows: int) -> Array:
	var fixture := _unique_board(rows)
	fixture[rows - 1][0] = 1
	fixture[rows - 1][1] = 1
	fixture[rows - 2][1] = 2
	fixture[rows - 2][2] = 2
	fixture[rows - 2][3] = 2
	fixture[rows - 2][4] = 4
	return fixture


func _unique_board(rows: int) -> Array:
	var fixture: Array = []
	for y in range(rows):
		var row: Array[int] = []
		for x in range(5):
			row.append(y * 5 + x + 1)
		fixture.append(row)
	return fixture


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
