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
			canvas.draw_rect(Rect2(0, 112, view_size.x, view_size.y - 112), Color("1c102a"))
			# Quiet flight-cloth seams support the generated board pieces without
			# introducing false arrows outside the authoritative grid.
			for seam in range(12):
				var y := 172.0 + float(seam) * 61.0
				var drift := sin(elapsed * 0.22 + float(seam) * 0.71) * 7.0
				canvas.draw_line(Vector2(-20, y + drift), Vector2(560, y + 18.0 + drift), Color("efcde8", 0.022 + float(seam % 3) * 0.007), 1.0)
			for stud in range(8):
				var p := Vector2(32.0 + fposmod(float(stud * 173), 476.0), 186.0 + fposmod(float(stud * 109), 674.0))
				canvas.draw_circle(p + Vector2(1, 2), 4.0, Color("08030c", 0.22))
				canvas.draw_circle(p, 2.4, Color("d3a45b", 0.17))
			canvas.draw_circle(Vector2(470, 820), 110, Color("c66c77", 0.035))
		"amaze":
			canvas.draw_rect(Rect2(0, 112, view_size.x, view_size.y - 112), Color("28192d"))
			# Quiet code-native workshop edges frame the interactive canvas. The
			# generated hero remains the signature asset; these props never pretend
			# to be traversable cells or bake gameplay into a background plate.
			canvas.draw_circle(Vector2(-34, 290), 118, Color("ff739e", 0.10))
			canvas.draw_circle(Vector2(-34, 290), 82, Color("ffb26f", 0.08))
			canvas.draw_circle(Vector2(574, 788), 142, Color("4ed8cf", 0.075))
			for groove in range(12):
				var y := 182.0 + float(groove) * 58.0
				canvas.draw_line(Vector2(18, y), Vector2(522, y + 11.0), Color("fff0df", 0.022 + float(groove % 3) * 0.006), 1.0)
			for dab in range(13):
				var palette := [Color("ff739e"), Color("ff9b75"), Color("f2c85b"), Color("4ed8cf")]
				var p := Vector2(18.0 + fposmod(float(dab * 193), 504.0), 184.0 + fposmod(float(dab * 127), 666.0))
				canvas.draw_circle(p, 2.0 + float(dab % 3), Color(palette[dab % palette.size()], 0.13))
			canvas.draw_line(Vector2(24, 850), Vector2(516, 850), Color("fff0df", 0.15), 5.0)


func shake_offset(effect: Dictionary, now: float) -> Vector2:
	if bool(effect.get("reduced", false)) or bool(effect.get("reduced_effects", false)):
		return Vector2.ZERO
	var age := now - float(effect.get("started", now))
	var grade := clampi(int(effect.get("grade", 1)), 1, 4)
	if str(effect.get("game_id", "")) == "tripeaks":
		var kind := str(effect.get("kind", ""))
		# Paper-card intent stays local. Only semantic success/failure impact may
		# move the board, and never before the impact phase.
		if grade < 2 or "reject" in kind or kind in ["card_draw", "card_reveal"]:
			return Vector2.ZERO
		var impact_start := float(effect.get("duration", 0.72)) * 0.36
		age -= impact_start
		if age < 0.0:
			return Vector2.ZERO
		var tripeaks_duration := 0.08 + float(grade) * 0.035
		if age >= tripeaks_duration:
			return Vector2.ZERO
		var tripeaks_envelope := pow(1.0 - age / tripeaks_duration, 2.1)
		var tripeaks_amplitude: float = [0.0, 0.7, 1.8, 3.1][grade - 1]
		var tripeaks_phase := float(effect.get("seed", 0)) * 0.41
		return Vector2(sin(age * 88.0 + tripeaks_phase), sin(age * 121.0 + tripeaks_phase * 1.6)) * tripeaks_amplitude * tripeaks_envelope
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
	if bool(effect.get("reduced_effects", false)):
		# Reduced-effects keeps the semantic anchor and readable CJK label, but
		# replaces particles, repeated rings and shake with one quiet local outline.
		var reduced_fade := 1.0 - _ease_out_cubic(clampf((t - 0.50) / 0.50, 0.0, 1.0))
		canvas.draw_arc(position, 15.0 + t * 7.0, 0, TAU, 24, Color(color, 0.54 * reduced_fade), 2.0, true)
		var reduced_label := str(effect.get("label", ""))
		if not reduced_label.is_empty():
			var reduced_label_position: Vector2 = effect.get("label_position", position + Vector2(0, -46))
			_draw_event_label(canvas, reduced_label_position, reduced_label, color, reduced_fade, label_font, 11)
		return

	var rejected := "error" in kind or "reject" in kind or "mismatch" in kind or (game_id == "amaze_go" and kind == "arrow_loss")
	if bool(effect.get("reduced", false)) and game_id == "merge2048":
		# A short semantic ring retains acknowledgment without screen shake,
		# particle travel, or layered high-amplitude flashes.
		canvas.draw_arc(position, 23.0 + t * 8.0, 0, TAU, 28, Color(color.lightened(0.22), 0.46 * fade), 2.0, true)
	elif rejected and game_id not in ["meowdoku", "sudoku"]:
		if game_id == "tripeaks":
			_draw_tripeaks_reject_event(canvas, effect, position, t, fade)
		else:
			_draw_reject_event(canvas, position, color, grade, t, fade)
	else:
		match game_id:
			"merge2048": _draw_merge_event(canvas, position, color, grade, t, peak, fade)
			"watermelon": _draw_fruit_event(canvas, position, color, grade, t, peak, fade)
			"meowdoku": _draw_paw_event(canvas, position, color, kind, grade, t, fade)
			"sudoku": _draw_logic_event(canvas, position, color, kind, grade, t, fade)
			"solitaire", "tripeaks": _draw_card_event(canvas, game_id, kind, position, color, grade, t, peak, fade, symbol_font, effect)
			"mahjong": _draw_jade_event(canvas, position, color, grade, t, fade)
			"tileclub": _draw_stitch_event(canvas, position, color, grade, t, fade)
			"amaze_go": _draw_clearance_event(canvas, position, color, grade, t, fade, effect.get("direction", [1, 0]))
			"arrow_go": _draw_arrow_event(canvas, position, color, grade, t, fade, effect.get("direction", [1, 0]))
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


func _draw_tripeaks_reject_event(canvas: CanvasItem, effect: Dictionary, p: Vector2, t: float, fade: float) -> void:
	var reason := str(effect.get("reason", ""))
	var card_rect := Rect2(p - Vector2(21, 29), Vector2(42, 58))
	_draw_rounded_box(canvas, card_rect, 6.0, Color("3b1633", 0.30 * fade))
	canvas.draw_arc(p, 25.0 + t * 7.0, -PI * 0.84, PI * 0.16, 22, Color("ff8298", 0.38 * fade), 1.8, true)
	if reason == "locked":
		# Crossing paper straps repeat the actual blocker relationship; the lock
		# stays inside the attempted card instead of becoming a global warning.
		var tighten := 3.0 * sin(clampf(t / 0.36, 0.0, 1.0) * PI)
		canvas.draw_line(card_rect.position + Vector2(6 + tighten, 9), card_rect.end - Vector2(6 + tighten, 9), Color("f0c664", 0.88 * fade), 3.4, true)
		canvas.draw_line(Vector2(card_rect.end.x - 6 - tighten, card_rect.position.y + 9), Vector2(card_rect.position.x + 6 + tighten, card_rect.end.y - 9), Color("f0c664", 0.72 * fade), 3.0, true)
		canvas.draw_arc(p + Vector2(0, -2), 7.0, PI, TAU, 14, Color("ffd988", 0.92 * fade), 2.4, true)
		_draw_rounded_box(canvas, Rect2(p + Vector2(-8, -1), Vector2(16, 13)), 3.0, Color("d85870", 0.90 * fade))
		canvas.draw_circle(p + Vector2(0, 5), 1.8, Color("fff1c5", fade))
	else:
		# A rank rejection uses a paper-edge bracket and local zigzag; it never
		# resembles the crossing blocker straps above.
		for side_value in [-1.0, 1.0]:
			var side := float(side_value)
			var x: float = p.x + side * (18.0 + t * 5.0)
			canvas.draw_line(Vector2(x, p.y - 18), Vector2(x, p.y + 18), Color("ffd0d8", 0.76 * fade), 2.2, true)
			canvas.draw_line(Vector2(x, p.y - 18), Vector2(x - side * 7.0, p.y - 18), Color("ffd0d8", 0.76 * fade), 2.2, true)
			canvas.draw_line(Vector2(x, p.y + 18), Vector2(x - side * 7.0, p.y + 18), Color("ffd0d8", 0.76 * fade), 2.2, true)
		_draw_zigzag(canvas, p + Vector2(-14, 0), p + Vector2(14, 0), Color("ff657d", fade), 4.0, 3.0)


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


func _draw_card_event(canvas: CanvasItem, game_id: String, kind: String, p: Vector2, color: Color, grade: int, t: float, peak: float, fade: float, symbol_font: Font, effect: Dictionary) -> void:
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
	if game_id == "tripeaks":
		_draw_tripeaks_card_event(canvas, effect, kind, p, color, grade, t, peak, fade, symbol_font)
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


func _draw_tripeaks_card_event(canvas: CanvasItem, effect: Dictionary, kind: String, p: Vector2, color: Color, grade: int, t: float, peak: float, fade: float, symbol_font: Font) -> void:
	var suits := ["♥", "♠", "♦", "♣"]
	if kind == "card_draw":
		var draw_radius := 19.0 + t * 17.0
		canvas.draw_arc(p, draw_radius, -PI * 0.92, PI * 0.18, 24, Color("d8b9fa", 0.62 * fade), 2.2, true)
		canvas.draw_line(p + Vector2(-25, 18), p + Vector2(lerpf(-25.0, 21.0, t), 18), Color("f6d77c", 0.54 * fade), 2.0, true)
		return
	if kind == "card_reveal":
		var edge_width := maxf(1.5, 20.0 * abs(cos(t * PI)))
		canvas.draw_line(p + Vector2(-edge_width, 31), p + Vector2(edge_width, 31), Color("f5d985", 0.68 * fade), 2.0, true)
		canvas.draw_arc(p, 17.0 + t * 12.0, -PI * 0.90, PI * 0.08, 20, Color("d9bcfb", 0.40 * fade), 1.8, true)
		return
	if kind == "tripeaks_loss":
		var contraction := lerpf(44.0, 20.0, clampf(t / 0.58, 0.0, 1.0))
		var dusk := Color("ff7188", 0.72 * fade)
		canvas.draw_polyline(PackedVector2Array([
			p + Vector2(-contraction, 13), p + Vector2(-contraction * 0.50, -10), p,
			p + Vector2(contraction * 0.50, -10), p + Vector2(contraction, 13),
		]), dusk, 2.7, true)
		canvas.draw_line(p + Vector2(-21, 25), p + Vector2(21, 25), Color("ffd0d7", 0.68 * fade), 3.0, true)
		canvas.draw_circle(p, 8.0 + peak * 4.0, Color("7f263f", 0.46 * fade))
		return

	var milestone := kind == "peak_milestone"
	var won := kind == "tripeaks_win"
	var ridge_half_width := 34.0 + float(grade) * 4.0
	var ridge_height := 18.0 + t * (17.0 + float(grade) * 5.0)
	var route := PackedVector2Array([
		p + Vector2(-ridge_half_width, 17),
		p + Vector2(-ridge_half_width * 0.52, -ridge_height * 0.55),
		p,
		p + Vector2(ridge_half_width * 0.52, -ridge_height * 0.55),
		p + Vector2(ridge_half_width, 17),
	])
	canvas.draw_polyline(route, Color(color.lightened(0.20), 0.68 * fade), 2.2 + float(grade) * 0.38, true)
	if milestone or won:
		var moon_radius := 17.0 + peak * (4.0 + float(grade))
		canvas.draw_circle(p + Vector2(0, -42), moon_radius, Color("fff1b3", 0.22 * fade))
		canvas.draw_circle(p + Vector2(7, -47), moon_radius * 0.88, Color("35204f", 0.72 * fade))
		var active_peak := int(effect.get("peak_index", -1))
		for summit in range(3):
			var summit_x := p.x + (float(summit) - 1.0) * 28.0
			var lit := won or summit == active_peak
			canvas.draw_circle(Vector2(summit_x, p.y + 8), 4.2 + peak * 2.4, Color("fff0a5", (0.90 if lit else 0.24) * fade))
	var suit_count := mini(1 + grade, 5)
	for index in range(suit_count):
		var spread := (float(index) - float(suit_count - 1) * 0.5) * 17.0
		var q := p + Vector2(spread, -13.0 - t * (20.0 + float(index % 2) * 7.0) - peak * 4.0)
		canvas.draw_string(symbol_font, q, suits[index % suits.size()], HORIZONTAL_ALIGNMENT_CENTER, 15.0, 9 + grade, Color(color.lightened(0.24), fade))
	if won:
		canvas.draw_arc(p, 55.0 + t * 18.0, -PI * 0.92, PI * 0.10, 30, Color("f7d36f", 0.56 * fade), 3.2, true)


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


func _draw_clearance_event(canvas: CanvasItem, p: Vector2, color: Color, grade: int, t: float, fade: float, direction_value: Variant) -> void:
	var direction := Vector2.RIGHT
	if direction_value is Array and direction_value.size() >= 2:
		direction = Vector2(float(direction_value[0]), float(direction_value[1])).normalized()
	elif direction_value is Vector2i or direction_value is Vector2:
		direction = Vector2(direction_value).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var side := Vector2(-direction.y, direction.x)
	var lane_count := 2 + mini(grade, 3)
	for index in range(lane_count):
		var lane_t := clampf((t - float(index) * 0.055) / 0.78, 0.0, 1.0)
		var center := p + direction * (12.0 + lane_t * (20.0 + float(grade) * 5.0)) + side * (float(index) - float(lane_count - 1) * 0.5) * 7.0
		canvas.draw_line(center - direction * 4.5, center + direction * 4.5, Color(color.lightened(0.22), fade * (0.84 - float(index) * 0.10)), 2.2, true)
	canvas.draw_arc(p, 15.0 + t * (13.0 + float(grade) * 3.0), 0, TAU, 28, Color(color.lightened(0.18), 0.46 * fade), 2.0, true)


func _draw_arrow_event(canvas: CanvasItem, p: Vector2, color: Color, grade: int, t: float, fade: float, direction_value: Variant) -> void:
	var direction := Vector2.RIGHT
	if direction_value is Array and direction_value.size() >= 2:
		direction = Vector2(float(direction_value[0]), float(direction_value[1])).normalized()
	elif direction_value is Vector2i or direction_value is Vector2:
		direction = Vector2(direction_value).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var side := Vector2(-direction.y, direction.x)
	for index in range(3 + grade):
		var distance := -18.0 + float(index) * 14.0 + t * 30.0
		_draw_chevron(canvas, p + direction * distance + side * sin(float(index) * 1.7) * 2.0, direction, 10.0 + grade, Color(color, fade * (0.8 - index * 0.07)))
	canvas.draw_arc(p, 17.0 + t * 34.0, 0, TAU, 30, Color(color.lightened(0.24), 0.42 * fade), 2.0, true)


func _draw_paint_event(canvas: CanvasItem, p: Vector2, color: Color, grade: int, t: float, fade: float) -> void:
	# A paint response grows from a local stamp into bristles and wet droplets;
	# routine rolls stay compact so near-complete and terminal beats keep contrast.
	var press := sin(clampf(t / 0.34, 0.0, 1.0) * PI)
	var ring_t := clampf((t - 0.16) / 0.76, 0.0, 1.0)
	canvas.draw_circle(p + Vector2(1.5, 2.5), 10.0 + press * (5.0 + grade * 1.5), Color("451329", 0.34 * fade))
	canvas.draw_circle(p, 9.0 + press * (5.0 + grade * 1.7), Color(color, 0.30 * fade))
	canvas.draw_arc(p, 14.0 + ring_t * (22.0 + grade * 7.0), 0, TAU, 34, Color(color.lightened(0.25), 0.64 * fade), 2.2 + float(grade) * 0.35, true)
	for bristle in range(4 + grade * 2):
		var angle := float(bristle) / float(4 + grade * 2) * TAU + 0.18
		var direction := Vector2(cos(angle), sin(angle))
		var inner := p + direction * (13.0 + ring_t * 8.0)
		var outer := p + direction * (18.0 + ring_t * (12.0 + grade * 3.0))
		canvas.draw_line(inner, outer, Color(color.lightened(0.16), 0.74 * fade), 2.0 + float(grade) * 0.22, true)
	var count := 3 + grade * 3
	for index in range(count):
		var angle := float(index) / float(count) * TAU + float(index % 2) * 0.21
		var distance := 13.0 + ring_t * (18.0 + float(index % 3) * 5.0 + grade * 3.0)
		var q := p + Vector2(cos(angle), sin(angle)) * distance + Vector2(0, ring_t * ring_t * 7.0)
		canvas.draw_circle(q, 2.1 + float(index % 3) * 0.8 + float(grade) * 0.28, Color(color.lightened(float(index % 2) * 0.14), fade))
	if grade >= 3:
		for sparkle in range(grade):
			var angle := -PI * 0.75 + float(sparkle) / float(maxi(1, grade - 1)) * PI * 1.5
			_draw_diamond(canvas, p + Vector2(cos(angle), sin(angle)) * (28.0 + ring_t * 26.0), 3.0 + press * 2.0, Color("fff1c7", 0.88 * fade))


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
