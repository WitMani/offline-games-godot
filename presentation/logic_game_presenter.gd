extends RefCounted

## Presentation-only state and drawing for Meowdoku. The gameplay board remains
## authoritative in main.gd; this presenter consumes semantic selection/result
## events and never writes rule state.

const BOARD_ORIGIN := Vector2(47.0, 236.0)
const CELL_SIZE := 49.5
const BOARD_EDGE := CELL_SIZE * 9.0
const MEOW_REWARD_TEXTURE: Texture2D = preload("res://assets/art/logic/gag-v1/meowdoku_paw_reward.png")

var selected_cell := Vector2i(0, 0)
var selected_started := -10.0
var event_kind := ""
var event_cell := Vector2i(-1, -1)
var event_block := -1
var event_number := 0
var event_grade := 0
var event_started := -10.0


func reset(now: float, initial_cell := Vector2i(0, 0)) -> void:
	selected_cell = initial_cell
	selected_started = now - 1.0
	event_kind = ""
	event_cell = Vector2i(-1, -1)
	event_block = -1
	event_number = 0
	event_grade = 0
	event_started = -10.0


func select(cell: Vector2i, now: float) -> void:
	selected_cell = cell
	selected_started = now


func present(kind: String, cell: Vector2i, block: int, number: int, grade: int, now: float) -> void:
	event_kind = kind
	event_cell = cell
	event_block = block
	event_number = number
	event_grade = clampi(grade, 1, 4)
	event_started = now


func snapshot(now: float) -> Dictionary:
	return {
		"selected": [selected_cell.x, selected_cell.y],
		"selected_age": maxf(0.0, now - selected_started),
		"kind": event_kind,
		"cell": [event_cell.x, event_cell.y],
		"block": event_block,
		"number": event_number,
		"grade": event_grade,
		"event_age": maxf(0.0, now - event_started),
		"font_role": "ui_cjk",
	}


func board_rect() -> Rect2:
	return Rect2(BOARD_ORIGIN, Vector2(BOARD_EDGE, BOARD_EDGE))


func cell_center(cell: Vector2i) -> Vector2:
	return BOARD_ORIGIN + Vector2((float(cell.x) + 0.5) * CELL_SIZE, (float(cell.y) + 0.5) * CELL_SIZE)


func draw_header_badge(canvas: CanvasItem, game_id: String, center: Vector2, extent: float) -> void:
	_draw_reward_texture(canvas, game_id == "meowdoku", center, Vector2(extent, extent), Color.WHITE)


func draw_result_badge(canvas: CanvasItem, game_id: String, center: Vector2) -> void:
	# The terminal card keeps the same physical vocabulary as the board so the
	# global settle reads as the folio's conclusion, not a generic app modal.
	var meow := game_id == "meowdoku"
	canvas.draw_circle(center, 39.0, Color("fff8eb", 0.34))
	_draw_reward_texture(canvas, meow, center, Vector2(76, 76), Color.WHITE)
	canvas.draw_arc(center, 40.0, -PI * 0.88, PI * 0.20, 30, Color("d55f96" if meow else "7566c7", 0.34), 2.0, true)


func draw_board(canvas: CanvasItem, game_id: String, state: Dictionary, now: float, number_font: Font) -> void:
	var board: Array = state.get("board", [])
	var given: Array = state.get("given", [])
	if board.size() != 9 or given.size() != 9:
		return
	var meow := game_id == "meowdoku"
	var accent := Color("e16c9f") if meow else Color("7566c7")
	_draw_folio_shell(canvas, meow, accent)
	_draw_event_block_wash(canvas, meow, accent, now)
	for y in range(9):
		for x in range(9):
			_draw_cell(canvas, meow, board, given, Vector2i(x, y), accent, now, number_font)
	_draw_grid(canvas, meow)
	_draw_completed_block_marks(canvas, meow, board, accent)
	_draw_object_event(canvas, meow, accent, now, number_font)


func _draw_folio_shell(canvas: CanvasItem, meow: bool, accent: Color) -> void:
	var rect := board_rect()
	if meow:
		# Soft cat-ear tabs, stacked paper edges, and binding rings make the board
		# read as a stationery object even with all event effects disabled.
		canvas.draw_colored_polygon(PackedVector2Array([
			rect.position + Vector2(18, -4), rect.position + Vector2(33, -22), rect.position + Vector2(48, -3)
		]), Color("d783ab"))
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(rect.end.x - 48, rect.position.y - 3), Vector2(rect.end.x - 33, rect.position.y - 22), Vector2(rect.end.x - 18, rect.position.y - 4)
		]), Color("d783ab"))
		_draw_box(canvas, Rect2(rect.position + Vector2(0, 8), rect.size), 18.0, Color("4c2439", 0.36))
		_draw_box(canvas, rect.grow(7.0), 19.0, Color("b95d88"))
		_draw_box(canvas, rect.grow(4.0), 17.0, Color("fff0f7"))
		canvas.draw_line(rect.position + Vector2(8, 3), Vector2(rect.end.x - 8, rect.position.y + 3), Color("ffffff", 0.82), 2.0, true)
		for ring in range(8):
			var ring_y := rect.position.y + 24.0 + float(ring) * 54.0
			canvas.draw_circle(Vector2(rect.position.x - 9, ring_y), 7.0, Color("7b3d5d", 0.28))
			canvas.draw_arc(Vector2(rect.position.x - 9, ring_y), 5.0, 0, TAU, 20, Color("ffe0ee"), 2.2, true)
	else:
		# A compact drafting board, layered folio paper, and brass registration
		# corners replace the former flat spreadsheet silhouette.
		_draw_box(canvas, Rect2(rect.position + Vector2(0, 9), rect.size), 6.0, Color("15171e", 0.40))
		_draw_box(canvas, rect.grow(8.0), 7.0, Color("4a4237"))
		_draw_box(canvas, rect.grow(4.0), 5.0, Color("d8c7a7"))
		_draw_box(canvas, rect, 3.0, Color("faf5e8"))
		for mark in range(9):
			var mark_x := rect.position.x + 25.0 + float(mark) * 49.5
			canvas.draw_line(Vector2(mark_x, rect.position.y - 7), Vector2(mark_x, rect.position.y - 2), Color("b78f55", 0.74), 1.5, true)
		for corner_variant in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			var corner: Vector2 = corner_variant
			var p: Vector2 = rect.get_center() + corner * (rect.size * 0.5 + Vector2(3, 3))
			var inward: Vector2 = -corner
			canvas.draw_line(p, p + Vector2(inward.x * 18.0, 0), Color("c49c59"), 3.0, true)
			canvas.draw_line(p, p + Vector2(0, inward.y * 18.0), Color("c49c59"), 3.0, true)
	canvas.draw_arc(rect.get_center(), rect.size.x * 0.69, -PI * 0.92, -PI * 0.08, 48, Color(accent, 0.035), 1.5, true)


func _draw_cell(canvas: CanvasItem, meow: bool, board: Array, given: Array, cell: Vector2i, accent: Color, now: float, number_font: Font) -> void:
	var base := Rect2(BOARD_ORIGIN + Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
	var visual := _animated_cell_rect(base, cell, now)
	var selected := cell == selected_cell
	var value := int(board[cell.y][cell.x])
	var fixed := int(given[cell.y][cell.x]) > 0
	var same_group := cell.x / 3 == selected_cell.x / 3 and cell.y / 3 == selected_cell.y / 3
	var related := cell.x == selected_cell.x or cell.y == selected_cell.y or same_group
	var block_even := ((cell.x / 3) + (cell.y / 3)) % 2 == 0
	var fill: Color
	if meow:
		fill = Color("fffafd") if block_even else Color("fff6fb")
		if fixed:
			fill = Color("f3e2eb") if block_even else Color("efdce7")
	else:
		fill = Color("fbf8ef") if block_even else Color("f6f1e7")
		if fixed:
			fill = Color("e9e2d7") if block_even else Color("e4dccf")
	if related:
		fill = fill.lerp(Color(accent, 0.72), 0.10)
	if selected:
		fill = fill.lerp(Color(accent, 0.88), 0.25)
	var raised := selected or (cell == event_cell and event_kind in ["logic_correct", "logic_erase", "logic_error"])
	if raised:
		_draw_box(canvas, Rect2(visual.position + Vector2(0, 2.5), visual.size), 4.0, Color("3d2132" if meow else "30343b", 0.22))
	# The heavy grid supplies each cell silhouette. A single inset paper fill keeps
	# the 81-cell stable frame tactile without multiplying rounded-box draw calls.
	canvas.draw_rect(visual.grow(-0.7), fill)
	canvas.draw_line(visual.position + Vector2(4, 2), Vector2(visual.end.x - 4, visual.position.y + 2), Color("ffffff", 0.42), 1.0, true)
	if selected:
		_draw_cell_focus(canvas, visual, meow, accent)
	if value > 0:
		var ink := Color("253047") if fixed else (Color("b24778") if meow else Color("3f5f9b"))
		var number_scale := _number_scale_for_cell(cell, now)
		var font_size := maxi(18, int(23.0 * number_scale))
		_draw_center_text(canvas, number_font, str(value), visual.get_center() + Vector2(0, 1), font_size, ink)
		if not fixed:
			# Entered values have a small ink underline/dot, adding a non-color
			# distinction from printed givens.
			var underline_y := visual.end.y - 8.0
			canvas.draw_line(Vector2(visual.get_center().x - 7, underline_y), Vector2(visual.get_center().x + 7, underline_y), Color(ink, 0.46), 1.6, true)
			canvas.draw_circle(Vector2(visual.get_center().x + 10, underline_y - 1), 1.4, Color(ink, 0.58))


func _animated_cell_rect(base: Rect2, cell: Vector2i, now: float) -> Rect2:
	var scale := 1.0
	var offset := Vector2.ZERO
	if cell == selected_cell:
		var age := now - selected_started
		if age >= 0.0 and age < 0.28:
			if age < 0.055:
				scale = lerpf(1.0, 0.91, age / 0.055)
			else:
				var settle := clampf((age - 0.055) / 0.225, 0.0, 1.0)
				scale = lerpf(0.91, 1.0, _ease_out_back(settle))
	if cell == event_cell:
		var age := now - event_started
		if event_kind == "logic_error" and age >= 0.0 and age < 0.34:
			var envelope := 1.0 - age / 0.34
			offset.x += sin(age * 102.0) * 4.6 * envelope
		elif event_kind in ["logic_correct", "logic_erase"] and age >= 0.0 and age < 0.42:
			scale *= 1.0 + sin(clampf(age / 0.42, 0.0, 1.0) * PI) * 0.09
	var center := base.get_center() + offset
	var size := base.size * scale
	return Rect2(center - size * 0.5, size)


func _number_scale_for_cell(cell: Vector2i, now: float) -> float:
	if cell != event_cell or event_kind != "logic_correct":
		return 1.0
	var age := now - event_started
	if age < 0.0 or age >= 0.48:
		return 1.0
	return 1.0 + sin(clampf(age / 0.48, 0.0, 1.0) * PI) * 0.18


func _draw_cell_focus(canvas: CanvasItem, rect: Rect2, meow: bool, accent: Color) -> void:
	var radius := minf(rect.size.x, rect.size.y) * (0.26 if meow else 0.30)
	if meow:
		# An open pencil arc avoids reading as an empty zero while retaining a
		# clear target around the selected value.
		canvas.draw_arc(rect.get_center(), radius, -PI * 0.92, PI * 0.58, 22, Color(accent, 0.86), 2.1, true)
	else:
		canvas.draw_arc(rect.get_center(), radius, 0, TAU, 24, Color(accent, 0.82), 1.8, true)
		canvas.draw_line(rect.get_center() + Vector2(-radius - 3, 0), rect.get_center() + Vector2(-radius + 3, 0), Color("c49c59", 0.84), 1.5, true)
		canvas.draw_line(rect.get_center() + Vector2(radius - 3, 0), rect.get_center() + Vector2(radius + 3, 0), Color("c49c59", 0.84), 1.5, true)
	var tick := 7.0
	for corner_variant in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		var corner: Vector2 = corner_variant
		var p: Vector2 = rect.get_center() + corner * (rect.size * 0.5 - Vector2(4, 4))
		var inward: Vector2 = -corner
		canvas.draw_line(p, p + Vector2(inward.x * tick, 0), Color(accent, 0.72), 1.6, true)
		canvas.draw_line(p, p + Vector2(0, inward.y * tick), Color(accent, 0.72), 1.6, true)
	if meow:
		_draw_paw(canvas, rect.position + Vector2(10, 10), Color(accent, 0.58), 0.28)
	else:
		canvas.draw_circle(rect.position + Vector2(10, 10), 2.2, Color("c49c59", 0.90))


func _draw_grid(canvas: CanvasItem, meow: bool) -> void:
	var thin := Color("745c6d", 0.48) if meow else Color("536075", 0.48)
	var thick := Color("604a5d", 0.82) if meow else Color("354158", 0.82)
	for index in range(10):
		var width := 3.0 if index % 3 == 0 else 1.05
		var color := thick if index % 3 == 0 else thin
		var x := BOARD_ORIGIN.x + float(index) * CELL_SIZE
		var y := BOARD_ORIGIN.y + float(index) * CELL_SIZE
		canvas.draw_line(Vector2(x, BOARD_ORIGIN.y), Vector2(x, BOARD_ORIGIN.y + BOARD_EDGE), color, width, true)
		canvas.draw_line(Vector2(BOARD_ORIGIN.x, y), Vector2(BOARD_ORIGIN.x + BOARD_EDGE, y), color, width, true)


func _draw_event_block_wash(canvas: CanvasItem, meow: bool, accent: Color, now: float) -> void:
	var age := now - event_started
	if age < 0.0:
		return
	if event_kind == "logic_block_complete" and event_block >= 0 and age < 0.90:
		var rect := _block_rect(event_block)
		var peak := sin(clampf(age / 0.62, 0.0, 1.0) * PI)
		_draw_box(canvas, rect.grow(3.0 + peak * 5.0), 10.0 if meow else 5.0, Color(accent, 0.10 + peak * 0.10))
		canvas.draw_arc(rect.get_center(), rect.size.x * (0.42 + age * 0.12), 0, TAU, 48, Color(accent, 0.46 * (1.0 - age / 0.90)), 3.0, true)
	elif event_kind == "logic_complete" and age < 1.18:
		var fade := 1.0 - clampf(age / 1.18, 0.0, 1.0)
		_draw_box(canvas, board_rect().grow(5.0 + sin(clampf(age / 0.62, 0.0, 1.0) * PI) * 6.0), 18.0 if meow else 7.0, Color("f4bf57", 0.15 * fade))


func _draw_completed_block_marks(canvas: CanvasItem, meow: bool, board: Array, accent: Color) -> void:
	for block in range(9):
		if not _block_complete(board, block):
			continue
		var rect := _block_rect(block)
		var mark := rect.position + Vector2(rect.size.x - 15, 15)
		if meow:
			_draw_paw(canvas, mark, Color(accent, 0.44), 0.42)
		else:
			_draw_compass(canvas, mark, 8.0, Color("b78f55", 0.64), 0.0)


func _draw_object_event(canvas: CanvasItem, meow: bool, accent: Color, now: float, number_font: Font) -> void:
	var age := now - event_started
	if age < 0.0:
		return
	if event_kind == "logic_error" and age < 0.62:
		var center := cell_center(event_cell)
		var fade := 1.0 - clampf(age / 0.62, 0.0, 1.0)
		if event_number > 0:
			_draw_center_text(canvas, number_font, str(event_number), center + Vector2(0, 1), 23, Color("c84056", 0.68 * fade))
		if meow:
			_draw_torn_correction(canvas, center, Color("e14f79", fade), 1.0 + sin(age * 12.0) * 0.05)
		else:
			_draw_red_pen_correction(canvas, center, Color("c8404f", fade), clampf(age / 0.16, 0.0, 1.0))
	elif event_kind == "logic_correct" and age < 0.68:
		var center := cell_center(event_cell)
		var fade := 1.0 - clampf((age - 0.28) / 0.40, 0.0, 1.0)
		if meow:
			var stamp_scale := 0.35 + _ease_out_back(clampf(age / 0.22, 0.0, 1.0)) * 0.34
			_draw_paw(canvas, center + Vector2(13, -13), Color(accent, 0.66 * fade), stamp_scale)
		else:
			var radius := 8.0 + _ease_out_cubic(clampf(age / 0.26, 0.0, 1.0)) * 16.0
			_draw_compass(canvas, center, radius, Color(accent, 0.56 * fade), age * 1.8)
	elif event_kind == "logic_erase" and age < 0.52:
		var center := cell_center(event_cell)
		var progress := _ease_out_cubic(clampf(age / 0.52, 0.0, 1.0))
		var eraser_color := Color("f5a6bc") if meow else Color("c7a879")
		var p := center + Vector2(lerpf(-19.0, 19.0, progress), -2.0)
		_draw_box(canvas, Rect2(p - Vector2(8, 5), Vector2(16, 10)), 3.0, Color(eraser_color, 0.90 * (1.0 - progress)))
		canvas.draw_line(center + Vector2(-18, 8), center + Vector2(lerpf(-18.0, 18.0, progress), 8), Color(eraser_color, 0.42), 2.0, true)
	elif event_kind == "logic_block_complete" and event_block >= 0 and age < 0.96:
		var center := _block_rect(event_block).get_center()
		var fade := 1.0 - clampf((age - 0.52) / 0.44, 0.0, 1.0)
		var stamp_scale := _ease_out_back(clampf(age / 0.32, 0.0, 1.0))
		if meow:
			_draw_paw(canvas, center, Color(accent, 0.14 * fade), 2.5 * stamp_scale)
		else:
			_draw_compass(canvas, center, 24.0 + stamp_scale * 37.0, Color("b78f55", 0.20 * fade), age * 0.8)
		_draw_reward_texture(canvas, meow, center, Vector2.ONE * 76.0 * stamp_scale, Color(1, 1, 1, 0.78 * fade))
	elif event_kind == "logic_complete" and age < 1.18:
		var fade := 1.0 - clampf((age - 0.70) / 0.48, 0.0, 1.0)
		for block in range(9):
			var local_age := age - float(block) * 0.045
			if local_age < 0.0:
				continue
			var center := _block_rect(block).get_center()
			var pulse := _ease_out_back(clampf(local_age / 0.28, 0.0, 1.0))
			if meow:
				_draw_paw(canvas, center, Color("d96d9f", 0.18 * fade), 1.25 * pulse)
			else:
				_draw_compass(canvas, center, 18.0 + pulse * 13.0, Color("b78f55", 0.22 * fade), float(block) * 0.31)
		var reward_scale := _ease_out_back(clampf(age / 0.38, 0.0, 1.0))
		_draw_reward_texture(canvas, meow, board_rect().get_center(), Vector2.ONE * 122.0 * reward_scale, Color(1, 1, 1, 0.92 * fade))


func _draw_torn_correction(canvas: CanvasItem, center: Vector2, color: Color, scale: float) -> void:
	var points := PackedVector2Array()
	for index in range(8):
		var x := -22.0 + float(index) * 44.0 / 7.0
		var y := (-5.0 if index % 2 == 0 else 5.0) * scale
		points.append(center + Vector2(x, y))
	canvas.draw_polyline(points, color, 4.0, true)
	for side in [-1.0, 1.0]:
		canvas.draw_colored_polygon(PackedVector2Array([
			center + Vector2(side * 23.0, -7.0), center + Vector2(side * 17.0, 0), center + Vector2(side * 23.0, 7.0)
		]), Color(color, color.a * 0.72))


func _draw_red_pen_correction(canvas: CanvasItem, center: Vector2, color: Color, progress: float) -> void:
	var start_a := center + Vector2(-18, -16)
	var end_a := center + Vector2(18, 16)
	var start_b := center + Vector2(-18, 16)
	var end_b := center + Vector2(18, -16)
	canvas.draw_line(start_a, start_a.lerp(end_a, progress), color, 3.2, true)
	if progress > 0.45:
		canvas.draw_line(start_b, start_b.lerp(end_b, (progress - 0.45) / 0.55), Color("ee7b84", color.a), 2.4, true)


func _draw_paw(canvas: CanvasItem, center: Vector2, color: Color, scale: float) -> void:
	canvas.draw_circle(center + Vector2(0, 3.5) * scale, 7.2 * scale, color)
	for index in range(4):
		var angle := -2.55 + float(index) * 0.72
		canvas.draw_circle(center + Vector2(cos(angle), sin(angle)) * 10.5 * scale, 3.0 * scale, color)


func _draw_compass(canvas: CanvasItem, center: Vector2, radius: float, color: Color, rotation: float) -> void:
	canvas.draw_arc(center, radius, 0, TAU, 32, color, maxf(1.2, radius * 0.075), true)
	for index in range(4):
		var angle := rotation + float(index) * PI * 0.5
		var direction := Vector2(cos(angle), sin(angle))
		var side := Vector2(-direction.y, direction.x)
		canvas.draw_colored_polygon(PackedVector2Array([
			center + direction * radius * 0.84,
			center - direction * radius * 0.16 + side * radius * 0.14,
			center - direction * radius * 0.16 - side * radius * 0.14,
		]), Color(color, color.a * (0.92 if index % 2 == 0 else 0.52)))
	canvas.draw_circle(center, maxf(1.6, radius * 0.10), Color("fff0bd", color.a))


func _draw_reward_texture(canvas: CanvasItem, meow: bool, center: Vector2, bounds: Vector2, modulate: Color) -> void:
	var texture := MEOW_REWARD_TEXTURE
	if texture == null:
		return
	var source_size := texture.get_size()
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return
	var fit := minf(bounds.x / source_size.x, bounds.y / source_size.y)
	var draw_size := source_size * fit
	canvas.draw_texture_rect(texture, Rect2(center - draw_size * 0.5, draw_size), false, modulate)


func _block_rect(block: int) -> Rect2:
	var x := block % 3
	var y := block / 3
	return Rect2(BOARD_ORIGIN + Vector2(float(x) * CELL_SIZE * 3.0, float(y) * CELL_SIZE * 3.0), Vector2(CELL_SIZE * 3.0, CELL_SIZE * 3.0))


func _block_complete(board: Array, block: int) -> bool:
	var start_x := (block % 3) * 3
	var start_y := (block / 3) * 3
	for y in range(start_y, start_y + 3):
		for x in range(start_x, start_x + 3):
			if int(board[y][x]) == 0:
				return false
	return true


func _draw_center_text(canvas: CanvasItem, font: Font, text: String, center: Vector2, font_size: int, color: Color) -> void:
	if font == null:
		return
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	canvas.draw_string(font, center + Vector2(-width * 0.5, font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_box(canvas: CanvasItem, rect: Rect2, radius: float, color: Color) -> void:
	# This path runs for every live grid cell. Build the rounded fill from draw
	# primitives so stable frames do not allocate dozens of StyleBox resources.
	var corner := clampf(radius, 0.0, minf(rect.size.x, rect.size.y) * 0.5)
	if corner <= 0.5:
		canvas.draw_rect(rect, color)
		return
	canvas.draw_rect(Rect2(rect.position + Vector2(corner, 0), Vector2(rect.size.x - corner * 2.0, rect.size.y)), color)
	canvas.draw_rect(Rect2(rect.position + Vector2(0, corner), Vector2(rect.size.x, rect.size.y - corner * 2.0)), color)
	canvas.draw_circle(rect.position + Vector2(corner, corner), corner, color)
	canvas.draw_circle(Vector2(rect.end.x - corner, rect.position.y + corner), corner, color)
	canvas.draw_circle(Vector2(rect.position.x + corner, rect.end.y - corner), corner, color)
	canvas.draw_circle(rect.end - Vector2(corner, corner), corner, color)


func _ease_out_cubic(value: float) -> float:
	return 1.0 - pow(1.0 - value, 3.0)


func _ease_out_back(value: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(value - 1.0, 3.0) + c1 * pow(value - 1.0, 2.0)
