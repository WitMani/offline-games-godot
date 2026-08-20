extends RefCounted

## Presentation-only renderer for Number Connect / 2248.
## The authoritative board, path legality, scoring, gravity, and end states stay
## in merge2248_model.gd. This object only turns those states into a tactile
## candy-workshop frame and bounded merge choreography.

const CREAM := Color("fff0c7")
const CREAM_LIGHT := Color("fffaf0")
const COCOA := Color("4b2c28")
const COCOA_DARK := Color("241a1a")
const FELT := Color("176168")
const FELT_DARK := Color("0b3e43")
const WOOD := Color("a45c32")
const WOOD_DARK := Color("60351f")
const HONEY := Color("e4a84e")

var _rounded_style_cache: Dictionary = {}


func draw_board(canvas: CanvasItem, rect: Rect2, cell: Vector2) -> void:
	# A physical tray reads in a still frame: table shadow, wood body, cream
	# lip, teal felt, then restrained stitching. No glow is needed.
	var tray_shadow := rect.grow(17.0)
	tray_shadow.position += Vector2(0, 9)
	_draw_rounded_box(canvas, tray_shadow, 30.0, Color("2c1715", 0.56))
	_draw_rounded_box(canvas, rect.grow(16.0), 29.0, WOOD_DARK)
	_draw_rounded_box(canvas, rect.grow(12.0), 25.0, WOOD)
	_draw_rounded_box(canvas, rect.grow(7.0), 21.0, HONEY)
	_draw_rounded_box(canvas, rect.grow(3.0), 18.0, CREAM)
	_draw_rounded_box(canvas, rect, 16.0, FELT_DARK)
	_draw_rounded_box(canvas, rect.grow(-4.0), 13.0, FELT)
	canvas.draw_line(rect.position + Vector2(14, 9), Vector2(rect.end.x - 14, rect.position.y + 9), Color("8ed3c8", 0.24), 2.0, true)
	canvas.draw_line(Vector2(rect.position.x + 10, rect.end.y - 8), rect.end - Vector2(10, 8), Color("062f32", 0.45), 2.0, true)
	for lane in range(1, 5):
		var x := rect.position.x + float(lane) * cell.x
		_draw_dashed_line(canvas, Vector2(x, rect.position.y + 18), Vector2(x, rect.end.y - 18), Color(CREAM, 0.065), 7.0, 7.0, 1.2)
	for row in range(1, 8):
		var y := rect.position.y + float(row) * cell.y
		_draw_dashed_line(canvas, Vector2(rect.position.x + 18, y), Vector2(rect.end.x - 18, y), Color("052f33", 0.14), 8.0, 9.0, 1.0)


func draw_ribbon(
	canvas: CanvasItem,
	points: Array[Vector2],
	pointer: Vector2,
	drag_active: bool,
	time: float,
	accent: Color,
	grade: int = 1
) -> void:
	if points.is_empty():
		return
	var grade_value := clampi(grade, 1, 4)
	var width_scale := 1.0 + float(grade_value - 1) * 0.09
	if points.size() > 1:
		for i in range(1, points.size()):
			var a := points[i - 1]
			var b := points[i]
			_draw_ribbon_segment(canvas, a, b, accent, 1.0, width_scale)
			var travel := fposmod(time * 1.75 + float(i) * 0.21, 1.0)
			var pulse := a.lerp(b, travel)
			canvas.draw_circle(pulse + Vector2(0, 2), 5.6 * width_scale, Color(COCOA_DARK, 0.32))
			canvas.draw_circle(pulse, 4.4 * width_scale, accent.lightened(0.22))
			canvas.draw_circle(pulse - Vector2(1.2, 1.2), 1.7, CREAM_LIGHT)
			if grade_value >= 3:
				var second_pulse := a.lerp(b, fposmod(travel + 0.46, 1.0))
				canvas.draw_circle(second_pulse, 2.6 + float(grade_value - 3), Color(CREAM_LIGHT, 0.82))
	if drag_active:
		var tail_from := points[-1]
		var max_tail := minf(tail_from.distance_to(pointer), 82.0)
		var tail_to := tail_from + tail_from.direction_to(pointer) * max_tail
		_draw_ribbon_segment(canvas, tail_from, tail_to, accent, 0.46, width_scale)


func draw_token(
	canvas: CanvasItem,
	center: Vector2,
	value: int,
	body_color: Color,
	selected: bool,
	font: Font,
	time: float,
	scale_value: Vector2 = Vector2.ONE,
	rotation: float = 0.0,
	alpha: float = 1.0
) -> void:
	var exponent := maxi(1, int(round(log(float(maxi(value, 2))) / log(2.0))))
	var kind := _shape_kind(exponent)
	var rim_color := CREAM_LIGHT if selected else body_color.darkened(0.46)
	var lifted := 4.0 if selected else 0.0
	canvas.draw_set_transform(center - Vector2(0, lifted), rotation, scale_value)

	# The full material stack remains readable if every transient FX layer is
	# removed: contact shadow, silhouette, body, inset, highlight, numeral.
	_draw_token_shape(canvas, kind, Color(COCOA_DARK, 0.42 * alpha), Vector2(0, 7.0 + lifted), 2.6)
	if selected:
		_draw_token_shape(canvas, kind, _with_alpha(CREAM_LIGHT, alpha), Vector2.ZERO, 5.0)
	_draw_token_shape(canvas, kind, _with_alpha(rim_color, alpha), Vector2.ZERO, 2.2)
	_draw_token_shape(canvas, kind, _with_alpha(body_color, alpha), Vector2.ZERO, -0.3)
	_draw_token_shape(canvas, kind, _with_alpha(body_color.lightened(0.13), alpha), Vector2(-1.0, -2.0), -5.1)

	# Tier details add a second signal beyond hue and numeral.
	if exponent >= 6:
		canvas.draw_arc(Vector2.ZERO, 19.5, -2.9, 0.25, 28, _with_alpha(CREAM, 0.43 * alpha), 2.0, true)
		for i in range(3):
			var facet_angle := -2.45 + float(i) * 0.48
			var facet_pos := Vector2(cos(facet_angle), sin(facet_angle)) * 23.0
			_draw_diamond(canvas, facet_pos, 3.2, _with_alpha(CREAM_LIGHT, 0.72 * alpha))
	if exponent >= 9:
		_draw_crown(canvas, Vector2(0, -24), _with_alpha(HONEY, 0.94 * alpha))

	canvas.draw_arc(Vector2(-2, -1), 22.0, 3.64, 5.35, 16, _with_alpha(CREAM_LIGHT, 0.62 * alpha), 2.4, true)
	canvas.draw_circle(Vector2(-10, -13), 3.0, _with_alpha(CREAM_LIGHT, 0.74 * alpha))
	if selected:
		var sparkle := Vector2(cos(time * 3.4), sin(time * 3.4)) * 29.0
		_draw_spark(canvas, sparkle, 4.0, _with_alpha(CREAM_LIGHT, 0.88 * alpha))

	_draw_token_number(canvas, font, value, alpha)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_merge_fx(canvas: CanvasItem, effect: Dictionary, now: float, number_font: Font, label_font: Font) -> void:
	var age := now - float(effect.get("started", now))
	var points: Array = effect.get("points", [])
	var values: Array = effect.get("values", [])
	if points.is_empty():
		return
	var destination: Vector2 = points[-1]
	var result := int(effect.get("result", 2))
	var color: Color = effect.get("color", Color("ff7777"))
	var grade := clampi(int(effect.get("grade", 1)), 1, 4)
	var chain_length := int(effect.get("chain_length", points.size()))
	var gained := int(effect.get("gained", result))
	var intensity := float(grade)

	# Gather: retained path candies converge toward the destination. The model
	# has already transitioned; these are strictly short-lived visual echoes.
	var gather_duration := 0.18 + intensity * 0.014
	if age < gather_duration + 0.03:
		var gather := _ease_in_cubic(clampf(age / gather_duration, 0.0, 1.0))
		for i in range(maxi(0, points.size() - 1)):
			var delay := float(i) * 0.012
			var local_t := _ease_in_cubic(clampf((age - delay) / gather_duration, 0.0, 1.0))
			var arc_offset := Vector2(0, -sin(local_t * PI) * (10.0 + intensity * 3.0 + float(i % 3) * 4.0))
			var token_value := int(values[i]) if i < values.size() else maxi(2, result / 2)
			var echo_position: Vector2 = points[i].lerp(destination, local_t) + arc_offset
			if grade >= 3:
				canvas.draw_line(echo_position, destination, Color(CREAM, (1.0 - local_t) * 0.14), 2.0 + intensity * 0.5, true)
			draw_token(canvas, echo_position, token_value, _value_color(token_value), false, number_font, now, Vector2.ONE * lerpf(0.96, 0.29 + intensity * 0.015, local_t), sin(local_t * PI) * 0.018 * float(grade - 1) * (-1.0 if i % 2 == 0 else 1.0), 1.0 - local_t * 0.46)
		var pinch_alpha := 1.0 - gather
		canvas.draw_circle(destination, 13.0 + gather * (17.0 + intensity * 3.0), Color(CREAM, (0.12 + intensity * 0.025) * pinch_alpha))

	# Impact/result: an authored overshoot, cream splash, and restrained sugar
	# crumbs. Scale, stretch and angular recoil rise by semantic grade.
	var impact_duration := 0.38 + intensity * 0.055
	var impact_t := clampf((age - 0.085) / impact_duration, 0.0, 1.0)
	if age >= 0.085 and impact_t < 1.0:
		var result_scale := _graded_pop_scale(impact_t, grade)
		var result_rotation := _graded_pop_rotation(impact_t, grade, result)
		draw_token(canvas, destination, result, color, false, number_font, now, result_scale, result_rotation)
		if grade >= 3 and age < 0.19:
			var flash := sin(clampf((age - 0.085) / 0.105, 0.0, 1.0) * PI)
			canvas.draw_circle(destination, 45.0 + intensity * 9.0, Color(CREAM_LIGHT, flash * (0.035 + intensity * 0.018)))
		var ring_count := grade
		for ring in range(ring_count):
			var ring_t := _ease_out_cubic(clampf((age - 0.10 - float(ring) * 0.045) / (0.38 + intensity * 0.035), 0.0, 1.0))
			var ring_fade := 1.0 - ring_t
			if ring_t > 0.0 and ring_t < 1.0:
				canvas.draw_arc(destination, 22.0 + ring_t * (42.0 + intensity * 7.0 + float(ring) * 8.0), 0.0, TAU, 40, Color(CREAM_LIGHT if ring % 2 == 0 else color.lightened(0.26), (0.72 - float(ring) * 0.08) * ring_fade), 4.3 - float(ring) * 0.45, true)
		var burst := _ease_out_cubic(clampf((age - 0.105) / (0.42 + intensity * 0.045), 0.0, 1.0))
		var fade := 1.0 - burst
		var crumb_count := 6 + grade * 4
		for i in range(crumb_count):
			var angle := float(i) / float(crumb_count) * TAU + float(result % 7) * 0.13
			var distance := 17.0 + burst * (23.0 + intensity * 5.0 + float(i % 3) * 8.0)
			var crumb := destination + Vector2(cos(angle), sin(angle)) * distance
			if i % 2 == 0:
				_draw_spark(canvas, crumb, 2.8 + float(i % 3) + intensity * 0.18, Color(CREAM_LIGHT, fade))
			else:
				canvas.draw_circle(crumb, 1.7 + intensity * 0.25 + 2.0 * fade, Color(color.lightened(0.28), fade))

	# A compact callout makes the grade explicit without asking the player to
	# infer it only from particles. It pops with the result and leaves first.
	if age >= 0.10:
		var total_duration := float(effect.get("duration", 0.90))
		var badge_t := clampf((age - 0.10) / maxf(0.01, total_duration - 0.10), 0.0, 1.0)
		var badge_in := _ease_out_cubic(clampf(badge_t / 0.24, 0.0, 1.0))
		var badge_fade := 1.0 - _ease_out_cubic(clampf((badge_t - 0.62) / 0.38, 0.0, 1.0))
		var badge_width := 90.0 + float(grade) * 20.0
		var badge_center := destination + Vector2(0, -49.0 - intensity * 4.0 - badge_in * 8.0)
		var badge_rect := Rect2(badge_center - Vector2(badge_width * 0.5, 15.0), Vector2(badge_width, 30.0)).grow((1.0 - badge_in) * -5.0)
		_draw_rounded_box(canvas, Rect2(badge_rect.position + Vector2(0, 3), badge_rect.size), 15.0, Color(COCOA_DARK, 0.42 * badge_fade))
		_draw_rounded_box(canvas, badge_rect, 15.0, _with_alpha(_grade_color(grade), 0.96 * badge_fade))
		var badge_label := "%s ×%d  +%d" % [_grade_label(grade), chain_length, gained]
		var badge_size := 11 + grade
		var badge_text := label_font.get_string_size(badge_label, HORIZONTAL_ALIGNMENT_LEFT, -1, badge_size)
		canvas.draw_string(label_font, badge_center + Vector2(-badge_text.x * 0.5, badge_size * 0.35), badge_label, HORIZONTAL_ALIGNMENT_LEFT, -1, badge_size, Color(COCOA, badge_fade))


func draw_recipe_label(canvas: CanvasItem, rect: Rect2, preview: int, font: Font, grade: int = 1, chain_length: int = 2, time: float = 0.0) -> void:
	var grade_value := clampi(grade, 1, 4)
	var pulse := (0.5 + sin(time * (4.0 + float(grade_value) * 0.35)) * 0.5) * float(grade_value - 1) * 0.7
	var visual_rect := rect.grow(pulse)
	var grade_color := _grade_color(grade_value)
	var label_shadow := Rect2(visual_rect.position + Vector2(0, 4 + grade_value), visual_rect.size)
	_draw_rounded_box(canvas, label_shadow, visual_rect.size.y * 0.5, Color(COCOA_DARK, 0.36 + float(grade_value) * 0.035))
	_draw_rounded_box(canvas, visual_rect, visual_rect.size.y * 0.5, Color(CREAM_LIGHT, 0.99))
	_draw_rounded_box(canvas, visual_rect.grow(-3.0), maxf(2.0, visual_rect.size.y * 0.5 - 3.0), grade_color)
	var label := "松开 · 熬成 %d" % preview
	if grade_value >= 2:
		label = "%s ×%d · 熬成 %d" % [_grade_label(grade_value), chain_length, preview]
	var font_size := 12 if grade_value >= 3 else 13
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	canvas.draw_string(font, visual_rect.get_center() + Vector2(-text_size.x * 0.5, font_size * 0.36), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COCOA)
	for pip in range(grade_value):
		canvas.draw_circle(visual_rect.position + Vector2(13 + pip * 6, visual_rect.size.y * 0.5), 1.8, Color(CREAM_LIGHT, 0.94))
	_draw_spark(canvas, Vector2(visual_rect.end.x - 16, visual_rect.get_center().y), 3.0 + float(grade_value - 1) * 0.45, Color("fff9e9"))


func _draw_ribbon_segment(canvas: CanvasItem, a: Vector2, b: Vector2, accent: Color, alpha: float, width_scale: float) -> void:
	canvas.draw_line(a + Vector2(0, 4), b + Vector2(0, 4), Color(COCOA_DARK, 0.34 * alpha), 17.0 * width_scale, true)
	canvas.draw_line(a, b, Color(CREAM, 0.98 * alpha), 14.0 * width_scale, true)
	canvas.draw_line(a - Vector2(0, 2), b - Vector2(0, 2), Color(CREAM_LIGHT, 0.72 * alpha), 4.0 * width_scale, true)
	canvas.draw_line(a + Vector2(0, 3), b + Vector2(0, 3), Color(accent, 0.36 * alpha), 3.2 * width_scale, true)
	canvas.draw_circle(a, 7.0 * width_scale, Color(CREAM, 0.98 * alpha))
	canvas.draw_circle(b, 7.0 * width_scale, Color(CREAM, 0.98 * alpha))


func _draw_token_number(canvas: CanvasItem, font: Font, value: int, alpha: float) -> void:
	var label := str(value)
	var font_size := 20 if value < 1000 else (16 if value < 10000 else 13)
	var size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var origin := Vector2(-size.x * 0.5, font_size * 0.35)
	canvas.draw_string(font, origin + Vector2(0, 2.4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(COCOA_DARK, 0.62 * alpha))
	canvas.draw_string(font, origin, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(CREAM_LIGHT, 0.98 * alpha))


func _shape_kind(exponent: int) -> int:
	if exponent == 1:
		return 0 # pillow
	if exponent == 2:
		return 1 # wrapped candy
	if exponent == 3:
		return 2 # lozenge
	return 3 # flower / star for 16+


func _draw_token_shape(canvas: CanvasItem, kind: int, color: Color, offset: Vector2, expansion: float) -> void:
	match kind:
		0:
			_draw_rounded_box(canvas, Rect2(Vector2(-29, -25) + offset - Vector2.ONE * expansion, Vector2(58, 50) + Vector2.ONE * expansion * 2.0), 17.0 + expansion * 0.35, color)
		1:
			canvas.draw_colored_polygon(_wrapper_points(offset, expansion), color)
		2:
			_draw_rounded_box(canvas, Rect2(Vector2(-31, -22) + offset - Vector2.ONE * expansion, Vector2(62, 44) + Vector2.ONE * expansion * 2.0), 21.0 + expansion * 0.32, color)
		3:
			canvas.draw_colored_polygon(_star_points(offset, 6, 31.0 + expansion, 24.0 + expansion * 0.72, -PI * 0.5), color)


func _star_points(center: Vector2, points: int, outer: float, inner: float, rotation: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in range(points * 2):
		var radius := outer if i % 2 == 0 else inner
		var angle := rotation + float(i) * PI / float(points)
		result.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return result


func _wrapper_points(center: Vector2, expansion: float) -> PackedVector2Array:
	var scale_x := 1.0 + expansion / 30.0
	var scale_y := 1.0 + expansion / 24.0
	var base := PackedVector2Array([
		Vector2(-24, -22), Vector2(-31, -17), Vector2(-27, -9),
		Vector2(-34, 0), Vector2(-27, 9), Vector2(-31, 17),
		Vector2(-24, 22), Vector2(24, 22), Vector2(31, 17),
		Vector2(27, 9), Vector2(34, 0), Vector2(27, -9),
		Vector2(31, -17), Vector2(24, -22),
	])
	var result := PackedVector2Array()
	for point in base:
		result.append(center + Vector2(point.x * scale_x, point.y * scale_y))
	return result


func _draw_rounded_box(canvas: CanvasItem, rect: Rect2, radius: float, color: Color) -> void:
	var radius_px := clampi(roundi(radius), 0, roundi(minf(rect.size.x, rect.size.y) * 0.5))
	var alpha_step := clampi(roundi(color.a * 31.0), 0, 31)
	var quantized_color := Color(color.r, color.g, color.b, float(alpha_step) / 31.0)
	var cache_key := "%d:%d" % [quantized_color.to_rgba32(), radius_px]
	var style: StyleBoxFlat = _rounded_style_cache.get(cache_key)
	if style == null:
		style = StyleBoxFlat.new()
		style.bg_color = quantized_color
		style.set_corner_radius_all(radius_px)
		_rounded_style_cache[cache_key] = style
	canvas.draw_style_box(style, rect)


func _draw_dashed_line(canvas: CanvasItem, a: Vector2, b: Vector2, color: Color, dash: float, gap: float, width: float) -> void:
	var length := a.distance_to(b)
	if length <= 0.0:
		return
	var direction := a.direction_to(b)
	var cursor := 0.0
	while cursor < length:
		var end_cursor := minf(cursor + dash, length)
		canvas.draw_line(a + direction * cursor, a + direction * end_cursor, color, width, true)
		cursor += dash + gap


func _draw_spark(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -radius * 1.55),
		center + Vector2(radius * 0.36, -radius * 0.36),
		center + Vector2(radius * 1.55, 0),
		center + Vector2(radius * 0.36, radius * 0.36),
		center + Vector2(0, radius * 1.55),
		center + Vector2(-radius * 0.36, radius * 0.36),
		center + Vector2(-radius * 1.55, 0),
		center + Vector2(-radius * 0.36, -radius * 0.36),
	]), color)


func _draw_diamond(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -radius),
		center + Vector2(radius, 0),
		center + Vector2(0, radius),
		center + Vector2(-radius, 0),
	]), color)


func _draw_crown(canvas: CanvasItem, center: Vector2, color: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-10, 5), center + Vector2(-10, -4),
		center + Vector2(-5, 0), center + Vector2(0, -8),
		center + Vector2(5, 0), center + Vector2(10, -4),
		center + Vector2(10, 5),
	]), color)


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * alpha)


func _value_color(value: int) -> Color:
	match value:
		2: return Color("ff7777")
		4: return Color("a876f3")
		8: return Color("ffc801")
		16: return Color("82cd64")
		32: return Color("64c7fe")
		64: return Color("ffb177")
		128: return Color("598cdd")
		256: return Color("aa8364")
		512: return Color("00ddaa")
		1024: return Color("8787f9")
		2048: return Color("77faff")
	return Color("8290ab")


func _ease_in_cubic(value: float) -> float:
	return value * value * value


func _ease_out_cubic(value: float) -> float:
	var inverse := 1.0 - value
	return 1.0 - inverse * inverse * inverse


func _graded_pop_scale(value: float, grade: int) -> Vector2:
	var intensity := float(clampi(grade, 1, 4))
	var peak := 1.14 + intensity * 0.075
	if value < 0.38:
		var rise_t := _ease_out_cubic(value / 0.38)
		var base := lerpf(0.56, peak, rise_t)
		var stretch := sin(rise_t * PI) * 0.035 * intensity
		return Vector2(base + stretch, base - stretch * 0.62)
	var settle_t := (value - 0.38) / 0.62
	var settled := lerpf(peak, 1.0, _ease_out_cubic(settle_t))
	var wobble := sin(settle_t * PI * (2.0 + intensity * 0.38)) * pow(1.0 - settle_t, 1.55) * 0.018 * intensity
	return Vector2(settled + wobble, settled - wobble * 0.76)


func _graded_pop_rotation(value: float, grade: int, result: int) -> float:
	if grade <= 1:
		return 0.0
	var turn := -1.0 if int(round(log(float(maxi(result, 2))) / log(2.0))) % 2 == 0 else 1.0
	return sin(value * PI * (1.4 + float(grade) * 0.26)) * pow(1.0 - value, 1.25) * 0.018 * float(grade - 1) * turn


func _grade_label(grade: int) -> String:
	match clampi(grade, 1, 4):
		1: return "轻甜"
		2: return "连携"
		3: return "超连携"
		_: return "传奇配方"


func _grade_color(grade: int) -> Color:
	match clampi(grade, 1, 4):
		1: return Color("f3d495")
		2: return Color("f4c568")
		3: return Color("ff9b78")
		_: return Color("ffe46f")
