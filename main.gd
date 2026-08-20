extends Control

## No WiFi Games: a clean-room, offline-first Godot collection.
## Every mini-game shares the same reset/input/snapshot/result contract so the
## independent evaluator can exercise complete player-facing loops.

const VIEW_SIZE := Vector2(540.0, 960.0)
const HEADER_H := 104.0
const BOARD_TOP := 164.0
const SNAKE_STEP_INTERVAL := 0.36
const BG := Color("0b1021")
const SURFACE := Color("151d38")
const SURFACE_2 := Color("1d2747")
const INK := Color("f7f8ff")
const MUTED := Color("9ca9ca")
const CYAN := Color("5de4ff")
const VIOLET := Color("a78bfa")
const GREEN := Color("70e1a1")
const AMBER := Color("ffc857")
const RED := Color("ff708b")
const GOLD := Color("f6c667")
const PAPER := Color("f3efe2")
const NIGHT := Color("10172d")
const MINT := Color("69e3bf")
const COAL := Color("080d19")
const DEEP := Color("0e1628")
const BRIGHT_MUTED := Color("b8c2d9")
const WARM_PAPER := Color("fff8e8")
const HOME_CARD_ORIGIN := Vector2(24.0, 424.0)
const HOME_CARD_SIZE := Vector2(234.0, 58.0)
const HOME_CARD_GAP := Vector2(258.0, 68.0)
const HOME_CASE_TEXTURE: Texture2D = preload("res://assets/art/ui/open_game_case.webp")
const HOME_CARTRIDGE_TEXTURE: Texture2D = preload("res://assets/art/ui/cartridge_label.webp")
const HOME_COVER_CARTRIDGE_TEXTURE: Texture2D = preload("res://assets/art/ui/cartridge_cover_label.webp")
const HOME_COVER_TEXTURES := {
	"merge2248": preload("res://assets/art/covers/merge2248.webp"),
	"merge2048": preload("res://assets/art/covers/merge2048.webp"),
	"watermelon": preload("res://assets/art/covers/watermelon.webp"),
	"meowdoku": preload("res://assets/art/covers/meowdoku.webp"),
	"sudoku": preload("res://assets/art/covers/sudoku.webp"),
	"snake_classic": preload("res://assets/art/covers/snake_classic.webp"),
	"snake_io": preload("res://assets/art/covers/snake_io.webp"),
	"solitaire": preload("res://assets/art/covers/solitaire.webp"),
	"tripeaks": preload("res://assets/art/covers/tripeaks.webp"),
	"mahjong": preload("res://assets/art/covers/mahjong.webp"),
	"tileclub": preload("res://assets/art/covers/tileclub.webp"),
	"amaze_go": preload("res://assets/art/covers/amaze_go.webp"),
	"arrow_go": preload("res://assets/art/covers/arrow_go.webp"),
	"amaze": preload("res://assets/art/covers/amaze.webp")
}
const MERGE2248_BG_TEXTURE: Texture2D = preload("res://assets/art/merge2248/candy_workshop_bg_v2.webp")
const SNAKE_GARDEN_TEXTURE: Texture2D = preload("res://assets/art/snake/modern_garden.webp")
const SNAKE_GB_TEXTURE: Texture2D = preload("res://assets/art/snakes/gb_handheld.webp")
const SNAKES_DOODLE_TEXTURE: Texture2D = preload("res://assets/art/snakes/arena_doodles.webp")
const SNAKE_RULES = preload("res://snake_model.gd")
const SNAKE_GB_RULES = preload("res://models/snake_gb_model.gd")
const SNAKES_ARENA_RULES = preload("res://models/snakes_arena_model.gd")
const MERGE2248_RULES = preload("res://models/merge2248_model.gd")
const MERGE2248_PRESENTATION = preload("res://presentation/merge2248_presenter.gd")
const MERGE2048_CLASSIC_PRESENTATION = preload("res://presentation/merge2048_classic_presenter.gd")
const CATALOG_ART_DIRECTION = preload("res://presentation/catalog_art_director.gd")
const WATERMELON_PRESENTATION = preload("res://presentation/watermelon_presenter.gd")
const LOGIC_GAME_PRESENTATION = preload("res://presentation/logic_game_presenter.gd")
const SFX_CASE_OPEN: AudioStream = preload("res://assets/audio/ui/case_open.wav")
const SFX_SNAKE_KEY: AudioStream = preload("res://assets/audio/snake/key.wav")
const SFX_SNAKE_REJECT: AudioStream = preload("res://assets/audio/snake/reject.wav")
const SFX_SNAKE_EAT: AudioStream = preload("res://assets/audio/snake/eat.wav")
const SFX_SNAKE_CRASH: AudioStream = preload("res://assets/audio/snake/crash.wav")
const SFX_SNAKE_WIN: AudioStream = preload("res://assets/audio/snake/win.wav")
const SFX_FRUIT_DROP: AudioStream = preload("res://assets/audio/2048balls/fruit_drop.ogg")
const SFX_FRUIT_MERGE: AudioStream = preload("res://assets/audio/2048balls/fruit_merge.ogg")
const SFX_FRUIT_CASCADE: AudioStream = preload("res://assets/audio/2048balls/fruit_cascade.ogg")
const SFX_2048_SLIDE: AudioStream = preload("res://assets/audio/merge2048/tile_slide.ogg")
const SFX_2048_MERGE: AudioStream = preload("res://assets/audio/merge2048/tile_merge.ogg")
const SFX_2048_MILESTONE: AudioStream = preload("res://assets/audio/merge2048/tile_milestone.ogg")
const SFX_LOGIC_SELECT: AudioStream = preload("res://assets/audio/logic/paper_select.wav")
const SFX_LOGIC_CONFIRM: AudioStream = preload("res://assets/audio/logic/ink_confirm.wav")
const SFX_LOGIC_ERROR: AudioStream = preload("res://assets/audio/logic/correction_scratch.wav")
const SFX_LOGIC_BLOCK: AudioStream = preload("res://assets/audio/logic/block_stamp.wav")
const SFX_LOGIC_COMPLETE: AudioStream = preload("res://assets/audio/logic/folio_complete.wav")
const SFX_MEOW_GAG_COMPLETE: AudioStream = preload("res://assets/audio/logic/gag-v1/meowdoku_complete_reward.ogg")

var catalog: Array = [
	{"id":"merge2248", "title":"2248", "subtitle":"数字连线", "group":"数字", "accent":Color("ffbf2f"), "desc":"八方向连接数字，把相邻数合成到 2048"},
	{"id":"merge2048", "title":"2048", "subtitle":"滑动合成", "group":"数字", "accent":Color("f4b860"), "desc":"用四个方向合成更大的数字"},
	{"id":"watermelon", "title":"2048 Balls", "subtitle":"合成大西瓜", "group":"数字", "accent":Color("ff6b8a"), "desc":"落下水果，让相同水果合体"},
	{"id":"meowdoku", "title":"Meowdoku", "subtitle":"猫咪数独", "group":"数独", "accent":Color("f39ac7"), "desc":"轻松填完九宫格，零网络也能玩"},
	{"id":"sudoku", "title":"Sudoku", "subtitle":"传统数独", "group":"数独", "accent":Color("a78bfa"), "desc":"经典逻辑推理，支持错误提示"},
	{"id":"snake_classic", "title":"GB Snake", "subtitle":"掌机贪食蛇", "group":"街机", "accent":Color("a8b883"), "desc":"实体方向键操控，成长到长度 120"},
	{"id":"snake_io", "title":"Snakes", "subtitle":"蛇群竞技", "group":"街机", "accent":Color("06ddea"), "desc":"自由转向、冲刺截击，争夺竞技场第一名"},
	{"id":"solitaire", "title":"Solitaire", "subtitle":"经典接龙", "group":"纸牌", "accent":Color("ffcf70"), "desc":"翻牌、移动牌列，逐步清空桌面"},
	{"id":"tripeaks", "title":"TriPeaks", "subtitle":"三峰纸牌", "group":"纸牌", "accent":Color("e89dff"), "desc":"按相邻点数消牌，清掉三座牌峰"},
	{"id":"mahjong", "title":"Vita Mahjong", "subtitle":"麻将消除", "group":"消除", "accent":Color("6de7c8"), "desc":"配对相同牌面，清空棋盘"},
	{"id":"tileclub", "title":"Tile Club", "subtitle":"三消方块", "group":"消除", "accent":Color("ff9f68"), "desc":"收集三枚同色方块，管理七格槽位"},
	{"id":"amaze_go", "title":"Amaze GO", "subtitle":"箭头迷宫", "group":"路径", "accent":Color("74a8ff"), "desc":"沿着路径走到终点，不能走回头路"},
	{"id":"arrow_go", "title":"Arrow GO", "subtitle":"方向解谜", "group":"路径", "accent":Color("b69cff"), "desc":"读懂方向提示，找到最短路线"},
	{"id":"amaze", "title":"Amaze", "subtitle":"涂色迷宫", "group":"路径", "accent":Color("4de1a4"), "desc":"走遍迷宫，把每一步都变成颜色"}
]

var logger: Node
var action_executor: Node
const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const LATIN_FONT: Font = preload("res://assets/fonts/DejaVuSans.ttf")
const SYMBOL_FONT: Font = preload("res://assets/fonts/Unifont.otf")
const DISPLAY_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const NUMBER_FONT: Font = preload("res://assets/fonts/DejaVuSans.ttf")
const TILE_NUMBER_FONT: Font = preload("res://assets/fonts/RobotoMedium-Numbers.ttf")
var fallback_font: Font
var buttons: Array[Button] = []
var screen := "home"
var game_id := ""
var state: Dictionary = {}
var rng := RandomNumberGenerator.new()
var tick := 0
var elapsed := 0.0
var web_publish_next_at := -1.0
var snapshot_save_next_at := -1.0
var snake_clock := 0.0
var selected_cell := Vector2i(-1, -1)
var pointer_down := Vector2(-1, -1)
var feedback_text := ""
var feedback_color := CYAN
var feedback_until := 0.0
var home_hover := -1
var screen_transition_started := 0.0
var has_transitioned := false
var screen_transition_direction := 1.0
var impact_until := 0.0
var impact_position := Vector2.ZERO
var impact_color := CYAN
var impact_strength := 0.0
var last_score := 0
var score_pulse_until := 0.0
var motion_kind := ""
var motion_started := -10.0
var motion_duration := 0.0
var motion_from := Vector2.ZERO
var motion_to := Vector2.ZERO
var motion_color := CYAN
var motion_label := ""
var home_entered_at := 0.0
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_cursor := 0
var snake_model = SNAKE_RULES.new()
var snake_gb_model = SNAKE_GB_RULES.new()
var snakes_arena_model = SNAKES_ARENA_RULES.new()
var merge2248_model = MERGE2248_RULES.new()
var merge2248_presenter = MERGE2248_PRESENTATION.new()
var merge2048_classic_presenter = MERGE2048_CLASSIC_PRESENTATION.new()
var catalog_art_director = CATALOG_ART_DIRECTION.new()
var watermelon_presenter = WATERMELON_PRESENTATION.new()
var logic_game_presenter = LOGIC_GAME_PRESENTATION.new()
var catalog_fx: Array[Dictionary] = []
var catalog_fx_serial := 0
var merge2248_drag_active := false
var merge2248_pointer := Vector2.ZERO
var merge2248_fx: Array[Dictionary] = []
var merge2248_chain_pulse := -10.0
var merge2248_chain_grade := 0
var merge2248_settle_started := -10.0
var merge2248_settle_grade := 1
var merge2248_juice_started := -10.0
var merge2248_juice_grade := 0
var merge2248_juice_destination := Vector2.ZERO
var merge2248_score_started := -10.0
var merge2248_score_grade := 1
var merge2048_motion: Dictionary = {}
var snake_ghosts: Array[Dictionary] = []
var snake_pixels: Array[Dictionary] = []
var snake_fx_kind := ""
var snake_fx_started := -10.0
var snake_fx_cell := Vector2i.ZERO
var snake_fx_direction := Vector2i.RIGHT
var snake_result_ready_at := -1.0
var snake_lcd_flash_until := -1.0
var snake_score_bump_until := -1.0
var snake_button_direction := Vector2i.ZERO
var snake_button_until := -1.0
var snake_reject_direction := Vector2i.ZERO
var snake_reject_until := -1.0
var snake_reset_started := -10.0
var snake_previous_cells: Array = []
var snake_move_started := -10.0
var snake_drag_origin := Vector2.ZERO
var snake_drag_anchor := Vector2.ZERO
var snake_drag_active := false
var snake_drag_samples: Array[Dictionary] = []
var snake_last_swipe_at := -10.0
var snake_float_labels: Array[Dictionary] = []
var snake_blink_started := -10.0
var snake_tutorial_dismissed := false
var snake_tutorial_fade_started := -10.0
var arena_pointer_active := false
var arena_pointer_screen := Vector2(370, 493)
var arena_aim_direction := Vector2.RIGHT
var arena_boost_active := false
var arena_boost_button_requested := false
var arena_boost_key_requests := {KEY_SPACE:false, KEY_SHIFT:false}
var arena_camera := Vector2.ZERO
var arena_camera_previous := Vector2.ZERO
var arena_camera_shake := Vector2.ZERO
var arena_fx: Array[Dictionary] = []
var arena_float_labels: Array[Dictionary] = []
var arena_rank_previous := -1
var arena_rank_bump_until := -1.0
var arena_steer_heading := 0.0
var arena_steer_turn := 0.0
var arena_steer_started := -10.0
var arena_steer_until := -10.0
var arena_competition_world := Vector2.ZERO
var arena_competition_until := -10.0
var arena_leader_previous_id := -1
var arena_leader_change_name := ""
var arena_leader_change_until := -10.0
var arena_result_ready_at := -1.0
var arena_reset_started := -10.0
var arena_last_player_position := Vector2.ZERO
var arena_tutorial_dismissed := false
var arena_death_segments: Array = []
var arena_death_started := -10.0
var arena_death_skin := 0
var arena_death_mass := 38.0
var arena_death_heading := 0.0
var arena_eat_started := -10.0
var arena_eat_world := Vector2.ZERO
var arena_eat_value := 0.0

func _ready() -> void:
	set_process(true)
	set_process_input(true)
	var cjk_font := UI_FONT as FontFile
	if cjk_font:
		cjk_font.fallbacks = [LATIN_FONT, SYMBOL_FONT]
	fallback_font = UI_FONT
	logger = get_node_or_null("/root/Logger")
	action_executor = get_node_or_null("/root/ActionExecutor")
	if logger:
		logger.set_dimension_mode("2d")
		logger.set_config({"project":"no_wifi_games", "catalog_size":catalog.size(), "offline":true})
		var grounder := get_node_or_null("/root/VisualGrounder")
		if grounder:
			logger.set_visual_grounder(grounder)
	if action_executor:
		action_executor.set_dimension_mode("2d")
		action_executor.register_entity("Game", self, {})
	_setup_audio()
	_build_home()
	_play_sfx(SFX_CASE_OPEN, -11.0)
	_setup_web_acceptance()
	_publish_web_state()
	_capture("boot")

func _process(delta: float) -> void:
	elapsed += delta
	tick += 1
	var current_score := int(state.get("score", 0))
	if screen == "game" and current_score > last_score:
		score_pulse_until = elapsed + 0.28
	last_score = current_score
	if logger:
		logger.set_tick(tick)
	if screen == "game" and game_id == "snake_classic" and state.get("status", "playing") == "playing":
		_snake_gb_update(delta)
	elif screen == "game" and game_id == "snake_io" and state.get("status", "playing") == "playing":
		_snakes_arena_update(delta)
	_snake_prune_fx()
	_snakes_arena_prune_fx()
	_prune_catalog_fx()
	_sync_observability()
	queue_redraw()

func _flash_feedback(text: String, color: Color = CYAN) -> void:
	feedback_text = text
	feedback_color = color
	feedback_until = elapsed + 0.86
	queue_redraw()

func _setup_audio() -> void:
	for index in range(5):
		var player := AudioStreamPlayer.new()
		player.name = "SfxVoice%d" % index
		player.bus = "Master"
		add_child(player)
		sfx_players.append(player)

func _play_sfx(stream: AudioStream, volume_db := -7.0, pitch := 1.0) -> void:
	if stream == null or sfx_players.is_empty():
		return
	var player: AudioStreamPlayer = sfx_players[sfx_cursor % sfx_players.size()]
	sfx_cursor += 1
	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()

func _haptic(duration_ms: int) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (navigator.vibrate) navigator.vibrate(%d);" % duration_ms)
	else:
		Input.vibrate_handheld(duration_ms)

func _haptic_pattern(pattern: Array[int]) -> void:
	if pattern.is_empty():
		return
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (navigator.vibrate) navigator.vibrate(%s);" % JSON.stringify(pattern))
	else:
		var total_ms := 0
		for interval in pattern:
			total_ms += interval
		Input.vibrate_handheld(mini(total_ms, 180))

func _impact(position: Vector2, color: Color, strength := 1.0) -> void:
	impact_position = position
	impact_color = color
	impact_strength = strength
	impact_until = elapsed + 0.34
	queue_redraw()

func _start_motion(kind: String, from: Vector2, to: Vector2, color: Color, label := "", duration := 0.34) -> void:
	motion_kind = kind
	motion_started = elapsed
	motion_duration = duration
	motion_from = from
	motion_to = to
	motion_color = color
	motion_label = label
	queue_redraw()

func _start_catalog_event(kind: String, position: Vector2, color: Color, grade := 1, label := "", duration := 0.72, metadata: Dictionary = {}) -> void:
	if game_id in ["merge2248", "snake_classic", "snake_io"]:
		return
	catalog_fx_serial += 1
	var effect := {
		"game_id": game_id,
		"kind": kind,
		"position": position,
		"color": color,
		"grade": clampi(grade, 1, 4),
		"label": label,
		"started": elapsed,
		"duration": duration,
		"seed": catalog_fx_serial,
	}
	if game_id == "meowdoku":
		effect["font_role"] = "ui_cjk"
	effect.merge(metadata, true)
	catalog_fx.append(effect)
	# The fruit burst is a large transparent texture. Six concurrent envelopes
	# preserve rapid taps and cascades while bounding overdraw on WebGL/Canvas.
	var catalog_fx_cap := 6 if game_id in ["watermelon", "merge2048"] else 12
	while catalog_fx.size() > catalog_fx_cap:
		catalog_fx.pop_front()
	var semantic := str(metadata.get("semantic", kind))
	if game_id == "meowdoku":
		_play_meowdoku_event_sfx(semantic, clampi(grade, 1, 4))
	elif game_id == "merge2048":
		var wood_grade := clampi(grade, 1, 4)
		if semantic == "wood_reject":
			_play_sfx(SFX_SNAKE_REJECT, -17.0, 0.88)
			_haptic_pattern([9, 22, 9])
		elif semantic == "wood_slide":
			_play_sfx(SFX_2048_SLIDE, -15.5, 0.96 + float(wood_grade) * 0.025)
			_haptic(6)
		else:
			_play_sfx(SFX_2048_SLIDE, -20.0, 1.02)
			_play_sfx(SFX_2048_MERGE, -13.5 + float(wood_grade) * 1.2, 0.92 + float(wood_grade) * 0.045)
			if wood_grade >= 3:
				_play_sfx(SFX_2048_MILESTONE, -19.0 + float(wood_grade) * 1.8, 0.94 + float(wood_grade) * 0.025)
			match wood_grade:
				1: _haptic(8)
				2: _haptic_pattern([12, 18, 19])
				3: _haptic_pattern([16, 15, 27])
				_: _haptic_pattern([18, 13, 24, 13, 36])
	elif "error" in kind or "reject" in kind or "mismatch" in kind:
		_play_sfx(SFX_SNAKE_REJECT, -16.0, 0.94)
		_haptic(12)
	elif game_id == "watermelon":
		var fruit_grade := clampi(grade, 1, 4)
		if kind == "fruit_drop":
			_play_sfx(SFX_FRUIT_DROP, -15.0, 0.98 + float(fruit_grade) * 0.035)
			_haptic(7)
		else:
			_play_sfx(SFX_FRUIT_MERGE, -13.0 + float(fruit_grade) * 1.2, 0.88 + float(fruit_grade) * 0.055)
			if fruit_grade >= 3:
				_play_sfx(SFX_FRUIT_CASCADE, -19.0 + float(fruit_grade) * 1.8, 0.94 + float(fruit_grade) * 0.035)
			match fruit_grade:
				1: _haptic(8)
				2: _haptic_pattern([12, 18, 20])
				3: _haptic_pattern([16, 15, 28])
				_: _haptic_pattern([18, 14, 25, 14, 38])
	else:
		var event_grade := clampi(grade, 1, 4)
		_play_sfx(SFX_SNAKE_EAT if event_grade >= 2 else SFX_SNAKE_KEY, -17.0 + float(event_grade) * 1.5, 0.92 + float(event_grade) * 0.09)
		if event_grade == 1:
			_haptic(8)
		else:
			_haptic_pattern([10 + event_grade * 4, 16, 18 + event_grade * 9])
	queue_redraw()

func _play_meowdoku_event_sfx(kind: String, grade: int) -> void:
	if "error" in kind:
		_play_sfx(SFX_LOGIC_ERROR, -14.0, 1.08)
		_haptic_pattern([9, 18, 9])
	elif "complete" in kind and grade >= 4:
		# A quiet folio tone supports the authored GAG reward without masking its
		# felt-paw transient and three warm chimes.
		_play_sfx(SFX_LOGIC_COMPLETE, -22.0, 1.08)
		_play_sfx(SFX_MEOW_GAG_COMPLETE, -10.0, 1.0)
		_haptic_pattern([18, 20, 25, 24, 36])
	elif "block" in kind:
		_play_sfx(SFX_LOGIC_BLOCK, -11.5, 1.08)
		_haptic_pattern([13, 18, 22])
	elif "erase" in kind:
		_play_sfx(SFX_LOGIC_SELECT, -18.0, 0.97)
		_haptic(5)
	else:
		_play_sfx(SFX_LOGIC_CONFIRM, -16.0, 1.08)
		_haptic(6)

func _prune_catalog_fx() -> void:
	var active: Array[Dictionary] = []
	for effect in catalog_fx:
		if elapsed - float(effect.get("started", elapsed)) < float(effect.get("duration", 0.72)):
			active.append(effect)
	catalog_fx = active

func _catalog_shake_offset() -> Vector2:
	for index in range(catalog_fx.size() - 1, -1, -1):
		var effect: Dictionary = catalog_fx[index]
		if str(effect.get("game_id", "")) == game_id:
			return catalog_art_director.shake_offset(effect, elapsed)
	return Vector2.ZERO

func _catalog_result_overlay_ready() -> bool:
	# Let the authoritative board consequence and its local event read before a
	# terminal modal covers the playfield. Rules already ended the game; this is
	# presentation-only timing and never delays state mutation.
	for index in range(catalog_fx.size() - 1, -1, -1):
		var effect: Dictionary = catalog_fx[index]
		if str(effect.get("game_id", "")) != game_id:
			continue
		var visible_window := minf(0.82, float(effect.get("duration", 0.72)))
		if elapsed - float(effect.get("started", elapsed)) < visible_window:
			return false
		break
	return true

func _begin_transition(direction := 1.0) -> void:
	screen_transition_started = elapsed
	screen_transition_direction = direction
	has_transitioned = true

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode in [KEY_SPACE, KEY_SHIFT] and screen == "game" and game_id == "snake_io":
		_set_arena_boost_key(event.keycode, event.pressed)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if screen == "game":
				_build_home()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_R and screen == "game":
			_reset_current()
			get_viewport().set_input_as_handled()
			return
		if screen != "game":
			return
		if event.keycode in [KEY_UP, KEY_W]:
			_direction_input(Vector2i.UP)
		elif event.keycode in [KEY_DOWN, KEY_S]:
			_direction_input(Vector2i.DOWN)
		elif event.keycode in [KEY_LEFT, KEY_A]:
			_direction_input(Vector2i.LEFT)
		elif event.keycode in [KEY_RIGHT, KEY_D]:
			_direction_input(Vector2i.RIGHT)
		elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
			_sudoku_place(event.keycode - KEY_0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pointer_down = event.position
			if screen == "game" and game_id == "merge2248" and _merge2248_begin_at(event.position):
				merge2248_drag_active = true
			elif screen == "game" and game_id == "snake_io":
				_snakes_arena_begin_pointer(event.position)
		else:
			var swipe_delta: Vector2 = event.position - pointer_down
			if game_id == "merge2248" and merge2248_drag_active:
				_merge2248_extend_at(event.position)
				_merge2248_release()
				merge2248_drag_active = false
			elif game_id == "snake_io":
				_snakes_arena_end_pointer(event.position)
			elif pointer_down.x >= 0.0 and swipe_delta.length() > 42.0 and game_id == "merge2048":
				if abs(swipe_delta.x) > abs(swipe_delta.y):
					_merge_move(Vector2i.RIGHT if swipe_delta.x > 0 else Vector2i.LEFT)
				else:
					_merge_move(Vector2i.DOWN if swipe_delta.y > 0 else Vector2i.UP)
			else:
				_handle_tap(event.position)
			pointer_down = Vector2(-1, -1)
	elif event is InputEventMouseMotion:
		if merge2248_drag_active and game_id == "merge2248":
			_merge2248_extend_at(event.position)
		elif arena_pointer_active and game_id == "snake_io":
			_snakes_arena_aim_at_screen(event.position)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		pointer_down = event.position
		if screen == "game" and game_id == "merge2248" and _merge2248_begin_at(event.position):
			merge2248_drag_active = true
		elif screen == "game" and game_id == "snake_io":
			_snakes_arena_begin_pointer(event.position)
	elif event is InputEventScreenTouch and not event.pressed:
		if game_id == "merge2248" and merge2248_drag_active:
			_merge2248_extend_at(event.position)
			_merge2248_release()
			merge2248_drag_active = false
		elif game_id == "snake_io":
			_snakes_arena_end_pointer(event.position)
		else:
			_handle_tap(event.position)
	elif event is InputEventScreenDrag:
		if game_id == "merge2248" and merge2248_drag_active:
			_merge2248_extend_at(event.position)
		elif game_id == "snake_io":
			_snakes_arena_aim_at_screen(event.position)

func _build_home() -> void:
	if game_id == "snake_io":
		_clear_arena_boost_requests()
	screen = "home"
	game_id = ""
	state = {}
	last_score = 0
	home_entered_at = elapsed
	home_hover = -1
	_begin_transition(-1.0)
	_clear_buttons()
	for index in range(catalog.size()):
		var item: Dictionary = catalog[index]
		var row := index / 2
		var col := index % 2
		var rect := Rect2(HOME_CARD_ORIGIN + Vector2(float(col) * HOME_CARD_GAP.x, float(row) * HOME_CARD_GAP.y), HOME_CARD_SIZE)
		_add_home_cartridge(index, item, rect)
	if elapsed > 0.1:
		_play_sfx(SFX_CASE_OPEN, -11.0)
	queue_redraw()

func _open_game(id: String) -> void:
	game_id = id
	screen = "game"
	catalog_fx.clear()
	rng.seed = abs(id.hash()) + 17
	_start_game_state()
	last_score = int(state.get("score", 0))
	_begin_transition(1.0)
	_build_game_buttons()
	_log_event("game_opened", {"game_id":game_id})
	_capture("entry_%s" % game_id)
	_flash_feedback("已进入 · %s" % _catalog_item(game_id).title, _catalog_item(game_id).accent)
	queue_redraw()

func _build_game_buttons() -> void:
	_clear_buttons()
	if game_id == "snake_classic":
		_add_hardware_button("收盒", Rect2(10, 17, 92, 52), Callable(self, "_build_home"))
		_add_hardware_button("重开", Rect2(438, 17, 92, 52), Callable(self, "_reset_current"))
	elif game_id == "snake_io":
		_add_arena_nav_button("收盒", Rect2(12, 18, 88, 54), Callable(self, "_build_home"))
		_add_arena_nav_button("再来", Rect2(440, 18, 88, 54), Callable(self, "_reset_current"))
	else:
		_add_button("首页", Rect2(16, 24, 76, 48), Callable(self, "_build_home"), SURFACE_2, 15)
		_add_button("重开", Rect2(448, 24, 76, 48), Callable(self, "_reset_current"), SURFACE_2, 15)
	match game_id:
		"merge2048":
			_add_button("左", Rect2(170, 826, 58, 52), Callable(self, "_merge_move").bind(Vector2i.LEFT), SURFACE_2, 16)
			_add_button("下", Rect2(241, 878, 58, 52), Callable(self, "_merge_move").bind(Vector2i.DOWN), SURFACE_2, 16)
			_add_button("上", Rect2(241, 826, 58, 52), Callable(self, "_merge_move").bind(Vector2i.UP), SURFACE_2, 16)
			_add_button("右", Rect2(312, 826, 58, 52), Callable(self, "_merge_move").bind(Vector2i.RIGHT), SURFACE_2, 16)
		"watermelon":
			_add_button("轻触果箱选择落点", Rect2(158, 820, 224, 52), Callable(self, "_water_drop_hint"), SURFACE_2, 14)
		"sudoku", "meowdoku":
			for n in range(1, 10):
				var row := (n - 1) / 5
				var col := (n - 1) % 5
				_add_button(str(n), Rect2(72 + col * 80, 736 + row * 58, 62, 50), Callable(self, "_sudoku_place").bind(n), SURFACE_2, 17)
			_add_button("擦除", Rect2(392, 794, 76, 50), Callable(self, "_sudoku_place").bind(0), SURFACE_2, 14)
		"snake_classic":
			_add_hardware_button("", Rect2(132, 554, 54, 54), Callable(self, "_set_snake_direction").bind(Vector2i.UP), Vector2i.UP)
			_add_hardware_button("", Rect2(78, 608, 54, 54), Callable(self, "_set_snake_direction").bind(Vector2i.LEFT), Vector2i.LEFT)
			_add_hardware_button("", Rect2(186, 608, 54, 54), Callable(self, "_set_snake_direction").bind(Vector2i.RIGHT), Vector2i.RIGHT)
			_add_hardware_button("", Rect2(132, 662, 54, 54), Callable(self, "_set_snake_direction").bind(Vector2i.DOWN), Vector2i.DOWN)
		"snake_io":
			_add_arena_boost_button()
		"solitaire":
			_add_button("摸牌", Rect2(38, 816, 102, 52), Callable(self, "_solitaire_draw"), SURFACE_2, 15)
			_add_button("自动整理", Rect2(152, 816, 112, 52), Callable(self, "_solitaire_auto"), SURFACE_2, 15)
		"tripeaks":
			_add_button("翻开牌堆", Rect2(202, 816, 136, 52), Callable(self, "_tripeaks_next"), SURFACE_2, 15)
		"tileclub":
			_add_button("槽位规则", Rect2(202, 816, 136, 52), Callable(self, "_tileclub_tray_hint"), SURFACE_2, 15)
		"amaze_go", "arrow_go", "amaze":
			_add_button("路线提示", Rect2(202, 816, 136, 52), Callable(self, "_amaze_hint"), SURFACE_2, 15)

func _reset_current() -> void:
	if game_id.is_empty():
		return
	catalog_fx.clear()
	rng.seed = abs(game_id.hash()) + 17
	_start_game_state()
	_log_event("game_reset", {"game_id":game_id})
	_capture("reset_%s" % game_id)
	if game_id == "snake_classic":
		snake_reset_started = elapsed
		_play_sfx(SFX_SNAKE_KEY, -8.0)
	elif game_id == "snake_io":
		arena_reset_started = elapsed
		_play_sfx(SFX_CASE_OPEN, -12.0, 1.14)
	else:
		_flash_feedback("新局开始", GREEN)
	queue_redraw()

func _add_home_cartridge(index: int, item: Dictionary, rect: Rect2) -> Button:
	var button := Button.new()
	button.name = "Cartridge_%02d_%s" % [index, str(item.id)]
	button.text = ""
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = "%s · %s" % [str(item.title), str(item.subtitle)]
	button.set_meta("game_id", str(item.id))
	button.set_meta("home_index", index)
	var clear := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", clear)
	button.add_theme_stylebox_override("hover", clear)
	button.add_theme_stylebox_override("pressed", clear)
	button.add_theme_stylebox_override("focus", clear)
	button.mouse_entered.connect(func() -> void: home_hover = index; queue_redraw())
	button.mouse_exited.connect(func() -> void: home_hover = -1; queue_redraw())
	button.focus_entered.connect(func() -> void: home_hover = index; queue_redraw())
	button.focus_exited.connect(func() -> void:
		if home_hover == index: home_hover = -1
		queue_redraw()
	)
	button.pressed.connect(Callable(self, "_open_game").bind(str(item.id)))
	add_child(button)
	buttons.append(button)
	return button

func _add_hardware_button(label: String, rect: Rect2, callback: Callable, direction := Vector2i.ZERO) -> Button:
	var button := Button.new()
	button.text = label
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if not label.is_empty():
		button.tooltip_text = label
	else:
		button.tooltip_text = {Vector2i.UP:"向上", Vector2i.DOWN:"向下", Vector2i.LEFT:"向左", Vector2i.RIGHT:"向右"}.get(direction, "方向键")
	button.set_meta("snake_direction", direction)
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color("33291c") if not label.is_empty() else Color("e7d5a8"))
	button.add_theme_color_override("font_hover_color", Color("17120c") if not label.is_empty() else Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("17120c") if not label.is_empty() else Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0.0)
	normal.border_color = Color(0, 0, 0, 0.0)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(10)
	var hover := normal.duplicate()
	hover.bg_color = Color("c1a260", 0.12 if label.is_empty() else 0.10)
	hover.border_color = Color("e7d5a8", 0.42 if label.is_empty() else 0.22)
	var pressed := normal.duplicate()
	pressed.bg_color = Color("e7d5a8", 0.18 if label.is_empty() else 0.16)
	pressed.border_color = Color("fff3cc", 0.82 if label.is_empty() else 0.36)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.pressed.connect(callback)
	add_child(button)
	buttons.append(button)
	return button

func _add_arena_boost_button() -> Button:
	var button := Button.new()
	button.name = "ArenaBoost"
	button.text = ""
	button.position = Vector2(426, 828)
	button.size = Vector2(92, 92)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = "按住冲刺"
	button.set_meta("arena_boost", true)
	var normal := StyleBoxEmpty.new()
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("45ead1", 0.08)
	hover.border_color = Color("d9fff7", 0.38)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(46)
	var pressed := hover.duplicate()
	pressed.bg_color = Color("45ead1", 0.18)
	pressed.border_color = Color("fff2b8", 0.82)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.button_down.connect(Callable(self, "_set_arena_boost").bind(true))
	button.button_up.connect(Callable(self, "_set_arena_boost").bind(false))
	button.focus_exited.connect(Callable(self, "_set_arena_boost").bind(false))
	add_child(button)
	buttons.append(button)
	return button

func _add_arena_nav_button(label: String, rect: Rect2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = label
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("02101b"))
	button.add_theme_color_override("font_hover_color", Color("02101b"))
	button.add_theme_color_override("font_pressed_color", Color("02101b"))
	var normal := StyleBoxEmpty.new()
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("ffffff", 0.14)
	hover.border_color = Color("ffffff", 0.48)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(18)
	var pressed := hover.duplicate()
	pressed.bg_color = Color("02101b", 0.12)
	pressed.border_color = Color("02101b", 0.36)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.pressed.connect(callback)
	add_child(button)
	buttons.append(button)
	return button

func _clear_buttons() -> void:
	for button in buttons:
		if is_instance_valid(button):
			button.queue_free()
	buttons.clear()

func _add_button(label: String, rect: Rect2, callback: Callable, accent: Color = SURFACE_2, font_size: int = 15) -> Button:
	# The bundled CJK subset intentionally stays small; normalize a few decorative
	# Unicode arrows that are not present in the web font into CJK labels.
	label = label.replace("‹  ", "").replace("↻  ", "")
	label = label.replace("←", "左").replace("→", "右").replace("↑", "上").replace("↓", "下")
	var button := Button.new()
	button.text = label
	button.position = rect.position
	button.size = rect.size
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT if screen == "home" else HORIZONTAL_ALIGNMENT_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_font_override("font", DISPLAY_FONT if screen == "home" else UI_FONT)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	var action_control := screen == "game" and rect.position.y > 150.0
	var meow_control := action_control and game_id == "meowdoku"
	var effective_accent: Color = Color(_catalog_item(game_id).get("accent", accent)) if action_control else accent
	var normal_fill := _game_control_fill() if action_control else Color("111a2e")
	var normal := _button_style(normal_fill, Color(effective_accent, 0.28 if action_control else 0.10), 12, 1)
	var hover := _button_style(Color(effective_accent, 0.22), Color(effective_accent, 0.94), 12, 2)
	var pressed := _button_style(Color(effective_accent, 0.38), Color.WHITE, 10, 2)
	var focus := _button_style(Color(effective_accent, 0.18), Color.WHITE, 12, 2)
	if meow_control:
		var control_ink := Color("5b2d46")
		normal = _button_style(Color("f7e2ed"), Color(effective_accent, 0.52), 14, 1)
		hover = _button_style(Color("fff5fa"), Color(effective_accent, 0.92), 14, 2)
		pressed = _button_style(Color("e9bfd3"), Color(effective_accent.darkened(0.24), 0.92), 12, 2)
		focus = _button_style(Color("fff5fa"), Color("f6c667"), 14, 2)
		button.add_theme_font_override("font", NUMBER_FONT if label.is_valid_int() else UI_FONT)
		button.add_theme_color_override("font_color", control_ink)
		button.add_theme_color_override("font_hover_color", control_ink)
		button.add_theme_color_override("font_pressed_color", control_ink)
		button.add_theme_color_override("font_focus_color", control_ink)
	if screen == "home":
		normal.bg_color = Color(0, 0, 0, 0)
		normal.border_color = Color(0, 0, 0, 0)
		hover.bg_color = Color(accent, 0.14)
		hover.border_color = Color(accent, 0.8)
		pressed.bg_color = Color(accent, 0.24)
		normal.content_margin_left = 76
		hover.content_margin_left = 76
		pressed.content_margin_left = 76
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(callback)
	add_child(button)
	buttons.append(button)
	return button

func _game_control_fill() -> Color:
	match game_id:
		"merge2248": return Color("23585a")
		"merge2048": return Color("3a2d25")
		"watermelon": return Color("3b2237")
		"meowdoku": return Color("f7e2ed")
		"sudoku": return Color("27223a")
		"snake_classic": return Color("343b2d")
		"snake_io": return Color("0a2845")
		"solitaire", "tripeaks": return Color("12342e") if game_id == "solitaire" else Color("281b40")
		"mahjong": return Color("1d4a42")
		"tileclub": return Color("392849")
		"amaze_go": return Color("102e4c")
		"arrow_go": return Color("2b2148")
		"amaze": return Color("153f35")
	return Color("111a2e")

func _button_style(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _handle_tap(pos: Vector2) -> void:
	if screen != "game" or state.get("status", "playing") == "won":
		return
	match game_id:
		"watermelon":
			if Rect2(30, 236, 462, 466).has_point(pos):
				var column := clampi(int((pos.x - 43.0) / 62.0), 0, 6)
				_water_drop(column)
		"sudoku", "meowdoku": _sudoku_tap(pos)
		"mahjong": _mahjong_tap(pos)
		"tileclub": _tileclub_tap(pos)
		"amaze_go", "arrow_go", "amaze": _amaze_tap(pos)
		"tripeaks": _tripeaks_tap(pos)
		"solitaire": _solitaire_tap(pos)

func _direction_input(direction: Vector2i) -> void:
	if game_id == "merge2048":
		_merge_move(direction)
	elif game_id == "snake_classic" or game_id == "snake_io":
		_set_snake_direction(direction)
	elif game_id == "amaze_go" or game_id == "arrow_go" or game_id == "amaze":
		_amaze_step(direction)

func _log_event(event_name: String, data: Dictionary = {}) -> void:
	if logger:
		logger.log_event(event_name, data)
	_sync_observability()

func _sync_observability(force := false) -> void:
	if force or elapsed >= web_publish_next_at:
		_publish_web_state()
		web_publish_next_at = elapsed + 0.10
	if screen != "game":
		return
	var should_save := elapsed >= snapshot_save_next_at
	if logger == null and action_executor == null and not should_save:
		return
	var snapshot := state.duplicate(true)
	snapshot["game_id"] = game_id
	snapshot["screen"] = screen
	snapshot["tick"] = tick
	if logger:
		logger.update_entity("Game", snapshot)
	if action_executor:
		action_executor.update_entity_state("Game", snapshot)
	if should_save:
		_save_snapshot(snapshot)
		snapshot_save_next_at = elapsed + 2.0

func _save_snapshot(snapshot: Dictionary) -> void:
	var file := FileAccess.open("user://offline_games_state.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(snapshot))

func _capture(reason: String) -> void:
	if logger:
		logger.capture(reason, {"game_id":game_id, "state":state.duplicate(true)})

func _setup_web_acceptance() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
		window.__gameAcceptanceState = {ready:true, screen:'home', game_id:'', catalog_size:14, state:{}};
		window.__gameAcceptance = {
			getState: function(){ return window.__gameAcceptanceState; },
			getConfig: function(){ return {name:'No WiFi Games', offline:true, catalog_size:14, version:'0.1.0'}; }
		};
	""")

func _publish_web_state() -> void:
	if not OS.has_feature("web"):
		return
	var exposed := {"ready":true, "screen":screen, "game_id":game_id, "catalog_size":catalog.size(), "state":state.duplicate(true)}
	JavaScriptBridge.eval("window.__gameAcceptanceState = %s;" % JSON.stringify(exposed))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COAL)
	# Snakes paints an opaque full-screen arena. Avoid drawing the collection's
	# 210-call ambient scanline field underneath pixels that can never be seen.
	if screen != "game" or game_id != "snake_io":
		_draw_ambient_backdrop()
	if screen == "home":
		_draw_home()
	else:
		_draw_game()
	_draw_transition_wipe()

func _draw_ambient_backdrop() -> void:
	var accent := CYAN if screen == "home" else Color(_catalog_item(game_id).get("accent", CYAN))
	draw_circle(Vector2(500, 28), 156, Color(accent, 0.075))
	draw_circle(Vector2(34, 904), 184, Color(accent, 0.045))
	for i in range(18):
		var px := fposmod(float(i * 83) + elapsed * (3.0 + float(i % 3)), 600.0) - 30.0
		var py := fposmod(float(i * 137), 940.0) + 10.0
		draw_circle(Vector2(px, py), 0.8 + float(i % 3) * 0.35, Color(INK, 0.055))
	for y in range(0, 960, 5):
		draw_line(Vector2(0, y), Vector2(540, y), Color(INK, 0.009), 1.0)

func _draw_transition_wipe() -> void:
	if not has_transitioned:
		return
	var progress := clampf((elapsed - screen_transition_started) / 0.24, 0.0, 1.0)
	if progress >= 1.0:
		return
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	var width := (1.0 - eased) * 540.0
	var x := 0.0 if screen_transition_direction > 0.0 else 540.0 - width
	draw_rect(Rect2(x, 0, width, 960), Color("090806", 0.92))
	var edge_x := width if screen_transition_direction > 0.0 else x
	draw_line(Vector2(edge_x, 0), Vector2(edge_x, 960), Color("d3b269", 0.52 * (1.0 - progress)), 3.0)

func _draw_home() -> void:
	draw_texture_rect(HOME_CASE_TEXTURE, Rect2(Vector2.ZERO, VIEW_SIZE), false)
	# The title and cartridges are printed onto physical labels; the generated
	# case supplies the material, wear, stitching and lighting.
	var breathe := 0.96 + sin(elapsed * 1.15) * 0.025
	draw_texture_rect(HOME_CARTRIDGE_TEXTURE, Rect2(58, 126, 424, 78), false, Color(breathe, breathe, breathe, 1.0))
	_draw_center("离线游戏收藏箱", Vector2(270, 164), 19, Color("172235"))
	_draw_center("十四枚游戏卡匣 · 不联网 · 不打扰", Vector2(270, 236), 13, Color("e9d7af", 0.90))
	_draw_center_font(LATIN_FONT, "CHOOSE A CARTRIDGE", Vector2(270, 364), 11, Color("cfb477", 0.86))
	for index in range(catalog.size()):
		_draw_home_card(index, catalog[index])
	_draw_center("所有进度仅留在这台设备", Vector2(270, 918), 11, Color("d7c8a7", 0.72))

func _draw_home_card(index: int, item: Dictionary) -> void:
	var row := index / 2
	var col := index % 2
	var rect := Rect2(HOME_CARD_ORIGIN + Vector2(float(col) * HOME_CARD_GAP.x, float(row) * HOME_CARD_GAP.y), HOME_CARD_SIZE)
	var accent: Color = item.accent
	var reveal := clampf((elapsed - home_entered_at - float(row) * 0.035) / 0.26, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - reveal, 3.0)
	var hovered := index == home_hover
	var lift := -3.0 if hovered else 0.0
	var visual_rect := Rect2(rect.position + Vector2((1.0 - eased) * (-12.0 if col == 0 else 12.0), (1.0 - eased) * 10.0 + lift), rect.size)
	if hovered:
		draw_texture_rect(HOME_COVER_CARTRIDGE_TEXTURE, visual_rect.grow(3.0), false, Color(1.0, 0.94, 0.74, 0.28))
	var cover: Texture2D = HOME_COVER_TEXTURES.get(str(item.id)) as Texture2D
	var cover_rect := Rect2(visual_rect.position + Vector2(13.25, 7.5), Vector2(46.0, 46.0))
	if hovered:
		cover_rect = cover_rect.grow(1.0)
	if cover:
		var cover_energy := 1.08 if hovered else 0.96
		draw_texture_rect(cover, cover_rect, false, Color(cover_energy, cover_energy, cover_energy, eased))
	draw_texture_rect(HOME_COVER_CARTRIDGE_TEXTURE, visual_rect, false, Color(1, 1, 1, eased))
	var ink := Color("1b2430", eased)
	var accent_ink := accent.darkened(0.52)
	accent_ink.a = eased
	_draw_text_font(DISPLAY_FONT, str(item.title), visual_rect.position + Vector2(72, 32), 14 if str(item.title).length() < 10 else 12, ink)
	var group_text := str(item.group)
	var group_width := UI_FONT.get_string_size(group_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	_draw_text(group_text, visual_rect.position + Vector2(216 - group_width, 33), 10, accent_ink)

func _draw_game_icon(id: String, center: Vector2, accent: Color, scale := 1.0) -> void:
	var r := 18.0 * scale
	match id:
		"merge2248", "merge2048":
			_draw_panel(Rect2(center - Vector2(r, r), Vector2(r * 2, r * 2)), Color(accent, 0.22), accent, int(7 * scale), 2)
			_draw_center("2", center + Vector2(-6, 3) * scale, int(13 * scale), INK)
			_draw_center("+", center + Vector2(5, 4) * scale, int(10 * scale), accent)
		"watermelon":
			draw_circle(center + Vector2(-7, 3) * scale, 10 * scale, Color("ec6d8e"))
			draw_circle(center + Vector2(7, -4) * scale, 8 * scale, Color("62d3aa"))
			draw_arc(center + Vector2(4, -12) * scale, 8 * scale, 3.2, 5.2, 12, accent, 2 * scale)
		"meowdoku":
			logic_game_presenter.draw_header_badge(self, id, center, r * 2.15)
		"sudoku":
			for i in range(3):
				draw_line(center + Vector2(-11 + i * 11, -11) * scale, center + Vector2(-11 + i * 11, 11) * scale, accent, 1.5 * scale)
				draw_line(center + Vector2(-11, -11 + i * 11) * scale, center + Vector2(11, -11 + i * 11) * scale, accent, 1.5 * scale)
		"snake_classic", "snake_io":
			draw_circle(center + Vector2(-9, 2) * scale, 5 * scale, Color(accent, 0.55))
			draw_circle(center + Vector2(0, 2) * scale, 6 * scale, Color(accent, 0.78))
			draw_circle(center + Vector2(10, 2) * scale, 7 * scale, accent)
			draw_circle(center + Vector2(12, 0) * scale, 1.5 * scale, BG)
		"solitaire", "tripeaks":
			_draw_playing_card(Rect2(center - Vector2(12, 17) * scale, Vector2(24, 34) * scale), 7, accent)
			draw_line(center + Vector2(-14, 16) * scale, center + Vector2(14, 16) * scale, Color(accent, 0.7), 2 * scale)
		"mahjong":
			_draw_panel(Rect2(center - Vector2(12, 16) * scale, Vector2(24, 32) * scale), PAPER, accent, int(4 * scale), 2)
			_draw_center("中", center + Vector2(0, 5) * scale, int(14 * scale), RED)
		"tileclub":
			for i in range(3):
				_draw_panel(Rect2(center + Vector2(-13 + i * 10, -10 + (i % 2) * 7) * scale, Vector2(14, 14) * scale), accent.lightened(0.1 * i), Color(accent, 0.7), int(3 * scale), 1)
		"amaze_go", "arrow_go", "amaze":
			draw_line(center + Vector2(-13, 10) * scale, center + Vector2(-2, -1) * scale, accent, 3 * scale)
			draw_line(center + Vector2(-2, -1) * scale, center + Vector2(12, -10) * scale, accent, 3 * scale)
			draw_circle(center + Vector2(12, -10) * scale, 4 * scale, GOLD)

func _draw_panel(rect: Rect2, fill: Color, border: Color = Color.TRANSPARENT, radius := 12, width := 0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.set_border_width_all(width)
	draw_style_box(style, rect)

func _draw_game() -> void:
	if game_id == "snake_classic":
		_draw_snake_gb_experience()
		return
	if game_id == "snake_io":
		_draw_snakes_arena_experience()
		return
	var item := _catalog_item(game_id)
	var accent: Color = item.get("accent", CYAN)
	_draw_game_world(accent)
	var header_fill := _game_header_fill()
	var header_line := Color("f1bd68") if game_id == "merge2248" else accent
	draw_rect(Rect2(0, 0, size.x, 112), header_fill)
	draw_rect(Rect2(0, 108, size.x, 4), header_line)
	_draw_game_icon(game_id, Vector2(116, 54), accent, 0.9)
	_draw_text(str(item.get("group", "游戏")), Vector2(144, 29), 10, accent)
	_draw_text_font(DISPLAY_FONT, str(item.get("title", game_id)), Vector2(142, 63), 28, INK)
	_draw_text(str(item.get("subtitle", "")), Vector2(144, 88), 12, BRIGHT_MUTED)
	_draw_status_badge("离线", Vector2(382, 34), GREEN, true, 58)
	_draw_score_panel()
	var play_shake := _catalog_shake_offset()
	draw_set_transform(play_shake, 0.0, Vector2.ONE)
	match game_id:
		"merge2248": _draw_merge2248()
		"merge2048": _draw_merge()
		"watermelon": _draw_watermelon()
		"sudoku", "meowdoku": _draw_sudoku()
		"snake_io": pass
		"solitaire": _draw_solitaire()
		"tripeaks": _draw_tripeaks()
		"mahjong": _draw_mahjong()
		"tileclub": _draw_tileclub()
		"amaze_go", "arrow_go", "amaze": _draw_amaze()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state.get("status", "playing") == "over" and _catalog_result_overlay_ready():
		_draw_result_overlay(false)
	elif state.get("status", "playing") == "won" and _catalog_result_overlay_ready():
		_draw_result_overlay(true)
	if elapsed < feedback_until:
		var remaining := feedback_until - elapsed
		var alpha: float = clampf(remaining / 0.24, 0.0, 1.0)
		var toast_x := 276.0 + (1.0 - alpha) * 18.0
		_draw_panel(Rect2(toast_x, 129, 246, 42), Color(_game_panel_fill(), 0.98 * alpha), Color(feedback_color, 0.76 * alpha), 10, 2)
		draw_rect(Rect2(toast_x, 129, 5, 42), Color(feedback_color, alpha))
		_draw_center(feedback_text, Vector2(toast_x + 123, 150), 13, Color(INK, alpha))
	_draw_motion_overlay()
	_draw_impact_fx()
	_draw_catalog_fx()

func _game_header_fill() -> Color:
	match game_id:
		"merge2248": return Color("173f42", 0.985)
		"merge2048": return Color("322015", 0.985)
		"watermelon": return Color("4b2830", 0.985)
		"meowdoku": return Color("4a263d", 0.985)
		"sudoku": return Color("302b32", 0.985)
		"solitaire": return Color("0d3529", 0.985)
		"tripeaks": return Color("271940", 0.985)
		"mahjong": return Color("174139", 0.985)
		"tileclub": return Color("4a2036", 0.985)
		"amaze_go": return Color("102d4d", 0.985)
		"arrow_go": return Color("2b2048", 0.985)
		"amaze": return Color("173f34", 0.985)
	return Color("10192d", 0.985)

func _game_panel_fill() -> Color:
	match game_id:
		"merge2248": return Color("17484a", 0.96)
		"merge2048": return Color("49301e", 0.96)
		"watermelon": return Color("63323c", 0.96)
		"meowdoku": return Color("6b3854", 0.96)
		"sudoku": return Color("494047", 0.96)
		"solitaire": return Color("154939", 0.96)
		"tripeaks": return Color("3a2857", 0.96)
		"mahjong": return Color("23584a", 0.96)
		"tileclub": return Color("663047", 0.96)
		"amaze_go": return Color("16456b", 0.96)
		"arrow_go": return Color("443467", 0.96)
		"amaze": return Color("245b49", 0.96)
	return Color("101a2e", 0.94)

func _game_secondary_text() -> Color:
	match game_id:
		"merge2048", "watermelon", "solitaire", "mahjong", "tileclub", "amaze_go", "amaze":
			return Color("f4ead4", 0.84)
		"meowdoku", "tripeaks", "arrow_go":
			return Color("f2e3f5", 0.84)
	return Color("d7e5d8", 0.88) if game_id == "merge2248" else BRIGHT_MUTED

func _draw_catalog_fx() -> void:
	for effect in catalog_fx:
		if str(effect.get("game_id", "")) == game_id:
			catalog_art_director.draw_event_fx(self, effect, elapsed, DISPLAY_FONT, SYMBOL_FONT)

func _draw_score_panel() -> void:
	var candy_mode := game_id == "merge2248"
	var panel_fill := _game_panel_fill()
	var panel_border := Color("f3d59d", 0.30) if candy_mode else Color(INK, 0.09)
	var secondary_text := _game_secondary_text()
	_draw_panel(Rect2(18, 124, 504, 52), panel_fill, panel_border, 10, 1)
	var compact := state.has("mistakes")
	_draw_text("得分", Vector2(31, 142), 10, secondary_text)
	var score_scale := 1.0 + (0.16 * clampf((score_pulse_until - elapsed) / 0.28, 0.0, 1.0))
	var score_color := INK
	if candy_mode:
		var score_age := elapsed - merge2248_score_started
		var score_duration := 0.30 + float(merge2248_score_grade) * 0.07
		if score_age >= 0.0 and score_age < score_duration:
			var score_t := clampf(score_age / score_duration, 0.0, 1.0)
			var score_kick := sin(score_t * PI) * (0.04 + float(merge2248_score_grade) * 0.025)
			score_scale += score_kick
			score_color = _merge2248_grade_color(merge2248_score_grade).lerp(INK, score_t)
	_draw_center_font(NUMBER_FONT, str(int(state.get("score", 0))), Vector2(72, 159), int(21 * score_scale), score_color)
	draw_line(Vector2(112, 134), Vector2(112, 166), Color(INK, 0.10), 1.0)
	_draw_text("步数", Vector2(127, 142), 10, secondary_text)
	_draw_center_font(NUMBER_FONT, str(int(state.get("moves", 0))), Vector2(164, 159), 21, INK)
	var status_x := 219.0 if compact else 238.0
	draw_line(Vector2(status_x - 15, 134), Vector2(status_x - 15, 166), Color(INK, 0.10), 1.0)
	_draw_text("局势", Vector2(status_x, 142), 10, secondary_text)
	_draw_text(_status_label(), Vector2(status_x, 162), 12, _status_color())
	if state.has("mistakes"):
		_draw_status_badge("错误 %d" % int(state.mistakes), Vector2(410, 135), RED if int(state.mistakes) > 0 else GREEN, int(state.mistakes) == 0, 98)
	elif elapsed >= feedback_until:
		_draw_text(_objective_status(), Vector2(302, 156), 11, Color(secondary_text, 0.82))

func _objective_status() -> String:
	match game_id:
		"merge2248": return "最高 %s / 2048" % _merge2248_highest_label()
		"merge2048": return "目标 2048"
		"watermelon": return "下个 %s" % _fruit_name(int(state.get("next", 1)))
		"snake_classic": return "长度 %d / %d" % [int(state.get("score", 4)), int(state.get("target_length", 120))]
		"snake_io": return "位次 #%d · 体量 %.1f" % [max(1, int(state.get("rank", 1))), float(state.get("mass", 0.0))]
		"solitaire": return "牌库 %d" % int(state.get("stock", 0))
		"tripeaks": return "余牌 %d" % int(state.get("stock", 0))
		"mahjong": return "待配 %d" % (20 - int(state.get("removed", []).size()))
		"tileclub": return "槽位 %d / 7" % int(state.get("tray", []).size())
		"amaze_go", "arrow_go", "amaze": return "已探索 %d 格" % _painted_count()
	return ""

func _play_rect() -> Rect2:
	return Rect2(26, 190, 488, 600)

func _draw_section_heading(title: String, detail: String, accent: Color) -> void:
	_draw_text_font(DISPLAY_FONT, title, Vector2(30, 207), 18, INK)
	_draw_text(detail, Vector2(508 - fallback_font.get_string_size(detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x, 205), 11, Color(BRIGHT_MUTED, 0.78))
	draw_line(Vector2(30, 216), Vector2(510, 216), Color(accent, 0.34), 2.0)

func _draw_result_overlay(won: bool) -> void:
	if game_id == "meowdoku":
		var paper := Color("fff1f7")
		var edge := Color("d55f96")
		var ink := Color("4b2940")
		draw_rect(Rect2(0, 112, 540, 848), Color("231c28", 0.56))
		_draw_panel(Rect2(54, 344, 432, 236), Color("17131a", 0.26), Color.TRANSPARENT, 18, 0)
		_draw_panel(Rect2(48, 338, 444, 238), paper, Color(edge, 0.92), 18, 3)
		draw_line(Vector2(74, 356), Vector2(466, 356), Color("ffffff", 0.72), 2.0, true)
		logic_game_presenter.draw_result_badge(self, game_id, Vector2(270, 384))
		_draw_center_font(DISPLAY_FONT, "手账完成", Vector2(270, 438), 30, ink)
		_draw_center_font(UI_FONT, "得分 %d · 步数 %d" % [int(state.get("score", 0)), int(state.get("moves", 0))], Vector2(270, 480), 16, Color(ink, 0.88))
		_draw_center_font(UI_FONT, "点击右上角“重开”继续挑战", Vector2(270, 526), 13, Color(ink, 0.68))
		return
	draw_rect(Rect2(0, 112, 540, 848), Color(COAL, 0.72))
	var color := GREEN if won else RED
	_draw_panel(Rect2(48, 338, 444, 238), Color("111a2e", 0.985), Color(color, 0.82), 18, 2)
	draw_circle(Vector2(270, 382), 27, Color(color, 0.18))
	draw_arc(Vector2(270, 382), 24, 0, TAU, 40, color, 3.0)
	_draw_center("胜利" if won else "本局结束", Vector2(270, 438), 32, color)
	_draw_center("得分 %d · 步数 %d" % [int(state.get("score", 0)), int(state.get("moves", 0))], Vector2(270, 478), 16, INK)
	_draw_center("点击右上角“重开”继续挑战", Vector2(270, 524), 13, BRIGHT_MUTED)

func _draw_game_world(_accent: Color) -> void:
	if game_id == "merge2248":
		draw_texture_rect(MERGE2248_BG_TEXTURE, Rect2(Vector2.ZERO, VIEW_SIZE), false, Color.WHITE)
		# Quiet the generated workshop beneath live UI while retaining the
		# authored edge props and warm material context.
		draw_rect(Rect2(0, 112, 540, 848), Color("0f4d50", 0.10))
		return
	catalog_art_director.draw_environment(self, game_id, VIEW_SIZE, elapsed)

func draw_triangle(a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([a, b, c]), color)

func _draw_impact_fx() -> void:
	if elapsed >= impact_until:
		return
	var t := 1.0 - clampf((impact_until - elapsed) / 0.34, 0.0, 1.0)
	for i in range(10):
		var angle := TAU * float(i) / 10.0
		var distance := lerpf(4.0, 46.0 * impact_strength, t)
		var p := impact_position + Vector2(cos(angle), sin(angle)) * distance
		draw_circle(p, lerpf(4.0, 0.6, t), Color(impact_color, (1.0 - t) * 0.86))
	draw_arc(impact_position, lerpf(8.0, 54.0 * impact_strength, t), 0, TAU, 36, Color(impact_color, (1.0 - t) * 0.62), 3.0)

func _draw_motion_overlay() -> void:
	if motion_duration <= 0.0:
		return
	var progress := clampf((elapsed - motion_started) / motion_duration, 0.0, 1.0)
	if progress >= 1.0:
		return
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	var arc_height := -56.0 * sin(progress * PI)
	var position := motion_from.lerp(motion_to, eased) + Vector2(0, arc_height)
	var alpha := sin(progress * PI)
	match motion_kind:
		"tile":
			_draw_panel(Rect2(position - Vector2(25, 25), Vector2(50, 50)), Color(motion_color, 0.96), Color(INK, 0.78), 12, 2)
			_draw_center(motion_label, position + Vector2(0, 2), 20, COAL)
		"card":
			var flip_scale := maxf(0.12, abs(cos(progress * PI)))
			var rect := Rect2(position - Vector2(29 * flip_scale, 40), Vector2(58 * flip_scale, 80))
			if progress < 0.5:
				_draw_card_back(rect, motion_color)
			else:
				_draw_playing_card(rect, int(motion_label), motion_color)
		"path":
			draw_line(motion_from, position, Color(motion_color, 0.46 * alpha), 8.0)
			draw_circle(position, 11.0 + sin(progress * PI) * 4.0, Color(motion_color, 0.92))

func _status_label() -> String:
	match str(state.get("status", "playing")):
		"won": return "已完成"
		"over": return "已结束"
		_: return "进行中"

func _status_color() -> Color:
	match str(state.get("status", "playing")):
		"won": return GREEN
		"over": return RED
		_: return CYAN

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color = INK) -> void:
	if fallback_font:
		draw_string(fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw_text_font(font: Font, text: String, pos: Vector2, font_size: int, color: Color = INK) -> void:
	if font:
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw_center(text: String, center: Vector2, font_size: int, color: Color = INK) -> void:
	if not fallback_font:
		return
	var width := fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_draw_text(text, Vector2(center.x - width * 0.5, center.y + font_size * 0.35), font_size, color)

func _draw_center_font(font: Font, text: String, center: Vector2, font_size: int, color: Color = INK) -> void:
	if not font:
		return
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_draw_text_font(font, text, Vector2(center.x - width * 0.5, center.y + font_size * 0.35), font_size, color)

func _draw_pill(text: String, pos: Vector2, color: Color, width := 104.0) -> void:
	_draw_panel(Rect2(pos, Vector2(width, 30)), Color(color, 0.14), Color(color, 0.55), 15, 1)
	_draw_center(text, pos + Vector2(width * 0.5, 15), 13, color)

func _draw_status_badge(text: String, pos: Vector2, color: Color, positive: bool, width := 104.0) -> void:
	_draw_panel(Rect2(pos, Vector2(width, 30)), Color(color, 0.13), Color(color, 0.66), 8, 1)
	var marker := Rect2(pos + Vector2(9, 10), Vector2(10, 10))
	if positive:
		draw_circle(marker.get_center(), 5.0, color)
		draw_circle(marker.get_center(), 2.0, Color(COAL, 0.72))
	else:
		draw_colored_polygon(PackedVector2Array([marker.position + Vector2(5, 0), marker.position + Vector2(10, 10), marker.position]), color)
	_draw_center(text, pos + Vector2(width * 0.5 + 6, 15), 12, color)

func _draw_playing_card(rect: Rect2, rank: int, accent: Color = RED, suit_index := -1) -> void:
	_draw_panel(Rect2(rect.position + Vector2(0, 4), rect.size), Color(0, 0, 0, 0.30), Color.TRANSPARENT, 6, 0)
	_draw_panel(rect, WARM_PAPER, Color(accent, 0.64), 6, 1)
	var suit := posmod(rank - 1, 4) if suit_index < 0 else posmod(suit_index, 4)
	var red_suit := suit == 1 or suit == 3
	var card_color := Color("c93f55") if red_suit else Color("182136")
	var rank_label := _card_rank(rank)
	var suit_label: String = ["♠", "♥", "♣", "◆"][suit]
	_draw_text_font(LATIN_FONT, rank_label, rect.position + Vector2(6, 18), max(10, int(rect.size.x * 0.18)), card_color)
	_draw_center_font(SYMBOL_FONT, suit_label, rect.get_center() + Vector2(0, 7), max(15, int(rect.size.x * 0.28)), card_color)
	_draw_text_font(LATIN_FONT, rank_label, rect.end - Vector2(7 + max(8, int(rect.size.x * 0.18)) * 0.52, 7), max(8, int(rect.size.x * 0.16)), card_color)

func _draw_card_back(rect: Rect2, accent: Color) -> void:
	_draw_panel(Rect2(rect.position + Vector2(0, 4), rect.size), Color(0, 0, 0, 0.30), Color.TRANSPARENT, 6, 0)
	_draw_panel(rect, Color("26355a"), Color(WARM_PAPER, 0.66), 6, 2)
	var inset := rect.grow(-6)
	_draw_panel(inset, Color(accent, 0.22), Color(accent, 0.62), 3, 1)
	for y in range(int(inset.position.y + 4), int(inset.end.y), 8):
		draw_line(Vector2(inset.position.x + 3, y), Vector2(inset.end.x - 3, y), Color(WARM_PAPER, 0.12), 1.0)

func _card_rank(rank: int) -> String:
	match rank:
		1: return "A"
		11: return "J"
		12: return "Q"
		13: return "K"
		_: return str(rank)

func _catalog_item(id: String) -> Dictionary:
	for item in catalog:
		if item.id == id:
			return item
	return {"id":id, "title":id, "subtitle":"", "group":"游戏", "accent":CYAN, "desc":""}

func _start_game_state() -> void:
	state = {"status":"playing", "score":0, "moves":0, "game_id":game_id}
	selected_cell = Vector2i(-1, -1)
	snake_clock = 0.0
	match game_id:
		"merge2248": _init_merge2248()
		"merge2048": _init_merge()
		"watermelon": _init_watermelon()
		"sudoku", "meowdoku": _init_sudoku()
		"snake_classic": _init_snake_gb()
		"snake_io": _init_snakes_arena()
		"solitaire": _init_solitaire()
		"tripeaks": _init_tripeaks()
		"mahjong": _init_mahjong()
		"tileclub": _init_tileclub()
		"amaze_go", "arrow_go", "amaze": _init_amaze()
	_sync_observability()

func _new_grid(width: int, height: int, value: Variant = 0) -> Array:
	var result: Array = []
	for y in range(height):
		var row: Array = []
		for _x in range(width):
			row.append(value)
		result.append(row)
	return result

# -----------------------------------------------------------------------------
# Number Connect / 2248
# -----------------------------------------------------------------------------

func _init_merge2248() -> void:
	merge2248_model.reset(abs(game_id.hash()) + 17, 8)
	merge2248_drag_active = false
	merge2248_fx.clear()
	merge2248_chain_pulse = -10.0
	merge2248_chain_grade = 0
	merge2248_settle_started = -10.0
	merge2248_settle_grade = 1
	merge2248_juice_started = -10.0
	merge2248_juice_grade = 0
	merge2248_juice_destination = Vector2.ZERO
	merge2248_score_started = -10.0
	merge2248_score_grade = 1
	_sync_merge2248_state()

func _sync_merge2248_state() -> void:
	state.merge2248 = merge2248_model.snapshot()
	state.board = state.merge2248.board
	state.selected = state.merge2248.selected
	state.score = state.merge2248.score
	state.moves = state.merge2248.moves
	state.status = state.merge2248.status
	state.preview = state.merge2248.preview

func _merge2248_board_rect() -> Rect2:
	return Rect2(50, 224, 440, 640)

func _merge2248_cell_at(screen_pos: Vector2) -> Vector2i:
	var rect := _merge2248_board_rect()
	if not rect.has_point(screen_pos):
		return Vector2i(-1, -1)
	var cell_size := Vector2(rect.size.x / 5.0, rect.size.y / float(merge2248_model.height))
	return Vector2i(int((screen_pos.x - rect.position.x) / cell_size.x), int((screen_pos.y - rect.position.y) / cell_size.y))

func _merge2248_begin_at(screen_pos: Vector2) -> bool:
	var began := merge2248_model.begin(_merge2248_cell_at(screen_pos))
	if began:
		merge2248_pointer = screen_pos
		merge2248_chain_pulse = elapsed
		merge2248_chain_grade = 0
		_play_sfx(SFX_SNAKE_KEY, -18.0, 1.12)
		_haptic(4)
		_sync_merge2248_state()
		queue_redraw()
	return began

func _merge2248_extend_at(screen_pos: Vector2) -> void:
	merge2248_pointer = screen_pos
	if merge2248_model.extend(_merge2248_cell_at(screen_pos)):
		merge2248_chain_pulse = elapsed
		var previous_grade := merge2248_chain_grade
		merge2248_chain_grade = _merge2248_feedback_grade(merge2248_model.selected.size(), merge2248_model.preview_result())
		var chain_pitch := 1.0 + minf(float(merge2248_model.selected.size()), 9.0) * 0.055
		_play_sfx(SFX_SNAKE_KEY, -17.0, chain_pitch)
		_haptic(6 + merge2248_chain_grade * 3 + (4 if merge2248_chain_grade > previous_grade else 0))
		_sync_merge2248_state()
		queue_redraw()

func _merge2248_release() -> void:
	# Preserve presentation inputs before the authoritative model consumes the
	# path. These copies never influence legality, score, gravity, or refill.
	var path_values: Array[int] = []
	for selected in merge2248_model.selected:
		path_values.append(int(merge2248_model.board[selected.y][selected.x]))
	var outcome: Dictionary = merge2248_model.release()
	_sync_merge2248_state()
	if bool(outcome.get("changed", false)):
		var gained := int(outcome.gained)
		var result_value := int(outcome.result)
		var chain_length := int(outcome.path.size())
		var feedback_grade := _merge2248_feedback_grade(chain_length, result_value)
		var path_points: Array[Vector2] = []
		for path_cell in outcome.path:
			path_points.append(_merge2248_cell_center(path_cell))
		var destination := path_points[-1]
		merge2248_fx.append({
			"started": elapsed,
			"points": path_points,
			"values": path_values,
			"result": result_value,
			"color": _merge2248_color(result_value),
			"grade": feedback_grade,
			"chain_length": chain_length,
			"gained": gained,
			"duration": 0.76 + float(feedback_grade) * 0.11,
		})
		_merge2248_start_juice(feedback_grade, destination)
		_play_sfx(SFX_SNAKE_EAT, -8.0 + float(feedback_grade - 1) * 1.2, 0.90 + minf(float(chain_length), 9.0) * 0.035)
		if feedback_grade >= 3:
			_play_sfx(SFX_SNAKE_EAT, -15.0, 0.58 + float(feedback_grade) * 0.045)
		_haptic_pattern(_merge2248_release_haptic(feedback_grade))
		var grade_label := _merge2248_grade_label(feedback_grade)
		_flash_feedback("%s ×%d · +%d → %d" % [grade_label, chain_length, gained, result_value], _merge2248_grade_color(feedback_grade))
		feedback_until = elapsed + 0.78 + float(feedback_grade) * 0.12
		_log_event("merge2248_connect", {"length":chain_length, "gained":gained, "result":result_value, "feedback_grade":feedback_grade})
		if state.status != "playing":
			_capture("win_merge2248" if state.status == "won" else "game_over_merge2248")
	queue_redraw()

func _merge2248_feedback_grade(chain_length: int, result_value: int) -> int:
	var grade := 1
	if chain_length >= 3 or result_value >= 16:
		grade = 2
	if chain_length >= 5 or result_value >= 128:
		grade = 3
	if chain_length >= 8 or result_value >= 512:
		grade = 4
	return grade

func _merge2248_grade_label(grade: int) -> String:
	match clampi(grade, 1, 4):
		1: return "轻甜"
		2: return "连携"
		3: return "超连携"
		_: return "传奇配方"

func _merge2248_grade_color(grade: int) -> Color:
	match clampi(grade, 1, 4):
		1: return Color("fff0c7")
		2: return Color("f4c568")
		3: return Color("ff9b78")
		_: return Color("ffe46f")

func _merge2248_release_haptic(grade: int) -> Array[int]:
	match clampi(grade, 1, 4):
		1:
			var light: Array[int] = [20]
			return light
		2:
			var combo: Array[int] = [18, 24, 34]
			return combo
		3:
			var super_combo: Array[int] = [24, 18, 48]
			return super_combo
		_:
			var legendary: Array[int] = [30, 16, 46, 18, 72]
			return legendary

func _merge2248_start_juice(grade: int, destination: Vector2) -> void:
	merge2248_juice_started = elapsed
	merge2248_juice_grade = clampi(grade, 1, 4)
	merge2248_juice_destination = destination
	merge2248_settle_grade = merge2248_juice_grade
	merge2248_settle_started = elapsed + 0.10 + float(merge2248_juice_grade) * 0.018
	merge2248_score_started = elapsed
	merge2248_score_grade = merge2248_juice_grade
	score_pulse_until = elapsed + 0.28 + float(merge2248_juice_grade) * 0.07
	merge2248_chain_grade = 0
	_impact(destination, _merge2248_grade_color(merge2248_juice_grade), 0.54 + float(merge2248_juice_grade) * 0.27)

func _merge2248_shake_offset() -> Vector2:
	if merge2248_juice_grade <= 0:
		return Vector2.ZERO
	var age := elapsed - merge2248_juice_started - 0.055
	var duration := 0.08 + float(merge2248_juice_grade) * 0.085
	if age < 0.0 or age >= duration:
		return Vector2.ZERO
	var amplitude: float = [0.7, 2.8, 6.0, 10.5][merge2248_juice_grade - 1]
	var t := clampf(age / duration, 0.0, 1.0)
	var envelope := pow(1.0 - t, 1.75)
	var direction := (_merge2248_board_rect().get_center() - merge2248_juice_destination).normalized()
	if direction.length_squared() < 0.01:
		direction = Vector2.RIGHT
	var tangent := Vector2(-direction.y, direction.x)
	var phase := merge2248_juice_destination.x * 0.017 + merge2248_juice_destination.y * 0.011
	var longitudinal := sin(age * (78.0 + float(merge2248_juice_grade) * 7.0) + phase)
	var lateral := sin(age * 113.0 + phase * 1.7 + 0.8)
	return (direction * longitudinal + tangent * lateral * 0.58) * amplitude * envelope

func _merge2248_board_juice_transform(rect: Rect2) -> Transform2D:
	var center := rect.get_center()
	var scale_value := Vector2.ONE
	var rotation := 0.0
	var age := elapsed - merge2248_juice_started
	var grade_strength := float(merge2248_juice_grade)
	var duration := 0.20 + grade_strength * 0.095
	if merge2248_juice_grade > 0 and age >= 0.0 and age < duration:
		if age < 0.075:
			var compression := sin(clampf(age / 0.075, 0.0, 1.0) * PI)
			scale_value = Vector2(1.0 + compression * 0.010 * grade_strength, 1.0 - compression * 0.016 * grade_strength)
		else:
			var rebound_t := clampf((age - 0.075) / (duration - 0.075), 0.0, 1.0)
			var rebound := sin(rebound_t * PI * 4.5) * pow(1.0 - rebound_t, 1.8)
			scale_value = Vector2(1.0 - rebound * 0.0065 * grade_strength, 1.0 + rebound * 0.010 * grade_strength)
			var turn_sign := -1.0 if merge2248_juice_destination.x < center.x else 1.0
			rotation = rebound * 0.0014 * maxf(0.0, grade_strength - 1.0) * turn_sign
	var offset := _merge2248_shake_offset()
	var cosine := cos(rotation)
	var sine := sin(rotation)
	var x_axis := Vector2(cosine, sine) * scale_value.x
	var y_axis := Vector2(-sine, cosine) * scale_value.y
	var transformed_center := x_axis * center.x + y_axis * center.y
	return Transform2D(x_axis, y_axis, center + offset - transformed_center)

func _merge2248_cell_center(cell_position: Vector2i) -> Vector2:
	var rect := _merge2248_board_rect()
	var cell := Vector2(rect.size.x / 5.0, rect.size.y / float(merge2248_model.height))
	return rect.position + Vector2((cell_position.x + 0.5) * cell.x, (cell_position.y + 0.5) * cell.y)

func _merge2248_highest_label() -> String:
	var highest := 0
	for row in merge2248_model.board:
		for value in row:
			highest = maxi(highest, int(value))
	return str(highest)

func _merge2248_color(value: int) -> Color:
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
		_: return Color("8290ab")

func _draw_merge2248() -> void:
	var rect := _merge2248_board_rect()
	var rows: int = merge2248_model.height
	var cell := Vector2(rect.size.x / 5.0, rect.size.y / float(rows))
	var selected_cells: Array = merge2248_model.selected
	_draw_section_heading("糖果配方", "同值起步 · 八向拉糖", Color("f1bd68"))
	var juice_transform := _merge2248_board_juice_transform(rect)
	var juice_scale := juice_transform.get_scale()
	var juice_rotation := juice_transform.get_rotation()
	draw_set_transform_matrix(juice_transform)
	merge2248_presenter.draw_board(self, rect, cell)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var path_points: Array[Vector2] = []
	for selected_cell_position in selected_cells:
		path_points.append(juice_transform * _merge2248_cell_center(selected_cell_position))
	var preview := merge2248_model.preview_result()
	var preview_grade := _merge2248_feedback_grade(selected_cells.size(), preview) if preview > 0 else maxi(1, merge2248_chain_grade)
	var ribbon_color := _merge2248_color(preview) if preview > 0 else Color("efb85f")
	merge2248_presenter.draw_ribbon(self, path_points, juice_transform * merge2248_pointer, merge2248_drag_active, elapsed, ribbon_color, preview_grade)

	for y in range(rows):
		for x in range(5):
			var center := rect.position + Vector2((x + 0.5) * cell.x, (y + 0.5) * cell.y)
			var value := int(merge2248_model.board[y][x])
			var selected_now := Vector2i(x, y) in selected_cells
			var selection_index := selected_cells.find(Vector2i(x, y))
			var token_scale := Vector2.ONE
			var token_rotation := 0.0
			var token_offset := Vector2.ZERO

			# New authoritative cells land with a small row/column stagger after
			# the gather impact. This animation does not block the next input.
			var settle_delay := float(y) * 0.018 + float(x) * 0.012
			var settle_age := elapsed - merge2248_settle_started - settle_delay
			var settle_duration := 0.40 + float(merge2248_settle_grade) * 0.04
			if settle_age >= 0.0 and settle_age < settle_duration:
				var settle_t := clampf(settle_age / settle_duration, 0.0, 1.0)
				var fall := 1.0 - pow(1.0 - settle_t, 3.0)
				token_offset.y = lerpf(-16.0 - float(merge2248_settle_grade) * 5.0, 0.0, fall)
				var contact := sin(clampf((settle_t - 0.62) / 0.38, 0.0, 1.0) * PI)
				var contact_strength := 0.045 + float(merge2248_settle_grade) * 0.014
				token_scale *= Vector2(1.0 + contact * contact_strength, 1.0 - contact * contact_strength)

			if selected_now:
				var pulse := sin(elapsed * 6.8 - float(maxi(selection_index, 0)) * 0.48)
				var accepted_age := clampf((elapsed - merge2248_chain_pulse) / 0.18, 0.0, 1.0)
				var accepted_pop := sin(accepted_age * PI) * 0.10
				token_scale *= Vector2(1.08 + accepted_pop + pulse * 0.012, 0.96 - accepted_pop * 0.32 - pulse * 0.008)
				if selection_index == selected_cells.size() - 1 and merge2248_drag_active:
					token_rotation = clampf((merge2248_pointer.x - center.x) / 900.0, -0.075, 0.075)

			merge2248_presenter.draw_token(
				self,
				juice_transform * (center + token_offset),
				value,
				_merge2248_color(value),
				selected_now,
				NUMBER_FONT,
				elapsed,
				token_scale * juice_scale,
				token_rotation + juice_rotation
			)

	var helper := "连接相邻同值糖果，再追踪同值或双倍数字"
	if preview > 0:
		var label_width: float = [178.0, 210.0, 234.0, 258.0][preview_grade - 1]
		merge2248_presenter.draw_recipe_label(self, Rect2(270.0 - label_width * 0.5, 879, label_width, 40), preview, DISPLAY_FONT, preview_grade, selected_cells.size(), elapsed)
	else:
		_draw_panel(Rect2(101, 884, 338, 30), Color("17484a", 0.90), Color("f3d59d", 0.26), 15, 1)
		_draw_center(helper, Vector2(270, 903), 11, Color("fff1ce", 0.94))
	_draw_merge2248_fx(juice_transform)

func _draw_merge2248_fx(juice_transform: Transform2D = Transform2D.IDENTITY) -> void:
	var active: Array[Dictionary] = []
	for effect in merge2248_fx:
		var age := elapsed - float(effect.started)
		if age > float(effect.get("duration", 0.90)):
			continue
		active.append(effect)
		var visual_effect := effect.duplicate()
		var transformed_points: Array[Vector2] = []
		for point in effect.get("points", []):
			transformed_points.append(juice_transform * Vector2(point))
		visual_effect.points = transformed_points
		merge2248_presenter.draw_merge_fx(self, visual_effect, elapsed, NUMBER_FONT, DISPLAY_FONT)
	merge2248_fx = active

# -----------------------------------------------------------------------------
# 2048
# -----------------------------------------------------------------------------

func _init_merge() -> void:
	merge2048_motion.clear()
	var board := _new_grid(4, 4, 0)
	board[1][1] = 2
	board[2][2] = 2
	board[1][2] = 4
	board[2][1] = 4
	state["board"] = board
	state["target"] = 2248 if game_id == "merge2248" else 2048
	state["score"] = 0
	_spawn_merge_tile()
	_spawn_merge_tile()

func _spawn_merge_tile() -> Dictionary:
	var empty: Array[Vector2i] = []
	var board: Array = state["board"]
	for y in range(4):
		for x in range(4):
			if int(board[y][x]) == 0:
				empty.append(Vector2i(x, y))
	if empty.is_empty():
		return {}
	var p: Vector2i = empty[rng.randi_range(0, empty.size() - 1)]
	var value := 4 if rng.randf() > 0.86 else 2
	board[p.y][p.x] = value
	return {"position":p, "value":value}

func _slide_line(line: Array) -> Dictionary:
	var compact: Array = []
	for source_index in range(line.size()):
		var value := int(line[source_index])
		if int(value) > 0:
			compact.append({"value":value, "sources":[source_index]})
	var merged: Array = []
	var gained := 0
	var i := 0
	while i < compact.size():
		var current: Dictionary = compact[i]
		if i + 1 < compact.size() and int(current["value"]) == int(compact[i + 1]["value"]):
			var value: int = int(current["value"]) * 2
			var sources: Array = current["sources"].duplicate()
			sources.append_array(compact[i + 1]["sources"])
			merged.append({"value":value, "sources":sources})
			gained += value
			i += 2
		else:
			merged.append(current)
			i += 1
	var result_line: Array = []
	var moves: Array[Dictionary] = []
	for destination_index in range(merged.size()):
		var group: Dictionary = merged[destination_index]
		var result_value := int(group["value"])
		result_line.append(result_value)
		var sources: Array = group["sources"]
		for source_index in sources:
			moves.append({
				"from_index":int(source_index),
				"to_index":destination_index,
				"source_value":int(line[int(source_index)]),
				"result_value":result_value,
				"merged":sources.size() > 1,
			})
	while result_line.size() < line.size():
		result_line.append(0)
	return {"line":result_line, "gained":gained, "changed":result_line != line, "moves":moves}

func _merge_move(direction: Vector2i) -> void:
	if state.get("status", "playing") != "playing":
		return
	var board: Array = state["board"]
	var board_before: Array = board.duplicate(true)
	var changed := false
	var gained := 0
	var motion_moves: Array[Dictionary] = []
	for index in range(4):
		var line: Array = []
		if direction == Vector2i.LEFT or direction == Vector2i.RIGHT:
			line = board[index].duplicate()
		else:
			for y in range(4):
				line.append(board[y][index])
		if direction == Vector2i.RIGHT or direction == Vector2i.DOWN:
			line.reverse()
		var outcome: Dictionary = _slide_line(line)
		var result_line: Array = outcome["line"]
		for line_move in outcome["moves"]:
			var from_index := int(line_move["from_index"])
			var to_index := int(line_move["to_index"])
			if direction == Vector2i.RIGHT or direction == Vector2i.DOWN:
				from_index = 3 - from_index
				to_index = 3 - to_index
			var from := Vector2i(from_index, index) if direction.x != 0 else Vector2i(index, from_index)
			var to := Vector2i(to_index, index) if direction.x != 0 else Vector2i(index, to_index)
			if from != to or bool(line_move["merged"]):
				motion_moves.append({
					"from":from,
					"to":to,
					"source_value":int(line_move["source_value"]),
					"result_value":int(line_move["result_value"]),
					"merged":bool(line_move["merged"]),
				})
		if direction == Vector2i.RIGHT or direction == Vector2i.DOWN:
			result_line.reverse()
		if direction == Vector2i.LEFT or direction == Vector2i.RIGHT:
			board[index] = result_line
		else:
			for y in range(4):
				board[y][index] = result_line[y]
		changed = changed or bool(outcome["changed"])
		gained += int(outcome["gained"])
	if not changed:
		if game_id == "merge2048":
			var reject_position := Vector2(270, 454) + Vector2(direction) * 116.0
			_flash_feedback("这一侧已经锁住", RED)
			# The persistent top toast carries the copy; keep the local rejection
			# mark text-free so it cannot cover live tile values on a full board.
			_start_catalog_event("merge_reject", reject_position, RED, 1, "", 0.58, {"semantic":"wood_reject", "direction":direction})
			_log_event("merge_rejected", {"direction":str(direction), "score":state["score"]})
		return
	var board_after_slide: Array = board.duplicate(true)
	state["moves"] = int(state["moves"]) + 1
	state["score"] = int(state["score"]) + gained
	var spawn := _spawn_merge_tile()
	_flash_feedback("合成 +%d" % gained if gained > 0 else "木牌滑动归位", GOLD if gained > 0 else CYAN)
	var impact_position := _merge_impact_position(board_before, board_after_slide, direction, gained)
	var merge_color := GOLD if gained > 0 else CYAN
	var merge_grade := 1
	if gained >= 8: merge_grade = 2
	if gained >= 32: merge_grade = 3
	if gained >= 128: merge_grade = 4
	var reached_target := _merge_has_target()
	if reached_target:
		merge_grade = 4
	var impact_cell := Vector2i(
		clampi(int(floor((impact_position.x - 42.0) / 109.0)), 0, 3),
		clampi(int(floor((impact_position.y - 236.0) / 109.0)), 0, 3)
	)
	if game_id == "merge2048":
		merge2048_motion = {
			"started":elapsed,
			"duration":0.62 + float(merge_grade) * 0.04,
			"moves":motion_moves,
			"spawn":spawn,
			"grade":merge_grade,
			"impact_cell":impact_cell,
			"direction":direction,
			"board_before":board_before,
			"board_after_slide":board_after_slide,
		}
	_impact(impact_position, merge_color, 0.7 if gained == 0 else 1.0)
	var semantic := "wood_slide" if gained == 0 else ("wood_masterpiece" if merge_grade == 4 else ("wood_milestone" if merge_grade == 3 else "wood_merge"))
	var label := "木牌归位" if gained == 0 else ("大师雕版 · +%d" % gained if merge_grade == 4 else ("金纹连携 · +%d" % gained if merge_grade == 3 else "木作合成 · +%d" % gained))
	_start_catalog_event("merge", impact_position, merge_color, merge_grade, label, 0.66 + merge_grade * 0.07, {"semantic":semantic, "gained":gained, "direction":direction})
	_log_event("merge_move", {"direction":str(direction), "gained":gained, "score":state["score"], "grade":merge_grade, "semantic":semantic, "motion_count":motion_moves.size()})
	if reached_target:
		state["status"] = "won"
		_capture("win_%s" % game_id)
	elif not _merge_has_moves():
		state["status"] = "over"
		_capture("game_over_%s" % game_id)

func _merge_impact_position(before: Array, after: Array, direction: Vector2i, gained: int) -> Vector2:
	var best := Vector2i(1, 1)
	var best_weight := -1.0
	for y in range(4):
		for x in range(4):
			var value := int(after[y][x])
			if value <= 0 or value == int(before[y][x]):
				continue
			var edge_bias := float((3 - x) if direction == Vector2i.LEFT else x) if direction.x != 0 else float((3 - y) if direction == Vector2i.UP else y)
			var weight := float(value) * (3.0 if gained > 0 and value <= gained else 1.0) + edge_bias
			if weight > best_weight:
				best_weight = weight
				best = Vector2i(x, y)
	return Vector2(42, 236) + Vector2(best.x + 0.5, best.y + 0.5) * 109.0

func _merge_has_target() -> bool:
	if game_id == "merge2248":
		return int(state.get("score", 0)) >= 2248
	for row in state["board"]:
		for value in row:
			if int(value) >= _merge_target_tile():
				return true
	return false

func _merge_target_tile() -> int:
	return 2048

func _merge_has_moves() -> bool:
	var board: Array = state["board"]
	for y in range(4):
		for x in range(4):
			if int(board[y][x]) == 0:
				return true
			if x < 3 and board[y][x] == board[y][x + 1]:
				return true
			if y < 3 and board[y][x] == board[y + 1][x]:
				return true
	return false

func _draw_merge() -> void:
	var board: Array = state["board"]
	var origin := Vector2(42, 236)
	var tile := 109.0
	var accent: Color = _catalog_item(game_id).accent
	var board_fill := Color("10302f") if game_id == "merge2248" else Color("3b271c")
	_draw_panel(Rect2(origin - Vector2(13, 8) + Vector2(0, 8), Vector2(466, 462)), Color("140a05", 0.48), Color.TRANSPARENT, 24 if game_id == "merge2248" else 18, 0)
	_draw_panel(Rect2(origin - Vector2(13, 8), Vector2(466, 462)), board_fill, Color(accent, 0.70), 24 if game_id == "merge2248" else 18, 4)
	if game_id == "merge2248":
		for row in range(5):
			draw_line(origin + Vector2(0, row * tile - 4), origin + Vector2(430, row * tile - 4), Color(accent, 0.07), 2.0)
		for y in range(4):
			for x in range(4):
				var value := int(board[y][x])
				var rect := Rect2(origin + Vector2(x * tile, y * tile), Vector2(tile - 7, tile - 7))
				var color := _merge_color(value)
				_draw_panel(Rect2(rect.position + Vector2(0, 6), rect.size), Color(0, 0, 0, 0.34), Color.TRANSPARENT, 20, 0)
				_draw_panel(rect, color, Color("f7d9a6", 0.18 if value > 0 else 0.08), 19, 2 if value > 0 else 1)
				if value > 0:
					draw_circle(rect.get_center(), 38.0 if value < 100 else 31.0, Color(INK, 0.08))
					draw_arc(rect.get_center(), 43.0, -PI * 0.75, PI * 0.75, 24, Color(accent, 0.28), 3.0)
					var number_color := _readable_number_color(_merge_number_background(value))
					_draw_segment_number(value, rect.get_center(), 28.0 if value < 100 else 20.0, number_color)
	else:
		# The renderer owns appearance and timing only; the authoritative board and
		# source-to-destination mappings are produced by the rule path above.
		merge2048_classic_presenter.draw_board(self, board, origin, tile, elapsed, merge2048_motion, TILE_NUMBER_FONT)
	_draw_section_heading("能量矩阵" if game_id == "merge2248" else "经典方阵", "滑动合并同值方块", accent)
	_draw_text("每次合并都会为高能方块充能" if game_id == "merge2248" else "雕版会随数值升级，冲向同侧完成合并", Vector2(42, 734), 12, Color(_game_secondary_text(), 0.82))

func _merge_color(value: int) -> Color:
	if game_id == "merge2048":
		match value:
			0: return Color("6b5a47")
			2: return Color("d9b886")
			4: return Color("c99a61")
			8: return Color("efa363")
			16: return Color("ee8353")
			32: return Color("e96149")
			64: return Color("db3d35")
			128: return Color("e8c455")
			256: return Color("d9ae36")
			512: return Color("c98b28")
			1024: return Color("ad6d21")
			_: return Color("704d83")
	match value:
		0: return Color("163f3e")
		2: return Color("244f50")
		4: return Color("276668")
		8: return Color("298080")
		16: return Color("35a28f")
		32: return Color("68c875")
		64: return Color("c0d75a")
		128: return Color("f3c95b")
		256: return Color("f0a352")
		512: return Color("e9815b")
		1024: return Color("dd6d80")
		_: return Color("c45fe0")

func _merge_number_background(value: int) -> Color:
	if game_id == "merge2048" and value > 0:
		return merge2048_classic_presenter.number_background(value)
	var fill := _merge_color(value)
	# 2248's energy halo is drawn directly under the digits. Contrast must be
	# chosen against that composited pixel color, not the unmodified tile fill.
	return fill.lerp(INK, 0.08) if game_id == "merge2248" and value > 0 else fill

func _draw_segment_number(value: int, center: Vector2, height: float, color: Color) -> void:
	var text := str(value)
	var digit_width: float = height * 0.56
	var gap: float = height * 0.18
	var total_width: float = float(text.length()) * digit_width + float(maxi(0, text.length() - 1)) * gap
	var cursor_x: float = center.x - total_width * 0.5
	for character in text:
		_draw_segment_digit(character, Vector2(cursor_x + digit_width * 0.5, center.y), height, color)
		cursor_x += digit_width + gap

func _draw_segment_digit(character: String, center: Vector2, height: float, color: Color) -> void:
	var active: String
	match character:
		"0": active = "abcdef"
		"1": active = "bc"
		"2": active = "abdeg"
		"3": active = "abcdg"
		"4": active = "bcfg"
		"5": active = "acdfg"
		"6": active = "acdefg"
		"7": active = "abc"
		"8": active = "abcdefg"
		"9": active = "abcdfg"
		_: active = "g"
	var half_w := height * 0.24
	var half_h := height * 0.46
	var middle_y := 0.0
	var points := {
		"a":[Vector2(-half_w, -half_h), Vector2(half_w, -half_h)],
		"b":[Vector2(half_w, -half_h), Vector2(half_w, middle_y)],
		"c":[Vector2(half_w, middle_y), Vector2(half_w, half_h)],
		"d":[Vector2(-half_w, half_h), Vector2(half_w, half_h)],
		"e":[Vector2(-half_w, middle_y), Vector2(-half_w, half_h)],
		"f":[Vector2(-half_w, -half_h), Vector2(-half_w, middle_y)],
		"g":[Vector2(-half_w, middle_y), Vector2(half_w, middle_y)]
	}
	var width := maxf(2.4, height * 0.105)
	for segment in active:
		var ends: Array = points[String(segment)]
		draw_line(center + ends[0] + Vector2(0, 1.5), center + ends[1] + Vector2(0, 1.5), Color(COAL, 0.26), width + 1.4, true)
		draw_line(center + ends[0], center + ends[1], color, width, true)

func _readable_number_color(fill: Color) -> Color:
	var dark := Color.BLACK
	var light := Color.WHITE
	return dark if _contrast_ratio(fill, dark) >= _contrast_ratio(fill, light) else light

func _contrast_ratio(first: Color, second: Color) -> float:
	var lighter := maxf(_relative_luminance(first), _relative_luminance(second))
	var darker := minf(_relative_luminance(first), _relative_luminance(second))
	return (lighter + 0.05) / (darker + 0.05)

func _relative_luminance(color: Color) -> float:
	return 0.2126 * _linear_channel(color.r) + 0.7152 * _linear_channel(color.g) + 0.0722 * _linear_channel(color.b)

func _linear_channel(channel: float) -> float:
	return channel / 12.92 if channel <= 0.04045 else pow((channel + 0.055) / 1.055, 2.4)

# -----------------------------------------------------------------------------
# 2048 Balls / watermelon
# -----------------------------------------------------------------------------

func _init_watermelon() -> void:
	state["columns"] = [[], [], [], [], [], [], []]
	state["next"] = 1
	state["score"] = 0
	state["moves"] = 0

func _water_drop(column: int) -> void:
	if game_id != "watermelon" or state.get("status") != "playing":
		return
	var columns: Array = state["columns"]
	if columns[column].size() >= 7:
		var blocked_position := Vector2(70 + column * 62, 338)
		_flash_feedback("这列已经装满", RED)
		_start_catalog_event("fruit_error_full", blocked_position, RED, 2, "换一条轨道", 0.68)
		_log_event("ball_drop_rejected", {"column":column, "reason":"column_full"})
		return
	var value := int(state["next"])
	columns[column].append(value)
	state["next"] = 1 + ((value + rng.randi_range(0, 2)) % 5)
	state["moves"] = int(state["moves"]) + 1
	_flash_feedback("落下 · %s" % _fruit_name(value), _fruit_color(value))
	var merged := true
	var merge_count := 0
	var highest_result := value
	var merge_score_gained := 0
	while merged:
		merged = false
		for i in range(columns[column].size() - 1):
			if columns[column][i] == columns[column][i + 1]:
				columns[column][i] = min(5, int(columns[column][i]) + 1)
				highest_result = maxi(highest_result, int(columns[column][i]))
				merge_count += 1
				columns[column].remove_at(i + 1)
				var merge_points := int(columns[column][i]) * 10
				merge_score_gained += merge_points
				state["score"] = int(state["score"]) + merge_points
				_impact(Vector2(70 + column * 66, 610 - i * 58), _fruit_color(int(columns[column][i])), 0.9)
				merged = true
				break
	var event_row := maxi(0, columns[column].size() - 1)
	if merge_count > 0:
		var merged_row: int = columns[column].find(highest_result)
		if merged_row >= 0:
			event_row = merged_row
	var event_position := Vector2(70 + column * 62, 668 - event_row * 50)
	if merge_count > 0:
		var merge_grade := clampi(1 + merge_count + (1 if highest_result >= 5 else 0), 2, 4)
		var harvest_complete := int(state["score"]) >= 1000
		if harvest_complete:
			merge_grade = 4
		var merge_kind := "fruit_harvest_complete" if harvest_complete else "fruit_merge"
		var merge_label := "丰收完成 · +%d" % merge_score_gained if harvest_complete else "%s%s · +%d" % [_fruit_name(highest_result), "连携" if merge_count > 1 else "合成", merge_score_gained]
		_start_catalog_event(merge_kind, event_position, _fruit_color(highest_result), merge_grade, merge_label, 0.92 if merge_grade >= 3 else 0.78)
	else:
		_start_catalog_event("fruit_drop", event_position, _fruit_color(value), 1, "%s落箱" % _fruit_name(value), 0.56)
	_log_event("ball_drop", {"column":column, "value":value, "merge_count":merge_count, "highest_result":highest_result, "score_gained":merge_score_gained})
	if columns[column].size() >= 7:
		_start_catalog_event("fruit_error_full", Vector2(70 + column * 62, 340), RED, 2, "果箱满了", 0.68)
		state["status"] = "over"
		_capture("watermelon_full")
		return
	if int(state["score"]) >= 1000:
		state["status"] = "won"
		_capture("watermelon_win")

func _water_drop_hint() -> void:
	if game_id == "watermelon" and state.get("status") == "playing":
		_flash_feedback("直接点击果箱内任一轨道", RED)

func _draw_watermelon() -> void:
	_draw_section_heading("果园落口", "点击下方轨道投放", RED)
	_draw_panel(Rect2(396, 226, 112, 80), Color("42243a", 0.96), Color("ffd17e", 0.72), 16, 2)
	_draw_text("下一个", Vector2(412, 247), 10, BRIGHT_MUTED)
	_draw_fruit(Vector2(472, 275), int(state["next"]), 21.0, false)
	watermelon_presenter.draw_crate(self, Rect2(26, 232, 470, 474), elapsed)
	draw_line(Vector2(48, 316), Vector2(474, 316), Color("fff2f5", 0.54), 3.0)
	_draw_text("危险线", Vector2(416, 350), 11, Color("ffd2d8"))
	for col in range(7):
		var x := 43.0 + col * 62.0
		var drop_center := Vector2(x + 27, 334)
		draw_circle(drop_center + Vector2(0, 2), 12.0, Color("1f0e0a", 0.24))
		draw_arc(drop_center, 11.0, 0, TAU, 20, Color("ffd890", 0.52), 1.5)
		draw_line(drop_center - Vector2(0, 5), drop_center + Vector2(0, 5), Color(INK, 0.42), 2.0)
		draw_line(drop_center + Vector2(-4, 2), drop_center + Vector2(0, 6), Color(INK, 0.42), 2.0)
		draw_line(drop_center + Vector2(4, 2), drop_center + Vector2(0, 6), Color(INK, 0.42), 2.0)
		var stack: Array = state["columns"][col]
		for row in range(stack.size()):
			var y := 668.0 - row * 50.0
			_draw_fruit(Vector2(x + 27, y), int(stack[row]), 23.0)
	_draw_text("合成西瓜即可完成本局", Vector2(38, 742), 13, BRIGHT_MUTED)

func _draw_fruit(center: Vector2, value: int, radius: float, animate := true) -> void:
	watermelon_presenter.draw_fruit(self, center, value, radius, elapsed, catalog_fx, animate)

func _fruit_color(value: int) -> Color:
	match value:
		1: return Color("f6d365")
		2: return Color("f49b67")
		3: return Color("ec6d8e")
		4: return Color("bd81e8")
		_: return Color("62d3aa")

func _fruit_symbol(value: int) -> String:
	return ["", "一", "二", "三", "四", "五"][clampi(value, 1, 5)]

func _fruit_name(value: int) -> String:
	return ["", "柠檬", "橙子", "苹果", "葡萄", "西瓜"][clampi(value, 1, 5)]

# -----------------------------------------------------------------------------
# Sudoku / Meowdoku
# -----------------------------------------------------------------------------

func _sudoku_solution() -> Array:
	return [
		[5,3,4,6,7,8,9,1,2], [6,7,2,1,9,5,3,4,8], [1,9,8,3,4,2,5,6,7],
		[8,5,9,7,6,1,4,2,3], [4,2,6,8,5,3,7,9,1], [7,1,3,9,2,4,8,5,6],
		[9,6,1,5,3,7,2,8,4], [2,8,7,4,1,9,6,3,5], [3,4,5,2,8,6,1,7,9]
	]

func _init_sudoku() -> void:
	var solution := _sudoku_solution()
	var puzzle := solution.duplicate(true)
	var holes := [0, 2, 4, 7, 10, 12, 15, 18, 20, 23, 27, 30, 32, 35, 38, 41, 44, 47, 50, 53, 56, 60, 63, 66, 70, 73, 76]
	for index in holes:
		puzzle[index / 9][index % 9] = 0
	state["solution"] = solution
	state["board"] = puzzle
	state["given"] = puzzle.duplicate(true)
	state["mistakes"] = 0
	state["selected"] = [0, 0]
	state["score"] = 0
	if game_id == "meowdoku":
		logic_game_presenter.reset(elapsed, Vector2i(0, 0))

func _sudoku_tap(pos: Vector2) -> void:
	var origin := Vector2(47, 236)
	var cell := 49.5
	if Rect2(origin, Vector2(cell * 9, cell * 9)).has_point(pos):
		var x := int((pos.x - origin.x) / cell)
		var y := int((pos.y - origin.y) / cell)
		state["selected"] = [x, y]
		selected_cell = Vector2i(x, y)
		if game_id == "meowdoku":
			logic_game_presenter.select(selected_cell, elapsed)
			_play_sfx(SFX_LOGIC_SELECT, -19.0, 1.08)
			_haptic(4)
		_log_event("sudoku_cell_selected", {"x":x, "y":y})
		queue_redraw()

func _sudoku_place(number: int) -> void:
	if (game_id != "sudoku" and game_id != "meowdoku") or state.get("status") != "playing":
		return
	if game_id == "meowdoku":
		_meowdoku_place(number)
		return
	var selected: Array = state.get("selected", [0, 0])
	var x := int(selected[0])
	var y := int(selected[1])
	var given: Array = state["given"]
	if int(given[y][x]) != 0:
		return
	var solution: Array = state["solution"]
	if number != 0 and number != int(solution[y][x]):
		state["mistakes"] = int(state["mistakes"]) + 1
		_flash_feedback("这里不是 %d" % number, RED)
		_impact(Vector2(47 + (x + 0.5) * 49.5, 236 + (y + 0.5) * 49.5), RED, 0.45)
		_start_catalog_event("logic_error", Vector2(47 + (x + 0.5) * 49.5, 236 + (y + 0.5) * 49.5), RED, 2, "再想一步", 0.62)
		_log_event("sudoku_mistake", {"x":x, "y":y, "value":number})
		return
	state["board"][y][x] = number
	state["moves"] = int(state["moves"]) + 1
	_flash_feedback("落子 %d" % number, Color("f39ac7") if game_id == "meowdoku" else VIOLET)
	_impact(Vector2(47 + (x + 0.5) * 49.5, 236 + (y + 0.5) * 49.5), Color("f39ac7") if game_id == "meowdoku" else VIOLET, 0.38)
	var sudoku_event_position := Vector2(47 + (x + 0.5) * 49.5, 236 + (y + 0.5) * 49.5)
	var completed_block := _sudoku_block_complete((y / 3) * 3 + x / 3)
	var sudoku_grade := 2 if completed_block else 1
	var sudoku_label := ("猫爪盖章" if game_id == "meowdoku" else "九宫完成") if completed_block else ("落笔正确" if game_id == "sudoku" else "猫爪确认")
	_start_catalog_event("logic_correct", sudoku_event_position, Color("f39ac7") if game_id == "meowdoku" else VIOLET, sudoku_grade, sudoku_label, 0.68)
	if _sudoku_complete():
		_start_catalog_event("logic_complete", Vector2(270, 458), GOLD, 4, "整册完成", 1.05)
		state["score"] = max(100, 1000 - int(state["mistakes"]) * 25)
		state["status"] = "won"
		_capture("sudoku_win")
	else:
		_log_event("sudoku_place", {"x":x, "y":y, "value":number})

func _meowdoku_place(number: int) -> void:
	var selected: Array = state.get("selected", [0, 0])
	var x := int(selected[0])
	var y := int(selected[1])
	var given: Array = state["given"]
	if int(given[y][x]) != 0:
		return
	var solution: Array = state["solution"]
	var cell := Vector2i(x, y)
	var position := logic_game_presenter.cell_center(cell)
	var block := int(y / 3) * 3 + int(x / 3)
	var accent := Color("e16c9f")
	if number != 0 and number != int(solution[y][x]):
		state["mistakes"] = int(state["mistakes"]) + 1
		_flash_feedback("这里不是 %d" % number, RED)
		logic_game_presenter.present("logic_error", cell, block, number, 2, elapsed)
		_start_catalog_event("logic_error", position, RED, 2, "猫爪提醒", 0.66, {"semantic":"logic_error"})
		_log_event("sudoku_mistake", {"x":x, "y":y, "value":number})
		return
	state["board"][y][x] = number
	state["moves"] = int(state["moves"]) + 1
	var completed_block := _sudoku_block_complete(block)
	var completed_all := _sudoku_complete()
	if number == 0:
		_flash_feedback("轻轻擦去", accent)
		logic_game_presenter.present("logic_erase", cell, block, number, 1, elapsed)
		_start_catalog_event("logic_erase", position, accent, 1, "轻轻擦去", 0.54, {"semantic":"logic_erase"})
	elif completed_all:
		_flash_feedback("整册完成", GOLD)
		logic_game_presenter.present("logic_complete", cell, block, number, 4, elapsed)
		_start_catalog_event("logic_complete", Vector2(270, 458), GOLD, 4, "整册完成", 1.18, {"semantic":"logic_complete"})
	elif completed_block:
		_flash_feedback("猫爪盖章", accent)
		logic_game_presenter.present("logic_block_complete", cell, block, number, 3, elapsed)
		_start_catalog_event("logic_block_complete", _sudoku_block_center(block), accent, 3, "猫爪盖章", 0.96, {"semantic":"logic_block_complete"})
	else:
		_flash_feedback("落子 %d" % number, accent)
		logic_game_presenter.present("logic_correct", cell, block, number, 1, elapsed)
		_start_catalog_event("logic_correct", position, accent, 1, "猫爪确认", 0.68, {"semantic":"logic_correct"})
	if completed_all:
		state["score"] = max(100, 1000 - int(state["mistakes"]) * 25)
		state["status"] = "won"
		_capture("meowdoku_win")
	else:
		_log_event("sudoku_place", {"x":x, "y":y, "value":number})

func _sudoku_complete() -> bool:
	for row in state["board"]:
		for value in row:
			if int(value) == 0:
				return false
	return true

func _draw_sudoku() -> void:
	if game_id == "meowdoku":
		var meow_accent := Color("e16c9f")
		var meow_ink := Color("67344d")
		var meow_detail := "选格后输入数字"
		_draw_text_font(DISPLAY_FONT, "猫爪手账", Vector2(30, 207), 18, meow_ink)
		_draw_text(meow_detail, Vector2(508 - UI_FONT.get_string_size(meow_detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x, 205), 11, Color("80536a"))
		draw_line(Vector2(30, 216), Vector2(510, 216), Color(meow_accent, 0.44), 2.0)
		logic_game_presenter.draw_board(self, game_id, state, elapsed, NUMBER_FONT)
		_draw_text("同行、同列与九宫同步定位", Vector2(47, 706), 13, Color("73435b"))
		return
	var origin := Vector2(47, 236)
	var cell := 49.5
	var board: Array = state["board"]
	var given: Array = state["given"]
	var selected: Array = state.get("selected", [0, 0])
	var accent := Color("f39ac7") if game_id == "meowdoku" else VIOLET
	var paper := Color("fff5fb") if game_id == "meowdoku" else Color("f4f0e6")
	_draw_section_heading("猫爪手账" if game_id == "meowdoku" else "逻辑手册", "选格后输入数字", accent)
	_draw_panel(Rect2(origin - Vector2(6, 6), Vector2(cell * 9 + 12, cell * 9 + 12)), Color(0, 0, 0, 0.28), Color.TRANSPARENT, 16 if game_id == "meowdoku" else 4, 0)
	_draw_panel(Rect2(origin - Vector2(4, 4), Vector2(cell * 9 + 8, cell * 9 + 8)), paper, Color(accent, 0.76), 16 if game_id == "meowdoku" else 3, 2)
	if game_id == "meowdoku":
		for ring in range(8):
			var ring_y := origin.y + 24.0 + ring * 54.0
			draw_circle(Vector2(origin.x - 9, ring_y), 5.0, Color("f9d7e8"), false, 2.0)
	else:
		for mark in range(5):
			var mark_x := origin.x + 46.0 + mark * 86.0
			draw_line(Vector2(mark_x, origin.y - 8), Vector2(mark_x + 9, origin.y - 2), Color("b78f55", 0.38), 2.0)
	for y in range(9):
		for x in range(9):
			var rect := Rect2(origin + Vector2(x * cell, y * cell), Vector2(cell, cell))
			var fill := Color("fff8fd") if game_id == "meowdoku" else Color("f8f5ed")
			if int(given[y][x]) > 0:
				fill = Color("f2e4ee") if game_id == "meowdoku" else Color("e7e2d8")
			if int(selected[0]) == x or int(selected[1]) == y or (x / 3 == int(selected[0]) / 3 and y / 3 == int(selected[1]) / 3):
				fill = Color(accent, 0.12)
			if selected[0] == x and selected[1] == y:
				fill = Color(accent, 0.28)
			draw_rect(rect, fill)
			if int(board[y][x]) > 0:
				var value_color := Color("253047") if int(given[y][x]) > 0 else accent.darkened(0.22)
				_draw_center_font(NUMBER_FONT, str(board[y][x]), rect.get_center(), 23, value_color)
	for i in range(10):
		var width := 3.0 if i % 3 == 0 else 1.0
		var line_color := Color("604a67", 0.62) if game_id == "meowdoku" else Color("30374b", 0.62)
		draw_line(origin + Vector2(i * cell, 0), origin + Vector2(i * cell, cell * 9), line_color, width)
		draw_line(origin + Vector2(0, i * cell), origin + Vector2(cell * 9, i * cell), line_color, width)
	if game_id == "meowdoku":
		for block in range(9):
			if _sudoku_block_complete(block):
				var bx := block % 3
				var by := block / 3
				_draw_paw(origin + Vector2(bx * cell * 3 + cell * 2.65, by * cell * 3 + cell * 0.36), Color(accent, 0.58), 0.72)
	_draw_text("选中格会同步标出同行、同列与九宫", Vector2(47, 706), 13, BRIGHT_MUTED)

func _sudoku_block_center(block: int) -> Vector2:
	var bx := block % 3
	var by := int(block / 3)
	return Vector2(47, 236) + Vector2((float(bx) * 3.0 + 1.5) * 49.5, (float(by) * 3.0 + 1.5) * 49.5)

func _sudoku_block_complete(block: int) -> bool:
	var board: Array = state["board"]
	var start_x := (block % 3) * 3
	var start_y := (block / 3) * 3
	for y in range(start_y, start_y + 3):
		for x in range(start_x, start_x + 3):
			if int(board[y][x]) == 0:
				return false
	return true

func _draw_paw(center: Vector2, color: Color, scale := 1.0) -> void:
	draw_circle(center + Vector2(0, 4) * scale, 7 * scale, color)
	for i in range(3):
		draw_circle(center + Vector2(-8 + i * 8, -5) * scale, 3 * scale, color)

# -----------------------------------------------------------------------------
# Snake classic / Snake IO
# -----------------------------------------------------------------------------

func _init_snake_gb() -> void:
	snake_clock = 0.0
	snake_gb_model.reset(abs("snake_gb".hash()) + 17)
	_sync_snake_gb_state()
	snake_ghosts.clear()
	snake_pixels.clear()
	snake_float_labels.clear()
	snake_previous_cells.clear()
	snake_fx_kind = ""
	snake_fx_direction = Vector2i.RIGHT
	snake_result_ready_at = -1.0
	snake_lcd_flash_until = -1.0
	snake_score_bump_until = -1.0
	snake_button_direction = Vector2i.ZERO
	snake_button_until = -1.0
	snake_reject_until = -1.0
	snake_reset_started = elapsed

func _sync_snake_gb_state() -> void:
	state = snake_gb_model.snapshot()
	state["game_id"] = game_id

func _snake_gb_update(delta: float) -> void:
	snake_clock += delta
	if snake_clock < 0.18:
		return
	snake_clock = fmod(snake_clock, 0.18)
	_snake_gb_step()

func _snake_gb_step() -> void:
	snake_previous_cells = state.get("segments", []).duplicate(true)
	snake_move_started = elapsed
	var events: Array[Dictionary] = snake_gb_model.advance_step()
	_sync_snake_gb_state()
	_snake_gb_dispatch(events)

func _snake_gb_dispatch(events: Array[Dictionary]) -> void:
	for event in events:
		var kind := str(event.get("kind", ""))
		match kind:
			"turn_accepted":
				snake_button_direction = _snake_vector(event.get("direction", Vector2i.ZERO))
				snake_button_until = elapsed + 0.11
				_play_sfx(SFX_SNAKE_KEY, -10.0, 0.90 + float(posmod(snake_gb_model.step_index, 4)) * 0.035)
				_haptic(8)
			"turn_rejected":
				snake_reject_direction = _snake_vector(event.get("direction", Vector2i.ZERO))
				snake_reject_until = elapsed + 0.14
				_play_sfx(SFX_SNAKE_REJECT, -14.0, 0.78)
			"moved":
				if bool(event.get("tail_vacated", false)):
					snake_ghosts.append({"cell":event.get("tail", Vector2i.ZERO), "until":elapsed + 0.10})
			"ate":
				snake_fx_kind = "eat"
				snake_fx_started = elapsed
				snake_fx_cell = _snake_vector(event.get("at", Vector2i.ZERO))
				snake_lcd_flash_until = elapsed + 0.09
				snake_score_bump_until = elapsed + 0.22
				_snake_gb_emit_pixels(snake_fx_cell, 10, "eat")
				snake_float_labels.append({"cell":snake_fx_cell, "started":elapsed, "text":"+1"})
				_play_sfx(SFX_SNAKE_EAT, -8.0, 1.12)
				_haptic(18)
				_log_event("snake_gb_food", {"length":int(state.get("score", 4))})
			"growth_materialized":
				snake_score_bump_until = elapsed + 0.24
			"wall_hit", "self_hit":
				snake_fx_kind = "crash"
				snake_fx_started = elapsed
				snake_fx_cell = _snake_vector(event.get("to", Vector2i.ZERO))
				snake_fx_direction = snake_gb_model.direction
				snake_result_ready_at = elapsed + 0.62
				_snake_gb_emit_pixels(snake_fx_cell, 14, "crash")
				_play_sfx(SFX_SNAKE_CRASH, -5.0, 0.82)
				_haptic(50)
				_capture("snake_gb_%s" % kind)
			"length_won":
				snake_fx_kind = "win"
				snake_fx_started = elapsed
				snake_fx_cell = _snake_vector(event.get("at", snake_gb_model.segments[0]))
				snake_result_ready_at = elapsed + 0.72
				_snake_gb_emit_pixels(snake_fx_cell, 22, "win")
				_play_sfx(SFX_SNAKE_WIN, -4.5, 0.94)
				_haptic(70)
				_capture("snake_gb_win")

func _snake_gb_emit_pixels(cell: Vector2i, count: int, kind: String) -> void:
	for index in range(count):
		var angle := TAU * float(index) / maxf(1.0, float(count)) + float(index % 3) * 0.12
		var speed := 32.0 + float(index % 5) * 12.0
		snake_pixels.append({
			"cell":cell, "velocity":Vector2.from_angle(angle) * speed,
			"started":elapsed, "life":0.30 + float(index % 4) * 0.08,
			"size":2.0 + float(index % 3), "kind":"gb_%s" % kind
		})

func _init_snakes_arena() -> void:
	snakes_arena_model.reset(abs("snakes_arena".hash()) + 17, 5, 96)
	arena_pointer_active = false
	arena_aim_direction = Vector2.RIGHT
	arena_boost_active = false
	arena_boost_button_requested = false
	arena_boost_key_requests = {KEY_SPACE:false, KEY_SHIFT:false}
	arena_fx.clear()
	arena_float_labels.clear()
	arena_result_ready_at = -1.0
	arena_rank_bump_until = -1.0
	arena_steer_started = -10.0
	arena_steer_until = -10.0
	arena_competition_until = -10.0
	arena_leader_change_until = -10.0
	arena_leader_change_name = ""
	arena_camera_shake = Vector2.ZERO
	arena_reset_started = elapsed
	arena_tutorial_dismissed = false
	arena_death_segments.clear()
	arena_death_started = -10.0
	arena_eat_started = -10.0
	arena_eat_world = Vector2.ZERO
	arena_eat_value = 0.0
	_sync_snakes_arena_state()
	arena_rank_previous = int(state.get("rank", -1))
	var board: Array = state.get("leaderboard", [])
	arena_leader_previous_id = int(board[0].get("id", -1)) if not board.is_empty() else -1
	arena_camera = _arena_player_world_position()
	arena_camera_previous = arena_camera
	arena_last_player_position = arena_camera

func _sync_snakes_arena_state() -> void:
	state = snakes_arena_model.snapshot()
	state["game_id"] = game_id
	state["started"] = true
	state["score"] = roundi(float(state.get("mass", 0.0)))
	state["moves"] = int(state.get("tick", 0))

func _snakes_arena_update(delta: float) -> void:
	var previous_rank := int(state.get("rank", -1))
	var previous_board: Array = state.get("leaderboard", [])
	var previous_leader_id := int(previous_board[0].get("id", -1)) if not previous_board.is_empty() else -1
	var previous_player: Dictionary = state.get("player", {}).duplicate(true)
	snakes_arena_model.set_player_aim(_arena_player_world_position() + arena_aim_direction * 420.0)
	var model_tick_before := int(snakes_arena_model.tick)
	var events: Array[Dictionary] = snakes_arena_model.step(delta)
	if int(snakes_arena_model.tick) == model_tick_before:
		return
	_sync_snakes_arena_state()
	var current_board: Array = state.get("leaderboard", [])
	var current_leader_id := int(current_board[0].get("id", -1)) if not current_board.is_empty() else -1
	if previous_leader_id >= 0 and current_leader_id >= 0 and current_leader_id != previous_leader_id:
		arena_leader_previous_id = previous_leader_id
		arena_leader_change_name = "你" if current_leader_id == int(state.get("player_id", 0)) else str(current_board[0].get("name", "BOT"))
		arena_leader_change_until = elapsed + 1.18
	for event in events:
		if str(event.get("kind", "")) == "player_died":
			arena_death_segments = previous_player.get("segments", []).duplicate(true)
			arena_death_started = elapsed
			arena_death_skin = int(previous_player.get("skin", 0))
			arena_death_mass = float(previous_player.get("mass", 38.0))
			arena_death_heading = float(previous_player.get("heading", 0.0))
	var player_position := _arena_player_world_position()
	var camera_blend := 1.0 - exp(-delta * 5.8)
	arena_camera_previous = arena_camera
	arena_camera = arena_camera.lerp(player_position, camera_blend)
	arena_last_player_position = player_position
	_snakes_arena_dispatch(events)
	var current_rank := int(state.get("rank", -1))
	if current_rank > 0 and previous_rank > 0 and current_rank != previous_rank:
		arena_rank_bump_until = elapsed + 0.58
		var improved := current_rank < previous_rank
		arena_float_labels.append({"world":player_position, "started":elapsed, "text":"位次 ↑ %d" % current_rank if improved else "位次 %d" % current_rank, "color":Color("ffe28a") if improved else Color("f79a86")})
		if improved:
			_play_sfx(SFX_SNAKE_KEY, -12.0, 1.32)
	if current_rank > 0:
		arena_rank_previous = current_rank

func _snakes_arena_dispatch(events: Array[Dictionary]) -> void:
	for event in events:
		var kind := str(event.get("kind", ""))
		match kind:
			"player_steered":
				arena_tutorial_dismissed = true
				arena_steer_heading = float(event.get("heading", arena_steer_heading))
				arena_steer_turn = float(event.get("turn", 0.0))
				arena_steer_started = elapsed
				arena_steer_until = elapsed + 0.26
			"player_ate":
				var at := _arena_vector(event.get("at", Vector2.ZERO))
				var value := float(event.get("value", 1.0))
				arena_eat_started = elapsed
				arena_eat_world = at
				arena_eat_value = value
				_snakes_arena_emit_fx("eat", at, Color("ffd92f"), 12)
				arena_float_labels.append({"world":at, "started":elapsed, "text":"+%.1f 体量" % value, "color":Color("fff1ce")})
				_play_sfx(SFX_SNAKE_EAT, -9.0, 1.02 + minf(0.18, value * 0.035))
				_haptic(14)
				_log_event("snakes_seed", {"mass":float(state.get("mass", 0.0))})
			"boost_started":
				if int(event.get("id", -1)) == 0:
					_snakes_arena_emit_fx("boost", _arena_player_world_position(), Color("06ddea"), 7)
					_play_sfx(SFX_SNAKE_KEY, -13.0, 1.42)
					_haptic(10)
			"boost_rejected":
				if int(event.get("id", -1)) == 0:
					_clear_arena_boost_requests()
					arena_float_labels.append({"world":_arena_player_world_position(), "started":elapsed, "text":"还吃不动！", "color":Color("ffb09e")})
					_play_sfx(SFX_SNAKE_REJECT, -9.0, 0.92)
					_haptic(16)
			"boost_shed":
				if int(event.get("id", -1)) == 0:
					_snakes_arena_emit_fx("shed", _arena_vector(event.get("at", Vector2.ZERO)), Color("06ddea"), 2)
			"bot_died":
				var bot_at := _arena_vector(event.get("at", Vector2.ZERO))
				arena_competition_world = bot_at
				arena_competition_until = elapsed + 1.24
				_snakes_arena_emit_fx("debris", bot_at, Color("ffd92f"), 20)
				arena_float_labels.append({"world":bot_at, "started":elapsed, "text":"彩豆散开！", "color":Color("fff1ce")})
				_play_sfx(SFX_SNAKE_CRASH, -13.0, 1.18)
			"bot_ate":
				var forage_at := _arena_vector(event.get("at", Vector2.ZERO))
				var forage_value := float(event.get("value", 1.0))
				_snakes_arena_emit_fx("scavenge", forage_at, Color("ffe28a"), 5)
				arena_float_labels.append({"world":forage_at, "started":elapsed, "text":"抢食 +%.1f" % forage_value, "color":Color("fff2b8")})
			"player_died":
				var player_at := _arena_vector(event.get("at", _arena_player_world_position()))
				if arena_death_segments.is_empty():
					var dead_player: Dictionary = state.get("player", {})
					arena_death_segments = dead_player.get("segments", []).duplicate(true)
					arena_death_started = elapsed
					arena_death_skin = int(dead_player.get("skin", 0))
					arena_death_mass = float(dead_player.get("mass", 38.0))
					arena_death_heading = float(dead_player.get("heading", 0.0))
				_clear_arena_boost_requests()
				arena_pointer_active = false
				arena_result_ready_at = elapsed + 0.72
				_snakes_arena_emit_fx("death", player_at, Color("ff3341"), 28)
				arena_camera_shake = Vector2(10.0, 6.0)
				_play_sfx(SFX_SNAKE_CRASH, -4.5, 0.92)
				_haptic(62)
				_capture("snakes_player_died")

func _snakes_arena_emit_fx(kind: String, world: Vector2, color: Color, count: int) -> void:
	for index in range(count):
		while arena_fx.size() >= 120:
			arena_fx.pop_front()
		var angle := TAU * float(index) / maxf(1.0, float(count)) + rng.randf_range(-0.10, 0.10)
		var speed := 38.0 + float(index % 7) * 15.0
		arena_fx.append({
			"kind":kind, "world":world, "velocity":Vector2.from_angle(angle) * speed,
			"started":elapsed, "life":0.34 + float(index % 5) * 0.095,
			"size":2.2 + float(index % 4) * 1.3, "color":color
		})

func _snakes_arena_prune_fx() -> void:
	for index in range(arena_fx.size() - 1, -1, -1):
		var fx: Dictionary = arena_fx[index]
		if elapsed - float(fx.get("started", elapsed)) >= float(fx.get("life", 0.4)):
			arena_fx.remove_at(index)
	for index in range(arena_float_labels.size() - 1, -1, -1):
		if elapsed - float(arena_float_labels[index].get("started", elapsed)) >= 0.86:
			arena_float_labels.remove_at(index)
	if arena_camera_shake.length_squared() > 0.01:
		arena_camera_shake *= 0.82

func _arena_vector(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value)
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO

func _arena_player_world_position() -> Vector2:
	var player: Dictionary = state.get("player", {})
	return _arena_vector(player.get("position", [0.0, 0.0]))

func _snakes_arena_begin_pointer(position: Vector2) -> void:
	if screen != "game" or game_id != "snake_io" or state.get("status", "playing") != "playing":
		return
	if not Rect2(18, 92, 504, 818).has_point(position):
		return
	arena_pointer_active = true
	_snakes_arena_aim_at_screen(position)

func _snakes_arena_aim_at_screen(position: Vector2) -> void:
	if game_id != "snake_io" or state.get("status", "playing") != "playing":
		return
	var delta := position - Vector2(270, 493)
	if delta.length() < 12.0:
		return
	arena_pointer_screen = position
	arena_aim_direction = delta.normalized()
	snakes_arena_model.set_player_aim(_arena_player_world_position() + arena_aim_direction * 420.0)
	arena_tutorial_dismissed = true

func _snakes_arena_end_pointer(position: Vector2) -> void:
	if arena_pointer_active:
		_snakes_arena_aim_at_screen(position)
	arena_pointer_active = false

func _set_arena_boost(active: bool) -> void:
	if game_id != "snake_io":
		return
	arena_boost_button_requested = active
	_refresh_arena_boost_request()


func _set_arena_boost_key(keycode: Key, active: bool) -> void:
	if game_id != "snake_io":
		return
	arena_boost_key_requests[keycode] = active
	_refresh_arena_boost_request()


func _refresh_arena_boost_request() -> void:
	var keyboard_requested := bool(arena_boost_key_requests.get(KEY_SPACE, false)) or bool(arena_boost_key_requests.get(KEY_SHIFT, false))
	arena_boost_active = (arena_boost_button_requested or keyboard_requested) and state.get("status", "playing") == "playing"
	snakes_arena_model.set_player_boost(arena_boost_active)
	if arena_boost_active:
		arena_tutorial_dismissed = true


func _clear_arena_boost_requests() -> void:
	arena_boost_button_requested = false
	arena_boost_key_requests = {KEY_SPACE:false, KEY_SHIFT:false}
	arena_boost_active = false
	snakes_arena_model.set_player_boost(false)

func _init_snake() -> void:
	snake_model.reset(game_id == "snake_io", abs(game_id.hash()) + 17)
	state = snake_model.snapshot()
	state["game_id"] = game_id
	snake_ghosts.clear()
	snake_pixels.clear()
	snake_float_labels.clear()
	snake_previous_cells.clear()
	snake_fx_kind = ""
	snake_fx_direction = Vector2i.RIGHT
	snake_result_ready_at = -1.0
	snake_lcd_flash_until = -1.0
	snake_score_bump_until = -1.0
	snake_button_until = -1.0
	snake_reject_until = -1.0
	snake_drag_active = false
	snake_drag_samples.clear()
	snake_last_swipe_at = -10.0
	snake_blink_started = elapsed + 1.8 + rng.randf_range(0.0, 1.8)
	snake_tutorial_dismissed = false
	snake_tutorial_fade_started = -10.0
	snake_reset_started = elapsed

func _set_snake_direction(direction: Vector2i) -> void:
	if state.get("status") != "playing":
		return
	if game_id == "snake_classic":
		var events: Array[Dictionary] = snake_gb_model.request_turn(direction)
		_sync_snake_gb_state()
		_snake_gb_dispatch(events)
	elif game_id == "snake_io":
		arena_aim_direction = Vector2(direction).normalized()
		snakes_arena_model.set_player_aim(_arena_player_world_position() + arena_aim_direction * 420.0)
		arena_tutorial_dismissed = true

func _snake_events_have_kind(events: Array[Dictionary], expected_kind: String) -> bool:
	for event in events:
		if str(event.get("kind", "")) == expected_kind:
			return true
	return false

func _snake_begin_drag(position: Vector2) -> void:
	snake_drag_active = true
	snake_drag_origin = position
	snake_drag_anchor = position
	snake_drag_samples.assign([{"position":position, "time":elapsed}])

func _snake_drag_to(position: Vector2) -> void:
	if not snake_drag_active or screen != "game" or game_id != "snake_classic":
		return
	_snake_record_drag_sample(position)
	var delta := position - snake_drag_anchor
	var threshold := 50.0 if elapsed - snake_last_swipe_at < 0.17 else 40.0
	if delta.length() < threshold:
		return
	var direction := Vector2i.ZERO
	if absf(delta.x) > absf(delta.y):
		direction = Vector2i.RIGHT if delta.x > 0.0 else Vector2i.LEFT
	else:
		direction = Vector2i.DOWN if delta.y > 0.0 else Vector2i.UP
	var current_direction := _snake_vector(state.get("direction", [1, 0]))
	if direction.x == current_direction.x and direction.y == current_direction.y:
		return
	if direction + current_direction == Vector2i.ZERO:
		return
	if direction.x == current_direction.x or direction.y == current_direction.y:
		return
	_set_snake_direction(direction)
	if snake_gb_model.turn_queue.has(direction):
		snake_last_swipe_at = elapsed
		snake_drag_anchor = position
		snake_drag_samples.assign([{"position":position, "time":elapsed}])

func _snake_record_drag_sample(position: Vector2) -> void:
	# The reference detector evaluates distance inside a rolling 0.3 s window:
	# a held finger may keep steering forever, but slow accumulated drift is not
	# a swipe.  Interpolating the cutoff keeps the result independent of event
	# frequency (and makes the 40 px threshold meaningful on Web touch input).
	snake_drag_samples.append({"position":position, "time":elapsed})
	var cutoff := elapsed - 0.30
	while snake_drag_samples.size() >= 2 and float(snake_drag_samples[1].get("time", elapsed)) <= cutoff:
		snake_drag_samples.pop_front()
	if snake_drag_samples.size() >= 2:
		var first: Dictionary = snake_drag_samples[0]
		var second: Dictionary = snake_drag_samples[1]
		var first_time := float(first.get("time", elapsed))
		var second_time := float(second.get("time", elapsed))
		if first_time < cutoff and second_time > first_time:
			var blend := clampf((cutoff - first_time) / (second_time - first_time), 0.0, 1.0)
			snake_drag_samples[0] = {
				"position":Vector2(first.get("position", position)).lerp(Vector2(second.get("position", position)), blend),
				"time":cutoff
			}
	if not snake_drag_samples.is_empty():
		snake_drag_anchor = Vector2(snake_drag_samples[0].get("position", position))

func _snake_end_drag(position: Vector2) -> void:
	if not snake_drag_active:
		return
	_snake_drag_to(position)
	var tap_delta := position - snake_drag_origin
	if tap_delta.length() < 18.0:
		var from_center := position - Vector2(270, 500)
		if from_center.length() > 34.0:
			var tap_direction := Vector2i.ZERO
			if absf(from_center.x) > absf(from_center.y):
				tap_direction = Vector2i.RIGHT if from_center.x > 0.0 else Vector2i.LEFT
			else:
				tap_direction = Vector2i.DOWN if from_center.y > 0.0 else Vector2i.UP
			var current_direction := _snake_vector(state.get("direction", [1, 0]))
			if tap_direction.x != current_direction.x and tap_direction.y != current_direction.y:
				_set_snake_direction(tap_direction)
	snake_drag_active = false
	snake_drag_samples.clear()

func _snake_step() -> void:
	if game_id == "snake_classic":
		_snake_gb_step()
		return
	if game_id == "snake_io":
		_snakes_arena_update(1.0 / 60.0)
		return
	snake_previous_cells = state.get("snake", []).duplicate(true)
	snake_move_started = elapsed
	_snake_dispatch(snake_model.advance_step())
	_sync_snake_state()

func _spawn_snake_food() -> void:
	# Compatibility hook for evaluator scripts; normal spawning belongs to the model.
	if game_id == "snake_classic":
		snake_gb_model._spawn_food()
		_sync_snake_gb_state()
		return
	if game_id == "snake_io":
		snakes_arena_model._spawn_random_pellet()
		_sync_snakes_arena_state()
		return
	snake_model.foods.clear()
	snake_model._spawn_food()
	snake_model._refill_foods()
	snake_model.food = snake_model.foods[0] if not snake_model.foods.is_empty() else Vector2i.ZERO
	_sync_snake_state()

func _snake_update(delta: float) -> void:
	if game_id == "snake_io":
		_snakes_arena_update(delta)
		return
	snake_clock += delta
	var interval := _snake_step_interval()
	if snake_clock >= interval:
		snake_clock = 0.0
		_snake_step()

func _snake_step_interval() -> float:
	return 1.0 / 7.5 if game_id == "snake_classic" else SNAKE_STEP_INTERVAL

func _sync_snake_state() -> void:
	if game_id == "snake_classic":
		_sync_snake_gb_state()
		return
	if game_id == "snake_io":
		_sync_snakes_arena_state()
		return
	state = snake_model.snapshot()
	state["game_id"] = game_id

func _snake_dispatch(events: Array[Dictionary]) -> void:
	for event in events:
		var kind := str(event.get("kind", ""))
		match kind:
			"started":
				snake_clock = 0.0
			"turn_accepted":
				snake_button_direction = _snake_vector(event.get("direction", Vector2i.ZERO))
				snake_button_until = elapsed + 0.10
				_play_sfx(SFX_SNAKE_KEY, -11.0, 0.96 + float(posmod(snake_model.step_index, 3)) * 0.035)
				_haptic(8)
				_log_event("snake_direction", {"direction":str(snake_button_direction)})
			"turn_rejected":
				snake_reject_direction = _snake_vector(event.get("direction", Vector2i.ZERO))
				snake_reject_until = elapsed + 0.16
				if game_id != "snake_classic":
					_play_sfx(SFX_SNAKE_REJECT, -10.0)
					_haptic(10)
			"moved":
				if bool(event.get("tail_vacated", false)):
					snake_ghosts.append({"cell":event.get("tail", Vector2i.ZERO), "until":elapsed + 0.085})
			"ate":
				snake_fx_kind = "eat"
				snake_fx_started = elapsed
				snake_fx_cell = _snake_vector(event.get("at", Vector2i.ZERO))
				snake_lcd_flash_until = elapsed + 0.10
				snake_score_bump_until = elapsed + 0.24
				_snake_emit_pixels(snake_fx_cell, 16)
				snake_float_labels.append({"cell":snake_fx_cell, "started":elapsed, "text":"+2"})
				_play_sfx(SFX_SNAKE_EAT, -7.0, 1.0 + minf(0.18, float(int(event.get("score", 4)) - 4) * 0.012))
				_haptic(22)
				_flash_feedback("成长 +2", GREEN)
				_log_event("snake_food", {"score":int(event.get("score", 0))})
			"wall_hit", "self_hit":
				snake_fx_kind = "crash"
				snake_fx_started = elapsed
				snake_fx_cell = _snake_vector(event.get("to", Vector2i.ZERO))
				snake_fx_direction = _snake_vector(state.get("direction", [1, 0]))
				snake_result_ready_at = elapsed + 0.70
				_snake_emit_crash_debris(snake_fx_cell, 12)
				_play_sfx(SFX_SNAKE_CRASH, -5.5)
				_haptic(48)
				_capture("snake_%s" % kind)
			"won":
				snake_fx_kind = "win"
				snake_fx_started = elapsed
				snake_fx_cell = _snake_vector(event.get("at", Vector2i.ZERO))
				snake_result_ready_at = elapsed + 0.72
				_snake_emit_pixels(snake_fx_cell, 16)
				_play_sfx(SFX_SNAKE_WIN, -5.0)
				_haptic(70)
				_capture("snake_win")

func _snake_prune_fx() -> void:
	for index in range(snake_ghosts.size() - 1, -1, -1):
		if elapsed >= float(snake_ghosts[index].get("until", 0.0)):
			snake_ghosts.remove_at(index)
	for index in range(snake_pixels.size() - 1, -1, -1):
		if elapsed - float(snake_pixels[index].get("started", 0.0)) >= float(snake_pixels[index].get("life", 0.2)):
			snake_pixels.remove_at(index)
	for index in range(snake_float_labels.size() - 1, -1, -1):
		if elapsed - float(snake_float_labels[index].get("started", 0.0)) >= 0.72:
			snake_float_labels.remove_at(index)
	if elapsed >= snake_blink_started + 0.12:
		snake_blink_started = elapsed + 2.1 + rng.randf_range(0.0, 2.4)

func _snake_emit_crash_debris(cell: Vector2i, count: int) -> void:
	var wall_normal := Vector2.ZERO
	if cell.x < 0:
		wall_normal = Vector2.RIGHT
	elif cell.x >= snake_model.width:
		wall_normal = Vector2.LEFT
	elif cell.y < 0:
		wall_normal = Vector2.DOWN
	elif cell.y >= snake_model.height:
		wall_normal = Vector2.UP
	for index in range(count):
		var angle := TAU * float(index) / float(count) + 0.13 * float(index % 2)
		var velocity := Vector2(cos(angle), sin(angle)) * (42.0 + float(index % 4) * 13.0)
		if wall_normal != Vector2.ZERO:
			velocity = (wall_normal.rotated(lerpf(-1.10, 1.10, float(index) / maxf(1.0, float(count - 1)))) * (48.0 + float(index % 4) * 14.0))
		snake_pixels.append({
			"cell":cell, "velocity":velocity,
			"started":elapsed, "life":0.42 + float(index % 3) * 0.11,
			"size":3.0 + float(index % 2) * 1.6,
			"kind":"crash_leaf" if index % 3 == 0 else ("crash_petal" if index % 3 == 1 else "crash_dust")
		})

func _snake_emit_pixels(cell: Vector2i, count: int) -> void:
	for index in range(count):
		var angle := TAU * float(index) / float(count) + float(index % 3) * 0.19
		var particle_kind := "star" if index < 6 else ("apple" if index < 12 else "leaf")
		snake_pixels.append({
			"cell":cell, "velocity":Vector2(cos(angle), sin(angle)) * (68.0 + float(index % 4) * 13.0),
			"started":elapsed, "life":0.82 + float(index % 3) * 0.09 if particle_kind == "star" else (0.44 + float(index % 3) * 0.13),
			"size":3.0 + float(index % 2) * 1.5, "kind":particle_kind
		})

func _snake_lcd_metrics() -> Dictionary:
	return {"origin":Vector2(105.0, 152.0), "cell":22.0, "screen":Rect2(88, 132, 364, 550)}

func _snake_vector(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(value)
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO

func _snake_cell_center(cell_value: Variant) -> Vector2:
	var cell := _snake_vector(cell_value)
	var metrics := _snake_lcd_metrics()
	return Vector2(metrics.origin) + Vector2(float(cell.x) + 0.5, float(cell.y) + 0.5) * float(metrics.cell)

func _snake_impact_screen_point(cell_value: Variant) -> Vector2:
	var cell := _snake_vector(cell_value)
	var metrics := _snake_lcd_metrics()
	var origin: Vector2 = metrics.origin
	var cell_size: float = metrics.cell
	var grid_end := origin + Vector2(float(snake_model.width), float(snake_model.height)) * cell_size
	var point := origin + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size
	if cell.x < 0:
		point.x = origin.x
	elif cell.x >= snake_model.width:
		point.x = grid_end.x
	if cell.y < 0:
		point.y = origin.y
	elif cell.y >= snake_model.height:
		point.y = grid_end.y
	return point

func _snake_gb_metrics() -> Dictionary:
	return {"origin":Vector2(170.25, 184.0), "cell":13.3, "screen":Rect2(111, 157, 318, 346)}

func _snake_gb_cell_center(cell_value: Variant) -> Vector2:
	var metrics := _snake_gb_metrics()
	var cell := _snake_vector(cell_value)
	return Vector2(metrics.origin) + (Vector2(cell) + Vector2(0.5, 0.5)) * float(metrics.cell)

func _snake_gb_impact_point(cell_value: Variant) -> Vector2:
	var metrics := _snake_gb_metrics()
	var cell := _snake_vector(cell_value)
	var width := int(state.get("width", 15))
	var height := int(state.get("height", 23))
	var origin: Vector2 = metrics.origin
	var cell_size: float = metrics.cell
	var point := origin + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size
	point.x = clampf(point.x, origin.x, origin.x + float(width) * cell_size)
	point.y = clampf(point.y, origin.y, origin.y + float(height) * cell_size)
	return point

func _draw_snake_gb_experience() -> void:
	draw_texture_rect(SNAKE_GB_TEXTURE, Rect2(Vector2.ZERO, VIEW_SIZE), false)
	var crash_age := elapsed - snake_fx_started
	var shake := Vector2.ZERO
	if snake_fx_kind == "crash" and crash_age >= 0.0 and crash_age < 0.30:
		var force := (1.0 - crash_age / 0.30) * 3.5
		shake = Vector2(force if int(crash_age * 88.0) % 2 == 0 else -force, force * 0.36)
	_draw_panel(Rect2(12, 18, 90, 50), Color("9b9361", 0.86), Color("d7c792", 0.34), 14, 1)
	_draw_panel(Rect2(438, 18, 90, 50), Color("9b9361", 0.86), Color("d7c792", 0.34), 14, 1)
	_draw_center("收盒", Vector2(57, 44), 13, Color("27271d"))
	_draw_center("重开", Vector2(483, 44), 13, Color("27271d"))
	_draw_center_font(LATIN_FONT, "GB SNAKE", Vector2(270, 119), 20, Color("c9bd85"))
	_draw_snake_gb_lcd(shake)
	_draw_snake_gb_controls()
	_draw_snake_gb_fx(shake)
	var status := str(state.get("status", "playing"))
	if status != "playing" and snake_result_ready_at > 0.0 and elapsed >= snake_result_ready_at:
		_draw_snake_gb_terminal(status == "won")
	elif elapsed - snake_reset_started < 4.6:
		var prompt_alpha := clampf(1.0 - maxf(0.0, elapsed - snake_reset_started - 3.4) / 1.2, 0.0, 1.0)
		_draw_center("实体方向键转向 · 长度达到 120", Vector2(270, 758), 13, Color("d8c995", 0.82 * prompt_alpha))

func _draw_snake_gb_lcd(offset: Vector2) -> void:
	var metrics := _snake_gb_metrics()
	var screen_rect: Rect2 = metrics.screen
	var origin: Vector2 = metrics.origin
	var cell: float = metrics.cell
	var lcd_ink := Color("27321e")
	var lcd_mid := Color("536342")
	if elapsed < snake_lcd_flash_until:
		draw_rect(screen_rect.grow(-2.0), Color("e0e7af", 0.38))
	var length_scale := 1.0 + 0.16 * clampf((snake_score_bump_until - elapsed) / 0.24, 0.0, 1.0)
	_draw_text_font(NUMBER_FONT, "LEN %03d" % int(state.get("score", 4)), Vector2(122, 176) + offset, int(11 * length_scale), lcd_ink)
	_draw_center_font(NUMBER_FONT, "TARGET %03d" % int(state.get("target_length", 120)), Vector2(270, 175) + offset, 10, Color(lcd_ink, 0.88))
	var move_text := "%04d" % int(state.get("moves", 0))
	var move_width := NUMBER_FONT.get_string_size(move_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	_draw_text_font(NUMBER_FONT, move_text, Vector2(418 - move_width, 176) + offset, 10, lcd_ink)
	var board_rect := Rect2(origin + offset, Vector2(float(state.get("width", 15)), float(state.get("height", 23))) * cell)
	draw_rect(board_rect, Color(lcd_ink, 0.24), false, 1.2)
	for grid_x in range(0, int(state.get("width", 15)) + 1, 5):
		draw_line(origin + Vector2(float(grid_x) * cell, 0) + offset, origin + Vector2(float(grid_x) * cell, float(state.get("height", 23)) * cell) + offset, Color(lcd_ink, 0.055), 1.0)
	for grid_y in range(0, int(state.get("height", 23)) + 1, 5):
		draw_line(origin + Vector2(0, float(grid_y) * cell) + offset, origin + Vector2(float(state.get("width", 15)) * cell, float(grid_y) * cell) + offset, Color(lcd_ink, 0.055), 1.0)
	for y in range(int(state.get("height", 23))):
		for x in range(int(state.get("width", 15))):
			if (x + y) % 2 == 0:
				draw_rect(Rect2(origin + Vector2(x, y) * cell + offset, Vector2(cell, cell)), Color(lcd_mid, 0.035))
	for ghost in snake_ghosts:
		var ghost_cell := _snake_vector(ghost.get("cell", Vector2i.ZERO))
		var alpha := clampf((float(ghost.get("until", elapsed)) - elapsed) / 0.10, 0.0, 1.0)
		draw_rect(Rect2(origin + Vector2(ghost_cell) * cell + Vector2(2, 2) + offset, Vector2(cell - 4, cell - 4)), Color(lcd_ink, alpha * 0.18))
	var food_cell := _snake_vector(state.get("food", [11, 11]))
	var food_center := _snake_gb_cell_center(food_cell) + offset
	var food_pulse := 0.72 + sin(elapsed * 8.5) * 0.20
	draw_rect(Rect2(food_center - Vector2(4.6, 4.6), Vector2(9.2, 9.2)), Color(lcd_ink, food_pulse))
	draw_rect(Rect2(food_center - Vector2(1.4, 7.2), Vector2(2.8, 3.0)), Color(lcd_ink, food_pulse))
	var segments: Array = state.get("segments", [])
	var move_progress := clampf((elapsed - snake_move_started) / 0.18, 0.0, 1.0)
	var phosphor_progress := floorf(move_progress * 3.0) / 3.0
	for index in range(segments.size() - 1, -1, -1):
		var segment := _snake_vector(segments[index])
		var visual := Vector2(segment)
		if index < snake_previous_cells.size():
			visual = Vector2(_snake_vector(snake_previous_cells[index])).lerp(Vector2(segment), phosphor_progress)
		var rect := Rect2(origin + visual * cell + Vector2(1.5, 1.5) + offset, Vector2(cell - 3.0, cell - 3.0))
		var body_alpha := 1.0 if index == 0 else 0.90 - minf(0.18, float(index) * 0.004)
		draw_rect(rect, Color(lcd_ink, body_alpha))
		draw_line(rect.position + Vector2(1.5, 1.5), Vector2(rect.end.x - 1.5, rect.position.y + 1.5), Color("8b9c65", 0.26), 1.0)
		if index == 0:
			var direction := _snake_vector(state.get("direction", [1, 0]))
			var eye_side := Vector2(-direction.y, direction.x)
			var eye := rect.get_center() + Vector2(direction) * 2.6 + eye_side * 2.2
			draw_rect(Rect2(eye - Vector2.ONE, Vector2(2, 2)), Color("b9c58d"))
	for y in range(int(screen_rect.position.y + 3), int(screen_rect.end.y - 3), 3):
		draw_line(Vector2(screen_rect.position.x + 4, y), Vector2(screen_rect.end.x - 4, y), Color("1d2618", 0.026), 1.0)
	var glare := PackedVector2Array([screen_rect.position + Vector2(16, 7), screen_rect.position + Vector2(104, 7), screen_rect.position + Vector2(47, 114)])
	draw_colored_polygon(glare, Color("f4f1c5", 0.035))

func _draw_snake_gb_controls() -> void:
	var direction_centers := {
		Vector2i.UP:Vector2(159, 581), Vector2i.LEFT:Vector2(107, 635),
		Vector2i.RIGHT:Vector2(211, 635), Vector2i.DOWN:Vector2(159, 689)
	}
	if elapsed < snake_button_until and direction_centers.has(snake_button_direction):
		var center: Vector2 = direction_centers[snake_button_direction]
		draw_circle(center, 19.0, Color("e7d5a8", 0.16))
		draw_arc(center, 21.0, 0, TAU, 28, Color("fff3cc", 0.58), 2.0)
	if elapsed < snake_reject_until and direction_centers.has(snake_reject_direction):
		var rejected_center: Vector2 = direction_centers[snake_reject_direction]
		draw_arc(rejected_center, 22.0, 0, TAU, 28, Color("d35f51", 0.72), 2.0)
	var action_glow := 0.08 + (sin(elapsed * 2.4) + 1.0) * 0.025
	draw_circle(Vector2(410, 610), 32.0, Color("c76855", action_glow))
	draw_circle(Vector2(330, 647), 29.0, Color("c76855", action_glow * 0.72))

func _draw_snake_gb_fx(offset: Vector2) -> void:
	for pixel in snake_pixels:
		var age := elapsed - float(pixel.get("started", elapsed))
		var life := float(pixel.get("life", 0.35))
		var progress := clampf(age / life, 0.0, 1.0)
		var kind := str(pixel.get("kind", "gb_eat"))
		var base := _snake_gb_impact_point(pixel.get("cell", Vector2i.ZERO)) if kind == "gb_crash" else _snake_gb_cell_center(pixel.get("cell", Vector2i.ZERO))
		var p := base + Vector2(pixel.get("velocity", Vector2.ZERO)) * age + offset
		var size_value := float(pixel.get("size", 2.0)) * (1.0 - progress * 0.5)
		var color := Color("29351f") if kind != "gb_win" else Color("e8dfa7")
		draw_rect(Rect2(p - Vector2.ONE * size_value * 0.5, Vector2.ONE * size_value), Color(color, 1.0 - progress))
	if snake_fx_kind == "eat":
		var age := elapsed - snake_fx_started
		if age >= 0.0 and age < 0.28:
			var p := _snake_gb_cell_center(snake_fx_cell) + offset
			draw_arc(p, lerpf(5.0, 24.0, age / 0.28), 0, TAU, 24, Color("27321e", 1.0 - age / 0.28), 2.0)
	elif snake_fx_kind == "crash":
		var age := elapsed - snake_fx_started
		if age >= 0.0 and age < 0.36:
			var p := _snake_gb_impact_point(snake_fx_cell) + offset
			for ring in range(3):
				draw_arc(p, 6.0 + age * (52.0 + ring * 18.0), 0, TAU, 24, Color("27321e", (1.0 - age / 0.36) * (0.86 - ring * 0.18)), 2.0)
	for label in snake_float_labels:
		var age := elapsed - float(label.get("started", elapsed))
		var progress := clampf(age / 0.72, 0.0, 1.0)
		var p := _snake_gb_cell_center(label.get("cell", Vector2i.ZERO)) + Vector2(0, -9.0 - 18.0 * progress) + offset
		_draw_center_font(NUMBER_FONT, str(label.get("text", "+1")), p, 12, Color("27321e", 1.0 - progress))

func _draw_snake_gb_terminal(won: bool) -> void:
	var panel := Rect2(130, 291, 280, 126)
	_draw_panel(panel, Color("8e9d6d", 0.94), Color("27321e", 0.92), 3, 3)
	for y in range(int(panel.position.y + 4), int(panel.end.y - 4), 4):
		draw_line(Vector2(panel.position.x + 5, y), Vector2(panel.end.x - 5, y), Color("27321e", 0.035), 1.0)
	_draw_center_font(NUMBER_FONT, "TARGET CLEAR" if won else "GAME OVER", Vector2(270, 326), 20, Color("27321e"))
	var reason := "LENGTH 120" if won else ("SELF HIT" if str(state.get("terminal_reason", "")) == "self" else "WALL HIT")
	_draw_center_font(NUMBER_FONT, reason, Vector2(270, 354), 12, Color("3e4b30"))
	_draw_center_font(NUMBER_FONT, "LEN %03d   STEP %04d" % [int(state.get("score", 4)), int(state.get("moves", 0))], Vector2(270, 383), 11, Color("27321e"))
	_draw_center("按右上角重开", Vector2(270, 405), 10, Color("3e4b30"))

func _arena_visual_scale() -> float:
	var mass := maxf(1.0, float(state.get("mass", 38.0)))
	return clampf(0.69 - log(mass / 38.0) * 0.030, 0.61, 0.69)

func _arena_world_to_screen(world: Vector2, scale_value: float, shake := Vector2.ZERO) -> Vector2:
	var look_ahead := arena_aim_direction * 52.0
	return Vector2(270, 505) + (world - arena_camera - look_ahead) * scale_value + shake

func _arena_skin_palette(skin: int) -> Dictionary:
	match posmod(skin, 8):
		0: return {"outline":Color("02101b"), "head":Color("b8ff00"), "bands":[Color("06ddea"), Color("0879f2"), Color("00e86a"), Color("b8ff00"), Color("ffd92f"), Color("ff711a"), Color("ff3341")], "cheek":Color("ff711a"), "eye_gap":0.48}
		1: return {"outline":Color("260c18"), "head":Color("ff3341"), "bands":[Color("ff3341"), Color("ff711a"), Color("ffd92f")], "cheek":Color("ffd92f"), "eye_gap":0.44}
		2: return {"outline":Color("05142d"), "head":Color("0879f2"), "bands":[Color("0879f2"), Color("06ddea"), Color("00e86a")], "cheek":Color("b8ff00"), "eye_gap":0.52}
		3: return {"outline":Color("1e0828"), "head":Color("f33be8"), "bands":[Color("f33be8"), Color("c58bff"), Color("ff8ee8")], "cheek":Color("ffd92f"), "eye_gap":0.40}
		4: return {"outline":Color("092315"), "head":Color("00e86a"), "bands":[Color("00e86a"), Color("b8ff00"), Color("ffd92f")], "cheek":Color("06ddea"), "eye_gap":0.55}
		5: return {"outline":Color("301106"), "head":Color("ff711a"), "bands":[Color("ff711a"), Color("ffd92f"), Color("ff3341")], "cheek":Color("b8ff00"), "eye_gap":0.46}
		6: return {"outline":Color("171135"), "head":Color("c58bff"), "bands":[Color("c58bff"), Color("f33be8"), Color("0879f2")], "cheek":Color("ffb1e9"), "eye_gap":0.50}
		_: return {"outline":Color("062431"), "head":Color("06ddea"), "bands":[Color("06ddea"), Color("00e86a"), Color("fff1ce")], "cheek":Color("ff711a"), "eye_gap":0.42}

func _draw_snakes_cartoon_background() -> void:
	# The clean-room doodle field is pre-baked into one imported texture. This
	# preserves the cartoon identity while replacing ~240 per-frame Canvas calls
	# with one Web-safe draw.
	draw_texture_rect(SNAKES_DOODLE_TEXTURE, Rect2(Vector2.ZERO, VIEW_SIZE), false)

func _draw_snakes_arena_experience() -> void:
	_draw_snakes_cartoon_background()
	var shake_force := arena_camera_shake.length()
	var shake := Vector2.ZERO
	if shake_force > 0.1:
		shake = Vector2(sin(elapsed * 93.0), cos(elapsed * 77.0)) * minf(8.0, shake_force)
	var scale_value := _arena_visual_scale()
	_draw_snakes_arena_world(scale_value, shake)
	_draw_snakes_arena_fx(scale_value, shake)
	_draw_snakes_arena_hud()
	if arena_pointer_active and state.get("status", "playing") == "playing":
		var pulse := 11.0 + sin(elapsed * 9.0) * 2.0
		draw_circle(arena_pointer_screen + Vector2(2, 3), pulse + 3.0, Color("01050d", 0.38))
		draw_arc(arena_pointer_screen, pulse + 2.0, 0, TAU, 28, Color("02101b", 0.82), 3.5)
		for dot_index in range(4):
			var dot_angle := elapsed * 1.8 + float(dot_index) * TAU / 4.0
			draw_circle(arena_pointer_screen + Vector2.from_angle(dot_angle) * (pulse + 5.0), 2.8, Color("ffd92f", 0.86))
	var status := str(state.get("status", "playing"))
	if status != "playing" and arena_result_ready_at > 0.0 and elapsed >= arena_result_ready_at:
		_draw_snakes_arena_terminal()
	if elapsed - arena_reset_started < 0.65:
		var reset_progress := clampf((elapsed - arena_reset_started) / 0.65, 0.0, 1.0)
		var spawn_center := _arena_world_to_screen(_arena_player_world_position(), scale_value, shake)
		var ring_radius := lerpf(18.0, 86.0, reset_progress)
		draw_arc(spawn_center, ring_radius, 0, TAU, 48, Color("ffffff", (1.0 - reset_progress) * 0.72), 4.0)
		for star_index in range(8):
			var star_angle := float(star_index) * TAU / 8.0 + reset_progress * 1.6
			var star_position := spawn_center + Vector2.from_angle(star_angle) * ring_radius
			var star_color := Color("ffd92f") if star_index % 2 == 0 else Color("06ddea")
			draw_circle(star_position, lerpf(5.0, 1.0, reset_progress), Color(star_color, 1.0 - reset_progress))

func _draw_snakes_arena_world(scale_value: float, shake: Vector2) -> void:
	var arena_radius := float(state.get("arena_radius", 920.0)) * scale_value
	var arena_origin := _arena_world_to_screen(Vector2.ZERO, scale_value, shake)
	draw_arc(arena_origin + Vector2(4, 7), arena_radius, 0, TAU, 180, Color("01050d", 0.78), 14.0)
	draw_arc(arena_origin, arena_radius, 0, TAU, 180, Color("1c4560", 0.74), 8.0)
	for marker in range(28):
		var marker_angle := float(marker) / 28.0 * TAU + elapsed * 0.012
		var marker_center := arena_origin + Vector2.from_angle(marker_angle) * arena_radius
		draw_circle(marker_center, 2.6, Color("fff1ce", 0.34))
	var player_position := _arena_player_world_position()
	var edge_ratio := player_position.length() / maxf(1.0, float(state.get("arena_radius", 920.0)))
	if edge_ratio > 0.74:
		var danger_alpha := clampf((edge_ratio - 0.74) / 0.24, 0.0, 1.0)
		draw_arc(arena_origin, arena_radius - 2.0, 0, TAU, 180, Color("ff3341", danger_alpha * (0.68 + sin(elapsed * 7.0) * 0.14)), 10.0)
	var pellets: Array = state.get("pellets", [])
	for pellet in pellets:
		_draw_snakes_arena_pellet(pellet, scale_value, shake)
	if elapsed < arena_competition_until:
		var contest_age := maxf(0.0, 1.24 - (arena_competition_until - elapsed))
		var contest_progress := clampf(contest_age / 1.24, 0.0, 1.0)
		var contest_center := _arena_world_to_screen(arena_competition_world, scale_value, shake)
		for ring in range(3):
			var contest_radius := 18.0 + contest_progress * (48.0 + float(ring) * 15.0)
			draw_arc(contest_center, contest_radius, 0, TAU, 42, Color("ffe28a", (1.0 - contest_progress) * (0.52 - float(ring) * 0.10)), 1.6)
	var snakes: Array = state.get("snakes", [])
	for snake in snakes:
		if int(snake.get("id", -1)) != int(state.get("player_id", 0)) and bool(snake.get("alive", false)):
			_draw_snakes_arena_snake(snake, scale_value, shake, false)
	for snake in snakes:
		if int(snake.get("id", -1)) == int(state.get("player_id", 0)) and bool(snake.get("alive", false)):
			_draw_snakes_arena_snake(snake, scale_value, shake, true)
	_draw_snakes_arena_death_trace(scale_value, shake)
	_draw_snakes_arena_near_miss(scale_value, shake)
	_draw_snakes_arena_leader_pointer(scale_value, shake)

func _draw_snakes_arena_pellet(pellet: Dictionary, scale_value: float, shake: Vector2) -> void:
	var world := _arena_vector(pellet.get("position", Vector2.ZERO))
	var p := _arena_world_to_screen(world, scale_value, shake)
	if p.x < -24.0 or p.x > 564.0 or p.y < 76.0 or p.y > 944.0:
		return
	var palette_index := int(pellet.get("palette", 0))
	var colors := [Color("06ddea"), Color("ffd92f"), Color("00e86a"), Color("ff3341"), Color("f33be8")]
	var color: Color = colors[posmod(palette_index, colors.size())]
	var value := float(pellet.get("value", 1.0))
	var source := str(pellet.get("source", "ambient"))
	var radius := clampf(4.8 + sqrt(maxf(0.0, value)) * 1.55, 6.0, 10.5)
	if source == "debris":
		radius += 2.0
	elif source == "boost":
		radius -= 1.0
	var pulse := 1.0 + sin(elapsed * 4.8 + float(int(pellet.get("id", 0)) % 13)) * 0.075
	var draw_radius := radius * pulse
	draw_circle(p, draw_radius * 2.25, Color(color, 0.11))
	if source == "debris":
		var outer_star := PackedVector2Array()
		var inner_star := PackedVector2Array()
		for point_index in range(12):
			var point_angle := float(point_index) / 12.0 * TAU + elapsed * 0.34
			var point_radius := draw_radius * (1.22 if point_index % 2 == 0 else 0.62)
			outer_star.append(p + Vector2.from_angle(point_angle) * (point_radius + 2.0))
			inner_star.append(p + Vector2.from_angle(point_angle) * point_radius)
		draw_colored_polygon(outer_star, Color("02101b"))
		draw_colored_polygon(inner_star, color)
	else:
		draw_circle(p, draw_radius + 2.0, Color("02101b"))
		draw_circle(p, draw_radius, color)
	draw_circle(p - Vector2(draw_radius * 0.32, draw_radius * 0.34), maxf(1.4, draw_radius * 0.30), Color("ffffff", 0.92))

func _draw_snakes_arena_snake(snake: Dictionary, scale_value: float, shake: Vector2, player: bool) -> void:
	var segments: Array = snake.get("segments", [])
	if segments.size() < 2:
		return
	var palette := _arena_skin_palette(int(snake.get("skin", 0)))
	var outline: Color = palette.get("outline", Color("02101b"))
	var bands: Array = palette.get("bands", [Color("06ddea")])
	var points := PackedVector2Array()
	var source_count: int = segments.size()
	var sample_stride: int = maxi(1, ceili(float(source_count - 1) / 47.0))
	# Remote bots are half-step sampled: their source joints are only ~10 px
	# apart on screen while their candy body is 20–30 px wide, so every second
	# joint remains fully overlapping and visually smooth at half the draw cost.
	if not player:
		sample_stride = maxi(2, sample_stride)
	var source_index := 0
	while source_index < source_count:
		points.append(_arena_world_to_screen(_arena_vector(segments[source_index]), scale_value, shake))
		source_index += sample_stride
	if points[points.size() - 1] != _arena_world_to_screen(_arena_vector(segments[source_count - 1]), scale_value, shake):
		points.append(_arena_world_to_screen(_arena_vector(segments[source_count - 1]), scale_value, shake))
	var screen_bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		screen_bounds = screen_bounds.expand(point)
	if not screen_bounds.grow(64.0).intersects(Rect2(-64.0, 44.0, 668.0, 980.0)):
		return
	var mass := float(snake.get("mass", 30.0))
	var body_radius := clampf((17.0 + sqrt(maxf(0.0, mass)) * 0.72) * scale_value, 9.5, 14.8)
	var outline_width := maxf(3.0, body_radius * 0.30)
	var scavenging := not player and str(snake.get("state", "")) == "scavenging"
	var last_index := points.size() - 1
	var tail_segment_start := maxi(1, last_index - 5)
	var main_points := PackedVector2Array()
	for index in range(tail_segment_start + 1):
		main_points.append(points[index])
	if main_points.size() >= 2:
		var main_shadow := PackedVector2Array()
		for point in main_points:
			main_shadow.append(point + Vector2(3.2, 5.0))
		draw_polyline(main_shadow, Color("01050d", 0.52), body_radius * 2.0 + outline_width * 2.0, true)
		draw_polyline(main_points, outline, body_radius * 2.0 + outline_width * 2.0, true)
	for index in range(last_index, 0, -1):
		var from_tail := float(last_index - index)
		var taper_t := clampf(from_tail / 5.0, 0.0, 1.0)
		taper_t = taper_t * taper_t * (3.0 - 2.0 * taper_t)
		var disc_radius := body_radius * lerpf(0.30, 1.0, taper_t)
		var next_from_tail := float(last_index - (index - 1))
		var next_taper_t := clampf(next_from_tail / 5.0, 0.0, 1.0)
		next_taper_t = next_taper_t * next_taper_t * (3.0 - 2.0 * next_taper_t)
		var next_radius := body_radius * lerpf(0.30, 1.0, next_taper_t)
		var segment_radius := (disc_radius + next_radius) * 0.5
		var band_index := posmod(int(floor(float(index) / 2.15)) + int(snake.get("skin", 0)), bands.size())
		var band: Color = bands[band_index]
		# Only the last five capsules need individual tapered under-paint. The
		# rest share two continuous rails, cutting dozens of Web Canvas calls
		# without losing the rounded candy-band silhouette.
		if index >= tail_segment_start:
			var tail_outline := outline_width * clampf(segment_radius / body_radius, 0.48, 1.0)
			draw_line(points[index] + Vector2(3.2, 5.0), points[index - 1] + Vector2(3.2, 5.0), Color("01050d", 0.52), segment_radius * 2.0 + tail_outline * 2.0, true)
			draw_line(points[index], points[index - 1], outline, segment_radius * 2.0 + tail_outline * 2.0, true)
		draw_line(points[index], points[index - 1], band, segment_radius * 2.0, true)
		# A single round cap per segment restores the overlapping soft-candy bead
		# silhouette; the shared rails still avoid repeating its expensive underlay.
		draw_circle(points[index], disc_radius, band)
		if index % 3 == 0 and disc_radius > body_radius * 0.72:
			var highlight_position := points[index] - Vector2(disc_radius * 0.26, disc_radius * 0.34)
			draw_circle(highlight_position, maxf(1.2, disc_radius * 0.34), Color("ffffff", 0.12))
		if index % 6 == 0 and disc_radius > body_radius * 0.8:
			draw_circle(points[index] - Vector2(disc_radius * 0.42, disc_radius * 0.48), maxf(0.8, disc_radius * 0.10), Color("ffffff", 0.58))
	if bool(snake.get("boosting", false)):
		_draw_snakes_arena_cartoon_boost(points, body_radius, bands, int(snake.get("id", 0)))
	var head := points[0]
	var heading := float(snake.get("heading", 0.0))
	var head_radius := body_radius * (1.36 if player else 1.30)
	var steer_intensity := 0.0
	if player and elapsed < arena_steer_until:
		steer_intensity = clampf((arena_steer_until - elapsed) / 0.26, 0.0, 1.0) * clampf(absf(arena_steer_turn) / 0.045, 0.28, 1.0)
	var eat_intensity := 0.0
	if player:
		var eat_age := elapsed - arena_eat_started
		if eat_age >= 0.0 and eat_age < 0.28:
			eat_intensity = sin(clampf(eat_age / 0.28, 0.0, 1.0) * PI)
	var boost_intensity := 1.0 if bool(snake.get("boosting", false)) else 0.0
	var head_scale := Vector2(1.10 + steer_intensity * 0.13 + eat_intensity * 0.20 + boost_intensity * 0.08, 1.04 - steer_intensity * 0.09 - eat_intensity * 0.14 - boost_intensity * 0.05)
	draw_set_transform(head, heading, head_scale)
	draw_circle(Vector2(3.2, 5.0), head_radius + outline_width + 1.0, Color("01050d", 0.48))
	draw_circle(Vector2.ZERO, head_radius + outline_width, outline)
	var head_color: Color = palette.get("head", bands[0])
	draw_circle(Vector2.ZERO, head_radius, head_color)
	draw_circle(Vector2(-head_radius * 0.28, -head_radius * 0.35), head_radius * 0.52, Color("ffffff", 0.13))
	var eye_radius := head_radius * 0.32
	var eye_gap := float(palette.get("eye_gap", 0.48))
	var blink_period := 3.15 + float(posmod(int(snake.get("id", 0)) * 7, 13)) * 0.10
	var blinking := fposmod(elapsed + float(int(snake.get("id", 0))) * 0.71, blink_period) < 0.105
	var mood := str(snake.get("state", "relaxed"))
	for eye_sign in [-1.0, 1.0]:
		var asymmetry: float = 1.0 + float(eye_sign) * float(posmod(int(snake.get("id", 0)), 3) - 1) * 0.035
		var eye_center := Vector2(head_radius * 0.26, eye_sign * head_radius * eye_gap)
		if blinking:
			draw_line(eye_center - Vector2(eye_radius * 0.78, 0), eye_center + Vector2(eye_radius * 0.78, 0), outline, maxf(2.4, eye_radius * 0.28), true)
		else:
			draw_circle(eye_center, eye_radius * asymmetry + 2.2, outline)
			draw_circle(eye_center, eye_radius * asymmetry, Color("ffffff"))
			var look_offset := Vector2(eye_radius * (0.28 if boost_intensity > 0.0 else 0.20), eye_sign * eye_radius * (0.05 if mood == "scavenging" else 0.0))
			var pupil_radius := eye_radius * (0.48 if mood == "scavenging" else 0.43)
			draw_circle(eye_center + look_offset, pupil_radius, Color("02101b"))
			draw_circle(eye_center + look_offset - Vector2(pupil_radius * 0.26, pupil_radius * 0.32), maxf(0.9, pupil_radius * 0.24), Color("ffffff"))
	var cheek: Color = palette.get("cheek", Color("ff711a"))
	draw_circle(Vector2(head_radius * 0.48, head_radius * 0.73), head_radius * 0.13, Color(cheek, 0.72))
	draw_circle(Vector2(head_radius * 0.48, -head_radius * 0.73), head_radius * 0.13, Color(cheek, 0.72))
	var smile := PackedVector2Array([
		Vector2(head_radius * 0.61, -head_radius * 0.16),
		Vector2(head_radius * 0.70, 0),
		Vector2(head_radius * 0.61, head_radius * 0.16)
	])
	draw_polyline(smile, outline, maxf(1.8, head_radius * 0.10), true)
	if mood == "chasing":
		for eye_sign in [-1.0, 1.0]:
			var brow_center := Vector2(head_radius * 0.06, eye_sign * head_radius * eye_gap)
			draw_line(brow_center + Vector2(-2, eye_sign * 3), brow_center + Vector2(eye_radius * 0.9, -eye_sign * 2), outline, 2.2, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var invulnerable := float(snake.get("invulnerable", 0.0))
	if player and invulnerable > 0.0:
		var shield_alpha := clampf(invulnerable / 1.15, 0.0, 1.0)
		draw_circle(head, head_radius + 11.0, Color("ffffff", 0.08 + shield_alpha * 0.08))
		draw_arc(head, head_radius + 11.0, 0, TAU, 44, Color("ffffff", 0.42 + shield_alpha * 0.22), 2.6)
		for star_index in range(3):
			var star_angle := elapsed * 2.2 + float(star_index) * TAU / 3.0
			var star_position := head + Vector2.from_angle(star_angle) * (head_radius + 14.0)
			draw_line(star_position - Vector2(3, 0), star_position + Vector2(3, 0), Color("ffd92f", shield_alpha), 2.0, true)
			draw_line(star_position - Vector2(0, 3), star_position + Vector2(0, 3), Color("ffd92f", shield_alpha), 2.0, true)
	var label := "你" if player else ((str(snake.get("name", "BOT")) + " · 抢豆") if scavenging else str(snake.get("name", "BOT")))
	var label_color := Color("fff1ce") if player else Color("ffffff", 0.92)
	_draw_center(label, head + Vector2(0, -head_radius - 16.0), 13 if player else 12, label_color)

func _draw_snakes_arena_cartoon_boost(points: PackedVector2Array, body_radius: float, bands: Array, snake_id: int) -> void:
	if points.size() < 3:
		return
	for index in range(2, mini(points.size() - 1, 16), 3):
		var forward := (points[index - 1] - points[index + 1]).normalized()
		if forward == Vector2.ZERO:
			continue
		var side := Vector2(-forward.y, forward.x)
		var side_sign := -1.0 if posmod(index / 3 + snake_id, 2) == 0 else 1.0
		var wobble := sin(elapsed * 9.0 + float(index + snake_id)) * body_radius * 0.16
		var side_offset := side * (side_sign * (body_radius + 4.0) + wobble)
		var line_start := points[index] - forward * body_radius * 0.45 + side_offset
		var line_end := points[index] - forward * (body_radius * 2.65 + float(index % 3) * 4.0) + side_offset
		var streak_color: Color = bands[posmod(index + snake_id, bands.size())]
		draw_line(line_start, line_end, Color(streak_color, 0.72), maxf(2.4, body_radius * 0.22), true)
	var tail := points[points.size() - 1]
	for star_index in range(3):
		var angle := elapsed * 3.2 + float(star_index) * TAU / 3.0 + float(snake_id)
		var star := tail + Vector2.from_angle(angle) * (body_radius * 1.2 + float(star_index) * 4.0)
		draw_line(star - Vector2(3, 0), star + Vector2(3, 0), Color("fff1ce", 0.76), 2.0, true)
		draw_line(star - Vector2(0, 3), star + Vector2(0, 3), Color("fff1ce", 0.76), 2.0, true)


func _draw_snakes_arena_steer_wake(head: Vector2, heading: float, head_radius: float, intensity: float) -> void:
	var forward := Vector2.from_angle(heading)
	var side := Vector2(-forward.y, forward.x) * (1.0 if arena_steer_turn >= 0.0 else -1.0)
	for strand in range(2):
		var strand_offset := float(strand) * 4.0
		var ribbon := PackedVector2Array([
			head - forward * (head_radius * 0.15 + strand_offset) + side * (head_radius * 0.76),
			head - forward * (head_radius * 0.72 + strand_offset) + side * (head_radius * 0.96),
			head - forward * (head_radius * 1.34 + strand_offset) + side * (head_radius * 0.62),
			head - forward * (head_radius * 1.90 + strand_offset) + side * (head_radius * 0.24)
		])
		draw_polyline(ribbon, Color("baffef", intensity * (0.64 - float(strand) * 0.18)), 2.2 - float(strand) * 0.5, true)
	var prow := head + forward * (head_radius + 7.0)
	draw_arc(prow, 5.0 + intensity * 3.0, heading - 0.72, heading + 0.72, 12, Color("ffe28a", intensity * 0.72), 1.8)


func _draw_snakes_arena_scavenge_intent(head: Vector2, world: Vector2, scale_value: float, shake: Vector2) -> void:
	var target := Vector2.ZERO
	var nearest := INF
	var found := false
	for pellet in state.get("pellets", []):
		if str(pellet.get("source", "ambient")) != "debris":
			continue
		var pellet_world := _arena_vector(pellet.get("position", Vector2.ZERO))
		var distance_squared := world.distance_squared_to(pellet_world)
		if distance_squared < nearest:
			nearest = distance_squared
			target = pellet_world
			found = true
	if not found:
		return
	var target_screen := _arena_world_to_screen(target, scale_value, shake)
	var direction := (target_screen - head).normalized()
	if direction == Vector2.ZERO:
		return
	var visible_distance := minf(74.0, head.distance_to(target_screen))
	for marker in range(1, 4):
		var marker_position := head + direction * (16.0 + visible_distance * float(marker) / 4.0)
		var marker_alpha := 0.54 - float(marker) * 0.09
		draw_circle(marker_position, 3.2 - float(marker) * 0.35, Color("ffe28a", marker_alpha))
		draw_circle(marker_position - direction * 1.2, 1.0, Color("fff7cf", marker_alpha + 0.16))

func _draw_snakes_arena_death_trace(scale_value: float, shake: Vector2) -> void:
	var age := elapsed - arena_death_started
	if arena_death_segments.size() < 2 or age < 0.0 or age > 0.70:
		return
	var palette := _arena_skin_palette(arena_death_skin)
	var outline: Color = palette.get("outline", Color("02101b"))
	var bands: Array = palette.get("bands", [Color("06ddea")])
	var points := PackedVector2Array()
	for segment in arena_death_segments:
		points.append(_arena_world_to_screen(_arena_vector(segment), scale_value, shake))
	var body_radius := clampf((17.0 + sqrt(maxf(0.0, arena_death_mass)) * 0.72) * scale_value, 9.5, 14.8)
	for index in range(points.size() - 1, 0, -1):
		var local_progress := clampf((age - float(index) * 0.012) / 0.48, 0.0, 1.0)
		var pop := 1.0 + sin(local_progress * PI) * 0.24
		var fly_angle := float(index * 17 + arena_death_skin * 23) * 0.37
		var fly := Vector2.from_angle(fly_angle) * local_progress * body_radius * 1.8
		var disc_radius := body_radius * pop * (1.0 - local_progress * 0.82)
		var band: Color = bands[posmod(int(floor(float(index) / 2.15)) + arena_death_skin, bands.size())]
		draw_circle(points[index] + fly + Vector2(2, 3), disc_radius + 2.6, Color("01050d", (1.0 - local_progress) * 0.54))
		draw_circle(points[index] + fly, disc_radius + 2.0, Color(outline, 1.0 - local_progress))
		draw_circle(points[index] + fly, disc_radius, Color(band, 1.0 - local_progress))
		if local_progress > 0.18:
			var sparkle := points[index] + fly + Vector2.from_angle(fly_angle + 1.2) * (disc_radius + 4.0)
			draw_line(sparkle - Vector2(3, 0), sparkle + Vector2(3, 0), Color("ffffff", 1.0 - local_progress), 1.8, true)
			draw_line(sparkle - Vector2(0, 3), sparkle + Vector2(0, 3), Color("ffffff", 1.0 - local_progress), 1.8, true)
	var head := points[0]
	var squash := sin(minf(1.0, age / 0.18) * PI) * 0.24
	var head_fade := clampf(1.0 - maxf(0.0, age - 0.34) / 0.36, 0.0, 1.0)
	var head_radius := body_radius * 1.36
	draw_set_transform(head, arena_death_heading, Vector2(0.66 + squash, 1.34 - squash * 0.38))
	draw_circle(Vector2(3, 5), head_radius + 3.0, Color("01050d", head_fade * 0.48))
	draw_circle(Vector2.ZERO, head_radius + 2.6, Color(outline, head_fade))
	draw_circle(Vector2.ZERO, head_radius, Color(palette.get("head", bands[0]), head_fade))
	for eye_sign in [-1.0, 1.0]:
		var eye := Vector2(head_radius * 0.28, eye_sign * head_radius * 0.46)
		var cross_size := head_radius * 0.20
		draw_line(eye - Vector2(cross_size, cross_size), eye + Vector2(cross_size, cross_size), Color("ffffff", head_fade), 2.4, true)
		draw_line(eye - Vector2(cross_size, -cross_size), eye + Vector2(cross_size, -cross_size), Color("ffffff", head_fade), 2.4, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_snakes_arena_near_miss(scale_value: float, shake: Vector2) -> void:
	if state.get("status", "playing") != "playing":
		return
	var player_position := _arena_player_world_position()
	var nearest := INF
	for snake in state.get("snakes", []):
		if int(snake.get("id", -1)) == int(state.get("player_id", 0)) or not bool(snake.get("alive", false)):
			continue
		var segments: Array = snake.get("segments", [])
		for index in range(2, segments.size()):
			nearest = minf(nearest, player_position.distance_to(_arena_vector(segments[index])))
	if nearest >= 34.0 and nearest < 76.0:
		var danger := 1.0 - (nearest - 34.0) / 42.0
		var head := _arena_world_to_screen(player_position, scale_value, shake)
		var alert := head + Vector2(22.0, -27.0 - sin(elapsed * 12.0) * 3.0)
		draw_circle(alert + Vector2(2, 3), 12.0, Color("01050d", danger * 0.48))
		draw_circle(alert, 12.0, Color("02101b", danger))
		draw_circle(alert, 9.0, Color("ffd92f", danger))
		_draw_center_font(LATIN_FONT, "!", alert + Vector2(0, 5), 15, Color("02101b", danger))

func _draw_snakes_arena_leader_pointer(scale_value: float, shake: Vector2) -> void:
	var board: Array = state.get("leaderboard", [])
	if board.is_empty():
		return
	var leader_id := int(board[0].get("id", -1))
	if leader_id == int(state.get("player_id", 0)):
		return
	var leader_world := Vector2.ZERO
	var found := false
	for snake in state.get("snakes", []):
		if int(snake.get("id", -1)) == leader_id and bool(snake.get("alive", false)):
			leader_world = _arena_vector(snake.get("position", Vector2.ZERO))
			found = true
			break
	if not found:
		return
	var leader_screen := _arena_world_to_screen(leader_world, scale_value, shake)
	var safe := Rect2(46, 166, 448, 610)
	if safe.has_point(leader_screen):
		return
	var center := safe.get_center()
	var direction := (leader_screen - center).normalized()
	if direction == Vector2.ZERO:
		return
	var distance_x := (safe.size.x * 0.5 - 12.0) / maxf(0.001, absf(direction.x))
	var distance_y := (safe.size.y * 0.5 - 12.0) / maxf(0.001, absf(direction.y))
	var pointer := center + direction * minf(distance_x, distance_y)
	var side := Vector2(-direction.y, direction.x)
	var arrow := PackedVector2Array([pointer + direction * 12.0, pointer - direction * 9.0 + side * 9.0, pointer - direction * 9.0 - side * 9.0])
	draw_colored_polygon(arrow, Color("02101b"))
	var inner_arrow := PackedVector2Array([pointer + direction * 8.0, pointer - direction * 5.0 + side * 5.0, pointer - direction * 5.0 - side * 5.0])
	draw_colored_polygon(inner_arrow, Color("ffd92f"))
	for crown_dot in [-1.0, 0.0, 1.0]:
		draw_circle(pointer - direction * 15.0 + side * crown_dot * 5.0, 2.4, Color("ffd92f"))
	_draw_center("第一名", pointer - direction * 25.0, 9, Color("fff1ce"))

func _draw_snakes_arena_fx(scale_value: float, shake: Vector2) -> void:
	for fx in arena_fx:
		var age := elapsed - float(fx.get("started", elapsed))
		var life := float(fx.get("life", 0.4))
		var progress := clampf(age / life, 0.0, 1.0)
		var world := _arena_vector(fx.get("world", Vector2.ZERO)) + Vector2(fx.get("velocity", Vector2.ZERO)) * age
		var p := _arena_world_to_screen(world, scale_value, shake)
		var color: Color = fx.get("color", Color("ffe28a"))
		var size_value := float(fx.get("size", 3.0)) * (1.0 - progress * 0.52)
		var kind := str(fx.get("kind", "eat"))
		if kind == "death" or kind == "debris" or kind == "eat":
			var star_points := PackedVector2Array()
			var point_count := 10 if kind == "death" else 8
			for point_index in range(point_count):
				var point_angle := float(point_index) / float(point_count) * TAU + age * 2.6
				var point_radius := size_value * (1.65 if point_index % 2 == 0 else 0.58)
				star_points.append(p + Vector2.from_angle(point_angle) * point_radius)
			draw_colored_polygon(star_points, Color("02101b", 1.0 - progress))
			var inner_size := maxf(1.0, size_value * 0.58)
			draw_circle(p, inner_size, Color(color, 1.0 - progress))
			if kind == "eat":
				draw_circle(p - Vector2(inner_size * 0.28, inner_size * 0.34), maxf(0.7, inner_size * 0.28), Color("ffffff", 1.0 - progress))
		else:
			draw_circle(p + Vector2(1.5, 2.2), size_value + 2.0, Color("01050d", (1.0 - progress) * 0.48))
			draw_circle(p, size_value + 1.6, Color("02101b", 1.0 - progress))
			draw_circle(p, size_value, Color(color, 1.0 - progress))
	for label in arena_float_labels:
		var age := elapsed - float(label.get("started", elapsed))
		var progress := clampf(age / 0.86, 0.0, 1.0)
		var p := _arena_world_to_screen(_arena_vector(label.get("world", Vector2.ZERO)), scale_value, shake) + Vector2(0, -48.0 - progress * 34.0)
		var label_color: Color = label.get("color", Color("fff2b8"))
		_draw_center(str(label.get("text", "+1")), p + Vector2(2, 3), 15, Color("02101b", (1.0 - progress) * 0.88))
		_draw_center(str(label.get("text", "+1")), p, 15, Color(label_color, 1.0 - progress))

func _draw_snakes_cartoon_sticker(rect: Rect2, fill: Color, radius: int = 18) -> void:
	_draw_panel(Rect2(rect.position + Vector2(3, 5), rect.size), Color("01050d", 0.58), Color.TRANSPARENT, radius, 0)
	_draw_panel(rect, fill, Color("02101b"), radius, 4)
	draw_line(rect.position + Vector2(radius, 7), Vector2(rect.end.x - radius, rect.position.y + 7), Color("ffffff", 0.34), 2.0, true)

func _draw_snakes_arena_hud() -> void:
	_draw_snakes_cartoon_sticker(Rect2(12, 18, 88, 54), Color("fff1ce"), 18)
	_draw_snakes_cartoon_sticker(Rect2(440, 18, 88, 54), Color("ffd92f"), 18)
	_draw_snakes_cartoon_sticker(Rect2(176, 17, 188, 62), Color("06ddea"), 22)
	_draw_center_font(LATIN_FONT, "SNAKES", Vector2(270, 40), 19, Color("02101b"))
	_draw_center("体量 %.1f" % float(state.get("mass", 0.0)), Vector2(270, 65), 13, Color("02101b"))
	var rank := int(state.get("rank", -1))
	var display_rank: int = rank if rank > 0 else maxi(1, arena_rank_previous)
	var rank_scale := 1.0 + 0.18 * clampf((arena_rank_bump_until - elapsed) / 0.58, 0.0, 1.0)
	_draw_snakes_cartoon_sticker(Rect2(18, 94, 112, 62), Color("ffd92f"), 19)
	_draw_text("我的位次", Vector2(32, 116), 10, Color("3b2605"))
	_draw_center_font(NUMBER_FONT, "#%d" % display_rank, Vector2(76, 146), int(23 * rank_scale), Color("02101b"))
	var board: Array = state.get("leaderboard", [])
	var display_entries: Array[Dictionary] = []
	var player_id := int(state.get("player_id", 0))
	var player_in_top := false
	for index in range(mini(3, board.size())):
		var top_entry: Dictionary = board[index]
		display_entries.append(top_entry)
		if int(top_entry.get("id", -1)) == player_id:
			player_in_top = true
	if not player_in_top:
		for entry_value in board:
			var candidate: Dictionary = entry_value
			if int(candidate.get("id", -1)) == player_id:
				display_entries.append(candidate)
				break
	var board_height := 42.0 + float(display_entries.size()) * 28.0
	_draw_snakes_cartoon_sticker(Rect2(354, 94, 168, board_height), Color("fff1ce"), 18)
	_draw_text("排行榜", Vector2(372, 119), 13, Color("02101b"))
	for index in range(display_entries.size()):
		var entry: Dictionary = display_entries[index]
		var is_player := int(entry.get("id", -1)) == player_id
		var entry_rank := 1
		for board_index in range(board.size()):
			if int(board[board_index].get("id", -1)) == int(entry.get("id", -1)):
				entry_rank = board_index + 1
				break
		var row_y := 145.0 + float(index) * 28.0
		if is_player:
			_draw_panel(Rect2(365, row_y - 16, 146, 24), Color("06ddea", 0.32), Color("02101b", 0.20), 10, 1)
		var entry_palette := _arena_skin_palette(int(entry.get("skin", 0)))
		var avatar_color: Color = entry_palette.get("head", Color("06ddea"))
		draw_circle(Vector2(378, row_y - 4), 7.0, Color("02101b"))
		draw_circle(Vector2(378, row_y - 4), 5.0, avatar_color)
		draw_circle(Vector2(379.5, row_y - 6.0), 1.2, Color("ffffff"))
		_draw_text("%d" % entry_rank, Vector2(390, row_y), 11, Color("5a3c0b"))
		_draw_text("你" if is_player else str(entry.get("name", "BOT")), Vector2(407, row_y), 12, Color("02101b"))
		var mass_text := "%02d" % roundi(float(entry.get("mass", 0.0)))
		var mass_width := NUMBER_FONT.get_string_size(mass_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		_draw_text_font(NUMBER_FONT, mass_text, Vector2(503 - mass_width, row_y), 11, Color("02101b"))
	if elapsed < arena_leader_change_until and not arena_leader_change_name.is_empty():
		var change_alpha := clampf((arena_leader_change_until - elapsed) / 1.18, 0.0, 1.0)
		_draw_snakes_cartoon_sticker(Rect2(172, 164, 196, 38), Color("ffd92f", change_alpha), 17)
		_draw_center("新的第一名 · %s" % arena_leader_change_name, Vector2(270, 190), 11, Color("02101b", change_alpha))
	if state.get("status", "playing") == "playing":
		_draw_snakes_arena_radar()
		_draw_snakes_arena_boost()
		if not arena_tutorial_dismissed:
			_draw_snakes_cartoon_sticker(Rect2(122, 888, 296, 42), Color("fff1ce", 0.96), 18)
			_draw_center("指向任意方向 · 按住右下冲刺", Vector2(270, 916), 11, Color("02101b"))

func _draw_snakes_arena_radar() -> void:
	var center := Vector2(68, 870)
	var radius := 39.0
	draw_circle(center + Vector2(3, 5), radius + 5.0, Color("01050d", 0.56))
	draw_circle(center, radius + 5.0, Color("02101b"))
	draw_circle(center, radius, Color("fff1ce"))
	draw_circle(center, radius - 5.0, Color("0b2232"))
	draw_arc(center, radius - 5.0, 0, TAU, 42, Color("ffffff", 0.20), 2.0)
	var arena_radius := maxf(1.0, float(state.get("arena_radius", 920.0)))
	var board: Array = state.get("leaderboard", [])
	var leader_id := int(board[0].get("id", -1)) if not board.is_empty() else -1
	var player_id := int(state.get("player_id", 0))
	for snake in state.get("snakes", []):
		if not bool(snake.get("alive", false)):
			continue
		var snake_id := int(snake.get("id", -1))
		if snake_id != player_id and snake_id != leader_id:
			continue
		var relative := _arena_vector(snake.get("position", Vector2.ZERO)) / arena_radius * radius
		var palette := _arena_skin_palette(int(snake.get("skin", 0)))
		var dot_color: Color = palette.get("head", Color("06ddea"))
		var dot_radius := 4.8 if snake_id == player_id else 3.6
		draw_circle(center + relative, dot_radius + 1.8, Color("02101b"))
		draw_circle(center + relative, dot_radius, dot_color)
		if snake_id == leader_id and snake_id != player_id:
			draw_line(center + relative + Vector2(-4, -7), center + relative + Vector2(0, -11), Color("ffd92f"), 2.0, true)
			draw_line(center + relative + Vector2(0, -11), center + relative + Vector2(4, -7), Color("ffd92f"), 2.0, true)

func _draw_snakes_arena_boost() -> void:
	var pressed_offset := Vector2(0, 5) if arena_boost_active else Vector2.ZERO
	var center := Vector2(472, 874) + pressed_offset
	var mass := float(state.get("mass", 0.0))
	var reserve := clampf((mass - 22.0) / 28.0, 0.0, 1.0)
	var pulse := 1.0 + (sin(elapsed * 13.0) * 0.035 if arena_boost_active else 0.0)
	draw_circle(center + Vector2(3, 6), 45.0 * pulse, Color("01050d", 0.58))
	draw_circle(center, 45.0 * pulse, Color("02101b"))
	draw_circle(center, 39.0 * pulse, Color("06ddea") if reserve > 0.04 else Color("ff3341"))
	draw_circle(center - Vector2(8, 11), 13.0, Color("ffffff", 0.18))
	for segment in range(8):
		var start_angle := -PI * 0.5 + float(segment) * TAU / 8.0 + 0.05
		var lit := float(segment + 1) / 8.0 <= reserve + 0.001
		draw_arc(center, 43.0, start_angle, start_angle + TAU / 8.0 - 0.10, 8, Color("ffd92f") if lit else Color("3a2941"), 5.5)
	if arena_boost_active:
		draw_arc(center, 31.0 + sin(elapsed * 16.0) * 2.0, 0, TAU, 40, Color("ffffff", 0.72), 3.0)
	_draw_center("冲刺", center + Vector2(0, 5), 15, Color("02101b"))

func _draw_snakes_arena_terminal() -> void:
	var reason_key := str(state.get("terminal_reason", "body"))
	var reason := "撞到竞技场边缘" if reason_key == "boundary" else ("和游蛇撞了个满怀" if reason_key == "head" else "撞到其他游蛇")
	var panel := Rect2(72, 752, 396, 154)
	_draw_snakes_cartoon_sticker(panel, Color("fff1ce"), 26)
	_draw_center("撞到了！", Vector2(270, 791), 27, Color("ff3341"))
	_draw_center(reason, Vector2(270, 821), 13, Color("02101b"))
	var final_rank := int(state.get("rank", -1))
	if final_rank <= 0:
		final_rank = maxi(1, arena_rank_previous)
	_draw_center("体量 %.1f  ·  最终位次 #%d" % [float(state.get("mass", 0.0)), final_rank], Vector2(270, 852), 15, Color("3b2605"))
	_draw_center("点右上角“再来”回到蛇群", Vector2(270, 883), 11, Color("534027"))

func _draw_snake_classic_experience() -> void:
	var garden_drift := Vector2(sin(elapsed * 0.34), cos(elapsed * 0.27)) * 1.6
	draw_texture_rect(SNAKE_GARDEN_TEXTURE, Rect2(garden_drift - Vector2(2, 2), VIEW_SIZE + Vector2(4, 4)), false, Color(0.94, 0.94, 0.94, 1.0))
	var metrics := _snake_lcd_metrics()
	var screen_rect: Rect2 = metrics.screen
	var shake := Vector2.ZERO
	if snake_fx_kind == "crash":
		var crash_age := elapsed - snake_fx_started
		if crash_age >= 0.0 and crash_age < 0.24:
			var shake_strength := lerpf(6.0, 0.0, crash_age / 0.24)
			shake = Vector2(shake_strength if int(crash_age * 90.0) % 2 == 0 else -shake_strength, shake_strength * 0.45 if int(crash_age * 70.0) % 2 == 0 else -shake_strength * 0.45)
	elif snake_fx_kind == "eat" and elapsed - snake_fx_started < 0.12:
		shake = Vector2(0, -2.0)
	_draw_panel(Rect2(screen_rect.position + shake + Vector2(0, 12), screen_rect.size), Color("16324c", 0.11), Color.TRANSPARENT, 30, 0)
	_draw_panel(Rect2(screen_rect.position + shake + Vector2(0, 6), screen_rect.size), Color("704733", 0.055), Color.TRANSPARENT, 30, 0)
	_draw_panel(Rect2(screen_rect.position + shake, screen_rect.size), Color("ffeab0", 0.88), Color("16324c", 0.80), 28, 4)
	draw_line(screen_rect.position + Vector2(28, 9) + shake, Vector2(screen_rect.end.x - 28, screen_rect.position.y + 9) + shake, Color("fff8dc", 0.48), 2.0)
	draw_line(Vector2(screen_rect.position.x + 20, screen_rect.end.y - 8) + shake, screen_rect.end - Vector2(20, 8) + shake, Color("704733", 0.13), 2.0)
	_draw_snake_lcd_hud(shake)
	_draw_snake_lcd_board(shake)
	_draw_snake_lcd_fx(shake)
	if snake_reset_started > 0.0:
		var reset_progress := clampf((elapsed - snake_reset_started) / 0.32, 0.0, 1.0)
		if reset_progress < 1.0:
			draw_circle(screen_rect.get_center(), lerpf(320.0, 0.0, reset_progress), Color("fff8dc", 0.48 * (1.0 - reset_progress)))
		else:
			snake_reset_started = -10.0
	_draw_snake_modern_chrome()
	var status := str(state.get("status", "playing"))
	if status != "playing" and snake_result_ready_at > 0.0 and elapsed >= snake_result_ready_at:
		_draw_snake_terminal(status == "won")

func _draw_snake_lcd_hud(offset: Vector2) -> void:
	var score_scale := 1.0 + 0.18 * clampf((snake_score_bump_until - elapsed) / 0.24, 0.0, 1.0)
	_draw_text("长度", Vector2(108, 119) + offset, 11, Color("5b7350"))
	_draw_text_font(NUMBER_FONT, "%02d" % int(state.get("score", 4)), Vector2(150, 120) + offset, int(21 * score_scale), Color("16324c"))
	_draw_text("步数", Vector2(352, 119) + offset, 11, Color("5b7350"))
	_draw_text_font(NUMBER_FONT, "%02d" % int(state.get("moves", 0)), Vector2(391, 120) + offset, 21, Color("16324c"))

func _draw_snake_lcd_board(offset: Vector2) -> void:
	var metrics := _snake_lcd_metrics()
	var origin: Vector2 = metrics.origin
	var cell: float = metrics.cell
	for y in range(23):
		for x in range(15):
			if (x + y) % 2 == 0:
				draw_rect(Rect2(origin + Vector2(x, y) * cell + offset, Vector2(cell, cell)), Color("ffc578", 0.17))
	for x in range(0, 16, 2):
		draw_line(origin + Vector2(x * cell, 0) + offset, origin + Vector2(x * cell, 23 * cell) + offset, Color("c98753", 0.11), 1.0)
	for y in range(0, 24, 2):
		draw_line(origin + Vector2(0, y * cell) + offset, origin + Vector2(15 * cell, y * cell) + offset, Color("c98753", 0.11), 1.0)
	for ghost in snake_ghosts:
		var ghost_cell := _snake_vector(ghost.get("cell", Vector2i.ZERO))
		var alpha := clampf((float(ghost.get("until", elapsed)) - elapsed) / 0.085, 0.0, 1.0)
		draw_circle(origin + (Vector2(ghost_cell) + Vector2(0.5, 0.5)) * cell + offset, cell * 0.40, Color("498252", alpha * 0.16))
	var foods: Array = state.get("foods", [state.get("food", [11, 11])])
	for food_value in foods:
		var food_cell := _snake_vector(food_value)
		var food_center := origin + (Vector2(food_cell) + Vector2(0.5, 0.5)) * cell + offset
		_draw_snake_apple(food_center, food_cell)
	var snake: Array = state.get("snake", [])
	var move_progress := clampf((elapsed - snake_move_started) / maxf(0.001, _snake_step_interval()), 0.0, 1.0)
	var smooth_progress := lerpf(move_progress, move_progress * move_progress * (3.0 - 2.0 * move_progress), 0.65)
	var centers: Array[Vector2] = []
	for index in range(snake.size()):
		var segment := _snake_vector(snake[index])
		var visual_cell := Vector2(segment)
		if index < snake_previous_cells.size():
			visual_cell = Vector2(_snake_vector(snake_previous_cells[index])).lerp(Vector2(segment), smooth_progress)
		centers.append(origin + (visual_cell + Vector2(0.5, 0.5)) * cell + offset)
	_draw_snake_continuous_body(centers)
	for index in range(snake.size() - 1, -1, -1):
		var segment := _snake_vector(snake[index])
		var segment_direction := _snake_vector(state.get("direction", [1, 0]))
		if index < snake.size() - 1:
			segment_direction = segment - _snake_vector(snake[index + 1])
		_draw_snake_modern_segment(centers[index], index, snake.size(), segment_direction)

func _draw_snake_continuous_body(centers: Array[Vector2]) -> void:
	if centers.size() < 2:
		return
	var body_points := PackedVector2Array()
	for center in centers:
		body_points.append(center)
	var shadow_points := PackedVector2Array()
	for center in centers:
		shadow_points.append(center + Vector2(4.5, 5.5))
	draw_polyline(shadow_points, Color(0, 0, 0, 0.15), 20.0, true)
	draw_polyline(body_points, Color("498252"), 19.0, true)
	draw_polyline(body_points, Color("32b744"), 13.0, true)
	var tail_center: Vector2 = centers.back()
	var before_tail: Vector2 = centers[centers.size() - 2]
	var back: Vector2 = (tail_center - before_tail).normalized()
	if back == Vector2.ZERO:
		back = Vector2.LEFT
	var side: Vector2 = Vector2(-back.y, back.x)
	var tail_base: Vector2 = tail_center + back * 2.0
	var tail_tip: Vector2 = tail_center + back * 16.0
	var shadow_tail := PackedVector2Array([
		tail_base + side * 8.0 + Vector2(4.5, 5.5),
		tail_tip + Vector2(4.5, 5.5),
		tail_base - side * 8.0 + Vector2(4.5, 5.5)
	])
	draw_colored_polygon(shadow_tail, Color(0, 0, 0, 0.15))
	draw_colored_polygon(PackedVector2Array([tail_base + side * 8.0, tail_tip, tail_base - side * 8.0]), Color("498252"))
	draw_colored_polygon(PackedVector2Array([tail_base + side * 5.0 - Vector2(1.5, 1.5), tail_tip - back * 2.5, tail_base - side * 5.0 - Vector2(1.5, 1.5)]), Color("32b744"))

func _draw_snake_modern_segment(center: Vector2, index: int, count: int, direction: Vector2i) -> void:
	var head := index == 0
	var tail_factor := 1.0
	if count > 2 and index >= count - 2:
		tail_factor = 0.72 if index == count - 1 else 0.88
	var radius := (14.2 if head else 12.8) * tail_factor
	var eat_age := elapsed - snake_fx_started
	var stretch := Vector2.ONE
	if head and snake_fx_kind == "eat" and eat_age >= 0.0 and eat_age < 0.16:
		var squash := sin(eat_age / 0.16 * PI) * 0.18
		stretch = Vector2(1.0 + squash, 1.0 - squash)
	elif head and snake_fx_kind == "crash" and eat_age >= 0.0 and eat_age < 0.34:
		var hit_curve := sin(clampf(eat_age / 0.34, 0.0, 1.0) * PI)
		stretch = Vector2(0.74 + hit_curve * 0.18, 1.22 - hit_curve * 0.14)
		var recoil_direction := -Vector2(snake_fx_direction)
		if recoil_direction == Vector2.ZERO:
			recoil_direction = (_snake_cell_center(_snake_vector(state.get("snake", [[7, 11]])[0])) - _snake_impact_screen_point(snake_fx_cell)).normalized()
		center += recoil_direction * sin(clampf(eat_age / 0.34, 0.0, 1.0) * PI) * 5.0
	var angle := Vector2(direction).angle()
	if direction == Vector2i.ZERO:
		angle = 0.0
	var oriented_stretch := stretch * (Vector2(1.18, 0.96) if not head else Vector2(1.08, 1.0))
	draw_set_transform(center, angle, oriented_stretch)
	draw_circle(Vector2.ZERO, radius, Color("3d994a") if head else Color("498252"))
	draw_circle(Vector2(-1.5, -2.0), radius * 0.80, Color("76ca3e") if head else Color("32b744"))
	if not head:
		draw_circle(Vector2(-radius * 0.18, -radius * 0.18), maxf(1.5, radius * 0.18), Color("76c93d", 0.92))
		draw_circle(Vector2(radius * 0.28, radius * 0.18), maxf(1.1, radius * 0.11), Color("b0dd58", 0.72))
	else:
		_draw_snake_face(Vector2.ZERO, direction, radius)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_snake_face(center: Vector2, direction: Vector2i, radius: float) -> void:
	var forward := Vector2(direction)
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	var side := Vector2(-forward.y, forward.x)
	var eye_forward := forward * radius * 0.26
	var blink := elapsed >= snake_blink_started and elapsed < snake_blink_started + 0.12
	var crash_age := elapsed - snake_fx_started
	var eyes_squeezed := snake_fx_kind == "crash" and crash_age >= 0.0 and crash_age < 0.42
	var food_look := forward * 1.8
	var head_cell := _snake_vector(state.get("snake", [[7, 11]])[0])
	var foods: Array = state.get("foods", [])
	if not foods.is_empty():
		var nearest := Vector2(_snake_vector(foods[0]) - head_cell)
		if nearest.length() > 0.01:
			food_look = nearest.normalized() * 1.8
	for sign_value in [-1.0, 1.0]:
		var eye_center: Vector2 = center + eye_forward + side * radius * 0.36 * sign_value
		if blink or eyes_squeezed:
			var eye_tilt: Vector2 = forward * (1.5 * sign_value if eyes_squeezed else 0.0)
			draw_line(eye_center - side * 3.2 - eye_tilt, eye_center + side * 3.2 + eye_tilt, Color("16324c"), 1.8)
		else:
			draw_circle(eye_center, radius * 0.26, Color("fffdf4"))
			draw_circle(eye_center + food_look, radius * 0.12, Color("16324c"))
	var nose_center := center + forward * radius * 0.70
	draw_circle(nose_center + side * 2.8, 1.2, Color("245b39"))
	draw_circle(nose_center - side * 2.8, 1.2, Color("245b39"))

func _draw_snake_apple(center: Vector2, cell_value: Vector2i) -> void:
	var breathe := 1.0 + sin(elapsed * 7.2 + float(cell_value.x * 3 + cell_value.y)) * 0.065
	draw_set_transform(center, 0.0, Vector2(breathe, breathe))
	draw_circle(Vector2(3.5, 6.5), 11.8, Color(0, 0, 0, 0.13))
	var apple_shape := PackedVector2Array([
		Vector2(0, -6.5), Vector2(-5.0, -10.0), Vector2(-10.0, -7.0), Vector2(-12.5, -1.0),
		Vector2(-10.5, 6.0), Vector2(-4.0, 11.5), Vector2(0, 13.0), Vector2(4.0, 11.5),
		Vector2(10.5, 6.0), Vector2(12.5, -1.0), Vector2(10.0, -7.0), Vector2(5.0, -10.0)
	])
	draw_colored_polygon(apple_shape, Color("e74449"))
	draw_circle(Vector2(-4.0, -1.5), 8.3, Color("ff5f58"))
	draw_circle(Vector2(4.0, -1.5), 8.3, Color("f45150"))
	draw_arc(Vector2(0, 4.0), 8.6, 0.20, PI - 0.20, 18, Color("b52f3a", 0.40), 2.0)
	draw_circle(Vector2(-5.8, -4.2), 2.8, Color("ffd0ae", 0.90))
	draw_circle(Vector2(-4.8, -5.1), 1.0, Color("fff8dc", 0.84))
	draw_line(Vector2(0, -7), Vector2(1.8, -14), Color("704733"), 2.5)
	var leaf_wobble := sin(elapsed * 5.0 + float(cell_value.x)) * 2.0
	var leaf_points := PackedVector2Array([Vector2(1, -11), Vector2(12, -14 + leaf_wobble), Vector2(6, -5)])
	draw_colored_polygon(leaf_points, Color("76c93d"))
	draw_line(Vector2(3, -10), Vector2(9, -11 + leaf_wobble * 0.45), Color("3d994a", 0.72), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_snake_modern_chrome() -> void:
	_draw_panel(Rect2(18, 20, 96, 48), Color("fff8dc", 0.84), Color("16324c", 0.22), 18, 1)
	_draw_panel(Rect2(426, 20, 96, 48), Color("fff8dc", 0.84), Color("16324c", 0.22), 18, 1)
	_draw_center("收盒", Vector2(66, 44), 14, Color("16324c"))
	_draw_center("重开", Vector2(474, 44), 14, Color("16324c"))
	_draw_center_font(DISPLAY_FONT, "Garden Snake", Vector2(270, 45), 25, Color("16324c"))
	var terminal_visible := str(state.get("status", "playing")) != "playing" and snake_result_ready_at > 0.0 and elapsed >= snake_result_ready_at
	if terminal_visible:
		return
	var tutorial_alpha := 1.0
	if snake_tutorial_dismissed:
		tutorial_alpha = 1.0 - clampf((elapsed - snake_tutorial_fade_started) / 0.42, 0.0, 1.0)
	if tutorial_alpha > 0.01:
		_draw_center("按住也能连续滑 · 键盘方向键同样可用", Vector2(270, 752), 12, Color("5b7350", 0.86 * tutorial_alpha))
	_draw_panel(Rect2(117, 792, 306, 52), Color("fff8dc", 0.72), Color("76c93d", 0.40), 20, 1)
	_draw_center("吃苹果长大 · 别碰墙，也别碰自己", Vector2(270, 821), 14, Color("16324c"))

func _draw_snake_lcd_fx(offset: Vector2) -> void:
	for pixel in snake_pixels:
		var age := elapsed - float(pixel.get("started", elapsed))
		var life := float(pixel.get("life", 0.2))
		var progress := clampf(age / life, 0.0, 1.0)
		var particle_cell := _snake_vector(pixel.get("cell", Vector2i.ZERO))
		var particle_origin := _snake_impact_screen_point(particle_cell) if snake_fx_kind == "crash" else _snake_cell_center(particle_cell)
		var position := particle_origin + Vector2(pixel.get("velocity", Vector2.ZERO)) * age + offset
		var pixel_size := float(pixel.get("size", 3.0))
		var kind := str(pixel.get("kind", "apple"))
		if kind == "star":
			var star_outline := Color("e8893e", (1.0 - progress) * 0.92)
			var star_color := Color("ffd05f", 1.0 - progress)
			draw_line(position - Vector2(pixel_size + 0.8, 0), position + Vector2(pixel_size + 0.8, 0), star_outline, 3.0)
			draw_line(position - Vector2(0, pixel_size + 0.8), position + Vector2(0, pixel_size + 0.8), star_outline, 3.0)
			draw_line(position - Vector2(pixel_size, 0), position + Vector2(pixel_size, 0), star_color, 1.6)
			draw_line(position - Vector2(0, pixel_size), position + Vector2(0, pixel_size), star_color, 1.6)
			draw_circle(position, 1.8, Color("fff3b0", 1.0 - progress))
		elif kind == "leaf" or kind == "crash_leaf":
			draw_colored_polygon(PackedVector2Array([position + Vector2(-pixel_size, 0), position + Vector2(pixel_size, -pixel_size * 0.65), position + Vector2(pixel_size * 0.3, pixel_size)]), Color("76c93d", 1.0 - progress))
		elif kind == "crash_petal":
			draw_colored_polygon(PackedVector2Array([position + Vector2(-pixel_size, -pixel_size * 0.3), position + Vector2(pixel_size, -pixel_size), position + Vector2(pixel_size * 0.55, pixel_size)]), Color("ff5f58", 1.0 - progress))
		elif kind == "crash_dust":
			draw_circle(position, pixel_size * (1.0 - progress * 0.62), Color("c98753", (1.0 - progress) * 0.72))
		else:
			draw_circle(position, pixel_size * (1.0 - progress * 0.55), Color("ff5f58", 1.0 - progress))
	if snake_fx_kind == "eat":
		var eat_age := elapsed - snake_fx_started
		if eat_age >= 0.0 and eat_age < 0.34:
			var eat_progress := eat_age / 0.34
			var eat_center := _snake_cell_center(snake_fx_cell) + offset
			draw_circle(eat_center, lerpf(20.0, 2.0, eat_progress), Color("fff3b0", (1.0 - eat_progress) * 0.72))
			draw_arc(eat_center, lerpf(8.0, 42.0, eat_progress), 0, TAU, 40, Color("ff9d6e", (1.0 - eat_progress) * 0.82), 3.0)
	for label in snake_float_labels:
		var age := elapsed - float(label.get("started", elapsed))
		var progress := clampf(age / 0.72, 0.0, 1.0)
		var position := _snake_cell_center(label.get("cell", Vector2i.ZERO)) + offset + Vector2(0, -18.0 - progress * 32.0)
		_draw_center(str(label.get("text", "+2")), position, 18, Color("16324c", 1.0 - progress))
	if snake_fx_kind == "crash":
		var age := elapsed - snake_fx_started
		if age >= 0.0 and age < 0.32:
			var p := _snake_impact_screen_point(snake_fx_cell) + offset
			var progress := age / 0.32
			draw_circle(p, lerpf(26.0, 2.0, progress), Color("fff3b0", (1.0 - progress) * 0.94))
			for ring in range(3):
				draw_arc(p, 12.0 + progress * (42.0 + ring * 12.0), 0, TAU, 40, Color("ff5f58", (1.0 - progress) * (0.82 - ring * 0.16)), 4.0 - ring)

func _draw_snake_terminal(won: bool) -> void:
	var panel := Rect2(72, 704, 396, 174)
	_draw_panel(Rect2(panel.position + Vector2(0, 7), panel.size), Color("704733", 0.11), Color.TRANSPARENT, 30, 0)
	_draw_panel(panel, Color("fff8dc", 0.965), Color("16324c", 0.74), 30, 3)
	for leaf_side in [-1.0, 1.0]:
		var leaf_center := Vector2(270 + leaf_side * 162.0, 722)
		draw_colored_polygon(PackedVector2Array([leaf_center + Vector2(-8 * leaf_side, 5), leaf_center + Vector2(10 * leaf_side, -7), leaf_center + Vector2(6 * leaf_side, 10)]), Color("76c93d", 0.58))
	_draw_center("花园探险完成" if won else "哎呀，撞到了", Vector2(270, 741), 26, Color("3d994a") if won else Color("e34c50"))
	_draw_center("目标达成" if won else ("碰到了自己的身体" if str(state.get("terminal_reason", "")) == "self" else "碰到了花园边界"), Vector2(270, 782), 14, Color("5b7350"))
	_draw_center("长度 %d  ·  %d 步" % [int(state.get("score", 4)), int(state.get("moves", 0))], Vector2(270, 821), 18, Color("16324c"))
	_draw_center("点右上角“重开”再来一局", Vector2(270, 854), 12, Color("5b7350"))

func _draw_snake() -> void:
	var origin := Vector2(70, 246)
	var cell := 20.0
	var width := int(state["width"])
	var height := int(state["height"])
	var classic := game_id == "snake_classic"
	var accent := Color("9ab36f") if classic else Color("66b3ff")
	_draw_section_heading("掌机液晶" if classic else "无界竞技场", "方向键控制 · 吃到能量成长", accent)
	if classic:
		_draw_panel(Rect2(42, 226, 456, 514), Color("45483d"), Color("6f7465"), 24, 5)
		_draw_panel(Rect2(origin - Vector2(8, 8), Vector2(width * cell + 16, height * cell + 16)), Color("a8b883"), Color("202a1b"), 5, 4)
		for y in range(height):
			for x in range(width):
				if (x + y) % 2 == 0:
					draw_rect(Rect2(origin + Vector2(x * cell, y * cell), Vector2(cell, cell)), Color("536342", 0.10))
	else:
		_draw_panel(Rect2(origin - Vector2(10, 10), Vector2(width * cell + 20, height * cell + 20)), Color("06182e"), Color(accent, 0.62), 20, 3)
		for y in range(height):
			for x in range(width):
				if (x + y) % 2 == 0:
					draw_rect(Rect2(origin + Vector2(x * cell, y * cell), Vector2(cell, cell)), Color(accent, 0.035))
		# Arena rings imply speed without placing fake collectibles in the playfield.
	var food: Array = state["food"]
	var food_pos := origin + Vector2((int(food[0]) + 0.5) * cell, (int(food[1]) + 0.5) * cell)
	draw_circle(food_pos, 9.0 + sin(elapsed * 6.0) * 2.0, Color(RED, 0.22))
	draw_circle(food_pos, 6.0, Color("374426") if classic else RED)
	var snake: Array = state["snake"]
	for i in range(snake.size()):
		var segment: Array = snake[i]
		var color := Color("25331d") if classic else (accent if i == 0 else accent.darkened(0.26 + float(i) * 0.02))
		var body := Rect2(origin + Vector2(int(segment[0]) * cell + 2, int(segment[1]) * cell + 2), Vector2(cell - 4, cell - 4))
		_draw_panel(body, color, Color(INK, 0.22), 2 if classic else 7, 1)
		if i == 0:
			draw_circle(body.get_center() + Vector2(3, -3), 2.0, WARM_PAPER if classic else COAL)
	if classic:
		_draw_text_font(DISPLAY_FONT, "目标 120", Vector2(62, 770), 16, Color("a8b883"))
		_draw_status_badge("LCD 经典模式", Vector2(360, 752), accent, true, 146)
	else:
		_draw_status_badge("本地挑战", Vector2(66, 752), accent, true, 112)
		_draw_status_badge("穿越边界", Vector2(376, 752), VIOLET, true, 130)
		_draw_text("发光竞技场 · 无尽成长模式", Vector2(66, 790), 12, BRIGHT_MUTED)

# -----------------------------------------------------------------------------
# Solitaire / TriPeaks
# -----------------------------------------------------------------------------

func _init_solitaire() -> void:
	state["stock"] = 24
	state["waste"] = 0
	state["foundations"] = [0, 0, 0, 0]
	state["tableau"] = [5, 4, 3, 2, 1, 0, 0]
	state["selected_col"] = -1
	state["score"] = 0

func _solitaire_draw() -> void:
	if game_id != "solitaire" or state.get("status") != "playing":
		return
	if int(state["stock"]) > 0:
		state["stock"] = int(state["stock"]) - 1
		state["waste"] = int(state["waste"]) + 1
		state["moves"] = int(state["moves"]) + 1
		_flash_feedback("翻开一张牌", AMBER)
		_impact(Vector2(188, 254), AMBER, 0.45)
		_start_motion("card", Vector2(77, 282), Vector2(169, 282), AMBER, str(1 + int(state["waste"]) % 13), 0.42)
		_start_catalog_event("card_draw", Vector2(168, 304), AMBER, 1, "新牌入场", 0.58)
		_log_event("solitaire_draw", {"stock":state["stock"], "waste":state["waste"]})
	else:
		state["stock"] = int(state["waste"])
		state["waste"] = 0
		_start_catalog_event("card_recycle", Vector2(76, 304), CYAN, 1, "牌库重整", 0.58)

func _solitaire_auto() -> void:
	if game_id != "solitaire" or state.get("status") != "playing":
		return
	var tableau: Array = state["tableau"]
	for i in range(tableau.size()):
		if tableau[i] > 0:
			tableau[i] -= 1
			var foundations: Array = state["foundations"]
			foundations[i % 4] = min(13, int(foundations[i % 4]) + 1)
			state["score"] = int(state["score"]) + 25
			state["moves"] = int(state["moves"]) + 1
			_flash_feedback("自动归位 · +25", GOLD)
			_impact(Vector2(390 + (i % 4) * 32, 254), GOLD, 0.55)
			var foundation_total := _solitaire_foundation_total()
			_start_catalog_event("foundation_place", Vector2(323 + (i % 4) * 54, 286), GOLD, 3 if foundation_total % 4 == 0 else 2, "归位 · +25", 0.78)
			break
	if _solitaire_foundation_total() >= 8:
		state["status"] = "won"
		_capture("solitaire_win")
	_log_event("solitaire_auto_move", {"foundations":state["foundations"]})

func _solitaire_tap(pos: Vector2) -> void:
	if game_id != "solitaire" or state.get("status") != "playing":
		return
	var origin := Vector2(34, 330)
	var col := int((pos.x - origin.x) / 68.0)
	if col < 0 or col >= 7 or pos.y < origin.y or pos.y > 720:
		return
	var tableau: Array = state["tableau"]
	if int(state["selected_col"]) < 0:
		if tableau[col] > 0:
			state["selected_col"] = col
			_flash_feedback("已选中牌列 %d" % (col + 1), CYAN)
	else:
		var from := int(state["selected_col"])
		if from != col and tableau[from] > 0:
			tableau[from] -= 1
			tableau[col] += 1
			state["score"] = int(state["score"]) + 10
			state["moves"] = int(state["moves"]) + 1
			_impact(Vector2(63 + col * 68, 430), CYAN, 0.5)
			_start_catalog_event("card_move", Vector2(63 + col * 68, 430), CYAN, 1, "牌列衔接", 0.58)
			if _solitaire_foundation_total() >= 8:
				state["status"] = "won"
				_capture("solitaire_win")
			_log_event("solitaire_move", {"from":from, "to":col})
		state["selected_col"] = -1

func _solitaire_foundation_total() -> int:
	var total := 0
	for value in state["foundations"]:
		total += int(value)
	return total

func _draw_solitaire() -> void:
	_draw_section_heading("翡翠牌桌", "点选牌列，再点目标列", AMBER)
	_draw_text("牌库", Vector2(38, 244), 12, Color("e6d7a4"))
	var stock_rect := Rect2(38, 254, 72, 100)
	if int(state["stock"]) > 0:
		_draw_card_back(stock_rect, Color("d3aa52"))
	else:
		_draw_panel(stock_rect, Color("f8edcc", 0.05), Color("f8edcc", 0.28), 6, 2)
	_draw_status_badge(str(state["stock"]), Vector2(42, 362), AMBER, true, 64)
	_draw_text("废牌", Vector2(132, 244), 12, Color("e6d7a4"))
	if int(state["waste"]) > 0:
		_draw_playing_card(Rect2(132, 254, 72, 100), 1 + int(state["waste"]) % 13, RED, int(state["waste"]) % 4)
	else:
		_draw_panel(Rect2(132, 254, 72, 100), Color("f8edcc", 0.05), Color("f8edcc", 0.28), 6, 2)
	_draw_text("归位区", Vector2(300, 244), 12, Color("e6d7a4"))
	var suits := ["♠", "◆", "♣", "♥"]
	for i in range(4):
		var rect := Rect2(300 + i * 54, 254, 46, 64)
		_draw_panel(rect, Color("f8edcc", 0.045), GREEN if int(state["foundations"][i]) > 0 else Color("f8edcc", 0.28), 6, 2)
		_draw_center_font(SYMBOL_FONT, suits[i], rect.get_center() + Vector2(0, 3), 18, RED if i % 2 == 1 else Color("dce2d3"))
		if int(state["foundations"][i]) > 0:
			_draw_center_font(NUMBER_FONT, str(state["foundations"][i]), rect.get_center() + Vector2(0, 23), 10, GREEN)
	var origin := Vector2(34, 416)
	for col in range(7):
		var count := int(state["tableau"][col])
		for row in range(max(1, count)):
			var rect := Rect2(origin.x + col * 68, origin.y + row * 42, 58, 80)
			if row == count - 1 and count > 0:
				_draw_playing_card(rect, 13 - count + 1, RED, col % 4)
			else:
				_draw_card_back(rect, Color("365b78"))
			if int(state["selected_col"]) == col:
				draw_rect(rect.grow(3), CYAN, false, 3.0)
	_draw_text("将 8 张牌送入归位区即可完成", Vector2(34, 780), 13, Color("e7dcc0"))

func _init_tripeaks() -> void:
	state["cards"] = [2, 5, 8, 3, 6, 9, 12, 4, 7, 10, 13, 1, 5, 8, 11]
	state["removed"] = []
	state["current"] = 7
	state["stock"] = 12
	state["score"] = 0
	state["streak"] = 0

func _tripeaks_next() -> void:
	if game_id != "tripeaks" or state.get("status") != "playing":
		return
	if int(state["stock"]) > 0:
		state["stock"] = int(state["stock"]) - 1
		state["current"] = 1 + ((int(state["current"]) + 4) % 13)
		state["moves"] = int(state["moves"]) + 1
		state["streak"] = 0
		_flash_feedback("翻开 %s" % _card_rank(int(state["current"])), VIOLET)
		_start_motion("card", Vector2(74, 758), Vector2(74, 758), VIOLET, str(state["current"]), 0.40)
		_start_catalog_event("card_draw", Vector2(72, 754), VIOLET, 1, "暮色翻牌", 0.56)
		_log_event("tripeaks_stock", {"current":state["current"], "stock":state["stock"]})
	else:
		state["status"] = "over"

func _tripeaks_tap(pos: Vector2) -> void:
	if game_id != "tripeaks" or state.get("status") != "playing":
		return
	var cards: Array = state["cards"]
	var removed: Array = state["removed"]
	for i in range(cards.size()):
		var center := _tripeaks_card_center(i)
		var cx := center.x
		var cy := center.y
		if pos.distance_to(Vector2(cx, cy)) < 34.0 and not i in removed:
			var locked := i < 5 and not (i + 5) in removed
			if locked:
				_flash_feedback("先清除压住它的牌", RED)
				_impact(center, RED, 0.42)
				_start_catalog_event("card_reject_locked", center, RED, 1, "仍被压住", 0.58)
				return
			var value := int(cards[i])
			var current := int(state["current"])
			if abs(value - current) == 1 or value == 1 and current == 13 or value == 13 and current == 1:
				removed.append(i)
				state["streak"] = int(state.get("streak", 0)) + 1
				state["current"] = value
				state["score"] = int(state["score"]) + 30
				state["moves"] = int(state["moves"]) + 1
				_flash_feedback("连牌成功 · +30", MINT)
				_impact(center, MINT, 0.75)
				var streak := int(state["streak"])
				var streak_grade := clampi(1 + streak / 2, 1, 4)
				_start_catalog_event("card_streak", center, MINT if streak_grade < 3 else GOLD, streak_grade, "连牌 ×%d" % streak, 0.62 + streak_grade * 0.08)
				if removed.size() == cards.size():
					state["status"] = "won"
					_capture("tripeaks_win")
				_log_event("tripeaks_clear", {"card":value, "cleared":removed.size()})
			else:
				state["streak"] = 0
				_flash_feedback("点数不相邻", RED)
				_start_catalog_event("card_reject_rank", center, RED, 1, "点数不相邻", 0.58)
				_log_event("tripeaks_invalid", {"card":value, "current":current})
			return

func _draw_tripeaks() -> void:
	_draw_section_heading("三座暮色牌峰", "相邻点数可收入牌堆", VIOLET)
	var streak := int(state.get("streak", 0))
	if streak > 1:
		_draw_status_badge("连牌 ×%d" % streak, Vector2(382, 190), GOLD, true, 116)
	var cards: Array = state["cards"]
	var removed: Array = state["removed"]
	for i in range(cards.size()):
		var center := _tripeaks_card_center(i)
		var available := not i in removed
		var locked := i < 5 and not (i + 5) in removed
		if locked and available:
			_draw_card_back(Rect2(center - Vector2(29, 39), Vector2(58, 78)), VIOLET)
		else:
			_draw_playing_card(Rect2(center - Vector2(29, 39), Vector2(58, 78)), cards[i], VIOLET if available else Color(INK, 0.1), i % 4)
		if not available:
			draw_rect(Rect2(center - Vector2(29, 39), Vector2(58, 78)), Color(COAL, 0.72))
		elif locked:
			draw_arc(center, 12, 0, TAU, 24, Color(VIOLET, 0.72), 2.0)
	_draw_panel(Rect2(30, 684, 480, 118), Color("102b27", 0.92), Color("e2c48a", 0.34), 12, 1)
	_draw_text("当前牌", Vector2(48, 708), 11, Color("e7dcc0"))
	_draw_playing_card(Rect2(42, 716, 58, 76), int(state["current"]), VIOLET, int(state["current"]) % 4)
	_draw_text("牌库 %d" % int(state["stock"]), Vector2(120, 754), 13, Color("e7dcc0"))
	_draw_text("点击相邻点数 · A 与 K 相接", Vector2(252, 754), 13, Color("e7dcc0"))

func _tripeaks_card_center(index: int) -> Vector2:
	var centers := [
		Vector2(108, 254), Vector2(270, 254), Vector2(432, 254), Vector2(189, 316), Vector2(351, 316),
		Vector2(72, 382), Vector2(171, 382), Vector2(270, 382), Vector2(369, 382), Vector2(468, 382),
		Vector2(72, 466), Vector2(171, 466), Vector2(270, 466), Vector2(369, 466), Vector2(468, 466)
	]
	return centers[clampi(index, 0, centers.size() - 1)]

# -----------------------------------------------------------------------------
# Mahjong matching / Tile Club
# -----------------------------------------------------------------------------

func _init_mahjong() -> void:
	state["tiles"] = [1,2,3,4,5,6,7,8,9,10,1,2,3,4,5,6,7,8,9,10]
	state["removed"] = []
	state["selected"] = -1
	state["score"] = 0

func _mahjong_tap(pos: Vector2) -> void:
	if game_id != "mahjong" or state.get("status") != "playing":
		return
	var origin := Vector2(44, 242)
	var cell := Vector2(88, 112)
	var col := int((pos.x - origin.x) / cell.x)
	var row := int((pos.y - origin.y) / cell.y)
	if col < 0 or col >= 5 or row < 0 or row >= 4:
		return
	var index := row * 5 + col
	var removed: Array = state["removed"]
	if index in removed:
		return
	var selected := int(state["selected"])
	if selected < 0:
		state["selected"] = index
		_flash_feedback("已选中第 %d 张牌" % (index + 1), CYAN)
		_start_catalog_event("jade_select", origin + Vector2((col + 0.43) * cell.x, (row + 0.43) * cell.y), CYAN, 1, "玉牌抬起", 0.48)
		return
	if selected == index:
		state["selected"] = -1
		return
	var tiles: Array = state["tiles"]
	if tiles[selected] == tiles[index]:
		removed.append(selected)
		removed.append(index)
		state["selected"] = -1
		state["score"] = int(state["score"]) + 50
		_flash_feedback("配对成功 · +50", MINT)
		state["moves"] = int(state["moves"]) + 1
		var mahjong_grade := 4 if removed.size() == tiles.size() else 2
		_start_catalog_event("jade_pair", origin + Vector2((col + 0.43) * cell.x, (row + 0.43) * cell.y), MINT if mahjong_grade < 4 else GOLD, mahjong_grade, "同纹共鸣 · +50", 0.82 if mahjong_grade < 4 else 1.08)
		_log_event("mahjong_pair", {"tile":tiles[index], "remaining":tiles.size() - removed.size()})
		if removed.size() == tiles.size():
			state["status"] = "won"
			_capture("mahjong_win")
	else:
		state["selected"] = index
		state["mistakes"] = int(state.get("mistakes", 0)) + 1
		_flash_feedback("牌面不一致", RED)
		_start_catalog_event("jade_mismatch", origin + Vector2((col + 0.43) * cell.x, (row + 0.43) * cell.y), RED, 2, "纹样不同", 0.62)
		_log_event("mahjong_mismatch", {"first":tiles[selected], "second":tiles[index]})

func _draw_mahjong() -> void:
	_draw_section_heading("静心牌阵", "配对相同牌面 · 已收起 %d / 20" % int(state["removed"].size()), MINT)
	var origin := Vector2(44, 242)
	var cell := Vector2(88, 112)
	var tiles: Array = state["tiles"]
	var removed: Array = state["removed"]
	for index in range(tiles.size()):
		var row := index / 5
		var col := index % 5
		var rect := Rect2(origin + Vector2(col * cell.x, row * cell.y), Vector2(76, 96))
		if index in removed:
			draw_circle(rect.get_center(), 4.0, Color("8be5c7", 0.16))
			continue
		var selected := int(state["selected"]) == index
		if selected:
			rect.position.y -= 7.0
		_draw_panel(Rect2(rect.position + Vector2(0, 8), rect.size), Color("071c19", 0.48), Color.TRANSPARENT, 8, 0)
		_draw_panel(Rect2(rect.position + Vector2(0, 4), rect.size), Color("99cdbb"), Color("5d8c7d", 0.72), 8, 1)
		var face := Rect2(rect.position, rect.size - Vector2(0, 5))
		_draw_panel(face, Color("f2ebd6") if not selected else Color("b8f0db"), CYAN if selected else Color("d4c7a7"), 8, 2)
		_draw_mahjong_face(face, int(tiles[index]))
		if selected:
			draw_rect(face.grow(4), CYAN, false, 3.0)
	_draw_text("象牙牌面 · 选中牌会抬起发光", Vector2(44, 728), 13, Color("d5e8df"))

func _draw_mahjong_face(rect: Rect2, value: int) -> void:
	var center := rect.get_center()
	match value:
		1, 2, 3, 4:
			_draw_center(["", "东", "南", "西", "北"][value], center + Vector2(0, 6), 27, Color("214d47"))
		5:
			_draw_center("中", center + Vector2(0, 6), 29, Color("c83f4f"))
		6:
			_draw_center("发", center + Vector2(0, 6), 29, Color("3c8c64"))
		7:
			_draw_center("白", center + Vector2(0, 6), 27, Color("4385c6"))
			draw_rect(Rect2(center - Vector2(16, 20), Vector2(32, 40)), Color("4385c6", 0.58), false, 2.0)
		8, 9, 10:
			var count := value - 7
			for i in range(count):
				draw_circle(center + Vector2((i - (count - 1) * 0.5) * 17, 0), 7.0, [Color("4385c6"), Color("c84b58"), Color("47a06e")][i % 3])

func _init_tileclub() -> void:
	var tiles: Array = []
	for value in range(1, 8):
		for _copy in range(6):
			tiles.append(value)
	# Two bonus triples plus one intentional open slot make a 7x7 composition
	# while every playable symbol count stays divisible by three.
	for bonus in [1, 1, 1, 2, 2, 2]:
		tiles.append(bonus)
	tiles.append(0)
	# Deterministic Fisher-Yates shuffle keeps evaluator runs reproducible while
	# avoiding the debug-looking striped test pattern.
	for index in range(tiles.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary: Variant = tiles[index]
		tiles[index] = tiles[swap_index]
		tiles[swap_index] = temporary
	state["tiles"] = tiles
	state["tray"] = []
	state["score"] = 0
	state["moves"] = 0

func _tileclub_tap(pos: Vector2) -> void:
	if game_id != "tileclub" or state.get("status") != "playing":
		return
	var origin := Vector2(36, 236)
	var cell := 64.0
	var col := int((pos.x - origin.x) / cell)
	var row := int((pos.y - origin.y) / cell)
	if col < 0 or col >= 7 or row < 0 or row >= 7:
		return
	var index := row * 7 + col
	var tiles: Array = state["tiles"]
	if int(tiles[index]) == 0:
		return
	var value := int(tiles[index])
	tiles[index] = 0
	var tray: Array = state["tray"]
	tray.append(value)
	state["moves"] = int(state["moves"]) + 1
	_flash_feedback("收集 · %s" % _tile_symbol(value), _tile_color(value))
	var tile_center := Vector2(64 + col * 64, 264 + row * 64)
	_impact(tile_center, _tile_color(value), 0.45)
	_start_motion("tile", tile_center, Vector2(66 + (tray.size() - 1) * 67, 759), _tile_color(value), _tile_symbol(value), 0.44)
	_start_catalog_event("stitch_collect", tile_center, _tile_color(value), 1, "%s片入槽" % _tile_symbol(value), 0.54)
	var removed_count := 0
	for n in range(1, 8):
		var count := 0
		for v in tray:
			if int(v) == n:
				count += 1
		if count >= 3:
			removed_count = 0
			for i in range(tray.size() - 1, -1, -1):
				if int(tray[i]) == n and removed_count < 3:
					tray.remove_at(i)
					removed_count += 1
				state["score"] = int(state["score"]) + 100
				_flash_feedback("三枚消除 · +100", GOLD)
				_impact(Vector2(270, 730), GOLD, 1.0)
				var cleared_after_match := _tileclub_cleared()
				_start_catalog_event("stitch_match", Vector2(270, 755), GOLD, 4 if cleared_after_match else 3, "三枚缝合 · +100", 0.96 if not cleared_after_match else 1.12)
			_log_event("tileclub_match", {"tile":n, "score":state["score"]})
		if removed_count > 0:
			break
	if tray.size() >= 7:
		state["status"] = "over"
		_capture("tileclub_tray_full")
	elif _tileclub_cleared():
		state["status"] = "won"
		_capture("tileclub_win")

func _tileclub_tray_hint() -> void:
	if game_id == "tileclub" and state.get("status") == "playing":
		_flash_feedback("集齐三枚自动消除 · 七格满则结束", AMBER)
		_log_event("tileclub_tray_hint", {})

func _tileclub_cleared() -> bool:
	for value in state["tiles"]:
		if int(value) != 0:
			return false
	return true

func _draw_tileclub() -> void:
	_draw_section_heading("玩具俱乐部", "三枚同图案自动消除", Color("ff9f68"))
	var origin := Vector2(36, 236)
	var cell := 64.0
	var tiles: Array = state["tiles"]
	for index in range(49):
		var row := index / 7
		var col := index % 7
		var rect := Rect2(origin + Vector2(col * cell, row * cell), Vector2(56, 56))
		var value := int(tiles[index])
		if value == 0:
			draw_circle(rect.get_center(), 3.0, Color(INK, 0.08))
			if index == 48 and state["tray"].is_empty() and int(state["moves"]) == 0:
				draw_arc(rect.get_center(), 18, 0, TAU, 24, Color(INK, 0.10), 1.0)
		else:
			_draw_panel(Rect2(rect.position + Vector2(0, 5), rect.size), Color(0, 0, 0, 0.30), Color.TRANSPARENT, 12, 0)
			_draw_panel(rect, _tile_color(value), Color(INK, 0.30), 12, 2)
			for stitch_corner in [Vector2(8, 8), Vector2(48, 8), Vector2(48, 48), Vector2(8, 48)]:
				draw_circle(rect.position + stitch_corner, 1.5, Color("fff0d7", 0.76))
			draw_circle(rect.position + Vector2(17, 15), 10, Color(INK, 0.13))
			_draw_center(_tile_symbol(value), rect.get_center() + Vector2(0, 3), 22, COAL)
			if (row + col) % 4 == 0:
				draw_arc(rect.get_center(), 21, -PI * 0.2, PI * 0.9, 16, Color(INK, 0.16), 2.0)
	var tray_count := int(state["tray"].size())
	var risk_color := RED if tray_count >= 6 else (AMBER if tray_count >= 5 else MINT)
	_draw_status_badge("槽位 %d / 7" % tray_count, Vector2(36, 692), risk_color, tray_count < 5, 124)
	_draw_panel(Rect2(30, 726, 480, 66), Color("17142a", 0.96), Color(risk_color, 0.46), 14, 2)
	for i in range(7):
		var slot := Rect2(39 + i * 67, 736, 54, 46)
		_draw_panel(slot, Color("0e1528"), Color(risk_color, 0.62) if i < tray_count else Color(INK, 0.14), 8, 2)
		if i < tray_count:
			var tray_value := int(state["tray"][i])
			_draw_center(_tile_symbol(tray_value), slot.get_center(), 18, _tile_color(tray_value))

func _tile_color(value: int) -> Color:
	var colors := [Color("78d7e8"), Color("f6c667"), Color("ff8a78"), Color("b898f2"), Color("6fdb9d"), Color("f18cc8"), Color("a1b5d9")]
	return colors[clampi(value - 1, 0, colors.size() - 1)]

func _tile_symbol(value: int) -> String:
	return ["", "叶", "月", "莓", "星", "花", "贝", "晶"][clampi(value, 1, 7)]

# -----------------------------------------------------------------------------
# Amaze / Arrow GO path games
# -----------------------------------------------------------------------------

func _init_amaze() -> void:
	var grid_size := 6 if game_id == "amaze_go" else (9 if game_id == "arrow_go" else 8)
	var painted := _new_grid(grid_size, grid_size, false)
	painted[0][0] = true
	state["size"] = grid_size
	state["player"] = [0, 0]
	state["target"] = [grid_size - 1, grid_size - 1]
	state["painted"] = painted
	state["score"] = 0
	state["moves"] = 0
	state["streak"] = 0
	state["hint"] = [1, 0]
	var arrows := _new_grid(grid_size, grid_size, [1, 0])
	for y in range(grid_size):
		for x in range(grid_size):
			if x < grid_size - 1:
				arrows[y][x] = [1, 0]
			else:
				arrows[y][x] = [0, 1]
	state["arrows"] = arrows
	state["walls"] = _build_maze_walls(grid_size)

func _amaze_tap(pos: Vector2) -> void:
	if state.get("status") != "playing":
		return
	var grid_size := int(state["size"])
	var cell := 430.0 / grid_size
	var origin := Vector2(54, 236)
	var col := int((pos.x - origin.x) / cell)
	var row := int((pos.y - origin.y) / cell)
	var player: Array = state["player"]
	var delta := Vector2i(col - int(player[0]), row - int(player[1]))
	if abs(delta.x) + abs(delta.y) == 1:
		_amaze_step(delta)

func _amaze_step(direction: Vector2i) -> void:
	if (game_id != "amaze_go" and game_id != "arrow_go" and game_id != "amaze") or state.get("status") != "playing":
		return
	var player: Array = state["player"]
	var size_grid := int(state["size"])
	if game_id == "arrow_go":
		var arrow: Array = state["arrows"][int(player[1])][int(player[0])]
		if direction != Vector2i(int(arrow[0]), int(arrow[1])):
			_flash_feedback("箭流只允许%s" % _direction_name(arrow), RED)
			_impact(_path_cell_center(int(player[0]), int(player[1]), size_grid), RED, 0.48)
			_start_catalog_event("path_reject_arrow", _path_cell_center(int(player[0]), int(player[1]), size_grid), RED, 2, "逆着箭流", 0.62)
			return
	if game_id == "amaze_go" and _maze_blocks(int(player[0]), int(player[1]), direction):
		_flash_feedback("这里有墙", RED)
		_impact(_path_cell_center(int(player[0]), int(player[1]), size_grid), RED, 0.48)
		_start_catalog_event("path_reject_wall", _path_cell_center(int(player[0]), int(player[1]), size_grid), RED, 2, "蓝图有墙", 0.62)
		return
	var next := Vector2i(int(player[0]) + direction.x, int(player[1]) + direction.y)
	if next.x < 0 or next.y < 0 or next.x >= size_grid or next.y >= size_grid:
		_start_catalog_event("path_reject_edge", _path_cell_center(int(player[0]), int(player[1]), size_grid), RED, 1, "已到边界", 0.54)
		return
	var from_position := _path_cell_center(int(player[0]), int(player[1]), size_grid)
	player[0] = next.x
	player[1] = next.y
	state["painted"][next.y][next.x] = true
	state["moves"] = int(state["moves"]) + 1
	state["score"] = int(state["score"]) + 5
	state["streak"] = int(state.get("streak", 0)) + 1
	var to_position := _path_cell_center(next.x, next.y, size_grid)
	_impact(to_position, _catalog_item(game_id).accent, 0.30)
	_start_motion("path", from_position, to_position, _catalog_item(game_id).accent, "", 0.24)
	var path_streak := int(state["streak"])
	var path_grade := 2 if path_streak % 5 == 0 else 1
	var path_label := "轨迹 ×%d" % path_streak if path_grade > 1 else ("颜料铺开" if game_id == "amaze" else ("箭流推进" if game_id == "arrow_go" else "蓝图点亮"))
	_start_catalog_event("path_step", to_position, _catalog_item(game_id).accent, path_grade, path_label, 0.52 if path_grade == 1 else 0.70)
	_log_event("path_step", {"x":next.x, "y":next.y})
	var target: Array = state["target"]
	var reached_goal := next.x == int(target[0]) and next.y == int(target[1])
	if game_id == "amaze":
		reached_goal = _painted_count() == size_grid * size_grid
	if reached_goal:
		_start_catalog_event("path_complete", to_position, GOLD, 4, "全域完成", 1.12)
		state["status"] = "won"
		state["score"] = int(state["score"]) + 100
		_capture("path_win_%s" % game_id)

func _amaze_hint() -> void:
	if state.get("status") != "playing":
		return
	var player: Array = state["player"]
	var target: Array = state["target"]
	var direction := Vector2i.ZERO
	if int(player[0]) < int(target[0]): direction = Vector2i.RIGHT
	elif int(player[0]) > int(target[0]): direction = Vector2i.LEFT
	elif int(player[1]) < int(target[1]): direction = Vector2i.DOWN
	else: direction = Vector2i.UP
	state["hint"] = [direction.x, direction.y]
	_flash_feedback("建议%s" % _direction_name(state["hint"]), VIOLET if game_id == "arrow_go" else CYAN)
	_log_event("path_hint", {"direction":str(direction)})

func _draw_amaze() -> void:
	var grid_size := int(state["size"])
	var cell := 430.0 / grid_size
	var origin := Vector2(54, 236)
	var painted: Array = state["painted"]
	var accent: Color = _catalog_item(game_id).accent
	_draw_section_heading("蓝图迷阵" if game_id == "amaze_go" else ("箭流中枢" if game_id == "arrow_go" else "霓彩工坊"), "相邻格点击或方向键移动", accent)
	_draw_panel(Rect2(origin - Vector2(10, 10), Vector2(450, 450)), Color("081528", 0.88), Color(accent, 0.54), 18, 3)
	for y in range(grid_size):
		for x in range(grid_size):
			var rect := Rect2(origin + Vector2(x * cell, y * cell), Vector2(cell - 2, cell - 2))
			var fill := Color("16243f")
			if painted[y][x]:
				fill = Color(accent, 0.34)
			_draw_panel(rect, fill, Color(INK, 0.11), 3 if game_id == "arrow_go" else 8, 1)
			if game_id == "arrow_go":
				_draw_path_arrow(rect.get_center(), state["arrows"][y][x], Color(accent, 0.82 if not painted[y][x] else 0.34), cell * 0.25)
			elif game_id == "amaze_go":
				_draw_maze_walls(rect, x, y, grid_size, accent)
			elif painted[y][x]:
				var paint := _paint_color(x + y)
				paint.a = 0.72
				draw_circle(rect.get_center(), cell * 0.34, paint)
				if x > 0 and painted[y][x - 1]:
					draw_line(rect.get_center(), rect.get_center() - Vector2(cell, 0), paint, cell * 0.55)
				if y > 0 and painted[y - 1][x]:
					draw_line(rect.get_center(), rect.get_center() - Vector2(0, cell), paint, cell * 0.55)
	var target: Array = state["target"]
	var player: Array = state["player"]
	var target_pos := origin + Vector2((int(target[0]) + 0.5) * cell, (int(target[1]) + 0.5) * cell)
	var player_pos := origin + Vector2((int(player[0]) + 0.5) * cell, (int(player[1]) + 0.5) * cell)
	if game_id != "amaze":
		draw_circle(target_pos, cell * 0.35 + sin(elapsed * 3.0) * 2.0, Color(AMBER, 0.16))
		draw_arc(target_pos, cell * 0.25, 0, TAU, 24, AMBER, maxf(2.0, cell * 0.07), true)
	draw_circle(player_pos, cell * 0.37, Color(accent, 0.18))
	if game_id == "amaze_go":
		draw_circle(player_pos, cell * 0.25, Color("f1d28a"))
		draw_arc(player_pos, cell * 0.18, 0, TAU, 24, Color("75532c"), maxf(2.0, cell * 0.045), true)
		draw_line(player_pos, player_pos + Vector2(cell * 0.12, -cell * 0.13), Color("b44343"), maxf(2.0, cell * 0.055), true)
	elif game_id == "arrow_go":
		draw_colored_polygon(PackedVector2Array([player_pos + Vector2(cell * 0.27, 0), player_pos + Vector2(-cell * 0.18, -cell * 0.20), player_pos + Vector2(-cell * 0.10, 0), player_pos + Vector2(-cell * 0.18, cell * 0.20)]), accent)
	else:
		draw_circle(player_pos, cell * 0.25, accent)
		draw_circle(player_pos - Vector2(cell * 0.08, cell * 0.08), cell * 0.07, Color("fff4da", 0.88))
	if game_id != "amaze":
		_draw_center("终", target_pos, max(12, int(cell * 0.22)), COAL)
	var painted_count := _painted_count()
	if game_id == "amaze":
		_draw_status_badge("涂色 %d%%" % int(float(painted_count) / float(grid_size * grid_size) * 100.0), Vector2(54, 692), accent, true, 124)
		_draw_text("滚动彩球，涂满全部格子才能完成", Vector2(54, 746), 12, BRIGHT_MUTED)
	elif game_id == "arrow_go":
		_draw_status_badge("箭流%s" % _direction_name(state.get("hint", [1, 0])), Vector2(54, 692), accent, true, 124)
		_draw_text("沿格内箭头辨认方向，寻找出口", Vector2(54, 746), 12, BRIGHT_MUTED)
	else:
		_draw_status_badge("轨迹 %d 格" % painted_count, Vector2(54, 692), accent, true, 124)
		_draw_text("穿过蓝图迷宫，已走路径会持续点亮", Vector2(54, 746), 12, BRIGHT_MUTED)
	_draw_text("目标在右下角", Vector2(388, 715), 12, Color(BRIGHT_MUTED, 0.78)) if game_id != "amaze" else _draw_text("覆盖全部区域", Vector2(388, 715), 12, Color(BRIGHT_MUTED, 0.78))

func _draw_path_arrow(center: Vector2, value: Array, color: Color, length: float) -> void:
	var direction := Vector2(float(value[0]), float(value[1]))
	if direction == Vector2.ZERO:
		return
	var start := center - direction * length * 0.52
	var end := center + direction * length * 0.52
	draw_line(start, end, color, max(2.0, length * 0.16))
	var side := Vector2(-direction.y, direction.x)
	draw_line(end, end - direction * length * 0.34 + side * length * 0.28, color, max(2.0, length * 0.14))
	draw_line(end, end - direction * length * 0.34 - side * length * 0.28, color, max(2.0, length * 0.14))

func _draw_maze_walls(rect: Rect2, x: int, y: int, grid_size: int, color: Color) -> void:
	var wall_color := Color(color, 0.54)
	var walls: Dictionary = state.get("walls", {})
	if y == 0 or bool(walls.get(_maze_edge_key(x, y, 0, -1), false)):
		draw_line(rect.position, Vector2(rect.end.x, rect.position.y), wall_color, 3.0)
	if x == 0 or bool(walls.get(_maze_edge_key(x, y, -1, 0), false)):
		draw_line(rect.position, Vector2(rect.position.x, rect.end.y), wall_color, 3.0)
	if y == grid_size - 1 or bool(walls.get(_maze_edge_key(x, y, 0, 1), false)):
		draw_line(Vector2(rect.position.x, rect.end.y), rect.end, wall_color, 3.0)
	if x == grid_size - 1 or bool(walls.get(_maze_edge_key(x, y, 1, 0), false)):
		draw_line(Vector2(rect.end.x, rect.position.y), rect.end, wall_color, 3.0)

func _build_maze_walls(grid_size: int) -> Dictionary:
	var walls := {}
	# Keep a guaranteed route across the top and down the right edge; add paired
	# interior walls elsewhere so the rendered blueprint and collision agree.
	for y in range(1, grid_size - 1):
		for x in range(grid_size - 1):
			if (x * 3 + y * 5) % 4 == 0:
				walls[_maze_edge_key(x, y, 1, 0)] = true
	for y in range(1, grid_size - 1):
		for x in range(1, grid_size - 1):
			if (x * 5 + y * 2) % 5 == 0:
				walls[_maze_edge_key(x, y, 0, 1)] = true
	return walls

func _maze_edge_key(x: int, y: int, dx: int, dy: int) -> String:
	var nx := x + dx
	var ny := y + dy
	var first := "%d,%d" % [x, y]
	var second := "%d,%d" % [nx, ny]
	return "%s|%s" % [first, second] if first < second else "%s|%s" % [second, first]

func _maze_blocks(x: int, y: int, direction: Vector2i) -> bool:
	var walls: Dictionary = state.get("walls", {})
	return bool(walls.get(_maze_edge_key(x, y, direction.x, direction.y), false))

func _path_cell_center(x: int, y: int, grid_size: int) -> Vector2:
	var cell := 430.0 / grid_size
	return Vector2(54 + (x + 0.5) * cell, 236 + (y + 0.5) * cell)

func _painted_count() -> int:
	var count := 0
	for row in state["painted"]:
		for value in row:
			if bool(value): count += 1
	return count

func _paint_color(index: int) -> Color:
	return [Color("55e0ae"), Color("65c9ff"), Color("a994ff"), Color("ff8bb4"), Color("ffd15c")][posmod(index, 5)]

func _direction_name(value: Array) -> String:
	if int(value[0]) > 0: return "向右"
	if int(value[0]) < 0: return "向左"
	if int(value[1]) > 0: return "向下"
	return "向上"
