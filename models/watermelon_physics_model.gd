class_name WatermelonPhysicsModel
extends RefCounted

## Deterministic, presentation-free drop-and-merge simulation for 2048 Balls.
##
## The model owns free horizontal aim, gravity, circular contacts, equal-value
## collision merges, score, danger-line failure, target completion and restart.
## Rendering, sound, haptics and camera feedback consume semantic events only.

const RUNNING := "playing"
const OVER := "over"

const FIXED_DT := 1.0 / 120.0
const LEFT_WALL := 54.0
const RIGHT_WALL := 468.0
const SPAWN_Y := 328.0
const FLOOR_Y := 682.0
const DANGER_Y := 356.0
const GRAVITY := 980.0
const MAX_SPEED := 940.0
const AIR_DAMPING := 0.9992
const WALL_RESTITUTION := 0.22
const BALL_RESTITUTION := 0.16
const CONTACT_FRICTION := 0.14
const DROP_COOLDOWN := 0.24
const DANGER_HOLD_SECONDS := 0.86
const FIRST_TARGET_TIER := 8 # 2^8 = 256, then 2048 and beyond.
const MAX_TIER := 30

var balls: Array[Dictionary] = []
var score := 0
var best_score := 0
var moves := 0
var status := RUNNING
var aim_x := 270.0
var next_tier := 1
var target_tier := FIRST_TARGET_TIER
var elapsed := 0.0
var tick := 0
var accumulator := 0.0
var drop_cooldown := 0.0
var rng := RandomNumberGenerator.new()

var _next_ball_id := 1
var _shot_serial := 0
var _shot_chains: Dictionary = {}
var _pending_events: Array[Dictionary] = []


func reset(seed_value: int = 2048, preserve_best := true) -> void:
	var retained_best := best_score if preserve_best else 0
	rng.seed = seed_value
	balls.clear()
	score = 0
	best_score = retained_best
	moves = 0
	status = RUNNING
	aim_x = 270.0
	next_tier = 1
	target_tier = FIRST_TARGET_TIER
	elapsed = 0.0
	tick = 0
	accumulator = 0.0
	drop_cooldown = 0.0
	_next_ball_id = 1
	_shot_serial = 0
	_shot_chains.clear()
	_pending_events.clear()


func set_aim_x(value: float) -> void:
	var radius := radius_for_tier(next_tier)
	aim_x = clampf(value, LEFT_WALL + radius, RIGHT_WALL - radius)


func nudge_aim(direction: float) -> void:
	set_aim_x(aim_x + signf(direction) * 24.0)


func can_drop() -> bool:
	if status != RUNNING or drop_cooldown > 0.0:
		return false
	var radius := radius_for_tier(next_tier)
	var spawn := Vector2(clampf(aim_x, LEFT_WALL + radius, RIGHT_WALL - radius), SPAWN_Y)
	for ball in balls:
		if spawn.distance_to(ball["position"]) < radius + float(ball["radius"]) + 2.0:
			return false
	return true


func drop(tier_override: int = 0) -> bool:
	if status != RUNNING:
		_pending_events.append({"kind":"drop_rejected", "reason":"terminal", "position":Vector2(aim_x, SPAWN_Y)})
		return false
	var tier := clampi(tier_override if tier_override > 0 else next_tier, 1, MAX_TIER)
	var radius := radius_for_tier(tier)
	set_aim_x(aim_x)
	var spawn := Vector2(clampf(aim_x, LEFT_WALL + radius, RIGHT_WALL - radius), SPAWN_Y)
	if drop_cooldown > 0.0:
		_pending_events.append({"kind":"drop_rejected", "reason":"cooldown", "position":spawn})
		return false
	for ball in balls:
		if spawn.distance_to(ball["position"]) < radius + float(ball["radius"]) + 2.0:
			_pending_events.append({"kind":"drop_rejected", "reason":"spawn_blocked", "position":spawn})
			return false

	_shot_serial += 1
	_shot_chains[_shot_serial] = 0
	var released_ball := _make_ball(tier, spawn, Vector2.ZERO, _shot_serial, false)
	balls.append(released_ball)
	moves += 1
	drop_cooldown = DROP_COOLDOWN
	_pending_events.append({
		"kind":"ball_released", "shot_id":_shot_serial, "ball_id":int(released_ball["id"]), "tier":tier,
		"value":value_for_tier(tier), "position":spawn,
	})
	if tier_override <= 0:
		next_tier = _roll_next_tier()
	set_aim_x(aim_x)
	return true


func step(delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not _pending_events.is_empty():
		events.append_array(_pending_events)
		_pending_events.clear()
	if delta <= 0.0 or status != RUNNING:
		return events
	accumulator += minf(delta, 0.25)
	while accumulator + 0.0000001 >= FIXED_DT and status == RUNNING:
		accumulator -= FIXED_DT
		events.append_array(_fixed_step(FIXED_DT))
	return events


func inject_ball(tier: int, position: Vector2, velocity := Vector2.ZERO, shot_id: int = 0) -> int:
	var ball := _make_ball(clampi(tier, 1, MAX_TIER), position, velocity, shot_id, true)
	balls.append(ball)
	return int(ball["id"])


func clear_events() -> void:
	_pending_events.clear()


func radius_for_tier(tier: int) -> float:
	return minf(33.0, 15.0 + float(clampi(tier, 1, MAX_TIER)) * 1.75)


func value_for_tier(tier: int) -> int:
	return 1 << clampi(tier, 1, 30)


func highest_tier() -> int:
	var result := 0
	for ball in balls:
		result = maxi(result, int(ball["tier"]))
	return result


func snapshot() -> Dictionary:
	var serialized: Array[Dictionary] = []
	for ball in balls:
		var position: Vector2 = ball["position"]
		var velocity: Vector2 = ball["velocity"]
		serialized.append({
			"id":int(ball["id"]), "tier":int(ball["tier"]),
			"value":value_for_tier(int(ball["tier"])),
			"position":[snappedf(position.x, 0.001), snappedf(position.y, 0.001)],
			"velocity":[snappedf(velocity.x, 0.001), snappedf(velocity.y, 0.001)],
			"radius":float(ball["radius"]), "shot_id":int(ball["shot_id"]),
			"danger_time":snappedf(float(ball["danger_time"]), 0.001),
		})
	return {
		"balls":serialized, "score":score, "best":best_score, "moves":moves, "status":status,
		"aim_x":snappedf(aim_x, 0.001), "next_tier":next_tier,
		"next_value":value_for_tier(next_tier), "highest_tier":highest_tier(),
		"target_tier":target_tier, "target_value":value_for_tier(target_tier),
		"tick":tick,
	}


func _fixed_step(delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	elapsed += delta
	tick += 1
	drop_cooldown = maxf(0.0, drop_cooldown - delta)

	for index in range(balls.size()):
		var ball: Dictionary = balls[index]
		ball["age"] = float(ball["age"]) + delta
		var velocity: Vector2 = ball["velocity"]
		velocity.y = minf(MAX_SPEED, velocity.y + GRAVITY * delta)
		velocity *= AIR_DAMPING
		var position: Vector2 = ball["position"]
		position += velocity * delta
		ball["position"] = position
		ball["velocity"] = velocity
		balls[index] = ball

	for _iteration in range(4):
		_resolve_bounds(events)
		var merge_pair := _first_merge_pair()
		if merge_pair.x >= 0:
			_merge_pair(merge_pair.x, merge_pair.y, events)
			continue
		_resolve_ball_contacts(events)

	_update_danger(delta, events)
	return events


func _make_ball(tier: int, position: Vector2, velocity: Vector2, shot_id: int, contacted: bool) -> Dictionary:
	var ball := {
		"id":_next_ball_id, "tier":tier, "position":position, "velocity":velocity,
		"radius":radius_for_tier(tier), "shot_id":shot_id, "age":0.0,
		"contact_reported":contacted, "danger_time":0.0,
	}
	_next_ball_id += 1
	return ball


func _resolve_bounds(events: Array[Dictionary]) -> void:
	for index in range(balls.size()):
		var ball: Dictionary = balls[index]
		var position: Vector2 = ball["position"]
		var velocity: Vector2 = ball["velocity"]
		var radius := float(ball["radius"])
		var contacted := false
		if position.x - radius < LEFT_WALL:
			position.x = LEFT_WALL + radius
			if velocity.x < 0.0:
				velocity.x = -velocity.x * WALL_RESTITUTION
			contacted = true
		elif position.x + radius > RIGHT_WALL:
			position.x = RIGHT_WALL - radius
			if velocity.x > 0.0:
				velocity.x = -velocity.x * WALL_RESTITUTION
			contacted = true
		if position.y + radius > FLOOR_Y:
			position.y = FLOOR_Y - radius
			if velocity.y > 0.0:
				velocity.y = -velocity.y * WALL_RESTITUTION
			velocity.x *= 0.90
			if absf(velocity.y) < 8.0:
				velocity.y = 0.0
			contacted = true
		ball["position"] = position
		ball["velocity"] = velocity
		balls[index] = ball
		if contacted:
			_report_first_contact(index, events)


func _first_merge_pair() -> Vector2i:
	for first in range(balls.size()):
		for second in range(first + 1, balls.size()):
			if int(balls[first]["tier"]) != int(balls[second]["tier"]):
				continue
			var first_position: Vector2 = balls[first]["position"]
			var second_position: Vector2 = balls[second]["position"]
			var contact_distance := float(balls[first]["radius"]) + float(balls[second]["radius"])
			if first_position.distance_squared_to(second_position) <= contact_distance * contact_distance:
				return Vector2i(first, second)
	return Vector2i(-1, -1)


func _merge_pair(first: int, second: int, events: Array[Dictionary]) -> void:
	var a: Dictionary = balls[first]
	var b: Dictionary = balls[second]
	var new_tier := mini(MAX_TIER, int(a["tier"]) + 1)
	var position: Vector2 = (Vector2(a["position"]) + Vector2(b["position"])) * 0.5
	var velocity: Vector2 = (Vector2(a["velocity"]) + Vector2(b["velocity"])) * 0.42 + Vector2(0, -46.0)
	var shot_id := maxi(int(a["shot_id"]), int(b["shot_id"]))
	var chain := int(_shot_chains.get(shot_id, 0)) + 1 if shot_id > 0 else 1
	if shot_id > 0:
		_shot_chains[shot_id] = chain
	var grade := clampi(1 + chain, 2, 4)
	if new_tier >= 8:
		grade = maxi(grade, 3)
	if new_tier >= target_tier:
		grade = 4

	balls.remove_at(second)
	balls.remove_at(first)
	var result := _make_ball(new_tier, position, velocity, shot_id, true)
	balls.append(result)
	var gained := value_for_tier(new_tier)
	score += gained
	best_score = maxi(best_score, score)
	events.append({
		"kind":"balls_merged", "position":position, "tier":new_tier,
		"value":gained, "grade":grade, "chain":chain, "shot_id":shot_id,
		"source_ids":[int(a["id"]), int(b["id"])], "result_id":int(result["id"]),
		"source_positions":[Vector2(a["position"]), Vector2(b["position"])],
	})
	if new_tier >= target_tier:
		var completed_target := value_for_tier(target_tier)
		events.append({
			"kind":"target_reached", "position":position, "tier":new_tier,
			"value":gained, "completed_target":completed_target, "grade":4,
		})
		target_tier = mini(MAX_TIER, target_tier + 3)


func _resolve_ball_contacts(events: Array[Dictionary]) -> void:
	for first in range(balls.size()):
		for second in range(first + 1, balls.size()):
			var a: Dictionary = balls[first]
			var b: Dictionary = balls[second]
			var a_position: Vector2 = a["position"]
			var b_position: Vector2 = b["position"]
			var delta := b_position - a_position
			var minimum_distance := float(a["radius"]) + float(b["radius"])
			var distance_squared := delta.length_squared()
			if distance_squared >= minimum_distance * minimum_distance:
				continue
			var distance := sqrt(maxf(distance_squared, 0.000001))
			var normal := delta / distance if distance_squared > 0.000001 else Vector2.RIGHT.rotated(float((int(a["id"]) * 31 + int(b["id"]) * 17) % 360) * PI / 180.0)
			var a_mass := float(a["radius"]) * float(a["radius"])
			var b_mass := float(b["radius"]) * float(b["radius"])
			var a_inverse := 1.0 / a_mass
			var b_inverse := 1.0 / b_mass
			var inverse_sum := a_inverse + b_inverse
			var penetration := minimum_distance - distance
			a_position -= normal * penetration * (a_inverse / inverse_sum)
			b_position += normal * penetration * (b_inverse / inverse_sum)

			var a_velocity: Vector2 = a["velocity"]
			var b_velocity: Vector2 = b["velocity"]
			var relative := b_velocity - a_velocity
			var normal_speed := relative.dot(normal)
			if normal_speed < 0.0:
				var impulse_size := -(1.0 + BALL_RESTITUTION) * normal_speed / inverse_sum
				var impulse := normal * impulse_size
				a_velocity -= impulse * a_inverse
				b_velocity += impulse * b_inverse
				var tangent := relative - normal * normal_speed
				if tangent.length_squared() > 0.0001:
					var friction_impulse := tangent.normalized() * minf(tangent.length() / inverse_sum, impulse_size * CONTACT_FRICTION)
					a_velocity += friction_impulse * a_inverse
					b_velocity -= friction_impulse * b_inverse
			a["position"] = a_position
			b["position"] = b_position
			a["velocity"] = a_velocity
			b["velocity"] = b_velocity
			balls[first] = a
			balls[second] = b
			_report_first_contact(first, events)
			_report_first_contact(second, events)


func _report_first_contact(index: int, events: Array[Dictionary]) -> void:
	if index < 0 or index >= balls.size():
		return
	var ball: Dictionary = balls[index]
	if bool(ball["contact_reported"]):
		return
	ball["contact_reported"] = true
	balls[index] = ball
	events.append({
		"kind":"ball_landed", "position":ball["position"], "tier":int(ball["tier"]),
		"value":value_for_tier(int(ball["tier"])), "shot_id":int(ball["shot_id"]), "ball_id":int(ball["id"]),
	})


func _update_danger(delta: float, events: Array[Dictionary]) -> void:
	for index in range(balls.size()):
		var ball: Dictionary = balls[index]
		var position: Vector2 = ball["position"]
		var velocity: Vector2 = ball["velocity"]
		var threatens := float(ball["age"]) > 0.72 and position.y - float(ball["radius"]) < DANGER_Y and velocity.length() < 42.0
		if threatens:
			ball["danger_time"] = float(ball["danger_time"]) + delta
		else:
			ball["danger_time"] = maxf(0.0, float(ball["danger_time"]) - delta * 2.0)
		balls[index] = ball
		if float(ball["danger_time"]) >= DANGER_HOLD_SECONDS:
			status = OVER
			events.append({"kind":"danger_overflow", "position":position, "tier":int(ball["tier"]), "value":value_for_tier(int(ball["tier"]))})
			return


func _roll_next_tier() -> int:
	var ceiling := clampi(highest_tier() - 4, 1, 3)
	return rng.randi_range(1, ceiling)
