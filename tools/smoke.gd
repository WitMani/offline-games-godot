extends SceneTree

const GAME_IDS := [
	"merge2248", "merge2048", "watermelon", "meowdoku", "sudoku",
	"snake_classic", "snake_io", "solitaire", "tripeaks", "mahjong",
	"tileclub", "amaze_go", "arrow_go", "amaze"
]

var game: Control

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var failures: Array[String] = []
	for id in GAME_IDS:
		game._open_game(id)
		await process_frame
		if game.game_id != id or game.screen != "game":
			failures.append("open:%s" % id)
		game._reset_current()
		await process_frame
		if game.state.get("status", "") != "playing":
			failures.append("reset:%s" % id)
		# Exercise one deterministic input for each family.
		match id:
			"merge2248", "merge2048": game._merge_move(Vector2i.LEFT)
			"watermelon": game._water_drop(3)
			"meowdoku", "sudoku":
				game.state["selected"] = [0, 0]
				game._sudoku_place(5)
			"snake_classic", "snake_io": game._set_snake_direction(Vector2i.DOWN)
			"solitaire": game._solitaire_draw()
			"tripeaks": game._tripeaks_next()
			"mahjong":
				game._mahjong_tap(Vector2(44, 220))
				game._mahjong_tap(Vector2(484, 332))
			"tileclub": game._tileclub_tap(Vector2(36, 188))
			"amaze_go", "arrow_go", "amaze": game._amaze_step(Vector2i.RIGHT)
		await process_frame
		if not game.state.has("moves"):
			failures.append("state:%s" % id)
	print("SMOKE_GAMES=%d" % GAME_IDS.size())
	if failures.is_empty():
		print("SMOKE_RESULT=PASS")
	else:
		print("SMOKE_RESULT=FAIL %s" % ",".join(failures))
	quit(0 if failures.is_empty() else 1)
