extends SceneTree

const GAME_IDS := [
	"merge2048", "watermelon", "meowdoku", "sudoku", "solitaire", "tripeaks",
	"mahjong", "tileclub", "amaze_go", "arrow_go", "amaze"
]

var game: Control
var output_dir := "user://catalog_peak_visual_audit"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	await _settle(0.32)
	for index in range(GAME_IDS.size()):
		var id: String = GAME_IDS[index]
		game._open_game(id)
		await _settle(0.20)
		_trigger_peak(id)
		await _settle(0.17)
		await _save_frame("%02d_%s_peak" % [index + 1, id])
	print("CATALOG_PEAK_AUDIT_DIR=%s" % ProjectSettings.globalize_path(output_dir))
	quit()


func _settle(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame
	await process_frame


func _save_frame(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var error := image.save_png("%s/%s.png" % [output_dir, stem])
	if error != OK:
		push_error("Catalog peak capture failed: %s" % stem)


func _trigger_peak(id: String) -> void:
	match id:
		"merge2048":
			game.state["board"] = [[64, 64, 64, 64], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
			game._merge_move(Vector2i.LEFT)
		"watermelon":
			game.state["columns"][3] = [3, 2, 2, 1]
			game.state["next"] = 1
			game._water_drop(3)
		"meowdoku", "sudoku":
			var solution: Array = game.state["solution"]
			for y in range(3):
				for x in range(3):
					game.state["board"][y][x] = solution[y][x]
			game.state["board"][0][2] = 0
			game.state["selected"] = [2, 0]
			game._sudoku_place(int(solution[0][2]))
		"solitaire":
			game.state["foundations"] = [1, 1, 1, 0]
			game.state["tableau"] = [1, 0, 0, 0, 0, 0, 0]
			game._solitaire_auto()
		"tripeaks":
			game.state["current"] = 8
			game.state["streak"] = 5
			game._tripeaks_tap(game._tripeaks_card_center(5))
		"mahjong":
			game.state["removed"] = range(1, 10) + range(11, 20)
			game.state["selected"] = 0
			game._mahjong_tap(Vector2(50, 242 + 2 * 112 + 10))
		"tileclub":
			var empty_tiles: Array = []
			for _index in range(49):
				empty_tiles.append(0)
			game.state["tiles"] = empty_tiles
			game.state["tiles"][24] = 1
			game.state["tray"] = [1, 1]
			game._tileclub_tap(Vector2(36 + 3 * 64 + 10, 236 + 3 * 64 + 10))
		"amaze_go", "arrow_go":
			var grid_size := int(game.state["size"])
			game.state["player"] = [grid_size - 2, grid_size - 1]
			if id == "arrow_go":
				game.state["arrows"][grid_size - 1][grid_size - 2] = [1, 0]
			game._amaze_step(Vector2i.RIGHT)
		"amaze":
			var grid_size := int(game.state["size"])
			for y in range(grid_size):
				for x in range(grid_size):
					game.state["painted"][y][x] = true
			game.state["painted"][0][1] = false
			game.state["player"] = [0, 0]
			game._amaze_step(Vector2i.RIGHT)
