extends RefCounted

const MERGE2048_BG: Texture2D = preload("res://assets/art/catalog/merge2048_atelier_v1.webp")
const WATERMELON_BG: Texture2D = preload("res://assets/art/catalog/watermelon_orchard_v1.webp")
const MEOWDOKU_BG: Texture2D = preload("res://assets/art/catalog/meowdoku_stationery_v1.webp")
const SOLITAIRE_BG: Texture2D = preload("res://assets/art/catalog/solitaire_conservatory_v1.webp")
const MAHJONG_BG: Texture2D = preload("res://assets/art/catalog/mahjong_teahouse_v1.webp")
const TILECLUB_BG: Texture2D = preload("res://assets/art/catalog/tileclub_craft_v1.webp")
const AMAZE_GO_BG: Texture2D = preload("res://assets/art/catalog/amaze_blueprint_v1.webp")

const TEXTURE_BACKGROUNDS := {
	"merge2048": MERGE2048_BG,
	"watermelon": WATERMELON_BG,
	"meowdoku": MEOWDOKU_BG,
	"solitaire": SOLITAIRE_BG,
	"mahjong": MAHJONG_BG,
	"tileclub": TILECLUB_BG,
	"amaze_go": AMAZE_GO_BG,
}


func draw_environment(canvas: CanvasItem, game_id: String, view_size: Vector2, elapsed: float) -> void:
	if TEXTURE_BACKGROUNDS.has(game_id):
		canvas.draw_texture_rect(TEXTURE_BACKGROUNDS[game_id], Rect2(Vector2.ZERO, view_size), false, Color.WHITE)
		match game_id:
			"merge2048": canvas.draw_rect(Rect2(0, 112, view_size.x, view_size.y - 112), Color("3b1f12", 0.10))
			"watermelon": canvas.draw_rect(Rect2(0, 112, view_size.x, view_size.y - 112), Color("4f2d1d", 0.08))
			"meowdoku": canvas.draw_rect(Rect2(0, 112, view_size.x, view_size.y - 112), Color("7b344f", 0.045))
			"solitaire": canvas.draw_rect(Rect2(0, 112, view_size.x, view_size.y - 112), Color("06281e", 0.08))
			"mahjong": canvas.draw_rect(Rect2(0, 112, view_size.x, view_size.y - 112), Color("062d24", 0.08))
			"tileclub": canvas.draw_rect(Rect2(0, 112, view_size.x, view_size.y - 112), Color("421327", 0.09))
			"amaze_go": canvas.draw_rect(Rect2(0, 112, view_size.x, view_size.y - 112), Color("061b39", 0.08))
		return

	match game_id:
		"sudoku":
			canvas.draw_rect(Rect2(0, 112, view_size.x, view_size.y - 112), Color("302a25"))
			canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(20, 196), Vector2(520, 184), Vector2(508, 804), Vector2(30, 812)
			]), Color("e9ddc7"))
			for line in range(18):
				var y := 218.0 + float(line) * 31.0
				canvas.draw_line(Vector2(32, y), Vector2(510, y - 8), Color("7f6d5a", 0.075), 1.0)
			_draw_brass_compass(canvas, Vector2(486, 852), 58.0, Color("b78f55", 0.34), elapsed * 0.08)
		"tripeaks":
			canvas.draw_rect(Rect2(0, 112, view_size.x, view_size.y - 112), Color("160f2d"))
			for star in range(26):
				var sx := fposmod(float(star * 83), 520.0) + 10.0
				var sy := fposmod(float(star * 137), 610.0) + 185.0
				var twinkle := 0.16 + sin(elapsed * 1.7 + float(star)) * 0.07
				canvas.draw_circle(Vector2(sx, sy), 0.8 + float(star % 3) * 0.35, Color("f4d9ff", twinkle))
			for peak in range(3):
				var center_x := 108.0 + float(peak) * 162.0
				canvas.draw_colored_polygon(PackedVector2Array([
					Vector2(center_x - 126, 650), Vector2(center_x, 226), Vector2(center_x + 126, 650)
				]), Color("745a9d", 0.14))
				canvas.draw_line(Vector2(center_x - 126, 650), Vector2(center_x, 226), Color("e9baff", 0.12), 3.0)
		"arrow_go":
			canvas.draw_rect(Rect2(0, 112, view_size.x, view_size.y - 112), Color("17122f"))
			for lane in range(7):
				var y := 244.0 + float(lane) * 83.0
				var shift := fposmod(elapsed * (14.0 + lane) + lane * 39.0, 96.0)
				for x in range(-1, 7):
					_draw_chevron(canvas, Vector2(float(x) * 96.0 + shift, y), Vector2.RIGHT, 12.0, Color("b69cff", 0.045 + float(lane % 2) * 0.025))
			canvas.draw_circle(Vector2(470, 820), 110, Color("704fe4", 0.05))
		"amaze":
			canvas.draw_rect(Rect2(0, 112, view_size.x, view_size.y - 112), Color("143229"))
			for blob in range(16):
				var palette := [Color("4de1a4"), Color("ff8b78"), Color("f6c667"), Color("79a7ff"), Color("d897ff")]
				var p := Vector2(fposmod(float(blob * 97), 580.0) - 20.0, 210.0 + fposmod(float(blob * 151), 690.0))
				canvas.draw_circle(p, 18.0 + float(blob % 4) * 7.0, Color(palette[blob % palette.size()], 0.045))
			canvas.draw_line(Vector2(24, 850), Vector2(516, 850), Color("f8eed2", 0.12), 5.0)


func shake_offset(effect: Dictionary, now: float) -> Vector2:
	var age := now - float(effect.get("started", now))
	var grade := clampi(int(effect.get("grade", 1)), 1, 4)
	if grade < 2 or age < 0.0:
		return Vector2.ZERO
	var duration := 0.12 + float(grade) * 0.045
	if age >= duration:
		return Vector2.ZERO
	var envelope := pow(1.0 - age / duration, 1.8)
	var amplitude: float = [0.0, 1.4, 3.4, 5.8][grade - 1]
	var phase := float(effect.get("seed", 0)) * 0.37
	return Vector2(sin(age * 92.0 + phase), sin(age * 127.0 + phase * 1.7)) * amplitude * envelope


func draw_event_fx(canvas: CanvasItem, effect: Dictionary, now: float, label_font: Font, symbol_font: Font) -> void:
	var age := now - float(effect.get("started", now))
	var duration := float(effect.get("duration", 0.72))
	if age < 0.0 or age >= duration:
		return
	var t := clampf(age / duration, 0.0, 1.0)
	var peak := sin(clampf(t / 0.58, 0.0, 1.0) * PI)
	var fade := 1.0 - _ease_out_cubic(clampf((t - 0.56) / 0.44, 0.0, 1.0))
	var position: Vector2 = effect.get("position", Vector2(270, 480))
	var color: Color = effect.get("color", Color.WHITE)
	var grade := clampi(int(effect.get("grade", 1)), 1, 4)
	var game_id := str(effect.get("game_id", ""))
	var kind := str(effect.get("kind", "event"))

	var rejected := "error" in kind or "reject" in kind or "mismatch" in kind
	if rejected and game_id not in ["meowdoku", "sudoku"]:
		_draw_reject_event(canvas, position, color, grade, t, fade)
	else:
		match game_id:
			"merge2048": _draw_merge_event(canvas, position, color, grade, t, peak, fade)
			"watermelon": _draw_fruit_event(canvas, position, color, grade, t, peak, fade)
			"meowdoku": _draw_paw_event(canvas, position, color, kind, grade, t, fade)
			"sudoku": _draw_logic_event(canvas, position, color, kind, grade, t, fade)
			"solitaire", "tripeaks": _draw_card_event(canvas, game_id, kind, position, color, grade, t, peak, fade, symbol_font)
			"mahjong": _draw_jade_event(canvas, position, color, grade, t, fade)
			"tileclub": _draw_stitch_event(canvas, position, color, grade, t, fade)
			"amaze_go": _draw_compass_event(canvas, position, color, grade, t, fade)
			"arrow_go": _draw_arrow_event(canvas, position, color, grade, t, fade)
			"amaze": _draw_paint_event(canvas, position, color, grade, t, fade)

	var label := str(effect.get("label", ""))
	if not label.is_empty() and age >= 0.08:
		var label_position := position + Vector2(0, -50.0 - float(grade) * 4.0 - peak * 8.0)
		if game_id == "meowdoku":
			# Keep dynamic CJK feedback in the folio footer so it never covers a
			# playable number or the section heading.
			label_position = Vector2(270, 705.0 - peak * 4.0)
		elif effect.has("label_position"):
			label_position = effect["label_position"]
		_draw_event_label(canvas, label_position, label, color, fade, label_font, 11 + mini(grade, 2))


func _draw_merge_event(canvas: CanvasItem, p: Vector2, color: Color, grade: int, t: float, peak: float, fade: float) -> void:
	for ring in range(grade + 1):
		var ring_t := clampf((t - float(ring) * 0.055) / 0.82, 0.0, 1.0)
		if ring_t <= 0.0:
			continue
		canvas.draw_arc(p, 24.0 + ring_t * (36.0 + ring * 12.0), 0, TAU, 36, Color(color.lightened(0.28), fade * (0.62 - ring * 0.08)), 3.2 - ring * 0.35, true)
	for corner in range(4):
		var angle := PI * 0.25 + float(corner) * PI * 0.5
		var q := p + Vector2(cos(angle), sin(angle)) * (23.0 + t * (26.0 + grade * 3.0))
		_draw_diamond(canvas, q, 3.0 + peak * 3.0, Color(color, fade))
	canvas.draw_circle(p, 11.0 + peak * (8.0 + grade * 2.0), Color("fff2c7", 0.18 * fade))


func _draw_reject_event(canvas: CanvasItem, p: Vector2, _color: Color, grade: int, t: float, fade: float) -> void:
	var red := Color("ff657d", fade)
	var kick := 3.0 + float(grade) * 1.5
	_draw_zigzag(canvas, p + Vector2(-28, -kick), p + Vector2(28, kick), red, 5.0 + grade, 3.2)
	_draw_zigzag(canvas, p + Vector2(-28, kick), p + Vector2(28, -kick), Color("ffd2d9", fade * 0.70), 4.0 + grade, 2.2)
	canvas.draw_arc(p, 18.0 + t * 25.0, -PI * 0.82, PI * 0.20, 22, Color("ff8799", fade * 0.42), 2.0, true)


func _draw_fruit_event(canvas: CanvasItem, p: Vector2, color: Color, grade: int, t: float, peak: float, fade: float) -> void:
	var droplets := 7 + grade * 3
	for index in range(droplets):
		var angle := float(index) / droplets * TAU - PI * 0.5
		var distance := 13.0 + t * (28.0 + float(index % 3) * 8.0 + grade * 4.0)
		var q := p + Vector2(cos(angle), sin(angle)) * distance + Vector2(0, t * t * 18.0)
		canvas.draw_circle(q, 2.0 + peak * 2.8, Color(color.lightened(0.22), fade))
	for leaf in range(maxi(1, grade - 1)):
		var leaf_p := p + Vector2(-22.0 + leaf * 22.0, -18.0 - peak * 14.0)
		_draw_leaf(canvas, leaf_p, 7.0 + grade, Color("78b95b", fade), -0.7 + leaf * 0.8)
	canvas.draw_arc(p, 18.0 + t * 34.0, PI * 0.08, PI * 0.92, 24, Color("fff4c4", 0.64 * fade), 4.0, true)


func _draw_paw_event(canvas: CanvasItem, p: Vector2, color: Color, kind: String, grade: int, t: float, fade: float) -> void:
	if "error" in kind:
		_draw_zigzag(canvas, p + Vector2(-25, 0), p + Vector2(25, 0), Color("ff5c78", fade), 7.0, 4.0)
		for claw in range(3):
			var claw_x := -10.0 + float(claw) * 10.0
			canvas.draw_line(p + Vector2(claw_x - 4, -17), p + Vector2(claw_x + 3, -7), Color("ffb4c8", 0.76 * fade), 2.0, true)
		return
	if "erase" in kind:
		canvas.draw_line(p + Vector2(-24, 8), p + Vector2(lerpf(-24.0, 24.0, t), 8), Color("f5a6bc", 0.58 * fade), 3.0, true)
		return
	var scale := 0.6 + _ease_out_cubic(clampf(t / 0.42, 0.0, 1.0)) * (0.58 + grade * 0.08)
	_draw_paw(canvas, p, Color(color, 0.74 * fade), scale)
	var ring_count := 2 if "block" in kind else (3 if "complete" in kind else 1)
	for ring in range(ring_count):
		var ring_t := clampf((t - float(ring) * 0.08) / 0.82, 0.0, 1.0)
		canvas.draw_arc(p, 16.0 + ring_t * (32.0 + ring * 11.0), 0, TAU, 28, Color("fff6fb", (0.62 - ring * 0.12) * fade), 2.5, true)


func _draw_logic_event(canvas: CanvasItem, p: Vector2, color: Color, kind: String, grade: int, t: float, fade: float) -> void:
	if "error" in kind:
		_draw_zigzag(canvas, p + Vector2(-27, -12), p + Vector2(27, 12), Color("d64f5f", fade), 6.0, 3.6)
		return
	var radius := 12.0 + t * (30.0 + grade * 5.0)
	canvas.draw_arc(p, radius, -PI * 0.74, PI * 0.74, 28, Color(color, 0.72 * fade), 2.5, true)
	canvas.draw_line(p - Vector2(radius * 0.72, 0), p + Vector2(radius * 0.72, 0), Color(color, 0.32 * fade), 1.5, true)
	canvas.draw_line(p - Vector2(0, radius * 0.72), p + Vector2(0, radius * 0.72), Color(color, 0.32 * fade), 1.5, true)


func _draw_card_event(canvas: CanvasItem, game_id: String, kind: String, p: Vector2, color: Color, grade: int, t: float, peak: float, fade: float, symbol_font: Font) -> void:
	var suits := ["♥", "♠", "♦", "♣"]
	if game_id == "solitaire":
		var foundation_event := "foundation" in kind or "win" in kind
		var ring_count := grade if foundation_event else 1
		for ring in range(ring_count):
			var ring_t := clampf((t - float(ring) * 0.07) / 0.72, 0.0, 1.0)
			if ring_t <= 0.0:
				continue
			var radius := 16.0 + ring_t * (22.0 + float(grade) * 5.0 + float(ring) * 6.0)
			canvas.draw_arc(p, radius, -PI * 0.82, PI * 0.82, 28, Color("f8d98f", fade * (0.64 - float(ring) * 0.09)), 2.8, true)
		if foundation_event:
			var count := 2 + grade * 2
			for index in range(count):
				var angle := -PI * 0.5 + float(index) / float(maxi(1, count - 1)) * PI
				var travel := 18.0 + t * (24.0 + float(grade) * 5.0)
				var q := p + Vector2(cos(angle), sin(angle)) * travel + Vector2(0, t * t * 8.0)
				canvas.draw_string(symbol_font, q, suits[index % suits.size()], HORIZONTAL_ALIGNMENT_CENTER, 16.0, 9 + grade, Color(color.lightened(0.16), fade))
		if "win" in kind:
			for side in [-1.0, 1.0]:
				var stem_start := p + Vector2(18.0 * side, 17.0)
				var stem_end := p + Vector2((42.0 + t * 18.0) * side, -28.0 - peak * 7.0)
				canvas.draw_line(stem_start, stem_end, Color("f1c96f", 0.74 * fade), 3.0, true)
				for leaf in range(4):
					var leaf_t := (float(leaf) + 1.0) / 5.0
					var leaf_center := stem_start.lerp(stem_end, leaf_t)
					_draw_leaf(canvas, leaf_center, 5.0 + peak * 1.5, Color("8bc99b", fade), -0.8 * side)
		return
	var climb := 18.0 + t * (26.0 + float(grade) * 7.0)
	var ridge := PackedVector2Array([
		p + Vector2(-42.0, 16.0),
		p + Vector2(-18.0, -climb * 0.55),
		p,
		p + Vector2(18.0, -climb * 0.55),
		p + Vector2(42.0, 16.0),
	])
	canvas.draw_polyline(ridge, Color(color.lightened(0.18), 0.52 * fade), 2.4 + float(grade) * 0.35, true)
	var suit_count := 1 + grade
	for index in range(suit_count):
		var spread := (float(index) - float(suit_count - 1) * 0.5) * 18.0
		var q := p + Vector2(spread, -16.0 - t * (24.0 + float(index % 2) * 9.0) - peak * 5.0)
		canvas.draw_string(symbol_font, q, suits[index % suits.size()], HORIZONTAL_ALIGNMENT_CENTER, 16.0, 10 + grade, Color(color.lightened(0.22), fade))
	if grade >= 3:
		var crown_y := -40.0 - t * 10.0
		canvas.draw_colored_polygon(PackedVector2Array([
			p + Vector2(-16, crown_y + 10), p + Vector2(-13, crown_y),
			p + Vector2(-4, crown_y + 7), p + Vector2(0, crown_y - 4),
			p + Vector2(5, crown_y + 7), p + Vector2(14, crown_y),
			p + Vector2(17, crown_y + 10),
		]), Color("f7cf70", (0.60 + peak * 0.22) * fade))


func _draw_jade_event(canvas: CanvasItem, p: Vector2, color: Color, grade: int, t: float, fade: float) -> void:
	for ring in range(2 + grade):
		var offset := float(ring) * 0.06
		var rt := clampf((t - offset) / 0.76, 0.0, 1.0)
		if rt > 0.0:
			canvas.draw_arc(p, 18.0 + rt * (25.0 + ring * 9.0), 0, TAU, 38, Color(color.lightened(0.20), fade * (0.65 - ring * 0.08)), 3.0, true)
	for index in range(grade * 2):
		var angle := float(index) / maxi(1, grade * 2) * TAU
		_draw_diamond(canvas, p + Vector2(cos(angle), sin(angle)) * (24.0 + t * 24.0), 3.5, Color("f6e8bd", fade))


func _draw_stitch_event(canvas: CanvasItem, p: Vector2, color: Color, grade: int, t: float, fade: float) -> void:
	var radius := 18.0 + t * (32.0 + grade * 5.0)
	for stitch in range(12 + grade * 4):
		var angle := float(stitch) / float(12 + grade * 4) * TAU
		var tangent := Vector2(-sin(angle), cos(angle))
		var center := p + Vector2(cos(angle), sin(angle)) * radius
		canvas.draw_line(center - tangent * 3.0, center + tangent * 3.0, Color(color.lightened(0.18), fade), 2.0, true)
	canvas.draw_circle(p, 9.0 + grade * 2.0, Color(color, 0.24 * fade))
	canvas.draw_circle(p + Vector2(-4, -2), 2.0, Color("fff2d2", fade))
	canvas.draw_circle(p + Vector2(4, 2), 2.0, Color("fff2d2", fade))


func _draw_compass_event(canvas: CanvasItem, p: Vector2, color: Color, grade: int, t: float, fade: float) -> void:
	_draw_brass_compass(canvas, p, 18.0 + t * (28.0 + grade * 5.0), Color(color, 0.74 * fade), t * PI * 0.75)


func _draw_arrow_event(canvas: CanvasItem, p: Vector2, color: Color, grade: int, t: float, fade: float) -> void:
	for index in range(3 + grade):
		var distance := -18.0 + float(index) * 14.0 + t * 30.0
		_draw_chevron(canvas, p + Vector2(distance, 0), Vector2.RIGHT, 10.0 + grade, Color(color, fade * (0.8 - index * 0.07)))
	canvas.draw_arc(p, 17.0 + t * 34.0, 0, TAU, 30, Color(color.lightened(0.24), 0.42 * fade), 2.0, true)


func _draw_paint_event(canvas: CanvasItem, p: Vector2, color: Color, grade: int, t: float, fade: float) -> void:
	var count := 7 + grade * 3
	for index in range(count):
		var angle := float(index) / count * TAU + float(index % 2) * 0.2
		var q := p + Vector2(cos(angle), sin(angle)) * (10.0 + t * (23.0 + grade * 5.0 + index % 3 * 5.0))
		canvas.draw_circle(q, 2.8 + float(index % 3), Color(color.lightened(float(index % 2) * 0.14), fade))
	canvas.draw_circle(p, 11.0 + grade * 2.0, Color(color, 0.18 * fade))


func _draw_event_label(canvas: CanvasItem, center: Vector2, label: String, color: Color, alpha: float, font: Font, font_size: int) -> void:
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var width := maxf(76.0, text_size.x + 28.0)
	var rect := Rect2(center - Vector2(width * 0.5, 15), Vector2(width, 30))
	_draw_rounded_box(canvas, Rect2(rect.position + Vector2(0, 3), rect.size), 15.0, Color("080d19", 0.38 * alpha))
	_draw_rounded_box(canvas, rect, 15.0, Color(color.darkened(0.34), 0.93 * alpha))
	canvas.draw_string(font, center + Vector2(-text_size.x * 0.5, font_size * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("fff9ee", alpha))


func _draw_brass_compass(canvas: CanvasItem, center: Vector2, radius: float, color: Color, rotation: float) -> void:
	canvas.draw_circle(center, radius, Color("0b1021", color.a * 0.42))
	canvas.draw_arc(center, radius, 0, TAU, 40, color, maxf(1.5, radius * 0.07), true)
	for index in range(4):
		var angle := rotation + float(index) * PI * 0.5
		var direction := Vector2(cos(angle), sin(angle))
		var side := Vector2(-direction.y, direction.x)
		canvas.draw_colored_polygon(PackedVector2Array([
			center + direction * radius * 0.82,
			center - direction * radius * 0.22 + side * radius * 0.16,
			center - direction * radius * 0.22 - side * radius * 0.16,
		]), Color(color, color.a * (0.92 if index % 2 == 0 else 0.52)))
	canvas.draw_circle(center, maxf(2.0, radius * 0.12), Color("fff0b5", color.a))


func _draw_chevron(canvas: CanvasItem, center: Vector2, direction: Vector2, size: float, color: Color) -> void:
	var side := Vector2(-direction.y, direction.x)
	var point := center + direction * size * 0.55
	canvas.draw_line(point, center - direction * size * 0.45 + side * size * 0.55, color, maxf(1.5, size * 0.16), true)
	canvas.draw_line(point, center - direction * size * 0.45 - side * size * 0.55, color, maxf(1.5, size * 0.16), true)


func _draw_paw(canvas: CanvasItem, center: Vector2, color: Color, scale: float) -> void:
	canvas.draw_circle(center + Vector2(0, 4) * scale, 8.0 * scale, color)
	for index in range(4):
		var angle := -2.55 + float(index) * 0.72
		canvas.draw_circle(center + Vector2(cos(angle), sin(angle)) * 11.0 * scale, 3.4 * scale, color)


func _draw_leaf(canvas: CanvasItem, center: Vector2, radius: float, color: Color, rotation: float) -> void:
	var direction := Vector2(cos(rotation), sin(rotation))
	var side := Vector2(-direction.y, direction.x)
	canvas.draw_colored_polygon(PackedVector2Array([
		center - direction * radius,
		center + side * radius * 0.58,
		center + direction * radius,
		center - side * radius * 0.58,
	]), color)
	canvas.draw_line(center - direction * radius * 0.72, center + direction * radius * 0.72, Color(color.darkened(0.25), color.a), 1.2, true)


func _draw_zigzag(canvas: CanvasItem, start: Vector2, end: Vector2, color: Color, amplitude: float, width: float) -> void:
	var points := PackedVector2Array()
	var direction := start.direction_to(end)
	var side := Vector2(-direction.y, direction.x)
	for index in range(8):
		var t := float(index) / 7.0
		points.append(start.lerp(end, t) + side * amplitude * (-1.0 if index % 2 == 0 else 1.0))
	canvas.draw_polyline(points, color, width, true)


func _draw_diamond(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -radius), center + Vector2(radius, 0),
		center + Vector2(0, radius), center + Vector2(-radius, 0),
	]), color)


func _draw_rounded_box(canvas: CanvasItem, rect: Rect2, radius: float, color: Color) -> void:
	canvas.draw_style_box(_style_box(color, radius), rect)


func _style_box(color: Color, radius: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(radius))
	return box


func _ease_out_cubic(value: float) -> float:
	return 1.0 - pow(1.0 - value, 3.0)
