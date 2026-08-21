class_name TriPeaksModel
extends RefCounted

## Renderer-free clean-room model for the catalog's TriPeaks entry.
##
## The package-specific target rules are not available in lawful evidence.
## This model therefore implements the explicitly documented local contract;
## it must not be cited as proof of target-version parity.

const SCHEMA := "tripeaks-state/v3"
const GAME_ID := "tripeaks"
const PLAYING := "playing"
const WON := "won"
const LOST := "lost"
const SUIT_COUNT := 4
const RANK_COUNT := 13
const CARD_COUNT := SUIT_COUNT * RANK_COUNT
const TABLEAU_COUNT := 28
const STOCK_COUNT := 23
const CLEAR_SCORE := 30

# Card slot indices form rows of 3, 6, 9 and 10. Each entry lists the two
# lower slots that cover it. Slots 18..27 are exposed at entry.
const BLOCKERS := [
	[3, 4], [5, 6], [7, 8],
	[9, 10], [10, 11], [12, 13], [13, 14], [15, 16], [16, 17],
	[18, 19], [19, 20], [20, 21], [21, 22], [22, 23],
	[23, 24], [24, 25], [25, 26], [26, 27],
	[], [], [], [], [], [], [], [], [], [],
]
const PEAK_SLOTS := [0, 1, 2]

var seed := 0
var wrap_ace_king := true
var tableau: Array = [] # Fixed 28 slots; removed cards are represented by -1.
var stock: Array = [] # Card ids, bottom to top.
var waste: Array = [] # Card ids, bottom to top; always non-empty in live state.
var score := 0
var moves := 0
var streak := 0
var status := PLAYING

var _rng := RandomNumberGenerator.new()


func reset(seed_value: int = 20260820, wrap_enabled: bool = true) -> void:
	seed = seed_value
	wrap_ace_king = wrap_enabled
	score = 0
	moves = 0
	streak = 0
	status = PLAYING
	tableau.clear()
	stock.clear()
	waste.clear()

	_rng.seed = seed
	var deck: Array = []
	for card in range(CARD_COUNT):
		deck.append(card)
	_shuffle(deck)
	for _slot in range(TABLEAU_COUNT):
		tableau.append(int(deck.pop_back()))
	waste.append(int(deck.pop_back()))
	stock = deck.duplicate()


func clear_tableau(slot: int) -> Dictionary:
	if status != PLAYING:
		return _ignored("game_finished")
	if slot < 0 or slot >= TABLEAU_COUNT:
		return _ignored("slot_out_of_range")
	if int(tableau[slot]) < 0:
		return _ignored("already_removed")
	if not is_exposed(slot):
		return _ignored("locked")
	var card := int(tableau[slot])
	if not ranks_are_adjacent(card_rank(card), waste_rank()):
		return _ignored("rank_not_adjacent")

	var exposed_before := exposed_slots()
	var peak_count_before := cleared_peak_count()
	tableau[slot] = -1
	waste.append(card)
	moves += 1
	streak += 1
	score += CLEAR_SCORE
	var revealed: Array = []
	for candidate in exposed_slots():
		if candidate not in exposed_before:
			revealed.append(candidate)
	var peak_index := PEAK_SLOTS.find(slot)
	var peak_count_after := cleared_peak_count()
	_refresh_terminal()
	return _event("win" if status == WON else ("loss" if status == LOST else "clear"), true, {
		"action":"clear",
		"slot":slot,
		"card":card,
		"rank":card_rank(card),
		"revealed":revealed,
		"streak":streak,
		"score_delta":CLEAR_SCORE,
		"peak_index":peak_index,
		"peak_cleared":peak_index >= 0,
		"peak_count":peak_count_after,
		"final_peak":peak_count_before < PEAK_SLOTS.size() and peak_count_after == PEAK_SLOTS.size(),
		"remaining":remaining_tableau_count(),
	})


func draw_stock() -> Dictionary:
	if status != PLAYING:
		return _ignored("game_finished")
	if stock.is_empty():
		_refresh_terminal()
		if status == LOST:
			return _event("loss", true, {"action":"empty_stock", "stock_count":0})
		return _ignored("stock_empty")
	var card := int(stock.pop_back())
	waste.append(card)
	moves += 1
	streak = 0
	_refresh_terminal()
	return _event("loss" if status == LOST else "draw", true, {
		"action":"draw",
		"card":card,
		"rank":card_rank(card),
		"stock_count":stock.size(),
		"streak":streak,
	})


func restart() -> Dictionary:
	var restart_seed := seed
	var restart_wrap := wrap_ace_king
	reset(restart_seed, restart_wrap)
	return _event("restart", true, {"seed":seed, "wrap_ace_king":wrap_ace_king})


func is_exposed(slot: int) -> bool:
	if slot < 0 or slot >= TABLEAU_COUNT or int(tableau[slot]) < 0:
		return false
	for blocker in BLOCKERS[slot]:
		if int(tableau[int(blocker)]) >= 0:
			return false
	return true


func exposed_slots() -> Array:
	var result: Array = []
	for slot in range(TABLEAU_COUNT):
		if is_exposed(slot):
			result.append(slot)
	return result


func legal_slots() -> Array:
	if status != PLAYING or waste.is_empty():
		return []
	var result: Array = []
	var current_rank := waste_rank()
	for slot in exposed_slots():
		if ranks_are_adjacent(card_rank(int(tableau[slot])), current_rank):
			result.append(slot)
	return result


func ranks_are_adjacent(first_rank: int, second_rank: int) -> bool:
	if first_rank < 1 or first_rank > RANK_COUNT or second_rank < 1 or second_rank > RANK_COUNT:
		return false
	if absi(first_rank - second_rank) == 1:
		return true
	return wrap_ace_king and ((first_rank == 1 and second_rank == 13) or (first_rank == 13 and second_rank == 1))


func waste_card() -> int:
	return int(waste.back()) if not waste.is_empty() else -1


func waste_rank() -> int:
	return card_rank(waste_card()) if not waste.is_empty() else -1


func remaining_tableau_count() -> int:
	var count := 0
	for card in tableau:
		if int(card) >= 0:
			count += 1
	return count


func removed_slots() -> Array:
	var result: Array = []
	for slot in range(TABLEAU_COUNT):
		if int(tableau[slot]) < 0:
			result.append(slot)
	return result


func cleared_peak_count() -> int:
	var count := 0
	for slot in PEAK_SLOTS:
		if int(tableau[slot]) < 0:
			count += 1
	return count


func card_rank(card: int) -> int:
	return posmod(card, RANK_COUNT) + 1 if card >= 0 and card < CARD_COUNT else -1


func card_suit(card: int) -> int:
	return int(card / RANK_COUNT) if card >= 0 and card < CARD_COUNT else -1


func card_id(rank: int, suit: int) -> int:
	if rank < 1 or rank > RANK_COUNT or suit < 0 or suit >= SUIT_COUNT:
		return -1
	return suit * RANK_COUNT + rank - 1


func snapshot() -> Dictionary:
	return {
		"schema":SCHEMA,
		"game_id":GAME_ID,
		"seed":seed,
		"wrap_ace_king":wrap_ace_king,
		"tableau":tableau.duplicate(),
		"removed":removed_slots(),
		"stock":stock.duplicate(),
		"waste":waste.duplicate(),
		"score":score,
		"moves":moves,
		"streak":streak,
		"status":status,
		"remaining":remaining_tableau_count(),
	}


func restore(saved: Dictionary) -> bool:
	var normalized := _validated_snapshot(saved)
	if normalized.is_empty():
		return false
	seed = int(normalized["seed"])
	wrap_ace_king = bool(normalized["wrap_ace_king"])
	tableau = normalized["tableau"].duplicate()
	stock = normalized["stock"].duplicate()
	waste = normalized["waste"].duplicate()
	score = int(normalized["score"])
	moves = int(normalized["moves"])
	streak = int(normalized["streak"])
	status = PLAYING
	_rng.seed = seed
	return true


func _refresh_terminal() -> void:
	if remaining_tableau_count() == 0:
		status = WON
	elif stock.is_empty() and legal_slots().is_empty():
		status = LOST


func _shuffle(cards: Array) -> void:
	for index in range(cards.size() - 1, 0, -1):
		var swap_index := _rng.randi_range(0, index)
		var held: Variant = cards[index]
		cards[index] = cards[swap_index]
		cards[swap_index] = held


func _event(kind: String, changed: bool, metadata: Dictionary = {}) -> Dictionary:
	var result := {"kind":kind, "changed":changed, "status":status}
	result.merge(metadata, true)
	return result


func _ignored(reason: String) -> Dictionary:
	return _event("ignored", false, {"reason":reason})


func _validated_snapshot(saved: Dictionary) -> Dictionary:
	if str(saved.get("schema", "")) != SCHEMA or str(saved.get("game_id", "")) != GAME_ID:
		return {}
	if str(saved.get("status", "")) != PLAYING:
		return {}
	if typeof(saved.get("wrap_ace_king", null)) != TYPE_BOOL:
		return {}
	var saved_tableau: Variant = saved.get("tableau", null)
	var saved_removed: Variant = saved.get("removed", null)
	var saved_stock: Variant = saved.get("stock", null)
	var saved_waste: Variant = saved.get("waste", null)
	if not saved_tableau is Array or not saved_removed is Array or not saved_stock is Array or not saved_waste is Array:
		return {}
	if saved_tableau.size() != TABLEAU_COUNT or saved_waste.is_empty() or saved_stock.size() > STOCK_COUNT:
		return {}
	if _normalized_any_int(saved.get("seed", null)) == -2147483648:
		return {}

	var seen := {}
	var normalized_tableau: Array = []
	var expected_removed: Array = []
	for slot in range(TABLEAU_COUNT):
		var value: Variant = saved_tableau[slot]
		var card := _normalized_card_or_removed(value)
		if card < -1 or (card >= 0 and seen.has(card)):
			return {}
		if card < 0:
			expected_removed.append(slot)
		else:
			seen[card] = true
		normalized_tableau.append(card)
	var normalized_removed := _normalized_slot_list(saved_removed)
	if normalized_removed.is_empty() and not saved_removed.is_empty():
		return {}
	if normalized_removed != expected_removed:
		return {}
	# A removed upper card could only have been cleared after all of its blockers.
	for slot in expected_removed:
		for blocker in BLOCKERS[int(slot)]:
			if int(normalized_tableau[int(blocker)]) >= 0:
				return {}

	var normalized_stock: Array = []
	var normalized_waste: Array = []
	for value in saved_stock:
		var card := _normalized_card(value)
		if card < 0 or seen.has(card):
			return {}
		seen[card] = true
		normalized_stock.append(card)
	for value in saved_waste:
		var card := _normalized_card(value)
		if card < 0 or seen.has(card):
			return {}
		seen[card] = true
		normalized_waste.append(card)
	if seen.size() != CARD_COUNT:
		return {}

	var saved_score := _normalized_nonnegative_int(saved.get("score", -1))
	var saved_moves := _normalized_nonnegative_int(saved.get("moves", -1))
	var saved_streak := _normalized_nonnegative_int(saved.get("streak", -1))
	if (
		saved_score != expected_removed.size() * CLEAR_SCORE
		or saved_moves != normalized_waste.size() - 1
		or saved_streak < 0
		or saved_streak > expected_removed.size()
	):
		return {}
	if normalized_tableau.all(func(card): return int(card) < 0):
		return {}
	var current_rank := card_rank(int(normalized_waste.back()))
	if normalized_stock.is_empty() and not _has_legal_slot_in(normalized_tableau, current_rank, bool(saved["wrap_ace_king"])):
		return {}
	return {
		"seed":_normalized_any_int(saved.get("seed", 0)),
		"wrap_ace_king":bool(saved["wrap_ace_king"]),
		"tableau":normalized_tableau,
		"stock":normalized_stock,
		"waste":normalized_waste,
		"score":saved_score,
		"moves":saved_moves,
		"streak":saved_streak,
	}


func _has_legal_slot_in(candidate_tableau: Array, current_rank: int, wrap_enabled: bool) -> bool:
	for slot in range(TABLEAU_COUNT):
		var card := int(candidate_tableau[slot])
		if card < 0:
			continue
		var exposed := true
		for blocker in BLOCKERS[slot]:
			if int(candidate_tableau[int(blocker)]) >= 0:
				exposed = false
				break
		if not exposed:
			continue
		var rank := card_rank(card)
		if absi(rank - current_rank) == 1 or (wrap_enabled and ((rank == 1 and current_rank == 13) or (rank == 13 and current_rank == 1))):
			return true
	return false


func _normalized_card(value: Variant) -> int:
	var number := _normalized_any_int(value)
	return number if number >= 0 and number < CARD_COUNT else -1


func _normalized_card_or_removed(value: Variant) -> int:
	var number := _normalized_any_int(value)
	return number if number >= -1 and number < CARD_COUNT else -2


func _normalized_nonnegative_int(value: Variant) -> int:
	var number := _normalized_any_int(value)
	return number if number >= 0 else -1


func _normalized_any_int(value: Variant) -> int:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return -2147483648
	var number := float(value)
	if not is_finite(number) or number != floor(number):
		return -2147483648
	return int(number)


func _normalized_slot_list(values: Array) -> Array:
	var result: Array = []
	var seen := {}
	for value in values:
		var slot := _normalized_any_int(value)
		if slot < 0 or slot >= TABLEAU_COUNT or seen.has(slot):
			return []
		seen[slot] = true
		result.append(slot)
	result.sort()
	return result
