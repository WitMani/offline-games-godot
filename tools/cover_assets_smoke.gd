extends SceneTree

const EXPECTED_GAME_IDS: Array[String] = [
	"merge2248", "merge2048", "watermelon", "meowdoku", "sudoku",
	"snake_classic", "snake_io", "solitaire", "tripeaks", "mahjong",
	"tileclub", "amaze_go", "arrow_go", "amaze"
]
const COVER_DIR := "res://assets/art/covers"
const EXPECTED_ORIGIN := Vector2(24.0, 424.0)
const EXPECTED_SIZE := Vector2(234.0, 58.0)
const EXPECTED_GAP := Vector2(258.0, 68.0)
const EXPECTED_COVER_SIZE := Vector2i(256, 256)
const MAX_COVER_BYTES := 32 * 1024
const MAX_TOTAL_COVER_BYTES := 256 * 1024

var game: Control
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate() as Control
	root.add_child(game)
	await process_frame
	await process_frame

	var catalog_ids := _catalog_ids()
	_expect_equal(catalog_ids, EXPECTED_GAME_IDS, "catalog IDs and order")
	_expect_equal(_unique_count(catalog_ids), EXPECTED_GAME_IDS.size(), "catalog IDs are unique")

	var constants: Dictionary = game.get_script().get_script_constant_map()
	var mapping: Dictionary = constants.get("HOME_COVER_TEXTURES", {})
	_expect_equal(mapping.size(), EXPECTED_GAME_IDS.size(), "cover preload mapping size")
	var mapping_keys: Array[String] = []
	for key in mapping.keys():
		mapping_keys.append(str(key))
	mapping_keys.sort()
	var expected_sorted := EXPECTED_GAME_IDS.duplicate()
	expected_sorted.sort()
	_expect_equal(mapping_keys, expected_sorted, "cover preload keys exactly match catalog IDs")

	var disk_ids := _cover_ids_on_disk()
	_expect_equal(disk_ids, expected_sorted, "cover files exactly match catalog IDs")

	var total_bytes := 0
	var hashes: Dictionary = {}
	for game_id in EXPECTED_GAME_IDS:
		var path := "%s/%s.webp" % [COVER_DIR, game_id]
		_expect_true(ResourceLoader.exists(path, "Texture2D"), "%s exists as Texture2D" % path)
		var resource := load(path)
		_expect_true(resource is Texture2D, "%s loads as Texture2D" % path)
		if resource is Texture2D:
			var texture := resource as Texture2D
			_expect_equal(Vector2i(texture.get_width(), texture.get_height()), EXPECTED_COVER_SIZE, "%s dimensions" % game_id)
			var image := texture.get_image()
			_expect_true(image != null and not image.is_empty(), "%s has decodable pixels" % game_id)
			_expect_true(mapping.has(game_id), "%s is present in preload mapping" % game_id)
			if mapping.has(game_id):
				var mapped: Variant = mapping[game_id]
				_expect_true(mapped is Texture2D, "%s mapped resource is Texture2D" % game_id)
				if mapped is Texture2D:
					_expect_equal((mapped as Texture2D).resource_path, path, "%s mapping points to its own file" % game_id)
		var bytes := FileAccess.get_file_as_bytes(path).size()
		total_bytes += bytes
		_expect_true(bytes > 0 and bytes <= MAX_COVER_BYTES, "%s source bytes within budget (%d)" % [game_id, bytes])
		var digest := FileAccess.get_md5(path)
		_expect_true(not hashes.has(digest), "%s is not byte-identical to another cover" % game_id)
		hashes[digest] = game_id
	_expect_true(total_bytes <= MAX_TOTAL_COVER_BYTES, "cover source total within budget (%d)" % total_bytes)

	_assert_home_button_geometry()
	game.queue_free()
	await process_frame
	print("COVER_ASSETS_COUNT=%d" % EXPECTED_GAME_IDS.size())
	print("COVER_ASSETS_SOURCE_BYTES=%d" % total_bytes)
	if failures.is_empty():
		print("COVER_ASSETS_RESULT=PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("COVER_ASSETS_RESULT=FAIL %d" % failures.size())
	quit(1)


func _catalog_ids() -> Array[String]:
	var result: Array[String] = []
	for item in game.get("catalog"):
		result.append(str(item.get("id", "")))
	return result


func _cover_ids_on_disk() -> Array[String]:
	var result: Array[String] = []
	var directory := DirAccess.open(COVER_DIR)
	_expect_true(directory != null, "cover directory opens")
	if directory == null:
		return result
	for filename in directory.get_files():
		if filename.ends_with(".webp"):
			result.append(filename.trim_suffix(".webp"))
	result.sort()
	return result


func _assert_home_button_geometry() -> void:
	var home_buttons: Array[Button] = []
	_collect_home_buttons(game, home_buttons)
	home_buttons.sort_custom(func(left: Button, right: Button) -> bool:
		return int(left.get_meta("home_index", -1)) < int(right.get_meta("home_index", -1))
	)
	_expect_equal(home_buttons.size(), EXPECTED_GAME_IDS.size(), "home has 14 cartridge hit areas")
	for index in range(mini(home_buttons.size(), EXPECTED_GAME_IDS.size())):
		var button := home_buttons[index]
		var expected_position := EXPECTED_ORIGIN + Vector2(float(index % 2) * EXPECTED_GAP.x, float(index / 2) * EXPECTED_GAP.y)
		_expect_equal(str(button.get_meta("game_id", "")), EXPECTED_GAME_IDS[index], "button %d game_id" % index)
		_expect_equal(int(button.get_meta("home_index", -1)), index, "button %d home_index" % index)
		_expect_true(button.position.is_equal_approx(expected_position), "button %d position unchanged (%s)" % [index, str(button.position)])
		_expect_true(button.size.is_equal_approx(EXPECTED_SIZE), "button %d size unchanged (%s)" % [index, str(button.size)])
		_expect_equal(button.name, "Cartridge_%02d_%s" % [index, EXPECTED_GAME_IDS[index]], "button %d stable name" % index)
		_expect_true(not button.disabled and button.mouse_filter != Control.MOUSE_FILTER_IGNORE, "button %d remains interactive" % index)


func _collect_home_buttons(node: Node, result: Array[Button]) -> void:
	for child in node.get_children():
		if child is Button and child.has_meta("game_id"):
			result.append(child as Button)
		_collect_home_buttons(child, result)


func _unique_count(values: Array[String]) -> int:
	var seen: Dictionary = {}
	for value in values:
		seen[value] = true
	return seen.size()


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (actual=%s expected=%s)" % [message, str(actual), str(expected)])
