extends RefCounted

## 2048 Balls presentation-only renderer.
##
## The authoritative column model still lives in main.gd. This presenter owns
## the tactile fruit family, orchard-crate material, and the staged visual arc
## for drop and merge events. It never mutates gameplay state.

const FRUIT_TEXTURES := {
	1: preload("res://assets/art/2048balls/fruit_01_lemon.png"),
	2: preload("res://assets/art/2048balls/fruit_02_orange.png"),
	3: preload("res://assets/art/2048balls/fruit_03_apple.png"),
	4: preload("res://assets/art/2048balls/fruit_04_grape.png"),
	5: preload("res://assets/art/2048balls/fruit_05_watermelon.png"),
}
const JUICE_BURST: Texture2D = preload("res://assets/art/2048balls/juice_merge_burst.png")

const PRESTIGE_SCALE := {
	1: 0.90,
	2: 0.96,
	3: 1.02,
	4: 1.10,
	5: 1.18,
}


func draw_crate(canvas: CanvasItem, rect: Rect2, elapsed: float) -> void:
	# A quiet cavity keeps state readable while the rails, fasteners, planks,
	# and leaf ties make the container feel authored rather than like a panel.
	_rounded_box(canvas, Rect2(rect.position + Vector2(0, 10), rect.size), 28.0, Color("1d0d08", 0.42))
	_rounded_box(canvas, rect, 28.0, Color("b96935"), Color("f5c870"), 3)
	_rounded_box(canvas, rect.grow(-13.0), 20.0, Color("542d22", 0.90), Color("6f3b28"), 2)
	_rounded_box(canvas, rect.grow(-23.0), 15.0, Color("351d20", 0.82), Color("e8a95e", 0.22), 1)

	for slat in range(6):
		var y := rect.position.y + 34.0 + float(slat) * 74.0
		canvas.draw_line(Vector2(rect.position.x + 19.0, y + 4.0), Vector2(rect.end.x - 19.0, y), Color("1f0f0b", 0.22), 9.0, true)
		canvas.draw_line(Vector2(rect.position.x + 21.0, y), Vector2(rect.end.x - 21.0, y - 3.0), Color("efae63", 0.12), 3.0, true)

	# Raised side posts and rails create contact, body, edge, and highlight.
	for post_x in [rect.position.x + 6.0, rect.end.x - 24.0]:
		_rounded_box(canvas, Rect2(post_x, rect.position.y + 12.0, 18.0, rect.size.y - 24.0), 8.0, Color("8d4728"), Color("f2b767", 0.72), 2)
		canvas.draw_line(Vector2(post_x + 5.0, rect.position.y + 24.0), Vector2(post_x + 5.0, rect.end.y - 24.0), Color("ffd48a", 0.24), 2.0, true)
	for rail_y in [rect.position.y + 3.0, rect.end.y - 22.0]:
		_rounded_box(canvas, Rect2(rect.position.x + 8.0, rail_y, rect.size.x - 16.0, 20.0), 9.0, Color("9f512d"), Color("f7c775", 0.70), 2)

	for nail_x in [rect.position.x + 19.0, rect.end.x - 19.0]:
		for nail_y in [rect.position.y + 19.0, rect.end.y - 18.0]:
			canvas.draw_circle(Vector2(nail_x, nail_y) + Vector2(0, 2), 4.2, Color("351b17", 0.54))
			canvas.draw_circle(Vector2(nail_x, nail_y), 3.2, Color("d9b07a"))
			canvas.draw_circle(Vector2(nail_x - 1.0, nail_y - 1.0), 1.0, Color("fff0c0", 0.68))

	# A physical cord marks danger without relying on color alone.
	var danger_y := rect.position.y + 124.0
	canvas.draw_line(Vector2(rect.position.x + 22.0, danger_y + 2.0), Vector2(rect.end.x - 22.0, danger_y - 1.0), Color("3a1719", 0.52), 5.0, true)
	canvas.draw_line(Vector2(rect.position.x + 22.0, danger_y), Vector2(rect.end.x - 22.0, danger_y - 3.0), Color("ff7187", 0.86), 2.2, true)
	for marker in range(7):
		var x := rect.position.x + 48.0 + float(marker) * 62.0
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(x - 5.0, danger_y), Vector2(x + 5.0, danger_y), Vector2(x, danger_y + 8.0)
		]), Color("ffd27d", 0.72))

	for lane in range(1, 7):
		var lane_x := rect.position.x + 13.0 + float(lane) * 62.0
		canvas.draw_dashed_line(Vector2(lane_x, rect.position.y + 98.0), Vector2(lane_x, rect.end.y - 24.0), Color("ffd8a1", 0.085), 1.0, 7.0)

	var breeze := sin(elapsed * 1.4) * 0.08
	_draw_leaf(canvas, rect.position + Vector2(37, 12), 10.0, Color("7fbd59"), -0.65 + breeze)
	_draw_leaf(canvas, Vector2(rect.end.x - 38, rect.position.y + 11), 10.0, Color("91cc62"), 2.55 - breeze)


func draw_fruit(
	canvas: CanvasItem,
	center: Vector2,
	value: int,
	radius: float,
	now: float,
	effects: Array,
	animate := true
) -> void:
	var clamped_value := clampi(value, 1, 5)
	var effect := _latest_effect_at(effects, center) if animate else {}
	var draw_center := center
	var axis_scale := Vector2.ONE
	var alpha := 1.0
	var kind := str(effect.get("kind", ""))
	var age := now - float(effect.get("started", now)) if not effect.is_empty() else 99.0
	var grade := clampi(int(effect.get("grade", 1)), 1, 4)

	if kind == "fruit_drop" and age >= 0.0:
		var fall_t := clampf(age / 0.24, 0.0, 1.0)
		var eased_fall := _ease_out_quart(fall_t)
		draw_center.y = lerpf(342.0, center.y, eased_fall)
		axis_scale = Vector2(0.90, 1.13) if fall_t < 0.76 else Vector2(1.18, 0.78).lerp(Vector2.ONE, _ease_out_back(clampf((fall_t - 0.76) / 0.24, 0.0, 1.0)))
		if fall_t < 0.84:
			for ghost_index in range(2):
				var ghost_t := clampf(fall_t - 0.10 - float(ghost_index) * 0.12, 0.0, 1.0)
				var ghost_y := lerpf(342.0, center.y, _ease_out_quart(ghost_t))
				_draw_fruit_texture(canvas, Vector2(center.x, ghost_y), clamped_value, radius, Vector2(0.82, 1.18), 0.11 - float(ghost_index) * 0.03)
	elif (kind == "fruit_merge" or kind == "fruit_harvest_complete") and age >= 0.0:
		var anticipation_t := clampf(age / 0.13, 0.0, 1.0)
		if age < 0.16:
			var source_value := maxi(1, clamped_value - 1)
			var gather := _ease_in_cubic(anticipation_t)
			_draw_fruit_texture(canvas, center + Vector2(0, lerpf(-28.0, -5.0, gather)), source_value, radius * 0.92, Vector2(0.88, 1.08), 0.46 * (1.0 - anticipation_t * 0.45))
			_draw_fruit_texture(canvas, center + Vector2(0, lerpf(28.0, 5.0, gather)), source_value, radius * 0.92, Vector2(0.88, 1.08), 0.46 * (1.0 - anticipation_t * 0.45))
			axis_scale = Vector2(0.72, 0.72)
			alpha = 0.48
		else:
			var impact_t := clampf((age - 0.13) / 0.42, 0.0, 1.0)
			var ring_peak := sin(clampf(impact_t / 0.62, 0.0, 1.0) * PI)
			if grade >= 3:
				_draw_juice_burst(canvas, center, grade, impact_t, ring_peak)
			var settle := exp(-6.2 * impact_t) * cos(impact_t * TAU * 2.05)
			axis_scale = Vector2(1.0 + settle * (0.34 + grade * 0.035), 1.0 - settle * (0.23 + grade * 0.025))
			alpha = clampf(0.68 + impact_t * 1.8, 0.0, 1.0)

	_draw_contact_shadow(canvas, draw_center, radius, clamped_value, axis_scale, alpha)
	_draw_fruit_texture(canvas, draw_center, clamped_value, radius, axis_scale, alpha)
	if clamped_value == 5:
		_draw_watermelon_crown(canvas, draw_center, radius, now, alpha)


func _latest_effect_at(effects: Array, center: Vector2) -> Dictionary:
	for index in range(effects.size() - 1, -1, -1):
		var effect: Dictionary = effects[index]
		if str(effect.get("game_id", "")) != "watermelon":
			continue
		var effect_position: Vector2 = effect.get("position", Vector2(-1000, -1000))
		if effect_position.distance_to(center) <= 5.0:
			return effect
	return {}


func _draw_fruit_texture(canvas: CanvasItem, center: Vector2, value: int, radius: float, axis_scale: Vector2, alpha: float) -> void:
	var texture: Texture2D = FRUIT_TEXTURES.get(clampi(value, 1, 5))
	if texture == null:
		return
	var texture_size := texture.get_size()
	var target_height := radius * 2.12 * float(PRESTIGE_SCALE.get(clampi(value, 1, 5), 1.0))
	var target_size := Vector2(target_height * texture_size.x / texture_size.y, target_height) * axis_scale
	canvas.draw_texture_rect(texture, Rect2(center - target_size * 0.5, target_size), false, Color(1, 1, 1, alpha))


func _draw_contact_shadow(canvas: CanvasItem, center: Vector2, radius: float, value: int, axis_scale: Vector2, alpha: float) -> void:
	var prestige := float(PRESTIGE_SCALE.get(value, 1.0))
	var half_size := Vector2(radius * prestige * axis_scale.x * 0.76, radius * 0.19)
	var points := PackedVector2Array()
	for index in range(24):
		var angle := float(index) / 24.0 * TAU
		points.append(center + Vector2(cos(angle) * half_size.x, sin(angle) * half_size.y) + Vector2(0, radius * prestige * 0.76))
	canvas.draw_colored_polygon(points, Color("160b0d", 0.32 * alpha))


func _draw_juice_burst(canvas: CanvasItem, center: Vector2, grade: int, t: float, peak: float) -> void:
	var fade := 1.0 - _ease_out_cubic(clampf((t - 0.55) / 0.45, 0.0, 1.0))
	# Grade three is an emphatic chain, while grade four is the rare catalog
	# peak. Keeping separate envelopes makes the asset read as hierarchy rather
	# than as the same explosion with a slightly different number.
	var size := (108.0 + peak * 32.0) if grade == 3 else (142.0 + peak * 50.0)
	var tint := Color(1, 1, 1, fade * (0.42 if grade == 3 else 0.82))
	canvas.draw_texture_rect(JUICE_BURST, Rect2(center - Vector2.ONE * size * 0.5, Vector2.ONE * size), false, tint)
	canvas.draw_arc(center, 27.0 + t * (30.0 + grade * 5.0), 0, TAU, 38, Color("fff1a9", fade * (0.56 if grade == 3 else 0.76)), 2.7 + grade * 0.38, true)


func _draw_watermelon_crown(canvas: CanvasItem, center: Vector2, radius: float, now: float, alpha: float) -> void:
	var pulse := 0.5 + sin(now * 2.7) * 0.5
	for index in range(3):
		var angle := -PI * 0.74 + float(index) * PI * 0.74
		var p := center + Vector2(cos(angle), sin(angle)) * (radius * 1.00 + pulse * 1.5)
		canvas.draw_circle(p, 1.6 + pulse * 0.7, Color("fff2a8", alpha * (0.50 + pulse * 0.24)))


func _draw_leaf(canvas: CanvasItem, center: Vector2, radius: float, color: Color, rotation: float) -> void:
	var direction := Vector2(cos(rotation), sin(rotation))
	var side := Vector2(-direction.y, direction.x)
	canvas.draw_colored_polygon(PackedVector2Array([
		center - direction * radius,
		center + side * radius * 0.55,
		center + direction * radius,
		center - side * radius * 0.55,
	]), color)
	canvas.draw_line(center - direction * radius * 0.72, center + direction * radius * 0.72, Color(color.darkened(0.28), color.a), 1.3, true)


func _rounded_box(canvas: CanvasItem, rect: Rect2, radius: float, fill: Color, border := Color.TRANSPARENT, border_width := 0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_corner_radius_all(int(radius))
	style.set_border_width_all(border_width)
	canvas.draw_style_box(style, rect)


func _ease_out_quart(value: float) -> float:
	return 1.0 - pow(1.0 - value, 4.0)


func _ease_in_cubic(value: float) -> float:
	return value * value * value


func _ease_out_cubic(value: float) -> float:
	return 1.0 - pow(1.0 - value, 3.0)


func _ease_out_back(value: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(value - 1.0, 3.0) + c1 * pow(value - 1.0, 2.0)
