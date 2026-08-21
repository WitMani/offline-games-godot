extends RefCounted

## Presentation-only renderer for classic 2048.
##
## The authoritative board and slide/merge result stay in main.gd. This class
## consumes the rule-produced motion payload and renders GAG-derived tile
## materials, staged travel, impact, and settle without mutating game state.

const TILE_TEXTURES := {
	1: preload("res://assets/art/merge2048/tile_tier_1.png"),
	2: preload("res://assets/art/merge2048/tile_tier_2.png"),
	3: preload("res://assets/art/merge2048/tile_tier_3.png"),
	4: preload("res://assets/art/merge2048/tile_tier_4.png"),
}
const WOOD_SHAVING_BURST: Texture2D = preload("res://assets/art/merge2048/wood_shaving_burst.png")

const TIER_BASE := {
	1: Color("ead3a6"),
	2: Color("e38a2d"),
	3: Color("244f70"),
	4: Color("60386f"),
}

var well_shadow_style: StyleBoxFlat
var well_outer_style: StyleBoxFlat
var well_inner_style: StyleBoxFlat


func _init() -> void:
	# These wells are drawn every frame. Reuse the three immutable style boxes
	# instead of allocating 48 StyleBox resources per frame on the Web renderer.
	well_shadow_style = _make_box(11, Color("180d08", 0.38))
	well_outer_style = _make_box(11, Color("5b4334", 0.72), Color("d7aa70", 0.18), 1)
	well_inner_style = _make_box(8, Color("33251e", 0.48), Color("100b08", 0.16), 1)


func tier_for_value(value: int) -> int:
	if value >= 512:
		return 4
	if value >= 64:
		return 3
	if value >= 8:
		return 2
	return 1


func number_background(value: int) -> Color:
	return TIER_BASE[tier_for_value(value)]


func draw_board(
	canvas: CanvasItem,
	board: Array,
	origin: Vector2,
	tile_size: float,
	now: float,
	motion: Dictionary,
	number_font: Font
) -> void:
	for y in range(4):
		for x in range(4):
			_draw_well(canvas, _cell_rect(origin, tile_size, Vector2i(x, y)))

	var duration := float(motion.get("duration", 0.0))
	var age := now - float(motion.get("started", -1000.0))
	var active := not motion.is_empty() and duration > 0.0 and age >= 0.0 and age < duration
	if not active:
		_draw_stable_board(canvas, board, origin, tile_size, number_font)
		return
	if bool(motion.get("reduced", false)):
		# Preserve the final authoritative board and material hierarchy while
		# replacing travel, rebound, and burst with a single quiet result marker.
		_draw_stable_board(canvas, board, origin, tile_size, number_font)
		var reduced_impact: Vector2i = motion.get("impact_cell", Vector2i(1, 1))
		var reduced_center := _cell_rect(origin, tile_size, reduced_impact).get_center()
		var reduced_grade := clampi(int(motion.get("grade", 1)), 1, 4)
		canvas.draw_arc(reduced_center, 38.0 + reduced_grade * 2.0, 0, TAU, 32, Color("f4c56d", 0.42), 2.0, true)
		return

	var timeline := clampf(age / duration, 0.0, 1.0)
	var destinations := {}
	for move in motion.get("moves", []):
		var destination: Vector2i = move.get("to", Vector2i(-1, -1))
		destinations[_cell_key(destination)] = true
	var spawn: Dictionary = motion.get("spawn", {})
	var spawn_position: Vector2i = spawn.get("position", Vector2i(-1, -1))

	# Uninvolved final cells remain stable, preserving board legibility while the
	# acted-on objects travel above them.
	for y in range(4):
		for x in range(4):
			var coordinate := Vector2i(x, y)
			var value := int(board[y][x])
			if value <= 0 or destinations.has(_cell_key(coordinate)) or coordinate == spawn_position:
				continue
			_draw_tile(canvas, _cell_rect(origin, tile_size, coordinate), value, number_font)

	_draw_peak_burst(canvas, motion, origin, tile_size, timeline)

	# Intent -> compression -> directional travel. Every source mapping comes
	# directly from the authoritative line resolver; presentation does not infer
	# or recompute the merge result.
	if timeline < 0.56:
		var travel_t := clampf((timeline - 0.12) / 0.42, 0.0, 1.0)
		var travel := _ease_in_out_cubic(travel_t)
		var anticipation := sin(clampf(timeline / 0.18, 0.0, 1.0) * PI)
		var disappear := clampf((timeline - 0.48) / 0.08, 0.0, 1.0)
		for move in motion.get("moves", []):
			var from: Vector2i = move.get("from", Vector2i.ZERO)
			var to: Vector2i = move.get("to", from)
			var from_center := _cell_rect(origin, tile_size, from).get_center()
			var to_center := _cell_rect(origin, tile_size, to).get_center()
			var direction := from_center.direction_to(to_center)
			var center := from_center.lerp(to_center, travel) - direction * anticipation * 3.5
			var rect := _cell_rect(origin, tile_size, from)
			rect.position = center - rect.size * 0.5
			var merged := bool(move.get("merged", false))
			var scale := Vector2(1.0 + anticipation * 0.045, 1.0 - anticipation * 0.035)
			if merged:
				scale *= lerpf(1.0, 0.82, travel)
			_draw_tile(canvas, rect, int(move.get("source_value", 2)), number_font, 1.0 - disappear, scale)

	# Impact -> result pop -> damped settle on the exact destination cells.
	if timeline >= 0.48:
		var impact_t := clampf((timeline - 0.48) / 0.42, 0.0, 1.0)
		var settle := exp(-5.8 * impact_t) * cos(impact_t * TAU * 1.9)
		var grade := clampi(int(motion.get("grade", 1)), 1, 4)
		var result_scale := Vector2(
			1.0 + settle * (0.20 + grade * 0.025),
			1.0 - settle * (0.14 + grade * 0.018)
		)
		for key in destinations:
			var parts := str(key).split(":")
			var coordinate := Vector2i(int(parts[0]), int(parts[1]))
			var value := int(board[coordinate.y][coordinate.x])
			if value > 0:
				_draw_tile(canvas, _cell_rect(origin, tile_size, coordinate), value, number_font, 1.0, result_scale)

	if not spawn.is_empty() and timeline >= 0.70:
		var spawn_t := clampf((timeline - 0.70) / 0.24, 0.0, 1.0)
		var spawn_scale := _ease_out_back(spawn_t)
		_draw_tile(
			canvas,
			_cell_rect(origin, tile_size, spawn_position),
			int(spawn.get("value", 2)),
			number_font,
			spawn_t,
			Vector2.ONE * spawn_scale
		)


func _draw_stable_board(canvas: CanvasItem, board: Array, origin: Vector2, tile_size: float, number_font: Font) -> void:
	for y in range(4):
		for x in range(4):
			var value := int(board[y][x])
			if value > 0:
				_draw_tile(canvas, _cell_rect(origin, tile_size, Vector2i(x, y)), value, number_font)


func _draw_peak_burst(canvas: CanvasItem, motion: Dictionary, origin: Vector2, tile_size: float, timeline: float) -> void:
	var grade := clampi(int(motion.get("grade", 1)), 1, 4)
	if grade < 3 or timeline < 0.42 or timeline > 0.90:
		return
	var impact: Vector2i = motion.get("impact_cell", Vector2i(1, 1))
	var center := _cell_rect(origin, tile_size, impact).get_center()
	var burst_t := clampf((timeline - 0.42) / 0.48, 0.0, 1.0)
	var envelope := sin(burst_t * PI)
	var size := (126.0 if grade == 3 else 172.0) * (0.84 + envelope * 0.22)
	var alpha := envelope * (0.50 if grade == 3 else 0.82)
	canvas.draw_texture_rect(
		WOOD_SHAVING_BURST,
		Rect2(center - Vector2.ONE * size * 0.5, Vector2.ONE * size),
		false,
		Color(1, 1, 1, alpha)
	)


func _draw_well(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_style_box(well_shadow_style, Rect2(rect.position + Vector2(0, 5), rect.size))
	canvas.draw_style_box(well_outer_style, rect)
	canvas.draw_style_box(well_inner_style, rect.grow(-6.0))


func _draw_tile(
	canvas: CanvasItem,
	rect: Rect2,
	value: int,
	number_font: Font,
	alpha := 1.0,
	axis_scale := Vector2.ONE
) -> void:
	var tier := tier_for_value(value)
	var texture: Texture2D = TILE_TEXTURES[tier]
	var center := rect.get_center()
	canvas.draw_set_transform(center, 0.0, axis_scale)
	var local_rect := Rect2(-rect.size * 0.54, rect.size * 1.08)
	canvas.draw_texture_rect(texture, local_rect, false, Color(1, 1, 1, alpha))

	var number_size := 34 if value < 100 else (27 if value < 1000 else 21)
	var number_color := Color("432817") if tier <= 2 else Color("fff1d4")
	var text := str(value)
	var text_size := number_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size)
	canvas.draw_string(
		number_font,
		Vector2(-text_size.x * 0.5, number_size * 0.34),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		number_size,
		Color(number_color, alpha)
	)

	# Code-native carpenter notches preserve progression within a material tier
	# without baking live values into generated imagery.
	var notch_count := clampi(int(round(log(float(value)) / log(2.0))) - 1, 1, 7)
	var notch_color := Color("6f3b20", alpha * 0.66) if tier <= 2 else Color("f7d285", alpha * 0.74)
	var start_x := -float(notch_count - 1) * 4.0
	for notch in range(notch_count):
		canvas.draw_circle(Vector2(start_x + notch * 8.0, rect.size.y * 0.34), 1.7, notch_color)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _cell_rect(origin: Vector2, tile_size: float, coordinate: Vector2i) -> Rect2:
	return Rect2(origin + Vector2(coordinate.x, coordinate.y) * tile_size, Vector2(tile_size - 7.0, tile_size - 7.0))


func _cell_key(coordinate: Vector2i) -> String:
	return "%d:%d" % [coordinate.x, coordinate.y]


func _make_box(radius: int, fill: Color, border := Color.TRANSPARENT, border_width := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	return style


func _ease_in_out_cubic(value: float) -> float:
	return 4.0 * value * value * value if value < 0.5 else 1.0 - pow(-2.0 * value + 2.0, 3.0) * 0.5


func _ease_out_back(value: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(value - 1.0, 3.0) + c1 * pow(value - 1.0, 2.0)
