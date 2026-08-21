extends SceneTree

const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const GAG_HEAD: Texture2D = preload("res://assets/art/snakes/gag/gb_snake_head_gag_v2.png")
const GAG_LURE: Texture2D = preload("res://assets/art/snakes/gag/gb_snake_lure_gag_v2.png")
const GAG_SEAL: Texture2D = preload("res://assets/art/snakes/gag/gb_snake_field_seal_gag_v2.png")
const GAG_COLLECT: AudioStream = preload("res://assets/audio/snake/gag/gb_snake_specimen_collect_gag_v2.ogg")
const GAG_COMPLETE: AudioStream = preload("res://assets/audio/snake/gag/gb_snake_field_log_complete_gag_v2.ogg")
const MODEL_SHA := "80d44bd3049fcde30e3cded6d30e375360f2ab5900d286083f7b1bd95653f719"
const HEAD_SHA := "b31eb852f4844151fc5be6ce85408c079290526292be8feffc9ef7836c57f3d5"
const LURE_SHA := "0c2ab2985a5007f23b785d32ec20d8001489bd0c9d5b09f0e9f9d017432a1607"
const SEAL_SHA := "8b078efc3ccf496cde71f05bfc55a9b6cf1cc6cafe630a6f53def5fe2a5ec47e"
const COLLECT_SHA := "35d0d69c32474ab5ba1ca65d2b6a458c0b3a5604adbf8ecda480aaf6c967b861"
const COMPLETE_SHA := "49e2f9b89d473b69adc31d06d6234268521332fb3a5718780ca473824b609aff"
const REQUIRED_COPY := [
	"收盒", "重开", "滑动或方向键转向 · 吃食物长两格", "按右上角重开",
	"双食物无尽生长", "长度", "无尽模式",
]

var game: Control
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	_test_runtime_assets()
	_test_dynamic_font_role()
	_test_initial_signature()
	_test_turn_feedback()
	_test_forage_feedback()
	_test_decade_feedback()
	_test_crash_feedback()
	_test_field_record_feedback_is_nonterminal()
	_test_reduced_effects_preserve_consequence()
	for player in game.sfx_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	game.free()
	await process_frame
	await process_frame
	print("GB_SNAKE_ART_CASES=%d" % assertions)
	print("GB_SNAKE_ART_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func _open() -> void:
	game.reduced_effects = false
	game.haptics_enabled = true
	game._open_game("snake_classic")
	game.has_transitioned = false
	game.snake_reset_started = -10.0


func _last_sfx(offset := 1) -> AudioStream:
	var player_index := posmod(game.sfx_cursor - offset, game.sfx_players.size())
	return game.sfx_players[player_index].stream


func _expect_fx(kind: String, grade: int) -> void:
	_expect(str(game.snake_gb_object_fx.get("kind", "")) == kind, "%s_kind" % kind)
	_expect(int(game.snake_gb_object_fx.get("grade", 0)) == grade, "%s_grade" % kind)
	_expect(float(game.snake_gb_object_fx.get("duration", 0.0)) > 0.0, "%s_duration" % kind)


func _set_foods(first: Vector2i, second: Vector2i) -> void:
	game.snake_gb_model.foods.assign([first, second])
	game.snake_gb_model.food = first


func _test_runtime_assets() -> void:
	var textures := [
		[GAG_HEAD, Vector2(64, 44), "res://assets/art/snakes/gag/gb_snake_head_gag_v2.png", HEAD_SHA, "head"],
		[GAG_LURE, Vector2(48, 64), "res://assets/art/snakes/gag/gb_snake_lure_gag_v2.png", LURE_SHA, "lure"],
		[GAG_SEAL, Vector2(192, 192), "res://assets/art/snakes/gag/gb_snake_field_seal_gag_v2.png", SEAL_SHA, "seal"],
	]
	for item in textures:
		var texture: Texture2D = item[0]
		var label: String = item[4]
		_expect(texture != null, "gag_%s_missing" % label)
		_expect(texture.get_size() == item[1], "gag_%s_dimensions" % label)
		_expect(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "gag_%s_alpha" % label)
		_expect(FileAccess.get_sha256(item[2]) == item[3], "gag_%s_hash" % label)
	_expect(GAG_COLLECT != null and GAG_COLLECT.get_length() >= 0.43 and GAG_COLLECT.get_length() < 0.45, "gag_collect_duration")
	_expect(GAG_COMPLETE != null and GAG_COMPLETE.get_length() >= 0.91 and GAG_COMPLETE.get_length() < 0.93, "gag_complete_duration")
	_expect(FileAccess.get_sha256("res://assets/audio/snake/gag/gb_snake_specimen_collect_gag_v2.ogg") == COLLECT_SHA, "gag_collect_hash")
	_expect(FileAccess.get_sha256("res://assets/audio/snake/gag/gb_snake_field_log_complete_gag_v2.ogg") == COMPLETE_SHA, "gag_complete_hash")
	_expect(FileAccess.get_sha256("res://models/snake_gb_model.gd") == MODEL_SHA, "model_contract_hash")


func _test_dynamic_font_role() -> void:
	for sample in REQUIRED_COPY:
		for index in range(sample.length()):
			var codepoint: int = sample.unicode_at(index)
			_expect(UI_FONT.has_char(codepoint), "font_U+%04X" % codepoint)


func _test_initial_signature() -> void:
	_open()
	_expect(game.SNAKE_GB_GAG_HEAD_TEXTURE == GAG_HEAD, "head_runtime_binding")
	_expect(game.SNAKE_GB_GAG_LURE_TEXTURE == GAG_LURE, "lure_runtime_binding")
	_expect(game.SNAKE_GB_GAG_FIELD_SEAL_TEXTURE == GAG_SEAL, "seal_runtime_binding")
	_expect(game.snake_gb_object_fx.is_empty(), "initial_fx")
	_expect(game.state.get("segments", []) == [[7, 11], [6, 11], [5, 11], [4, 11]], "initial_segments")
	_expect(game.state.get("foods", []).size() == 2, "initial_two_lures")
	_expect(game.state.get("foods", [])[0] != game.state.get("foods", [])[1], "initial_lures_unique")
	_expect(game.state.get("food", []) == game.state.get("foods", [])[0], "food_alias")
	_expect(bool(game.state.get("endless", false)), "endless_contract")
	_expect(not game.state.has("target_length"), "no_false_target")


func _test_turn_feedback() -> void:
	_open()
	var before: Dictionary = game.state.duplicate(true)
	game._set_snake_direction(Vector2i.UP)
	_expect_fx("turn_accepted", 1)
	_expect(game.snake_gb_model.turn_queue == [Vector2i.UP], "accepted_queue")
	_expect(game.state.get("segments", []) == before.get("segments", []), "accepted_moved_early")
	_expect(int(game.state.get("score", 0)) == int(before.get("score", -1)), "accepted_score_changed")
	_expect(_last_sfx() == game.SFX_SNAKE_KEY, "accepted_key_sound")
	_open()
	before = game.state.duplicate(true)
	game._set_snake_direction(Vector2i.LEFT)
	_expect_fx("turn_rejected", 1)
	_expect(game.state == before, "rejected_mutated_rules")
	_expect(str(game.snake_gb_object_fx.get("reason", "")) == "reverse", "rejected_reason")
	_expect(_last_sfx() == game.SFX_SNAKE_REJECT, "rejected_sound")


func _test_forage_feedback() -> void:
	_open()
	var old_head: Vector2i = game.snake_gb_model.segments[0]
	_set_foods(old_head + Vector2i.RIGHT, Vector2i(2, 2))
	game._sync_snake_gb_state()
	game._snake_gb_step()
	_expect_fx("forage", 2)
	_expect(game.snake_gb_model.segments[0] == old_head + Vector2i.RIGHT, "forage_head")
	_expect(int(game.state.get("pending_growth", 0)) == 2, "forage_pending_two")
	_expect(int(game.state.get("score", 0)) == 4, "forage_materialized_early")
	_expect(game.state.get("foods", []).size() == 2, "forage_replenishes_two")
	_expect(not game.snake_float_labels.is_empty() and str(game.snake_float_labels.back().get("text", "")) == "+2", "forage_plus_two_copy")
	_expect(_last_sfx() == GAG_COLLECT, "forage_gag_sound")


func _test_decade_feedback() -> void:
	_open()
	var line: Array[Vector2i] = []
	for x in range(12, 3, -1):
		line.append(Vector2i(x, 11))
	game.snake_gb_model.segments = line
	game.snake_gb_model.direction = Vector2i.RIGHT
	game.snake_gb_model.turn_queue.clear()
	_set_foods(Vector2i(2, 2), Vector2i(3, 3))
	game.snake_gb_model.pending_growth = 1
	game.snake_gb_model.score = 9
	game._sync_snake_gb_state()
	game._snake_gb_step()
	_expect_fx("field_log", 3)
	_expect(int(game.state.get("score", 0)) == 10, "decade_score")
	_expect(game.state.get("status") == "playing", "decade_nonterminal")
	_expect(game.snake_fx_kind == "milestone", "decade_visual_route")
	_expect(bool(game.snake_gb_object_fx.get("nonterminal", false)), "decade_semantic_flag")
	_expect(_last_sfx(2) == GAG_COLLECT, "decade_gag_layer")
	_expect(_last_sfx() == game.SFX_SNAKE_KEY, "decade_register_layer")


func _test_crash_feedback() -> void:
	_open()
	game.snake_gb_model.segments.assign([Vector2i(14, 8), Vector2i(13, 8), Vector2i(12, 8), Vector2i(11, 8)])
	game.snake_gb_model.direction = Vector2i.RIGHT
	game.snake_gb_model.turn_queue.clear()
	_set_foods(Vector2i(3, 3), Vector2i(4, 4))
	game.snake_gb_model.score = 4
	game._sync_snake_gb_state()
	game._snake_gb_step()
	_expect_fx("crash", 4)
	_expect(str(game.state.get("status", "")) == "over", "crash_status")
	_expect(str(game.state.get("terminal_reason", "")) == "wall", "crash_reason")
	_expect(int(game.state.get("moves", -1)) == 0, "crash_extra_move")
	_expect(_last_sfx() == game.SFX_SNAKE_CRASH, "crash_sound")


func _record_segments() -> Array[Vector2i]:
	var tail_to_head: Array[Vector2i] = []
	for y in range(7):
		if y % 2 == 0:
			for x in range(15):
				tail_to_head.append(Vector2i(x, y))
		else:
			for x in range(14, -1, -1):
				tail_to_head.append(Vector2i(x, y))
	for x in range(14, 0, -1):
		tail_to_head.append(Vector2i(x, 7))
	tail_to_head.reverse()
	return tail_to_head


func _test_field_record_feedback_is_nonterminal() -> void:
	_open()
	game.snake_gb_model.segments.assign(_record_segments())
	game.snake_gb_model.direction = Vector2i.DOWN
	game.snake_gb_model.turn_queue.clear()
	_set_foods(Vector2i(12, 20), Vector2i(13, 21))
	game.snake_gb_model.score = 119
	game.snake_gb_model.moves = 115
	game.snake_gb_model.step_index = 115
	game.snake_gb_model.pending_growth = 1
	game._sync_snake_gb_state()
	game._snake_gb_step()
	_expect_fx("complete", 4)
	_expect(str(game.state.get("status", "")) == "playing", "record_nonterminal_status")
	_expect(str(game.state.get("phase", "")) == "running", "record_nonterminal_phase")
	_expect(int(game.state.get("score", 0)) == 120, "record_score")
	_expect(str(game.state.get("terminal_reason", "")) == "", "record_no_terminal_reason")
	_expect(float(game.snake_result_ready_at) < 0.0, "record_no_result_modal")
	_expect(game.snake_fx_kind == "complete", "record_visual_route")
	_expect(bool(game.snake_gb_object_fx.get("nonterminal", false)), "record_semantic_flag")
	_expect(_last_sfx() == GAG_COMPLETE, "record_gag_sound")
	game._snake_gb_step()
	_expect(str(game.state.get("status", "")) == "playing" and int(game.state.get("moves", -1)) == 117, "record_play_continues")


func _test_reduced_effects_preserve_consequence() -> void:
	_open()
	game.reduced_effects = true
	game.haptics_enabled = true
	game.haptic_requests_sent = 0
	game.snake_pixels.clear()
	var old_head: Vector2i = game.snake_gb_model.segments[0]
	_set_foods(old_head + Vector2i.RIGHT, Vector2i(2, 2))
	game._sync_snake_gb_state()
	game._snake_gb_step()
	var forage_duration := float(game.snake_gb_object_fx.get("duration", 0.0))
	var label_duration := float(game.snake_float_labels.back().get("duration", 0.0)) if not game.snake_float_labels.is_empty() else 0.0
	_expect(int(game.state.get("pending_growth", -1)) == 2, "reduced_forage_consequence")
	_expect(forage_duration <= 0.18, "reduced_forage_duration")
	_expect(label_duration <= 0.18, "reduced_label_duration")
	_expect(game.snake_pixels.is_empty(), "reduced_no_particles")
	_expect(game._snake_gb_feedback_offset() == Vector2.ZERO, "reduced_no_shake")
	_expect(int(game.haptic_requests_sent) == 0, "reduced_no_haptics")
	game.snake_gb_model.segments.assign([Vector2i(14, 8), Vector2i(13, 8), Vector2i(12, 8), Vector2i(11, 8)])
	game.snake_gb_model.direction = Vector2i.RIGHT
	game.snake_gb_model.turn_queue.clear()
	_set_foods(Vector2i(3, 3), Vector2i(4, 4))
	game.snake_gb_model.pending_growth = 0
	game.snake_gb_model.score = 4
	game._sync_snake_gb_state()
	game._snake_gb_step()
	_expect(str(game.state.get("status", "")) == "over", "reduced_crash_consequence")
	_expect(float(game.snake_gb_object_fx.get("duration", 1.0)) <= 0.18, "reduced_crash_duration")
	_expect(game.snake_pixels.is_empty(), "reduced_crash_no_particles")
	_expect(int(game.haptic_requests_sent) == 0, "reduced_crash_no_haptics")
