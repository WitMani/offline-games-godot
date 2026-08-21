extends SceneTree

## Renderer-free probes for the documented local TriPeaks v3 contract.
## Passing these cases does not establish hidden target-package parity.

const MODEL_PATH := "res://models/tripeaks_model.gd"
const TEST_SEED := 20260820
const EXPECTED_CASES := 13

var failures: Array[String] = []
var cases_run := 0
var model_script: Script


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	model_script = load(MODEL_PATH)
	if model_script == null or not model_script.can_instantiate():
		failures.append("model_script_not_instantiable")
		_finish()
		return
	_test_full_deck_identity_and_partition()
	_test_seeded_deal_is_deterministic()
	_test_three_peak_blocker_topology_and_entry_exposure()
	_test_stock_to_waste_uses_real_card_and_resets_streak()
	_test_rank_adjacency_and_explicit_wrap_option()
	_test_locked_click_is_atomic()
	_test_rank_removed_and_range_rejects_are_atomic()
	_test_clear_reveals_dependents_and_scores_once()
	_test_peak_milestone_and_win_freeze()
	_test_no_move_loss_and_terminal_freeze()
	_test_restart_replays_exact_deal()
	_test_json_recovery_continues_deterministically()
	_test_corrupt_recovery_rejects_atomically()
	_finish()


func _fresh(wrap_enabled: bool = true):
	var model = model_script.new()
	model.reset(TEST_SEED, wrap_enabled)
	return model


func _finish() -> void:
	if cases_run != EXPECTED_CASES:
		failures.append("case_count_%d_of_%d" % [cases_run, EXPECTED_CASES])
	print("TRIPEAKS_V3_CONTRACT_CASES=%d" % cases_run)
	print("TRIPEAKS_V3_CONTRACT_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _record(name: String, passed: bool, evidence: String = "") -> void:
	cases_run += 1
	if not passed:
		failures.append(name + ("=" + evidence if not evidence.is_empty() else ""))


func _cid(rank: int, suit: int = 0) -> int:
	return suit * 13 + rank - 1


func _state_json(model) -> String:
	return JSON.stringify(model.snapshot())


func _all_live_cards(saved: Dictionary) -> Array:
	var cards: Array = []
	for value in saved["tableau"]:
		if int(value) >= 0:
			cards.append(int(value))
	cards.append_array(saved["stock"])
	cards.append_array(saved["waste"])
	return cards


func _fixture(model, active_slots: Dictionary, waste_top: int, stock_cards: Array = [], wrap_enabled: bool = true, fixture_streak: int = 0) -> bool:
	var used := {}
	var tableau: Array = []
	for slot in range(28):
		var card := int(active_slots.get(slot, -1))
		if card >= 0:
			if card >= 52 or used.has(card):
				return false
			used[card] = true
		tableau.append(card)
	if waste_top < 0 or waste_top >= 52 or used.has(waste_top):
		return false
	used[waste_top] = true
	var stock: Array = []
	for value in stock_cards:
		var card := int(value)
		if card < 0 or card >= 52 or used.has(card):
			return false
		used[card] = true
		stock.append(card)
	if stock.size() > 23:
		return false
	var waste: Array = []
	for card in range(52):
		if not used.has(card):
			waste.append(card)
	waste.append(waste_top)
	var removed: Array = []
	for slot in range(28):
		if int(tableau[slot]) < 0:
			removed.append(slot)
	var saved: Dictionary = model.snapshot()
	saved["wrap_ace_king"] = wrap_enabled
	saved["tableau"] = tableau
	saved["removed"] = removed
	saved["stock"] = stock
	saved["waste"] = waste
	saved["score"] = removed.size() * 30
	saved["moves"] = waste.size() - 1
	saved["streak"] = fixture_streak
	saved["status"] = "playing"
	saved["remaining"] = active_slots.size()
	return model.restore(saved)


func _test_full_deck_identity_and_partition() -> void:
	var model = _fresh()
	var saved: Dictionary = model.snapshot()
	var cards := _all_live_cards(saved)
	var unique := {}
	for card in cards:
		unique[int(card)] = true
	var identities_ok := true
	for card in range(52):
		identities_ok = identities_ok and model.card_id(model.card_rank(card), model.card_suit(card)) == card
	_record(
		"decision_full_52_card_identity",
		saved["tableau"].size() == 28 and saved["stock"].size() == 23 and saved["waste"].size() == 1 and cards.size() == 52 and unique.size() == 52 and identities_ok,
		JSON.stringify({"tableau":saved["tableau"].size(), "stock":saved["stock"].size(), "waste":saved["waste"].size(), "unique":unique.size()}),
	)


func _test_seeded_deal_is_deterministic() -> void:
	var first = _fresh()
	var second = _fresh()
	var third = model_script.new()
	third.reset(TEST_SEED + 1, true)
	_record("decision_seeded_deal", _state_json(first) == _state_json(second) and _state_json(first) != _state_json(third))


func _test_three_peak_blocker_topology_and_entry_exposure() -> void:
	var model = _fresh()
	var blockers_ok: bool = (
		model.BLOCKERS.size() == 28
		and model.BLOCKERS[0] == [3, 4]
		and model.BLOCKERS[1] == [5, 6]
		and model.BLOCKERS[2] == [7, 8]
		and model.BLOCKERS[9] == [18, 19]
		and model.BLOCKERS[17] == [26, 27]
	)
	_record("decision_three_peak_topology", blockers_ok and model.exposed_slots() == range(18, 28), JSON.stringify(model.exposed_slots()))


func _test_stock_to_waste_uses_real_card_and_resets_streak() -> void:
	var model = _fresh()
	var before: Dictionary = model.snapshot()
	var expected := int(before["stock"].back())
	model.streak = 4
	var event: Dictionary = model.draw_stock()
	var after: Dictionary = model.snapshot()
	var cards := _all_live_cards(after)
	var unique := {}
	for card in cards:
		unique[int(card)] = true
	_record(
		"decision_real_stock_draw",
		str(event["kind"]) == "draw" and int(event["card"]) == expected and int(after["waste"].back()) == expected and after["stock"].size() == 22 and int(after["streak"]) == 0 and cards.size() == 52 and unique.size() == 52,
		JSON.stringify(event),
	)


func _test_rank_adjacency_and_explicit_wrap_option() -> void:
	var wrapped = _fresh(true)
	var strict = _fresh(false)
	var passed: bool = (
		wrapped.ranks_are_adjacent(5, 6)
		and wrapped.ranks_are_adjacent(6, 5)
		and not wrapped.ranks_are_adjacent(5, 7)
		and wrapped.ranks_are_adjacent(1, 13)
		and wrapped.ranks_are_adjacent(13, 1)
		and not strict.ranks_are_adjacent(1, 13)
	)
	_record("decision_adjacency_wrap_option", passed)


func _test_locked_click_is_atomic() -> void:
	var model = _fresh()
	var loaded := _fixture(model, {0:_cid(12, 3), 3:_cid(11, 2), 9:_cid(6, 1), 18:_cid(9, 0)}, _cid(5, 2), [_cid(2, 3)])
	var before := _state_json(model)
	var event: Dictionary = model.clear_tableau(9)
	_record("decision_locked_reject_atomic", loaded and str(event.get("reason", "")) == "locked" and _state_json(model) == before, JSON.stringify(event))


func _test_rank_removed_and_range_rejects_are_atomic() -> void:
	var rank_model = _fresh()
	var rank_loaded := _fixture(rank_model, {0:_cid(12, 3), 3:_cid(11, 2), 9:_cid(10, 1), 18:_cid(9, 0)}, _cid(5, 2), [_cid(2, 3)])
	var rank_before := _state_json(rank_model)
	var rank_event: Dictionary = rank_model.clear_tableau(18)

	var removed_model = _fresh()
	var removed_loaded := _fixture(removed_model, {0:_cid(12, 3), 3:_cid(11, 2), 9:_cid(7, 1), 18:_cid(6, 0)}, _cid(5, 2), [_cid(2, 3)])
	var clear_event: Dictionary = removed_model.clear_tableau(18)
	var removed_before := _state_json(removed_model)
	var removed_event: Dictionary = removed_model.clear_tableau(18)
	var range_event: Dictionary = removed_model.clear_tableau(28)
	var passed: bool = (
		rank_loaded and str(rank_event.get("reason", "")) == "rank_not_adjacent" and _state_json(rank_model) == rank_before
		and removed_loaded and bool(clear_event["changed"]) and str(removed_event.get("reason", "")) == "already_removed"
		and str(range_event.get("reason", "")) == "slot_out_of_range" and _state_json(removed_model) == removed_before
	)
	_record("decision_illegal_clicks_atomic", passed, JSON.stringify({"rank":rank_event, "removed":removed_event, "range":range_event}))


func _test_clear_reveals_dependents_and_scores_once() -> void:
	var model = _fresh()
	var loaded := _fixture(model, {0:_cid(12, 3), 3:_cid(11, 2), 9:_cid(7, 1), 18:_cid(6, 0)}, _cid(5, 2), [_cid(2, 3)])
	var before_score := int(model.score)
	var before_moves := int(model.moves)
	var event: Dictionary = model.clear_tableau(18)
	var saved: Dictionary = model.snapshot()
	var passed: bool = (
		loaded and str(event["kind"]) == "clear" and int(event["card"]) == _cid(6, 0)
		and event["revealed"] == [9] and int(saved["tableau"][18]) == -1 and int(saved["waste"].back()) == _cid(6, 0)
		and int(saved["score"]) == before_score + 30 and int(saved["moves"]) == before_moves + 1 and int(saved["streak"]) == 1
	)
	_record("decision_clear_reveal_score", passed, JSON.stringify(event))


func _test_peak_milestone_and_win_freeze() -> void:
	var model = _fresh()
	var loaded := _fixture(model, {0:_cid(6, 0)}, _cid(5, 2), [], true, 2)
	var win: Dictionary = model.clear_tableau(0)
	var terminal := _state_json(model)
	var frozen_clear: Dictionary = model.clear_tableau(0)
	var frozen_draw: Dictionary = model.draw_stock()
	var passed: bool = (
		loaded and str(win["kind"]) == "win" and bool(win["peak_cleared"]) and bool(win["final_peak"])
		and int(win["peak_count"]) == 3 and int(win["remaining"]) == 0 and str(model.status) == "won"
		and str(frozen_clear.get("reason", "")) == "game_finished" and str(frozen_draw.get("reason", "")) == "game_finished"
		and _state_json(model) == terminal
	)
	_record("decision_final_peak_win_freeze", passed, JSON.stringify(win))


func _test_no_move_loss_and_terminal_freeze() -> void:
	var model = _fresh()
	var loaded := _fixture(model, {0:_cid(12, 3), 3:_cid(11, 2), 9:_cid(8, 1), 18:_cid(5, 0)}, _cid(2, 2), [_cid(10, 3)])
	var loss: Dictionary = model.draw_stock()
	var terminal := _state_json(model)
	var frozen_draw: Dictionary = model.draw_stock()
	var frozen_clear: Dictionary = model.clear_tableau(18)
	var passed: bool = (
		loaded and str(loss["kind"]) == "loss" and str(loss["action"]) == "draw" and str(model.status) == "lost"
		and str(frozen_draw.get("reason", "")) == "game_finished" and str(frozen_clear.get("reason", "")) == "game_finished"
		and _state_json(model) == terminal
	)
	_record("decision_no_move_loss_freeze", passed, JSON.stringify(loss))


func _test_restart_replays_exact_deal() -> void:
	var model = _fresh(false)
	var initial := _state_json(model)
	model.draw_stock()
	var restart: Dictionary = model.restart()
	_record("decision_restart_exact_deal", str(restart["kind"]) == "restart" and _state_json(model) == initial, JSON.stringify(restart))


func _test_json_recovery_continues_deterministically() -> void:
	var original = _fresh()
	original.draw_stock()
	var serialized := _state_json(original)
	var parsed: Variant = JSON.parse_string(serialized)
	var restored = _fresh(false)
	var accepted: bool = parsed is Dictionary and restored.restore(parsed)
	var matched: bool = accepted and _state_json(restored) == serialized
	if accepted:
		var first_event: Dictionary = original.draw_stock()
		var second_event: Dictionary = restored.draw_stock()
		matched = matched and JSON.stringify(first_event) == JSON.stringify(second_event) and _state_json(original) == _state_json(restored)
	_record("decision_json_recovery", accepted and matched, JSON.stringify({"accepted":accepted, "matched":matched}))


func _test_corrupt_recovery_rejects_atomically() -> void:
	var model = _fresh()
	model.draw_stock()
	var pristine := _state_json(model)
	var wrong_schema: Dictionary = model.snapshot().duplicate(true)
	wrong_schema["schema"] = "tripeaks-state/v2"
	var wrong_game: Dictionary = model.snapshot().duplicate(true)
	wrong_game["game_id"] = "solitaire"
	var duplicate: Dictionary = model.snapshot().duplicate(true)
	duplicate["stock"][0] = duplicate["waste"][0]
	var inconsistent_removed: Dictionary = model.snapshot().duplicate(true)
	inconsistent_removed["removed"] = [0]
	var unreachable_removed: Dictionary = model.snapshot().duplicate(true)
	var displaced_card := int(unreachable_removed["tableau"][0])
	unreachable_removed["tableau"][0] = -1
	unreachable_removed["removed"] = [0]
	unreachable_removed["waste"].insert(0, displaced_card)
	unreachable_removed["score"] = 30
	unreachable_removed["moves"] = unreachable_removed["waste"].size() - 1
	var terminal: Dictionary = model.snapshot().duplicate(true)
	terminal["status"] = "won"
	var no_waste: Dictionary = model.snapshot().duplicate(true)
	no_waste["waste"] = []
	var rejected: bool = (
		not model.restore(wrong_schema)
		and not model.restore(wrong_game)
		and not model.restore(duplicate)
		and not model.restore(inconsistent_removed)
		and not model.restore(unreachable_removed)
		and not model.restore(terminal)
		and not model.restore(no_waste)
	)
	_record("decision_corrupt_recovery_atomic", rejected and _state_json(model) == pristine)
