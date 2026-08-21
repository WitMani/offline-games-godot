extends SceneTree

const GAG_WRAPPED: Texture2D = preload("res://assets/art/merge2248/gag/candy_wrapped_gag_v3.png")
const GAG_TART: Texture2D = preload("res://assets/art/merge2248/gag/candy_tart_gag_v3.png")
const GAG_LOZENGE: Texture2D = preload("res://assets/art/merge2248/gag/candy_lozenge_gag_v3.png")
const GAG_FLOWER: Texture2D = preload("res://assets/art/merge2248/gag/candy_flower_gag_v3.png")
const GAG_BURST: Texture2D = preload("res://assets/art/merge2248/gag/caramel_cream_burst_gag_v3.png")
const GAG_MERGE: AudioStream = preload("res://assets/audio/merge2248/gag/candy_merge_gag_v3.ogg")
const GAG_MASTERY: AudioStream = preload("res://assets/audio/merge2248/gag/recipe_mastery_gag_v3.ogg")

const WRAPPED_SHA := "96114935b5d715de786ae2d90ba040c7f443090ca68557e2765b4f2abf522fd7"
const TART_SHA := "3047892e018d3c247fad28cd89a027d08cd0930b16910e8a5c5fa8a771b49d25"
const LOZENGE_SHA := "272067feab4621a0c13d4da07490a76339a50b4d49363aee35ece7db8275970b"
const FLOWER_SHA := "91a9b8e949a06de034c48f96403451981bb359c19ef136817738191dd7e9da4c"
const BURST_SHA := "ca256751e82b6cc546e78568490f0d993660ce463568073ea7aacc9498e7360a"
const MERGE_SHA := "2a73db4e3540b95026a92f64940374bf9dc59b7361f96bf6b60cc80f4528d181"
const MASTERY_SHA := "31d6eb4615ffb52a7520ef45bdca686a6b7bf0bd164efa0f5d9dda977cf869f8"

var game: Control
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.merge2248_persistence_enabled = false
	game.merge2248_reduced_effects_override = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	_test_runtime_assets()
	_test_stable_runtime_binding()
	_test_light_merge_route()
	_test_legendary_merge_route()
	print("MERGE2248_GAG_ART_CASES=%d" % assertions)
	print("MERGE2248_GAG_ART_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)


func _last_sfx(offset := 1) -> AudioStream:
	var player_index := posmod(game.sfx_cursor - offset, game.sfx_players.size())
	return game.sfx_players[player_index].stream


func _test_runtime_assets() -> void:
	var textures := [
		[GAG_WRAPPED, Vector2(256, 186), "res://assets/art/merge2248/gag/candy_wrapped_gag_v3.png", WRAPPED_SHA, "wrapped"],
		[GAG_TART, Vector2(256, 214), "res://assets/art/merge2248/gag/candy_tart_gag_v3.png", TART_SHA, "tart"],
		[GAG_LOZENGE, Vector2(256, 256), "res://assets/art/merge2248/gag/candy_lozenge_gag_v3.png", LOZENGE_SHA, "lozenge"],
		[GAG_FLOWER, Vector2(256, 252), "res://assets/art/merge2248/gag/candy_flower_gag_v3.png", FLOWER_SHA, "flower"],
		[GAG_BURST, Vector2(320, 316), "res://assets/art/merge2248/gag/caramel_cream_burst_gag_v3.png", BURST_SHA, "burst"],
	]
	for item in textures:
		var texture: Texture2D = item[0]
		var label: String = item[4]
		_expect(texture != null, "%s_missing" % label)
		_expect(texture.get_size() == item[1], "%s_dimensions" % label)
		_expect(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "%s_alpha" % label)
		_expect(FileAccess.get_sha256(item[2]) == item[3], "%s_hash" % label)
	_expect(GAG_MERGE != null and GAG_MERGE.get_length() >= 0.32 and GAG_MERGE.get_length() < 0.35, "merge_duration")
	_expect(GAG_MASTERY != null and GAG_MASTERY.get_length() >= 0.82 and GAG_MASTERY.get_length() < 0.85, "mastery_duration")
	_expect(FileAccess.get_sha256("res://assets/audio/merge2248/gag/candy_merge_gag_v3.ogg") == MERGE_SHA, "merge_hash")
	_expect(FileAccess.get_sha256("res://assets/audio/merge2248/gag/recipe_mastery_gag_v3.ogg") == MASTERY_SHA, "mastery_hash")
	_expect(game.MERGE2248_RULES.CONTRACT_VERSION == 4, "mechanics_contract_v4")


func _test_stable_runtime_binding() -> void:
	game._open_game("merge2248")
	game.has_transitioned = false
	_expect(game.merge2248_presenter.GAG_TOKEN_TEXTURES == [GAG_WRAPPED, GAG_TART, GAG_LOZENGE, GAG_FLOWER], "stable_token_family_binding")
	_expect(game.merge2248_presenter.GAG_MERGE_BURST_TEXTURE == GAG_BURST, "burst_binding")
	_expect(game.SFX_MERGE2248_GAG_MERGE == GAG_MERGE, "merge_audio_binding")
	_expect(game.SFX_MERGE2248_GAG_MASTERY == GAG_MASTERY, "mastery_audio_binding")
	_expect(game.merge2248_model.width * game.merge2248_model.height == 40, "ordinary_visible_slots")


func _prepare_chain(chain_length: int) -> void:
	game._init_merge2248(true)
	for y in range(game.merge2248_model.height):
		for x in range(game.merge2248_model.width):
			game.merge2248_model.board[y][x] = 1
	game._sync_merge2248_state()
	var path: Array[Vector2i] = []
	for index in range(chain_length):
		var row := index / 5
		var column := index % 5 if row % 2 == 0 else 4 - index % 5
		path.append(Vector2i(column, game.merge2248_model.height - 1 - row))
	game._merge2248_begin_at(game._merge2248_cell_center(path[0]))
	for index in range(1, path.size()):
		game._merge2248_extend_at(game._merge2248_cell_center(path[index]))


func _test_light_merge_route() -> void:
	_prepare_chain(2)
	game._merge2248_release()
	_expect(not game.merge2248_fx.is_empty() and int(game.merge2248_fx[-1].grade) == 1, "light_grade")
	_expect(_last_sfx() == GAG_MERGE, "light_merge_gag_audio")
	_expect(int(game.state.moves) == 1 and str(game.state.score) == "4", "light_authoritative_outcome")


func _test_legendary_merge_route() -> void:
	_prepare_chain(8)
	game._merge2248_release()
	_expect(not game.merge2248_fx.is_empty() and int(game.merge2248_fx[-1].grade) == 4, "legendary_grade")
	_expect(_last_sfx(2) == GAG_MERGE, "legendary_merge_layer")
	_expect(_last_sfx() == GAG_MASTERY, "legendary_mastery_layer")
	_expect(int(game.state.moves) == 1 and str(game.state.score) == "16", "legendary_authoritative_outcome")
