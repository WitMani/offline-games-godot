class_name SolitaireModel
extends RefCounted

## Renderer-free, clean-room Klondike model for the catalog's Solitaire entry.
##
## The seven-pile contract is a local product decision grounded in generic
## Klondike rules. It is not asserted as an extracted rule from the target app.

const SCHEMA := "solitaire-state/v1"
const GAME_ID := "solitaire"
const PLAYING := "playing"
const WON := "won"
const DRAW_ONE := 1
const DRAW_THREE := 3
const UNLIMITED_RECYCLES := -1
const SUIT_COUNT := 4
const RANK_COUNT := 13
const CARD_COUNT := SUIT_COUNT * RANK_COUNT
const TABLEAU_COUNT := 7

var seed := 0
var draw_count := DRAW_ONE
var max_recycles := UNLIMITED_RECYCLES
var recycles_used := 0
var stock: Array = [] # Card ids, bottom to top.
var waste: Array = [] # Card ids, bottom to top.
var tableau: Array = [] # Seven arrays of {card:int, face_up:bool}, bottom to top.
var foundations: Array = [] # Four suit-indexed card-id arrays, Ace to current top.
var score := 0
var moves := 0
var status := PLAYING

var _rng := RandomNumberGenerator.new()


func reset(seed_value: int = 20260820, requested_draw_count: int = DRAW_ONE, requested_max_recycles: int = UNLIMITED_RECYCLES) -> void:
	seed = seed_value
	draw_count = requested_draw_count if requested_draw_count in [DRAW_ONE, DRAW_THREE] else DRAW_ONE
	max_recycles = maxi(UNLIMITED_RECYCLES, requested_max_recycles)
	recycles_used = 0
	score = 0
	moves = 0
	status = PLAYING
	waste.clear()
	tableau.clear()
	foundations.clear()
	for _suit in range(SUIT_COUNT):
		foundations.append([])

	_rng.seed = seed
	var deck: Array = []
	for card in range(CARD_COUNT):
		deck.append(card)
	_shuffle(deck)
	for column in range(TABLEAU_COUNT):
		var pile: Array = []
		for row in range(column + 1):
			pile.append({"card":int(deck.pop_back()), "face_up":row == column})
		tableau.append(pile)
	stock = deck.duplicate()


func draw() -> Dictionary:
	if status != PLAYING:
		return _ignored("game_finished")
	if not stock.is_empty():
		var drawn: Array = []
		for _index in range(mini(draw_count, stock.size())):
			var card := int(stock.pop_back())
			waste.append(card)
			drawn.append(card)
		moves += 1
		return _event("draw", true, {
			"cards":drawn,
			"stock_count":stock.size(),
			"waste_count":waste.size(),
		})
	if waste.is_empty():
		return _ignored("stock_and_waste_empty")
	if max_recycles != UNLIMITED_RECYCLES and recycles_used >= max_recycles:
		return _ignored("recycle_limit")
	var recycled: Array = waste.duplicate()
	recycled.reverse()
	stock = recycled
	waste.clear()
	recycles_used += 1
	moves += 1
	return _event("recycle", true, {
		"stock_count":stock.size(),
		"recycles_used":recycles_used,
	})


func move_tableau_to_tableau(from_column: int, start_index: int, to_column: int) -> Dictionary:
	if status != PLAYING:
		return _ignored("game_finished")
	if not _valid_column(from_column) or not _valid_column(to_column):
		return _ignored("column_out_of_range")
	if from_column == to_column:
		return _ignored("same_column")
	var source: Array = tableau[from_column]
	if start_index < 0 or start_index >= source.size():
		return _ignored("source_out_of_range")
	if not bool(source[start_index].get("face_up", false)):
		return _ignored("face_down")
	if not _stack_is_valid(source, start_index):
		return _ignored("invalid_stack")
	var first_card := int(source[start_index]["card"])
	if not _can_place_on_tableau(first_card, to_column):
		return _ignored("tableau_rule")

	var moving: Array = source.slice(start_index)
	source.resize(start_index)
	var flipped_card := _flip_exposed_top(source)
	var destination: Array = tableau[to_column]
	destination.append_array(moving)
	moves += 1
	score += 5 + (5 if flipped_card >= 0 else 0)
	return _event("tableau_move", true, {
		"from_column":from_column,
		"to_column":to_column,
		"start_index":start_index,
		"cards":_card_ids(moving),
		"flipped_card":flipped_card,
	})


func move_waste_to_tableau(to_column: int) -> Dictionary:
	if status != PLAYING:
		return _ignored("game_finished")
	if not _valid_column(to_column):
		return _ignored("column_out_of_range")
	if waste.is_empty():
		return _ignored("waste_empty")
	var card := int(waste.back())
	if not _can_place_on_tableau(card, to_column):
		return _ignored("tableau_rule")
	waste.pop_back()
	var destination: Array = tableau[to_column]
	destination.append({"card":card, "face_up":true})
	moves += 1
	score += 5
	return _event("waste_to_tableau", true, {"card":card, "to_column":to_column})


func move_foundation_to_tableau(foundation_suit: int, to_column: int) -> Dictionary:
	if status != PLAYING:
		return _ignored("game_finished")
	if foundation_suit < 0 or foundation_suit >= SUIT_COUNT:
		return _ignored("foundation_out_of_range")
	if not _valid_column(to_column):
		return _ignored("column_out_of_range")
	var foundation: Array = foundations[foundation_suit]
	if foundation.is_empty():
		return _ignored("foundation_empty")
	var card := int(foundation.back())
	if not _can_place_on_tableau(card, to_column):
		return _ignored("tableau_rule")
	foundation.pop_back()
	var destination: Array = tableau[to_column]
	destination.append({"card":card, "face_up":true})
	moves += 1
	score = maxi(0, score - 5)
	return _event("foundation_to_tableau", true, {
		"card":card,
		"from_foundation":foundation_suit,
		"to_column":to_column,
	})


func move_waste_to_foundation(target_suit: int = -1) -> Dictionary:
	if status != PLAYING:
		return _ignored("game_finished")
	if waste.is_empty():
		return _ignored("waste_empty")
	var card := int(waste.back())
	var suit := card_suit(card) if target_suit < 0 else target_suit
	var reason := _foundation_reject_reason(card, suit)
	if not reason.is_empty():
		return _ignored(reason)
	waste.pop_back()
	return _finish_foundation_move(card, suit, "waste", -1)


func move_tableau_to_foundation(from_column: int, target_suit: int = -1) -> Dictionary:
	if status != PLAYING:
		return _ignored("game_finished")
	if not _valid_column(from_column):
		return _ignored("column_out_of_range")
	var source: Array = tableau[from_column]
	if source.is_empty():
		return _ignored("tableau_empty")
	var top: Dictionary = source.back()
	if not bool(top.get("face_up", false)):
		return _ignored("face_down")
	var card := int(top["card"])
	var suit := card_suit(card) if target_suit < 0 else target_suit
	var reason := _foundation_reject_reason(card, suit)
	if not reason.is_empty():
		return _ignored(reason)
	source.pop_back()
	var flipped_card := _flip_exposed_top(source)
	var result := _finish_foundation_move(card, suit, "tableau", from_column)
	result["flipped_card"] = flipped_card
	return result


func auto_foundation() -> Dictionary:
	if status != PLAYING:
		return _ignored("game_finished")
	if not waste.is_empty():
		var waste_card := int(waste.back())
		if _foundation_reject_reason(waste_card, card_suit(waste_card)).is_empty():
			var waste_result := move_waste_to_foundation()
			if str(waste_result.get("kind", "")) != "win":
				waste_result["kind"] = "auto_foundation"
			waste_result["auto"] = true
			return waste_result
	for column in range(TABLEAU_COUNT):
		var pile: Array = tableau[column]
		if pile.is_empty() or not bool(pile.back().get("face_up", false)):
			continue
		var card := int(pile.back()["card"])
		if _foundation_reject_reason(card, card_suit(card)).is_empty():
			var tableau_result := move_tableau_to_foundation(column)
			if str(tableau_result.get("kind", "")) != "win":
				tableau_result["kind"] = "auto_foundation"
			tableau_result["auto"] = true
			return tableau_result
	return _ignored("no_legal_foundation_move")


func restart() -> Dictionary:
	var restart_seed := seed
	var restart_draw_count := draw_count
	var restart_max_recycles := max_recycles
	reset(restart_seed, restart_draw_count, restart_max_recycles)
	return _event("restart", true)


func foundation_total() -> int:
	var total := 0
	for foundation in foundations:
		total += foundation.size()
	return total


func card_rank(card: int) -> int:
	return posmod(card, RANK_COUNT) + 1


func card_suit(card: int) -> int:
	return int(card / RANK_COUNT)


func card_color(card: int) -> int:
	return card_suit(card) % 2


func card_id(rank: int, suit: int) -> int:
	if rank < 1 or rank > RANK_COUNT or suit < 0 or suit >= SUIT_COUNT:
		return -1
	return suit * RANK_COUNT + rank - 1


func snapshot() -> Dictionary:
	return {
		"schema":SCHEMA,
		"game_id":GAME_ID,
		"seed":seed,
		"draw_count":draw_count,
		"max_recycles":max_recycles,
		"recycles_used":recycles_used,
		"stock":stock.duplicate(),
		"waste":waste.duplicate(),
		"tableau":tableau.duplicate(true),
		"foundations":foundations.duplicate(true),
		"score":score,
		"moves":moves,
		"status":status,
		"foundation_total":foundation_total(),
	}


func restore(saved: Dictionary) -> bool:
	var normalized := _validated_snapshot(saved)
	if normalized.is_empty():
		return false
	seed = int(normalized["seed"])
	draw_count = int(normalized["draw_count"])
	max_recycles = int(normalized["max_recycles"])
	recycles_used = int(normalized["recycles_used"])
	stock = normalized["stock"].duplicate()
	waste = normalized["waste"].duplicate()
	tableau = normalized["tableau"].duplicate(true)
	foundations = normalized["foundations"].duplicate(true)
	score = int(normalized["score"])
	moves = int(normalized["moves"])
	status = str(normalized["status"])
	_rng.seed = seed
	return true


func _finish_foundation_move(card: int, suit: int, source_kind: String, source_column: int) -> Dictionary:
	var foundation: Array = foundations[suit]
	foundation.append(card)
	moves += 1
	score += 10
	var won_now := foundation_total() == CARD_COUNT
	if won_now:
		status = WON
		score += 500
	return _event("win" if won_now else "foundation", true, {
		"card":card,
		"foundation_suit":suit,
		"source":source_kind,
		"source_column":source_column,
		"foundation_total":foundation_total(),
	})


func _foundation_reject_reason(card: int, target_suit: int) -> String:
	if target_suit < 0 or target_suit >= SUIT_COUNT:
		return "foundation_out_of_range"
	if card_suit(card) != target_suit:
		return "wrong_suit"
	var foundation: Array = foundations[target_suit]
	if card_rank(card) != foundation.size() + 1:
		return "foundation_sequence"
	return ""


func _can_place_on_tableau(card: int, column: int) -> bool:
	var destination: Array = tableau[column]
	if destination.is_empty():
		return card_rank(card) == RANK_COUNT
	var top: Dictionary = destination.back()
	if not bool(top.get("face_up", false)):
		return false
	var top_card := int(top["card"])
	return card_rank(top_card) == card_rank(card) + 1 and card_color(top_card) != card_color(card)


func _stack_is_valid(pile: Array, start_index: int) -> bool:
	for index in range(start_index, pile.size()):
		if not bool(pile[index].get("face_up", false)):
			return false
		if index + 1 >= pile.size():
			continue
		var lower := int(pile[index]["card"])
		var upper := int(pile[index + 1]["card"])
		if card_rank(lower) != card_rank(upper) + 1 or card_color(lower) == card_color(upper):
			return false
	return true


func _flip_exposed_top(pile: Array) -> int:
	if pile.is_empty() or bool(pile.back().get("face_up", false)):
		return -1
	var top: Dictionary = pile.back()
	top["face_up"] = true
	return int(top["card"])


func _card_ids(entries: Array) -> Array:
	var result: Array = []
	for entry in entries:
		result.append(int(entry["card"]))
	return result


func _valid_column(column: int) -> bool:
	return column >= 0 and column < TABLEAU_COUNT


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
	var saved_draw_count := int(saved.get("draw_count", 0))
	var saved_max_recycles := int(saved.get("max_recycles", -2))
	var saved_recycles_used := int(saved.get("recycles_used", -1))
	if saved_draw_count not in [DRAW_ONE, DRAW_THREE] or saved_max_recycles < UNLIMITED_RECYCLES or saved_recycles_used < 0:
		return {}
	if saved_max_recycles != UNLIMITED_RECYCLES and saved_recycles_used > saved_max_recycles:
		return {}
	var saved_score := int(saved.get("score", -1))
	var saved_moves := int(saved.get("moves", -1))
	if saved_score < 0 or saved_moves < 0:
		return {}
	var saved_stock: Variant = saved.get("stock", null)
	var saved_waste: Variant = saved.get("waste", null)
	var saved_tableau: Variant = saved.get("tableau", null)
	var saved_foundations: Variant = saved.get("foundations", null)
	if not saved_stock is Array or not saved_waste is Array or not saved_tableau is Array or not saved_foundations is Array:
		return {}
	if saved_tableau.size() != TABLEAU_COUNT or saved_foundations.size() != SUIT_COUNT:
		return {}

	var seen := {}
	var normalized_stock: Array = []
	var normalized_waste: Array = []
	var normalized_tableau: Array = []
	var normalized_foundations: Array = []
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

	for raw_pile in saved_tableau:
		if not raw_pile is Array:
			return {}
		var pile: Array = []
		var face_up_started := false
		for raw_entry in raw_pile:
			if not raw_entry is Dictionary or typeof(raw_entry.get("face_up", null)) != TYPE_BOOL:
				return {}
			var card := _normalized_card(raw_entry.get("card", -1))
			if card < 0 or seen.has(card):
				return {}
			var is_face_up := bool(raw_entry["face_up"])
			if is_face_up:
				face_up_started = true
			elif face_up_started:
				return {}
			seen[card] = true
			pile.append({"card":card, "face_up":is_face_up})
		if not pile.is_empty() and not bool(pile.back()["face_up"]):
			return {}
		for index in range(pile.size() - 1):
			if not bool(pile[index]["face_up"]):
				continue
			var lower := int(pile[index]["card"])
			var upper := int(pile[index + 1]["card"])
			if card_rank(lower) != card_rank(upper) + 1 or card_color(lower) == card_color(upper):
				return {}
		normalized_tableau.append(pile)

	for suit in range(SUIT_COUNT):
		var raw_foundation: Variant = saved_foundations[suit]
		if not raw_foundation is Array or raw_foundation.size() > RANK_COUNT:
			return {}
		var foundation: Array = []
		for index in range(raw_foundation.size()):
			var card := _normalized_card(raw_foundation[index])
			if card != card_id(index + 1, suit) or seen.has(card):
				return {}
			seen[card] = true
			foundation.append(card)
		normalized_foundations.append(foundation)

	if seen.size() != CARD_COUNT:
		return {}
	var total_foundations := 0
	for foundation in normalized_foundations:
		total_foundations += foundation.size()
	if total_foundations >= CARD_COUNT:
		return {}
	return {
		"seed":int(saved.get("seed", 0)),
		"draw_count":saved_draw_count,
		"max_recycles":saved_max_recycles,
		"recycles_used":saved_recycles_used,
		"stock":normalized_stock,
		"waste":normalized_waste,
		"tableau":normalized_tableau,
		"foundations":normalized_foundations,
		"score":saved_score,
		"moves":saved_moves,
		"status":PLAYING,
	}


func _normalized_card(value: Variant) -> int:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return -1
	var number := float(value)
	if not is_finite(number) or number != floor(number):
		return -1
	var card := int(number)
	return card if card >= 0 and card < CARD_COUNT else -1
