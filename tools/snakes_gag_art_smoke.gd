extends SceneTree

const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const GAG_HEAD: Texture2D = preload("res://assets/art/snakes/gag-v2/snakes_player_head_gag_v2.png")
const GAG_BEAN: Texture2D = preload("res://assets/art/snakes/gag-v2/snakes_prize_bean_gag_v2.png")
const GAG_BURST: Texture2D = preload("res://assets/art/snakes/gag-v2/snakes_knockout_burst_gag_v2.png")
const GAG_CHOMP: AudioStream = preload("res://assets/audio/snakes/gag-v2/gummy_chomp_gag_v2.ogg")
const GAG_BOOST: AudioStream = preload("res://assets/audio/snakes/gag-v2/gummy_boost_gag_v2.ogg")
const GAG_KNOCKOUT: AudioStream = preload("res://assets/audio/snakes/gag-v2/gummy_knockout_gag_v2.ogg")
const GAG_LEADER: AudioStream = preload("res://assets/audio/snakes/gag-v2/leader_takeover_gag_v2.ogg")
const MODEL_SHA := "7aeb9eb720233e4d957649293289935f46106d9b94320126c9682ca0e6f22852"
const HEAD_SHA := "bbed38ae8418b931577b25c525bd9c678f35f8e70469e9fc57e64c281ae99ec9"
const BEAN_SHA := "f1769c0bdd7d2ba294df7e9f2ebfbaa472f20caaf287687739b93626a6ebdc6c"
const BURST_SHA := "e149b09f7d91317eec53bc0868721691491298e335c2e6f83741d0bdff170cc1"
const CHOMP_SHA := "636f0616cfa6f01487362c0178958563aad9dfd473a6fddfc67f97bc09801ece"
const BOOST_SHA := "3e2aba7130176c2c90a565f3f88300a9118de2b3e957ab48a71868c1c7d6d6c2"
const KNOCKOUT_SHA := "9a23d746b0a856bf5982a29a9f62e6f7f390db44702566fe7a0797b16a83583f"
const LEADER_SHA := "c007cb704f3843304205b6c5306842ba7c9ca4536c6b2077ed9839a5612bf128"
const REQUIRED_COPY := [
	"收盒", "再来", "我的位次", "排行榜", "体量", "新的第一名",
	"位次 ↑ 1", "彩豆散开！", "抢食 +4.0", "还吃不动！",
	"指向任意方向 · 按住右下冲刺", "撞到了！", "最终位次",
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
	_test_font_role()
	_test_stable_signature()
	_test_event_routes()
	_test_reduced_effects_truth()
	_test_source_master_exclusion()
	print("SNAKES_GAG_ART_CASES=%d" % assertions)
	print("SNAKES_GAG_ART_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func _open() -> void:
	game._open_game("snake_io")
	game.has_transitioned = false
	game.arena_reset_started = -10.0


func _last_sfx(offset := 1) -> AudioStream:
	var player_index := posmod(game.sfx_cursor - offset, game.sfx_players.size())
	return game.sfx_players[player_index].stream


func _test_runtime_assets() -> void:
	var textures := [
		[GAG_HEAD, Vector2(192, 192), "res://assets/art/snakes/gag-v2/snakes_player_head_gag_v2.png", HEAD_SHA, "head"],
		[GAG_BEAN, Vector2(128, 112), "res://assets/art/snakes/gag-v2/snakes_prize_bean_gag_v2.png", BEAN_SHA, "bean"],
		[GAG_BURST, Vector2(256, 256), "res://assets/art/snakes/gag-v2/snakes_knockout_burst_gag_v2.png", BURST_SHA, "burst"],
	]
	for item in textures:
		var texture: Texture2D = item[0]
		var label: String = item[4]
		_expect(texture != null, "%s_missing" % label)
		_expect(texture.get_size() == item[1], "%s_dimensions" % label)
		_expect(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "%s_alpha" % label)
		_expect(FileAccess.get_sha256(item[2]) == item[3], "%s_hash" % label)
	var audio := [
		[GAG_CHOMP, "res://assets/audio/snakes/gag-v2/gummy_chomp_gag_v2.ogg", CHOMP_SHA, 0.66, 0.72, "chomp"],
		[GAG_BOOST, "res://assets/audio/snakes/gag-v2/gummy_boost_gag_v2.ogg", BOOST_SHA, 0.38, 0.42, "boost"],
		[GAG_KNOCKOUT, "res://assets/audio/snakes/gag-v2/gummy_knockout_gag_v2.ogg", KNOCKOUT_SHA, 0.45, 0.50, "knockout"],
		[GAG_LEADER, "res://assets/audio/snakes/gag-v2/leader_takeover_gag_v2.ogg", LEADER_SHA, 0.80, 0.86, "leader"],
	]
	for item in audio:
		var stream: AudioStream = item[0]
		var label: String = item[5]
		_expect(stream != null, "%s_audio_missing" % label)
		_expect(stream.get_length() >= item[3] and stream.get_length() <= item[4], "%s_audio_duration" % label)
		_expect(FileAccess.get_sha256(item[1]) == item[2], "%s_audio_hash" % label)
	_expect(FileAccess.get_sha256("res://models/snakes_arena_model.gd") == MODEL_SHA, "model_changed")
	_expect(FileAccess.file_exists("res://docs/replica/snakes-v3/mechanics-gate.json"), "mechanics_gate_missing")
	var gate_text := FileAccess.get_file_as_string("res://docs/replica/snakes-v3/mechanics-gate.json")
	_expect("\"gag_production_authorized\": true" in gate_text, "mechanics_gate_not_passed")


func _test_font_role() -> void:
	for sample in REQUIRED_COPY:
		for index in range(sample.length()):
			var codepoint: int = sample.unicode_at(index)
			_expect(UI_FONT.has_char(codepoint), "font_U+%04X" % codepoint)


func _test_stable_signature() -> void:
	_open()
	_expect(game.SNAKES_GAG_PLAYER_HEAD_TEXTURE == GAG_HEAD, "head_runtime_binding")
	_expect(game.SNAKES_GAG_PRIZE_BEAN_TEXTURE == GAG_BEAN, "bean_runtime_binding")
	_expect(game.SNAKES_GAG_KNOCKOUT_BURST_TEXTURE == GAG_BURST, "burst_runtime_binding")
	_expect(str(game.state.get("status", "")) == "playing", "initial_status")
	_expect(bool(game.state.get("player", {}).get("alive", false)), "initial_player_alive")
	_expect(game.state.get("pellets", []).size() == 96, "initial_pellet_count")
	_expect(game.arena_knockout_started < -1.0, "initial_knockout_fx")


func _test_event_routes() -> void:
	_open()
	var before: Dictionary = game.state.duplicate(true)
	var eat_events: Array[Dictionary] = [{"kind":"player_ate", "at":Vector2.ZERO, "value":4.5}]
	game._snakes_arena_dispatch(eat_events)
	_expect(game.state == before, "eat_presentation_mutated_state")
	_expect(game.arena_eat_started == game.elapsed, "eat_started")
	_expect(_last_sfx() == GAG_CHOMP, "eat_gag_sound")

	var boost_events: Array[Dictionary] = [{"kind":"boost_started", "id":0}]
	game._snakes_arena_dispatch(boost_events)
	_expect(game.state == before, "boost_presentation_mutated_state")
	_expect(_last_sfx() == GAG_BOOST, "boost_gag_sound")

	var knockout_events: Array[Dictionary] = [{
		"kind":"bot_died", "id":1, "killer_id":0, "at":Vector2(190, 0), "reason":"fixture"
	}]
	game._snakes_arena_dispatch(knockout_events)
	_expect(game.state == before, "knockout_presentation_mutated_state")
	_expect(game.arena_knockout_started == game.elapsed, "knockout_started")
	_expect(game.arena_knockout_world == Vector2(190, 0), "knockout_world")
	_expect(game.arena_knockout_killer_id == 0, "knockout_killer")
	_expect(_last_sfx() == GAG_KNOCKOUT, "knockout_gag_sound")

	var death_events: Array[Dictionary] = [{"kind":"player_died", "id":0, "at":Vector2.ZERO, "reason":"body"}]
	game._snakes_arena_dispatch(death_events)
	_expect(game.state == before, "death_presentation_mutated_state")
	_expect(game.arena_knockout_started == game.elapsed, "death_knockout_material_missing")
	_expect(game.arena_knockout_world == Vector2.ZERO, "death_knockout_world")
	_expect(_last_sfx(2) == GAG_KNOCKOUT, "death_gag_layer")
	_expect(_last_sfx() == game.SFX_SNAKE_CRASH, "death_crash_layer")


func _test_reduced_effects_truth() -> void:
	_open()
	game.snakes_reduced_effects = true
	game._sync_snakes_arena_state()
	var before: Dictionary = game.state.duplicate(true)
	var knockout_events: Array[Dictionary] = [{
		"kind":"bot_died", "id":1, "killer_id":0,
		"at":Vector2(120, 0), "reason":"fixture"
	}]
	game._snakes_arena_dispatch(knockout_events)
	_expect(game.state == before, "reduced_knockout_mutated_state")
	_expect(bool(game.state.get("reduced_effects", false)), "reduced_state_not_exposed")
	_expect(game.arena_fx.is_empty(), "reduced_particles_present")
	_expect(game.arena_camera_shake == Vector2.ZERO, "reduced_camera_shake_present")
	_expect(game.arena_knockout_started == game.elapsed, "reduced_semantic_marker_missing")
	var death_events: Array[Dictionary] = [{"kind":"player_died", "id":0, "at":Vector2.ZERO, "reason":"body"}]
	game._snakes_arena_dispatch(death_events)
	_expect(game.arena_result_ready_at == game.elapsed, "reduced_result_delayed")
	_expect(game.arena_knockout_world == Vector2.ZERO, "reduced_death_semantic_world")
	_expect(game.arena_fx.is_empty(), "reduced_death_particles_present")
	_expect(game.arena_camera_shake == Vector2.ZERO, "reduced_death_shake_present")
	game.snakes_reduced_effects = false


func _test_source_master_exclusion() -> void:
	for root_path in ["res://assets/art/snakes/gag-v2", "res://assets/audio/snakes/gag-v2"]:
		var directory := DirAccess.open(root_path)
		_expect(directory != null, "runtime_directory_missing")
		if directory == null:
			continue
		for file_name in directory.get_files():
			var lowered := file_name.to_lower()
			_expect(not "generated_images" in lowered, "source_master_shipped")
			_expect(not "_master" in lowered, "audio_master_shipped")
