extends SceneTree

const EXPECTED_GAME_IDS: Array[String] = [
	"merge2248", "merge2048", "watermelon", "meowdoku", "sudoku",
	"snake_classic", "snake_io", "solitaire", "tripeaks", "mahjong",
	"tileclub", "amaze_go", "arrow_go", "amaze"
]
const DESIGN_VIEWPORT := Rect2(0.0, 0.0, 540.0, 960.0)

var game: Control
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate() as Control
	root.add_child(game)
	await process_frame
	await process_frame

	var initial_buttons := _home_buttons_in_reading_order()
	_assert_home_button_layout(initial_buttons)

	var observed_ids: Array[String] = []
	var seen_ids: Dictionary = {}
	for index in range(EXPECTED_GAME_IDS.size()):
		var expected_id: String = EXPECTED_GAME_IDS[index]
		var home_buttons := _home_buttons_in_reading_order()
		_expect_equal(home_buttons.size(), EXPECTED_GAME_IDS.size(), "home still exposes 14 game buttons before opening %s" % expected_id)
		if index >= home_buttons.size():
			failures.append("missing home button at reading-order index %d for %s" % [index, expected_id])
			break

		var card_button: Button = home_buttons[index]
		card_button.pressed.emit()
		await process_frame

		var routed_id := str(game.get("game_id"))
		observed_ids.append(routed_id)
		_expect_equal(str(game.get("screen")), "game", "button %d opens the game screen" % index)
		_expect_equal(routed_id, expected_id, "button %d routes to its catalog game" % index)
		_expect_true(not seen_ids.has(routed_id), "home route IDs stay unique; duplicate %s" % routed_id)
		seen_ids[routed_id] = true

		var home_button := _find_game_home_button()
		_expect_true(home_button != null, "%s exposes a visible return-home button" % expected_id)
		if home_button == null:
			break
		home_button.pressed.emit()
		await process_frame
		await process_frame
		_expect_equal(str(game.get("screen")), "home", "%s returns to home before the next selection" % expected_id)

	_expect_equal(observed_ids, EXPECTED_GAME_IDS, "spatial button order matches the 14-game catalog order")
	_expect_equal(seen_ids.size(), EXPECTED_GAME_IDS.size(), "all 14 routed game IDs are unique")
	game.queue_free()
	await process_frame
	_finish()


func _home_buttons_in_reading_order() -> Array[Button]:
	if str(game.get("screen")) != "home":
		return []
	var result: Array[Button] = []
	_collect_visible_buttons(game, result)
	result = result.filter(func(button: Button) -> bool: return button.has_meta("game_id"))
	result.sort_custom(func(left: Button, right: Button) -> bool:
		var left_position := left.get_global_rect().position
		var right_position := right.get_global_rect().position
		if absf(left_position.y - right_position.y) > 1.0:
			return left_position.y < right_position.y
		return left_position.x < right_position.x
	)
	return result


func _collect_visible_buttons(node: Node, result: Array[Button]) -> void:
	for child in node.get_children():
		if child is Button:
			var button := child as Button
			if button.is_visible_in_tree() and not button.is_queued_for_deletion():
				result.append(button)
		_collect_visible_buttons(child, result)


func _assert_home_button_layout(home_buttons: Array[Button]) -> void:
	_expect_equal(home_buttons.size(), EXPECTED_GAME_IDS.size(), "home exposes exactly 14 visible game buttons")
	var metadata_ids: Array[String] = []
	var metadata_indices: Dictionary = {}
	for index in range(home_buttons.size()):
		var button := home_buttons[index]
		var rect := button.get_global_rect()
		var metadata_id := str(button.get_meta("game_id", ""))
		var metadata_index := int(button.get_meta("home_index", -1))
		metadata_ids.append(metadata_id)
		_expect_equal(metadata_index, index, "home button %d preserves its reading-order index" % index)
		_expect_true(not metadata_indices.has(metadata_index), "home_index metadata stays unique; duplicate %d" % metadata_index)
		metadata_indices[metadata_index] = true
		_expect_true(not button.disabled, "home button %d is enabled" % index)
		_expect_true(button.mouse_filter != Control.MOUSE_FILTER_IGNORE, "home button %d accepts pointer input" % index)
		_expect_true(rect.size.x > 0.0 and rect.size.y > 0.0, "home button %d has a non-empty hit area" % index)
		_expect_true(DESIGN_VIEWPORT.encloses(rect), "home button %d stays inside 540x960 (rect=%s)" % [index, str(rect)])
		for other_index in range(index):
			var other_rect := home_buttons[other_index].get_global_rect()
			_expect_true(not rect.intersects(other_rect), "home buttons %d and %d do not overlap (%s vs %s)" % [other_index, index, str(other_rect), str(rect)])
	_expect_equal(metadata_ids, EXPECTED_GAME_IDS, "home button metadata follows the 14-game catalog order")
	_expect_equal(metadata_indices.size(), EXPECTED_GAME_IDS.size(), "all 14 home_index values are unique")


func _find_game_home_button() -> Button:
	var visible_buttons: Array[Button] = []
	_collect_visible_buttons(game, visible_buttons)
	for button in visible_buttons:
		if button.text.strip_edges() in ["首页", "收盒"]:
			return button
	return null


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (actual=%s expected=%s)" % [message, str(actual), str(expected)])


func _finish() -> void:
	print("HOME_BUTTONS_SMOKE=%d" % EXPECTED_GAME_IDS.size())
	if failures.is_empty():
		print("HOME_BUTTONS_RESULT=PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("HOME_BUTTONS_RESULT=FAIL %d" % failures.size())
	quit(1)
