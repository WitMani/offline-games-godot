extends SceneTree

const FOX_PATH := "res://assets/art/catalog/path_games/gag/arrow_go_fox_center_gag_v3.png"
const ESCAPE_PATH := "res://assets/audio/catalog/path_games/gag/arrow_go_arrow_escape_gag_v3.ogg"
const REVEAL_PATH := "res://assets/audio/catalog/path_games/gag/arrow_go_fox_reveal_gag_v3.ogg"
const FOX_SHA := "9e19d9af49091876c2cbb7d19aa86f521f7998b3a14e09a3159164f6dcc16f2b"
const ESCAPE_SHA := "ae236ab82a2cb2ac252b3f5124d4c2759b93008696b9b75655d879425371c1e6"
const REVEAL_SHA := "67520ae739f20fd223e8b03cdd8c22fe620471ffe5e5630cd10fb0a351b85fdc"
const SOLUTION: Array[String] = ["b", "a", "d", "c", "k", "g", "f", "l", "i", "e", "j", "h"]

var game: Control
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._arrow_go_clear_recovery()
	_test_gag_runtime_derivatives()
	_test_stable_binding()
	_test_feedback_hierarchy()
	_test_reduced_effects()
	game._arrow_go_clear_recovery()
	print("ARROW_GO_ART_ASSERTIONS=%d" % assertions)
	print("ARROW_GO_ART_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)


func _open() -> void:
	game._open_game("arrow_go")
	game._reset_current()
	game.catalog_fx.clear()
	game.arrow_go_object_fx = {}


func _last_event() -> Dictionary:
	return {} if game.catalog_fx.is_empty() else game.catalog_fx.back()


func _test_gag_runtime_derivatives() -> void:
	_expect(FileAccess.get_sha256(FOX_PATH) == FOX_SHA, "fox_hash")
	_expect(FileAccess.get_sha256(ESCAPE_PATH) == ESCAPE_SHA, "escape_hash")
	_expect(FileAccess.get_sha256(REVEAL_PATH) == REVEAL_SHA, "reveal_hash")
	var fox_texture: Texture2D = load(FOX_PATH)
	var image := fox_texture.get_image()
	_expect(image.get_width() == 256 and image.get_height() == 256, "fox_dimensions")
	_expect(image.get_format() in [Image.FORMAT_RGBA8, Image.FORMAT_RGBAF, Image.FORMAT_RGBAH], "fox_alpha_format")
	_expect(image.get_pixel(0, 0).a < 0.02 and image.get_pixel(128, 128).a > 0.95, "fox_alpha_content")
	var escape: AudioStream = load(ESCAPE_PATH)
	var reveal: AudioStream = load(REVEAL_PATH)
	_expect(escape != null and absf(escape.get_length() - 0.497646) < 0.02, "escape_duration")
	_expect(reveal != null and absf(reveal.get_length() - 0.986188) < 0.02, "reveal_duration")


func _test_stable_binding() -> void:
	_open()
	_expect(game.ARROW_GO_GAG_FOX_TEXTURE.resource_path == FOX_PATH, "fox_preload")
	_expect(game.SFX_ARROW_GO_GAG_ESCAPE.resource_path == ESCAPE_PATH, "escape_preload")
	_expect(game.SFX_ARROW_GO_GAG_REVEAL.resource_path == REVEAL_PATH, "reveal_preload")
	_expect(int(game.state.get("remaining", 0)) == 12, "stable_remaining")
	_expect(game.arrow_go_model.live_ids().size() == 12, "stable_arrow_family")
	_expect(game._arrow_go_board_rect().has_point(game._arrow_go_board_rect().get_center()), "stable_center_role")
	var preset_text := FileAccess.get_file_as_string("res://export_presets.cfg")
	_expect("arrow_go_*_gag_v1.png" in preset_text and "arrow_go_*_gag_v1.ogg" in preset_text, "legacy_assets_export_excluded")


func _test_feedback_hierarchy() -> void:
	_open()
	var before: Dictionary = game.state.duplicate(true)
	game._arrow_go_attempt("a", "art_probe")
	_expect(game.state.get("removed_ids", []) == before.get("removed_ids", []), "reject_atomic")
	_expect(str(game.arrow_go_object_fx.get("kind", "")) == "blocked", "reject_object")
	_expect(str(_last_event().get("kind", "")) == "arrow_reject" and int(_last_event().get("grade", 0)) == 2, "reject_event")
	var turn: Dictionary = game._arrow_go_attempt("b", "art_probe")
	_expect(str(turn.kind) == "turn_escape" and int(turn.grade) == 2, "turn_grade")
	_expect(game._catalog_event_sfx("arrow_turn_escape", 2) == game.SFX_ARROW_GO_GAG_ESCAPE, "turn_gag_audio_route")
	game._arrow_go_attempt("a", "art_probe")
	_expect(str(_last_event().get("kind", "")) == "arrow_escape" and int(_last_event().get("grade", 0)) == 1, "routine_grade")
	for index in range(2, SOLUTION.size()):
		game._arrow_go_attempt(SOLUTION[index], "art_probe")
		if index in [3, 7]:
			_expect(str(_last_event().get("kind", "")) == "arrow_waypoint", "waypoint_kind_%d" % index)
		if index in [9, 10]:
			_expect(str(_last_event().get("kind", "")) == "arrow_near_clear" and int(_last_event().get("grade", 0)) == 3, "near_grade_%d" % index)
	_expect(str(_last_event().get("kind", "")) == "arrow_win" and int(_last_event().get("grade", 0)) == 4, "win_grade")
	_expect(game._catalog_event_sfx("arrow_win", 4) == game.SFX_ARROW_GO_GAG_REVEAL, "win_gag_audio_route")
	_expect(str(game.state.get("status", "")) == "won" and int(game.state.get("remaining", -1)) == 0, "win_authority")


func _test_reduced_effects() -> void:
	_open()
	game._arrow_go_set_reduced_effects(true)
	game._arrow_go_attempt("b", "art_probe")
	_expect(bool(game.state.get("reduced_effects", false)), "reduced_state")
	_expect(game._catalog_shake_offset() == Vector2.ZERO, "reduced_shake")
	_expect(game.state.get("removed_ids", []) == ["b"], "reduced_authority")
	_expect(str(game.arrow_go_object_fx.get("kind", "")) == "turn_escape", "reduced_semantic_event")
	game._arrow_go_set_reduced_effects(false)
