extends SceneTree

const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const MEOW_GAG_REWARD: Texture2D = preload("res://assets/art/logic/gag-v1/meowdoku_paw_reward.png")
const MEOW_GAG_COMPLETE: AudioStream = preload("res://assets/audio/logic/gag-v1/meowdoku_complete_reward.ogg")
const REQUIRED_COPY := [
	"猫咪领地", "每行一猫", "每列一猫", "同色一猫", "标记为排除格", "擦去排除标记",
	"抱回这只猫", "找到猫咪", "这里没有猫", "失去一颗心", "爱心用尽", "全员到齐",
	"单击选格或标记", "双击放猫", "题面提示猫", "重开再试一次", "已恢复猫咪手账",
]

var game: Control
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.meowdoku_recovery_enabled = false
	root.add_child(game)
	await process_frame
	_test_font_role()
	_test_gag_resources()
	_test_stable_identity()
	_test_selection_and_mark()
	_test_routine_cat()
	_test_error_and_loss()
	_test_given_and_erase()
	_test_completion_peak()
	_test_reduced_effects()
	print("MEOWDOKU_ART_SMOKE=%d" % assertions)
	print("MEOWDOKU_ART_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _test_font_role() -> void:
	for copy in REQUIRED_COPY:
		for index in range(copy.length()):
			_expect(UI_FONT.has_char(copy.unicode_at(index)), "font_U+%04X" % copy.unicode_at(index))


func _test_gag_resources() -> void:
	_expect(MEOW_GAG_REWARD.get_size() == Vector2(331, 297), "gag_texture_dimensions")
	_expect(MEOW_GAG_REWARD.get_image().detect_alpha() != Image.ALPHA_NONE, "gag_texture_alpha")
	_expect(MEOW_GAG_COMPLETE.get_length() >= 0.90, "gag_audio_duration")
	_expect(MEOW_GAG_REWARD.resource_path == "res://assets/art/logic/gag-v1/meowdoku_paw_reward.png", "gag_runtime_image_path")


func _test_stable_identity() -> void:
	game._open_game("meowdoku")
	_expect(game.state.puzzle_id == "notebook_5" and int(game.state.size) == 5, "stable_region_puzzle")
	_expect(game.state.regions.size() == 5 and int(game.state.required) == 5, "stable_region_state")
	_expect(int(game.state.hearts) == 3 and int(game.state.placed) == 0, "stable_hud")
	var presenter: Dictionary = game.meowdoku_presenter.snapshot(game.elapsed)
	_expect(presenter.gag_texture == "res://assets/art/logic/gag-v1/meowdoku_paw_reward.png", "stable_gag_role")
	_expect(presenter.font_role == "ui_cjk", "stable_font_role")
	_expect(game._meowdoku_board_rect() == game.meowdoku_presenter.board_rect(), "board_contact_contract")


func _test_selection_and_mark() -> void:
	game._open_game("meowdoku")
	var target := Vector2i(2, 2)
	var before: Dictionary = game.meowdoku_model.checkpoint()
	var selected: Dictionary = game._meowdoku_command("select", target)
	_expect(selected.event == "select" and game.state.selected == [2, 2], "selection_state")
	_expect(game.meowdoku_model.cats.is_empty() and int(game.state.hearts) == int(before.hearts), "selection_no_rule_delta")
	var marked: Dictionary = game._meowdoku_command("mark", target)
	_expect(marked.event == "mark" and [2, 2] in game.state.manual_marks, "mark_state")
	_expect_event("cat_mark", 1, "排除")
	_expect_presenter("mark", target)
	var unmarked: Dictionary = game._meowdoku_command("mark", target)
	_expect(unmarked.event == "unmark" and [2, 2] not in game.state.manual_marks, "unmark_state")


func _test_routine_cat() -> void:
	game._open_game("meowdoku")
	var target: Vector2i = game.meowdoku_model.solution[0]
	var result: Dictionary = game._meowdoku_command("cat", target)
	_expect(result.event == "cat" and [target.x, target.y] in game.state.cats, "cat_authoritative_state")
	_expect(int(game.state.placed) == 1 and int(game.state.hearts) == 3, "cat_progress")
	_expect(game.state.derived_marks.size() > 0, "cat_derived_exclusions")
	_expect_event("cat_found", 2, "找到猫咪")
	_expect_presenter("cat", target)
	var presenter: Dictionary = game.meowdoku_presenter.snapshot(game.elapsed)
	_expect(presenter.gag_texture == "res://assets/art/logic/gag-v1/meowdoku_paw_reward.png", "ordinary_gag_stamp_route")


func _test_error_and_loss() -> void:
	game._open_game("meowdoku")
	var wrong := Vector2i.ZERO
	if wrong in game.meowdoku_model.solution:
		wrong = Vector2i(1, 0)
	var before_cats: Array = game.state.cats.duplicate(true)
	var error: Dictionary = game._meowdoku_command("cat", wrong)
	_expect(error.event == "error" and int(game.state.hearts) == 2, "error_heart")
	_expect(game.state.cats == before_cats, "error_no_cat_mutation")
	_expect_event("cat_error", 2, "失去一颗心")
	_expect_presenter("error", wrong)
	game._meowdoku_command("cat", wrong)
	var loss: Dictionary = game._meowdoku_command("cat", wrong)
	_expect(loss.event == "loss" and game.state.status == "lost", "loss_status")
	_expect_event("cat_loss", 3, "爱心用尽")
	_expect_presenter("loss", wrong)


func _test_given_and_erase() -> void:
	game.meowdoku_fixture_id = "patchwork_7"
	game._open_game("meowdoku")
	var given: Vector2i = game.meowdoku_model.given_cats[0]
	_expect(game._meowdoku_command("erase", given).event == "given", "given_erase_blocked")
	_expect(game._meowdoku_command("mark", given).event == "given", "given_mark_blocked")
	var target: Vector2i = game.meowdoku_model.solution[1]
	game._meowdoku_command("cat", target)
	_expect(game._meowdoku_command("erase", target).event == "erase_cat", "placed_cat_erase")
	_expect([target.x, target.y] not in game.state.cats and [given.x, given.y] in game.state.cats, "erase_preserves_given")
	_expect_event("cat_erase", 1, "抱回猫咪")
	game.meowdoku_fixture_id = "notebook_5"


func _test_completion_peak() -> void:
	game._open_game("meowdoku")
	for cell in game.meowdoku_model.solution:
		game._meowdoku_command("cat", cell)
	_expect(game.state.status == "won" and int(game.state.placed) == int(game.state.required), "completion_state")
	_expect_event("cat_complete", 4, "全员到齐")
	_expect_presenter("complete", game.meowdoku_model.solution[-1])
	_expect(_audio_stream_was_routed("res://assets/audio/logic/gag-v1/meowdoku_complete_reward.ogg"), "gag_completion_audio_route")


func _test_reduced_effects() -> void:
	game._set_reduced_effects(true)
	game._open_game("meowdoku")
	var target: Vector2i = game.meowdoku_model.solution[0]
	game._meowdoku_command("cat", target)
	_expect([target.x, target.y] in game.state.cats, "reduced_preserves_state")
	_expect(game._catalog_shake_offset() == Vector2.ZERO, "reduced_disables_shake")
	_expect(game.reduced_effects, "reduced_flag")
	_expect_presenter("cat", target)
	game._set_reduced_effects(false)


func _audio_stream_was_routed(expected_path: String) -> bool:
	for player_variant in game.sfx_players:
		var player: AudioStreamPlayer = player_variant
		if player.stream != null and player.stream.resource_path == expected_path:
			return true
	return false


func _expect_event(kind: String, grade: int, label: String) -> void:
	if game.catalog_fx.is_empty():
		_expect(false, "%s_event_missing" % kind)
		return
	var effect: Dictionary = game.catalog_fx.back()
	_expect(str(effect.get("game_id", "")) == "meowdoku", "%s_event_game" % kind)
	_expect(str(effect.get("kind", "")) == kind, "%s_event_kind" % kind)
	_expect(int(effect.get("grade", 0)) == grade, "%s_event_importance" % kind)
	_expect(str(effect.get("label", "")) == label, "%s_event_label" % kind)
	_expect(str(effect.get("font_role", "")) == "ui_cjk", "%s_event_font" % kind)


func _expect_presenter(kind: String, cell: Vector2i) -> void:
	var presenter: Dictionary = game.meowdoku_presenter.snapshot(game.elapsed)
	_expect(str(presenter.get("event", "")) == kind, "%s_presenter_kind" % kind)
	_expect(presenter.get("event_cell", []) == [cell.x, cell.y], "%s_presenter_cell" % kind)


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
