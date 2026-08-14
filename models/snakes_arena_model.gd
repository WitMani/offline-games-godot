class_name SnakesArenaModel
extends RefCounted

## Deterministic, presentation-free continuous arena simulation inspired by
## Offline Games' separate `136_SNAKES` product contract.  It deliberately
## shares no grid movement rules with GB Snake / Snake2.

const RUNNING := "running"
const LOST := "lost"
const FIXED_DT := 1.0 / 60.0
const PLAYER_ID := 0
const BOT_NAMES := ["MICA", "RUNE", "TAVI", "NORI", "KITE", "PIP", "ZEST", "LOOP"]

var arena_radius := 920.0
var base_speed := 108.0
var boost_multiplier := 1.62
var maximum_turn_speed := 3.0
var minimum_boost_mass := 22.0
var boost_mass_cost_per_second := 5.6
var target_pellet_count := 96
var maximum_pellet_count := 180
var player_index := 0
var player_id := PLAYER_ID

var phase := RUNNING
var terminal_reason := ""
var elapsed := 0.0
var tick := 0
var accumulator := 0.0
var snakes: Array[Dictionary] = []
var pellets: Array[Dictionary] = []
var player_aim := Vector2.RIGHT * 400.0
var player_boost_requested := false
var rng := RandomNumberGenerator.new()
var next_pellet_id := 1


func reset(seed: int, bot_count: int = 5, pellet_count: int = 96) -> void:
	rng.seed = seed
	phase = RUNNING
	terminal_reason = ""
	elapsed = 0.0
	tick = 0
	accumulator = 0.0
	player_index = 0
	player_id = PLAYER_ID
	player_aim = Vector2.RIGHT * 400.0
	player_boost_requested = false
	next_pellet_id = 1
	target_pellet_count = clampi(pellet_count, 0, maximum_pellet_count)
	snakes.clear()
	pellets.clear()
	snakes.append(_make_snake(PLAYER_ID, false, Vector2.ZERO, 0.0, 38.0, 0))
	for bot_index in range(bot_count):
		var angle := TAU * float(bot_index) / maxf(1.0, float(bot_count)) + 0.55
		var distance := 310.0 + float((bot_index * 97) % 250)
		var position := Vector2.from_angle(angle) * distance
		var heading := wrapf(angle + PI * 0.72, -PI, PI)
		var mass := 30.0 + float((bot_index * 17) % 38)
		snakes.append(_make_snake(bot_index + 1, true, position, heading, mass, (bot_index + 1) % 8))
	_refill_pellets()


func set_player_aim(world_point: Vector2) -> void:
	player_aim = world_point


func set_player_boost(active: bool) -> void:
	player_boost_requested = active


func step(delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if delta <= 0.0:
		return events
	accumulator += minf(delta, 0.25)
	while accumulator + 0.0000001 >= FIXED_DT:
		accumulator -= FIXED_DT
		events.append_array(_fixed_step(FIXED_DT))
	return events


func kill_snake_for_test(index: int, reason: String) -> void:
	if index < 0 or index >= snakes.size():
		return
	_kill_snake(index, reason, -1, [])


func _fixed_step(delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	elapsed += delta
	tick += 1
	for snake_index in range(snakes.size()):
		var snake: Dictionary = snakes[snake_index]
		if not bool(snake.get("alive", false)):
			if bool(snake.get("is_bot", false)) and elapsed >= float(snake.get("respawn_at", INF)):
				_respawn_bot(snake_index)
				events.append({"kind":"bot_respawned", "id":int(snakes[snake_index]["id"])})
			continue
		if float(snake.get("invulnerable", 0.0)) > 0.0:
			snake["invulnerable"] = maxf(0.0, float(snake["invulnerable"]) - delta)
		if bool(snake.get("is_bot", false)):
			_update_bot_intent(snake_index)
			snake = snakes[snake_index]
		else:
			snake["desired_point"] = player_aim
			snake["boost_requested"] = player_boost_requested
		snakes[snake_index] = snake
		events.append_array(_advance_snake(snake_index, delta))
	_prune_pellets()
	if phase == RUNNING:
		events.append_array(_resolve_collisions())
		if phase == RUNNING:
			events.append_array(_resolve_food_pickups())
	_refill_pellets()
	return events


func _make_snake(id: int, is_bot: bool, position: Vector2, heading: float, mass: float, skin: int) -> Dictionary:
	var segment_count := _segment_count_for_mass(mass)
	var segments: Array[Vector2] = []
	var backward := -Vector2.from_angle(heading)
	for segment_index in range(segment_count):
		segments.append(position + backward * _segment_spacing(mass) * float(segment_index))
	return {
		"id":id,
		"name":"YOU" if not is_bot else BOT_NAMES[(id - 1) % BOT_NAMES.size()],
		"is_bot":is_bot,
		"alive":true,
		"position":position,
		"previous_position":position,
		"heading":heading,
		"desired_point":position + Vector2.from_angle(heading) * 300.0,
		"segments":segments,
		"mass":mass,
		"skin":skin,
		"boost_requested":false,
		"boosting":false,
		"boost_shed_clock":0.0,
		"boost_reject_latched":false,
		"speed_scale":1.0,
		"invulnerable":1.15,
		"respawn_at":INF,
		"decision_at":0.0,
		"state":"relaxed"
	}


func _advance_snake(index: int, delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var snake: Dictionary = snakes[index]
	var speed_scale := float(snake.get("speed_scale", 1.0))
	if speed_scale <= 0.0:
		snakes[index] = snake
		return events
	var position: Vector2 = snake["position"]
	var desired_point: Vector2 = snake.get("desired_point", position + Vector2.RIGHT)
	var desired_vector := desired_point - position
	if desired_vector.length_squared() < 0.0001:
		desired_vector = Vector2.from_angle(float(snake["heading"]))
	var desired_heading := desired_vector.angle()
	var old_heading := float(snake["heading"])
	var turn_delta := wrapf(desired_heading - old_heading, -PI, PI)
	var max_turn := maximum_turn_speed * delta
	var new_heading := old_heading + clampf(turn_delta, -max_turn, max_turn)
	snake["heading"] = wrapf(new_heading, -PI, PI)
	if index == player_index and absf(turn_delta) > 0.002:
		events.append({"kind":"player_steered", "heading":float(snake["heading"]), "turn":clampf(turn_delta, -max_turn, max_turn)})

	var wants_boost := bool(snake.get("boost_requested", false))
	var has_boost_mass := float(snake["mass"]) > minimum_boost_mass
	var was_boosting := bool(snake.get("boosting", false))
	var boosting := wants_boost and has_boost_mass
	if wants_boost and not has_boost_mass:
		if not bool(snake.get("boost_reject_latched", false)):
			events.append({"kind":"boost_rejected", "id":int(snake["id"]), "reason":"low_mass"})
		snake["boost_reject_latched"] = true
	else:
		snake["boost_reject_latched"] = false
	if boosting and not was_boosting:
		events.append({"kind":"boost_started", "id":int(snake["id"])})
	elif was_boosting and not boosting:
		events.append({"kind":"boost_stopped", "id":int(snake["id"])})
	snake["boosting"] = boosting
	if boosting:
		snake["mass"] = maxf(minimum_boost_mass, float(snake["mass"]) - boost_mass_cost_per_second * delta)
		snake["boost_shed_clock"] = float(snake.get("boost_shed_clock", 0.0)) + delta
		if float(snake["boost_shed_clock"]) >= 0.12:
			snake["boost_shed_clock"] = float(snake["boost_shed_clock"]) - 0.12
			var segments: Array = snake["segments"]
			var tail: Vector2 = segments.back() if not segments.is_empty() else position
			var pellet := _spawn_pellet_at(tail, 0.72, 2, "boost")
			events.append({"kind":"boost_shed", "id":int(snake["id"]), "pellet_id":int(pellet["id"]), "at":tail})
	else:
		snake["boost_shed_clock"] = 0.0

	var movement_speed := base_speed * speed_scale * (boost_multiplier if boosting else 1.0)
	snake["previous_position"] = position
	position += Vector2.from_angle(float(snake["heading"])) * movement_speed * delta
	snake["position"] = position
	_update_segments(snake)
	snakes[index] = snake
	return events


func _update_segments(snake: Dictionary) -> void:
	var segments: Array = snake["segments"]
	var wanted_count := _segment_count_for_mass(float(snake["mass"]))
	var spacing := _segment_spacing(float(snake["mass"]))
	if segments.is_empty():
		segments.append(snake["position"])
	segments[0] = snake["position"]
	while segments.size() < wanted_count:
		var tail: Vector2 = segments.back()
		var before_tail: Vector2 = segments[segments.size() - 2] if segments.size() >= 2 else tail - Vector2.from_angle(float(snake["heading"]))
		var tail_direction := (tail - before_tail).normalized()
		if tail_direction == Vector2.ZERO:
			tail_direction = -Vector2.from_angle(float(snake["heading"]))
		segments.append(tail + tail_direction * spacing)
	while segments.size() > wanted_count:
		segments.pop_back()
	for segment_index in range(1, segments.size()):
		var previous: Vector2 = segments[segment_index - 1]
		var current: Vector2 = segments[segment_index]
		var delta_to_current := current - previous
		if delta_to_current.length_squared() < 0.0001:
			delta_to_current = -Vector2.from_angle(float(snake["heading"]))
		segments[segment_index] = previous + delta_to_current.normalized() * spacing
	snake["segments"] = segments


func _update_bot_intent(index: int) -> void:
	var snake: Dictionary = snakes[index]
	var position: Vector2 = snake["position"]
	if elapsed < float(snake.get("decision_at", 0.0)):
		return
	snake["decision_at"] = elapsed + 0.24 + rng.randf_range(0.0, 0.22)
	var desired := position + Vector2.from_angle(float(snake["heading"])) * 260.0
	var best_distance := INF
	var debris_distance := INF
	var debris_target := Vector2.ZERO
	for pellet in pellets:
		var pellet_position: Vector2 = pellet["position"]
		var distance_squared := position.distance_squared_to(pellet_position)
		if distance_squared < best_distance:
			best_distance = distance_squared
			desired = pellet_position
		if str(pellet.get("source", "ambient")) == "debris" and distance_squared < debris_distance:
			debris_distance = distance_squared
			debris_target = pellet_position
	snake["state"] = "foraging"
	snake["boost_requested"] = false
	var scavenging := debris_distance < 420.0 * 420.0
	if scavenging:
		desired = debris_target
		snake["state"] = "scavenging"
		snake["boost_requested"] = sqrt(debris_distance) > 135.0 and float(snake["mass"]) > minimum_boost_mass + 8.0
	var player: Dictionary = snakes[player_index]
	if not scavenging and bool(player.get("alive", false)):
		var player_position: Vector2 = player["position"]
		var player_distance := position.distance_to(player_position)
		if float(snake["mass"]) > float(player["mass"]) * 1.12 and player_distance < 310.0:
			desired = player_position + Vector2.from_angle(float(player["heading"])) * 42.0
			snake["state"] = "chasing"
			snake["boost_requested"] = player_distance > 135.0 and float(snake["mass"]) > minimum_boost_mass + 8.0
		else:
			snake["state"] = "foraging"
	if position.length() > arena_radius * 0.76:
		desired = -position.normalized() * arena_radius * 0.18
		snake["state"] = "avoiding"
		snake["boost_requested"] = false
	snake["desired_point"] = desired
	snakes[index] = snake


func _resolve_food_pickups() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for pellet_index in range(pellets.size() - 1, -1, -1):
		var pellet: Dictionary = pellets[pellet_index]
		var pellet_position: Vector2 = pellet["position"]
		var winner_index := -1
		var winner_distance := INF
		var winner_id := 2147483647
		for snake_index in range(snakes.size()):
			var candidate: Dictionary = snakes[snake_index]
			if not bool(candidate.get("alive", false)):
				continue
			var pickup_radius := _head_radius(float(candidate["mass"])) + 7.0
			var distance_squared := Vector2(candidate["position"]).distance_squared_to(pellet_position)
			var candidate_id := int(candidate["id"])
			if distance_squared <= pickup_radius * pickup_radius and (distance_squared < winner_distance or (is_equal_approx(distance_squared, winner_distance) and candidate_id < winner_id)):
				winner_index = snake_index
				winner_distance = distance_squared
				winner_id = candidate_id
		if winner_index < 0:
			continue
		var winner: Dictionary = snakes[winner_index]
		var value := float(pellet.get("value", 1.0))
		winner["mass"] = float(winner["mass"]) + value
		snakes[winner_index] = winner
		pellets.remove_at(pellet_index)
		var kind := "player_ate" if winner_index == player_index else "bot_ate"
		events.append({"kind":kind, "id":int(winner["id"]), "pellet_id":int(pellet["id"]), "value":value, "at":pellet_position, "mass":float(winner["mass"])})
	return events


func _resolve_collisions() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var pending_reason: Array[String] = []
	var pending_killer: Array[int] = []
	for _index in range(snakes.size()):
		pending_reason.append("")
		pending_killer.append(-1)
	for snake_index in range(snakes.size()):
		var snake: Dictionary = snakes[snake_index]
		if not bool(snake.get("alive", false)) or float(snake.get("invulnerable", 0.0)) > 0.0:
			continue
		var head: Vector2 = snake["position"]
		if head.length() > arena_radius - _head_radius(float(snake["mass"])):
			pending_reason[snake_index] = "boundary"
	for first_index in range(snakes.size()):
		var first: Dictionary = snakes[first_index]
		if not bool(first.get("alive", false)) or float(first.get("invulnerable", 0.0)) > 0.0 or pending_reason[first_index] == "boundary":
			continue
		for second_index in range(first_index + 1, snakes.size()):
			var second: Dictionary = snakes[second_index]
			if not bool(second.get("alive", false)) or float(second.get("invulnerable", 0.0)) > 0.0 or pending_reason[second_index] == "boundary":
				continue
			var first_head: Vector2 = first["position"]
			var second_head: Vector2 = second["position"]
			var contact_distance := (_head_radius(float(first["mass"])) + _head_radius(float(second["mass"]))) * 0.78
			if first_head.distance_squared_to(second_head) > contact_distance * contact_distance:
				continue
			var first_mass := float(first["mass"])
			var second_mass := float(second["mass"])
			if first_mass > second_mass * 1.08:
				pending_reason[second_index] = "head"
				pending_killer[second_index] = int(first["id"])
			elif second_mass > first_mass * 1.08:
				pending_reason[first_index] = "head"
				pending_killer[first_index] = int(second["id"])
			else:
				pending_reason[first_index] = "head"
				pending_reason[second_index] = "head"
				pending_killer[first_index] = int(second["id"])
				pending_killer[second_index] = int(first["id"])
	for snake_index in range(snakes.size()):
		if not pending_reason[snake_index].is_empty():
			_kill_snake(snake_index, pending_reason[snake_index], pending_killer[snake_index], events)
	var body_reason: Array[String] = []
	var body_killer: Array[int] = []
	for _index in range(snakes.size()):
		body_reason.append("")
		body_killer.append(-1)
	for snake_index in range(snakes.size()):
		var snake: Dictionary = snakes[snake_index]
		if not bool(snake.get("alive", false)) or float(snake.get("invulnerable", 0.0)) > 0.0:
			continue
		var head: Vector2 = snake["position"]
		var head_radius := _head_radius(float(snake["mass"]))
		var collided := false
		for other_index in range(snakes.size()):
			if other_index == snake_index:
				continue
			var other: Dictionary = snakes[other_index]
			if not bool(other.get("alive", false)) or float(other.get("invulnerable", 0.0)) > 0.0:
				continue
			var segments: Array = other["segments"]
			for segment_index in range(2, segments.size()):
				var body_point: Vector2 = segments[segment_index]
				var body_radius := _body_radius(float(other["mass"]))
				if _swept_point_distance(snake["previous_position"], head, body_point) <= head_radius + body_radius * 0.78:
					body_reason[snake_index] = "body"
					body_killer[snake_index] = int(other["id"])
					collided = true
					break
			if collided:
				break
	for snake_index in range(snakes.size()):
		if not body_reason[snake_index].is_empty():
			_kill_snake(snake_index, body_reason[snake_index], body_killer[snake_index], events)
	return events


func _prune_pellets() -> void:
	for pellet_index in range(pellets.size() - 1, -1, -1):
		var pellet: Dictionary = pellets[pellet_index]
		var source := str(pellet.get("source", "ambient"))
		var lifetime := 12.0 if source == "boost" else (18.0 if source == "debris" else 42.0)
		if elapsed - float(pellet.get("born_at", 0.0)) >= lifetime:
			pellets.remove_at(pellet_index)
	var cap := maximum_pellet_count
	while pellets.size() > cap:
		var candidate := -1
		var oldest := INF
		for pellet_index in range(pellets.size()):
			var pellet: Dictionary = pellets[pellet_index]
			if str(pellet.get("source", "ambient")) == "debris":
				continue
			var born_at := float(pellet.get("born_at", 0.0))
			if born_at < oldest:
				oldest = born_at
				candidate = pellet_index
		if candidate < 0:
			candidate = 0
		pellets.remove_at(candidate)


func _kill_snake(index: int, reason: String, killer_id: int, events: Array) -> void:
	if index < 0 or index >= snakes.size():
		return
	var snake: Dictionary = snakes[index]
	if not bool(snake.get("alive", false)):
		return
	snake["alive"] = false
	snake["boosting"] = false
	snake["boost_requested"] = false
	snake["respawn_at"] = elapsed + 2.6 if bool(snake.get("is_bot", false)) else INF
	var segments: Array = snake["segments"]
	var dropped := 0
	for segment_index in range(0, segments.size(), 2):
		var value := 1.4 + minf(2.6, float(snake["mass"]) / maxf(1.0, float(segments.size())) * 0.42)
		_spawn_pellet_at(segments[segment_index], value, int(snake["skin"]) % 5, "debris")
		dropped += 1
	snakes[index] = snake
	events.append({"kind":"debris_dropped", "id":int(snake["id"]), "count":dropped, "reason":reason})
	if index == player_index:
		phase = LOST
		terminal_reason = reason
		events.append({"kind":"player_died", "id":int(snake["id"]), "reason":reason, "killer_id":killer_id, "at":snake["position"]})
	else:
		events.append({"kind":"bot_died", "id":int(snake["id"]), "reason":reason, "killer_id":killer_id, "at":snake["position"]})


func _respawn_bot(index: int) -> void:
	var old: Dictionary = snakes[index]
	var angle := rng.randf_range(0.0, TAU)
	var distance := rng.randf_range(220.0, arena_radius * 0.64)
	var fresh := _make_snake(int(old["id"]), true, Vector2.from_angle(angle) * distance, angle + PI, 28.0 + rng.randf_range(0.0, 22.0), int(old["skin"]))
	snakes[index] = fresh


func _refill_pellets() -> void:
	var bounded_target := clampi(target_pellet_count, 0, maximum_pellet_count)
	target_pellet_count = bounded_target
	while pellets.size() < bounded_target:
		_spawn_random_pellet()


func _spawn_random_pellet() -> void:
	for _attempt in range(80):
		var angle := rng.randf_range(0.0, TAU)
		var distance := sqrt(rng.randf()) * (arena_radius - 44.0)
		var candidate := Vector2.from_angle(angle) * distance
		if _pellet_position_is_free(candidate):
			_spawn_pellet_at(candidate, rng.randf_range(1.0, 2.6), rng.randi_range(0, 4), "ambient")
			return
	var fallback_angle := float(next_pellet_id % 31) / 31.0 * TAU
	var fallback_distance := 180.0 + float((next_pellet_id * 43) % 620)
	_spawn_pellet_at(Vector2.from_angle(fallback_angle) * fallback_distance, 1.0, next_pellet_id % 5, "ambient")


func _spawn_pellet_at(position: Vector2, value: float, palette: int, source: String) -> Dictionary:
	while pellets.size() >= maximum_pellet_count:
		var candidate := -1
		var oldest := INF
		for pellet_index in range(pellets.size()):
			var existing: Dictionary = pellets[pellet_index]
			if str(existing.get("source", "ambient")) == "debris":
				continue
			var born_at := float(existing.get("born_at", 0.0))
			if born_at < oldest:
				oldest = born_at
				candidate = pellet_index
		if candidate < 0:
			candidate = 0
		pellets.remove_at(candidate)
	var pellet := {"id":next_pellet_id, "position":position, "value":value, "palette":palette, "source":source, "born_at":elapsed}
	next_pellet_id += 1
	pellets.append(pellet)
	return pellet


func _pellet_position_is_free(position: Vector2) -> bool:
	for snake in snakes:
		var segments: Array = snake.get("segments", [])
		for segment in segments:
			if position.distance_squared_to(segment) < 38.0 * 38.0:
				return false
	for pellet in pellets:
		if position.distance_squared_to(pellet["position"]) < 12.0 * 12.0:
			return false
	return true


func _swept_point_distance(from: Vector2, to: Vector2, point: Vector2) -> float:
	var line := to - from
	var length_squared := line.length_squared()
	if length_squared <= 0.0001:
		return from.distance_to(point)
	var projection := clampf((point - from).dot(line) / length_squared, 0.0, 1.0)
	return (from + line * projection).distance_to(point)


func _segment_count_for_mass(mass: float) -> int:
	return clampi(int(round(8.0 + mass * 0.24)), 10, 72)


func _segment_spacing(mass: float) -> float:
	return 11.5 + minf(3.5, sqrt(maxf(0.0, mass)) * 0.24)


func _head_radius(mass: float) -> float:
	return 22.0 + minf(10.0, sqrt(maxf(0.0, mass)) * 0.90)


func _body_radius(mass: float) -> float:
	return _head_radius(mass) * 0.75


func snapshot() -> Dictionary:
	var packed_snakes: Array[Dictionary] = []
	for snake in snakes:
		var packed_segments: Array = []
		for segment in snake["segments"]:
			packed_segments.append([float(segment.x), float(segment.y)])
		var position: Vector2 = snake["position"]
		packed_snakes.append({
			"id":int(snake["id"]), "name":str(snake["name"]), "is_bot":bool(snake["is_bot"]),
			"alive":bool(snake["alive"]), "position":[position.x, position.y],
			"heading":float(snake["heading"]), "segments":packed_segments,
			"mass":float(snake["mass"]), "skin":int(snake["skin"]),
			"boosting":bool(snake["boosting"]), "invulnerable":float(snake["invulnerable"]),
			"state":str(snake["state"])
		})
	var packed_pellets: Array[Dictionary] = []
	for pellet in pellets:
		var position: Vector2 = pellet["position"]
		packed_pellets.append({
			"id":int(pellet["id"]), "position":[position.x, position.y],
			"value":float(pellet["value"]), "palette":int(pellet["palette"]),
			"source":str(pellet["source"])
		})
	var leaderboard := _leaderboard()
	var rank := -1
	for board_index in range(leaderboard.size()):
		if int(leaderboard[board_index]["id"]) == player_id:
			rank = board_index + 1
			break
	var player: Dictionary = packed_snakes[player_index]
	return {
		"phase":phase, "status":"over" if phase == LOST else "playing",
		"terminal_reason":terminal_reason, "arena_radius":arena_radius,
		"player_id":player_id, "player":player, "mass":float(player["mass"]),
		"rank":rank, "snakes":packed_snakes, "pellets":packed_pellets,
		"leaderboard":leaderboard, "elapsed":elapsed, "tick":tick
	}


func _leaderboard() -> Array[Dictionary]:
	var board: Array[Dictionary] = []
	for snake in snakes:
		if bool(snake.get("alive", false)):
			board.append({"id":int(snake["id"]), "name":str(snake["name"]), "mass":float(snake["mass"]), "skin":int(snake["skin"])})
	board.sort_custom(_leaderboard_before)
	return board


func _leaderboard_before(a: Dictionary, b: Dictionary) -> bool:
	var a_mass := float(a["mass"])
	var b_mass := float(b["mass"])
	if not is_equal_approx(a_mass, b_mass):
		return a_mass > b_mass
	return int(a["id"]) < int(b["id"])
