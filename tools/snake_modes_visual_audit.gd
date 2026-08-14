extends SceneTree

## Deterministic visual audit for the two implemented Snake products.
##
## This script deliberately freezes the main Control's process loop after the
## home frame. Every gameplay step and every animation interval is advanced by
## this script, so a slow Xvfb/PNG capture cannot accidentally advance either
## model between frames.

const OUTPUT_DIR := "user://snake_modes_visual_audit"
const FIXED_DT := 1.0 / 60.0
const FIXED_SEED := 1362026

var game: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	# Let _ready build the real home scene and settle its one-time case reveal.
	await _wait_frames(40)
	game.set_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	game.has_transitioned = false
	await _save("00_home")

	await _capture_gb_sequence()
	await _capture_arena_sequence()

	print("SNAKE_MODES_VISUAL_AUDIT_DIR=%s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	quit()


func _capture_gb_sequence() -> void:
	await _prepare_gb()
	await _save("01_gb_baseline")

	# Accepted turn: request first, then consume exactly one deterministic tick.
	game._set_snake_direction(Vector2i.UP)
	game._snake_gb_step()
	await _advance_visual(0.08)
	await _save("02_gb_turn")

	# Place the food directly ahead of the head. The next tick emits `ate`; the
	# following tick materializes the queued growth, matching the GB model.
	await _prepare_gb()
	var gb_head: Vector2i = game.snake_gb_model.segments[0]
	game.snake_gb_model.food = gb_head + Vector2i.RIGHT
	game.snake_gb_model.foods.assign([game.snake_gb_model.food])
	game._sync_snake_gb_state()
	game._snake_gb_step()
	await _save("03_gb_eat")
	game._snake_gb_step()
	await _advance_visual(0.06)
	await _save("04_gb_growth")

	# Wall crash fixture: one deterministic step from x=14 facing right.
	await _prepare_gb()
	game.snake_gb_model.segments.assign([Vector2i(14, 8), Vector2i(13, 8), Vector2i(12, 8), Vector2i(11, 8)])
	game.snake_gb_model.direction = Vector2i.RIGHT
	game.snake_gb_model.turn_queue.clear()
	game.snake_gb_model.food = Vector2i(3, 3)
	game.snake_gb_model.foods.assign([game.snake_gb_model.food])
	game.snake_gb_model.score = game.snake_gb_model.segments.size()
	game._sync_snake_gb_state()
	game._snake_gb_step()
	await _advance_visual(0.09)
	await _save("05_gb_crash")
	await _advance_visual(0.64)
	await _save("06_gb_terminal")

	# Win fixture: construct 119 contiguous cells while leaving (1, 0) empty.
	# The first tick eats (1,0), the second tick materializes length 120.
	await _prepare_gb()
	var win_segments: Array[Vector2i] = []
	for column in range(game.snake_gb_model.width):
		var start_y: int = 0 if column == 0 else 1
		var end_y: int = int(game.snake_gb_model.height) - 1
		var step_y: int = 1
		if column % 2 == 1:
			start_y = game.snake_gb_model.height - 1
			end_y = 1
			step_y = -1
		var y: int = start_y
		while (y <= end_y if step_y > 0 else y >= end_y) and win_segments.size() < 119:
			win_segments.append(Vector2i(column, y))
			y += step_y
	game.snake_gb_model.segments = win_segments
	game.snake_gb_model.direction = Vector2i.RIGHT
	game.snake_gb_model.turn_queue.clear()
	game.snake_gb_model.food = Vector2i(1, 0)
	game.snake_gb_model.foods.assign([game.snake_gb_model.food])
	game.snake_gb_model.score = win_segments.size()
	game.snake_gb_model.pending_growth = 0
	game.snake_gb_model.phase = game.snake_gb_model.RUNNING
	game.snake_gb_model.terminal_reason = ""
	game._sync_snake_gb_state()
	game._snake_gb_step()
	game._snake_gb_step()
	await _advance_visual(0.76)
	await _save("07_gb_win")


func _capture_arena_sequence() -> void:
	await _prepare_arena()
	await _save("08_arena_baseline")

	# Continuous steering proof: one fixed tick shows the head banking first;
	# the following samples show curvature propagating through the soft body.
	game._snakes_arena_aim_at_screen(Vector2(270, 246))
	game.arena_pointer_active = true
	game.arena_pointer_screen = Vector2(270, 246)
	game._snakes_arena_update(FIXED_DT)
	await _save("09a_arena_steer_head")
	await _advance_visual(0.16)
	game._snakes_arena_update(0.16)
	await _save("09b_arena_steer_body")
	for _phase in range(2):
		await _advance_visual(0.18)
		game._snakes_arena_update(0.18)
	await _save("09_arena_steer")
	game._snakes_arena_end_pointer(Vector2(270, 246))

	# Own-body pass-through proof: the head overlaps a late body segment at the
	# center of a visible loop. The public step/snapshot contract must remain
	# playing, and the renderer must layer the head-side path above the tail.
	await _prepare_arena()
	game.snakes_arena_model.target_pellet_count = 0
	game.snakes_arena_model.pellets.clear()
	var self_path: Array[Vector2] = [
		Vector2(0, 0), Vector2(-25, 0), Vector2(-50, -10),
		Vector2(-68, -36), Vector2(-54, -65), Vector2(-22, -78),
		Vector2(12, -64), Vector2(30, -36), Vector2(22, -12),
		Vector2(0, 0), Vector2(28, 12), Vector2(58, 19), Vector2(88, 24)
	]
	var self_player: Dictionary = game.snakes_arena_model.snakes[0].duplicate(true)
	self_player["position"] = Vector2.ZERO
	self_player["previous_position"] = Vector2.ZERO
	self_player["segments"] = self_path
	self_player["heading"] = 0.0
	self_player["desired_point"] = Vector2.RIGHT * 300.0
	self_player["speed_scale"] = 0.0
	self_player["invulnerable"] = 0.0
	game.snakes_arena_model.snakes[0] = self_player
	for bot_index in range(1, game.snakes_arena_model.snakes.size()):
		_pose_arena_snake(bot_index, Vector2(720, -620 + bot_index * 48), PI, 24.0 + bot_index, 0.0)
	var self_events: Array[Dictionary] = game.snakes_arena_model.step(FIXED_DT)
	game._sync_snakes_arena_state()
	game.arena_camera = Vector2.ZERO
	game.arena_camera_previous = Vector2.ZERO
	var self_player_died := false
	for event in self_events:
		if str(event.get("kind", "")) == "player_died":
			self_player_died = true
	var self_snapshot: Dictionary = game.snakes_arena_model.snapshot()
	assert(str(self_snapshot.get("status", "")) == "playing")
	assert(bool(self_snapshot.get("player", {}).get("alive", false)))
	assert(not self_player_died)
	await _save("09c_arena_self_pass")

	# A single fixture pellet is reached during a 0.10 s fixed update.
	await _prepare_arena()
	game.snakes_arena_model.target_pellet_count = 1
	game.snakes_arena_model.pellets.assign([{
		"id":9001,
		"position":Vector2(9, 0),
		"value":4.5,
		"palette":1,
		"source":"audit_fixture"
	}])
	game._sync_snakes_arena_state()
	game._snakes_arena_update(0.10)
	await _save("10_arena_eat")

	# Hold boost through enough fixed ticks to show combustion and a shed pellet.
	await _prepare_arena()
	game._set_arena_boost(true)
	game._snakes_arena_update(0.20)
	await _advance_visual(0.04)
	await _save("11_arena_boost")

	# Deterministic competition fixture: the current leader dies, its path turns
	# into real model debris, a nearby bot visibly curves toward it and eats it,
	# while the authoritative leaderboard promotes the player to crown leader.
	await _prepare_arena()
	game.snakes_arena_model.target_pellet_count = 0
	game.snakes_arena_model.pellets.clear()
	_pose_arena_snake(0, Vector2.ZERO, 0.0, 92.0, 0.0)
	_pose_arena_snake(1, Vector2(190, 0), 0.0, 128.0, 0.0)
	_pose_arena_snake(2, Vector2(310, 90), 0.0, 84.0, 1.0)
	for bot_index in range(3, game.snakes_arena_model.snakes.size()):
		_pose_arena_snake(bot_index, Vector2(-610 + bot_index * 34, 510 - bot_index * 40), PI, 20.0 + bot_index, 0.0)
	game._sync_snakes_arena_state()
	game.arena_camera = Vector2.ZERO
	game.arena_camera_previous = Vector2.ZERO
	game.arena_rank_previous = 2
	await _save("12a_arena_bot_before")
	var bot_position := Vector2(190, 0)
	game.snakes_arena_model.kill_snake_for_test(1, "fixture")
	game._sync_snakes_arena_state()
	var bot_death_events: Array[Dictionary] = [{"kind":"bot_died", "id":1, "reason":"fixture", "killer_id":0, "at":bot_position}]
	game._snakes_arena_dispatch(bot_death_events)
	game.arena_rank_bump_until = game.elapsed + 0.58
	game.arena_leader_change_name = "你"
	game.arena_leader_change_until = game.elapsed + 1.18
	game.arena_float_labels.append({"world":Vector2.ZERO, "started":game.elapsed, "text":"位次 ↑ 1", "color":Color("ffe28a")})
	await _save("12b_arena_bot_death")
	await _advance_visual(0.20)
	game._snakes_arena_update(0.20)
	await _save("12c_arena_bot_chase")
	for _phase in range(3):
		await _advance_visual(0.20)
		game._snakes_arena_update(0.20)
	await _save("12_arena_bot_death")

	# Kill the player and send the exact player_died event through the real visual
	# dispatch, giving a coherent death FX + result timer without auto-updates.
	await _prepare_arena()
	game.snakes_arena_model.kill_snake_for_test(0, "body")
	game._sync_snakes_arena_state()
	var death_events: Array[Dictionary] = [{
		"kind":"player_died",
		"id":0,
		"reason":"body",
		"at":Vector2.ZERO
	}]
	game._snakes_arena_dispatch(death_events)
	await _advance_visual(0.08)
	await _save("13_arena_player_death")
	await _advance_visual(0.70)
	await _save("14_arena_terminal")

	# Exercise the actual restart entry point, then normalize its fixture so the
	# saved restart frame is a stable live arena rather than a transition frame.
	game._reset_current()
	_reset_arena_fixture()
	await _advance_visual(0.46)
	await _save("15_arena_restart")


func _prepare_gb() -> void:
	game._open_game("snake_classic")
	game.snake_gb_model.reset(FIXED_SEED)
	game._sync_snake_gb_state()
	game.snake_fx_kind = ""
	game.snake_pixels.clear()
	game.snake_float_labels.clear()
	game.snake_ghosts.clear()
	game.snake_result_ready_at = -1.0
	game.snake_lcd_flash_until = -1.0
	game.snake_score_bump_until = -1.0
	game.snake_button_until = -1.0
	game.snake_reject_until = -1.0
	game.snake_reset_started = -10.0
	game.snake_move_started = game.elapsed
	game.snake_clock = -100.0
	game.has_transitioned = false
	game.queue_redraw()
	await _wait_frames(1)


func _prepare_arena() -> void:
	game._open_game("snake_io")
	_reset_arena_fixture()
	game.has_transitioned = false
	game.queue_redraw()
	await _wait_frames(1)


func _reset_arena_fixture() -> void:
	game.snakes_arena_model.reset(FIXED_SEED, 5, 72)
	game.arena_pointer_active = false
	game.arena_aim_direction = Vector2.RIGHT
	game.arena_boost_active = false
	game.arena_fx.clear()
	game.arena_float_labels.clear()
	game.arena_result_ready_at = -1.0
	game.arena_rank_bump_until = -1.0
	game.arena_steer_started = -10.0
	game.arena_steer_until = -10.0
	game.arena_competition_until = -10.0
	game.arena_leader_change_until = -10.0
	game.arena_leader_change_name = ""
	game.arena_reset_started = -10.0
	game.arena_camera_shake = Vector2.ZERO
	game.arena_pointer_screen = Vector2(370, 493)
	game.arena_tutorial_dismissed = false
	game.arena_eat_started = -10.0
	game.arena_eat_world = Vector2.ZERO
	game.arena_eat_value = 0.0
	game._sync_snakes_arena_state()
	game.arena_camera = game._arena_player_world_position()
	game.arena_camera_previous = game.arena_camera
	game.arena_last_player_position = game.arena_camera


func _pose_arena_snake(index: int, position: Vector2, heading: float, mass: float, speed_scale: float) -> void:
	var snake: Dictionary = game.snakes_arena_model.snakes[index]
	var segment_count := maxi(12, snake.get("segments", []).size())
	var spacing := 14.0
	var backward := -Vector2.from_angle(heading)
	var segments: Array[Vector2] = []
	for segment_index in range(segment_count):
		segments.append(position + backward * spacing * float(segment_index))
	snake["position"] = position
	snake["previous_position"] = position
	snake["heading"] = heading
	snake["desired_point"] = position + Vector2.from_angle(heading) * 300.0
	snake["segments"] = segments
	snake["mass"] = mass
	snake["speed_scale"] = speed_scale
	snake["invulnerable"] = 4.0
	snake["decision_at"] = 0.0
	snake["state"] = "relaxed"
	game.snakes_arena_model.snakes[index] = snake
	game.queue_redraw()


func _advance_visual(seconds: float) -> void:
	var frames := maxi(1, int(round(seconds / FIXED_DT)))
	for _frame in range(frames):
		game.elapsed += FIXED_DT
		game.tick += 1
		game._snake_prune_fx()
		game._snakes_arena_prune_fx()
		game.queue_redraw()
		await process_frame


func _wait_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _save(stem: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := game.get_viewport().get_texture().get_image()
	var error := image.save_png("%s/%s.png" % [OUTPUT_DIR, stem])
	if error != OK:
		push_error("Snake modes visual audit capture failed: %s" % stem)
