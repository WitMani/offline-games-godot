extends RefCounted

## Presentation-only renderer for the region-cat Meowdoku model. It consumes a
## JSON-safe snapshot and semantic events; it never computes legal moves,
## changes hearts, or decides completion.

const BOARD_RECT := Rect2(48, 244, 444, 444)
const PAW_REWARD_TEXTURE: Texture2D = preload("res://assets/art/logic/gag-v1/meowdoku_paw_reward.png")
const REGION_COLORS := [
	Color("ef9b9f"), Color("f5c972"), Color("86cdd2"), Color("a9a1dd"),
	Color("91d2a9"), Color("e9a7cb"), Color("7fb9e5"), Color("efad7b"),
	Color("b7d47e"), Color("c79edb"), Color("85d3bf"), Color("f0ba8c"),
]

var selected := Vector2i(-1, -1)
var selected_started := -10.0
var event_kind := ""
var event_cell := Vector2i(-1, -1)
var event_started := -10.0
var event_metadata: Dictionary = {}


func reset(now: float, initial_cell := Vector2i(-1, -1)) -> void:
	selected = initial_cell
	selected_started = now - 1.0
	event_kind = ""
	event_cell = Vector2i(-1, -1)
	event_started = -10.0
	event_metadata.clear()


func select(cell: Vector2i, now: float) -> void:
	selected = cell
	selected_started = now


func present(kind: String, cell: Vector2i, now: float, metadata: Dictionary = {}) -> void:
	event_kind = kind
	event_cell = cell
	event_started = now
	event_metadata = metadata.duplicate(true)


func snapshot(now: float) -> Dictionary:
	return {
		"selected":[selected.x, selected.y],
		"selected_age":maxf(0.0, now - selected_started),
		"event":event_kind,
		"event_cell":[event_cell.x, event_cell.y],
		"event_age":maxf(0.0, now - event_started),
		"event_metadata":event_metadata.duplicate(true),
		"gag_texture":"res://assets/art/logic/gag-v1/meowdoku_paw_reward.png",
		"font_role":"ui_cjk",
	}


func board_rect() -> Rect2:
	return BOARD_RECT


func cell_center(cell: Vector2i, board_size: int) -> Vector2:
	var cell_size := BOARD_RECT.size.x / float(maxi(1, board_size))
	return BOARD_RECT.position + Vector2((float(cell.x) + 0.5) * cell_size, (float(cell.y) + 0.5) * cell_size)


func draw_header_badge(canvas: CanvasItem, center: Vector2, extent: float) -> void:
	canvas.draw_circle(center + Vector2(0, 2), extent * 0.48, Color("1d0e18", 0.30))
	canvas.draw_circle(center, extent * 0.46, Color("fff0f7", 0.92))
	_draw_texture_contain(canvas, PAW_REWARD_TEXTURE, center, Vector2(extent * 0.86, extent * 0.78), Color.WHITE)


func draw_result_badge(canvas: CanvasItem, center: Vector2, won: bool) -> void:
	var ring := Color("f0bb58") if won else Color("ed7694")
	canvas.draw_circle(center + Vector2(0, 4), 46.0, Color("3a1830", 0.24))
	canvas.draw_circle(center, 44.0, Color("fff8ee", 0.88))
	_draw_texture_contain(canvas, PAW_REWARD_TEXTURE, center, Vector2(76, 70), Color.WHITE if won else Color("f2b0bf"))
	canvas.draw_arc(center, 44.0, -PI * 0.92, PI * 0.20, 34, Color(ring, 0.86), 3.0, true)


func draw_board(canvas: CanvasItem, state: Dictionary, now: float, ui_font: Font, reduced_effects: bool) -> void:
	var board_size := int(state.get("size", 0))
	var regions: Array = state.get("regions", [])
	if board_size <= 0 or regions.size() != board_size:
		return
	var cats := _data_cells(state.get("cats", []))
	var givens := _data_cells(state.get("given_cats", []))
	var manual_marks := _data_cells(state.get("manual_marks", []))
	var derived_marks := _data_cells(state.get("derived_marks", []))
	selected = _data_cell(state.get("selected", [selected.x, selected.y]))

	_draw_rule_ribbon(canvas, state, ui_font)
	_draw_notebook_shell(canvas)
	var cell_size := BOARD_RECT.size.x / float(board_size)
	for y in range(board_size):
		for x in range(board_size):
			var cell := Vector2i(x, y)
			var base := Rect2(BOARD_RECT.position + Vector2(float(x), float(y)) * cell_size, Vector2.ONE * cell_size)
			var visual := _animated_cell_rect(base.grow(-2.3), cell, now, reduced_effects)
			_draw_region_cell(canvas, visual, int(regions[y][x]), cell == selected)
	_draw_region_boundaries(canvas, regions, board_size, cell_size)

	for y in range(board_size):
		for x in range(board_size):
			var cell := Vector2i(x, y)
			var center := cell_center(cell, board_size)
			if cell in cats:
				_draw_cat(canvas, center, cell_size * 0.31, cell, cell in givens, now, reduced_effects)
			elif cell in manual_marks:
				_draw_x_mark(canvas, center, cell_size * 0.20, true)
			elif cell in derived_marks:
				_draw_x_mark(canvas, center, cell_size * 0.17, false)

	_draw_selection(canvas, board_size, cell_size, now, reduced_effects)
	_draw_board_event(canvas, state, now, ui_font, reduced_effects)
	_draw_footer(canvas, state, ui_font)


func _draw_rule_ribbon(canvas: CanvasItem, state: Dictionary, ui_font: Font) -> void:
	_draw_box(canvas, Rect2(30, 188, 480, 40), 14.0, Color("fff2f7", 0.96), Color("d981a8", 0.58), 1)
	var rules := ["每行一猫", "每列一猫", "同色一猫"]
	for index in range(rules.size()):
		var x := 47.0 + float(index) * 128.0
		var color: Color = REGION_COLORS[(index + 1) % REGION_COLORS.size()]
		canvas.draw_circle(Vector2(x + 5, 207), 7.0, Color(color.darkened(0.18), 0.88))
		_draw_paw(canvas, Vector2(x + 5, 206), Color("fff9f0"), 0.36)
		_draw_text(canvas, ui_font, rules[index], Vector2(x + 18, 211), 11, Color("63334e"))
	var level_text := "LEVEL %d" % int(state.get("level", 1))
	_draw_text(canvas, ui_font, level_text, Vector2(435, 211), 10, Color("8b526d"))


func _draw_notebook_shell(canvas: CanvasItem) -> void:
	var rect := BOARD_RECT
	canvas.draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(22, 0), rect.position + Vector2(43, -25), rect.position + Vector2(62, 1)
	]), Color("c86f99"))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(rect.end.x - 62, rect.position.y + 1), Vector2(rect.end.x - 43, rect.position.y - 25), Vector2(rect.end.x - 22, rect.position.y)
	]), Color("c86f99"))
	_draw_box(canvas, Rect2(rect.position + Vector2(0, 10), rect.size), 22.0, Color("4a2338", 0.34))
	_draw_box(canvas, rect.grow(11), 23.0, Color("b65f88"))
	_draw_box(canvas, rect.grow(7), 21.0, Color("ffeef6"), Color("fffafd", 0.80), 2)
	for ring in range(8):
		var y := rect.position.y + 27.0 + float(ring) * ((rect.size.y - 54.0) / 7.0)
		canvas.draw_circle(Vector2(rect.position.x - 11, y + 2), 7.4, Color("4c2439", 0.30))
		canvas.draw_arc(Vector2(rect.position.x - 11, y), 6.0, 0, TAU, 20, Color("ffe2ee"), 2.3, true)
	canvas.draw_line(rect.position + Vector2(10, 3), Vector2(rect.end.x - 10, rect.position.y + 3), Color("ffffff", 0.74), 2.0, true)


func _draw_region_cell(canvas: CanvasItem, rect: Rect2, region: int, selected_cell: bool) -> void:
	var color: Color = REGION_COLORS[posmod(region, REGION_COLORS.size())]
	var fill := color.lightened(0.20 if selected_cell else 0.14)
	_draw_box(canvas, Rect2(rect.position + Vector2(0, 3), rect.size), maxf(7.0, rect.size.x * 0.14), Color("54273c", 0.19))
	_draw_box(canvas, rect, maxf(7.0, rect.size.x * 0.14), fill, Color(color.darkened(0.24), 0.52), 1)
	var inset := rect.grow(-3.0)
	canvas.draw_line(inset.position + Vector2(5, 1), Vector2(inset.end.x - 5, inset.position.y + 1), Color("ffffff", 0.38), 1.2, true)
	match posmod(region, 4):
		0:
			canvas.draw_circle(rect.position + Vector2(rect.size.x * 0.78, rect.size.y * 0.78), maxf(1.2, rect.size.x * 0.025), Color("fff9eb", 0.26))
		1:
			canvas.draw_line(rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.82), rect.position + Vector2(rect.size.x * 0.28, rect.size.y * 0.72), Color("fff9eb", 0.22), 1.0)
		2:
			canvas.draw_arc(rect.position + Vector2(rect.size.x * 0.80, rect.size.y * 0.77), maxf(2.0, rect.size.x * 0.045), 0, TAU, 10, Color("fff9eb", 0.22), 1.0)
		3:
			canvas.draw_line(rect.position + Vector2(rect.size.x * 0.74, rect.size.y * 0.82), rect.position + Vector2(rect.size.x * 0.84, rect.size.y * 0.82), Color("fff9eb", 0.23), 1.0)


func _draw_region_boundaries(canvas: CanvasItem, regions: Array, board_size: int, cell_size: float) -> void:
	var seam := Color("62364d", 0.78)
	for y in range(board_size):
		for x in range(board_size):
			var region := int(regions[y][x])
			var left := BOARD_RECT.position.x + float(x) * cell_size
			var top := BOARD_RECT.position.y + float(y) * cell_size
			if x == 0 or int(regions[y][x - 1]) != region:
				canvas.draw_line(Vector2(left + 1, top + 5), Vector2(left + 1, top + cell_size - 5), seam, 2.4, true)
			if y == 0 or int(regions[y - 1][x]) != region:
				canvas.draw_line(Vector2(left + 5, top + 1), Vector2(left + cell_size - 5, top + 1), seam, 2.4, true)
			if x == board_size - 1 or int(regions[y][x + 1]) != region:
				canvas.draw_line(Vector2(left + cell_size - 1, top + 5), Vector2(left + cell_size - 1, top + cell_size - 5), seam, 2.4, true)
			if y == board_size - 1 or int(regions[y + 1][x]) != region:
				canvas.draw_line(Vector2(left + 5, top + cell_size - 1), Vector2(left + cell_size - 5, top + cell_size - 1), seam, 2.4, true)


func _draw_cat(canvas: CanvasItem, center: Vector2, radius: float, cell: Vector2i, given: bool, now: float, reduced_effects: bool) -> void:
	var scale := 1.0
	if not reduced_effects and cell == event_cell and event_kind in ["cat", "complete"]:
		var age := now - event_started
		if age >= 0.0 and age < 0.46:
			var t := clampf(age / 0.46, 0.0, 1.0)
			scale = 0.74 + (1.0 - pow(1.0 - minf(1.0, t * 1.45), 3.0)) * 0.34 - sin(t * PI) * 0.08
	var r := radius * scale
	var dark_cat := posmod(cell.x + cell.y, 3) == 0
	var fur := Color("544457") if dark_cat else Color("fff8e9")
	var outline := Color("3e2638")
	var ear_fill := fur.lightened(0.02)
	canvas.draw_circle(center + Vector2(0, r * 0.16 + 3), r * 0.98, Color("3c2132", 0.22))
	canvas.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-r * 0.78, -r * 0.18), center + Vector2(-r * 0.58, -r * 1.02), center + Vector2(-r * 0.10, -r * 0.54)
	]), outline)
	canvas.draw_colored_polygon(PackedVector2Array([
		center + Vector2(r * 0.78, -r * 0.18), center + Vector2(r * 0.58, -r * 1.02), center + Vector2(r * 0.10, -r * 0.54)
	]), outline)
	canvas.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-r * 0.66, -r * 0.24), center + Vector2(-r * 0.55, -r * 0.78), center + Vector2(-r * 0.20, -r * 0.46)
	]), ear_fill)
	canvas.draw_colored_polygon(PackedVector2Array([
		center + Vector2(r * 0.66, -r * 0.24), center + Vector2(r * 0.55, -r * 0.78), center + Vector2(r * 0.20, -r * 0.46)
	]), ear_fill)
	canvas.draw_circle(center, r, outline)
	canvas.draw_circle(center, r * 0.88, fur)
	canvas.draw_arc(center + Vector2(-r * 0.18, -r * 0.23), r * 0.56, -PI * 0.94, -PI * 0.46, 14, Color("ffffff", 0.34 if not dark_cat else 0.14), maxf(1.0, r * 0.08), true)
	var eye := Color("fff6df") if dark_cat else Color("4c3042")
	canvas.draw_circle(center + Vector2(-r * 0.34, -r * 0.08), maxf(1.5, r * 0.10), eye)
	canvas.draw_circle(center + Vector2(r * 0.34, -r * 0.08), maxf(1.5, r * 0.10), eye)
	canvas.draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, r * 0.10), center + Vector2(-r * 0.11, r * 0.01), center + Vector2(r * 0.11, r * 0.01)
	]), Color("e77799"))
	canvas.draw_arc(center + Vector2(-r * 0.10, r * 0.12), r * 0.20, 0.10, PI * 0.90, 10, eye, maxf(1.0, r * 0.055), true)
	canvas.draw_arc(center + Vector2(r * 0.10, r * 0.12), r * 0.20, PI * 0.10, PI * 0.90, 10, eye, maxf(1.0, r * 0.055), true)
	for side in [-1.0, 1.0]:
		for whisker in range(2):
			var start := center + Vector2(side * r * 0.44, r * (0.15 + whisker * 0.13))
			var finish := start + Vector2(side * r * 0.55, r * (-0.08 + whisker * 0.15))
			canvas.draw_line(start, finish, Color(eye, 0.72), maxf(1.0, r * 0.045), true)
	if given:
		canvas.draw_arc(center, r * 1.18, -PI * 0.9, PI * 0.28, 24, Color("ffe29a"), maxf(2.0, r * 0.10), true)
		canvas.draw_colored_polygon(PackedVector2Array([
			center + Vector2(r * 0.72, r * 0.64), center + Vector2(r * 1.00, r * 0.92), center + Vector2(r * 0.58, r * 1.00)
		]), Color("f2b94e"))


func _draw_x_mark(canvas: CanvasItem, center: Vector2, radius: float, manual: bool) -> void:
	var shadow := Color("5b3548", 0.28)
	var color := Color("6c3d57", 0.90) if manual else Color("fff8ef", 0.88)
	var width := maxf(2.2, radius * (0.22 if manual else 0.16))
	for offset in [Vector2(-radius, -radius), Vector2(-radius, radius)]:
		var finish := center + Vector2(-offset.x, offset.y)
		canvas.draw_line(center + offset + Vector2(1.5, 2), finish + Vector2(1.5, 2), shadow, width + 1.5, true)
		canvas.draw_line(center + offset, finish, color, width, true)
	if manual:
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			canvas.draw_circle(center + corner * radius, width * 0.52, Color("f2bed2"))


func _draw_selection(canvas: CanvasItem, board_size: int, cell_size: float, now: float, reduced_effects: bool) -> void:
	if selected.x < 0 or selected.x >= board_size or selected.y < 0 or selected.y >= board_size:
		return
	var rect := Rect2(BOARD_RECT.position + Vector2(selected) * cell_size, Vector2.ONE * cell_size).grow(-5.0)
	var pulse := 1.0
	if not reduced_effects:
		var age := maxf(0.0, now - selected_started)
		pulse = 0.72 + minf(1.0, age / 0.24) * 0.28
	var color := Color("6f3655", 0.92)
	var tick := cell_size * 0.22 * pulse
	for corner_value in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var corner: Vector2 = corner_value
		var p := rect.get_center() + corner * rect.size * 0.5
		var inward := -corner
		canvas.draw_line(p, p + Vector2(inward.x * tick, 0), color, 2.4, true)
		canvas.draw_line(p, p + Vector2(0, inward.y * tick), color, 2.4, true)
	_draw_paw(canvas, rect.position + Vector2(11, 11), Color("fff8ef", 0.92), 0.32)


func _draw_board_event(canvas: CanvasItem, state: Dictionary, now: float, ui_font: Font, reduced_effects: bool) -> void:
	var age := now - event_started
	if age < 0.0:
		return
	var board_size := int(state.get("size", 0))
	var position := cell_center(event_cell, board_size) if event_cell.x >= 0 else BOARD_RECT.get_center()
	if event_kind in ["error", "loss"] and age < 0.72:
		var fade := 1.0 - clampf(age / 0.72, 0.0, 1.0)
		for claw in range(3):
			var y := -15.0 + float(claw) * 14.0
			var length := 32.0 + float(claw) * 4.0
			canvas.draw_line(position + Vector2(-length, y - 6), position + Vector2(length, y + 6), Color("f04f76", 0.86 * fade), 4.0, true)
			canvas.draw_line(position + Vector2(-length + 4, y - 8), position + Vector2(length - 4, y + 4), Color("ffd1dc", 0.62 * fade), 1.5, true)
		if event_kind == "loss":
			_draw_broken_heart(canvas, BOARD_RECT.get_center(), 28.0, Color("ec5479", fade))
	elif event_kind == "cat" and age < 0.62:
		var t := clampf(age / 0.62, 0.0, 1.0)
		var fade := 1.0 - clampf((t - 0.58) / 0.42, 0.0, 1.0)
		var size := 34.0 + sin(minf(1.0, t / 0.58) * PI) * (12.0 if not reduced_effects else 3.0)
		_draw_texture_contain(canvas, PAW_REWARD_TEXTURE, position + Vector2(0, -4), Vector2(size, size), Color(1, 1, 1, fade * 0.88))
		canvas.draw_arc(position, 18.0 + t * 26.0, 0, TAU, 28, Color("fff8ed", fade * 0.72), 2.2, true)
	elif event_kind == "complete" and age < 1.18:
		var t := clampf(age / 1.18, 0.0, 1.0)
		var fade := 1.0 - clampf((t - 0.70) / 0.30, 0.0, 1.0)
		canvas.draw_rect(BOARD_RECT, Color("ffd86e", 0.10 * fade))
		var texture_size := 92.0 + sin(minf(1.0, t / 0.62) * PI) * (34.0 if not reduced_effects else 5.0)
		_draw_texture_contain(canvas, PAW_REWARD_TEXTURE, BOARD_RECT.get_center(), Vector2(texture_size, texture_size), Color(1, 1, 1, fade))
		for ring in range(3 if not reduced_effects else 1):
			var ring_t := clampf((t - float(ring) * 0.08) / 0.80, 0.0, 1.0)
			canvas.draw_arc(BOARD_RECT.get_center(), 48.0 + ring_t * (74.0 + ring * 18.0), 0, TAU, 44, Color("ffe7a0", fade * (0.68 - ring * 0.14)), 3.0, true)
	if event_kind in ["mark", "unmark", "erase_mark", "erase_cat", "cat", "error", "loss", "complete"] and age < 0.92:
		var label: String = str({
			"mark":"排除", "unmark":"擦去标记", "erase_mark":"擦去标记", "erase_cat":"抱回猫咪",
			"cat":"找到猫咪", "error":"失去一颗心", "loss":"爱心用尽", "complete":"全员到齐",
		}.get(event_kind, ""))
		if not label.is_empty():
			_draw_event_label(canvas, ui_font, label, Vector2(270, 728), Color("6e3654" if event_kind not in ["error", "loss"] else "9d2e50"), 1.0 - clampf(age / 0.92, 0.0, 1.0))


func _draw_footer(canvas: CanvasItem, state: Dictionary, ui_font: Font) -> void:
	_draw_box(canvas, Rect2(40, 704, 460, 82), 17.0, Color("fff1f7", 0.96), Color("d981a8", 0.54), 1)
	_draw_texture_contain(canvas, PAW_REWARD_TEXTURE, Vector2(76, 745), Vector2(52, 46), Color(1, 1, 1, 0.94))
	var placed := int(state.get("placed", 0))
	var required := int(state.get("required", 0))
	_draw_text(canvas, ui_font, "猫咪 %d/%d" % [placed, required], Vector2(108, 735), 16, Color("5d2e49"))
	_draw_text(canvas, ui_font, "单击选格或标记 · 双击放猫", Vector2(108, 760), 11, Color("87566e"))
	var hearts := int(state.get("hearts", 0))
	for index in range(3):
		_draw_heart(canvas, Vector2(407 + index * 28, 744), 11.0, Color("ed5f83") if index < hearts else Color("c8aab8", 0.46))
	_draw_text(canvas, ui_font, "机会", Vector2(398, 775), 10, Color("87566e"))


func _animated_cell_rect(base: Rect2, cell: Vector2i, now: float, reduced_effects: bool) -> Rect2:
	if reduced_effects:
		return base
	var scale := 1.0
	var offset := Vector2.ZERO
	if cell == selected:
		var selection_age := now - selected_started
		if selection_age >= 0.0 and selection_age < 0.24:
			var t := clampf(selection_age / 0.24, 0.0, 1.0)
			scale *= 1.0 - sin(t * PI) * 0.07
	if cell == event_cell:
		var age := now - event_started
		if event_kind in ["error", "loss"] and age >= 0.0 and age < 0.34:
			offset.x = sin(age * 100.0) * 4.4 * (1.0 - age / 0.34)
		elif event_kind == "cat" and age >= 0.0 and age < 0.42:
			scale *= 1.0 + sin(age / 0.42 * PI) * 0.09
	var center := base.get_center() + offset
	var size := base.size * scale
	return Rect2(center - size * 0.5, size)


func _draw_event_label(canvas: CanvasItem, font: Font, text: String, center: Vector2, color: Color, alpha: float) -> void:
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	var rect := Rect2(center - Vector2(maxf(80.0, text_size.x + 30.0) * 0.5, 16), Vector2(maxf(80.0, text_size.x + 30.0), 32))
	_draw_box(canvas, Rect2(rect.position + Vector2(0, 3), rect.size), 16.0, Color("4c2338", 0.18 * alpha))
	_draw_box(canvas, rect, 16.0, Color(color, 0.92 * alpha), Color("fff7ee", 0.42 * alpha), 1)
	_draw_text(canvas, font, text, center + Vector2(-text_size.x * 0.5, 4), 12, Color("fff9f1", alpha))


func _draw_paw(canvas: CanvasItem, center: Vector2, color: Color, scale: float) -> void:
	canvas.draw_circle(center + Vector2(0, 3) * scale, 7.0 * scale, color)
	for index in range(4):
		var angle := -2.55 + float(index) * 0.72
		canvas.draw_circle(center + Vector2(cos(angle), sin(angle)) * 10.0 * scale, 3.0 * scale, color)


func _draw_heart(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	canvas.draw_circle(center + Vector2(-radius * 0.38, -radius * 0.18), radius * 0.50, color)
	canvas.draw_circle(center + Vector2(radius * 0.38, -radius * 0.18), radius * 0.50, color)
	canvas.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-radius * 0.82, 0), center + Vector2(radius * 0.82, 0), center + Vector2(0, radius * 1.05)
	]), color)
	canvas.draw_arc(center + Vector2(-radius * 0.26, -radius * 0.28), radius * 0.22, -PI * 0.85, -PI * 0.25, 8, Color("ffffff", color.a * 0.44), 1.2, true)


func _draw_broken_heart(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	_draw_heart(canvas, center, radius, color)
	var cut := PackedVector2Array([
		center + Vector2(-3, -radius * 0.70), center + Vector2(5, -radius * 0.18),
		center + Vector2(-3, radius * 0.08), center + Vector2(5, radius * 0.75),
	])
	canvas.draw_polyline(cut, Color("fff3f6", color.a), 4.0, true)


func _draw_texture_contain(canvas: CanvasItem, texture: Texture2D, center: Vector2, bounds: Vector2, modulate: Color) -> void:
	if texture == null:
		return
	var source := texture.get_size()
	var scale := minf(bounds.x / maxf(1.0, source.x), bounds.y / maxf(1.0, source.y))
	var target := source * scale
	canvas.draw_texture_rect(texture, Rect2(center - target * 0.5, target), false, modulate)


func _data_cells(value: Variant) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not value is Array:
		return result
	for item in value:
		result.append(_data_cell(item))
	return result


func _data_cell(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i(-1, -1)


func _draw_text(canvas: CanvasItem, font: Font, text: String, position: Vector2, size: int, color: Color) -> void:
	canvas.draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw_box(canvas: CanvasItem, rect: Rect2, radius: float, fill: Color, border := Color.TRANSPARENT, border_width := 0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_corner_radius_all(int(radius))
	style.set_border_width_all(border_width)
	canvas.draw_style_box(style, rect)
