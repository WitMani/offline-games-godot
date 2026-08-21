extends SceneTree

## Renderer-free contract probes for the local clean-room Klondike decision.
## These cases prove local mechanics; they do not claim hidden target parity.

const MODEL_PATH := "res://models/solitaire_model.gd"
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
	_test_seven_pile_deal_topology()
	_test_seeded_deal_is_deterministic()
	_test_draw_one_and_unlimited_recycle_order()
	_test_draw_three_short_draw_and_finite_recycle()
	_test_tableau_alternating_descending_and_atomic_rejects()
	_test_stack_move_flips_newly_exposed_card()
	_test_empty_column_accepts_only_king_led_stack()
	_test_waste_to_tableau_obeys_same_rule()
	_test_foundation_is_same_suit_ascending()
	_test_auto_moves_at_most_one_legal_card()
	_test_win_requires_52_foundation_cards_and_freezes()
	_test_restart_and_json_recovery()
	_test_corrupt_recovery_rejects_atomically()
	_finish()


func _fresh(draw_count: int = 1, max_recycles: int = -1):
	var model = model_script.new()
	model.reset(TEST_SEED, draw_count, max_recycles)
	return model


func _finish() -> void:
	if cases_run != EXPECTED_CASES:
		failures.append("case_count_%d_of_%d" % [cases_run, EXPECTED_CASES])
	print("SOLITAIRE_V3_CONTRACT_CASES=%d" % cases_run)
	print("SOLITAIRE_V3_CONTRACT_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _record(name: String, passed: bool, evidence: String = "") -> void:
	cases_run += 1
	if not passed:
		failures.append(name + ("=" + evidence if not evidence.is_empty() else ""))


func _cid(rank: int, suit: int) -> int:
	return suit * 13 + rank - 1


func _entry(card: int, face_up: bool = true) -> Dictionary:
	return {"card":card, "face_up":face_up}


func _load_fixture(model, piles: Array, waste_cards: Array = [], foundation_counts: Array = [0, 0, 0, 0], stock_cards: Variant = null, fill_unused: String = "stock") -> bool:
	var saved: Dictionary = model.snapshot()
	var used := {}
	var foundations: Array = []
	for suit in range(4):
		var foundation: Array = []
		for rank in range(1, int(foundation_counts[suit]) + 1):
			var card := _cid(rank, suit)
			if used.has(card):
				return false
			used[card] = true
			foundation.append(card)
		foundations.append(foundation)
	var tableau: Array = []
	for column in range(7):
		var pile: Array = piles[column].duplicate(true) if column < piles.size() else []
		for card_entry in pile:
			var card := int(card_entry["card"])
			if used.has(card):
				return false
			used[card] = true
		tableau.append(pile)
	var waste: Array = []
	for value in waste_cards:
		var card := int(value)
		if used.has(card):
			return false
		used[card] = true
		waste.append(card)
	var stock: Array = []
	if stock_cards is Array:
		for value in stock_cards:
			var card := int(value)
			if used.has(card):
				return false
			used[card] = true
			stock.append(card)
	var remaining: Array = []
	for card in range(52):
		if not used.has(card):
			remaining.append(card)
	if fill_unused == "stock":
		stock.append_array(remaining)
	elif fill_unused == "waste":
		remaining.append_array(waste)
		waste = remaining
	elif not remaining.is_empty():
		return false
	saved["stock"] = stock
	saved["waste"] = waste
	saved["tableau"] = tableau
	saved["foundations"] = foundations
	saved["foundation_total"] = 0
	saved["score"] = 0
	saved["moves"] = 0
	saved["recycles_used"] = 0
	saved["status"] = "playing"
	return model.restore(saved)


func _all_cards(saved: Dictionary) -> Array:
	var cards: Array = []
	cards.append_array(saved["stock"])
	cards.append_array(saved["waste"])
	for pile in saved["tableau"]:
		for card_entry in pile:
			cards.append(int(card_entry["card"]))
	for foundation in saved["foundations"]:
		cards.append_array(foundation)
	return cards


func _test_seven_pile_deal_topology() -> void:
	var model = _fresh()
	var saved: Dictionary = model.snapshot()
	var topology_ok: bool = saved["stock"].size() == 24 and saved["waste"].is_empty() and saved["tableau"].size() == 7
	var faces_ok := true
	for column in range(7):
		var pile: Array = saved["tableau"][column]
		topology_ok = topology_ok and pile.size() == column + 1
		for index in range(pile.size()):
			faces_ok = faces_ok and bool(pile[index]["face_up"]) == (index == pile.size() - 1)
	var cards: Array = _all_cards(saved)
	var unique: Dictionary = {}
	for card in cards:
		unique[int(card)] = true
	_record("decision_seven_pile_deal", topology_ok and faces_ok and cards.size() == 52 and unique.size() == 52, JSON.stringify(saved["tableau"]))


func _test_seeded_deal_is_deterministic() -> void:
	var first = _fresh()
	var second = _fresh()
	var third = model_script.new()
	third.reset(TEST_SEED + 1, 1, -1)
	_record("decision_seeded_deal", JSON.stringify(first.snapshot()) == JSON.stringify(second.snapshot()) and JSON.stringify(first.snapshot()) != JSON.stringify(third.snapshot()))


func _test_draw_one_and_unlimited_recycle_order() -> void:
	var model = _fresh(1, -1)
	var original_stock: Array = model.snapshot()["stock"].duplicate()
	var first_top := int(original_stock.back())
	var first: Dictionary = model.draw()
	for _index in range(23):
		model.draw()
	var before_recycle: Dictionary = model.snapshot()
	var expected_stock: Array = before_recycle["waste"].duplicate()
	expected_stock.reverse()
	var recycle: Dictionary = model.draw()
	var after_recycle: Dictionary = model.snapshot()
	var next_draw: Dictionary = model.draw()
	var passed: bool = (
		str(first["kind"]) == "draw"
		and first["cards"] == [first_top]
		and str(recycle["kind"]) == "recycle"
		and after_recycle["stock"] == expected_stock
		and int(after_recycle["recycles_used"]) == 1
		and next_draw["cards"] == [first_top]
	)
	_record("decision_draw_one_unlimited_recycle", passed, JSON.stringify({"first":first, "recycle":recycle, "next":next_draw}))


func _test_draw_three_short_draw_and_finite_recycle() -> void:
	var model = _fresh(3, 1)
	var hearts: Array = []
	for rank in range(1, 14):
		hearts.append(_cid(rank, 3))
	var loaded: bool = _load_fixture(model, [], hearts.slice(5), [13, 13, 13, 0], hearts.slice(0, 5), "none")
	var first: Dictionary = model.draw()
	var second: Dictionary = model.draw()
	var recycled: Dictionary = model.draw()
	while not model.stock.is_empty():
		model.draw()
	var before_reject: String = JSON.stringify(model.snapshot())
	var rejected: Dictionary = model.draw()
	var passed: bool = (
		loaded
		and first["cards"].size() == 3
		and second["cards"].size() == 2
		and str(recycled["kind"]) == "recycle"
		and str(rejected.get("reason", "")) == "recycle_limit"
		and JSON.stringify(model.snapshot()) == before_reject
	)
	_record("decision_draw_three_finite_recycle", passed, JSON.stringify({"first":first, "second":second, "recycle":recycled, "reject":rejected}))


func _test_tableau_alternating_descending_and_atomic_rejects() -> void:
	var legal = _fresh()
	var legal_loaded: bool = _load_fixture(legal, [[_entry(_cid(9, 3))], [_entry(_cid(10, 2))]])
	var legal_result: Dictionary = legal.move_tableau_to_tableau(0, 0, 1)
	var legal_state: Dictionary = legal.snapshot()

	var wrong_color = _fresh()
	var color_loaded: bool = _load_fixture(wrong_color, [[_entry(_cid(9, 1))], [_entry(_cid(10, 3))]])
	var color_before: String = JSON.stringify(wrong_color.snapshot())
	var color_result: Dictionary = wrong_color.move_tableau_to_tableau(0, 0, 1)

	var wrong_rank = _fresh()
	var rank_loaded: bool = _load_fixture(wrong_rank, [[_entry(_cid(8, 3))], [_entry(_cid(10, 2))]])
	var rank_before: String = JSON.stringify(wrong_rank.snapshot())
	var rank_result: Dictionary = wrong_rank.move_tableau_to_tableau(0, 0, 1)

	var facedown = _fresh()
	var face_before: String = JSON.stringify(facedown.snapshot())
	var face_result: Dictionary = facedown.move_tableau_to_tableau(1, 0, 0)
	var passed: bool = (
		legal_loaded and bool(legal_result["changed"]) and legal_state["tableau"][0].is_empty() and legal_state["tableau"][1].size() == 2
		and color_loaded and str(color_result.get("reason", "")) == "tableau_rule" and JSON.stringify(wrong_color.snapshot()) == color_before
		and rank_loaded and str(rank_result.get("reason", "")) == "tableau_rule" and JSON.stringify(wrong_rank.snapshot()) == rank_before
		and str(face_result.get("reason", "")) == "face_down" and JSON.stringify(facedown.snapshot()) == face_before
	)
	_record("decision_tableau_legality_atomic", passed, JSON.stringify({"legal":legal_result, "color":color_result, "rank":rank_result, "face":face_result}))


func _test_stack_move_flips_newly_exposed_card() -> void:
	var model = _fresh()
	var hidden: int = _cid(1, 0)
	var nine_red: int = _cid(9, 3)
	var eight_black: int = _cid(8, 2)
	var loaded: bool = _load_fixture(model, [[_entry(hidden, false), _entry(nine_red), _entry(eight_black)], [_entry(_cid(10, 2))]])
	var result: Dictionary = model.move_tableau_to_tableau(0, 1, 1)
	var saved: Dictionary = model.snapshot()
	var passed: bool = (
		loaded and bool(result["changed"])
		and result["cards"] == [nine_red, eight_black]
		and int(result["flipped_card"]) == hidden
		and saved["tableau"][0].size() == 1 and bool(saved["tableau"][0][0]["face_up"])
		and saved["tableau"][1].size() == 3
	)
	_record("decision_stack_move_and_flip", passed, JSON.stringify(result))


func _test_empty_column_accepts_only_king_led_stack() -> void:
	var king = _fresh()
	var loaded_king: bool = _load_fixture(king, [[_entry(_cid(13, 3)), _entry(_cid(12, 2))], []])
	var king_result: Dictionary = king.move_tableau_to_tableau(0, 0, 1)
	var queen = _fresh()
	var loaded_queen: bool = _load_fixture(queen, [[_entry(_cid(12, 3))], []])
	var queen_before: String = JSON.stringify(queen.snapshot())
	var queen_result: Dictionary = queen.move_tableau_to_tableau(0, 0, 1)
	_record("decision_empty_column_king", loaded_king and bool(king_result["changed"]) and loaded_queen and str(queen_result.get("reason", "")) == "tableau_rule" and JSON.stringify(queen.snapshot()) == queen_before, JSON.stringify({"king":king_result, "queen":queen_result}))


func _test_waste_to_tableau_obeys_same_rule() -> void:
	var model = _fresh()
	var card: int = _cid(9, 3)
	var loaded: bool = _load_fixture(model, [[_entry(_cid(10, 2))]], [card])
	var result: Dictionary = model.move_waste_to_tableau(0)
	var saved: Dictionary = model.snapshot()
	_record("decision_waste_to_tableau", loaded and bool(result["changed"]) and saved["waste"].is_empty() and int(saved["tableau"][0].back()["card"]) == card, JSON.stringify(result))


func _test_foundation_is_same_suit_ascending() -> void:
	var model = _fresh()
	var ace_hearts: int = _cid(1, 3)
	var two_hearts: int = _cid(2, 3)
	var loaded: bool = _load_fixture(model, [], [two_hearts, ace_hearts])
	var before_wrong_suit: String = JSON.stringify(model.snapshot())
	var wrong_suit: Dictionary = model.move_waste_to_foundation(0)
	var wrong_atomic: bool = JSON.stringify(model.snapshot()) == before_wrong_suit
	var ace: Dictionary = model.move_waste_to_foundation(3)
	var two: Dictionary = model.move_waste_to_foundation(3)

	var gap = _fresh()
	var gap_loaded: bool = _load_fixture(gap, [], [two_hearts])
	var gap_before: String = JSON.stringify(gap.snapshot())
	var gap_result: Dictionary = gap.move_waste_to_foundation(3)
	var passed: bool = (
		loaded and str(wrong_suit.get("reason", "")) == "wrong_suit" and wrong_atomic
		and bool(ace["changed"]) and bool(two["changed"]) and model.snapshot()["foundations"][3] == [ace_hearts, two_hearts]
		and gap_loaded and str(gap_result.get("reason", "")) == "foundation_sequence" and JSON.stringify(gap.snapshot()) == gap_before
	)
	_record("decision_foundation_same_suit_ascending", passed, JSON.stringify({"wrong":wrong_suit, "ace":ace, "two":two, "gap":gap_result}))


func _test_auto_moves_at_most_one_legal_card() -> void:
	var model = _fresh()
	var ace_hearts: int = _cid(1, 3)
	var ace_clubs: int = _cid(1, 2)
	var loaded: bool = _load_fixture(model, [[_entry(ace_clubs)]], [ace_hearts])
	var first: Dictionary = model.auto_foundation()
	var first_saved: Dictionary = model.snapshot()
	var second: Dictionary = model.auto_foundation()
	var second_saved: Dictionary = model.snapshot()
	var no_move: Dictionary = model.auto_foundation()
	var passed: bool = (
		loaded and str(first["kind"]) == "auto_foundation" and int(first_saved["foundation_total"]) == 1
		and first_saved["foundations"][3] == [ace_hearts] and first_saved["foundations"][2].is_empty()
		and str(second["kind"]) == "auto_foundation" and int(second_saved["foundation_total"]) == 2
		and str(no_move.get("reason", "")) == "no_legal_foundation_move"
	)
	_record("decision_auto_one_legal_card", passed, JSON.stringify({"first":first, "second":second, "none":no_move}))


func _test_win_requires_52_foundation_cards_and_freezes() -> void:
	var model = _fresh()
	var king_hearts: int = _cid(13, 3)
	var loaded: bool = _load_fixture(model, [], [king_hearts], [13, 13, 13, 12], [], "none")
	var win: Dictionary = model.move_waste_to_foundation(3)
	var terminal: String = JSON.stringify(model.snapshot())
	var frozen_draw: Dictionary = model.draw()
	var frozen_auto: Dictionary = model.auto_foundation()
	var rejected_restore = _fresh()
	var terminal_restore_rejected: bool = not rejected_restore.restore(model.snapshot())
	var passed: bool = (
		loaded and str(win["kind"]) == "win" and str(model.status) == "won" and model.foundation_total() == 52
		and str(frozen_draw.get("reason", "")) == "game_finished" and str(frozen_auto.get("reason", "")) == "game_finished"
		and JSON.stringify(model.snapshot()) == terminal and terminal_restore_rejected
	)
	_record("decision_win_52_and_terminal_freeze", passed, JSON.stringify({"win":win, "draw":frozen_draw, "auto":frozen_auto}))


func _test_restart_and_json_recovery() -> void:
	var original = _fresh(3, 2)
	original.draw()
	var serialized: String = JSON.stringify(original.snapshot())
	var parsed: Variant = JSON.parse_string(serialized)
	var restored = _fresh()
	var accepted: bool = parsed is Dictionary and restored.restore(parsed)
	var matches: bool = accepted and JSON.stringify(restored.snapshot()) == serialized
	if accepted:
		original.draw()
		restored.draw()
		matches = matches and JSON.stringify(original.snapshot()) == JSON.stringify(restored.snapshot())
	original.restart()
	var fresh = _fresh(3, 2)
	var restarted_matches: bool = JSON.stringify(original.snapshot()) == JSON.stringify(fresh.snapshot())
	_record("decision_restart_json_recovery", accepted and matches and restarted_matches, JSON.stringify({"accepted":accepted, "matches":matches, "restart":restarted_matches}))


func _test_corrupt_recovery_rejects_atomically() -> void:
	var model = _fresh()
	model.draw()
	var pristine: String = JSON.stringify(model.snapshot())
	var wrong_schema: Dictionary = model.snapshot().duplicate(true)
	wrong_schema["schema"] = "solitaire-state/v0"
	var wrong_game: Dictionary = model.snapshot().duplicate(true)
	wrong_game["game_id"] = "tripeaks"
	var duplicate: Dictionary = model.snapshot().duplicate(true)
	duplicate["stock"][0] = duplicate["stock"][1]
	var invalid_faces: Dictionary = model.snapshot().duplicate(true)
	invalid_faces["tableau"][1][0]["face_up"] = true
	invalid_faces["tableau"][1][1]["face_up"] = false
	var terminal: Dictionary = model.snapshot().duplicate(true)
	terminal["status"] = "won"
	var rejected: bool = (
		not model.restore(wrong_schema)
		and not model.restore(wrong_game)
		and not model.restore(duplicate)
		and not model.restore(invalid_faces)
		and not model.restore(terminal)
	)
	_record("decision_corrupt_recovery_atomic", rejected and JSON.stringify(model.snapshot()) == pristine)
