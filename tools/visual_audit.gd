extends SceneTree

const GAME_IDS := [
	"merge2248", "merge2048", "watermelon", "meowdoku", "sudoku",
	"snake_classic", "snake_io", "solitaire", "tripeaks", "mahjong",
	"tileclub", "amaze_go", "arrow_go", "amaze"
]

var game: Control
var output_dir := "user://visual_audit"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	await _settle(0.45)
	await _save_frame("00_home")
	for index in range(GAME_IDS.size()):
		var id: String = GAME_IDS[index]
		game._open_game(id)
		await _settle(0.52)
		await _save_frame("%02d_%s_before" % [index + 1, id])
		_exercise(id)
		await _settle(0.16 if id != "snake_classic" and id != "snake_io" else 0.42)
		await _save_frame("%02d_%s_after" % [index + 1, id])
	print("VISUAL_AUDIT_DIR=%s" % ProjectSettings.globalize_path(output_dir))
	quit()

func _settle(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame
	await process_frame

func _save_frame(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [output_dir, stem]
	var error := image.save_png(path)
	if error != OK:
		push_error("Visual audit capture failed: %s" % path)

func _exercise(id: String) -> void:
	match id:
		"merge2248":
			var rect: Rect2 = game._merge2248_board_rect()
			var cell := rect.size / Vector2(5, 8)
			game.merge2248_model.board[7][0] = 2
			game.merge2248_model.board[7][1] = 2
			game._sync_merge2248_state()
			game._merge2248_begin_at(rect.position + Vector2(cell.x * 0.5, cell.y * 7.5))
			game.merge2248_drag_active = true
			game._merge2248_extend_at(rect.position + Vector2(cell.x * 1.5, cell.y * 7.5))
			game._merge2248_release()
			game.merge2248_drag_active = false
		"merge2048":
			game.state["board"] = [[2, 2, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
			game._merge_move(Vector2i.LEFT)
		"watermelon": game._handle_tap(Vector2(260, 380))
		"meowdoku", "sudoku":
			game.state["selected"] = [2, 0]
			game._sudoku_place(4)
		"snake_classic":
			var head: Vector2i = game.snake_gb_model.segments[0]
			game.snake_gb_model.food = head + game.snake_gb_model.direction
			game.snake_gb_model.foods.assign([game.snake_gb_model.food])
			game._sync_snake_gb_state()
			game._snake_gb_step()
		"snake_io":
			game.snakes_arena_model.target_pellet_count = 1
			game.snakes_arena_model.pellets.assign([{"id":9090, "position":Vector2(9, 0), "value":4.0, "palette":1, "source":"visual_audit"}])
			game._sync_snakes_arena_state()
			game._snakes_arena_update(0.10)
		"solitaire": game._solitaire_draw()
		"tripeaks": game._tripeaks_next()
		"mahjong": game._mahjong_tap(Vector2(50, 250))
		"tileclub":
			var tile_index := 0
			for index in range(game.state["tiles"].size()):
				if int(game.state["tiles"][index]) > 0:
					tile_index = index
					break
			var tile_col := tile_index % 7
			var tile_row := tile_index / 7
			game._tileclub_tap(Vector2(42 + tile_col * 64, 248 + tile_row * 64))
		"amaze_go", "arrow_go", "amaze": game._amaze_step(Vector2i.RIGHT)
