extends Control

## No WiFi Games: a clean-room, offline-first Godot collection.
## Every mini-game shares the same reset/input/snapshot/result contract so the
## independent evaluator can exercise complete player-facing loops.

const VIEW_SIZE := Vector2(540.0, 960.0)
const MEOWDOKU_WEB_CHECKPOINT_KEY := "offline-games.meowdoku.v3.checkpoint"
const HEADER_H := 104.0
const BOARD_TOP := 164.0
const SNAKE_STEP_INTERVAL := 0.36
const SNAKE_GB_STEP_INTERVAL := 1.0 / 7.5
const SNAKE_GB_WEB_STORAGE_KEY := "offline-games:snake-gb:v3"
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
const SNAKE_GB_GAG_HEAD_TEXTURE: Texture2D = preload("res://assets/art/snakes/gag/gb_snake_head_gag_v2.png")
const SNAKE_GB_GAG_LURE_TEXTURE: Texture2D = preload("res://assets/art/snakes/gag/gb_snake_lure_gag_v2.png")
const SNAKE_GB_GAG_FIELD_SEAL_TEXTURE: Texture2D = preload("res://assets/art/snakes/gag/gb_snake_field_seal_gag_v2.png")
const SNAKES_DOODLE_TEXTURE: Texture2D = preload("res://assets/art/snakes/arena_doodles.webp")
const SNAKES_GAG_PLAYER_HEAD_TEXTURE: Texture2D = preload("res://assets/art/snakes/gag-v2/snakes_player_head_gag_v2.png")
const SNAKES_GAG_PRIZE_BEAN_TEXTURE: Texture2D = preload("res://assets/art/snakes/gag-v2/snakes_prize_bean_gag_v2.png")
const SNAKES_GAG_KNOCKOUT_BURST_TEXTURE: Texture2D = preload("res://assets/art/snakes/gag-v2/snakes_knockout_burst_gag_v2.png")
const SOLITAIRE_CARD_BACK_TEXTURE: Texture2D = preload("res://assets/art/cards/solitaire_card_back_gag_v1.webp")
const TRIPEAKS_CARD_BACK_TEXTURE: Texture2D = preload("res://assets/art/cards/tripeaks_card_back_gag_v1.webp")
const MAHJONG_TILE_BASE_TEXTURE: Texture2D = preload("res://assets/art/catalog/tile_games/mahjong_tile_base.svg")
const MAHJONG_GAG_TILE_TEXTURE: Texture2D = preload("res://assets/art/catalog/tile_games/gag/mahjong_tile_blank_gag_v1.png")
const TILECLUB_GAG_BADGE_ATLAS_TEXTURE: Texture2D = preload("res://assets/art/catalog/tile_games/gag/tileclub_badge_atlas_gag_v1.png")
const TILECLUB_GAG_SHELL_TEXTURE: Texture2D = preload("res://assets/art/catalog/tile_games/gag/tileclub_shell_badge_gag_v1.png")
const AMAZE_GO_GAG_SURVEYOR_TEXTURE: Texture2D = preload("res://assets/art/catalog/path_games/gag/amaze_go_surveyor_gag_v1.png")
const AMAZE_GO_GAG_BEACON_TEXTURE: Texture2D = preload("res://assets/art/catalog/path_games/gag/amaze_go_beacon_gag_v1.png")
const ARROW_GO_GAG_WIND_PLATE_TEXTURE: Texture2D = preload("res://assets/art/catalog/path_games/gag/arrow_go_wind_plate_gag_v1.png")
const ARROW_GO_GAG_COURIER_RIGHT_TEXTURE: Texture2D = preload("res://assets/art/catalog/path_games/gag/arrow_go_courier_right_gag_v1.png")
const ARROW_GO_GAG_COURIER_DOWN_TEXTURE: Texture2D = preload("res://assets/art/catalog/path_games/gag/arrow_go_courier_down_gag_v1.png")
const ARROW_GO_GAG_HARBOR_TEXTURE: Texture2D = preload("res://assets/art/catalog/path_games/gag/arrow_go_harbor_gag_v1.png")
const SNAKE_RULES = preload("res://snake_model.gd")
const SNAKE_GB_RULES = preload("res://models/snake_gb_model.gd")
const SNAKES_ARENA_RULES = preload("res://models/snakes_arena_model.gd")
const MERGE2248_RULES = preload("res://models/merge2248_model.gd")
const MERGE2048_RULES = preload("res://models/merge2048_model.gd")
const WATERMELON_RULES = preload("res://models/watermelon_physics_model.gd")
const MEOWDOKU_RULES = preload("res://models/meowdoku_model.gd")
const SUDOKU_RULES = preload("res://models/sudoku_model.gd")
const SOLITAIRE_RULES = preload("res://models/solitaire_model.gd")
const TRIPEAKS_RULES = preload("res://models/tripeaks_model.gd")
const MAHJONG_RULES = preload("res://models/mahjong_solitaire_model.gd")
const MERGE2248_PRESENTATION = preload("res://presentation/merge2248_presenter.gd")
const MERGE2248_SAVE_PATH := "user://offline_games_merge2248_v4.json"
const MERGE2048_CLASSIC_PRESENTATION = preload("res://presentation/merge2048_classic_presenter.gd")
const CATALOG_ART_DIRECTION = preload("res://presentation/catalog_art_director.gd")
const WATERMELON_PRESENTATION = preload("res://presentation/watermelon_presenter.gd")
const LOGIC_GAME_PRESENTATION = preload("res://presentation/logic_game_presenter.gd")
const MEOWDOKU_PRESENTATION = preload("res://presentation/meowdoku_presenter.gd")
const SFX_CASE_OPEN: AudioStream = preload("res://assets/audio/ui/case_open.wav")
const SFX_SNAKE_KEY: AudioStream = preload("res://assets/audio/snake/key.wav")
const SFX_SNAKE_REJECT: AudioStream = preload("res://assets/audio/snake/reject.wav")
const SFX_SNAKE_EAT: AudioStream = preload("res://assets/audio/snake/eat.wav")
const SFX_SNAKE_CRASH: AudioStream = preload("res://assets/audio/snake/crash.wav")
const SFX_SNAKE_WIN: AudioStream = preload("res://assets/audio/snake/win.wav")
const SFX_SNAKE_GB_GAG_COLLECT: AudioStream = preload("res://assets/audio/snake/gag/gb_snake_specimen_collect_gag_v2.ogg")
const SFX_SNAKE_GB_GAG_COMPLETE: AudioStream = preload("res://assets/audio/snake/gag/gb_snake_field_log_complete_gag_v2.ogg")
const SFX_SNAKES_GAG_CHOMP: AudioStream = preload("res://assets/audio/snakes/gag-v2/gummy_chomp_gag_v2.ogg")
const SFX_SNAKES_GAG_BOOST: AudioStream = preload("res://assets/audio/snakes/gag-v2/gummy_boost_gag_v2.ogg")
const SFX_SNAKES_GAG_KNOCKOUT: AudioStream = preload("res://assets/audio/snakes/gag-v2/gummy_knockout_gag_v2.ogg")
const SFX_SNAKES_GAG_LEADER: AudioStream = preload("res://assets/audio/snakes/gag-v2/leader_takeover_gag_v2.ogg")
const SFX_FRUIT_DROP: AudioStream = preload("res://assets/audio/2048balls/fruit_drop.ogg")
const SFX_FRUIT_MERGE: AudioStream = preload("res://assets/audio/2048balls/fruit_merge.ogg")
const SFX_FRUIT_CASCADE: AudioStream = preload("res://assets/audio/2048balls/fruit_cascade.ogg")
const SFX_2048_SLIDE: AudioStream = preload("res://assets/audio/merge2048/tile_slide.ogg")
const SFX_2048_MERGE: AudioStream = preload("res://assets/audio/merge2048/tile_merge.ogg")
const SFX_2048_MILESTONE: AudioStream = preload("res://assets/audio/merge2048/tile_milestone.ogg")
const SFX_MERGE2248_GAG_MERGE: AudioStream = preload("res://assets/audio/merge2248/gag/candy_merge_gag_v3.ogg")
const SFX_MERGE2248_GAG_MASTERY: AudioStream = preload("res://assets/audio/merge2248/gag/recipe_mastery_gag_v3.ogg")
const SFX_LOGIC_SELECT: AudioStream = preload("res://assets/audio/logic/paper_select.wav")
const SFX_LOGIC_CONFIRM: AudioStream = preload("res://assets/audio/logic/ink_confirm.wav")
const SFX_LOGIC_ERROR: AudioStream = preload("res://assets/audio/logic/correction_scratch.wav")
const SFX_LOGIC_BLOCK: AudioStream = preload("res://assets/audio/logic/block_stamp.wav")
const SFX_LOGIC_COMPLETE: AudioStream = preload("res://assets/audio/logic/folio_complete.wav")
const SFX_MEOW_GAG_COMPLETE: AudioStream = preload("res://assets/audio/logic/gag-v1/meowdoku_complete_reward.ogg")
const SFX_SUDOKU_GAG_COMPLETE: AudioStream = preload("res://assets/audio/logic/gag-v1/sudoku_complete_reward.ogg")
const SFX_SOLITAIRE_CARD_SETTLE: AudioStream = preload("res://assets/audio/cards/solitaire_card_settle_gag_v1.ogg")
const SFX_TRIPEAKS_STREAK_PEAK: AudioStream = preload("res://assets/audio/cards/tripeaks_streak_peak_gag_v1.ogg")
const SFX_MAHJONG_GAG_PAIR: AudioStream = preload("res://assets/audio/catalog/tile_games/gag/jade_pair_resonance_gag_v1.ogg")
const SFX_TILECLUB_GAG_MATCH: AudioStream = preload("res://assets/audio/catalog/tile_games/gag/fabric_triple_stitch_gag_v1.ogg")
const SFX_AMAZE_GO_GAG_RATCHET: AudioStream = preload("res://assets/audio/catalog/path_games/gag/amaze_go_survey_ratchet_gag_v1.ogg")
const SFX_AMAZE_GO_GAG_SEAL: AudioStream = preload("res://assets/audio/catalog/path_games/gag/amaze_go_destination_seal_gag_v1.ogg")
const SFX_ARROW_GO_GAG_KITE_STEP: AudioStream = preload("res://assets/audio/catalog/path_games/gag/arrow_go_kite_step_gag_v1.ogg")
const SFX_ARROW_GO_GAG_HARBOR_DOCK: AudioStream = preload("res://assets/audio/catalog/path_games/gag/arrow_go_harbor_dock_gag_v1.ogg")
const MERGE2048_SAVE_PATH := "user://merge2048_classic.json"
const MERGE2048_SWIPE_THRESHOLD := 10.0

var catalog: Array = [
	{"id":"merge2248", "title":"2248", "subtitle":"数字连线", "group":"数字", "accent":Color("ffbf2f"), "desc":"八方向连接数字，延续你的最高配方"},
	{"id":"merge2048", "title":"2048", "subtitle":"滑动合成", "group":"数字", "accent":Color("f4b860"), "desc":"用四个方向合成更大的数字"},
	{"id":"watermelon", "title":"2048 Balls", "subtitle":"合成大西瓜", "group":"数字", "accent":Color("ff6b8a"), "desc":"落下水果，让相同水果合体"},
	{"id":"meowdoku", "title":"Meowdoku", "subtitle":"猫咪领地", "group":"逻辑", "accent":Color("f39ac7"), "desc":"每行、每列、每个色区各找一只猫"},
	{"id":"sudoku", "title":"Sudoku", "subtitle":"传统数独", "group":"数独", "accent":Color("a78bfa"), "desc":"经典逻辑推理，支持错误提示"},
	{"id":"snake_classic", "title":"GB Snake", "subtitle":"掌机贪食蛇", "group":"街机", "accent":Color("a8b883"), "desc":"滑动或方向键转向，双食物无尽生长"},
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
var reduced_effects := false
var haptics_enabled := true
var haptic_requests_sent := 0
var snake_clock := 0.0
var selected_cell := Vector2i(-1, -1)
var pointer_down := Vector2(-1, -1)
var meowdoku_double_action_consumed := false
var meowdoku_preliminary_single: Dictionary = {}
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
var motion_value := 0
var home_entered_at := 0.0
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_cursor := 0
var haptic_dispatch_count := 0
var snake_model = SNAKE_RULES.new()
var snake_gb_model = SNAKE_GB_RULES.new()
var snakes_arena_model = SNAKES_ARENA_RULES.new()
var merge2248_model = MERGE2248_RULES.new()
var merge2048_model = MERGE2048_RULES.new()
var watermelon_model = WATERMELON_RULES.new()
var meowdoku_model = MEOWDOKU_RULES.new()
var meowdoku_fixture_id := "notebook_5"
var meowdoku_recovery_enabled := true
var meowdoku_skip_recovery_once := false
var sudoku_model = SUDOKU_RULES.new()
var solitaire_model = SOLITAIRE_RULES.new()
var tripeaks_model = TRIPEAKS_RULES.new()
var mahjong_model = MAHJONG_RULES.new()
var merge2248_presenter = MERGE2248_PRESENTATION.new()
var merge2048_classic_presenter = MERGE2048_CLASSIC_PRESENTATION.new()
var catalog_art_director = CATALOG_ART_DIRECTION.new()
var watermelon_presenter = WATERMELON_PRESENTATION.new()
var logic_game_presenter = LOGIC_GAME_PRESENTATION.new()
var meowdoku_presenter = MEOWDOKU_PRESENTATION.new()
var sudoku_restart_requested := false
var sudoku_reduced_effects := false
var mahjong_object_fx: Dictionary = {}
var mahjong_focus := -1
var mahjong_reduced_effects := false
var tileclub_object_fx: Dictionary = {}
var amaze_go_object_fx: Dictionary = {}
var amaze_go_route: Array[Vector2i] = []
var amaze_go_facing := Vector2i.RIGHT
var arrow_go_object_fx: Dictionary = {}
var arrow_go_route: Array[Vector2i] = []
var arrow_go_facing := Vector2i.RIGHT
var catalog_fx: Array[Dictionary] = []
var catalog_fx_serial := 0
var tripeaks_focus_slot := 18
var tripeaks_recovered_from_snapshot := false
var tripeaks_restart_requested := false
var tripeaks_reduced_effects := false
var tripeaks_haptic_emissions := 0
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
var merge2248_persistence_enabled := true
var merge2248_save_path := MERGE2248_SAVE_PATH
var merge2248_reduced_effects_override: Variant = null
var merge2248_reduced_effects := false
var merge2048_motion: Dictionary = {}
var merge2048_persistence_enabled := true
var merge2048_save_path := MERGE2048_SAVE_PATH
var merge2048_seed_override := -1
var merge2048_force_new_run := false
var reduced_effects_enabled := false
var snake_ghosts: Array[Dictionary] = []
var snake_pixels: Array[Dictionary] = []
var snake_fx_kind := ""
var snake_fx_started := -10.0
var snake_fx_cell := Vector2i.ZERO
var snake_fx_direction := Vector2i.RIGHT
var snake_gb_object_fx: Dictionary = {}
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
var arena_restart_requested := false
var arena_recovered_from_snapshot := false
var arena_knockout_started := -10.0
var arena_knockout_world := Vector2.ZERO
var arena_knockout_killer_id := -1
var snakes_reduced_effects := false
var solitaire_selection: Dictionary = {}
var solitaire_focus_zone := "top"
var solitaire_focus_index := 0
var solitaire_focus_card_index := -1
var solitaire_recovered_from_snapshot := false
var solitaire_restart_requested := false
var solitaire_reduced_effects := false
var solitaire_haptic_emissions := 0

func _ready() -> void:
	set_process(true)
	set_process_input(true)
	# Automated probes must not inherit a developer's real active run. A probe
	# can opt into persistence by assigning an exact, isolated save path before
	# the node enters the tree.
	if merge2048_save_path == MERGE2048_SAVE_PATH and _merge2048_tool_runtime():
		merge2048_persistence_enabled = false
	_setup_accessibility_preferences()
	snakes_reduced_effects = reduced_effects or OS.get_environment("SNAKES_REDUCED_EFFECTS") == "1"
	if OS.has_feature("web"):
		var snakes_browser_preference: Variant = JavaScriptBridge.eval("window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 1 : 0", true)
		snakes_reduced_effects = snakes_reduced_effects or int(snakes_browser_preference) == 1
	var cjk_font := UI_FONT as FontFile
	if cjk_font:
		cjk_font.fallbacks = [LATIN_FONT, SYMBOL_FONT]
	fallback_font = UI_FONT
	merge2248_reduced_effects = _detect_merge2248_reduced_effects()
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
	_read_solitaire_effect_preference()
	_read_tripeaks_effect_preference()
	_setup_audio()
	_build_home()
	_play_sfx(SFX_CASE_OPEN, -11.0)
	_setup_web_acceptance()
	_try_restore_mahjong_session()
	_publish_web_state()
	_capture("boot")


func _detect_reduced_effects() -> void:
	var environment_value := OS.get_environment("OFFLINE_GAMES_REDUCED_EFFECTS").to_lower()
	reduced_effects = environment_value in ["1", "true", "yes", "on"]
	if OS.has_feature("web"):
		# Numeric JS results are stable across Godot Web bridge variants.
		var browser_preference: Variant = JavaScriptBridge.eval("window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 1 : 0", true)
		reduced_effects = reduced_effects or int(browser_preference) == 1


func _set_reduced_effects(value: bool) -> void:
	reduced_effects = value
	reduced_effects_enabled = value
	sudoku_reduced_effects = value
	snakes_reduced_effects = value
	solitaire_reduced_effects = value
	tripeaks_reduced_effects = value
	mahjong_reduced_effects = value
	if game_id == "mahjong":
		state["reduced_effects"] = value
	haptics_enabled = not value
	if reduced_effects:
		catalog_fx.clear()
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	tick += 1
	# Merge 2248 owns an arbitrary-length score string; move count is its safe
	# monotonic pulse signal. Other cartridges retain their numeric score path.
	var current_score := int(state.get("moves", 0)) if game_id == "merge2248" else int(state.get("score", 0))
	if screen == "game" and current_score > last_score:
		score_pulse_until = elapsed + 0.28
	last_score = current_score
	if logger:
		logger.set_tick(tick)
	if screen == "game" and game_id == "snake_classic" and state.get("status", "playing") == "playing":
		_snake_gb_update(delta)
	elif screen == "game" and game_id == "snake_io" and state.get("status", "playing") == "playing":
		_snakes_arena_update(delta)
	elif screen == "game" and game_id == "watermelon" and state.get("status", "playing") == "playing":
		_watermelon_update(delta)
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
	if reduced_effects or _merge2048_effects_reduced() or not haptics_enabled:
		return
	if game_id == "snake_io" and snakes_reduced_effects:
		return
	if game_id == "solitaire":
		if solitaire_reduced_effects:
			return
		solitaire_haptic_emissions += 1
	if game_id == "tripeaks" and tripeaks_reduced_effects:
		return
	if game_id == "tripeaks":
		tripeaks_haptic_emissions += 1
	if game_id == "mahjong" and bool(state.get("reduced_effects", false)):
		return
	haptic_dispatch_count += 1
	haptic_requests_sent += 1
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (navigator.vibrate) navigator.vibrate(%d);" % duration_ms)
	else:
		Input.vibrate_handheld(duration_ms)

func _haptic_pattern(pattern: Array[int]) -> void:
	if pattern.is_empty() or reduced_effects or _merge2048_effects_reduced() or not haptics_enabled:
		return
	if game_id == "snake_io" and snakes_reduced_effects:
		return
	if game_id == "solitaire":
		if solitaire_reduced_effects:
			return
		solitaire_haptic_emissions += 1
	if game_id == "tripeaks" and tripeaks_reduced_effects:
		return
	if game_id == "tripeaks":
		tripeaks_haptic_emissions += 1
	if game_id == "mahjong" and bool(state.get("reduced_effects", false)):
		return
	haptic_dispatch_count += 1
	haptic_requests_sent += 1
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (navigator.vibrate) navigator.vibrate(%s);" % JSON.stringify(pattern))
	else:
		var total_ms := 0
		for interval in pattern:
			total_ms += interval
		Input.vibrate_handheld(mini(total_ms, 180))

func _setup_accessibility_preferences() -> void:
	_detect_reduced_effects()
	reduced_effects_enabled = reduced_effects
	sudoku_reduced_effects = reduced_effects
	haptics_enabled = not reduced_effects

func _impact(position: Vector2, color: Color, strength := 1.0) -> void:
	impact_position = position
	impact_color = color
	impact_strength = minf(strength, 0.28) if _merge2048_effects_reduced() else strength
	impact_until = elapsed + (0.12 if _merge2048_effects_reduced() else 0.34)
	queue_redraw()

func _start_motion(kind: String, from: Vector2, to: Vector2, color: Color, label := "", duration := 0.34, visual_value := 0) -> void:
	motion_kind = kind
	motion_started = elapsed
	motion_duration = duration
	motion_from = from
	motion_to = to
	motion_color = color
	motion_label = label
	motion_value = visual_value
	queue_redraw()

func _start_catalog_event(kind: String, position: Vector2, color: Color, grade := 1, label := "", duration := 0.72, metadata: Dictionary = {}) -> void:
	if game_id in ["merge2248", "snake_classic", "snake_io"]:
		return
	catalog_fx_serial += 1
	var reduced := reduced_effects or _merge2048_effects_reduced() or (game_id == "solitaire" and solitaire_reduced_effects) or (game_id == "tripeaks" and tripeaks_reduced_effects)
	var effective_duration := duration
	if reduced:
		effective_duration = minf(duration, 0.24)
	var effect := {
		"game_id": game_id,
		"kind": kind,
		"position": position,
		"color": color,
		"grade": clampi(grade, 1, 4),
		"label": label,
		"started": elapsed,
		"duration": effective_duration,
		"seed": catalog_fx_serial,
		"reduced": reduced,
	}
	if game_id in ["merge2048", "sudoku", "meowdoku", "solitaire", "tripeaks", "mahjong", "tileclub", "amaze_go", "arrow_go"]:
		effect["font_role"] = "ui_cjk"
	effect.merge(metadata, true)
	if game_id == "solitaire":
		effect["reduced_effects"] = solitaire_reduced_effects
		effect["motion_mode"] = "static_result" if solitaire_reduced_effects else "object_arc"
	catalog_fx.append(effect)
	# The fruit burst is a large transparent texture. Six concurrent envelopes
	# preserve rapid taps and cascades while bounding overdraw on WebGL/Canvas.
	var catalog_fx_cap := 6 if game_id in ["watermelon", "merge2048", "mahjong", "tileclub"] else 12
	while catalog_fx.size() > catalog_fx_cap:
		catalog_fx.pop_front()
	# Reveal flips are visual children of one authoritative clear. They need
	# their own object envelope, but must not multiply audio or haptics.
	if bool(metadata.get("silent", false)):
		queue_redraw()
		return
	var semantic := str(metadata.get("semantic", kind))
	if game_id in ["sudoku", "meowdoku"]:
		_play_logic_event_sfx(semantic, clampi(grade, 1, 4))
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
	elif game_id == "tripeaks" and "reject" in kind:
		var locked_reject := "locked" in kind
		_play_sfx(SFX_SNAKE_REJECT, -15.5, 0.84 if locked_reject else 0.94)
		if locked_reject:
			_haptic_pattern([8, 22, 8])
		else:
			_haptic(10)
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
		var event_sfx := _catalog_event_sfx(kind, event_grade)
		var event_volume := -17.0 + float(event_grade) * 1.5
		var event_pitch := 0.92 + float(event_grade) * 0.09
		if event_sfx == SFX_SOLITAIRE_CARD_SETTLE:
			event_volume = -11.5 + float(event_grade) * 1.1
		elif event_sfx == SFX_TRIPEAKS_STREAK_PEAK:
			event_volume = -12.5 + float(event_grade) * 1.2
		elif event_sfx == SFX_MAHJONG_GAG_PAIR:
			event_volume = -7.0 + float(event_grade)
		elif event_sfx == SFX_TILECLUB_GAG_MATCH:
			event_volume = -7.0 + float(event_grade)
			event_pitch = 0.97 + float(event_grade - 3) * 0.035
		elif event_sfx == SFX_AMAZE_GO_GAG_RATCHET:
			event_volume = -13.5 + float(event_grade) * 0.9
			event_pitch = 0.96 + float(event_grade) * 0.045
		elif event_sfx == SFX_AMAZE_GO_GAG_SEAL:
			event_volume = -7.5
			event_pitch = 1.0
		elif event_sfx == SFX_ARROW_GO_GAG_KITE_STEP:
			event_volume = -3.2 + float(event_grade) * 0.4
			event_pitch = 0.96 + float(event_grade) * 0.055
		elif event_sfx == SFX_ARROW_GO_GAG_HARBOR_DOCK:
			event_volume = -1.0
			event_pitch = 1.0
		elif game_id == "tileclub" and event_sfx == SFX_SNAKE_REJECT:
			event_volume = -15.0 + float(event_grade)
			event_pitch = 0.88 + float(event_grade) * 0.025
		_play_sfx(event_sfx, event_volume, event_pitch)
		if game_id == "tripeaks":
			match kind:
				"card_draw": _haptic(5)
				"card_clear": _haptic(8)
				"card_streak": _haptic_pattern([9 + event_grade * 2, 16, 12 + event_grade * 5])
				"peak_milestone": _haptic_pattern([14, 17, 23, 20, 30])
				"tripeaks_win": _haptic_pattern([16, 15, 22, 15, 36])
				"tripeaks_loss": _haptic_pattern([12, 24, 12])
				_: _haptic(6)
		elif event_grade == 1:
			_haptic(8)
		else:
			_haptic_pattern([10 + event_grade * 4, 16, 18 + event_grade * 9])
	queue_redraw()

func _catalog_event_sfx(kind: String, grade: int) -> AudioStream:
	if game_id == "solitaire" and kind in ["card_draw", "card_recycle", "card_move", "foundation_place", "solitaire_win"]:
		return SFX_SOLITAIRE_CARD_SETTLE
	if game_id == "tripeaks":
		if kind in ["card_clear", "card_streak", "peak_milestone", "tripeaks_win"]:
			return SFX_TRIPEAKS_STREAK_PEAK
		if kind == "tripeaks_loss":
			return SFX_SNAKE_REJECT
		if kind in ["card_draw", "card_reveal"]:
			return SFX_SOLITAIRE_CARD_SETTLE
	if game_id == "mahjong" and kind == "jade_pair":
		return SFX_MAHJONG_GAG_PAIR
	if game_id == "tileclub" and kind in ["stitch_match", "stitch_clear"]:
		return SFX_TILECLUB_GAG_MATCH
	if game_id == "tileclub" and kind in ["stitch_risk", "stitch_tray_full"]:
		return SFX_SNAKE_REJECT
	if game_id == "amaze_go" and kind == "path_step":
		return SFX_AMAZE_GO_GAG_RATCHET
	if game_id == "amaze_go" and kind == "path_complete":
		return SFX_AMAZE_GO_GAG_SEAL
	if game_id == "arrow_go" and kind == "path_step":
		return SFX_ARROW_GO_GAG_KITE_STEP
	if game_id == "arrow_go" and kind == "path_complete":
		return SFX_ARROW_GO_GAG_HARBOR_DOCK
	return SFX_SNAKE_EAT if grade >= 2 else SFX_SNAKE_KEY

func _play_logic_event_sfx(kind: String, grade: int) -> void:
	var pitch := 1.08 if game_id == "meowdoku" else 0.96
	if "error" in kind:
		_play_sfx(SFX_LOGIC_ERROR, -14.0, pitch)
		_haptic_pattern([9, 18, 9])
	elif "complete" in kind and grade >= 4:
		# A quiet folio tone supports the authored game-specific GAG reward without
		# masking its tactile transient and restrained completion chime.
		_play_sfx(SFX_LOGIC_COMPLETE, -22.0, pitch)
		_play_sfx(SFX_MEOW_GAG_COMPLETE if game_id == "meowdoku" else SFX_SUDOKU_GAG_COMPLETE, -10.0, 1.0)
		_haptic_pattern([18, 20, 25, 24, 36])
	elif "block" in kind:
		_play_sfx(SFX_LOGIC_BLOCK, -11.5, pitch)
		_haptic_pattern([13, 18, 22])
	elif "erase" in kind:
		_play_sfx(SFX_LOGIC_SELECT, -18.0, pitch * 0.90)
		_haptic(5)
	else:
		_play_sfx(SFX_LOGIC_CONFIRM, -16.0, pitch)
		_haptic(6)

func _prune_catalog_fx() -> void:
	var active: Array[Dictionary] = []
	for effect in catalog_fx:
		if elapsed - float(effect.get("started", elapsed)) < float(effect.get("duration", 0.72)):
			active.append(effect)
	catalog_fx = active

func _catalog_shake_offset() -> Vector2:
	if reduced_effects or (game_id == "sudoku" and sudoku_reduced_effects) or (game_id == "solitaire" and solitaire_reduced_effects) or (game_id == "tripeaks" and tripeaks_reduced_effects) or (game_id == "mahjong" and bool(state.get("reduced_effects", false))):
		return Vector2.ZERO
	for index in range(catalog_fx.size() - 1, -1, -1):
		var effect: Dictionary = catalog_fx[index]
		if str(effect.get("game_id", "")) == game_id:
			return catalog_art_director.shake_offset(effect, elapsed)
	return Vector2.ZERO

func _catalog_result_overlay_ready() -> bool:
	if reduced_effects or (game_id == "sudoku" and sudoku_reduced_effects) or (game_id == "solitaire" and solitaire_reduced_effects) or (game_id == "tripeaks" and tripeaks_reduced_effects):
		return true
	# Let the authoritative board consequence and its local event read before a
	# terminal modal covers the playfield. Rules already ended the game; this is
	# presentation-only timing and never delays state mutation.
	for index in range(catalog_fx.size() - 1, -1, -1):
		var effect: Dictionary = catalog_fx[index]
		if str(effect.get("game_id", "")) != game_id:
			continue
		var effect_duration := float(effect.get("duration", 0.72))
		var visible_window := minf(0.82, effect_duration)
		if game_id == "solitaire":
			# Preserve the final card's impact and settle before the conservatory
			# result folio covers the table. Reduced-effects mode still resolves
			# quickly because its event duration is capped at 0.24 s.
			visible_window = effect_duration
		if elapsed - float(effect.get("started", elapsed)) < visible_window:
			return false
		break
	return true

func _begin_transition(direction := 1.0) -> void:
	if reduced_effects:
		has_transitioned = false
		return
	screen_transition_started = elapsed
	screen_transition_direction = direction
	has_transitioned = true

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode in [KEY_SPACE, KEY_SHIFT] and screen == "game" and game_id == "snake_io":
		_set_arena_boost_key(event.keycode, event.pressed)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and screen == "game" and game_id == "watermelon":
		if event.keycode in [KEY_LEFT, KEY_A]:
			_watermelon_nudge(-1.0)
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_RIGHT, KEY_D]:
			_watermelon_nudge(1.0)
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_DOWN, KEY_S, KEY_SPACE, KEY_ENTER]:
			_watermelon_drop_current()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and screen == "game" and game_id == "solitaire":
		if _solitaire_key_input(event.keycode):
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and screen == "game" and game_id == "tripeaks":
		if _tripeaks_key_input(event.keycode):
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
		if event.keycode == KEY_U and screen == "game" and game_id == "merge2248":
			_merge2248_undo()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_M and screen == "game" and game_id == "merge2248":
			_merge2248_cycle_mode()
			get_viewport().set_input_as_handled()
			return
		if screen != "game":
			return
		if game_id == "meowdoku":
			var meow_command := ""
			if event.keycode in [KEY_UP, KEY_W]:
				_meowdoku_move_selection(Vector2i.UP)
			elif event.keycode in [KEY_DOWN, KEY_S]:
				_meowdoku_move_selection(Vector2i.DOWN)
			elif event.keycode in [KEY_LEFT, KEY_A]:
				_meowdoku_move_selection(Vector2i.LEFT)
			elif event.keycode in [KEY_RIGHT, KEY_D]:
				_meowdoku_move_selection(Vector2i.RIGHT)
			elif event.keycode in [KEY_SPACE, KEY_X]:
				meow_command = "mark"
			elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_C]:
				meow_command = "cat"
			elif event.keycode in [KEY_BACKSPACE, KEY_DELETE]:
				meow_command = "erase"
			else:
				return
			if not meow_command.is_empty():
				_meowdoku_command(meow_command)
			get_viewport().set_input_as_handled()
			return
		if game_id == "sudoku":
			if (event.ctrl_pressed or event.meta_pressed) and event.keycode == KEY_Z:
				_sudoku_undo()
			elif event.keycode in [KEY_UP, KEY_W]:
				_sudoku_move_selection(Vector2i.UP)
			elif event.keycode in [KEY_DOWN, KEY_S]:
				_sudoku_move_selection(Vector2i.DOWN)
			elif event.keycode in [KEY_LEFT, KEY_A]:
				_sudoku_move_selection(Vector2i.LEFT)
			elif event.keycode in [KEY_RIGHT, KEY_D]:
				_sudoku_move_selection(Vector2i.RIGHT)
			elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
				_sudoku_place(event.keycode - KEY_0)
			elif event.keycode in [KEY_0, KEY_BACKSPACE, KEY_DELETE]:
				_sudoku_place(0)
			elif event.keycode == KEY_N:
				_sudoku_toggle_notes()
			elif event.keycode == KEY_H:
				_sudoku_hint()
			else:
				return
			get_viewport().set_input_as_handled()
			return
		if game_id == "mahjong" and _mahjong_keyboard_input(event.keycode):
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_UP, KEY_W] or (game_id == "merge2048" and event.keycode == KEY_K):
			_direction_input(Vector2i.UP)
		elif event.keycode in [KEY_DOWN, KEY_S] or (game_id == "merge2048" and event.keycode == KEY_J):
			_direction_input(Vector2i.DOWN)
		elif event.keycode in [KEY_LEFT, KEY_A] or (game_id == "merge2048" and event.keycode == KEY_H):
			_direction_input(Vector2i.LEFT)
		elif event.keycode in [KEY_RIGHT, KEY_D] or (game_id == "merge2048" and event.keycode == KEY_L):
			_direction_input(Vector2i.RIGHT)
		elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
			_sudoku_place(event.keycode - KEY_0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pointer_down = event.position
			if screen == "game" and game_id == "meowdoku" and event.double_click:
				_meowdoku_pointer_action(event.position, true)
				meowdoku_double_action_consumed = true
			elif screen == "game" and game_id == "merge2248" and _merge2248_begin_at(event.position):
				merge2248_drag_active = true
			elif screen == "game" and game_id == "snake_classic":
				_snake_begin_drag(event.position)
			elif screen == "game" and game_id == "snake_io":
				_snakes_arena_begin_pointer(event.position)
			elif screen == "game" and game_id == "watermelon" and _watermelon_board_rect().has_point(event.position):
				_watermelon_aim_at(event.position.x)
		else:
			var swipe_delta: Vector2 = event.position - pointer_down
			if game_id == "meowdoku" and meowdoku_double_action_consumed:
				meowdoku_double_action_consumed = false
			elif game_id == "merge2248" and merge2248_drag_active:
				_merge2248_extend_at(event.position)
				_merge2248_release()
				merge2248_drag_active = false
			elif game_id == "snake_classic" and snake_drag_active:
				_snake_end_drag(event.position)
			elif game_id == "snake_io":
				_snakes_arena_end_pointer(event.position)
			elif game_id == "watermelon" and _watermelon_board_rect().has_point(pointer_down):
				_watermelon_drop_at(event.position.x)
			elif pointer_down.x >= 0.0 and swipe_delta.length() > MERGE2048_SWIPE_THRESHOLD and game_id == "merge2048":
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
		elif snake_drag_active and game_id == "snake_classic":
			_snake_drag_to(event.position)
		elif arena_pointer_active and game_id == "snake_io":
			_snakes_arena_aim_at_screen(event.position)
		elif game_id == "watermelon" and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _watermelon_board_rect().has_point(pointer_down):
			_watermelon_aim_at(event.position.x)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		pointer_down = event.position
		if screen == "game" and game_id == "meowdoku" and event.double_tap:
			_meowdoku_pointer_action(event.position, true)
			meowdoku_double_action_consumed = true
		elif screen == "game" and game_id == "merge2248" and _merge2248_begin_at(event.position):
			merge2248_drag_active = true
		elif screen == "game" and game_id == "snake_classic":
			_snake_begin_drag(event.position)
		elif screen == "game" and game_id == "snake_io":
			_snakes_arena_begin_pointer(event.position)
		elif screen == "game" and game_id == "watermelon" and _watermelon_board_rect().has_point(event.position):
			_watermelon_aim_at(event.position.x)
	elif event is InputEventScreenTouch and not event.pressed:
		if game_id == "meowdoku" and meowdoku_double_action_consumed:
			meowdoku_double_action_consumed = false
		elif game_id == "merge2248" and merge2248_drag_active:
			_merge2248_extend_at(event.position)
			_merge2248_release()
			merge2248_drag_active = false
		elif game_id == "snake_classic" and snake_drag_active:
			_snake_end_drag(event.position)
		elif game_id == "snake_io":
			_snakes_arena_end_pointer(event.position)
		elif game_id == "watermelon" and _watermelon_board_rect().has_point(pointer_down):
			_watermelon_drop_at(event.position.x)
		elif game_id == "merge2048" and pointer_down.x >= 0.0:
			var swipe_delta: Vector2 = event.position - pointer_down
			if swipe_delta.length() > MERGE2048_SWIPE_THRESHOLD:
				if abs(swipe_delta.x) > abs(swipe_delta.y):
					_merge_move(Vector2i.RIGHT if swipe_delta.x > 0 else Vector2i.LEFT)
				else:
					_merge_move(Vector2i.DOWN if swipe_delta.y > 0 else Vector2i.UP)
			pointer_down = Vector2(-1, -1)
		else:
			_handle_tap(event.position)
	elif event is InputEventScreenDrag:
		if game_id == "merge2248" and merge2248_drag_active:
			_merge2248_extend_at(event.position)
		elif game_id == "snake_classic" and snake_drag_active:
			_snake_drag_to(event.position)
		elif game_id == "snake_io":
			_snakes_arena_aim_at_screen(event.position)
		elif game_id == "watermelon" and _watermelon_board_rect().has_point(pointer_down):
			_watermelon_aim_at(event.position.x)

func _build_home() -> void:
	var leaving_mahjong := screen == "game" and game_id == "mahjong"
	if game_id == "snake_io":
		_clear_arena_boost_requests()
	if leaving_mahjong:
		_clear_mahjong_session()
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
	last_score = int(state.get("moves", 0)) if game_id == "merge2248" else int(state.get("score", 0))
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
		"merge2248":
			_add_button("难度 · %s" % _merge2248_mode_label(), Rect2(16, 878, 96, 44), Callable(self, "_merge2248_cycle_mode"), Color("23585a"), 12)
			_add_button("撤销", Rect2(444, 878, 80, 44), Callable(self, "_merge2248_undo"), Color("23585a"), 13)
		"merge2048":
			if state.get("status", "playing") == "won":
				_add_button("继续挑战", Rect2(184, 826, 172, 56), Callable(self, "_merge2048_continue"), GOLD, 16)
			else:
				_add_button("左", Rect2(170, 826, 58, 52), Callable(self, "_merge_move").bind(Vector2i.LEFT), SURFACE_2, 16)
				_add_button("下", Rect2(241, 878, 58, 52), Callable(self, "_merge_move").bind(Vector2i.DOWN), SURFACE_2, 16)
				_add_button("上", Rect2(241, 826, 58, 52), Callable(self, "_merge_move").bind(Vector2i.UP), SURFACE_2, 16)
				_add_button("右", Rect2(312, 826, 58, 52), Callable(self, "_merge_move").bind(Vector2i.RIGHT), SURFACE_2, 16)
		"watermelon":
			_add_button("拖动瞄准 · 松手投放", Rect2(158, 878, 224, 52), Callable(self, "_water_drop_hint"), SURFACE_2, 14)
		"sudoku":
			var undo_button := _add_button("撤销", Rect2(34, 724, 106, 46), Callable(self, "_sudoku_undo"), SURFACE_2, 14)
			undo_button.name = "SudokuUndo"
			var erase_button := _add_button("擦除", Rect2(150, 724, 106, 46), Callable(self, "_sudoku_place").bind(0), SURFACE_2, 14)
			erase_button.name = "SudokuErase"
			var notes_label := "笔记 · %s" % ("开" if bool(state.get("notes_mode", false)) else "关")
			var notes_button := _add_button(notes_label, Rect2(266, 724, 106, 46), Callable(self, "_sudoku_toggle_notes"), SURFACE_2, 14)
			notes_button.name = "SudokuNotes"
			var hint_button := _add_button("提示 · %d" % int(state.get("hints_remaining", 0)), Rect2(382, 724, 124, 46), Callable(self, "_sudoku_hint"), SURFACE_2, 14)
			hint_button.name = "SudokuHint"
			for n in range(1, 10):
				var digit_button := _add_button(str(n), Rect2(30 + (n - 1) * 53, 784, 47, 52), Callable(self, "_sudoku_place").bind(n), SURFACE_2, 17)
				digit_button.name = "SudokuDigit%d" % n
		"meowdoku":
			_add_button("标记 ×", Rect2(90, 804, 104, 52), Callable(self, "_meowdoku_command").bind("mark"), SURFACE_2, 14)
			_add_button("放置猫", Rect2(218, 804, 104, 52), Callable(self, "_meowdoku_command").bind("cat"), SURFACE_2, 14)
			_add_button("清除", Rect2(346, 804, 104, 52), Callable(self, "_meowdoku_command").bind("erase"), SURFACE_2, 14)
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
		"mahjong":
			_add_button("洗牌", Rect2(35, 810, 104, 50), Callable(self, "_mahjong_shuffle"), SURFACE_2, 14)
			_add_button("提示", Rect2(157, 810, 104, 50), Callable(self, "_mahjong_hint"), SURFACE_2, 14)
			_add_button("撤销", Rect2(279, 810, 104, 50), Callable(self, "_mahjong_undo"), SURFACE_2, 14)
			_add_button("低动态开" if mahjong_reduced_effects else "低动态关", Rect2(401, 810, 104, 50), Callable(self, "_toggle_mahjong_reduced"), SURFACE_2, 12)
		"tileclub":
			_add_button("槽位规则", Rect2(202, 816, 136, 52), Callable(self, "_tileclub_tray_hint"), SURFACE_2, 15)
		"amaze_go", "arrow_go", "amaze":
			_add_button("路线提示", Rect2(202, 816, 136, 52), Callable(self, "_amaze_hint"), SURFACE_2, 15)

func _reset_current() -> void:
	if game_id.is_empty():
		return
	catalog_fx.clear()
	rng.seed = abs(game_id.hash()) + 17
	if game_id == "merge2048":
		merge2048_force_new_run = true
	if game_id == "meowdoku":
		meowdoku_skip_recovery_once = true
	if game_id == "sudoku":
		sudoku_restart_requested = true
		_clear_sudoku_web_snapshot()
	if game_id == "snake_classic":
		_clear_snake_gb_web_recovery()
	if game_id == "snake_io":
		arena_restart_requested = true
		_clear_snakes_web_snapshot()
	if game_id == "solitaire":
		solitaire_restart_requested = true
		_clear_solitaire_web_snapshot()
	if game_id == "tripeaks":
		tripeaks_restart_requested = true
		_clear_tripeaks_snapshot()
	_start_game_state(true)
	sudoku_restart_requested = false
	arena_restart_requested = false
	solitaire_restart_requested = false
	tripeaks_restart_requested = false
	if game_id == "merge2048":
		_build_game_buttons()
	if game_id == "sudoku":
		_update_sudoku_tool_buttons()
	_log_event("game_reset", {"game_id":game_id})
	_capture("reset_%s" % game_id)
	if game_id == "snake_classic":
		snake_reset_started = elapsed
		_play_sfx(SFX_SNAKE_KEY, -8.0)
	elif game_id == "snake_io":
		arena_reset_started = elapsed
		_play_sfx(SFX_CASE_OPEN, -12.0, 1.14)
		_persist_snakes_progress()
	elif game_id == "solitaire":
		_persist_solitaire_progress()
		_flash_feedback("新牌局已发好", GREEN)
	elif game_id == "tripeaks":
		_persist_tripeaks_progress()
		_flash_feedback("新牌局已发好", GREEN)
	else:
		_flash_feedback("新局开始", GREEN)
	if game_id == "mahjong":
		_persist_mahjong_session()
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
	var sudoku_control := action_control and game_id == "sudoku"
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
	elif sudoku_control:
		var control_ink := Color("343b4b")
		normal = _button_style(Color("eee4d1"), Color(effective_accent, 0.48), 5, 1)
		hover = _button_style(Color("fff8e9"), Color(effective_accent, 0.94), 5, 2)
		pressed = _button_style(Color("dac49d"), Color("9a743b"), 4, 2)
		focus = _button_style(Color("fff8e9"), Color("c49c59"), 5, 2)
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
		"sudoku": return Color("eee4d1")
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
	if screen != "game" or state.get("status", "playing") in ["won", "lost", "over"]:
		return
	match game_id:
		"watermelon":
			if _watermelon_board_rect().has_point(pos):
				_watermelon_drop_at(pos.x)
		"sudoku": _sudoku_tap(pos)
		"meowdoku": _meowdoku_pointer_action(pos, false)
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
	elif game_id == "meowdoku":
		_meowdoku_move_selection(direction)

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
	if game_id == "snake_io":
		snapshot["shell_tick"] = tick
	else:
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
	if OS.has_feature("web") and str(snapshot.get("game_id", "")) == "sudoku":
		var payload := JSON.stringify(snapshot)
		JavaScriptBridge.eval("window.localStorage.setItem('offline-games-sudoku-v3', %s);" % JSON.stringify(payload))
	if OS.has_feature("web") and str(snapshot.get("game_id", "")) == "snake_classic":
		var encoded := JSON.stringify(snapshot)
		JavaScriptBridge.eval("try { localStorage.setItem(%s, %s); true; } catch (_error) { false; }" % [JSON.stringify(SNAKE_GB_WEB_STORAGE_KEY), JSON.stringify(encoded)])
	if OS.has_feature("web") and str(snapshot.get("game_id", "")) == "snake_io":
		if str(snapshot.get("phase", "")) == "running" and str(snapshot.get("status", "")) == "playing":
			var arena_payload := JSON.stringify(snapshot)
			JavaScriptBridge.eval("window.localStorage.setItem('offline-games-snakes-v3', %s);" % JSON.stringify(arena_payload))
		else:
			_clear_snakes_web_snapshot()
	if OS.has_feature("web") and str(snapshot.get("game_id", "")) == "solitaire":
		if str(snapshot.get("status", "")) == "playing":
			var solitaire_payload := JSON.stringify(snapshot)
			JavaScriptBridge.eval("window.localStorage.setItem('offline-games-solitaire-v3', %s);" % JSON.stringify(solitaire_payload))
		else:
			_clear_solitaire_web_snapshot()
	if str(snapshot.get("game_id", "")) == "tripeaks":
		if str(snapshot.get("status", "")) == "playing":
			_store_tripeaks_snapshot(snapshot)
		else:
			_clear_tripeaks_snapshot()
	if OS.has_feature("web") and str(snapshot.get("game_id", "")) == "mahjong":
		var mahjong_encoded := JSON.stringify(JSON.stringify(snapshot))
		JavaScriptBridge.eval("localStorage.setItem('offline-games-mahjong-v3', %s);" % mahjong_encoded)

func _load_sudoku_web_snapshot() -> Dictionary:
	if not OS.has_feature("web"):
		return {}
	var raw: Variant = JavaScriptBridge.eval("window.localStorage.getItem('offline-games-sudoku-v3') || '';" )
	if not raw is String or str(raw).is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(str(raw))
	if parsed is Dictionary and str(parsed.get("game_id", "")) == "sudoku":
		return parsed
	return {}

func _clear_sudoku_web_snapshot() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.localStorage.removeItem('offline-games-sudoku-v3');")

func _persist_sudoku_progress() -> void:
	if game_id != "sudoku" or not OS.has_feature("web"):
		return
	var snapshot := state.duplicate(true)
	snapshot["game_id"] = game_id
	snapshot["screen"] = screen
	snapshot["tick"] = tick
	_save_snapshot(snapshot)

func _load_snakes_web_snapshot() -> Dictionary:
	if not OS.has_feature("web"):
		return {}
	var raw: Variant = JavaScriptBridge.eval("window.localStorage.getItem('offline-games-snakes-v3') || '';" )
	if not raw is String or str(raw).is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(str(raw))
	if parsed is Dictionary and str(parsed.get("game_id", "")) == "snake_io" and str(parsed.get("schema", "")) == "snakes-arena-state/v1":
		return parsed
	return {}

func _clear_snakes_web_snapshot() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.localStorage.removeItem('offline-games-snakes-v3');")

func _persist_snakes_progress() -> void:
	if game_id != "snake_io" or not OS.has_feature("web"):
		return
	var snapshot := state.duplicate(true)
	snapshot["game_id"] = game_id
	snapshot["screen"] = screen
	snapshot["shell_tick"] = tick
	_save_snapshot(snapshot)

func _load_solitaire_web_snapshot() -> Dictionary:
	if not OS.has_feature("web"):
		return {}
	var raw: Variant = JavaScriptBridge.eval("window.localStorage.getItem('offline-games-solitaire-v3') || '';" )
	if not raw is String or str(raw).is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(str(raw))
	if parsed is Dictionary and str(parsed.get("game_id", "")) == "solitaire" and str(parsed.get("schema", "")) == "solitaire-state/v1":
		return parsed
	return {}

func _clear_solitaire_web_snapshot() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.localStorage.removeItem('offline-games-solitaire-v3');")

func _persist_solitaire_progress() -> void:
	if game_id != "solitaire":
		return
	var snapshot := state.duplicate(true)
	snapshot["game_id"] = game_id
	snapshot["screen"] = screen
	snapshot["shell_tick"] = tick
	_save_snapshot(snapshot)

func _load_tripeaks_snapshot() -> Dictionary:
	var raw := ""
	if OS.has_feature("web"):
		var web_raw: Variant = JavaScriptBridge.eval("window.localStorage.getItem('offline-games-tripeaks-v3') || '';" )
		if web_raw is String:
			raw = str(web_raw)
	elif FileAccess.file_exists("user://offline_games_tripeaks_v3.json"):
		var file := FileAccess.open("user://offline_games_tripeaks_v3.json", FileAccess.READ)
		if file:
			raw = file.get_as_text()
	if raw.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary and str(parsed.get("game_id", "")) == "tripeaks" and str(parsed.get("schema", "")) == TRIPEAKS_RULES.SCHEMA:
		return parsed
	return {}

func _store_tripeaks_snapshot(snapshot: Dictionary) -> void:
	var payload := JSON.stringify(snapshot)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.localStorage.setItem('offline-games-tripeaks-v3', %s);" % JSON.stringify(payload))
	else:
		var file := FileAccess.open("user://offline_games_tripeaks_v3.json", FileAccess.WRITE)
		if file:
			file.store_string(payload)

func _clear_tripeaks_snapshot() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.localStorage.removeItem('offline-games-tripeaks-v3');")
	var path := ProjectSettings.globalize_path("user://offline_games_tripeaks_v3.json")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func _persist_tripeaks_progress() -> void:
	if game_id != "tripeaks":
		return
	var snapshot := state.duplicate(true)
	snapshot["game_id"] = game_id
	snapshot["screen"] = screen
	snapshot["shell_tick"] = tick
	_save_snapshot(snapshot)

func _load_snake_gb_web_recovery() -> Dictionary:
	if not OS.has_feature("web"):
		return {}
	var raw: Variant = JavaScriptBridge.eval("(function(){ try { return localStorage.getItem(%s) || ''; } catch (_error) { return ''; } })()" % JSON.stringify(SNAKE_GB_WEB_STORAGE_KEY))
	if not raw is String or str(raw).is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(str(raw))
	if parsed is Dictionary and str(parsed.get("game_id", "")) == "snake_classic":
		return parsed
	return {}

func _restore_snake_gb_snapshot(candidate: Dictionary) -> bool:
	if candidate.is_empty() or not snake_gb_model.restore(candidate):
		return false
	_sync_snake_gb_state()
	return true

func _clear_snake_gb_web_recovery() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try { localStorage.removeItem(%s); true; } catch (_error) { false; }" % JSON.stringify(SNAKE_GB_WEB_STORAGE_KEY))

func _read_solitaire_effect_preference() -> void:
	if OS.has_feature("web"):
		var reduced: Variant = JavaScriptBridge.eval("window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 1 : 0", true)
		solitaire_reduced_effects = reduced_effects or int(reduced) == 1
	else:
		solitaire_reduced_effects = reduced_effects

func _set_solitaire_reduced_effects(enabled: bool) -> void:
	solitaire_reduced_effects = enabled
	if game_id == "solitaire":
		_sync_solitaire_state()
		_publish_web_state()
		queue_redraw()

func _read_tripeaks_effect_preference() -> void:
	if OS.has_feature("web"):
		var reduced: Variant = JavaScriptBridge.eval("window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 1 : 0", true)
		tripeaks_reduced_effects = reduced_effects or int(reduced) == 1
	else:
		tripeaks_reduced_effects = reduced_effects

func _set_tripeaks_reduced_effects(enabled: bool) -> void:
	tripeaks_reduced_effects = enabled
	if enabled:
		catalog_fx = catalog_fx.filter(func(effect: Dictionary): return str(effect.get("game_id", "")) != "tripeaks")
	if game_id == "tripeaks":
		_sync_tripeaks_state()
		_publish_web_state()
		queue_redraw()

func _persist_mahjong_session() -> void:
	if game_id != "mahjong" or screen != "game":
		return
	var snapshot := state.duplicate(true)
	snapshot["game_id"] = "mahjong"
	snapshot["screen"] = "game"
	snapshot["tick"] = tick
	_save_snapshot(snapshot)
	_publish_web_state()

func _try_restore_mahjong_session() -> bool:
	var raw := ""
	if OS.has_feature("web"):
		raw = str(JavaScriptBridge.eval("localStorage.getItem('offline-games-mahjong-v3') || ''"))
	elif FileAccess.file_exists("user://offline_games_state.json"):
		var file := FileAccess.open("user://offline_games_state.json", FileAccess.READ)
		if file:
			raw = file.get_as_text()
	if raw.is_empty():
		return false
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		return false
	var candidate: Dictionary = parsed
	if str(candidate.get("game_id", "")) != "mahjong" or str(candidate.get("screen", "")) != "game":
		return false
	if not mahjong_model.restore(candidate):
		return false
	game_id = "mahjong"
	screen = "game"
	mahjong_reduced_effects = bool(candidate.get("reduced_effects", false))
	mahjong_focus = int(candidate.get("focus", mahjong_model.first_focus()))
	if not mahjong_model.is_active(mahjong_focus):
		mahjong_focus = mahjong_model.first_focus()
	mahjong_object_fx = {}
	_sync_mahjong_state(false)
	last_score = int(state.get("score", 0))
	_begin_transition(1.0)
	_build_game_buttons()
	_flash_feedback("牌局已恢复", MINT)
	return true

func _clear_mahjong_session() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("localStorage.removeItem('offline-games-mahjong-v3');")
	if FileAccess.file_exists("user://offline_games_state.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://offline_games_state.json"))

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
			watermelon_presenter.draw_fruit(self, center, 3, 14.0 * scale, elapsed, [], false)
		"meowdoku":
			meowdoku_presenter.draw_header_badge(self, center, r * 2.15)
		"sudoku":
			logic_game_presenter.draw_header_badge(self, id, center, r * 2.15)
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
		"sudoku": _draw_sudoku()
		"meowdoku": _draw_meowdoku()
		"snake_io": pass
		"solitaire": _draw_solitaire()
		"tripeaks": _draw_tripeaks()
		"mahjong": _draw_mahjong()
		"tileclub": _draw_tileclub()
		"amaze_go", "arrow_go", "amaze": _draw_amaze()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state.get("status", "playing") in ["over", "lost"] and _catalog_result_overlay_ready():
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
	_draw_card_game_object_fx()
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
	var catalog_motion_reduced := reduced_effects or (game_id == "sudoku" and sudoku_reduced_effects) or (game_id == "solitaire" and solitaire_reduced_effects) or (game_id == "tripeaks" and tripeaks_reduced_effects)
	if catalog_motion_reduced and game_id != "mahjong":
		return
	for effect in catalog_fx:
		if str(effect.get("game_id", "")) != game_id:
			continue
		if game_id == "solitaire" and bool(effect.get("reduced_effects", false)):
			continue
		if game_id == "tripeaks" and tripeaks_reduced_effects:
			continue
		if game_id == "mahjong" and (reduced_effects or bool(state.get("reduced_effects", false))):
			_draw_mahjong_reduced_catalog_event(effect)
		else:
			var event_label_font: Font = UI_FONT if game_id == "solitaire" else DISPLAY_FONT
			catalog_art_director.draw_event_fx(self, effect, elapsed, event_label_font, SYMBOL_FONT)

func _draw_mahjong_reduced_catalog_event(effect: Dictionary) -> void:
	# Reduced effects keep the semantic result at the affected object while
	# removing ring travel, particle drift, camera shake and haptics. Opacity is
	# the only changing visual channel; the mark never changes position or size.
	var duration := maxf(0.01, float(effect.get("duration", 0.72)))
	var progress := clampf((elapsed - float(effect.get("started", elapsed))) / duration, 0.0, 1.0)
	var alpha := 1.0 - smoothstep(0.62, 1.0, progress)
	var position: Vector2 = effect.get("position", Vector2(270, 458))
	var color: Color = effect.get("color", MINT)
	var grade := clampi(int(effect.get("grade", 1)), 1, 4)
	var negative := "reject" in str(effect.get("kind", "")) or "mismatch" in str(effect.get("kind", ""))
	var radius := 15.0 + float(grade) * 2.5
	draw_circle(position, radius + 5.0, Color("09251f", 0.62 * alpha))
	draw_circle(position, radius, Color(color, 0.16 * alpha))
	draw_arc(position, radius, 0, TAU, 28, Color(color, 0.78 * alpha), 2.5, true)
	if negative:
		draw_line(position - Vector2(7, 7), position + Vector2(7, 7), Color(color, 0.90 * alpha), 2.5, true)
		draw_line(position + Vector2(-7, 7), position + Vector2(7, -7), Color(color, 0.90 * alpha), 2.5, true)
	else:
		draw_line(position + Vector2(-7, 0), position + Vector2(-2, 6), Color(color, 0.90 * alpha), 2.5, true)
		draw_line(position + Vector2(-2, 6), position + Vector2(9, -7), Color(color, 0.90 * alpha), 2.5, true)
	var label := str(effect.get("label", ""))
	if not label.is_empty():
		_draw_center_font(UI_FONT, label, position + Vector2(0, -radius - 13.0), 12, Color("f7f0d9", 0.92 * alpha))

func _draw_score_panel() -> void:
	if game_id == "meowdoku":
		_draw_meowdoku_score_panel()
		return
	var candy_mode := game_id == "merge2248"
	var panel_fill := _game_panel_fill()
	var panel_border := Color("f3d59d", 0.30) if candy_mode else Color(INK, 0.09)
	var secondary_text := _game_secondary_text()
	_draw_panel(Rect2(18, 124, 504, 52), panel_fill, panel_border, 10, 1)
	var compact := state.has("mistakes")
	_draw_text("得分", Vector2(31, 142), 10, secondary_text)
	var score_scale := 1.0 + (0.16 * clampf((score_pulse_until - elapsed) / 0.28, 0.0, 1.0))
	if candy_mode and _merge2248_reduced_effects_active():
		score_scale = 1.0
	var score_color := INK
	if candy_mode and not _merge2248_reduced_effects_active():
		var score_age := elapsed - merge2248_score_started
		var score_duration := 0.30 + float(merge2248_score_grade) * 0.07
		if score_age >= 0.0 and score_age < score_duration:
			var score_t := clampf(score_age / score_duration, 0.0, 1.0)
			var score_kick := sin(score_t * PI) * (0.04 + float(merge2248_score_grade) * 0.025)
			score_scale += score_kick
			score_color = _merge2248_grade_color(merge2248_score_grade).lerp(INK, score_t)
	var score_text := str(state.get("score_label", "0")) if candy_mode else str(int(state.get("score", 0)))
	var score_font_size := 17 if candy_mode and score_text.length() > 7 else 21
	_draw_center_font(NUMBER_FONT, score_text, Vector2(72, 159), int(score_font_size * score_scale), score_color)
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


func _draw_meowdoku_score_panel() -> void:
	var panel_fill := Color("6b3854", 0.96)
	_draw_panel(Rect2(18, 124, 504, 52), panel_fill, Color("ffe9f3", 0.18), 12, 1)
	_draw_text("关卡", Vector2(31, 142), 10, Color("f2dbe8", 0.82))
	_draw_center_font(NUMBER_FONT, str(int(state.get("level", 1))), Vector2(70, 159), 20, INK)
	draw_line(Vector2(108, 134), Vector2(108, 166), Color(INK, 0.12), 1.0)
	_draw_text("猫咪", Vector2(124, 142), 10, Color("f2dbe8", 0.82))
	_draw_center_font(NUMBER_FONT, "%d/%d" % [int(state.get("placed", 0)), int(state.get("required", 0))], Vector2(174, 159), 19, INK)
	draw_line(Vector2(220, 134), Vector2(220, 166), Color(INK, 0.12), 1.0)
	_draw_text("局势", Vector2(236, 142), 10, Color("f2dbe8", 0.82))
	_draw_text(_status_label(), Vector2(236, 162), 12, _status_color())
	draw_line(Vector2(312, 134), Vector2(312, 166), Color(INK, 0.12), 1.0)
	_draw_text("机会", Vector2(328, 142), 10, Color("f2dbe8", 0.82))
	var hearts := int(state.get("hearts", 0))
	for index in range(3):
		_draw_text_font(SYMBOL_FONT, "♥", Vector2(376 + index * 30, 162), 20, Color("ff7899") if index < hearts else Color("d7b3c1", 0.42))
	_draw_text("错误 %d" % int(state.get("mistakes", 0)), Vector2(472, 158), 10, Color("ffd6e1") if int(state.get("mistakes", 0)) > 0 else Color("d9f5df"))

func _objective_status() -> String:
	match game_id:
		"merge2248": return "历史 %s · %s" % [str(state.get("all_time_label", "0")), _merge2248_mode_label()]
		"merge2048": return "最佳 %d · 目标 2048" % int(state.get("best", 0))
		"watermelon": return "目标 %d" % int(state.get("target_value", 256))
		"meowdoku": return "猫咪 %d / %d" % [int(state.get("placed", 0)), int(state.get("required", 0))]
		"snake_classic": return "长度 %d · 无尽模式" % int(state.get("score", 4))
		"snake_io": return "位次 #%d · 体量 %.1f" % [max(1, int(state.get("rank", 1))), float(state.get("mass", 0.0))]
		"solitaire": return "牌库 %d · 归位 %d/52" % [state.get("stock", []).size(), int(state.get("foundation_total", 0))]
		"tripeaks": return "余牌 %d · 峰顶 %d/3" % [state.get("stock", []).size(), int(state.get("peak_count", 0))]
		"mahjong": return "待配 %d" % int(state.get("remaining", 0))
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
	if game_id == "merge2048" and won:
		draw_rect(Rect2(0, 112, 540, 848), Color("21150e", 0.72))
		_draw_panel(Rect2(54, 344, 432, 246), Color("0f0804", 0.34), Color.TRANSPARENT, 18, 0)
		_draw_panel(Rect2(48, 338, 444, 246), Color("f1d7a5"), Color("d99b43", 0.94), 16, 3)
		for shaving in range(9):
			var angle := float(shaving) * TAU / 9.0
			var shaving_center := Vector2(270, 386) + Vector2.from_angle(angle) * 42.0
			draw_arc(shaving_center, 7.0, angle, angle + PI * 0.72, 10, Color("9b592c", 0.68), 2.0)
		_draw_center_font(TILE_NUMBER_FONT, "2048", Vector2(270, 404), 38, Color("5a2f1c"))
		_draw_center_font(DISPLAY_FONT, "经典目标达成", Vector2(270, 458), 27, Color("4b2b1d"))
		_draw_center_font(UI_FONT, "得分 %d · 最佳 %d" % [int(state.get("score", 0)), int(state.get("best", 0))], Vector2(270, 500), 16, Color("5c3a29"))
		_draw_center_font(UI_FONT, "可以继续合并，冲击更高数字", Vector2(270, 542), 13, Color("6a4935"))
		return
	if game_id == "meowdoku":
		var edge := Color("efba59") if won else Color("d9587b")
		var ink := Color("4b2940")
		draw_rect(Rect2(0, 112, 540, 848), Color("231421", 0.62))
		_draw_panel(Rect2(54, 344, 432, 248), Color("17131a", 0.28), Color.TRANSPARENT, 18, 0)
		_draw_panel(Rect2(48, 338, 444, 250), Color("fff1f7"), Color(edge, 0.94), 20, 3)
		draw_line(Vector2(74, 356), Vector2(466, 356), Color("ffffff", 0.72), 2.0, true)
		meowdoku_presenter.draw_result_badge(self, Vector2(270, 390), won)
		_draw_center_font(DISPLAY_FONT, "猫咪全员到齐" if won else "爱心用尽", Vector2(270, 456), 29, ink if won else Color("9d2e50"))
		_draw_center_font(UI_FONT, "找到 %d/%d 只 · 还剩 %d 颗心" % [int(state.get("placed", 0)), int(state.get("required", 0)), int(state.get("hearts", 0))], Vector2(270, 498), 15, Color(ink, 0.86))
		_draw_center_font(UI_FONT, "点击右上角“重开”再试一次", Vector2(270, 544), 13, Color(ink, 0.68))
		return
	if game_id == "sudoku":
		var paper := Color("faf3e4")
		var edge := Color("b78f55")
		var ink := Color("303745")
		draw_rect(Rect2(0, 112, 540, 848), Color("24221f", 0.56))
		_draw_panel(Rect2(54, 344, 432, 236), Color("17131a", 0.26), Color.TRANSPARENT, 18, 0)
		_draw_panel(Rect2(48, 338, 444, 238), paper, Color(edge, 0.92), 8, 3)
		draw_line(Vector2(74, 356), Vector2(466, 356), Color("ffffff", 0.72), 2.0, true)
		logic_game_presenter.draw_result_badge(self, game_id, Vector2(270, 384))
		_draw_center_font(DISPLAY_FONT, "逻辑完成", Vector2(270, 438), 30, ink)
		_draw_center_font(UI_FONT, "得分 %d · 步数 %d" % [int(state.get("score", 0)), int(state.get("moves", 0))], Vector2(270, 480), 16, Color(ink, 0.88))
		_draw_center_font(UI_FONT, "点击右上角“重开”继续挑战", Vector2(270, 526), 13, Color(ink, 0.68))
		return
	if game_id == "mahjong":
		draw_rect(Rect2(0, 112, 540, 848), Color("061b17", 0.68))
		_draw_panel(Rect2(54, 344, 432, 236), Color("03110e", 0.34), Color.TRANSPARENT, 12, 0)
		_draw_panel(Rect2(48, 338, 444, 238), Color("f5eed8"), Color("69caaa", 0.94), 10, 3)
		draw_line(Vector2(70, 356), Vector2(470, 356), Color("ffffff", 0.78), 2.0, true)
		_draw_mahjong_tile(Rect2(239, 350, 62, 82), 5)
		_draw_center_font(DISPLAY_FONT, "玉阵完成", Vector2(270, 456), 29, Color("19483e"))
		_draw_center_font(UI_FONT, "得分 %d · 步数 %d" % [int(state.get("score", 0)), int(state.get("moves", 0))], Vector2(270, 493), 16, Color("24594d"))
		_draw_center_font(UI_FONT, "点击右上角“重开”继续挑战", Vector2(270, 536), 13, Color("4d6f66"))
		return
	if game_id == "tileclub":
		var success := won
		var thread_color := Color("65dcb6") if success else Color("f06a91")
		var cloth_ink := Color("43263a")
		draw_rect(Rect2(0, 112, 540, 848), Color("261320", 0.70))
		_draw_panel(Rect2(55, 345, 430, 244), Color("160d15", 0.38), Color.TRANSPARENT, 18, 0)
		_draw_panel(Rect2(48, 338, 444, 244), Color("fff0cf"), Color(thread_color, 0.94), 16, 3)
		var stitch_rect := Rect2(63, 353, 414, 214)
		for stitch in range(18):
			var stitch_x := stitch_rect.position.x + 8.0 + float(stitch) * 22.5
			draw_line(Vector2(stitch_x, stitch_rect.position.y), Vector2(stitch_x + 8, stitch_rect.position.y), Color(cloth_ink, 0.24), 1.5)
			draw_line(Vector2(stitch_x, stitch_rect.end.y), Vector2(stitch_x + 8, stitch_rect.end.y), Color(cloth_ink, 0.24), 1.5)
		_draw_fabric_patch(Rect2(241, 354, 58, 58), int(tileclub_object_fx.get("value", 1)), 1.0, false, 0.48)
		_draw_center_font(DISPLAY_FONT, "织毯完成" if success else "槽位绷满", Vector2(270, 449), 29, cloth_ink)
		_draw_center_font(UI_FONT, "得分 %d · 步数 %d" % [int(state.get("score", 0)), int(state.get("moves", 0))], Vector2(270, 490), 16, Color(cloth_ink, 0.88))
		_draw_center_font(UI_FONT, "点击右上角“重开”继续挑战", Vector2(270, 536), 13, Color(cloth_ink, 0.68))
		return
	if game_id == "amaze_go":
		var blueprint_ink := Color("123b61")
		var brass := Color("d5ad5c")
		draw_rect(Rect2(0, 112, 540, 848), Color("06172d", 0.72))
		_draw_panel(Rect2(55, 345, 430, 250), Color("020b15", 0.36), Color.TRANSPARENT, 16, 0)
		_draw_panel(Rect2(48, 338, 444, 250), Color("e9e1c7"), brass, 12, 3)
		for rule in range(5):
			var rule_y := 360.0 + float(rule) * 45.0
			draw_line(Vector2(66, rule_y), Vector2(474, rule_y), Color(blueprint_ink, 0.10), 1.0)
		_draw_amaze_go_texture(AMAZE_GO_GAG_SURVEYOR_TEXTURE, Vector2(214, 390), 58.0, Color.WHITE)
		draw_line(Vector2(244, 390), Vector2(294, 390), Color(blueprint_ink, 0.42), 3.0, true)
		for rivet in range(4):
			draw_circle(Vector2(251 + rivet * 13, 390), 2.4, Color("c57652"))
		_draw_amaze_go_texture(AMAZE_GO_GAG_BEACON_TEXTURE, Vector2(326, 390), 64.0, Color.WHITE)
		_draw_center_font(DISPLAY_FONT, "航路认证", Vector2(270, 462), 29, blueprint_ink)
		_draw_center_font(UI_FONT, "得分 %d · 步数 %d" % [int(state.get("score", 0)), int(state.get("moves", 0))], Vector2(270, 504), 16, Color(blueprint_ink, 0.88))
		_draw_center_font(UI_FONT, "点击右上角“重开”继续挑战", Vector2(270, 548), 13, Color(blueprint_ink, 0.66))
		return
	if game_id == "arrow_go":
		var night_ink := Color("22305b")
		var brass := Color("d5a95c")
		draw_rect(Rect2(0, 112, 540, 848), Color("12091e", 0.74))
		_draw_panel(Rect2(55, 345, 430, 250), Color("06030c", 0.38), Color.TRANSPARENT, 18, 0)
		_draw_panel(Rect2(48, 338, 444, 250), Color("fff0d1"), brass, 16, 3)
		for seam in range(5):
			var seam_y := 360.0 + float(seam) * 45.0
			draw_line(Vector2(66, seam_y), Vector2(474, seam_y + 4.0), Color(night_ink, 0.085), 1.0)
		_draw_arrow_go_texture(ARROW_GO_GAG_COURIER_RIGHT_TEXTURE, Vector2(206, 390), 58.0, Color.WHITE)
		draw_line(Vector2(237, 390), Vector2(299, 390), Color("d76b5c", 0.78), 5.0, true)
		for knot in range(4):
			draw_circle(Vector2(248 + knot * 13, 390), 2.7, Color("f4c66c"))
		_draw_arrow_go_texture(ARROW_GO_GAG_HARBOR_TEXTURE, Vector2(330, 390), 64.0, Color.WHITE)
		_draw_center_font(DISPLAY_FONT, "航信送达", Vector2(270, 462), 29, night_ink)
		_draw_center_font(UI_FONT, "得分 %d · 步数 %d" % [int(state.get("score", 0)), int(state.get("moves", 0))], Vector2(270, 504), 16, Color(night_ink, 0.88))
		_draw_center_font(UI_FONT, "点击右上角“重开”继续挑战", Vector2(270, 548), 13, Color(night_ink, 0.66))
		return
	if game_id == "solitaire":
		var emerald_ink := Color("164538")
		var brass := Color("c9a34f")
		draw_rect(Rect2(0, 112, 540, 848), Color("03150f", 0.74))
		_draw_panel(Rect2(55, 345, 430, 258), Color("020b08", 0.42), Color.TRANSPARENT, 18, 0)
		_draw_panel(Rect2(48, 338, 444, 258), Color("fff5dd"), brass, 16, 3)
		draw_line(Vector2(72, 360), Vector2(468, 360), Color("ffffff", 0.82), 2.0, true)
		for suit in range(4):
			var card_rect := Rect2(167 + suit * 54, 366 + absf(1.5 - float(suit)) * 3.0, 44, 60)
			_draw_playing_card(card_rect, 13, GOLD, suit, 0.34)
		for side in [-1.0, 1.0]:
			var stem_start := Vector2(270 + side * 90.0, 438)
			var stem_end := Vector2(270 + side * 160.0, 392)
			draw_line(stem_start, stem_end, Color(brass, 0.64), 2.5, true)
			for leaf in range(3):
				var leaf_t := (float(leaf) + 1.0) / 4.0
				var leaf_center := stem_start.lerp(stem_end, leaf_t)
				draw_colored_polygon(PackedVector2Array([
					leaf_center + Vector2(-5 * side, 0),
					leaf_center + Vector2(5 * side, -7),
					leaf_center + Vector2(7 * side, 4),
				]), Color("78a873", 0.72))
		_draw_center_font(UI_FONT, "四组归位 · 牌局完成", Vector2(270, 468), 25, emerald_ink)
		_draw_center_font(UI_FONT, "得分 %d · 步数 %d" % [int(state.get("score", 0)), int(state.get("moves", 0))], Vector2(270, 512), 16, Color(emerald_ink, 0.88))
		_draw_center_font(UI_FONT, "点击右上角“重开”继续挑战", Vector2(270, 557), 13, Color(emerald_ink, 0.66))
		return
	draw_rect(Rect2(0, 112, 540, 848), Color(COAL, 0.72))
	var color := GREEN if won else RED
	_draw_panel(Rect2(48, 338, 444, 238), Color("111a2e", 0.985), Color(color, 0.82), 18, 2)
	draw_circle(Vector2(270, 382), 27, Color(color, 0.18))
	draw_arc(Vector2(270, 382), 24, 0, TAU, 40, color, 3.0)
	_draw_center("胜利" if won else "本局结束", Vector2(270, 438), 32, color)
	var result_score := str(state.get("score_label", state.get("score", "0"))) if game_id == "merge2248" else str(int(state.get("score", 0)))
	_draw_center("得分 %s · 步数 %d" % [result_score, int(state.get("moves", 0))], Vector2(270, 478), 16, INK)
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
			var press := sin(clampf(progress / 0.28, 0.0, 1.0) * PI)
			var patch_size := Vector2(50.0 * (1.0 + press * 0.11), 50.0 * (1.0 - press * 0.13))
			for knot in range(1, 5):
				var knot_t := clampf(float(knot) / 5.0, 0.0, 1.0)
				var knot_position := motion_from.lerp(position, knot_t)
				draw_circle(knot_position, 2.0, Color(motion_color.lightened(0.18), alpha * (0.56 - knot_t * 0.08)))
			var tile_alpha := maxf(alpha, 1.0 - progress)
			_draw_fabric_patch(Rect2(position - patch_size * 0.5, patch_size), motion_value, tile_alpha, false, 0.82)
		"card":
			var flip_scale := maxf(0.12, abs(cos(progress * PI)))
			var rect := Rect2(position - Vector2(29 * flip_scale, 40), Vector2(58 * flip_scale, 80))
			if progress < 0.5:
				_draw_card_back(rect, motion_color)
			else:
				_draw_playing_card(rect, int(motion_label), motion_color)
		"path":
			if game_id == "amaze_go":
				var planar_position := motion_from.lerp(motion_to, eased) + Vector2(0, -9.0 * sin(progress * PI))
				draw_line(motion_from, planar_position, Color("06192c", 0.54), 10.0, true)
				draw_line(motion_from, planar_position, Color("bde9e2", 0.84), 4.5, true)
				for pin in range(3):
					var pin_t := clampf((float(pin) + 1.0) / 4.0, 0.0, 1.0)
					var pin_position := motion_from.lerp(planar_position, pin_t)
					draw_circle(pin_position, 2.2, Color("d98b62", 0.82 * alpha))
				var rover_scale := 1.0 + sin(progress * PI) * 0.10
				_draw_amaze_go_texture(AMAZE_GO_GAG_SURVEYOR_TEXTURE, planar_position, 58.0 * rover_scale, Color.WHITE)
				_draw_amaze_go_heading(planar_position, amaze_go_facing, 28.0 * rover_scale, 0.92)
			elif game_id == "arrow_go":
				var planar_position := motion_from.lerp(motion_to, eased) + Vector2(0, -7.0 * sin(progress * PI))
				draw_line(motion_from + Vector2(1.2, 2.0), planar_position + Vector2(1.2, 2.0), Color("05030c", 0.56), 9.0, true)
				draw_line(motion_from, planar_position, Color("e87463", 0.88), 5.0, true)
				for knot in range(3):
					var knot_t := (float(knot) + 1.0) / 4.0
					var knot_position := motion_from.lerp(planar_position, knot_t)
					draw_circle(knot_position, 2.0, Color("ffe0ac", 0.82 * alpha))
				var courier_scale := 1.0 + sin(progress * PI) * 0.12
				_draw_arrow_go_texture(_arrow_go_courier_texture(arrow_go_facing), planar_position, 43.0 * courier_scale, Color.WHITE)
			else:
				draw_line(motion_from, position, Color(motion_color, 0.46 * alpha), 8.0)
				draw_circle(position, 11.0 + sin(progress * PI) * 4.0, Color(motion_color, 0.92))

func _card_event_phase_at(effect: Dictionary, now: float) -> String:
	var duration := maxf(0.001, float(effect.get("duration", 0.72)))
	var t := clampf((now - float(effect.get("started", now))) / duration, 0.0, 1.0)
	if t < 0.16:
		return "intent"
	if t < 0.36:
		return "anticipation"
	if t < 0.74:
		return "impact"
	return "settle"

func _card_event_progress(effect: Dictionary) -> float:
	var duration := maxf(0.001, float(effect.get("duration", 0.72)))
	return clampf((elapsed - float(effect.get("started", elapsed))) / duration, 0.0, 1.0)

func _latest_card_effect() -> Dictionary:
	if game_id not in ["solitaire", "tripeaks"]:
		return {}
	for index in range(catalog_fx.size() - 1, -1, -1):
		var effect: Dictionary = catalog_fx[index]
		if str(effect.get("game_id", "")) == game_id:
			return effect
	return {}

func _card_object_reject_offset(object_index: int) -> Vector2:
	var effect := _latest_card_effect()
	if effect.is_empty() or "reject" not in str(effect.get("kind", "")):
		return Vector2.ZERO
	if game_id == "solitaire" and bool(effect.get("reduced_effects", false)):
		return Vector2.ZERO
	if int(effect.get("card_index", effect.get("column", -1))) != object_index:
		return Vector2.ZERO
	var t := _card_event_progress(effect)
	var envelope := pow(1.0 - t, 2.0)
	return Vector2(sin(t * PI * 11.0) * 7.0 * envelope, 2.5 * sin(t * PI) * envelope)

func _tripeaks_reveal_effect(object_index: int) -> Dictionary:
	if game_id != "tripeaks":
		return {}
	for index in range(catalog_fx.size() - 1, -1, -1):
		var effect: Dictionary = catalog_fx[index]
		var started := float(effect.get("started", elapsed))
		var duration := float(effect.get("duration", 0.72))
		if (
			str(effect.get("game_id", "")) == "tripeaks"
			and str(effect.get("kind", "")) == "card_reveal"
			and int(effect.get("card_index", -1)) == object_index
			and elapsed >= started and elapsed < started + duration
		):
			return effect
	return {}

func _draw_card_game_object_fx() -> void:
	if game_id not in ["solitaire", "tripeaks"]:
		return
	for effect in catalog_fx:
		if str(effect.get("game_id", "")) != game_id or not effect.has("from") or not effect.has("to"):
			continue
		if game_id == "solitaire" and bool(effect.get("reduced_effects", false)):
			continue
		if game_id == "tripeaks" and tripeaks_reduced_effects:
			continue
		var started := float(effect.get("started", elapsed))
		var duration := maxf(0.001, float(effect.get("duration", 0.72)))
		if elapsed < started or elapsed >= started + duration:
			continue
		var kind := str(effect.get("kind", ""))
		if "reject" in kind or "select" in kind:
			continue
		var t := _card_event_progress(effect)
		var from: Vector2 = effect.get("from", Vector2.ZERO)
		var to: Vector2 = effect.get("to", from)
		var grade := clampi(int(effect.get("grade", 1)), 1, 4)
		var position := from
		var scale_value := Vector2.ONE
		var rotation := 0.0
		var reveal := bool(effect.get("reveal", false))
		if reveal:
			position += Vector2(0, -sin(t * PI) * (5.0 + float(grade)))
			if t < 0.16:
				var reveal_press := sin(t / 0.16 * PI)
				scale_value = Vector2(1.0 + reveal_press * 0.035, 1.0 - reveal_press * 0.055)
			elif t < 0.74:
				var reveal_flip := clampf((t - 0.16) / 0.58, 0.0, 1.0)
				scale_value.x = maxf(0.08, abs(cos(reveal_flip * PI)))
				rotation = sin(reveal_flip * PI) * 0.018
			else:
				var reveal_settle := clampf((t - 0.74) / 0.26, 0.0, 1.0)
				scale_value = Vector2.ONE * (1.0 + sin(reveal_settle * PI) * 0.055)
		elif t < 0.16:
			var press := sin(t / 0.16 * PI)
			position += Vector2(0, 3.5 * press)
			scale_value = Vector2(1.0 + press * 0.05, 1.0 - press * 0.08)
		elif t < 0.74:
			var travel_t := clampf((t - 0.16) / 0.58, 0.0, 1.0)
			var eased := 1.0 - pow(1.0 - travel_t, 3.0)
			position = from.lerp(to, eased)
			position.y -= sin(travel_t * PI) * (34.0 + float(grade) * 7.0)
			rotation = sin(travel_t * PI) * 0.085 * signf(to.x - from.x)
			if bool(effect.get("flip", false)):
				scale_value.x = maxf(0.12, abs(cos(travel_t * PI)))
		else:
			var settle_t := clampf((t - 0.74) / 0.26, 0.0, 1.0)
			var bounce := sin(settle_t * PI) * (0.055 + float(grade) * 0.016)
			position = to + Vector2(0, -sin(settle_t * PI) * 4.0)
			scale_value = Vector2.ONE * (1.0 + bounce)
		var card_size: Vector2 = effect.get("card_size", Vector2(58, 80))
		var rank := clampi(int(effect.get("rank", 1)), 1, 13)
		var suit := posmod(int(effect.get("suit", 0)), 4)
		var accent: Color = effect.get("color", AMBER)
		draw_set_transform(position, rotation, scale_value)
		if (reveal or bool(effect.get("back_first", false))) and t < 0.45:
			_draw_card_back(Rect2(-card_size * 0.5, card_size), accent)
		else:
			_draw_playing_card(Rect2(-card_size * 0.5, card_size), rank, accent, suit, 0.42 + float(grade) * 0.10)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _status_label() -> String:
	match str(state.get("status", "playing")):
		"won": return "已完成"
		"over", "lost": return "已结束"
		"stuck": return "待洗牌"
		_: return "进行中"

func _status_color() -> Color:
	match str(state.get("status", "playing")):
		"won": return GREEN
		"over", "lost": return RED
		"stuck": return AMBER
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

func _draw_playing_card(rect: Rect2, rank: int, accent: Color = RED, suit_index := -1, emphasis := 0.0) -> void:
	if game_id not in ["solitaire", "tripeaks"]:
		_draw_panel(Rect2(rect.position + Vector2(0, 4), rect.size), Color(0, 0, 0, 0.30), Color.TRANSPARENT, 6, 0)
		_draw_panel(rect, WARM_PAPER, Color(accent, 0.64), 6, 1)
		var other_suit := posmod(rank - 1, 4) if suit_index < 0 else posmod(suit_index, 4)
		var other_red_suit := other_suit == 1 or other_suit == 3
		var other_card_color := Color("c93f55") if other_red_suit else Color("182136")
		var other_rank_label := _card_rank(rank)
		var other_suit_label: String = ["♠", "♥", "♣", "◆"][other_suit]
		_draw_text_font(LATIN_FONT, other_rank_label, rect.position + Vector2(6, 18), max(10, int(rect.size.x * 0.18)), other_card_color)
		_draw_center_font(SYMBOL_FONT, other_suit_label, rect.get_center() + Vector2(0, 7), max(15, int(rect.size.x * 0.28)), other_card_color)
		_draw_text_font(LATIN_FONT, other_rank_label, rect.end - Vector2(7 + max(8, int(rect.size.x * 0.18)) * 0.52, 7), max(8, int(rect.size.x * 0.16)), other_card_color)
		return
	var radius := maxi(3, int(rect.size.x * 0.095))
	var shadow_drop := 4.0 + emphasis * 2.0
	_draw_panel(Rect2(rect.position + Vector2(0, shadow_drop), rect.size), Color("05070d", 0.34 + emphasis * 0.08), Color.TRANSPARENT, radius, 0)
	_draw_panel(Rect2(rect.position + Vector2(0, 1), rect.size), Color("e4d6b9"), Color(accent.darkened(0.36), 0.72), radius, 1)
	var face := rect.grow(-1.5)
	_draw_panel(face, Color("fff9ec"), Color("fffef7", 0.86), maxi(2, radius - 1), 1)
	draw_line(face.position + Vector2(5, 4), Vector2(face.end.x - 5, face.position.y + 4), Color(Color.WHITE, 0.78), 1.5, true)
	if rect.size.x >= 48.0:
		for fibre in range(3):
			var fibre_y := face.position.y + 24.0 + float(fibre) * maxf(12.0, face.size.y * 0.19)
			draw_line(Vector2(face.position.x + 7, fibre_y), Vector2(face.end.x - 7, fibre_y + 1), Color("9a805e", 0.035), 1.0)
	var suit := posmod(rank - 1, 4) if suit_index < 0 else posmod(suit_index, 4)
	var red_suit := suit == 1 or suit == 3
	var card_color := Color("c94458") if red_suit else Color("172239")
	var rank_label := _card_rank(rank)
	var suit_label: String = ["♠", "♥", "♣", "♦"][suit]
	var corner_size := maxi(9, int(rect.size.x * 0.20))
	_draw_text_font(LATIN_FONT, rank_label, rect.position + Vector2(6, 17), corner_size, card_color)
	_draw_text_font(SYMBOL_FONT, suit_label, rect.position + Vector2(6, 29), maxi(8, int(rect.size.x * 0.16)), Color(card_color, 0.92))
	var center_size := maxi(13, int(rect.size.x * (0.34 + emphasis * 0.025)))
	if rect.size.x >= 36.0:
		draw_circle(rect.get_center() + Vector2(0, 4), rect.size.x * 0.22, Color(card_color, 0.045 + emphasis * 0.035))
		_draw_center_font(SYMBOL_FONT, suit_label, rect.get_center() + Vector2(0, 8), center_size, card_color)
	var lower_rank_size := maxi(8, int(rect.size.x * 0.17))
	_draw_text_font(LATIN_FONT, rank_label, rect.end - Vector2(7 + lower_rank_size * 0.52, 7), lower_rank_size, card_color)
	if emphasis > 0.01:
		draw_arc(rect.get_center(), minf(rect.size.x, rect.size.y) * 0.58, -PI * 0.82, PI * 0.12, 18, Color(accent.lightened(0.30), minf(0.82, 0.28 + emphasis * 0.42)), 2.0, true)

func _draw_card_back(rect: Rect2, accent: Color) -> void:
	if game_id == "solitaire":
		var radius := maxi(3, int(rect.size.x * 0.095))
		_draw_panel(Rect2(rect.position + Vector2(0, 5), rect.size), Color("05070d", 0.36), Color.TRANSPARENT, radius, 0)
		_draw_panel(rect, Color("174236"), Color("d7b965", 0.86), radius, 2)
		if SOLITAIRE_CARD_BACK_TEXTURE != null and rect.size.x >= 34.0:
			var material_rect := rect.grow(-3.0)
			draw_texture_rect(SOLITAIRE_CARD_BACK_TEXTURE, material_rect, false, Color.WHITE)
			draw_rect(material_rect, Color("d7b965", 0.54), false, 1.2)
			draw_line(material_rect.position + Vector2(3, 3), Vector2(material_rect.end.x - 3, material_rect.position.y + 3), Color(Color.WHITE, 0.28), 1.0, true)
			return
		var solitaire_inset := rect.grow(-5)
		_draw_panel(solitaire_inset, Color(accent.darkened(0.35), 0.58), Color("d7b965", 0.66), maxi(2, radius - 2), 1)
		draw_circle(rect.get_center(), rect.size.x * 0.15, Color("d7b965", 0.62))
		return
	if game_id == "tripeaks":
		var tripeaks_radius := maxi(3, int(rect.size.x * 0.095))
		_draw_panel(Rect2(rect.position + Vector2(0, 5), rect.size), Color("05070d", 0.36), Color.TRANSPARENT, tripeaks_radius, 0)
		_draw_panel(rect, Color("30204f"), Color("cbb0f6", 0.86), tripeaks_radius, 2)
		if TRIPEAKS_CARD_BACK_TEXTURE != null and rect.size.x >= 34.0:
			var tripeaks_material_rect := rect.grow(-3.0)
			draw_texture_rect(TRIPEAKS_CARD_BACK_TEXTURE, tripeaks_material_rect, false, Color.WHITE)
			draw_rect(tripeaks_material_rect, Color("cbb0f6", 0.54), false, 1.2)
			draw_line(tripeaks_material_rect.position + Vector2(3, 3), Vector2(tripeaks_material_rect.end.x - 3, tripeaks_material_rect.position.y + 3), Color(Color.WHITE, 0.28), 1.0, true)
			return
		var tripeaks_inset := rect.grow(-5)
		_draw_panel(tripeaks_inset, Color(accent.darkened(0.35), 0.58), Color("cbb0f6", 0.66), maxi(2, tripeaks_radius - 2), 1)
		draw_circle(rect.get_center(), rect.size.x * 0.15, Color("cbb0f6", 0.62))
		return
	_draw_panel(Rect2(rect.position + Vector2(0, 4), rect.size), Color(0, 0, 0, 0.30), Color.TRANSPARENT, 6, 0)
	_draw_panel(rect, Color("26355a"), Color(WARM_PAPER, 0.66), 6, 2)
	var inset := rect.grow(-6)
	_draw_panel(inset, Color(accent, 0.22), Color(accent, 0.62), 3, 1)
	for y in range(int(inset.position.y + 4), int(inset.end.y), 8):
		draw_line(Vector2(inset.position.x + 3, y), Vector2(inset.end.x - 3, y), Color(WARM_PAPER, 0.12), 1.0)

func _card_back_texture() -> Texture2D:
	match game_id:
		"solitaire": return SOLITAIRE_CARD_BACK_TEXTURE
		"tripeaks": return TRIPEAKS_CARD_BACK_TEXTURE
		_: return null

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

func _start_game_state(force_reset := false) -> void:
	state = {"status":"playing", "score":0, "moves":0, "game_id":game_id}
	selected_cell = Vector2i(-1, -1)
	snake_clock = 0.0
	match game_id:
		"merge2248": _init_merge2248(force_reset)
		"merge2048": _init_merge()
		"watermelon": _init_watermelon()
		"sudoku": _init_sudoku()
		"meowdoku": _init_meowdoku()
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

func _init_merge2248(force_reset := false) -> void:
	var restored := false
	if not force_reset and merge2248_persistence_enabled:
		restored = _load_merge2248_progress()
	if not restored:
		var retained_mode := str(merge2248_model.mode)
		if retained_mode not in [MERGE2248_RULES.MODE_EASY, MERGE2248_RULES.MODE_HARD]:
			retained_mode = MERGE2248_RULES.MODE_EASY
		merge2248_model.reset(abs(game_id.hash()) + 17, retained_mode, true)
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
	if force_reset:
		_save_merge2248_progress()

func _sync_merge2248_state() -> void:
	state.merge2248 = merge2248_model.snapshot()
	state.board = state.merge2248.board
	state.selected = state.merge2248.selected
	state.score = state.merge2248.score
	state.moves = state.merge2248.moves
	state.status = state.merge2248.status
	state.preview = state.merge2248.preview
	state.preview_power = state.merge2248.preview_power
	state.preview_label = state.merge2248.preview_label
	state.score_label = state.merge2248.score_label
	state.all_time = state.merge2248.all_time
	state.all_time_label = state.merge2248.all_time_label
	state.mode = state.merge2248.mode
	state.mode_evidence_verified = state.merge2248.mode_evidence_verified
	state.can_undo = state.merge2248.can_undo
	state.reduced_effects = _merge2248_reduced_effects_active()

func _save_merge2248_progress() -> bool:
	if not merge2248_persistence_enabled:
		return false
	var file := FileAccess.open(merge2248_save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(merge2248_model.serialize()))
	file.flush()
	return true

func _load_merge2248_progress() -> bool:
	if not merge2248_persistence_enabled or not FileAccess.file_exists(merge2248_save_path):
		return false
	var file := FileAccess.open(merge2248_save_path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed is Dictionary and merge2248_model.restore(parsed)

func _merge2248_cycle_mode() -> void:
	if game_id != "merge2248":
		return
	var next_mode := MERGE2248_RULES.MODE_HARD if merge2248_model.mode == MERGE2248_RULES.MODE_EASY else MERGE2248_RULES.MODE_EASY
	var mode_seed: int = abs(game_id.hash()) + (181 if next_mode == MERGE2248_RULES.MODE_HARD else 17)
	merge2248_model.reset(mode_seed, next_mode, true)
	merge2248_drag_active = false
	merge2248_fx.clear()
	merge2248_chain_grade = 0
	merge2248_juice_grade = 0
	_sync_merge2248_state()
	_save_merge2248_progress()
	_build_game_buttons()
	_flash_feedback("难度切换 · %s" % _merge2248_mode_label(), Color("f1bd68"))
	_log_event("merge2248_mode", {"mode":merge2248_model.mode, "rows":merge2248_model.height, "evidence_verified":merge2248_model.is_mode_evidence_verified()})
	queue_redraw()

func _merge2248_mode_label() -> String:
	return "简单" if merge2248_model.mode == MERGE2248_RULES.MODE_EASY else "困难"

func _merge2248_undo() -> void:
	if game_id != "merge2248":
		return
	if not merge2248_model.undo():
		_flash_feedback("暂无可撤销配方", Color("d7e5d8"))
		return
	merge2248_drag_active = false
	merge2248_fx.clear()
	merge2248_chain_grade = 0
	merge2248_juice_grade = 0
	_sync_merge2248_state()
	_save_merge2248_progress()
	_flash_feedback("已撤销上一份配方", Color("82cd64"))
	_log_event("merge2248_undo", {"score":state.score, "moves":state.moves, "mode":state.mode})
	queue_redraw()

func _detect_merge2248_reduced_effects() -> bool:
	if not OS.has_feature("web"):
		return false
	var preference: Variant = JavaScriptBridge.eval("window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches", true)
	return bool(preference)

func _merge2248_reduced_effects_active() -> bool:
	if merge2248_reduced_effects_override != null:
		return bool(merge2248_reduced_effects_override)
	return merge2248_reduced_effects

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
		if not _merge2248_reduced_effects_active():
			_haptic(4)
		_sync_merge2248_state()
		queue_redraw()
	return began

func _merge2248_extend_at(screen_pos: Vector2) -> void:
	merge2248_pointer = screen_pos
	if merge2248_model.extend(_merge2248_cell_at(screen_pos)):
		merge2248_chain_pulse = elapsed
		var previous_grade := merge2248_chain_grade
		merge2248_chain_grade = _merge2248_feedback_grade(merge2248_model.selected.size(), merge2248_model.preview_power())
		var chain_pitch := 1.0 + minf(float(merge2248_model.selected.size()), 9.0) * 0.055
		_play_sfx(SFX_SNAKE_KEY, -17.0, chain_pitch)
		if not _merge2248_reduced_effects_active():
			_haptic(6 + merge2248_chain_grade * 3 + (4 if merge2248_chain_grade > previous_grade else 0))
		_sync_merge2248_state()
		queue_redraw()

func _merge2248_release() -> void:
	# Preserve presentation inputs before the authoritative model consumes the
	# path. These copies never influence legality, score, gravity, or refill.
	var path_powers: Array[int] = []
	var path_labels: Array[String] = []
	for selected in merge2248_model.selected:
		var power := int(merge2248_model.board[selected.y][selected.x])
		path_powers.append(power)
		path_labels.append(merge2248_model.power_label(power))
	var outcome: Dictionary = merge2248_model.release()
	_sync_merge2248_state()
	if bool(outcome.get("changed", false)):
		var gained := str(outcome.gained)
		var gained_label := str(outcome.gained_label)
		var result_power := int(outcome.result_power)
		var result_label := str(outcome.result_label)
		var chain_length := int(outcome.path.size())
		var feedback_grade := _merge2248_feedback_grade(chain_length, result_power)
		var path_points: Array[Vector2] = []
		for path_cell in outcome.path:
			path_points.append(_merge2248_cell_center(path_cell))
		var destination := path_points[-1]
		merge2248_fx.append({
			"started": elapsed,
			"points": path_points,
			"powers": path_powers,
			"labels": path_labels,
			"result_power": result_power,
			"result_label": result_label,
			"color": _merge2248_color(result_power),
			"grade": feedback_grade,
			"chain_length": chain_length,
			"gained": gained,
			"gained_label": gained_label,
			"reduced_effects": _merge2248_reduced_effects_active(),
			"duration": 0.44 if _merge2248_reduced_effects_active() else 0.76 + float(feedback_grade) * 0.11,
		})
		_merge2248_start_juice(feedback_grade, destination)
		_play_sfx(SFX_MERGE2248_GAG_MERGE, -11.5 + float(feedback_grade - 1) * 1.15, 0.92 + minf(float(chain_length), 9.0) * 0.028)
		if feedback_grade >= 3:
			_play_sfx(SFX_MERGE2248_GAG_MASTERY, -12.0 + float(feedback_grade - 3) * 1.8, 0.97 + float(feedback_grade - 3) * 0.035)
		if not _merge2248_reduced_effects_active():
			_haptic_pattern(_merge2248_release_haptic(feedback_grade))
		var grade_label := _merge2248_grade_label(feedback_grade)
		_flash_feedback("%s ×%d · +%s → %s" % [grade_label, chain_length, gained_label, result_label], _merge2248_grade_color(feedback_grade))
		feedback_until = elapsed + 0.78 + float(feedback_grade) * 0.12
		_save_merge2248_progress()
		_log_event("merge2248_connect", {"length":chain_length, "gained":gained, "result_power":result_power, "result_label":result_label, "feedback_grade":feedback_grade, "mode":merge2248_model.mode})
		if state.status != "playing":
			_capture("game_over_merge2248")
	queue_redraw()

func _merge2248_feedback_grade(chain_length: int, result_power: int) -> int:
	var grade := 1
	if chain_length >= 3 or result_power >= 4:
		grade = 2
	if chain_length >= 5 or result_power >= 7:
		grade = 3
	if chain_length >= 8 or result_power >= 9:
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
	merge2248_settle_started = elapsed if _merge2248_reduced_effects_active() else elapsed + 0.10 + float(merge2248_juice_grade) * 0.018
	merge2248_score_started = elapsed
	merge2248_score_grade = merge2248_juice_grade
	score_pulse_until = elapsed + 0.28 + float(merge2248_juice_grade) * 0.07
	merge2248_chain_grade = 0
	if not _merge2248_reduced_effects_active():
		_impact(destination, _merge2248_grade_color(merge2248_juice_grade), 0.54 + float(merge2248_juice_grade) * 0.27)

func _merge2248_shake_offset() -> Vector2:
	if merge2248_juice_grade <= 0 or _merge2248_reduced_effects_active():
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
	if _merge2248_reduced_effects_active():
		return Transform2D.IDENTITY
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
	return merge2248_model.power_label(merge2248_model.highest_power())

func _merge2248_color(power: int) -> Color:
	var palette := [
		Color("ff7777"), Color("a876f3"), Color("ffc801"), Color("82cd64"),
		Color("64c7fe"), Color("ffb177"), Color("598cdd"), Color("aa8364"),
		Color("00ddaa"), Color("8787f9"), Color("77faff"), Color("ff8fbe"),
	]
	return palette[posmod(maxi(power, 1) - 1, palette.size())]

func _draw_merge2248() -> void:
	var rect := _merge2248_board_rect()
	var rows: int = merge2248_model.height
	var cell := Vector2(rect.size.x / 5.0, rect.size.y / float(rows))
	var selected_cells: Array = merge2248_model.selected
	_draw_section_heading("糖果配方 · %s" % _merge2248_mode_label(), "同值起步 · 八向拉糖", Color("f1bd68"))
	var juice_transform := _merge2248_board_juice_transform(rect)
	var juice_scale := juice_transform.get_scale()
	var juice_rotation := juice_transform.get_rotation()
	draw_set_transform_matrix(juice_transform)
	merge2248_presenter.draw_board(self, rect, cell)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var path_points: Array[Vector2] = []
	for selected_cell_position in selected_cells:
		path_points.append(juice_transform * _merge2248_cell_center(selected_cell_position))
	var preview_power := merge2248_model.preview_power()
	var preview_label := merge2248_model.preview_label()
	var preview_grade := _merge2248_feedback_grade(selected_cells.size(), preview_power) if preview_power > 0 else maxi(1, merge2248_chain_grade)
	var ribbon_color := _merge2248_color(preview_power) if preview_power > 0 else Color("efb85f")
	merge2248_presenter.draw_ribbon(self, path_points, juice_transform * merge2248_pointer, merge2248_drag_active, elapsed, ribbon_color, preview_grade, _merge2248_reduced_effects_active())

	for y in range(rows):
		for x in range(5):
			var center := rect.position + Vector2((x + 0.5) * cell.x, (y + 0.5) * cell.y)
			var power := int(merge2248_model.board[y][x])
			var label := merge2248_model.power_label(power)
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
			if not _merge2248_reduced_effects_active() and settle_age >= 0.0 and settle_age < settle_duration:
				var settle_t := clampf(settle_age / settle_duration, 0.0, 1.0)
				var fall := 1.0 - pow(1.0 - settle_t, 3.0)
				token_offset.y = lerpf(-16.0 - float(merge2248_settle_grade) * 5.0, 0.0, fall)
				var contact := sin(clampf((settle_t - 0.62) / 0.38, 0.0, 1.0) * PI)
				var contact_strength := 0.045 + float(merge2248_settle_grade) * 0.014
				token_scale *= Vector2(1.0 + contact * contact_strength, 1.0 - contact * contact_strength)

			if selected_now:
				var pulse := 0.0 if _merge2248_reduced_effects_active() else sin(elapsed * 6.8 - float(maxi(selection_index, 0)) * 0.48)
				var accepted_age := 1.0 if _merge2248_reduced_effects_active() else clampf((elapsed - merge2248_chain_pulse) / 0.18, 0.0, 1.0)
				var accepted_pop := 0.0 if _merge2248_reduced_effects_active() else sin(accepted_age * PI) * 0.10
				token_scale *= Vector2(1.08 + accepted_pop + pulse * 0.012, 0.96 - accepted_pop * 0.32 - pulse * 0.008)
				if selection_index == selected_cells.size() - 1 and merge2248_drag_active:
					token_rotation = clampf((merge2248_pointer.x - center.x) / 900.0, -0.075, 0.075)

			merge2248_presenter.draw_token(
				self,
				juice_transform * (center + token_offset),
				power,
				label,
				_merge2248_color(power),
				selected_now,
				NUMBER_FONT,
				elapsed,
				token_scale * juice_scale,
				token_rotation + juice_rotation
			)

	var helper := "连接相邻同值糖果，再追踪同值或双倍数字"
	if preview_power > 0:
		var label_width: float = [178.0, 210.0, 234.0, 258.0][preview_grade - 1]
		merge2248_presenter.draw_recipe_label(self, Rect2(270.0 - label_width * 0.5, 879, label_width, 40), preview_label, DISPLAY_FONT, preview_grade, selected_cells.size(), elapsed, _merge2248_reduced_effects_active())
	else:
		_draw_panel(Rect2(118, 884, 320, 30), Color("17484a", 0.90), Color("f3d59d", 0.26), 15, 1)
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
	var progress := _merge2048_read_progress()
	var preserved_best := maxi(merge2048_model.best, int(progress.get("best", 0)))
	var restored := false
	if not merge2048_force_new_run and merge2048_persistence_enabled:
		var active: Variant = progress.get("active")
		if active is Dictionary:
			var candidate: Dictionary = active.duplicate(true)
			candidate["best"] = maxi(preserved_best, int(candidate.get("best", 0)))
			restored = merge2048_model.restore(candidate)
	if not restored:
		merge2048_model.reset(_merge2048_new_seed(), preserved_best)
	merge2048_force_new_run = false
	_sync_merge2048_state()
	_merge2048_save_progress()

func _sync_merge2048_state() -> void:
	state["merge2048"] = merge2048_model.snapshot()
	state["board"] = state.merge2048.board
	state["score"] = state.merge2048.score
	state["best"] = state.merge2048.best
	state["moves"] = state.merge2048.moves
	state["status"] = state.merge2048.status
	state["target"] = merge2048_model.TARGET
	state["can_continue"] = merge2048_model.won and not merge2048_model.keep_playing and not merge2048_model.over
	state["reduced_effects"] = reduced_effects_enabled

func _merge2048_load_fixture(
	fixture_board: Array,
	fixture_score := 0,
	fixture_moves := 0,
	fixture_won := false,
	fixture_keep_playing := false,
	fixture_over := false,
	fixture_best := -1
) -> bool:
	var accepted := merge2048_model.load_fixture(
		fixture_board,
		fixture_score,
		fixture_moves,
		fixture_won,
		fixture_keep_playing,
		fixture_over,
		fixture_best
	)
	if accepted:
		_sync_merge2048_state()
	return accepted

func _merge2048_continue() -> void:
	if not merge2048_model.continue_after_win():
		return
	_sync_merge2048_state()
	_merge2048_save_progress()
	merge2048_motion.clear()
	_build_game_buttons()
	_flash_feedback("继续冲击更高数字", GOLD)
	_log_event("merge_continue", {"score":merge2048_model.score, "best":merge2048_model.best})
	queue_redraw()

func _merge2048_new_seed() -> int:
	if merge2048_seed_override >= 0:
		return merge2048_seed_override
	var mixed := int(Time.get_unix_time_from_system() * 1000000.0) ^ Time.get_ticks_usec() ^ hash(Time.get_datetime_string_from_system())
	return absi(mixed)

func _merge2048_read_progress() -> Dictionary:
	if not merge2048_persistence_enabled or not FileAccess.file_exists(merge2048_save_path):
		return {}
	var file := FileAccess.open(merge2048_save_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("schema", 0)) != 1:
		return {}
	return parsed

func _merge2048_save_progress() -> void:
	if not merge2048_persistence_enabled:
		return
	var payload := {
		"schema":1,
		"best":merge2048_model.best,
		"active":null if merge2048_model.over else merge2048_model.snapshot(),
	}
	var file := FileAccess.open(merge2048_save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))

func _merge2048_tool_runtime() -> bool:
	for argument in OS.get_cmdline_args():
		if str(argument).begins_with("res://tools/"):
			return true
	return false

func _merge2048_effects_reduced() -> bool:
	return game_id == "merge2048" and reduced_effects_enabled

func _slide_line(line: Array) -> Dictionary:
	return merge2048_model.resolve_line(line)

func _merge_move(direction: Vector2i) -> void:
	var outcome: Dictionary = merge2048_model.move(direction)
	if not bool(outcome.changed):
		if merge2048_model.status() == "playing":
			var reject_position := Vector2(270, 454) + Vector2(direction) * 116.0
			_flash_feedback("这一侧已经锁住", RED)
			# The persistent top toast carries the copy; keep the local rejection
			# mark text-free so it cannot cover live tile values on a full board.
			_start_catalog_event("merge_reject", reject_position, RED, 1, "", 0.58, {"semantic":"wood_reject", "direction":direction})
			_log_event("merge_rejected", {"direction":str(direction), "score":merge2048_model.score})
		return
	var board_before: Array = outcome.board_before
	var board_after_slide: Array = outcome.board_after_slide
	var gained := int(outcome.gained)
	var spawn: Dictionary = outcome.spawn
	var motion_moves: Array = outcome.moves
	var merge_results: Array = outcome.merges
	_sync_merge2048_state()
	_merge2048_save_progress()
	var primary_merge := _merge2048_primary_merge(merge_results)
	var peak_value := int(primary_merge.get("result_value", 0))
	var merge_count := merge_results.size()
	var impact_cell := _merge2048_semantic_impact_cell(motion_moves, primary_merge)
	var impact_position := Vector2(42, 236) + Vector2(impact_cell.x + 0.5, impact_cell.y + 0.5) * 109.0
	var merge_color := GOLD if gained > 0 else CYAN
	var reached_target := bool(outcome.won_now)
	var merge_grade := _merge2048_feedback_grade(peak_value, reached_target)
	if merge_count > 1:
		_flash_feedback("连合 %d 次 · +%d" % [merge_count, gained], GOLD)
	elif merge_count == 1:
		_flash_feedback("合成 %d · +%d" % [peak_value, gained], GOLD)
	else:
		_flash_feedback("木牌滑动归位", CYAN)
	merge2048_motion = {
		"started":elapsed,
		"duration":0.16 if _merge2048_effects_reduced() else 0.62 + float(merge_grade) * 0.04,
		"moves":motion_moves,
		"merges":merge_results,
		"spawn":spawn,
		"grade":merge_grade,
		"peak_value":peak_value,
		"merge_count":merge_count,
		"impact_cell":impact_cell,
		"direction":direction,
		"board_before":board_before,
		"board_after_slide":board_after_slide,
		"reduced":_merge2048_effects_reduced(),
	}
	var impact_scale: float = [0.48, 0.76, 1.08, 1.38][merge_grade - 1]
	_impact(impact_position, merge_color, impact_scale if gained > 0 else 0.42)
	var semantic := "wood_slide" if gained == 0 else ("wood_masterpiece" if merge_grade == 4 else ("wood_milestone" if merge_grade == 3 else "wood_merge"))
	var label := "木牌归位"
	if gained > 0:
		label = "大师雕版 · %d" % peak_value if merge_grade == 4 else ("金纹里程碑 · %d" % peak_value if merge_grade == 3 else "木作合成 · %d" % peak_value)
		if merge_count > 1:
			label += " · %d 连合" % merge_count
	_start_catalog_event("merge", impact_position, merge_color, merge_grade, label, 0.66 + merge_grade * 0.07, {
		"semantic":semantic,
		"gained":gained,
		"peak_value":peak_value,
		"merge_count":merge_count,
		"impact_cell":impact_cell,
		"direction":direction,
	})
	_log_event("merge_move", {
		"direction":str(direction),
		"gained":gained,
		"peak_value":peak_value,
		"merge_count":merge_count,
		"impact_cell":impact_cell,
		"score":state["score"],
		"grade":merge_grade,
		"semantic":semantic,
		"motion_count":motion_moves.size(),
	})
	if reached_target:
		_capture("win_%s" % game_id)
		_build_game_buttons()
	elif bool(outcome.over_now):
		_capture("game_over_%s" % game_id)

func _merge2048_primary_merge(merge_results: Array) -> Dictionary:
	var primary := {}
	for merge_result in merge_results:
		if primary.is_empty() or int(merge_result.get("result_value", 0)) > int(primary.get("result_value", 0)):
			primary = merge_result
	return primary

func _merge2048_semantic_impact_cell(motion_moves: Array, primary_merge: Dictionary) -> Vector2i:
	if not primary_merge.is_empty():
		return primary_merge.get("to", Vector2i(1, 1))
	var destination := Vector2i(1, 1)
	var longest_travel := -1
	for move in motion_moves:
		var source: Vector2i = move.get("from", destination)
		var target: Vector2i = move.get("to", source)
		var travel := absi(target.x - source.x) + absi(target.y - source.y)
		if travel > longest_travel:
			longest_travel = travel
			destination = target
	return destination

func _merge2048_feedback_grade(peak_value: int, reached_target: bool) -> int:
	if reached_target or peak_value >= 128:
		return 4
	if peak_value >= 32:
		return 3
	if peak_value >= 8:
		return 2
	return 1

func _merge_has_target() -> bool:
	if game_id == "merge2248":
		return int(state.get("score", 0)) >= 2248
	return merge2048_model.won

func _merge_target_tile() -> int:
	return 2048

func _merge_has_moves() -> bool:
	return merge2048_model.has_moves()

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
	watermelon_model.reset(abs("watermelon".hash()) + 17, true)
	_sync_watermelon_state()

func _watermelon_board_rect() -> Rect2:
	return Rect2(26, 232, 470, 474)


func _watermelon_aim_at(screen_x: float) -> void:
	if game_id != "watermelon" or state.get("status") != "playing":
		return
	watermelon_model.set_aim_x(screen_x)
	_sync_watermelon_state()
	queue_redraw()


func _watermelon_nudge(direction: float) -> void:
	if game_id != "watermelon" or state.get("status") != "playing":
		return
	watermelon_model.nudge_aim(direction)
	_sync_watermelon_state()
	_flash_feedback("瞄准 %d" % int(round(watermelon_model.aim_x)), AMBER)


func _watermelon_drop_current() -> void:
	_watermelon_drop_at(watermelon_model.aim_x)


func _watermelon_drop_at(screen_x: float) -> void:
	if game_id != "watermelon" or state.get("status") != "playing":
		return
	watermelon_model.set_aim_x(screen_x)
	watermelon_model.drop()
	_consume_watermelon_events(watermelon_model.step(0.0))
	_sync_watermelon_state()


# Compatibility route used by the collection-wide smoke test. The runtime no
# longer has discrete columns; the seven legacy indices map to free aim points.
func _water_drop(column: int) -> void:
	var clamped_column := clampi(column, 0, 6)
	_watermelon_drop_at(70.0 + float(clamped_column) * 62.0)


func _watermelon_update(delta: float) -> void:
	_consume_watermelon_events(watermelon_model.step(delta))
	_sync_watermelon_state()


func _consume_watermelon_events(events: Array) -> void:
	for event_value in events:
		var event: Dictionary = event_value
		var kind := str(event.get("kind", ""))
		var position: Vector2 = event.get("position", Vector2(watermelon_model.aim_x, watermelon_model.SPAWN_Y))
		var tier := maxi(1, int(event.get("tier", 1)))
		var value := int(event.get("value", watermelon_model.value_for_tier(tier)))
		match kind:
			"ball_released":
				_flash_feedback("松手落下 · %d" % value, _fruit_color(tier))
			"ball_landed":
				_start_catalog_event(
					"fruit_drop", position, _fruit_color(tier), 1,
					"%d 落地" % value, 0.56,
					{"ball_id":int(event.get("ball_id", -1)), "tier":tier, "semantic":"fruit_drop"}
				)
			"balls_merged":
				var grade := clampi(int(event.get("grade", 2)), 2, 4)
				var chain := maxi(1, int(event.get("chain", 1)))
				var merge_word := "连携×%d" % chain if chain > 1 else "合成"
				var label := "%d %s · +%d" % [value, merge_word, value]
				_start_catalog_event(
					"fruit_merge", position, _fruit_color(tier), grade, label,
					0.96 if grade >= 3 else 0.78,
					{
						"result_id":int(event.get("result_id", -1)), "tier":tier,
						"chain":chain, "semantic":"fruit_merge",
						"source_positions":event.get("source_positions", []),
					}
				)
				_impact(position, _fruit_color(tier), 0.58 + float(grade) * 0.18)
			"target_reached":
				var completed := int(event.get("completed_target", value))
				var next_target := watermelon_model.value_for_tier(watermelon_model.target_tier)
				if not catalog_fx.is_empty() and str(catalog_fx.back().get("game_id", "")) == "watermelon":
					catalog_fx.back()["kind"] = "fruit_harvest_complete"
					catalog_fx.back()["label"] = "目标 %d 达成 · 向 %d" % [completed, next_target]
					catalog_fx.back()["grade"] = 4
				_flash_feedback("目标 %d 达成 · 继续挑战 %d" % [completed, next_target], GOLD)
				_sync_watermelon_state()
				_capture("watermelon_target_%d" % completed)
			"drop_rejected":
				var reason := str(event.get("reason", "blocked"))
				var reject_label := "落口被挡住" if reason == "spawn_blocked" else "稍候再投"
				_flash_feedback(reject_label, RED)
				_start_catalog_event("fruit_error_drop", position, RED, 2, reject_label, 0.68, {"reason":reason})
			"danger_overflow":
				_flash_feedback("果球越过危险线", RED)
				_start_catalog_event("fruit_error_overflow", position, RED, 4, "危险线溢出", 0.92, {"tier":tier})
				_sync_watermelon_state()
				_capture("watermelon_overflow")
		_log_event("watermelon_%s" % kind, event)


func _sync_watermelon_state() -> void:
	var snapshot := watermelon_model.snapshot()
	for key in snapshot:
		state[key] = snapshot[key]
	# Keep the common catalog-facing alias while the authoritative state remains
	# tier/value based. No column array is retained.
	state["next"] = int(snapshot.get("next_tier", 1))
	state.erase("columns")

func _water_drop_hint() -> void:
	if game_id == "watermelon" and state.get("status") == "playing":
		_flash_feedback("左右拖动瞄准，松手投放", AMBER)

func _draw_watermelon() -> void:
	_draw_section_heading("果园落口", "拖动瞄准 · 松手投放", RED)
	var board_rect := _watermelon_board_rect()
	watermelon_presenter.draw_crate(self, board_rect, elapsed)
	var aim_x := float(state.get("aim_x", 270.0))
	var next_tier := int(state.get("next_tier", 1))
	var next_visual := _watermelon_visual_value(next_tier)
	var next_value := int(state.get("next_value", 2))
	var aim_color := _fruit_color(next_tier)
	# Continuous aim and visible falling motion are gameplay state, not a
	# presentation-only fake. The guide sits behind every simulated ball.
	draw_dashed_line(Vector2(aim_x, 316), Vector2(aim_x, watermelon_model.FLOOR_Y - 8.0), Color(aim_color, 0.42), 2.0, 9.0)
	draw_circle(Vector2(aim_x, 310), 28.0, Color(aim_color, 0.12))
	draw_arc(Vector2(aim_x, 310), 28.0, 0, TAU, 36, Color(aim_color, 0.58), 2.0, true)
	watermelon_presenter.draw_fruit(self, Vector2(aim_x, 310), next_visual, 19.0, elapsed, [], false)
	_draw_watermelon_number_badge(Vector2(aim_x, 310), str(next_value), 11 if next_value < 100 else 9, 9.0)

	var highest_tier := int(state.get("highest_tier", 0))
	var balls: Array = state.get("balls", [])
	for ball_value in balls:
		var ball: Dictionary = ball_value
		var serialized_position: Array = ball.get("position", [270.0, 620.0])
		var center := Vector2(float(serialized_position[0]), float(serialized_position[1]))
		var tier := int(ball.get("tier", 1))
		var radius := float(ball.get("radius", 18.0))
		var visual_value := _watermelon_visual_value(tier)
		var ball_color := _fruit_color(tier)
		draw_circle(center + Vector2(0, 2), radius, Color("17090d", 0.30))
		draw_circle(center, radius, Color(ball_color, 0.14))
		draw_arc(center, radius, 0, TAU, 28, Color(ball_color.lightened(0.18), 0.34), 1.2, true)
		watermelon_presenter.draw_fruit(self, center, visual_value, radius, elapsed, catalog_fx, true, int(ball.get("id", -1)))
		var ball_number := str(int(ball.get("value", 2)))
		var number_size := 13 if ball_number.length() <= 2 else (11 if ball_number.length() <= 4 else 9)
		_draw_watermelon_number_badge(center, ball_number, number_size, maxf(9.0, radius * 0.36))

	# The next pod is deliberately painted after the crate so the hero fruit is
	# never hidden behind the upper rail.
	_draw_panel(Rect2(388, 224, 120, 86), Color("42243a", 0.96), Color("ffd17e", 0.72), 16, 2)
	_draw_text("下一个", Vector2(402, 247), 10, BRIGHT_MUTED)
	_draw_fruit(Vector2(469, 275), next_visual, 25.0, false)
	_draw_watermelon_number_badge(Vector2(469, 275), str(next_value), 12 if next_value < 100 else 10, 10.0)
	_draw_text("危险线", Vector2(414, 350), 11, Color("ffd2d8"))
	watermelon_presenter.draw_recipe_tray(self, Rect2(26, 708, 488, 142), next_visual, mini(5, highest_tier), elapsed)
	_draw_center("果园谱系 · 同值碰撞逐级丰收", Vector2(270, 742), 11, Color("fff0cc", 0.88))

func _draw_fruit(center: Vector2, value: int, radius: float, animate := true, entity_id := -1) -> void:
	watermelon_presenter.draw_fruit(self, center, value, radius, elapsed, catalog_fx, animate, entity_id)


func _draw_watermelon_number_badge(center: Vector2, label: String, font_size: int, radius: float) -> void:
	draw_circle(center + Vector2(0.8, 1.2), radius + 1.0, Color("17080c", 0.46))
	draw_circle(center, radius, Color("3a1620", 0.78))
	draw_arc(center, radius, 0, TAU, 22, Color("fff5d3", 0.54), 1.0, true)
	_draw_center_font(NUMBER_FONT, label, center + Vector2(0, -0.6), font_size, Color.WHITE)


func _watermelon_visual_value(tier: int) -> int:
	return 1 + posmod(maxi(1, tier) - 1, 5)

func _fruit_color(value: int) -> Color:
	match _watermelon_visual_value(value):
		1: return Color("f6d365")
		2: return Color("f49b67")
		3: return Color("ec6d8e")
		4: return Color("bd81e8")
		_: return Color("62d3aa")

func _fruit_symbol(value: int) -> String:
	return ["", "一", "二", "三", "四", "五"][_watermelon_visual_value(value)]

func _fruit_name(value: int) -> String:
	return ["", "柠檬", "橙子", "苹果", "葡萄", "西瓜"][_watermelon_visual_value(value)]

# -----------------------------------------------------------------------------
# Meowdoku: region-cat logic model
# -----------------------------------------------------------------------------

func _init_meowdoku() -> void:
	meowdoku_preliminary_single.clear()
	var loaded: Dictionary = meowdoku_model.load_puzzle(meowdoku_model.fixture(meowdoku_fixture_id))
	if not bool(loaded.get("ok", false)):
		push_error("Meowdoku fixture failed validation: %s" % str(loaded.get("error", "unknown")))
		state = {"status":"over", "score":0, "moves":0, "mistakes":0, "hearts":0}
		return
	var recovered := false
	if meowdoku_recovery_enabled and not meowdoku_skip_recovery_once:
		recovered = _recover_meowdoku_checkpoint()
	meowdoku_skip_recovery_once = false
	_sync_meowdoku_state()
	meowdoku_presenter.reset(elapsed, meowdoku_model.selected)
	if recovered:
		_flash_feedback("已恢复猫咪手账", Color("df77aa"))


func _sync_meowdoku_state() -> void:
	state = meowdoku_model.snapshot()
	state["score"] = maxi(0, meowdoku_model.cats.size() - meowdoku_model.given_cats.size()) * 100
	if meowdoku_model.status == meowdoku_model.WON:
		state["score"] = int(state.score) + meowdoku_model.hearts * 50
	state["checkpoint"] = meowdoku_model.checkpoint()
	selected_cell = meowdoku_model.selected


func _meowdoku_board_rect() -> Rect2:
	return meowdoku_presenter.board_rect()


func _meowdoku_cell_from_position(position: Vector2) -> Vector2i:
	var rect := _meowdoku_board_rect()
	if not rect.has_point(position) or meowdoku_model.size <= 0:
		return Vector2i(-1, -1)
	var cell_size := rect.size.x / float(meowdoku_model.size)
	return Vector2i(
		clampi(int((position.x - rect.position.x) / cell_size), 0, meowdoku_model.size - 1),
		clampi(int((position.y - rect.position.y) / cell_size), 0, meowdoku_model.size - 1)
	)


func _meowdoku_cell_center(cell: Vector2i) -> Vector2:
	var rect := _meowdoku_board_rect()
	var cell_size := rect.size.x / float(maxi(1, meowdoku_model.size))
	return rect.position + Vector2((float(cell.x) + 0.5) * cell_size, (float(cell.y) + 0.5) * cell_size)


func _meowdoku_pointer_action(position: Vector2, double_action: bool) -> Dictionary:
	var cell := _meowdoku_cell_from_position(position)
	if cell.x < 0:
		return {"changed":false, "event":"outside"}
	if double_action:
		var rolled_back := _rollback_meowdoku_preliminary_single(cell)
		var double_outcome := _meowdoku_command("cat", cell)
		if rolled_back and not bool(double_outcome.get("changed", false)):
			_persist_meowdoku_checkpoint()
		return double_outcome
	var before := meowdoku_model.checkpoint()
	var single_outcome: Dictionary
	if meowdoku_model.selected == cell:
		single_outcome = _meowdoku_command("mark", cell)
	else:
		single_outcome = _meowdoku_command("select", cell)
	meowdoku_preliminary_single = {
		"cell":cell,
		"at_msec":Time.get_ticks_msec(),
		"checkpoint":before,
	}
	return single_outcome


func _rollback_meowdoku_preliminary_single(cell: Vector2i) -> bool:
	if meowdoku_preliminary_single.is_empty():
		return false
	var previous := meowdoku_preliminary_single.duplicate(true)
	meowdoku_preliminary_single.clear()
	var age_msec := Time.get_ticks_msec() - int(previous.get("at_msec", -10000))
	if previous.get("cell", Vector2i(-1, -1)) != cell or age_msec < 0 or age_msec > 700:
		return false
	var checkpoint: Variant = previous.get("checkpoint", {})
	if not checkpoint is Dictionary:
		return false
	var restored: Dictionary = meowdoku_model.restore_checkpoint(checkpoint)
	if not bool(restored.get("ok", false)):
		return false
	_sync_meowdoku_state()
	queue_redraw()
	return true


func _meowdoku_move_selection(direction: Vector2i) -> Dictionary:
	meowdoku_preliminary_single.clear()
	var changed := meowdoku_model.move_selection(direction)
	var outcome := {"changed":changed, "event":"select", "cell":meowdoku_model.selected}
	_sync_meowdoku_state()
	if changed:
		_present_meowdoku_outcome(outcome)
		_persist_meowdoku_checkpoint()
	return outcome


func _meowdoku_command(command: String, cell := Vector2i(-1, -1)) -> Dictionary:
	if game_id != "meowdoku":
		return {"changed":false, "event":"wrong_game"}
	meowdoku_preliminary_single.clear()
	var outcome: Dictionary = meowdoku_model.apply_command(command, cell)
	_sync_meowdoku_state()
	_present_meowdoku_outcome(outcome)
	if bool(outcome.get("changed", false)):
		_persist_meowdoku_checkpoint()
	queue_redraw()
	return outcome


func _present_meowdoku_outcome(outcome: Dictionary) -> void:
	var event := str(outcome.get("event", "blocked"))
	var cell: Vector2i = outcome.get("cell", meowdoku_model.selected)
	var position := _meowdoku_cell_center(cell) if meowdoku_model.in_bounds(cell) else _meowdoku_board_rect().get_center()
	var accent := Color("df77aa")
	if event == "select":
		meowdoku_presenter.select(cell, elapsed)
	elif event not in ["blocked", "outside", "wrong_game", "unknown_command"]:
		meowdoku_presenter.present(event, cell, elapsed, outcome)
	match event:
		"select":
			_play_sfx(SFX_LOGIC_SELECT, -20.0, 1.10)
			_haptic(4)
		"mark":
			_flash_feedback("标记为排除格", Color("8d70bb"))
			_start_catalog_event("cat_mark", position, Color("9b82c7"), 1, "排除", 0.46, {"semantic":"cat_mark"})
		"unmark", "erase_mark":
			_flash_feedback("擦去排除标记", accent)
			_start_catalog_event("cat_erase", position, accent, 1, "擦去标记", 0.48, {"semantic":"cat_erase"})
		"erase_cat":
			_flash_feedback("抱回这只猫", accent)
			_start_catalog_event("cat_erase", position, accent, 1, "抱回猫咪", 0.52, {"semantic":"cat_erase"})
		"cat":
			_flash_feedback("找到猫咪 · %d/%d" % [meowdoku_model.cats.size(), meowdoku_model.size], accent)
			_start_catalog_event("cat_found", position, accent, 2, "找到猫咪", 0.66, {"semantic":"cat_found", "placed":meowdoku_model.cats.size()})
		"error":
			_flash_feedback("这里没有猫 · 还剩 %d 颗心" % meowdoku_model.hearts, RED)
			_start_catalog_event("cat_error", position, RED, 2, "失去一颗心", 0.72, {"semantic":"cat_error", "hearts":meowdoku_model.hearts})
		"loss":
			_flash_feedback("爱心用尽 · 可以重开", RED)
			_start_catalog_event("cat_loss", position, RED, 3, "爱心用尽", 0.92, {"semantic":"cat_error_loss", "hearts":0})
			_capture("meowdoku_loss")
		"complete":
			_flash_feedback("所有猫咪都找到啦", GOLD)
			_start_catalog_event("cat_complete", _meowdoku_board_rect().get_center(), GOLD, 4, "全员到齐", 1.18, {"semantic":"cat_complete"})
			_capture("meowdoku_win")
		"given":
			_flash_feedback("这是题面提示猫", Color("a85c83"))
		"occupied":
			_flash_feedback("猫咪已经在这里", accent)
		"empty":
			_flash_feedback("这里没有可清除内容", Color("8d70bb"))
	_log_event("meowdoku_%s" % event, {"cell":[cell.x, cell.y], "hearts":meowdoku_model.hearts, "status":meowdoku_model.status})


func _persist_meowdoku_checkpoint() -> void:
	if not meowdoku_recovery_enabled:
		return
	var checkpoint_text := JSON.stringify(meowdoku_model.checkpoint())
	var file := FileAccess.open("user://meowdoku_v3_checkpoint.json", FileAccess.WRITE)
	if file:
		file.store_string(checkpoint_text)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.localStorage.setItem(%s, %s)" % [JSON.stringify(MEOWDOKU_WEB_CHECKPOINT_KEY), JSON.stringify(checkpoint_text)])


func _recover_meowdoku_checkpoint() -> bool:
	if OS.has_feature("web"):
		var stored: Variant = JavaScriptBridge.eval("window.localStorage.getItem(%s) || ''" % JSON.stringify(MEOWDOKU_WEB_CHECKPOINT_KEY), true)
		if stored is String and not str(stored).is_empty():
			var web_parsed: Variant = JSON.parse_string(str(stored))
			if web_parsed is Dictionary and bool(meowdoku_model.restore_checkpoint(web_parsed).get("ok", false)):
				return true
	if not FileAccess.file_exists("user://meowdoku_v3_checkpoint.json"):
		return false
	var file := FileAccess.open("user://meowdoku_v3_checkpoint.json", FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	return bool(meowdoku_model.restore_checkpoint(parsed).get("ok", false))


func _meowdoku_restore_checkpoint(checkpoint: Dictionary) -> Dictionary:
	var result: Dictionary = meowdoku_model.restore_checkpoint(checkpoint)
	if bool(result.get("ok", false)):
		_sync_meowdoku_state()
		meowdoku_presenter.reset(elapsed, meowdoku_model.selected)
		_persist_meowdoku_checkpoint()
		queue_redraw()
	return result


# -----------------------------------------------------------------------------
# Classic numeric Sudoku
# -----------------------------------------------------------------------------

func _sudoku_solution() -> Array:
	return [
		[5,3,4,6,7,8,9,1,2], [6,7,2,1,9,5,3,4,8], [1,9,8,3,4,2,5,6,7],
		[8,5,9,7,6,1,4,2,3], [4,2,6,8,5,3,7,9,1], [7,1,3,9,2,4,8,5,6],
		[9,6,1,5,3,7,2,8,4], [2,8,7,4,1,9,6,3,5], [3,4,5,2,8,6,1,7,9]
	]

func _init_sudoku() -> void:
	if game_id == "sudoku":
		sudoku_model.reset(20260820, 36)
		if not sudoku_restart_requested:
			var saved := _load_sudoku_web_snapshot()
			if not saved.is_empty():
				sudoku_model.restore(saved)
		_sync_sudoku_state()
		selected_cell = sudoku_model.selected
		logic_game_presenter.reset(elapsed, sudoku_model.selected)
		return
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
	logic_game_presenter.reset(elapsed, Vector2i(0, 0))

func _sync_sudoku_state() -> void:
	state = sudoku_model.snapshot()
	state["game_id"] = "sudoku"
	state["reduced_effects"] = sudoku_reduced_effects

func _restore_sudoku_snapshot(saved: Dictionary) -> bool:
	if not sudoku_model.restore(saved):
		return false
	_sync_sudoku_state()
	selected_cell = sudoku_model.selected
	logic_game_presenter.reset(elapsed, sudoku_model.selected)
	_update_sudoku_tool_buttons()
	_persist_sudoku_progress()
	queue_redraw()
	return true

func _sudoku_tap(pos: Vector2) -> void:
	if game_id == "meowdoku":
		_meowdoku_pointer_action(pos, false)
		return
	var origin := Vector2(47, 236)
	var cell := 49.5
	if Rect2(origin, Vector2(cell * 9, cell * 9)).has_point(pos):
		var x := int((pos.x - origin.x) / cell)
		var y := int((pos.y - origin.y) / cell)
		if game_id == "sudoku":
			sudoku_model.select(Vector2i(x, y))
			_sync_sudoku_state()
		else:
			state["selected"] = [x, y]
		selected_cell = Vector2i(x, y)
		logic_game_presenter.select(selected_cell, elapsed)
		_play_sfx(SFX_LOGIC_SELECT, -19.0, 1.08 if game_id == "meowdoku" else 0.96)
		_haptic(4)
		_log_event("sudoku_cell_selected", {"x":x, "y":y})
		_persist_sudoku_progress()
		queue_redraw()

func _sudoku_move_selection(direction: Vector2i) -> void:
	if game_id != "sudoku" or state.get("status") != "playing":
		return
	var event: Dictionary = sudoku_model.move_selection(direction)
	if not bool(event.get("changed", false)):
		return
	_sync_sudoku_state()
	selected_cell = sudoku_model.selected
	logic_game_presenter.select(selected_cell, elapsed)
	_play_sfx(SFX_LOGIC_SELECT, -19.0, 0.96)
	_haptic(4)
	_log_event("sudoku_cell_selected", {"x":selected_cell.x, "y":selected_cell.y, "input":"keyboard"})
	_persist_sudoku_progress()
	queue_redraw()

func _sudoku_place(number: int) -> void:
	if (game_id != "sudoku" and game_id != "meowdoku") or state.get("status") != "playing":
		return
	if game_id == "meowdoku":
		_meowdoku_place(number)
		return
	_classic_sudoku_place(number)

func _classic_sudoku_place(number: int) -> void:
	var event: Dictionary = sudoku_model.erase() if number == 0 else sudoku_model.place(number)
	_sync_sudoku_state()
	_update_sudoku_tool_buttons()
	_dispatch_sudoku_event(event)

func _sudoku_toggle_notes() -> void:
	if game_id != "sudoku" or state.get("status") != "playing":
		return
	var event: Dictionary = sudoku_model.toggle_notes_mode()
	_sync_sudoku_state()
	_update_sudoku_tool_buttons()
	if bool(event.get("changed", false)):
		_flash_feedback("笔记已%s" % ("开启" if bool(event.get("enabled", false)) else "关闭"), Color("7566c7"))
		_log_event("sudoku_notes_mode", {"enabled":bool(event.get("enabled", false))})
		_persist_sudoku_progress()
	queue_redraw()

func _sudoku_hint() -> void:
	if game_id != "sudoku" or state.get("status") != "playing":
		return
	var event: Dictionary = sudoku_model.hint()
	_sync_sudoku_state()
	_update_sudoku_tool_buttons()
	_dispatch_sudoku_event(event)

func _sudoku_undo() -> void:
	if game_id != "sudoku":
		return
	var event: Dictionary = sudoku_model.undo()
	_sync_sudoku_state()
	_update_sudoku_tool_buttons()
	if bool(event.get("changed", false)):
		selected_cell = sudoku_model.selected
		var block := int(selected_cell.y / 3) * 3 + int(selected_cell.x / 3)
		logic_game_presenter.present("logic_undo", selected_cell, block, int(state.board[selected_cell.y][selected_cell.x]), 1, elapsed)
		_flash_feedback("撤销上一步", Color("7566c7"))
		_log_event("sudoku_undo", {"x":selected_cell.x, "y":selected_cell.y})
		_persist_sudoku_progress()
	queue_redraw()

func _dispatch_sudoku_event(event: Dictionary) -> void:
	if not bool(event.get("changed", false)):
		return
	var kind := str(event.get("kind", ""))
	var cell: Vector2i = event.get("cell", sudoku_model.selected)
	var block := int(event.get("block", 0))
	var number := int(event.get("value", 0))
	var position := logic_game_presenter.cell_center(cell)
	var accent := Color("7566c7")
	selected_cell = cell
	match kind:
		"error":
			_flash_feedback("这里不是 %d" % number, RED)
			logic_game_presenter.present("logic_error", cell, block, number, 2, elapsed)
			_start_catalog_event("logic_error", position, RED, 2, "红笔修正", 0.66, {"semantic":"logic_error"})
			_log_event("sudoku_mistake", {"x":cell.x, "y":cell.y, "value":number})
		"erase":
			_flash_feedback("轻轻擦去", accent)
			logic_game_presenter.present("logic_erase", cell, block, number, 1, elapsed)
			_start_catalog_event("logic_erase", position, accent, 1, "轻轻擦去", 0.54, {"semantic":"logic_erase"})
			_log_event("sudoku_erase", {"x":cell.x, "y":cell.y})
		"note":
			_flash_feedback("笔记 %d" % number, accent)
			logic_game_presenter.present("logic_note", cell, block, number, 1, elapsed)
			_log_event("sudoku_note", {"x":cell.x, "y":cell.y, "value":number, "enabled":bool(event.get("enabled", false))})
		"complete":
			_flash_feedback("整册完成", GOLD)
			logic_game_presenter.present("logic_complete", cell, block, number, 4, elapsed)
			_start_catalog_event("logic_complete", Vector2(270, 458), GOLD, 4, "整册完成", 1.18, {"semantic":"logic_complete", "action":str(event.get("action", "place"))})
			_capture("sudoku_win")
		"block_complete":
			_flash_feedback("九宫完成", accent)
			logic_game_presenter.present("logic_block_complete", cell, block, number, 3, elapsed)
			_start_catalog_event("logic_block_complete", _sudoku_block_center(block), accent, 3, "九宫完成", 0.96, {"semantic":"logic_block_complete", "action":str(event.get("action", "place"))})
			_log_event("sudoku_place", {"x":cell.x, "y":cell.y, "value":number, "action":str(event.get("action", "place"))})
		"hint":
			_flash_feedback("提示落笔 %d" % number, accent)
			logic_game_presenter.present("logic_hint", cell, block, number, 2, elapsed)
			_start_catalog_event("logic_hint", position, accent, 2, "提示落笔", 0.68, {"semantic":"logic_hint"})
			_log_event("sudoku_hint", {"x":cell.x, "y":cell.y, "value":number})
		"correct":
			_flash_feedback("落子 %d" % number, accent)
			logic_game_presenter.present("logic_correct", cell, block, number, 1, elapsed)
			_start_catalog_event("logic_correct", position, accent, 1, "落笔正确", 0.68, {"semantic":"logic_correct"})
			_log_event("sudoku_place", {"x":cell.x, "y":cell.y, "value":number})
	_persist_sudoku_progress()
	queue_redraw()

func _update_sudoku_tool_buttons() -> void:
	if game_id != "sudoku":
		return
	for button in buttons:
		if not is_instance_valid(button):
			continue
		if button.name == "SudokuNotes":
			button.text = "笔记 · %s" % ("开" if bool(state.get("notes_mode", false)) else "关")
		elif button.name == "SudokuHint":
			button.text = "提示 · %d" % int(state.get("hints_remaining", 0))

func _meowdoku_place(number: int) -> void:
	# Backward-compatible automation entry point. Numeric values are not part of
	# the target rules; zero clears and any positive value invokes the same cat
	# command as double-touch/Enter.
	_meowdoku_command("erase" if number == 0 else "cat")

func _sudoku_complete() -> bool:
	if game_id == "sudoku":
		return sudoku_model.is_complete()
	for row in state["board"]:
		for value in row:
			if int(value) == 0:
				return false
	return true

func _draw_sudoku() -> void:
	var accent := Color("7566c7")
	var ink := Color("303745")
	var detail := "选格后输入数字"
	_draw_text_font(DISPLAY_FONT, "逻辑手册", Vector2(30, 207), 18, ink)
	_draw_text(detail, Vector2(508 - UI_FONT.get_string_size(detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x, 205), 11, Color("5d6170"))
	draw_line(Vector2(30, 216), Vector2(510, 216), Color(accent, 0.44), 2.0)
	logic_game_presenter.draw_board(self, game_id, state, elapsed, NUMBER_FONT, sudoku_reduced_effects)
	_draw_text("同行、同列与九宫同步定位", Vector2(47, 706), 13, Color("4f5665"))


func _draw_meowdoku() -> void:
	meowdoku_presenter.draw_board(self, state, elapsed, UI_FONT, reduced_effects)

func _sudoku_block_center(block: int) -> Vector2:
	var bx := block % 3
	var by := int(block / 3)
	return Vector2(47, 236) + Vector2((float(bx) * 3.0 + 1.5) * 49.5, (float(by) * 3.0 + 1.5) * 49.5)

func _sudoku_block_complete(block: int) -> bool:
	if game_id == "sudoku":
		return sudoku_model.block_complete(block)
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
	var recovered := _restore_snake_gb_snapshot(_load_snake_gb_web_recovery())
	_sync_snake_gb_state()
	snake_ghosts.clear()
	snake_pixels.clear()
	snake_float_labels.clear()
	snake_previous_cells.clear()
	snake_fx_kind = ""
	snake_fx_direction = Vector2i.RIGHT
	snake_gb_object_fx.clear()
	snake_result_ready_at = -1.0
	snake_lcd_flash_until = -1.0
	snake_score_bump_until = -1.0
	snake_button_direction = Vector2i.ZERO
	snake_button_until = -1.0
	snake_reject_until = -1.0
	snake_drag_active = false
	snake_drag_samples.clear()
	snake_last_swipe_at = -10.0
	snake_reset_started = elapsed
	if recovered and state.get("status", "playing") == "over":
		snake_result_ready_at = elapsed

func _sync_snake_gb_state() -> void:
	state = snake_gb_model.snapshot()
	state["game_id"] = game_id

func _snake_gb_update(delta: float) -> void:
	snake_clock += delta
	if snake_clock < SNAKE_GB_STEP_INTERVAL:
		return
	snake_clock = fmod(snake_clock, SNAKE_GB_STEP_INTERVAL)
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
				snake_gb_object_fx = {
					"kind":"turn_accepted", "grade":1, "started":elapsed,
					"duration":_snake_gb_effect_duration(0.28), "direction":snake_button_direction
				}
				_play_sfx(SFX_SNAKE_KEY, -10.0, 0.90 + float(posmod(snake_gb_model.step_index, 4)) * 0.035)
				_haptic(8)
			"turn_rejected":
				snake_reject_direction = _snake_vector(event.get("direction", Vector2i.ZERO))
				snake_reject_until = elapsed + 0.14
				snake_gb_object_fx = {
					"kind":"turn_rejected", "grade":1, "started":elapsed,
					"duration":_snake_gb_effect_duration(0.28), "direction":snake_reject_direction,
					"reason":str(event.get("reason", "invalid"))
				}
				_play_sfx(SFX_SNAKE_REJECT, -14.0, 0.78)
				_haptic(6)
			"moved":
				if bool(event.get("tail_vacated", false)):
					snake_ghosts.append({"cell":event.get("tail", Vector2i.ZERO), "until":elapsed + 0.10})
			"ate":
				snake_fx_kind = "eat"
				snake_fx_started = elapsed
				snake_fx_cell = _snake_vector(event.get("at", Vector2i.ZERO))
				snake_gb_object_fx = {
					"kind":"forage", "grade":2, "started":elapsed,
					"duration":_snake_gb_effect_duration(0.54, 0.18), "cell":snake_fx_cell,
					"pending_growth":int(event.get("pending_growth", 2))
				}
				snake_lcd_flash_until = elapsed + (0.04 if reduced_effects else 0.09)
				snake_score_bump_until = elapsed + (0.08 if reduced_effects else 0.22)
				_snake_gb_emit_pixels(snake_fx_cell, 10, "eat")
				snake_float_labels.append({
					"cell":snake_fx_cell, "started":elapsed, "text":"+2",
					"duration":_snake_gb_effect_duration(0.72, 0.18),
				})
				_play_sfx(SFX_SNAKE_GB_GAG_COLLECT, -6.5, 0.98 + float(posmod(int(state.get("score", 4)), 3)) * 0.025)
				_haptic(18)
				_log_event("snake_gb_food", {"length":int(state.get("score", 4)), "growth_queued":int(event.get("growth_queued", 2))})
			"growth_materialized":
				snake_score_bump_until = elapsed + 0.24
			"length_milestone":
				var reached_length := int(event.get("score", state.get("score", 4)))
				snake_fx_kind = "milestone"
				snake_fx_started = elapsed
				snake_fx_cell = snake_gb_model.segments.back()
				snake_gb_object_fx = {
					"kind":"field_log", "grade":3, "started":elapsed,
					"duration":_snake_gb_effect_duration(0.82, 0.22),
					"cell":snake_fx_cell, "score":reached_length,
					"nonterminal":true,
				}
				_snake_gb_emit_pixels(snake_fx_cell, 16, "milestone")
				_play_sfx(SFX_SNAKE_GB_GAG_COLLECT, -4.5, 0.78)
				_play_sfx(SFX_SNAKE_KEY, -9.0, 1.16)
				_haptic(28)
				_log_event("snake_gb_field_log", {"length":reached_length, "grade":3, "nonterminal":true})
			"wall_hit", "self_hit":
				snake_fx_kind = "crash"
				snake_fx_started = elapsed
				snake_fx_cell = _snake_vector(event.get("to", Vector2i.ZERO))
				snake_fx_direction = snake_gb_model.direction
				snake_gb_object_fx = {
					"kind":"crash", "grade":4, "started":elapsed,
					"duration":_snake_gb_effect_duration(0.78, 0.18), "cell":snake_fx_cell,
					"direction":snake_fx_direction, "reason":kind
				}
				snake_result_ready_at = elapsed + 0.62
				_snake_gb_emit_pixels(snake_fx_cell, 14, "crash")
				_play_sfx(SFX_SNAKE_CRASH, -5.0, 0.82)
				_haptic(50)
				_capture("snake_gb_%s" % kind)
			"field_record_complete":
				snake_fx_kind = "complete"
				snake_fx_started = elapsed
				snake_fx_cell = snake_gb_model.segments[0]
				snake_gb_object_fx = {
					"kind":"complete", "grade":4, "started":elapsed,
					"duration":_snake_gb_effect_duration(1.56, 0.26), "cell":snake_fx_cell,
					"score":int(event.get("score", 120)), "nonterminal":true,
				}
				_snake_gb_emit_pixels(snake_fx_cell, 22, "complete")
				_play_sfx(SFX_SNAKE_GB_GAG_COMPLETE, -3.5, 1.0)
				_haptic(82)
				_capture("snake_gb_field_record")

func _snake_gb_effect_duration(full_duration: float, reduced_duration := 0.12) -> float:
	return reduced_duration if reduced_effects else full_duration

func _snake_gb_emit_pixels(cell: Vector2i, count: int, kind: String) -> void:
	if reduced_effects:
		return
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
	arena_recovered_from_snapshot = false
	if not arena_restart_requested:
		var saved := _load_snakes_web_snapshot()
		if not saved.is_empty():
			arena_recovered_from_snapshot = snakes_arena_model.restore(saved)
			if not arena_recovered_from_snapshot:
				_clear_snakes_web_snapshot()
	if arena_recovered_from_snapshot:
		# A reload must never synthesize a held boost input.
		snakes_arena_model.set_player_boost(false)
		if not snakes_arena_model.snakes.is_empty():
			snakes_arena_model.snakes[snakes_arena_model.player_index]["boost_requested"] = false
			snakes_arena_model.snakes[snakes_arena_model.player_index]["boosting"] = false
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
	arena_knockout_started = -10.0
	arena_knockout_world = Vector2.ZERO
	arena_knockout_killer_id = -1
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
	state["recovered"] = arena_recovered_from_snapshot
	state["reduced_effects"] = snakes_reduced_effects
	state["score"] = roundi(float(state.get("mass", 0.0)))
	state["moves"] = int(state.get("tick", 0))

func _restore_snakes_snapshot(saved: Dictionary) -> bool:
	if not snakes_arena_model.restore(saved):
		return false
	arena_recovered_from_snapshot = true
	_clear_arena_boost_requests()
	if not snakes_arena_model.snakes.is_empty():
		snakes_arena_model.snakes[snakes_arena_model.player_index]["boost_requested"] = false
		snakes_arena_model.snakes[snakes_arena_model.player_index]["boosting"] = false
	_sync_snakes_arena_state()
	arena_camera = _arena_player_world_position()
	arena_camera_previous = arena_camera
	arena_last_player_position = arena_camera
	queue_redraw()
	return true

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
		if current_leader_id == int(state.get("player_id", 0)):
			_play_sfx(SFX_SNAKES_GAG_LEADER, -5.5, 1.0)
			_haptic(38)
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
		if improved and current_rank != 1:
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
				_play_sfx(SFX_SNAKES_GAG_CHOMP, -6.5, 0.96 + minf(0.16, value * 0.030))
				_haptic(14)
				_log_event("snakes_seed", {"mass":float(state.get("mass", 0.0))})
				_persist_snakes_progress()
			"boost_started":
				if int(event.get("id", -1)) == 0:
					_snakes_arena_emit_fx("boost", _arena_player_world_position(), Color("06ddea"), 7)
					_play_sfx(SFX_SNAKES_GAG_BOOST, -8.0, 1.04)
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
				arena_knockout_started = elapsed
				arena_knockout_world = bot_at
				arena_knockout_killer_id = int(event.get("killer_id", -1))
				arena_competition_world = bot_at
				arena_competition_until = elapsed + 1.24
				_snakes_arena_emit_fx("debris", bot_at, Color("ffd92f"), 20)
				arena_float_labels.append({"world":bot_at, "started":elapsed, "text":"彩豆散开！", "color":Color("fff1ce")})
				_play_sfx(SFX_SNAKES_GAG_KNOCKOUT, -5.5 if arena_knockout_killer_id == int(state.get("player_id", 0)) else -9.0, 1.02)
				arena_camera_shake = Vector2(5.0, 3.0) if not snakes_reduced_effects else Vector2.ZERO
				if arena_knockout_killer_id == int(state.get("player_id", 0)):
					_haptic(34)
			"bot_ate":
				var forage_at := _arena_vector(event.get("at", Vector2.ZERO))
				var forage_value := float(event.get("value", 1.0))
				_snakes_arena_emit_fx("scavenge", forage_at, Color("ffe28a"), 5)
				arena_float_labels.append({"world":forage_at, "started":elapsed, "text":"抢食 +%.1f" % forage_value, "color":Color("fff2b8")})
			"player_died":
				var player_at := _arena_vector(event.get("at", _arena_player_world_position()))
				arena_knockout_started = elapsed
				arena_knockout_world = player_at
				arena_knockout_killer_id = int(event.get("killer_id", -1))
				if arena_death_segments.is_empty():
					var dead_player: Dictionary = state.get("player", {})
					arena_death_segments = dead_player.get("segments", []).duplicate(true)
					arena_death_started = elapsed
					arena_death_skin = int(dead_player.get("skin", 0))
					arena_death_mass = float(dead_player.get("mass", 38.0))
					arena_death_heading = float(dead_player.get("heading", 0.0))
				_clear_arena_boost_requests()
				arena_pointer_active = false
				arena_result_ready_at = elapsed if snakes_reduced_effects else elapsed + 0.72
				_snakes_arena_emit_fx("death", player_at, Color("ff3341"), 28)
				arena_camera_shake = Vector2(10.0, 6.0) if not snakes_reduced_effects else Vector2.ZERO
				_play_sfx(SFX_SNAKES_GAG_KNOCKOUT, -3.5, 0.86)
				_play_sfx(SFX_SNAKE_CRASH, -11.0, 0.82)
				_haptic(62)
				_clear_snakes_web_snapshot()
				_capture("snakes_player_died")

func _snakes_arena_emit_fx(kind: String, world: Vector2, color: Color, count: int) -> void:
	if snakes_reduced_effects:
		return
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
	if snakes_reduced_effects:
		arena_fx.clear()
		arena_camera_shake = Vector2.ZERO
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
	if screen != "game" or game_id != "snake_classic" or state.get("status", "playing") != "playing":
		return
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
	return SNAKE_GB_STEP_INTERVAL if game_id == "snake_classic" else SNAKE_STEP_INTERVAL

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
		if elapsed - float(snake_float_labels[index].get("started", 0.0)) >= float(snake_float_labels[index].get("duration", 0.72)):
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

func _snake_gb_object_fx_age() -> float:
	return elapsed - float(snake_gb_object_fx.get("started", -10.0))

func _snake_gb_feedback_offset() -> Vector2:
	if reduced_effects:
		return Vector2.ZERO
	var kind := str(snake_gb_object_fx.get("kind", ""))
	var age := _snake_gb_object_fx_age()
	match kind:
		"crash":
			if age >= 0.0 and age < 0.34:
				var force := (1.0 - age / 0.34) * 4.2
				var sign_value := 1.0 if int(age * 92.0) % 2 == 0 else -1.0
				return Vector2(sign_value * force, sign_value * force * 0.34)
		"field_log":
			if age >= 0.0 and age < 0.42:
				var force := sin(age * 68.0) * (1.0 - age / 0.42) * 1.8
				return Vector2(force, -absf(force) * 0.34)
		"complete":
			if age >= 0.12 and age < 0.64:
				var force := sin(age * 55.0) * (1.0 - age / 0.64) * 1.45
				return Vector2(force, -force * 0.24)
	return Vector2.ZERO

func _draw_snake_gb_texture_center(texture: Texture2D, center: Vector2, size_value: Vector2, modulate := Color.WHITE) -> void:
	draw_texture_rect(texture, Rect2(center - size_value * 0.5, size_value), false, modulate)

func _draw_snake_gb_head(center: Vector2, direction: Vector2i, alpha := 1.0, scale_value := 1.0, stretch := Vector2.ONE) -> void:
	var safe_direction := direction if direction != Vector2i.ZERO else Vector2i.RIGHT
	var angle := Vector2(safe_direction).angle()
	var size_value := Vector2(19.2, 13.2) * scale_value * stretch
	draw_set_transform(center, angle, Vector2.ONE)
	draw_texture_rect(SNAKE_GB_GAG_HEAD_TEXTURE, Rect2(-size_value * 0.5, size_value), false, Color(0.60, 0.68, 0.42, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_snake_gb_lure(center: Vector2, scale_value := 1.0, alpha := 1.0) -> void:
	var size_value := Vector2(11.8, 15.8) * scale_value
	_draw_snake_gb_texture_center(SNAKE_GB_GAG_LURE_TEXTURE, center, size_value, Color(0.66, 0.72, 0.45, alpha))

func _draw_snake_gb_field_seal(offset: Vector2) -> void:
	var kind := str(snake_gb_object_fx.get("kind", ""))
	var age := _snake_gb_object_fx_age()
	var pulse := 0.0
	var duration := maxf(0.01, float(snake_gb_object_fx.get("duration", 0.82)))
	if not reduced_effects and kind == "field_log" and age >= 0.0 and age < duration:
		pulse = sin(clampf(age / duration, 0.0, 1.0) * PI) * 0.12
	elif not reduced_effects and kind == "complete" and age >= 0.0 and age < duration:
		pulse = sin(clampf(age / duration, 0.0, 1.0) * PI) * 0.18
	var center := Vector2(270, 105) + offset * 0.58
	var size_value := Vector2.ONE * 54.0 * (1.0 + pulse)
	if pulse > 0.015:
		draw_circle(center, 34.0 + pulse * 34.0, Color("e8c96e", pulse * 0.34))
		draw_arc(center, 30.0 + pulse * 28.0, -PI * 0.90, PI * 0.90, 38, Color("f6df8e", pulse * 2.4), 2.0)
	_draw_snake_gb_texture_center(SNAKE_GB_GAG_FIELD_SEAL_TEXTURE, center, size_value)

func _draw_snake_gb_experience() -> void:
	draw_texture_rect(SNAKE_GB_TEXTURE, Rect2(Vector2.ZERO, VIEW_SIZE), false)
	var shake := _snake_gb_feedback_offset()
	_draw_panel(Rect2(12, 18, 90, 50), Color("9b9361", 0.86), Color("d7c792", 0.34), 14, 1)
	_draw_panel(Rect2(438, 18, 90, 50), Color("9b9361", 0.86), Color("d7c792", 0.34), 14, 1)
	_draw_center("收盒", Vector2(57, 44), 13, Color("27271d"))
	_draw_center("重开", Vector2(483, 44), 13, Color("27271d"))
	_draw_snake_gb_field_seal(shake)
	_draw_center_font(LATIN_FONT, "GB SNAKE · FIELD LOG", Vector2(270, 149) + shake * 0.58, 11, Color("c9bd85"))
	_draw_snake_gb_lcd(shake)
	_draw_snake_gb_controls(shake * 0.36)
	_draw_snake_gb_fx(shake)
	var status := str(state.get("status", "playing"))
	if status != "playing" and snake_result_ready_at > 0.0 and elapsed >= snake_result_ready_at:
		_draw_snake_gb_terminal()
	elif elapsed - snake_reset_started < 4.6:
		var prompt_alpha := clampf(1.0 - maxf(0.0, elapsed - snake_reset_started - 3.4) / 1.2, 0.0, 1.0)
		_draw_center("滑动或方向键转向 · 吃食物长两格", Vector2(270, 758), 13, Color("d8c995", 0.82 * prompt_alpha))

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
	_draw_center_font(NUMBER_FONT, "FIELD 120", Vector2(270, 175) + offset, 10, Color(lcd_ink, 0.88))
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
	var active_foods: Array = state.get("foods", [])
	var food_wave := 0.0 if reduced_effects else sin(elapsed * 6.6)
	var lock_wave := 0.0 if reduced_effects else sin(elapsed * 3.8)
	for food_index in range(active_foods.size()):
		var food_cell := _snake_vector(active_foods[food_index])
		var food_center := _snake_gb_cell_center(food_cell) + offset
		var phase_offset := -1.0 if food_index % 2 == 1 else 1.0
		var food_pulse := 0.935 + food_wave * 0.055 * phase_offset
		var food_scale := 1.0 + food_wave * 0.045 * phase_offset
		_draw_snake_gb_lure(food_center, food_scale, food_pulse)
		var lock_alpha := 0.255 + lock_wave * 0.055 * phase_offset
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			var anchor: Vector2 = food_center + Vector2(corner) * 8.7
			draw_line(anchor, anchor - Vector2(corner.x, 0) * 3.2, Color(lcd_mid, lock_alpha), 1.0)
			draw_line(anchor, anchor - Vector2(0, corner.y) * 3.2, Color(lcd_mid, lock_alpha), 1.0)
	var segments: Array = state.get("segments", [])
	var move_progress := clampf((elapsed - snake_move_started) / SNAKE_GB_STEP_INTERVAL, 0.0, 1.0)
	var phosphor_progress := 1.0 if reduced_effects else floorf(move_progress * 3.0) / 3.0
	var visual_head_center := Vector2.ZERO
	for index in range(segments.size() - 1, -1, -1):
		var segment := _snake_vector(segments[index])
		var visual := Vector2(segment)
		if index < snake_previous_cells.size():
			visual = Vector2(_snake_vector(snake_previous_cells[index])).lerp(Vector2(segment), phosphor_progress)
		var rect := Rect2(origin + visual * cell + Vector2(1.5, 1.5) + offset, Vector2(cell - 3.0, cell - 3.0))
		var body_alpha := 1.0 if index == 0 else 0.90 - minf(0.18, float(index) * 0.004)
		if index == 0:
			var direction := _snake_vector(state.get("direction", [1, 0]))
			visual_head_center = rect.get_center()
			_draw_snake_gb_head(visual_head_center, direction, body_alpha, 1.0)
		else:
			draw_rect(rect, Color(lcd_ink, body_alpha))
			if index % 3 == 0:
				draw_rect(Rect2(rect.position, Vector2(2.0, 2.0)), Color(lcd_mid, 0.46))
				draw_rect(Rect2(rect.end - Vector2(2.0, 2.0), Vector2(2.0, 2.0)), Color(lcd_mid, 0.46))
			var scale_mark := rect.get_center() + Vector2(-2.0 if index % 2 == 0 else 1.0, -2.0)
			draw_rect(Rect2(scale_mark, Vector2(2.4, 1.3)), Color("8b9c65", 0.27))
	var fx_kind := str(snake_gb_object_fx.get("kind", ""))
	var fx_age := _snake_gb_object_fx_age()
	var fx_duration := maxf(0.01, float(snake_gb_object_fx.get("duration", 0.28)))
	if visual_head_center != Vector2.ZERO and fx_age >= 0.0 and fx_age < fx_duration:
		var fx_progress := clampf(fx_age / fx_duration, 0.0, 1.0)
		if fx_kind == "turn_accepted":
			var requested := _snake_vector(snake_gb_object_fx.get("direction", Vector2i.RIGHT))
			var forward := Vector2(requested)
			var side := Vector2(-forward.y, forward.x)
			var bracket_alpha := sin(fx_progress * PI) * 0.86
			for side_sign in [-1.0, 1.0]:
				var bracket: Vector2 = visual_head_center + side * float(side_sign) * 9.4 + forward * 1.8
				draw_line(bracket - forward * 4.2, bracket + forward * 4.2, Color(lcd_ink, bracket_alpha), 1.5)
				draw_line(bracket + forward * 4.2, bracket + forward * 6.4 - side * side_sign * 2.0, Color(lcd_ink, bracket_alpha), 1.5)
		elif fx_kind == "turn_rejected":
			var rejected := _snake_vector(snake_gb_object_fx.get("direction", Vector2i.LEFT))
			var kick := sin(fx_progress * PI) * 6.0
			_draw_snake_gb_head(visual_head_center + Vector2(rejected) * kick, rejected, (1.0 - fx_progress) * 0.22, 0.88)
			draw_line(visual_head_center - Vector2(5, 5), visual_head_center + Vector2(5, 5), Color(lcd_ink, (1.0 - fx_progress) * 0.62), 1.5)
			draw_line(visual_head_center + Vector2(-5, 5), visual_head_center + Vector2(5, -5), Color(lcd_ink, (1.0 - fx_progress) * 0.62), 1.5)
	var recorded_logs := clampi(int(state.get("score", 4)) / 10, 0, 12)
	for log_index in range(12):
		var notch_x := 123.0 + float(log_index) * 26.5
		var filled := log_index < recorded_logs
		var notch_height := 6.0 if filled else 3.0
		var notch_alpha := 0.88 if filled else 0.20
		if fx_kind == "field_log" and log_index == recorded_logs - 1 and fx_age >= 0.0 and fx_age < fx_duration:
			notch_height += sin(clampf(fx_age / fx_duration, 0.0, 1.0) * PI) * 5.0
			notch_alpha = 1.0
		draw_rect(Rect2(Vector2(notch_x, 496.0 - notch_height) + offset, Vector2(3.0, notch_height)), Color(lcd_ink, notch_alpha))
	for y in range(int(screen_rect.position.y + 3), int(screen_rect.end.y - 3), 3):
		draw_line(Vector2(screen_rect.position.x + 4, y), Vector2(screen_rect.end.x - 4, y), Color("1d2618", 0.026), 1.0)
	var glare := PackedVector2Array([screen_rect.position + Vector2(16, 7), screen_rect.position + Vector2(104, 7), screen_rect.position + Vector2(47, 114)])
	draw_colored_polygon(glare, Color("f4f1c5", 0.035))

func _draw_snake_gb_controls(offset := Vector2.ZERO) -> void:
	var direction_centers := {
		Vector2i.UP:Vector2(159, 581) + offset, Vector2i.LEFT:Vector2(107, 635) + offset,
		Vector2i.RIGHT:Vector2(211, 635) + offset, Vector2i.DOWN:Vector2(159, 689) + offset
	}
	if elapsed < snake_button_until and direction_centers.has(snake_button_direction):
		var press_progress := clampf((snake_button_until - elapsed) / 0.11, 0.0, 1.0)
		var center: Vector2 = direction_centers[snake_button_direction] + Vector2(snake_button_direction) * (1.0 + press_progress)
		draw_circle(center, 18.0, Color("e7d5a8", 0.18 + press_progress * 0.08))
		draw_arc(center, 21.0, 0, TAU, 28, Color("fff3cc", 0.42 + press_progress * 0.28), 2.0)
		draw_circle(center + Vector2(snake_button_direction) * 10.0, 2.4, Color("fff3cc", 0.72))
	if elapsed < snake_reject_until and direction_centers.has(snake_reject_direction):
		var reject_progress := clampf((snake_reject_until - elapsed) / 0.14, 0.0, 1.0)
		var kick := sin((1.0 - reject_progress) * PI) * 4.0
		var rejected_center: Vector2 = direction_centers[snake_reject_direction] - Vector2(snake_reject_direction) * kick
		draw_arc(rejected_center, 22.0, 0, TAU, 28, Color("d35f51", 0.72), 2.0)
		draw_line(rejected_center - Vector2(6, 6), rejected_center + Vector2(6, 6), Color("d35f51", 0.64), 2.0)
	var action_glow := 0.08 if reduced_effects else 0.08 + (sin(elapsed * 2.4) + 1.0) * 0.025
	draw_circle(Vector2(410, 610) + offset, 32.0, Color("c76855", action_glow))
	draw_circle(Vector2(330, 647) + offset, 29.0, Color("c76855", action_glow * 0.72))

func _draw_snake_gb_fx(offset: Vector2) -> void:
	for pixel in snake_pixels:
		var age := elapsed - float(pixel.get("started", elapsed))
		var life := float(pixel.get("life", 0.35))
		var progress := clampf(age / life, 0.0, 1.0)
		var kind := str(pixel.get("kind", "gb_eat"))
		var base := _snake_gb_impact_point(pixel.get("cell", Vector2i.ZERO)) if kind == "gb_crash" else _snake_gb_cell_center(pixel.get("cell", Vector2i.ZERO))
		var p := base + Vector2(pixel.get("velocity", Vector2.ZERO)) * age + offset
		var size_value := float(pixel.get("size", 2.0)) * (1.0 - progress * 0.5)
		var color := Color("e8dfa7") if kind == "gb_complete" else Color("29351f")
		draw_rect(Rect2(p - Vector2.ONE * size_value * 0.5, Vector2.ONE * size_value), Color(color, 1.0 - progress))
	if snake_fx_kind == "eat":
		var age := elapsed - snake_fx_started
		var duration := maxf(0.01, float(snake_gb_object_fx.get("duration", 0.54)))
		if age >= 0.0 and age < duration:
			var p := _snake_gb_cell_center(snake_fx_cell) + offset
			var progress := clampf(age / duration, 0.0, 1.0)
			if progress < 0.34:
				var contract := 1.0 - progress / 0.34
				_draw_snake_gb_lure(p, 0.36 + contract * 0.82, contract * 0.86)
				for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
					var anchor: Vector2 = p + Vector2(corner) * lerpf(11.0, 6.2, 1.0 - contract)
					draw_line(anchor, anchor - Vector2(corner.x, 0) * 4.0, Color("27321e", contract * 0.84), 1.4)
					draw_line(anchor, anchor - Vector2(0, corner.y) * 4.0, Color("27321e", contract * 0.84), 1.4)
			var scan_progress := clampf((progress - 0.15) / 0.67, 0.0, 1.0)
			if scan_progress > 0.0 and scan_progress < 1.0:
				draw_arc(p, lerpf(5.0, 24.0, scan_progress), 0, TAU, 28, Color("27321e", (1.0 - scan_progress) * 0.92), 2.0)
				draw_line(p + Vector2(-22.0, lerpf(-9.0, 11.0, scan_progress)), p + Vector2(22.0, lerpf(-9.0, 11.0, scan_progress)), Color("536342", (1.0 - progress) * 0.48), 1.0)
	elif snake_fx_kind == "milestone":
		var age := elapsed - snake_fx_started
		var duration := maxf(0.01, float(snake_gb_object_fx.get("duration", 0.82)))
		if age >= 0.0 and age < duration:
			var progress := clampf(age / duration, 0.0, 1.0)
			var screen_rect := Rect2(111, 157, 318, 346)
			var sweep_y := lerpf(screen_rect.position.y + 18.0, screen_rect.end.y - 16.0, clampf(progress * 1.32, 0.0, 1.0))
			var sweep_alpha := sin(progress * PI) * 0.72
			draw_line(Vector2(screen_rect.position.x + 7.0, sweep_y) + offset, Vector2(screen_rect.end.x - 7.0, sweep_y) + offset, Color("27321e", sweep_alpha), 2.0)
			draw_line(Vector2(screen_rect.position.x + 18.0, sweep_y - 8.0) + offset, Vector2(screen_rect.end.x - 18.0, sweep_y - 8.0) + offset, Color("536342", sweep_alpha * 0.62), 1.0)
			var score_value := int(snake_gb_object_fx.get("score", state.get("score", 4)))
			_draw_center_font(NUMBER_FONT, "FIELD LOG %03d" % score_value, Vector2(270, 211) + offset + Vector2(0, -5.0 * (1.0 - progress)), 12, Color("27321e", sweep_alpha))
	elif snake_fx_kind == "crash":
		var age := elapsed - snake_fx_started
		var duration := maxf(0.01, minf(0.36, float(snake_gb_object_fx.get("duration", 0.36))))
		if age >= 0.0 and age < duration:
			var p := _snake_gb_impact_point(snake_fx_cell) + offset
			var progress := clampf(age / duration, 0.0, 1.0)
			var direction := snake_fx_direction if snake_fx_direction != Vector2i.ZERO else Vector2i.RIGHT
			_draw_snake_gb_head(p - Vector2(direction) * progress * 4.0, direction, (1.0 - progress) * 0.72, 1.10, Vector2(1.0 - progress * 0.46, 1.0 + progress * 0.38))
			for smear in range(3):
				var side := Vector2(-direction.y, direction.x)
				var from := p - Vector2(direction) * (5.0 + smear * 5.0) + side * (float(smear) - 1.0) * 3.0
				draw_line(from, from - Vector2(direction) * (13.0 + smear * 4.0), Color("27321e", (1.0 - progress) * (0.62 - smear * 0.12)), 2.0)
			for ring in range(3):
				draw_arc(p, 6.0 + progress * duration * (52.0 + ring * 18.0), 0, TAU, 24, Color("27321e", (1.0 - progress) * (0.86 - ring * 0.18)), 2.0)
	elif snake_fx_kind == "complete":
		var age := elapsed - snake_fx_started
		var duration := maxf(0.01, float(snake_gb_object_fx.get("duration", 1.56)))
		if age >= 0.0 and age < duration:
			var progress := clampf(age / duration, 0.0, 1.0)
			var screen_rect := Rect2(111, 157, 318, 346)
			for sweep in range(3):
				var local_progress := clampf(progress * 1.58 - float(sweep) * 0.14, 0.0, 1.0)
				var sweep_y := lerpf(screen_rect.end.y - 9.0, screen_rect.position.y + 9.0, local_progress)
				var sweep_alpha := sin(local_progress * PI) * (0.70 - float(sweep) * 0.13)
				draw_line(Vector2(screen_rect.position.x + 6.0 + sweep * 8.0, sweep_y) + offset, Vector2(screen_rect.end.x - 6.0 - sweep * 8.0, sweep_y) + offset, Color("27321e", sweep_alpha), 2.0 if sweep == 0 else 1.0)
			if progress < 0.74:
				_draw_center_font(NUMBER_FONT, "FIELD RECORD 120", Vector2(270, 225) + offset, 14, Color("27321e", sin(clampf(progress / 0.74, 0.0, 1.0) * PI)))
	for label in snake_float_labels:
		var age := elapsed - float(label.get("started", elapsed))
		var progress := clampf(age / maxf(0.01, float(label.get("duration", 0.72))), 0.0, 1.0)
		var p := _snake_gb_cell_center(label.get("cell", Vector2i.ZERO)) + Vector2(0, -9.0 - 18.0 * progress) + offset
		_draw_center_font(NUMBER_FONT, str(label.get("text", "+2")), p, 12, Color("27321e", 1.0 - progress))

func _draw_snake_gb_terminal() -> void:
	var panel := Rect2(130, 291, 280, 126)
	_draw_panel(panel, Color("8e9d6d", 0.94), Color("27321e", 0.92), 3, 3)
	for y in range(int(panel.position.y + 4), int(panel.end.y - 4), 4):
		draw_line(Vector2(panel.position.x + 5, y), Vector2(panel.end.x - 5, y), Color("27321e", 0.035), 1.0)
	_draw_center_font(NUMBER_FONT, "GAME OVER", Vector2(270, 326), 20, Color("27321e"))
	var reason := "SELF HIT" if str(state.get("terminal_reason", "")) == "self" else "WALL HIT"
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
	if not snakes_reduced_effects and shake_force > 0.1:
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
	if not snakes_reduced_effects and elapsed - arena_reset_started < 0.65:
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
	if not snakes_reduced_effects and elapsed < arena_competition_until:
		var contest_age := maxf(0.0, 1.24 - (arena_competition_until - elapsed))
		var contest_progress := clampf(contest_age / 1.24, 0.0, 1.0)
		var contest_center := _arena_world_to_screen(arena_competition_world, scale_value, shake)
		for ring in range(3):
			var contest_radius := 18.0 + contest_progress * (48.0 + float(ring) * 15.0)
			draw_arc(contest_center, contest_radius, 0, TAU, 42, Color("ffe28a", (1.0 - contest_progress) * (0.52 - float(ring) * 0.10)), 1.6)
	_draw_snakes_arena_knockout_material(scale_value, shake)
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
	var pulse := 1.0 if snakes_reduced_effects else 1.0 + sin(elapsed * 4.8 + float(int(pellet.get("id", 0)) % 13)) * 0.075
	var draw_radius := radius * pulse
	draw_circle(p, draw_radius * 2.25, Color(color, 0.13 if source == "debris" else 0.09))
	var bean_width := clampf(draw_radius * 2.05, 16.0, 22.0)
	var bean_height := bean_width * 0.875
	var bean_rotation := float(posmod(int(pellet.get("id", 0)) * 37, 29)) * 0.105
	if source == "debris":
		bean_rotation += 0.0 if snakes_reduced_effects else elapsed * 1.45
		draw_arc(p, bean_width * 0.68, bean_rotation, bean_rotation + PI * 1.38, 18, Color("fff1ce", 0.62), 1.6)
	draw_set_transform(p, bean_rotation, Vector2.ONE)
	draw_texture_rect(
		SNAKES_GAG_PRIZE_BEAN_TEXTURE,
		Rect2(Vector2(-bean_width, -bean_height) * 0.5, Vector2(bean_width, bean_height)),
		false,
		color.lightened(0.12)
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if source == "debris":
		var sparkle := p + Vector2.from_angle(bean_rotation - 0.7) * bean_width * 0.58
		draw_line(sparkle - Vector2(2.5, 0), sparkle + Vector2(2.5, 0), Color("ffffff", 0.84), 1.5, true)
		draw_line(sparkle - Vector2(0, 2.5), sparkle + Vector2(0, 2.5), Color("ffffff", 0.84), 1.5, true)

func _draw_snakes_arena_knockout_material(scale_value: float, shake: Vector2) -> void:
	if snakes_reduced_effects:
		return
	var age := elapsed - arena_knockout_started
	if age < 0.0 or age > 0.92:
		return
	var center := _arena_world_to_screen(arena_knockout_world, scale_value, shake)
	var size_value := 64.0
	var alpha := 1.0
	var squash := Vector2(1.16, 0.70)
	if age < 0.10:
		var anticipation := clampf(age / 0.10, 0.0, 1.0)
		size_value = lerpf(58.0, 86.0, anticipation)
		squash = Vector2(1.22 - anticipation * 0.12, 0.62 + anticipation * 0.28)
		alpha = lerpf(0.52, 0.94, anticipation)
	elif age < 0.32:
		var impact := clampf((age - 0.10) / 0.22, 0.0, 1.0)
		size_value = lerpf(86.0, 144.0, sin(impact * PI * 0.72))
		squash = Vector2.ONE * (1.0 + sin(impact * PI) * 0.10)
		alpha = 1.0
	else:
		var settle := clampf((age - 0.32) / 0.60, 0.0, 1.0)
		size_value = lerpf(140.0, 112.0, settle)
		squash = Vector2.ONE
		alpha = 1.0 - settle
	var draw_size := Vector2(size_value, size_value)
	draw_set_transform(center, age * 0.44, squash)
	draw_texture_rect(
		SNAKES_GAG_KNOCKOUT_BURST_TEXTURE,
		Rect2(-draw_size * 0.5, draw_size),
		false,
		Color(1.0, 1.0, 1.0, alpha)
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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
	if snakes_reduced_effects:
		steer_intensity = 0.0
		eat_intensity = 0.0
		boost_intensity = 0.0
	var head_scale := Vector2(1.10 + steer_intensity * 0.13 + eat_intensity * 0.20 + boost_intensity * 0.08, 1.04 - steer_intensity * 0.09 - eat_intensity * 0.14 - boost_intensity * 0.05)
	draw_set_transform(head, heading, head_scale)
	draw_circle(Vector2(3.2, 5.0), head_radius + outline_width + 1.0, Color("01050d", 0.48))
	if player:
		var head_size := clampf(head_radius * 2.76, 50.0, 58.0)
		draw_texture_rect(
			SNAKES_GAG_PLAYER_HEAD_TEXTURE,
			Rect2(Vector2(-head_size, -head_size) * 0.5, Vector2(head_size, head_size)),
			false
		)
	else:
		draw_circle(Vector2.ZERO, head_radius + outline_width, outline)
		var head_color: Color = palette.get("head", bands[0])
		draw_circle(Vector2.ZERO, head_radius, head_color)
		draw_circle(Vector2(-head_radius * 0.28, -head_radius * 0.35), head_radius * 0.52, Color("ffffff", 0.13))
		var eye_radius := head_radius * 0.32
		var eye_gap := float(palette.get("eye_gap", 0.48))
		var blink_period := 3.15 + float(posmod(int(snake.get("id", 0)) * 7, 13)) * 0.10
		var blinking := not snakes_reduced_effects and fposmod(elapsed + float(int(snake.get("id", 0))) * 0.71, blink_period) < 0.105
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
	if player and steer_intensity > 0.0 and not snakes_reduced_effects:
		_draw_snakes_arena_steer_wake(head, heading, head_radius, steer_intensity)
	elif scavenging and not snakes_reduced_effects:
		_draw_snakes_arena_scavenge_intent(head, _arena_vector(snake.get("position", Vector2.ZERO)), scale_value, shake)
	var invulnerable := float(snake.get("invulnerable", 0.0))
	if player and invulnerable > 0.0:
		var shield_alpha := clampf(invulnerable / 1.15, 0.0, 1.0)
		draw_circle(head, head_radius + 11.0, Color("ffffff", 0.08 + shield_alpha * 0.08))
		draw_arc(head, head_radius + 11.0, 0, TAU, 44, Color("ffffff", 0.42 + shield_alpha * 0.22), 2.6)
		for star_index in range(3):
			var star_angle := (0.0 if snakes_reduced_effects else elapsed * 2.2) + float(star_index) * TAU / 3.0
			var star_position := head + Vector2.from_angle(star_angle) * (head_radius + 14.0)
			draw_line(star_position - Vector2(3, 0), star_position + Vector2(3, 0), Color("ffd92f", shield_alpha), 2.0, true)
			draw_line(star_position - Vector2(0, 3), star_position + Vector2(0, 3), Color("ffd92f", shield_alpha), 2.0, true)
	var label := "你" if player else ((str(snake.get("name", "BOT")) + " · 抢豆") if scavenging else str(snake.get("name", "BOT")))
	var label_color := Color("fff1ce") if player else Color("ffffff", 0.92)
	_draw_center(label, head + Vector2(0, -head_radius - 16.0), 13 if player else 12, label_color)

func _draw_snakes_arena_cartoon_boost(points: PackedVector2Array, body_radius: float, bands: Array, snake_id: int) -> void:
	if snakes_reduced_effects or points.size() < 3:
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
	if snakes_reduced_effects:
		return
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
		var alert_motion := 0.0 if snakes_reduced_effects else sin(elapsed * 12.0) * 3.0
		var alert := head + Vector2(22.0, -27.0 - alert_motion)
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
		var label_rise := 0.0 if snakes_reduced_effects else progress * 34.0
		var p := _arena_world_to_screen(_arena_vector(label.get("world", Vector2.ZERO)), scale_value, shake) + Vector2(0, -48.0 - label_rise)
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
	var pulse := 1.0 + (sin(elapsed * 13.0) * 0.035 if arena_boost_active and not snakes_reduced_effects else 0.0)
	draw_circle(center + Vector2(3, 6), 45.0 * pulse, Color("01050d", 0.58))
	draw_circle(center, 45.0 * pulse, Color("02101b"))
	draw_circle(center, 39.0 * pulse, Color("06ddea") if reserve > 0.04 else Color("ff3341"))
	draw_circle(center - Vector2(8, 11), 13.0, Color("ffffff", 0.18))
	for segment in range(8):
		var start_angle := -PI * 0.5 + float(segment) * TAU / 8.0 + 0.05
		var lit := float(segment + 1) / 8.0 <= reserve + 0.001
		draw_arc(center, 43.0, start_angle, start_angle + TAU / 8.0 - 0.10, 8, Color("ffd92f") if lit else Color("3a2941"), 5.5)
	if arena_boost_active:
		var active_radius := 31.0 if snakes_reduced_effects else 31.0 + sin(elapsed * 16.0) * 2.0
		draw_arc(center, active_radius, 0, TAU, 40, Color("ffffff", 0.72), 3.0)
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
	solitaire_model.reset(abs("solitaire_klondike".hash()) + 17, SOLITAIRE_RULES.DRAW_ONE, SOLITAIRE_RULES.UNLIMITED_RECYCLES)
	solitaire_recovered_from_snapshot = false
	if not solitaire_restart_requested:
		var saved := _load_solitaire_web_snapshot()
		if not saved.is_empty():
			solitaire_recovered_from_snapshot = solitaire_model.restore(saved)
			if not solitaire_recovered_from_snapshot:
				_clear_solitaire_web_snapshot()
	solitaire_selection.clear()
	solitaire_focus_zone = "top"
	solitaire_focus_index = 0
	solitaire_focus_card_index = -1
	_sync_solitaire_state()

func _sync_solitaire_state() -> void:
	state = solitaire_model.snapshot()
	state["game_id"] = game_id
	state["recovered"] = solitaire_recovered_from_snapshot
	state["selection"] = solitaire_selection.duplicate(true)
	state["selected_col"] = int(solitaire_selection.get("column", -1)) if str(solitaire_selection.get("kind", "")) == "tableau" else -1
	state["keyboard_zone"] = solitaire_focus_zone
	state["keyboard_index"] = solitaire_focus_index
	state["keyboard_card_index"] = solitaire_focus_card_index
	state["reduced_effects"] = solitaire_reduced_effects

func _restore_solitaire_snapshot(saved: Dictionary) -> bool:
	if not solitaire_model.restore(saved):
		return false
	solitaire_recovered_from_snapshot = true
	solitaire_selection.clear()
	solitaire_focus_zone = "top"
	solitaire_focus_index = 0
	solitaire_focus_card_index = -1
	_sync_solitaire_state()
	queue_redraw()
	return true

func _solitaire_draw() -> void:
	if game_id != "solitaire" or state.get("status") != "playing":
		return
	_solitaire_clear_selection(false)
	var result: Dictionary = solitaire_model.draw()
	_sync_solitaire_state()
	_solitaire_emit_result(result, Vector2(74, 306), Vector2(168, 306))

func _solitaire_auto() -> void:
	if game_id != "solitaire" or state.get("status") != "playing":
		return
	var source := _solitaire_auto_source_center()
	var result: Dictionary = solitaire_model.auto_foundation()
	_solitaire_clear_selection(false)
	_sync_solitaire_state()
	var suit := int(result.get("foundation_suit", 0))
	_solitaire_emit_result(result, source, _solitaire_foundation_rect(suit).get_center())

func _solitaire_tap(pos: Vector2) -> void:
	if game_id != "solitaire" or state.get("status") != "playing":
		return
	var stock_rect := Rect2(38, 256, 72, 100)
	var waste_rect := Rect2(132, 256, 72, 100)
	if stock_rect.has_point(pos):
		solitaire_focus_zone = "top"
		solitaire_focus_index = 0
		_solitaire_draw()
		return
	if waste_rect.has_point(pos):
		solitaire_focus_zone = "top"
		solitaire_focus_index = 1
		_solitaire_activate_waste()
		return
	for suit in range(4):
		if _solitaire_foundation_rect(suit).has_point(pos):
			solitaire_focus_zone = "top"
			solitaire_focus_index = suit + 2
			_solitaire_activate_foundation(suit)
			return
	var hit := _solitaire_tableau_hit(pos)
	if hit.is_empty():
		return
	var column := int(hit["column"])
	var card_index := int(hit["card_index"])
	solitaire_focus_zone = "tableau"
	solitaire_focus_index = column
	solitaire_focus_card_index = card_index
	_solitaire_activate_tableau(column, card_index)

func _solitaire_activate_waste() -> void:
	if solitaire_model.waste.is_empty():
		_solitaire_reject("waste_empty", Vector2(168, 306), -1)
		return
	if str(solitaire_selection.get("kind", "")) == "waste":
		_solitaire_clear_selection()
		return
	_solitaire_select({"kind":"waste", "card":int(solitaire_model.waste.back())}, Vector2(168, 306))

func _solitaire_activate_foundation(suit: int) -> void:
	if solitaire_selection.is_empty():
		var foundation: Array = solitaire_model.foundations[suit]
		if foundation.is_empty():
			_solitaire_reject("foundation_empty", _solitaire_foundation_rect(suit).get_center(), suit)
			return
		_solitaire_select({"kind":"foundation", "suit":suit, "card":int(foundation.back())}, _solitaire_foundation_rect(suit).get_center())
		return
	if str(solitaire_selection.get("kind", "")) == "foundation" and int(solitaire_selection.get("suit", -1)) == suit:
		_solitaire_clear_selection()
		return
	_solitaire_execute_to_foundation(suit)

func _solitaire_activate_tableau(column: int, card_index: int) -> void:
	var pile: Array = solitaire_model.tableau[column]
	if solitaire_selection.is_empty():
		if card_index < 0 or card_index >= pile.size():
			_solitaire_reject("tableau_empty", Vector2(63 + column * 68, 450), column)
			return
		if not bool(pile[card_index].get("face_up", false)):
			_solitaire_reject("face_down", _solitaire_card_rect(column, card_index).get_center(), column)
			return
		_solitaire_select({
			"kind":"tableau", "column":column, "card_index":card_index,
			"card":int(pile[card_index]["card"]),
		}, _solitaire_card_rect(column, card_index).get_center())
		return
	if str(solitaire_selection.get("kind", "")) == "tableau" and int(solitaire_selection.get("column", -1)) == column:
		if card_index == int(solitaire_selection.get("card_index", -2)):
			_solitaire_clear_selection()
		elif card_index >= 0 and card_index < pile.size() and bool(pile[card_index].get("face_up", false)):
			_solitaire_select({
				"kind":"tableau", "column":column, "card_index":card_index,
				"card":int(pile[card_index]["card"]),
			}, _solitaire_card_rect(column, card_index).get_center())
		return
	_solitaire_execute_to_tableau(column)

func _solitaire_execute_to_tableau(column: int) -> void:
	var kind := str(solitaire_selection.get("kind", ""))
	var from := _solitaire_selection_center()
	var result: Dictionary
	match kind:
		"tableau":
			result = solitaire_model.move_tableau_to_tableau(
				int(solitaire_selection.get("column", -1)),
				int(solitaire_selection.get("card_index", -1)),
				column
			)
		"waste": result = solitaire_model.move_waste_to_tableau(column)
		"foundation": result = solitaire_model.move_foundation_to_tableau(int(solitaire_selection.get("suit", -1)), column)
		_: return
	if bool(result.get("changed", false)):
		_solitaire_clear_selection(false)
	_sync_solitaire_state()
	var destination: Array = solitaire_model.tableau[column]
	var to := _solitaire_tableau_top_center(column, destination.size())
	_solitaire_emit_result(result, from, to, column)

func _solitaire_execute_to_foundation(suit: int) -> void:
	var kind := str(solitaire_selection.get("kind", ""))
	var from := _solitaire_selection_center()
	var result: Dictionary
	match kind:
		"tableau": result = solitaire_model.move_tableau_to_foundation(int(solitaire_selection.get("column", -1)), suit)
		"waste": result = solitaire_model.move_waste_to_foundation(suit)
		_:
			_solitaire_reject("wrong_destination", _solitaire_foundation_rect(suit).get_center(), suit)
			return
	if bool(result.get("changed", false)):
		_solitaire_clear_selection(false)
	_sync_solitaire_state()
	_solitaire_emit_result(result, from, _solitaire_foundation_rect(suit).get_center(), suit)

func _solitaire_select(selection: Dictionary, position: Vector2) -> void:
	solitaire_selection = selection.duplicate(true)
	_sync_solitaire_state()
	var card := int(selection.get("card", 0))
	_flash_feedback("已拿起 %s%s" % [_card_rank(solitaire_model.card_rank(card)), ["♠", "♥", "♣", "♦"][solitaire_model.card_suit(card)]], CYAN)
	_start_catalog_event("card_select", position, CYAN, 1, "", 0.44, {
		"column":int(selection.get("column", -1)),
		"card_index":int(selection.get("card_index", -1)),
		"rank":solitaire_model.card_rank(card), "suit":solitaire_model.card_suit(card),
	})

func _solitaire_clear_selection(sync_state := true) -> void:
	solitaire_selection.clear()
	if sync_state and game_id == "solitaire":
		_sync_solitaire_state()

func _solitaire_selection_center() -> Vector2:
	match str(solitaire_selection.get("kind", "")):
		"waste": return Vector2(168, 306)
		"foundation": return _solitaire_foundation_rect(int(solitaire_selection.get("suit", 0))).get_center()
		"tableau": return _solitaire_card_rect(int(solitaire_selection.get("column", 0)), int(solitaire_selection.get("card_index", 0))).get_center()
	return Vector2(270, 480)

func _solitaire_auto_source_center() -> Vector2:
	if not solitaire_model.waste.is_empty():
		var waste_card := int(solitaire_model.waste.back())
		var waste_suit := solitaire_model.card_suit(waste_card)
		if solitaire_model.card_rank(waste_card) == solitaire_model.foundations[waste_suit].size() + 1:
			return Vector2(168, 306)
	for column in range(7):
		var pile: Array = solitaire_model.tableau[column]
		if pile.is_empty():
			continue
		var card := int(pile.back()["card"])
		var suit := solitaire_model.card_suit(card)
		if solitaire_model.card_rank(card) == solitaire_model.foundations[suit].size() + 1:
			return _solitaire_card_rect(column, pile.size() - 1).get_center()
	return Vector2(270, 704)

func _solitaire_emit_result(result: Dictionary, from: Vector2, to: Vector2, object_index := -1) -> void:
	if not bool(result.get("changed", false)):
		_solitaire_reject(str(result.get("reason", "invalid_move")), to, object_index)
		return
	var kind := str(result.get("kind", ""))
	var event_kind := "card_move"
	var label := "牌列衔接"
	var color := CYAN
	var grade := 1
	var duration := 0.72
	var card := int(result.get("card", -1))
	if result.get("cards", []) is Array and not result.get("cards", []).is_empty():
		card = int(result.get("cards", []).back())
	match kind:
		"draw":
			event_kind = "card_draw"
			label = "翻开 %d 张" % result.get("cards", []).size()
			color = AMBER
		"recycle":
			event_kind = "card_recycle"
			label = "牌库重整"
			color = CYAN
			if not solitaire_model.stock.is_empty():
				card = int(solitaire_model.stock.back())
		"foundation", "auto_foundation":
			event_kind = "foundation_place"
			var total := int(result.get("foundation_total", solitaire_model.foundation_total()))
			grade = 3 if total in [13, 26, 39] else 2
			label = "整组归位" if grade == 3 else "归位 · +10"
			color = GOLD
			duration = 0.92 if grade == 3 else 0.82
		"win":
			event_kind = "solitaire_win"
			label = "四组归位 · 牌局完成"
			color = GOLD
			grade = 4
			duration = 1.42
		"foundation_to_tableau":
			label = "取回牌桌"
			color = AMBER
		_:
			label = "牌列衔接"
	var rank := solitaire_model.card_rank(card) if card >= 0 else 1
	var suit := solitaire_model.card_suit(card) if card >= 0 else 0
	_flash_feedback(label, color)
	_start_catalog_event(event_kind, to, color, grade, label, duration, {
		"from":from, "to":to, "rank":rank, "suit":suit,
		"card_size":Vector2(58, 80), "flip":kind == "draw", "back":kind == "recycle",
		"foundation_total":int(result.get("foundation_total", solitaire_model.foundation_total())),
		"label_position":Vector2(to.x, minf(764.0, to.y + 68.0)),
	})
	_log_event("solitaire_%s" % kind, result)
	if str(solitaire_model.status) == "won":
		_capture("solitaire_win")
	_persist_solitaire_progress()

func _solitaire_reject(reason: String, position: Vector2, object_index := -1) -> void:
	var labels := {
		"waste_empty":"废牌区还是空的", "tableau_empty":"这里没有牌", "foundation_empty":"归位区还是空的",
		"face_down":"这张牌还未翻开", "tableau_rule":"需按红黑交替、点数递减衔接",
		"wrong_suit":"花色不对应", "foundation_sequence":"归位区需从 A 同花顺排",
		"recycle_limit":"本局不可再回收", "stock_and_waste_empty":"没有可摸的牌",
		"no_legal_foundation_move":"当前没有可自动归位的牌", "same_column":"已在这一列",
		"wrong_destination":"不能放到这里", "game_finished":"牌局已经完成",
	}
	var label := str(labels.get(reason, "这一步不符合牌桌规则"))
	_flash_feedback(label, RED)
	_start_catalog_event("card_reject_%s" % reason, position, RED, 1, "", 0.56, {
		"column":object_index, "card_index":object_index, "reason":reason,
	})
	_log_event("solitaire_reject", {"reason":reason, "object":object_index})

func _solitaire_key_input(keycode: Key) -> bool:
	if keycode == KEY_M:
		_solitaire_draw()
		return true
	if keycode == KEY_F:
		_solitaire_auto()
		return true
	if keycode in [KEY_ENTER, KEY_SPACE]:
		_solitaire_keyboard_activate()
		return true
	var direction := Vector2i.ZERO
	if keycode in [KEY_LEFT, KEY_A]:
		direction = Vector2i.LEFT
	elif keycode in [KEY_RIGHT, KEY_D]:
		direction = Vector2i.RIGHT
	elif keycode in [KEY_UP, KEY_W]:
		direction = Vector2i.UP
	elif keycode in [KEY_DOWN, KEY_S]:
		direction = Vector2i.DOWN
	else:
		return false
	_solitaire_keyboard_move(direction)
	return true

func _solitaire_keyboard_move(direction: Vector2i) -> void:
	if solitaire_focus_zone == "top":
		if direction.x != 0:
			solitaire_focus_index = posmod(solitaire_focus_index + direction.x, 6)
		elif direction.y > 0:
			var top_to_tableau := [0, 1, 3, 4, 5, 6]
			solitaire_focus_zone = "tableau"
			solitaire_focus_index = int(top_to_tableau[solitaire_focus_index])
			solitaire_focus_card_index = _solitaire_focus_top_card(solitaire_focus_index)
	else:
		if direction.x != 0:
			solitaire_focus_index = posmod(solitaire_focus_index + direction.x, 7)
			solitaire_focus_card_index = _solitaire_focus_top_card(solitaire_focus_index)
		elif direction.y < 0:
			var first_face_up := _solitaire_first_face_up(solitaire_focus_index)
			if solitaire_focus_card_index > first_face_up:
				solitaire_focus_card_index -= 1
			else:
				var tableau_to_top := [0, 1, 1, 2, 3, 4, 5]
				solitaire_focus_zone = "top"
				solitaire_focus_index = int(tableau_to_top[solitaire_focus_index])
				solitaire_focus_card_index = -1
		elif direction.y > 0:
			var top_card := _solitaire_focus_top_card(solitaire_focus_index)
			if solitaire_focus_card_index < top_card:
				solitaire_focus_card_index += 1
	_sync_solitaire_state()
	queue_redraw()

func _solitaire_keyboard_activate() -> void:
	if solitaire_focus_zone == "top":
		match solitaire_focus_index:
			0: _solitaire_draw()
			1: _solitaire_activate_waste()
			_: _solitaire_activate_foundation(solitaire_focus_index - 2)
		return
	_solitaire_activate_tableau(solitaire_focus_index, solitaire_focus_card_index)

func _solitaire_focus_top_card(column: int) -> int:
	var pile: Array = solitaire_model.tableau[column]
	return pile.size() - 1

func _solitaire_first_face_up(column: int) -> int:
	var pile: Array = solitaire_model.tableau[column]
	for index in range(pile.size()):
		if bool(pile[index].get("face_up", false)):
			return index
	return -1

func _solitaire_tableau_hit(pos: Vector2) -> Dictionary:
	if pos.y < 400.0 or pos.y > 786.0:
		return {}
	var column := int(floor((pos.x - 31.0) / 68.0))
	if column < 0 or column >= 7:
		return {}
	var lane := Rect2(31 + column * 68, 400, 64, 386)
	if not lane.has_point(pos):
		return {}
	var pile: Array = solitaire_model.tableau[column]
	for index in range(pile.size() - 1, -1, -1):
		if _solitaire_card_rect(column, index).has_point(pos):
			return {"column":column, "card_index":index}
	return {"column":column, "card_index":-1}

func _solitaire_tableau_spacing(count: int) -> float:
	if count <= 1:
		return 38.0
	return clampf(262.0 / float(count - 1), 14.0, 38.0)

func _solitaire_card_rect(column: int, card_index: int) -> Rect2:
	var pile: Array = solitaire_model.tableau[column] if column >= 0 and column < solitaire_model.tableau.size() else []
	var count := maxi(1, pile.size())
	var spacing := _solitaire_tableau_spacing(count)
	return Rect2(34 + column * 68, 408 + maxi(0, card_index) * spacing, 58, 80)

func _solitaire_foundation_rect(suit: int) -> Rect2:
	return Rect2(296 + suit * 54, 256, 48, 66)

func _solitaire_tableau_top_center(column: int, count: int) -> Vector2:
	return _solitaire_card_rect(column, maxi(0, count - 1)).get_center()

func _solitaire_foundation_total() -> int:
	return solitaire_model.foundation_total()

func _draw_solitaire() -> void:
	_draw_section_heading("翡翠温室牌桌", "点牌拿起 · 点目标落牌", AMBER)
	_draw_panel(Rect2(24, 225, 492, 568), Color("062d24", 0.56), Color("d5b85d", 0.34), 15, 1)
	draw_line(Vector2(40, 392), Vector2(500, 392), Color("e1c875", 0.18), 1.0, true)
	_draw_text("牌库", Vector2(38, 246), 12, Color("f0dda5"))
	var stock_rect := Rect2(38, 256, 72, 100)
	var stock: Array = state.get("stock", [])
	var waste: Array = state.get("waste", [])
	if not stock.is_empty():
		_draw_card_back(stock_rect, Color("d3aa52"))
	else:
		_draw_panel(stock_rect, Color("f8edcc", 0.035), Color("f8edcc", 0.26), 7, 2)
		_draw_center_font(SYMBOL_FONT, "↻", stock_rect.get_center() + Vector2(0, 5), 22, Color("f2d47d", 0.52))
	_draw_status_badge(str(stock.size()), Vector2(42, 362), AMBER, not stock.is_empty(), 64)
	_draw_text("废牌", Vector2(132, 246), 12, Color("f0dda5"))
	if not waste.is_empty():
		var waste_card := int(waste.back())
		var waste_selected := str(solitaire_selection.get("kind", "")) == "waste"
		_draw_playing_card(Rect2(132, 256 - (7 if waste_selected else 0), 72, 100), solitaire_model.card_rank(waste_card), AMBER, solitaire_model.card_suit(waste_card), 0.54 if waste_selected else 0.18)
	else:
		_draw_panel(Rect2(132, 256, 72, 100), Color("f8edcc", 0.035), Color("f8edcc", 0.26), 7, 2)
		_draw_center_font(SYMBOL_FONT, "♦", Vector2(168, 311), 18, Color("f2d47d", 0.34))
	_draw_text("归位区", Vector2(292, 246), 12, Color("f0dda5"))
	var suits := ["♠", "♥", "♣", "♦"]
	var foundations: Array = state.get("foundations", [])
	for i in range(4):
		var rect := _solitaire_foundation_rect(i)
		var foundation: Array = foundations[i]
		var foundation_value := foundation.size()
		var foundation_color := GREEN if foundation_value > 0 else Color("f8edcc", 0.25)
		_draw_panel(Rect2(rect.position + Vector2(0, 3), rect.size), Color("020a08", 0.24), Color.TRANSPARENT, 7, 0)
		if foundation_value > 0:
			var foundation_card := int(foundation.back())
			var foundation_selected := str(solitaire_selection.get("kind", "")) == "foundation" and int(solitaire_selection.get("suit", -1)) == i
			_draw_playing_card(rect.grow(2 if foundation_selected else 0), solitaire_model.card_rank(foundation_card), GOLD, solitaire_model.card_suit(foundation_card), 0.46 if foundation_selected else 0.16)
		else:
			_draw_panel(rect, Color("0f4738", 0.74), foundation_color, 7, 2)
			_draw_center_font(SYMBOL_FONT, suits[i], rect.get_center() + Vector2(0, 3), 18, Color("ce3f57") if i % 2 == 1 else Color("e9eee4"))
		draw_arc(rect.get_center(), 28.0, -PI * 0.82, -PI * 0.82 + TAU * clampf(float(foundation_value) / 13.0, 0.0, 1.0), 20, Color("f2cf74", 0.72), 2.0, true)
	var origin := Vector2(34, 408)
	var tableau: Array = state.get("tableau", [])
	var selected_column := int(solitaire_selection.get("column", -1)) if str(solitaire_selection.get("kind", "")) == "tableau" else -1
	var selected_index := int(solitaire_selection.get("card_index", -1))
	for col in range(7):
		var pile: Array = tableau[col]
		var count := pile.size()
		var lane := Rect2(origin.x + col * 68 - 3, origin.y - 5, 64, 318)
		var target_hint := not solitaire_selection.is_empty() and selected_column != col
		_draw_panel(lane, Color("082b24", 0.20), Color("f0d578", 0.22 if target_hint else 0.10), 9, 1)
		if target_hint:
			draw_circle(Vector2(lane.get_center().x, lane.end.y - 13), 3.0, Color("f0d578", 0.62))
		var column_offset := _card_object_reject_offset(col)
		for row in range(max(1, count)):
			var selected_card := selected_column == col and row >= selected_index and selected_index >= 0
			var lift := -7.0 if selected_card else 0.0
			var rect := _solitaire_card_rect(col, row) if count > 0 else Rect2(origin.x + col * 68, origin.y, 58, 80)
			rect.position.y += lift
			rect.position += column_offset
			if count > 0:
				var card_entry: Dictionary = pile[row]
				if bool(card_entry.get("face_up", false)):
					var card := int(card_entry["card"])
					_draw_playing_card(rect, solitaire_model.card_rank(card), AMBER if selected_card else Color("8dbda3"), solitaire_model.card_suit(card), 0.52 if selected_card else 0.08)
				else:
					_draw_card_back(rect, Color("77a78f"))
			else:
				_draw_panel(rect, Color("f7e9c7", 0.025), Color("f7e9c7", 0.18), 7, 1)
		if selected_column == col and count > 0:
			var selected_center := _solitaire_card_rect(col, selected_index).get_center() + Vector2(0, -7)
			draw_arc(selected_center, 41.0, -PI * 0.92, PI * 0.18, 24, Color("f8d978", 0.78), 3.0, true)
	if solitaire_focus_zone == "top":
		var focus_rect := stock_rect if solitaire_focus_index == 0 else Rect2(132, 256, 72, 100) if solitaire_focus_index == 1 else _solitaire_foundation_rect(solitaire_focus_index - 2)
		draw_rect(focus_rect.grow(4), Color("fff1a6", 0.82), false, 2.0)
	elif solitaire_focus_index >= 0 and solitaire_focus_index < 7:
		var focus_card_rect := _solitaire_card_rect(solitaire_focus_index, solitaire_focus_card_index)
		draw_rect(focus_card_rect.grow(3), Color("fff1a6", 0.76), false, 2.0)
	_draw_center("同花 A→K 归位 · 空列仅接 K · M 摸牌 · F 自动", Vector2(270, 778), 12, Color("f1dfb6"))

func _init_tripeaks() -> void:
	tripeaks_model.reset(abs("tripeaks_v3".hash()) + 17, true)
	tripeaks_recovered_from_snapshot = false
	if not tripeaks_restart_requested:
		var saved := _load_tripeaks_snapshot()
		if not saved.is_empty():
			tripeaks_recovered_from_snapshot = tripeaks_model.restore(saved)
			if not tripeaks_recovered_from_snapshot:
				_clear_tripeaks_snapshot()
	tripeaks_focus_slot = _tripeaks_choose_focus(270.0)
	_sync_tripeaks_state()

func _sync_tripeaks_state() -> void:
	state = tripeaks_model.snapshot()
	state["game_id"] = game_id
	state["recovered"] = tripeaks_recovered_from_snapshot
	state["focus_slot"] = tripeaks_focus_slot
	state["reduced_effects"] = tripeaks_reduced_effects
	state["haptic_emissions"] = tripeaks_haptic_emissions
	state["peak_count"] = tripeaks_model.cleared_peak_count()
	state["exposed_slots"] = tripeaks_model.exposed_slots()
	state["legal_slots"] = tripeaks_model.legal_slots()

func _restore_tripeaks_snapshot(saved: Dictionary) -> bool:
	if not tripeaks_model.restore(saved):
		return false
	tripeaks_recovered_from_snapshot = true
	tripeaks_focus_slot = _tripeaks_choose_focus(270.0)
	_sync_tripeaks_state()
	queue_redraw()
	return true

func _tripeaks_next() -> void:
	if game_id != "tripeaks" or state.get("status") != "playing":
		return
	tripeaks_focus_slot = -2
	var result: Dictionary = tripeaks_model.draw_stock()
	_sync_tripeaks_state()
	_tripeaks_emit_result(result, _tripeaks_stock_rect().get_center())

func _tripeaks_tap(pos: Vector2) -> void:
	if game_id != "tripeaks" or state.get("status") != "playing":
		return
	if _tripeaks_stock_rect().grow(7.0).has_point(pos):
		_tripeaks_next()
		return
	for slot in range(TRIPEAKS_RULES.TABLEAU_COUNT - 1, -1, -1):
		if int(tripeaks_model.tableau[slot]) >= 0 and _tripeaks_card_rect(slot).grow(3.0).has_point(pos):
			tripeaks_focus_slot = slot
			_tripeaks_activate_slot(slot)
			return

func _tripeaks_activate_slot(slot: int) -> void:
	if game_id != "tripeaks" or state.get("status") != "playing":
		return
	var origin := _tripeaks_card_center(slot)
	var preferred_x := origin.x
	var result: Dictionary = tripeaks_model.clear_tableau(slot)
	if bool(result.get("changed", false)) and int(tripeaks_model.tableau[slot]) < 0:
		tripeaks_focus_slot = _tripeaks_choose_focus(preferred_x)
	_sync_tripeaks_state()
	_tripeaks_emit_result(result, origin, slot)

func _tripeaks_emit_result(result: Dictionary, origin: Vector2, object_index := -1) -> void:
	if not bool(result.get("changed", false)):
		_tripeaks_reject(str(result.get("reason", "invalid_move")), origin, object_index)
		return
	var kind := str(result.get("kind", ""))
	var action := str(result.get("action", kind))
	var card := int(result.get("card", tripeaks_model.waste_card()))
	var rank := tripeaks_model.card_rank(card)
	var suit := tripeaks_model.card_suit(card)
	var streak_value := int(result.get("streak", tripeaks_model.streak))
	var grade := clampi(1 + maxi(0, streak_value - 1) / 2, 1, 4)
	var event_kind := "card_draw"
	var label := "翻开牌库"
	var color := VIOLET
	var duration := 0.68
	var destination := _tripeaks_waste_rect().get_center()
	if action == "clear":
		event_kind = "card_clear" if streak_value <= 1 else "card_streak"
		label = "相邻收牌" if streak_value <= 1 else "连牌上升"
		color = GOLD if grade >= 3 else MINT
		duration = 0.70 + float(grade) * 0.09
		if bool(result.get("peak_cleared", false)):
			event_kind = "peak_milestone"
			grade = maxi(3, grade)
			label = "峰顶点亮 %d/3" % int(result.get("peak_count", 0))
			color = GOLD
			duration = 1.02
	if kind == "win":
		event_kind = "tripeaks_win"
		label = "三峰全清"
		color = GOLD
		grade = 4
		duration = 1.36
	elif kind == "loss":
		event_kind = "tripeaks_loss"
		label = "牌库耗尽 · 本局结束"
		color = RED
		grade = 3
		duration = 0.98
	var event_position := destination if action in ["clear", "draw"] else origin
	var peak_index := int(result.get("peak_index", -1))
	if event_kind == "peak_milestone" and peak_index >= 0:
		event_position = _tripeaks_card_center(peak_index)
	elif event_kind == "tripeaks_win":
		event_position = Vector2(270, 468)
	elif event_kind == "tripeaks_loss":
		event_position = Vector2(270, 548)
	if tripeaks_reduced_effects or kind in ["win", "loss"]:
		_flash_feedback(label, color)
	if not tripeaks_reduced_effects:
		var metadata := {
			"card_index":object_index, "streak":streak_value,
			"revealed":result.get("revealed", []),
			"peak_count":int(result.get("peak_count", tripeaks_model.cleared_peak_count())),
			"peak_index":peak_index, "final_peak":bool(result.get("final_peak", false)),
			"label_position":Vector2(270, 638),
			"semantic":event_kind,
		}
		if card >= 0 and action in ["clear", "draw"]:
			metadata.merge({
				"from":origin, "to":destination, "rank":rank, "suit":suit,
				"card_size":Vector2(54, 76) if action == "draw" else Vector2(44, 62),
				"flip":action == "draw", "back_first":action == "draw",
			}, true)
		_start_catalog_event(event_kind, event_position, color, grade, label, duration, metadata)
		if action == "clear":
			_tripeaks_emit_reveal_events(result.get("revealed", []), grade, duration)
	state["haptic_emissions"] = tripeaks_haptic_emissions
	_log_event("tripeaks_%s" % kind, result)
	if kind == "win":
		_capture("tripeaks_win")
	elif kind == "loss":
		_capture("tripeaks_loss")
	_persist_tripeaks_progress()

func _tripeaks_emit_reveal_events(revealed: Array, parent_grade: int, parent_duration: float) -> void:
	if tripeaks_reduced_effects or revealed.is_empty():
		return
	var reveal_grade := 3 if revealed.size() > 1 else clampi(maxi(2, parent_grade), 2, 3)
	for reveal_index in range(revealed.size()):
		var slot := int(revealed[reveal_index])
		if slot < 0 or slot >= TRIPEAKS_RULES.TABLEAU_COUNT:
			continue
		var card := int(tripeaks_model.tableau[slot])
		if card < 0:
			continue
		var center := _tripeaks_card_center(slot)
		_start_catalog_event("card_reveal", center, Color("d7b8ff"), reveal_grade, "", 0.76, {
			"from":center, "to":center, "rank":tripeaks_model.card_rank(card),
			"suit":tripeaks_model.card_suit(card), "card_index":slot,
			"card_size":Vector2(44, 62), "reveal":true, "silent":true,
			"started":elapsed + minf(parent_duration * 0.40, 0.34) + float(reveal_index) * 0.045,
			"semantic":"reveal_exposed_card", "reveal_group_size":revealed.size(),
		})

func _tripeaks_reject(reason: String, position: Vector2, object_index := -1) -> void:
	var labels := {
		"locked":"先清除压住它的两张牌", "rank_not_adjacent":"点数需与当前牌相邻",
		"already_removed":"这张牌已经收走", "slot_out_of_range":"没有这张牌",
		"stock_empty":"牌库已空，仍有可收牌", "game_finished":"牌局已经结束",
	}
	var label := str(labels.get(reason, "这一步不符合牌桌规则"))
	_flash_feedback(label, RED)
	if not tripeaks_reduced_effects:
		_start_catalog_event("card_reject_%s" % reason, position, RED, 1, "", 0.56, {
			"card_index":object_index, "reason":reason, "semantic":"reject_%s" % reason,
		})
	state["haptic_emissions"] = tripeaks_haptic_emissions
	_log_event("tripeaks_reject", {"reason":reason, "object":object_index})

func _tripeaks_key_input(keycode: Key) -> bool:
	if keycode == KEY_M:
		_tripeaks_next()
		return true
	if keycode in [KEY_ENTER, KEY_SPACE]:
		if tripeaks_focus_slot == -2:
			_tripeaks_next()
		else:
			_tripeaks_activate_slot(tripeaks_focus_slot)
		return true
	var direction := Vector2i.ZERO
	if keycode in [KEY_LEFT, KEY_A]:
		direction = Vector2i.LEFT
	elif keycode in [KEY_RIGHT, KEY_D]:
		direction = Vector2i.RIGHT
	elif keycode in [KEY_UP, KEY_W]:
		direction = Vector2i.UP
	elif keycode in [KEY_DOWN, KEY_S]:
		direction = Vector2i.DOWN
	else:
		return false
	_tripeaks_move_focus(direction)
	return true

func _tripeaks_move_focus(direction: Vector2i) -> void:
	if tripeaks_focus_slot == -2:
		if direction.y < 0 or direction.x != 0:
			tripeaks_focus_slot = _tripeaks_choose_focus(_tripeaks_stock_rect().get_center().x)
		_sync_tripeaks_state()
		queue_redraw()
		return
	var row := _tripeaks_slot_row(tripeaks_focus_slot)
	if direction.x != 0:
		var same_row := _tripeaks_active_row_slots(row)
		if not same_row.is_empty():
			var current_index := same_row.find(tripeaks_focus_slot)
			tripeaks_focus_slot = int(same_row[posmod(current_index + direction.x, same_row.size())])
	elif direction.y > 0 and row == 3:
		tripeaks_focus_slot = -2
	elif direction.y != 0:
		var target_row := row + direction.y
		while target_row >= 0 and target_row <= 3:
			var candidates := _tripeaks_active_row_slots(target_row)
			if not candidates.is_empty():
				var current_x := _tripeaks_card_center(tripeaks_focus_slot).x
				tripeaks_focus_slot = _tripeaks_nearest_slot(candidates, current_x)
				break
			target_row += direction.y
	_sync_tripeaks_state()
	queue_redraw()

func _tripeaks_choose_focus(preferred_x: float) -> int:
	var exposed := tripeaks_model.exposed_slots()
	if not exposed.is_empty():
		return _tripeaks_nearest_slot(exposed, preferred_x)
	var active: Array = []
	for slot in range(TRIPEAKS_RULES.TABLEAU_COUNT):
		if int(tripeaks_model.tableau[slot]) >= 0:
			active.append(slot)
	return _tripeaks_nearest_slot(active, preferred_x) if not active.is_empty() else -2

func _tripeaks_nearest_slot(candidates: Array, preferred_x: float) -> int:
	var best := int(candidates[0])
	var best_distance := absf(_tripeaks_card_center(best).x - preferred_x)
	for candidate in candidates:
		var distance := absf(_tripeaks_card_center(int(candidate)).x - preferred_x)
		if distance < best_distance:
			best = int(candidate)
			best_distance = distance
	return best

func _tripeaks_slot_row(slot: int) -> int:
	if slot < 3:
		return 0
	if slot < 9:
		return 1
	if slot < 18:
		return 2
	return 3

func _tripeaks_active_row_slots(row: int) -> Array:
	var starts := [0, 3, 9, 18]
	var ends := [3, 9, 18, 28]
	var result: Array = []
	for slot in range(int(starts[row]), int(ends[row])):
		if int(tripeaks_model.tableau[slot]) >= 0:
			result.append(slot)
	return result

func _draw_tripeaks() -> void:
	_draw_section_heading("月影三峰牌桌", "只收未被压住的相邻点数", VIOLET)
	var streak := int(state.get("streak", 0))
	_draw_panel(Rect2(22, 223, 496, 432), Color("160f31", 0.78), Color("c6a4f0", 0.28), 15, 1)
	# The moon is a quiet board landmark; playable information remains entirely
	# on the cards. A dark overlap creates a crescent without another asset role.
	draw_circle(Vector2(270, 292), 54, Color("ecdafa", 0.075))
	draw_circle(Vector2(289, 276), 52, Color("160f31", 0.84))
	for peak in range(3):
		var peak_center_x := 122.5 + float(peak) * 147.0
		var ridge_color := Color("a987d5", 0.13 + float(peak) * 0.018)
		draw_colored_polygon(PackedVector2Array([
			Vector2(peak_center_x - 94, 628), Vector2(peak_center_x, 238), Vector2(peak_center_x + 94, 628),
		]), ridge_color)
		draw_line(Vector2(peak_center_x - 94, 628), Vector2(peak_center_x, 238), Color("e8d1ff", 0.18), 2.0, true)
		draw_line(Vector2(peak_center_x, 238), Vector2(peak_center_x + 94, 628), Color("e8d1ff", 0.10), 2.0, true)
	var tableau: Array = state.get("tableau", [])
	for slot in range(mini(tableau.size(), TRIPEAKS_RULES.TABLEAU_COUNT)):
		var center := _tripeaks_card_center(slot)
		var card := int(tableau[slot])
		var locked := not tripeaks_model.is_exposed(slot)
		var rect := _tripeaks_card_rect(slot)
		if card < 0:
			_draw_panel(rect, Color("bfa8df", 0.025), Color("d9c2f2", 0.16), 7, 1)
			continue
		var reject_offset := _card_object_reject_offset(slot)
		rect.position += reject_offset
		center += reject_offset
		if locked:
			_draw_card_back(rect, VIOLET)
		else:
			var reveal_effect := _tripeaks_reveal_effect(slot)
			if not reveal_effect.is_empty() and _card_event_progress(reveal_effect) < 0.45:
				_draw_card_back(rect, VIOLET)
			else:
				_draw_playing_card(rect, tripeaks_model.card_rank(card), Color("d2adff"), tripeaks_model.card_suit(card), 0.18)
			draw_line(Vector2(rect.position.x + 7, rect.end.y + 3), Vector2(rect.end.x - 7, rect.end.y + 3), Color("f2d37a", 0.60), 1.8, true)
		if tripeaks_focus_slot == slot:
			draw_rect(rect.grow(3), Color("fff0a8", 0.82), false, 2.0)
	# A cleared top slot exposes its summit lamp in the exact card footprint.
	# The three persistent lamps make milestone state visible after the burst.
	for peak in range(3):
		if peak < tableau.size() and int(tableau[peak]) < 0:
			var lamp_center := _tripeaks_card_center(peak)
			draw_circle(lamp_center, 17.0, Color("f1c764", 0.10))
			draw_arc(lamp_center, 13.0, -PI * 0.86, PI * 0.12, 22, Color("f6d77c", 0.84), 2.4, true)
			draw_colored_polygon(PackedVector2Array([
				lamp_center + Vector2(-11, 9), lamp_center + Vector2(0, -9), lamp_center + Vector2(11, 9),
			]), Color("f0c55e", 0.72))
			draw_circle(lamp_center + Vector2(0, 4), 3.2, Color("fff4bd", 0.94))
	_draw_panel(Rect2(30, 668, 480, 134), Color("17102f", 0.97), Color("d4b7f4", 0.46), 13, 1)
	_draw_text("当前牌", Vector2(47, 686), 11, Color("efe3ff"))
	var waste_card := tripeaks_model.waste_card()
	_draw_playing_card(_tripeaks_waste_rect(), tripeaks_model.card_rank(waste_card), VIOLET, tripeaks_model.card_suit(waste_card), 0.34)
	_draw_text("牌库", Vector2(133, 686), 11, Color("efe3ff"))
	var stock: Array = state.get("stock", [])
	if not stock.is_empty():
		_draw_card_back(_tripeaks_stock_rect(), VIOLET)
	else:
		_draw_panel(_tripeaks_stock_rect(), Color("f7edff", 0.025), Color("f7edff", 0.18), 7, 1)
	_draw_panel(Rect2(188, 719, 56, 30), Color(VIOLET, 0.13), Color(VIOLET, 0.66), 8, 1)
	_draw_center_font(NUMBER_FONT, str(stock.size()), Vector2(216, 734), 13, VIOLET)
	_draw_text("点击亮面的相邻点数", Vector2(262, 712), 13, Color("f0e6fb"))
	_draw_text("首尾点数相接 · 按键翻牌", Vector2(262, 737), 12, Color("c9b8dd"))
	var streak_grade := clampi(1 + streak / 2, 1, 4) if streak > 0 else 0
	_draw_text("连牌", Vector2(398, 686), 11, Color("efe3ff"))
	for pip in range(4):
		var lit := pip < streak_grade
		var pip_center := Vector2(405 + pip * 23, 760)
		draw_colored_polygon(PackedVector2Array([
			pip_center + Vector2(-8, 5), pip_center + Vector2(0, -8), pip_center + Vector2(8, 5),
		]), Color("f2cb69", 0.86) if lit else Color("b899cf", 0.18))
	if streak > 0:
		_draw_center_font(NUMBER_FONT, "×%d" % streak, Vector2(445, 724), 14, GOLD)
	if tripeaks_focus_slot == -2:
		draw_rect(_tripeaks_stock_rect().grow(3), Color("fff0a8", 0.82), false, 2.0)

func _tripeaks_card_center(index: int) -> Vector2:
	index = clampi(index, 0, TRIPEAKS_RULES.TABLEAU_COUNT - 1)
	if index < 3:
		return Vector2(122.5 + float(index) * 147.0, 262.0)
	if index < 9:
		var pair := int((index - 3) / 2)
		var within := (index - 3) % 2
		return Vector2(98.0 + float(pair) * 147.0 + float(within) * 49.0, 332.0)
	if index < 18:
		return Vector2(73.5 + float(index - 9) * 49.0, 402.0)
	return Vector2(49.0 + float(index - 18) * 49.0, 472.0)

func _tripeaks_card_rect(index: int) -> Rect2:
	return Rect2(_tripeaks_card_center(index) - Vector2(22, 31), Vector2(44, 62))

func _tripeaks_waste_rect() -> Rect2:
	return Rect2(47, 694, 58, 82)

func _tripeaks_stock_rect() -> Rect2:
	return Rect2(130, 697, 54, 76)

# -----------------------------------------------------------------------------
# Mahjong matching / Tile Club
# -----------------------------------------------------------------------------

func _init_mahjong() -> void:
	mahjong_model.reset()
	mahjong_focus = mahjong_model.first_focus()
	mahjong_object_fx = {}
	_sync_mahjong_state(false)

func _sync_mahjong_state(persist := true) -> void:
	state = mahjong_model.snapshot()
	state["remaining"] = mahjong_model.remaining_count()
	state["focus"] = mahjong_focus
	state["reduced_effects"] = mahjong_reduced_effects
	if persist:
		_persist_mahjong_session()

func _mahjong_keyboard_input(keycode: Key) -> bool:
	match keycode:
		KEY_UP:
			mahjong_focus = mahjong_model.focus_neighbor(mahjong_focus, Vector2.UP)
		KEY_DOWN:
			mahjong_focus = mahjong_model.focus_neighbor(mahjong_focus, Vector2.DOWN)
		KEY_LEFT:
			mahjong_focus = mahjong_model.focus_neighbor(mahjong_focus, Vector2.LEFT)
		KEY_RIGHT:
			mahjong_focus = mahjong_model.focus_neighbor(mahjong_focus, Vector2.RIGHT)
		KEY_ENTER, KEY_SPACE:
			if mahjong_focus < 0:
				mahjong_focus = mahjong_model.first_focus()
			_mahjong_resolve_index(mahjong_focus, "keyboard")
		KEY_H:
			_mahjong_hint()
		KEY_S:
			_mahjong_shuffle()
		KEY_U, KEY_Z:
			_mahjong_undo()
		KEY_M:
			_toggle_mahjong_reduced()
		_:
			return false
	state["focus"] = mahjong_focus
	queue_redraw()
	return true

func _mahjong_tap(pos: Vector2) -> void:
	if game_id != "mahjong":
		return
	var index := _mahjong_hit_test(pos)
	if index < 0:
		return
	mahjong_focus = index
	_mahjong_resolve_index(index, "pointer")

func _mahjong_resolve_index(index: int, route: String) -> Dictionary:
	var result: Dictionary = mahjong_model.select_tile(index)
	_sync_mahjong_state(false)
	match str(result.get("kind", "")):
		"selected":
			mahjong_object_fx = {
				"kind":"select", "indices":[index], "value":int(mahjong_model.tiles[index]["face"]),
				"grade":1, "started":elapsed, "duration":0.48,
			}
			_flash_feedback("玉牌已选", CYAN)
			_start_catalog_event("jade_select", _mahjong_tile_center(index), CYAN, 1, "玉牌抬起", 0.48)
		"deselected":
			mahjong_object_fx = {
				"kind":"deselect", "indices":[index], "value":int(mahjong_model.tiles[index]["face"]),
				"grade":1, "started":elapsed, "duration":0.28,
			}
		"blocked":
			mahjong_object_fx = {
				"kind":"blocked", "indices":[index], "value":int(mahjong_model.tiles[index]["face"]),
				"grade":1, "started":elapsed, "duration":0.54,
			}
			_flash_feedback("此牌仍被压住", RED)
			_start_catalog_event("jade_blocked_reject", _mahjong_tile_center(index), RED, 1, "牌面受阻", 0.54, {"semantic":"mahjong_blocked"})
			_log_event("mahjong_blocked", {"index":index, "route":route, "covered":bool(result.get("covered", false))})
		"mismatch":
			var mismatch_indices: Array = result["indices"]
			mahjong_object_fx = {
				"kind":"mismatch", "indices":mismatch_indices.duplicate(), "value":int(mahjong_model.tiles[index]["face"]),
				"grade":1, "started":elapsed, "duration":0.62,
			}
			_flash_feedback("牌面不一致", RED)
			_start_catalog_event("jade_mismatch", _mahjong_tile_center(index), RED, 1, "纹样不同", 0.62)
			_log_event("mahjong_mismatch", {"indices":mismatch_indices, "route":route})
		"matched":
			var pair_indices: Array = result["indices"]
			var remaining := int(result["remaining"])
			var mahjong_grade := 4 if bool(result["final"]) else (3 if remaining <= 4 else 2)
			var pair_duration := 1.10 if mahjong_grade == 4 else (0.94 if mahjong_grade == 3 else 0.82)
			var pair_kind := "clear" if mahjong_grade == 4 else ("near" if mahjong_grade == 3 else "pair")
			var label := "牌阵清空 · 玉成" if mahjong_grade == 4 else ("牌阵将清 · +50" if mahjong_grade == 3 else "同纹共鸣 · +50")
			var color := GOLD if mahjong_grade == 4 else (Color("f0d27c") if mahjong_grade == 3 else MINT)
			_flash_feedback(label, color)
			mahjong_object_fx = {
				"kind":pair_kind, "indices":pair_indices.duplicate(),
				"value":int(result["face"]), "grade":mahjong_grade, "started":elapsed, "duration":pair_duration,
			}
			var pair_center := (_mahjong_tile_center(int(pair_indices[0])) + _mahjong_tile_center(int(pair_indices[1]))) * 0.5
			_start_catalog_event("jade_pair", pair_center, color, mahjong_grade, label, pair_duration, {"semantic":"mahjong_pair", "remaining":remaining})
			_log_event("mahjong_pair", {"face":result["face"], "remaining":remaining, "route":route})
			if bool(result["final"]):
				_capture("mahjong_win")
			elif bool(result["stuck"]):
				_start_catalog_event("jade_deadlock_reject", Vector2(270, 458), RED, 3, "暂无可配 · 请洗牌", 0.86, {"semantic":"mahjong_deadlock"})
		"terminal_reject", "inert":
			pass
	_persist_mahjong_session()
	queue_redraw()
	return result

func _mahjong_hint() -> void:
	if game_id != "mahjong":
		return
	var result: Dictionary = mahjong_model.request_hint()
	_sync_mahjong_state(false)
	if str(result.get("kind", "")) == "hint":
		var indices: Array = result["indices"]
		mahjong_focus = int(indices[0])
		state["focus"] = mahjong_focus
		mahjong_object_fx = {"kind":"hint", "indices":indices.duplicate(), "value":int(result["face"]), "grade":1, "started":elapsed, "duration":1.10}
		var center := (_mahjong_tile_center(int(indices[0])) + _mahjong_tile_center(int(indices[1]))) * 0.5
		_flash_feedback("这对玉牌可以相合", CYAN)
		_start_catalog_event("jade_hint", center, CYAN, 1, "可配一对", 0.72, {"semantic":"mahjong_hint"})
	else:
		_flash_feedback("暂无可配 · 请洗牌", RED)
		_start_catalog_event("jade_deadlock_reject", Vector2(270, 458), RED, 3, "暂无可配 · 请洗牌", 0.86, {"semantic":"mahjong_deadlock"})
	_persist_mahjong_session()

func _mahjong_shuffle() -> void:
	if game_id != "mahjong":
		return
	var result: Dictionary = mahjong_model.reshuffle_remaining()
	_sync_mahjong_state(false)
	if str(result.get("kind", "")) == "reshuffled":
		mahjong_focus = int(result["indices"][0])
		state["focus"] = mahjong_focus
		mahjong_object_fx = {"kind":"shuffle", "indices":mahjong_model.free_indices(), "value":int(result["face"]), "grade":3, "started":elapsed, "duration":0.78}
		_flash_feedback("玉牌已重排", GOLD)
		_start_catalog_event("jade_shuffle", Vector2(270, 456), GOLD, 3, "牌路重开", 0.88, {"semantic":"mahjong_shuffle"})
		_log_event("mahjong_shuffle", {"remaining":mahjong_model.remaining_count(), "count":mahjong_model.reshuffles})
	else:
		_flash_feedback("当前无需洗牌", BRIGHT_MUTED)
	_persist_mahjong_session()

func _mahjong_undo() -> void:
	if game_id != "mahjong":
		return
	var result: Dictionary = mahjong_model.undo_pair()
	_sync_mahjong_state(false)
	if str(result.get("kind", "")) == "undone":
		var indices: Array = result["indices"]
		mahjong_focus = int(indices[0]) if not indices.is_empty() else mahjong_model.first_focus()
		state["focus"] = mahjong_focus
		mahjong_object_fx = {"kind":"undo", "indices":indices.duplicate(), "grade":2, "started":elapsed, "duration":0.62}
		_flash_feedback("上一对已放回", CYAN)
		_start_catalog_event("jade_undo", Vector2(270, 456), CYAN, 2, "玉牌归位", 0.64, {"semantic":"mahjong_undo"})
	else:
		_flash_feedback("暂无可撤销配对", BRIGHT_MUTED)
	_persist_mahjong_session()

func _toggle_mahjong_reduced() -> void:
	if game_id != "mahjong":
		return
	mahjong_reduced_effects = not mahjong_reduced_effects
	_sync_mahjong_state(false)
	_build_game_buttons()
	_flash_feedback("低动态已开启" if mahjong_reduced_effects else "低动态已关闭", MINT)
	_persist_mahjong_session()

func _mahjong_draw_order() -> Array[int]:
	var result: Array[int] = []
	for index in range(mahjong_model.tile_count()):
		if mahjong_model.is_active(index):
			result.append(index)
	result.sort_custom(func(a: int, b: int) -> bool:
		var left: Dictionary = mahjong_model.tiles[a]
		var right: Dictionary = mahjong_model.tiles[b]
		if int(left["layer"]) != int(right["layer"]):
			return int(left["layer"]) < int(right["layer"])
		if int(left["gy"]) != int(right["gy"]):
			return int(left["gy"]) < int(right["gy"])
		if int(left["gx"]) != int(right["gx"]):
			return int(left["gx"]) < int(right["gx"])
		return a < b
	)
	return result

func _mahjong_hit_test(pos: Vector2) -> int:
	var order := _mahjong_draw_order()
	for offset in range(order.size() - 1, -1, -1):
		var index := int(order[offset])
		if _mahjong_tile_rect(index).has_point(pos):
			return index
	return -1

func _draw_mahjong() -> void:
	_draw_section_heading("静心牌阵", "自由牌配对 · 已收起 %d / 36" % int(state["removed"].size()), MINT)
	_draw_panel(Rect2(188, 222, 164, 38), Color("32190f", 0.84), Color("bd8a52", 0.76), 8, 2)
	for slot in range(4):
		draw_rect(Rect2(194 + slot * 38, 228, 31, 25), Color("120b08", 0.28), false, 1.0)
	var last_pair: Array = state.get("last_pair", [])
	if last_pair.size() == 2:
		for slot in range(2):
			var source_index := int(last_pair[slot])
			_draw_mahjong_tile(Rect2(198 + slot * 38, 224, 28, 34), int(mahjong_model.tiles[source_index]["face"]), false, 0.0, 1.0, false)
	var reduced := bool(state.get("reduced_effects", false))
	var fx_age := elapsed - float(mahjong_object_fx.get("started", -10.0))
	var fx_duration := float(mahjong_object_fx.get("duration", 0.0))
	var fx_indices: Array = mahjong_object_fx.get("indices", [])
	for index in _mahjong_draw_order():
		var rect := _mahjong_tile_rect(index)
		var selected := int(state.get("selected", -1)) == index
		var blocked := not mahjong_model.is_free(index)
		var hinted: bool = index in state.get("hint_pair", [])
		var mismatch_amount := 0.0
		var object_scale := 1.0
		var object_offset := Vector2.ZERO
		if fx_duration > 0.0 and fx_age >= 0.0 and fx_age < fx_duration and index in fx_indices:
			var fx_t := clampf(fx_age / fx_duration, 0.0, 1.0)
			match str(mahjong_object_fx.get("kind", "")):
				"select":
					if not reduced:
						object_scale = 1.0 + sin(minf(1.0, fx_t / 0.62) * PI) * 0.055
						object_offset.y -= sin(minf(1.0, fx_t / 0.52) * PI) * 5.0
				"deselect":
					if not reduced:
						object_offset.y += sin(fx_t * PI) * 3.0
				"blocked":
					mismatch_amount = sin(minf(1.0, fx_t / 0.42) * PI) * 0.62
				"mismatch":
					var envelope := pow(1.0 - fx_t, 1.8)
					if not reduced:
						var direction := -1.0 if index == int(fx_indices[0]) else 1.0
						object_offset.x += sin(fx_t * TAU * 4.5) * 6.0 * envelope * direction
					mismatch_amount = sin(minf(1.0, fx_t / 0.30) * PI) * envelope
				"shuffle":
					if not reduced:
						object_offset += Vector2(sin(fx_t * TAU + float(index)), cos(fx_t * TAU * 0.7 + float(index))) * 3.0 * sin(fx_t * PI)
				"undo":
					if not reduced:
						object_scale = 0.86 + 0.14 * (1.0 - pow(1.0 - fx_t, 3.0))
		if selected and not reduced:
			object_offset.y -= 8.0
		if object_scale != 1.0:
			var center := rect.get_center()
			rect.size *= object_scale
			rect.position = center - rect.size * 0.5
		rect.position += object_offset
		_draw_mahjong_tile(rect, int(mahjong_model.tiles[index]["face"]), selected, mismatch_amount, 0.50 if blocked else 1.0, blocked)
		if hinted:
			var hint_alpha := 0.54 + sin(elapsed * 5.4) * 0.20
			draw_arc(rect.get_center(), minf(rect.size.x, rect.size.y) * 0.54, 0, TAU, 28, Color("79e9ff", hint_alpha), 3.0, true)
		if mahjong_focus == index:
			draw_arc(rect.get_center(), minf(rect.size.x, rect.size.y) * 0.58, -PI * 0.78, PI * 0.78, 28, Color("f6d987", 0.84), 2.0, true)
	_draw_mahjong_pair_feedback()
	_draw_text("亮牌可选 · 暗牌仍被遮挡", Vector2(44, 724), 13, Color("d5e8df"))
	_draw_text("方向键移动 · 回车配对 · H 提示 · S 洗牌 · U 撤销", Vector2(44, 754), 11, Color("bbd3ca"))

func _mahjong_tile_rect(index: int) -> Rect2:
	if index < 0 or index >= mahjong_model.tile_count():
		return Rect2()
	var tile_data: Dictionary = mahjong_model.tiles[index]
	var layer := int(tile_data["layer"])
	var origin := Vector2(54, 268)
	var position := origin + Vector2(float(tile_data["gx"]) * 36.0, float(tile_data["gy"]) * 52.0) + Vector2(float(layer) * 4.0, -float(layer) * 6.0)
	return Rect2(position, Vector2(68, 82))

func _mahjong_tile_center(index: int) -> Vector2:
	return _mahjong_tile_rect(index).get_center()

func _draw_mahjong_tile(rect: Rect2, value: int, selected := false, mismatch_amount := 0.0, alpha := 1.0, blocked := false) -> void:
	# The authored SVG is the jade/contact backing. The visible ivory hero body
	# is the blank GAG component; all gameplay glyphs stay live and code-native.
	var body_tint := Color(0.68, 0.76, 0.72, alpha) if blocked else Color(1, 1, 1, alpha)
	draw_texture_rect(MAHJONG_TILE_BASE_TEXTURE, rect, false, body_tint)
	var source_size := MAHJONG_GAG_TILE_TEXTURE.get_size()
	var available_size := rect.size - Vector2(12.0, 4.0)
	var fit_scale := minf(available_size.x / source_size.x, available_size.y / source_size.y)
	var gag_size := source_size * fit_scale
	var gag_rect := Rect2(rect.get_center() - gag_size * 0.5 + Vector2(0, -1.0), gag_size)
	draw_texture_rect(MAHJONG_GAG_TILE_TEXTURE, gag_rect, false, body_tint)
	var face := Rect2(rect.position, rect.size - Vector2(0, rect.size.y * 0.08))
	var inset := face.grow(-maxf(5.0, rect.size.x * 0.07))
	if selected:
		_draw_panel(inset, Color("a8f0d8", 0.16 * alpha), Color.TRANSPARENT, 5, 0)
	_draw_mahjong_face(inset, value, alpha)
	if blocked:
		_draw_panel(inset, Color("173a32", 0.13), Color("254b42", 0.20), 5, 1)
	if selected:
		draw_arc(face.get_center(), minf(face.size.x, face.size.y) * 0.54, -PI * 0.82, PI * 0.16, 30, Color("9effe1", 0.78 * alpha), 3.0, true)
		draw_circle(face.position + Vector2(face.size.x - 12, 12), 4.0, Color("eafff8", 0.88 * alpha))
	if mismatch_amount > 0.01:
		draw_line(face.position + Vector2(12, 17), face.end - Vector2(12, 17), Color("e44f62", mismatch_amount * alpha), 3.0)
		draw_line(Vector2(face.end.x - 12, face.position.y + 17), Vector2(face.position.x + 12, face.end.y - 17), Color("ff9ba8", mismatch_amount * 0.72 * alpha), 2.0)

func _draw_mahjong_pair_feedback() -> void:
	var kind := str(mahjong_object_fx.get("kind", ""))
	if kind not in ["pair", "near", "clear"]:
		return
	var age := elapsed - float(mahjong_object_fx.get("started", -10.0))
	var duration := float(mahjong_object_fx.get("duration", 0.0))
	if duration <= 0.0 or age < 0.0 or age >= duration:
		return
	var indices: Array = mahjong_object_fx.get("indices", [])
	if indices.size() != 2:
		return
	var t := clampf(age / duration, 0.0, 1.0)
	var gather := 1.0 - pow(1.0 - clampf((t - 0.10) / 0.46, 0.0, 1.0), 3.0)
	var settle := clampf((t - 0.58) / 0.42, 0.0, 1.0)
	var source_a := _mahjong_tile_center(int(indices[0]))
	var source_b := _mahjong_tile_center(int(indices[1]))
	var midpoint := (source_a + source_b) * 0.5
	var value := int(mahjong_object_fx.get("value", 1))
	var alpha := 1.0 - settle
	if bool(state.get("reduced_effects", false)):
		# A fixed registration seal communicates the pair result without travel or
		# scale motion. The authoritative removed state is already committed.
		draw_arc(midpoint, 26.0, 0, TAU, 28, Color("8ff0ce", 0.62 * alpha), 2.5, true)
		draw_circle(midpoint, 4.0, Color("f6d987", 0.78 * alpha))
		return
	for ghost in range(2):
		var source := source_a if ghost == 0 else source_b
		var side := -1.0 if ghost == 0 else 1.0
		var target := midpoint + Vector2(side * (12.0 if kind == "pair" else 7.0), -10.0 - sin(gather * PI) * 11.0)
		var center := source.lerp(target, gather)
		var scale := 1.0 + sin(minf(1.0, t / 0.42) * PI) * (0.07 if kind == "pair" else 0.12) - settle * 0.32
		var ghost_size := Vector2(68, 82) * scale
		_draw_mahjong_tile(Rect2(center - ghost_size * 0.5, ghost_size), value, false, 0.0, alpha)
		draw_line(source, center, Color("8ff0ce", 0.22 * alpha), 2.0)
	if kind in ["near", "clear"]:
		var bloom := sin(minf(1.0, t / 0.66) * PI)
		var petal_count := 8 if kind == "clear" else 5
		for petal in range(petal_count):
			var angle := float(petal) / float(petal_count) * TAU + t * 0.35
			var p := midpoint + Vector2(cos(angle), sin(angle)) * (20.0 + gather * 46.0)
			draw_circle(p, 3.0 + bloom * 3.0, Color("f6d987", 0.74 * alpha))

func _draw_mahjong_face(rect: Rect2, value: int, alpha := 1.0) -> void:
	var center := rect.get_center()
	var scale := minf(rect.size.x / 58.0, rect.size.y / 70.0)
	match value:
		1, 2, 3, 4:
			var wind_color := Color("28594f", alpha)
			_draw_center_font(UI_FONT, ["", "东", "南", "西", "北"][value], center + Vector2(1, 5) * scale, maxi(8, int(25 * scale)), Color("756d59", 0.22 * alpha))
			_draw_center_font(UI_FONT, ["", "东", "南", "西", "北"][value], center + Vector2(0, 3) * scale, maxi(8, int(25 * scale)), wind_color)
		5:
			_draw_panel(Rect2(center - Vector2(18, 22) * scale, Vector2(36, 44) * scale), Color("d44b58", 0.06 * alpha), Color("c83f4f", 0.58 * alpha), maxi(2, int(5 * scale)), maxi(1, int(2 * scale)))
			_draw_center_font(UI_FONT, "中", center + Vector2(0, 5) * scale, maxi(8, int(27 * scale)), Color("c83f4f", alpha))
		6:
			_draw_center_font(UI_FONT, "发", center + Vector2(0, 5) * scale, maxi(8, int(27 * scale)), Color("3c8c64", alpha))
		7:
			_draw_panel(Rect2(center - Vector2(17, 22) * scale, Vector2(34, 44) * scale), Color("f8fbf3", 0.34 * alpha), Color("4385c6", 0.72 * alpha), maxi(2, int(3 * scale)), maxi(1, int(2 * scale)))
			_draw_center_font(UI_FONT, "白", center + Vector2(0, 4) * scale, maxi(7, int(19 * scale)), Color("4385c6", 0.76 * alpha))
		8, 9, 10, 11:
			var count := value - 7
			var positions := [Vector2.ZERO] if count == 1 else ([Vector2(-10, 0), Vector2(10, 0)] if count == 2 else ([Vector2(0, -12), Vector2(-10, 8), Vector2(10, 8)] if count == 3 else [Vector2(-10, -11), Vector2(10, -11), Vector2(-10, 11), Vector2(10, 11)]))
			for i in range(count):
				var pip_center: Vector2 = center + Vector2(positions[i]) * scale
				var pip_color: Color = [Color("4385c6"), Color("c84b58"), Color("47a06e")][i % 3]
				draw_circle(pip_center, maxf(2.0, 6.4 * scale), Color(pip_color.darkened(0.18), alpha))
				draw_circle(pip_center, maxf(1.5, 4.9 * scale), Color(pip_color, alpha))
		12, 13, 14, 15:
			var count := value - 11
			for i in range(count):
				var x := (float(i) - float(count - 1) * 0.5) * 12.0 * scale
				draw_line(center + Vector2(x, -17 * scale), center + Vector2(x, 17 * scale), Color("3d8d65", alpha), maxf(2.0, 4.0 * scale), true)
				draw_circle(center + Vector2(x, -18 * scale), maxf(1.5, 2.8 * scale), Color("c64c58", alpha))
		16, 17, 18:
			var count := value - 15
			_draw_center_font(UI_FONT, ["", "一", "二", "三"][count], center + Vector2(0, -5) * scale, maxi(7, int(17 * scale)), Color("245783", alpha))
			_draw_center_font(UI_FONT, "万", center + Vector2(0, 13) * scale, maxi(7, int(18 * scale)), Color("b94750", alpha))

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
	tileclub_object_fx = {}

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
	var tile_center := _tileclub_tile_center(index)
	_impact(tile_center, _tile_color(value), 0.45)
	var arrival := Vector2(66 + (tray.size() - 1) * 67, 759)
	_start_motion("tile", tile_center, arrival, _tile_color(value), _tile_symbol(value), 0.44, value)
	var removed_count := 0
	var matched_value := 0
	var matched_positions: Array = []
	for n in range(1, 8):
		var count := 0
		for v in tray:
			if int(v) == n:
				count += 1
		if count >= 3:
			removed_count = 0
			for i in range(tray.size() - 1, -1, -1):
				if int(tray[i]) == n and removed_count < 3:
					matched_positions.append(Vector2(66 + i * 67, 759))
					tray.remove_at(i)
					removed_count += 1
			matched_value = n
			state["score"] = int(state["score"]) + 100
			_log_event("tileclub_match", {"tile":n, "score":state["score"]})
		if removed_count > 0:
			break
	var cleared_after_action := _tileclub_cleared()
	var tray_count := tray.size()
	if removed_count > 0:
		var match_grade := 4 if cleared_after_action else 3
		var match_duration := 1.12 if match_grade == 4 else 0.96
		tileclub_object_fx = {
			"kind":"clear" if match_grade == 4 else "match", "value":matched_value,
			"positions":matched_positions, "grade":match_grade, "started":elapsed,
			"duration":match_duration,
		}
		_flash_feedback("织毯完成 · 清盘" if match_grade == 4 else "三枚消除 · +100", GOLD)
		_impact(Vector2(270, 755), GOLD, 1.15 if match_grade == 4 else 0.92)
		_start_catalog_event("stitch_match", Vector2(270, 755), GOLD, match_grade, "织毯完成 · 清盘" if match_grade == 4 else "三枚缝合 · +100", match_duration)
	elif tray_count >= 7:
		tileclub_object_fx = {
			"kind":"full", "value":value, "positions":[], "grade":4,
			"started":elapsed, "duration":1.02,
		}
		_flash_feedback("槽位绷满 · 本局结束", RED)
		_start_catalog_event("stitch_tray_full", Vector2(270, 759), RED, 4, "槽位绷满 · 本局结束", 1.02)
	elif cleared_after_action:
		tileclub_object_fx = {
			"kind":"clear", "value":value, "positions":[arrival], "grade":4,
			"started":elapsed, "duration":1.08,
		}
		_flash_feedback("织毯完成 · 清盘", GOLD)
		_start_catalog_event("stitch_clear", Vector2(270, 755), GOLD, 4, "织毯完成 · 清盘", 1.08)
	elif tray_count >= 5:
		var risk_grade := 3 if tray_count == 6 else 2
		var risk_label := "只余一格 · 谨慎落片" if risk_grade == 3 else "槽位吃紧 · 余 2 格"
		tileclub_object_fx = {
			"kind":"risk", "value":value, "positions":[arrival], "grade":risk_grade,
			"started":elapsed, "duration":0.78 if risk_grade == 3 else 0.66,
		}
		_flash_feedback(risk_label, RED if risk_grade == 3 else AMBER)
		_start_catalog_event("stitch_risk", arrival, RED if risk_grade == 3 else AMBER, risk_grade, risk_label, 0.78 if risk_grade == 3 else 0.66)
	else:
		tileclub_object_fx = {
			"kind":"collect", "value":value, "positions":[arrival], "grade":1,
			"started":elapsed, "duration":0.54,
		}
		_start_catalog_event("stitch_collect", tile_center, _tile_color(value), 1, "%s片入槽" % _tile_symbol(value), 0.54)
	if tray_count >= 7:
		state["status"] = "over"
		_capture("tileclub_tray_full")
	elif cleared_after_action:
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

func _tileclub_tile_center(index: int) -> Vector2:
	return Vector2(64 + (index % 7) * 64, 264 + (index / 7) * 64)

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
			draw_circle(rect.get_center(), 2.5, Color("ffe5d6", 0.14))
			draw_line(rect.get_center() - Vector2(4, 4), rect.get_center() + Vector2(4, 4), Color("ffe5d6", 0.07), 1.0)
			if index == 48 and state["tray"].is_empty() and int(state["moves"]) == 0:
				draw_arc(rect.get_center(), 18, 0, TAU, 24, Color(INK, 0.10), 1.0)
		else:
			_draw_fabric_patch(rect, value)
	var tray_count := int(state["tray"].size())
	var risk_color := RED if tray_count >= 6 else (AMBER if tray_count >= 5 else MINT)
	var object_age := elapsed - float(tileclub_object_fx.get("started", -10.0))
	var object_duration := float(tileclub_object_fx.get("duration", 0.0))
	var object_kind := str(tileclub_object_fx.get("kind", ""))
	var risk_pulse := 0.0
	if object_kind in ["risk", "full"] and object_age >= 0.0 and object_age < object_duration:
		var object_t := clampf(object_age / object_duration, 0.0, 1.0)
		risk_pulse = sin(object_t * PI * (3.0 if object_kind == "full" else 2.0)) * 0.5 + 0.5
	_draw_status_badge("槽位 %d / 7" % tray_count, Vector2(36, 692), risk_color, tray_count < 5, 124)
	_draw_panel(Rect2(30, 726, 480, 66).grow(risk_pulse * 2.0), Color("211a30", 0.97), Color(risk_color, 0.46 + risk_pulse * 0.42), 14, 2 + int(risk_pulse * 2.0))
	var tile_motion_progress := clampf((elapsed - motion_started) / maxf(0.001, motion_duration), 0.0, 1.0) if motion_kind == "tile" else 1.0
	var motion_target_index := int(round((motion_to.x - 66.0) / 67.0))
	for i in range(7):
		var slot := Rect2(39 + i * 67, 736, 54, 46)
		var occupied := i < tray_count
		var slot_kick := sin(object_age * 68.0 + i * 0.8) * risk_pulse * (2.2 if object_kind == "full" else 0.7)
		slot.position.x += slot_kick
		_draw_panel(slot, Color("100f20"), Color(risk_color, 0.72 + risk_pulse * 0.18) if occupied else Color(INK, 0.14), 8, 2)
		if i < tray_count:
			var tray_value := int(state["tray"][i])
			var awaiting_arrival := tile_motion_progress < 1.0 and i == motion_target_index and tray_value == motion_value
			if not awaiting_arrival:
				_draw_fabric_patch(slot.grow(-4.0), tray_value, 1.0, true, risk_pulse * 0.45)
	if object_kind == "full" and risk_pulse > 0.02:
		var snap_color := Color("ff95ae", 0.70 * risk_pulse)
		draw_line(Vector2(37, 718), Vector2(251, 727), snap_color, 2.4)
		draw_line(Vector2(289, 727), Vector2(503, 718), snap_color, 2.4)
		draw_line(Vector2(251, 727), Vector2(260, 715), snap_color, 2.4)
		draw_line(Vector2(280, 738), Vector2(289, 727), snap_color, 2.4)
	_draw_tileclub_object_feedback()

func _draw_fabric_patch(rect: Rect2, value: int, alpha := 1.0, compact := false, emphasis := 0.0) -> void:
	# The visible cloth, piping, stitching, shadow and appliqué are selected GAG
	# derivatives. The shell uses its dedicated repair after the atlas cell failed
	# the motif-readability review.
	var safe_value := clampi(value, 1, 7)
	var visual_rect := rect
	if compact:
		var side := minf(rect.size.x, rect.size.y)
		visual_rect = Rect2(rect.get_center() - Vector2(side, side) * 0.5, Vector2(side, side))
	draw_rect(Rect2(visual_rect.position + Vector2(1.5, 2.5), visual_rect.size), Color("1c1119", 0.22 * alpha), true)
	if safe_value == 6:
		draw_texture_rect(TILECLUB_GAG_SHELL_TEXTURE, visual_rect, false, Color(1, 1, 1, alpha))
	else:
		draw_texture_rect_region(TILECLUB_GAG_BADGE_ATLAS_TEXTURE, visual_rect, _tileclub_gag_badge_region(safe_value), Color(1, 1, 1, alpha))
	if emphasis > 0.01:
		var highlight_radius := minf(visual_rect.size.x, visual_rect.size.y) * 0.52
		draw_arc(visual_rect.get_center(), highlight_radius, -PI * 0.75, PI * 0.20, 24, Color("fff4cc", emphasis * alpha), 2.4)

func _tileclub_gag_badge_region(value: int) -> Rect2:
	match clampi(value, 1, 7):
		1:
			return Rect2(50, 52, 126, 126)
		2:
			return Rect2(188, 52, 127, 126)
		3:
			return Rect2(50, 190, 126, 128)
		4:
			return Rect2(188, 190, 127, 128)
		5:
			return Rect2(50, 328, 126, 126)
		7:
			return Rect2(326, 328, 127, 127)
		_:
			return Rect2(326, 190, 127, 128)

func _draw_tileclub_object_feedback() -> void:
	var kind := str(tileclub_object_fx.get("kind", ""))
	if kind not in ["match", "clear"]:
		return
	var age := elapsed - float(tileclub_object_fx.get("started", -10.0))
	var duration := float(tileclub_object_fx.get("duration", 0.0))
	if duration <= 0.0 or age < 0.0 or age >= duration:
		return
	var t := clampf(age / duration, 0.0, 1.0)
	var gather := 1.0 - pow(1.0 - clampf((t - 0.08) / 0.43, 0.0, 1.0), 3.0)
	var settle := clampf((t - 0.58) / 0.42, 0.0, 1.0)
	var positions: Array = tileclub_object_fx.get("positions", [])
	var value := int(tileclub_object_fx.get("value", 1))
	var target := Vector2(270, 755)
	var alpha := 1.0 - settle
	for index in range(positions.size()):
		var source: Vector2 = positions[index]
		var spread := (float(index) - float(positions.size() - 1) * 0.5) * 16.0
		var destination := target + Vector2(spread * (1.0 - gather), -12.0 * sin(gather * PI))
		var center := source.lerp(destination, gather)
		var scale := 1.0 + sin(minf(1.0, t / 0.42) * PI) * 0.16 - settle * 0.42
		var patch_size := Vector2(46, 46) * scale
		_draw_fabric_patch(Rect2(center - patch_size * 0.5, patch_size), value, alpha, true, 0.72)
		draw_line(source, center, Color(_tile_color(value), 0.30 * alpha), 2.0)
	var seal_alpha := sin(clampf((t - 0.24) / 0.76, 0.0, 1.0) * PI)
	if seal_alpha > 0.01:
		var stitch_count := 18 if kind == "clear" else 12
		for stitch in range(stitch_count):
			var angle := float(stitch) / float(stitch_count) * TAU + t * 0.32
			var radius := 28.0 + gather * (25.0 if kind == "clear" else 12.0)
			var p := target + Vector2(cos(angle), sin(angle)) * radius
			var tangent := Vector2(-sin(angle), cos(angle))
			draw_line(p - tangent * 4.0, p + tangent * 4.0, Color("ffe5a8", seal_alpha * 0.80), 2.2)

func _tile_color(value: int) -> Color:
	var colors := [Color("6fcb58"), Color("f6c667"), Color("e95656"), Color("f6b72e"), Color("f17a83"), Color("65b8eb"), Color("5de4ff")]
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
	amaze_go_object_fx = {}
	amaze_go_route.clear()
	amaze_go_facing = Vector2i.RIGHT
	arrow_go_object_fx = {}
	arrow_go_route.clear()
	arrow_go_facing = Vector2i.RIGHT
	if game_id == "amaze_go":
		# Presentation-only route memory. Rules continue to read state.painted;
		# this ordered copy exists solely to render a legible surveyed trail.
		amaze_go_route.append(Vector2i.ZERO)
	elif game_id == "arrow_go":
		# Ordered presentation evidence mirrors successful moves but is never read
		# by the frozen path rules. Generated art cannot mutate this trail.
		arrow_go_route.append(Vector2i.ZERO)

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
		var expected_direction := Vector2i(int(arrow[0]), int(arrow[1]))
		if direction != expected_direction:
			arrow_go_object_fx = {
				"kind": "crosswind_reject",
				"started": elapsed,
				"duration": 0.48,
				"grade": 2,
				"from": _path_cell_center(int(player[0]), int(player[1]), size_grid),
				"expected": expected_direction,
				"attempted": direction,
			}
			_flash_feedback("箭流只允许%s" % _direction_name(arrow), RED)
			_impact(_path_cell_center(int(player[0]), int(player[1]), size_grid), RED, 0.48)
			_start_catalog_event("path_reject_arrow", _path_cell_center(int(player[0]), int(player[1]), size_grid), RED, 2, "逆着箭流", 0.62, {"expected":[expected_direction.x, expected_direction.y], "attempted":[direction.x, direction.y], "label_position":Vector2(270, 711)})
			return
	if game_id == "amaze_go" and _maze_blocks(int(player[0]), int(player[1]), direction):
		var wall_center := _path_cell_center(int(player[0]), int(player[1]), size_grid) + Vector2(direction) * (430.0 / float(size_grid)) * 0.5
		var wall_tangent := Vector2(-direction.y, direction.x)
		amaze_go_object_fx = {
			"kind": "wall_reject",
			"started": elapsed,
			"duration": 0.44,
			"grade": 2,
			"from": _path_cell_center(int(player[0]), int(player[1]), size_grid),
			"direction": direction,
			"contact": wall_center,
			"segment_a": wall_center - wall_tangent * (430.0 / float(size_grid)) * 0.48,
			"segment_b": wall_center + wall_tangent * (430.0 / float(size_grid)) * 0.48,
		}
		_flash_feedback("这里有墙", RED)
		_impact(_path_cell_center(int(player[0]), int(player[1]), size_grid), RED, 0.48)
		_start_catalog_event("path_reject_wall", _path_cell_center(int(player[0]), int(player[1]), size_grid), RED, 2, "蓝图有墙", 0.62)
		return
	var next := Vector2i(int(player[0]) + direction.x, int(player[1]) + direction.y)
	if next.x < 0 or next.y < 0 or next.x >= size_grid or next.y >= size_grid:
		if game_id == "amaze_go":
			var edge_center := _path_cell_center(int(player[0]), int(player[1]), size_grid) + Vector2(direction) * (430.0 / float(size_grid)) * 0.5
			var edge_tangent := Vector2(-direction.y, direction.x)
			amaze_go_object_fx = {
				"kind": "edge_reject",
				"started": elapsed,
				"duration": 0.34,
				"grade": 1,
				"from": _path_cell_center(int(player[0]), int(player[1]), size_grid),
				"direction": direction,
				"contact": edge_center,
				"segment_a": edge_center - edge_tangent * (430.0 / float(size_grid)) * 0.48,
				"segment_b": edge_center + edge_tangent * (430.0 / float(size_grid)) * 0.48,
			}
		elif game_id == "arrow_go":
			arrow_go_object_fx = {
				"kind": "edge_reject",
				"started": elapsed,
				"duration": 0.38,
				"grade": 1,
				"from": _path_cell_center(int(player[0]), int(player[1]), size_grid),
				"expected": direction,
				"attempted": direction,
			}
		_start_catalog_event("path_reject_edge", _path_cell_center(int(player[0]), int(player[1]), size_grid), RED, 1, "已到边界", 0.54, {"direction":[direction.x, direction.y], "label_position":Vector2(270, 711)} if game_id == "arrow_go" else {})
		return
	var from_position := _path_cell_center(int(player[0]), int(player[1]), size_grid)
	player[0] = next.x
	player[1] = next.y
	state["painted"][next.y][next.x] = true
	state["moves"] = int(state["moves"]) + 1
	state["score"] = int(state["score"]) + 5
	state["streak"] = int(state.get("streak", 0)) + 1
	if game_id == "amaze_go":
		amaze_go_route.append(next)
		amaze_go_facing = direction
	elif game_id == "arrow_go":
		arrow_go_route.append(next)
		arrow_go_facing = direction
	var to_position := _path_cell_center(next.x, next.y, size_grid)
	_impact(to_position, _catalog_item(game_id).accent, 0.30)
	_start_motion("path", from_position, to_position, _catalog_item(game_id).accent, "", 0.24)
	var path_streak := int(state["streak"])
	var path_grade := 2 if path_streak % 5 == 0 else 1
	var path_label := "轨迹 ×%d" % path_streak if path_grade > 1 else ("颜料铺开" if game_id == "amaze" else ("箭流推进" if game_id == "arrow_go" else "蓝图点亮"))
	if game_id == "amaze_go":
		amaze_go_object_fx = {
			"kind": "waypoint" if path_grade > 1 else "step",
			"started": elapsed,
			"duration": 0.70 if path_grade > 1 else 0.46,
			"grade": path_grade,
			"from": from_position,
			"to": to_position,
			"direction": direction,
			"route_index": amaze_go_route.size() - 1,
		}
	elif game_id == "arrow_go":
		arrow_go_object_fx = {
			"kind": "waypoint" if path_grade > 1 else "step",
			"started": elapsed,
			"duration": 0.74 if path_grade > 1 else 0.46,
			"grade": path_grade,
			"from": from_position,
			"to": to_position,
			"direction": direction,
			"route_index": arrow_go_route.size() - 1,
		}
	_start_catalog_event("path_step", to_position, _catalog_item(game_id).accent, path_grade, path_label, 0.52 if path_grade == 1 else 0.70, {"direction":[direction.x, direction.y], "label_position":Vector2(270, 711)} if game_id == "arrow_go" else {})
	_log_event("path_step", {"x":next.x, "y":next.y})
	var target: Array = state["target"]
	var reached_goal := next.x == int(target[0]) and next.y == int(target[1])
	if game_id == "amaze":
		reached_goal = _painted_count() == size_grid * size_grid
	if reached_goal:
		if game_id == "amaze_go":
			amaze_go_object_fx = {
				"kind": "complete",
				"started": elapsed,
				"duration": 1.12,
				"grade": 4,
				"from": from_position,
				"to": to_position,
				"direction": direction,
				"route_index": amaze_go_route.size() - 1,
			}
		elif game_id == "arrow_go":
			arrow_go_object_fx = {
				"kind": "complete",
				"started": elapsed,
				"duration": 1.18,
				"grade": 4,
				"from": from_position,
				"to": to_position,
				"direction": direction,
				"route_index": arrow_go_route.size() - 1,
			}
		_start_catalog_event("path_complete", to_position, GOLD, 4, "全域完成", 1.18 if game_id == "arrow_go" else 1.12, {"direction":[direction.x, direction.y], "label_position":Vector2(270, 711)} if game_id == "arrow_go" else {})
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
	if game_id == "amaze_go":
		_draw_amaze_go()
		return
	if game_id == "arrow_go":
		_draw_arrow_go()
		return
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

func _draw_arrow_go() -> void:
	var grid_size := int(state["size"])
	var cell := 430.0 / float(grid_size)
	var origin := Vector2(54, 236)
	var board_rect := Rect2(origin, Vector2(430, 430))
	var painted: Array = state["painted"]
	var aubergine := Color("211738")
	var brass := Color("d5aa5d")
	var ivory := Color("fff0cf")
	var coral := Color("e87463")

	_draw_section_heading("午夜风筝邮局", "相邻格点击或方向键移动", Color("d9b7ff"))
	_draw_panel(Rect2(origin - Vector2(15, 13), Vector2(460, 460)), Color("090613", 0.46), Color.TRANSPARENT, 18, 0)
	_draw_panel(Rect2(origin - Vector2(11, 11), Vector2(452, 452)), aubergine, Color(brass, 0.82), 14, 3)
	draw_rect(board_rect, Color("16102a"))
	for seam in range(10):
		var seam_y := board_rect.position.y + 10.0 + float(seam) * 44.0
		draw_line(Vector2(board_rect.position.x, seam_y), Vector2(board_rect.end.x, seam_y + 8.0), Color("e7c5ef", 0.025), 1.0)

	# The GAG wind socket is stable and frequent: all 81 opening cells use the
	# authored material. Directional fins remain live so art can never disagree
	# with the frozen arrow matrix.
	for y in range(grid_size):
		for x in range(grid_size):
			var center := _path_cell_center(x, y, grid_size)
			draw_circle(center + Vector2(1.5, 2.4), cell * 0.43, Color("05030b", 0.32))
			_draw_arrow_go_texture(ARROW_GO_GAG_WIND_PLATE_TEXTURE, center, cell * 0.955, Color.WHITE)
			if bool(painted[y][x]):
				draw_circle(center, cell * 0.265, Color(coral, 0.17))
				draw_arc(center, cell * 0.32, 0, TAU, 22, Color("ffd39b", 0.28), 1.2, true)

	# Presentation-only ordered route. Authoritative movement still reads the
	# arrow matrix and painted grid above.
	for route_index in range(1, arrow_go_route.size()):
		var previous: Vector2i = arrow_go_route[route_index - 1]
		var current: Vector2i = arrow_go_route[route_index]
		var from_position := _path_cell_center(previous.x, previous.y, grid_size)
		var to_position := _path_cell_center(current.x, current.y, grid_size)
		draw_line(from_position + Vector2(1.4, 2.2), to_position + Vector2(1.4, 2.2), Color("05030c", 0.56), 9.0, true)
		draw_line(from_position, to_position, Color(coral, 0.88), 5.2, true)
		draw_line(from_position, to_position, Color("ffd1b0", 0.52), 1.2, true)
	for route_index in range(arrow_go_route.size()):
		var route_node: Vector2i = arrow_go_route[route_index]
		var route_position := _path_cell_center(route_node.x, route_node.y, grid_size)
		var waypoint := route_index > 0 and route_index % 5 == 0
		draw_circle(route_position, 4.7 if waypoint else 3.5, Color("341527", 0.92))
		draw_circle(route_position, 2.8 if waypoint else 1.9, Color(brass if waypoint else ivory, 0.94))

	var player: Array = state["player"]
	var player_cell := Vector2i(int(player[0]), int(player[1]))
	for y in range(grid_size):
		for x in range(grid_size):
			var center := _path_cell_center(x, y, grid_size)
			var arrow: Array = state["arrows"][y][x]
			_draw_arrow_go_vane(center, Vector2i(int(arrow[0]), int(arrow[1])), cell, bool(painted[y][x]), Vector2i(x, y) == player_cell)

	var target: Array = state["target"]
	var target_position := _path_cell_center(int(target[0]), int(target[1]), grid_size)
	var player_position := _path_cell_center(player_cell.x, player_cell.y, grid_size)
	var object_kind := str(arrow_go_object_fx.get("kind", ""))
	var object_age := elapsed - float(arrow_go_object_fx.get("started", -10.0))
	var object_duration := maxf(0.001, float(arrow_go_object_fx.get("duration", 0.0)))
	var object_active := object_age >= 0.0 and object_age < object_duration
	var object_t := clampf(object_age / object_duration, 0.0, 1.0) if object_active else 1.0
	var harbor_scale := 1.0 + sin(elapsed * 2.3) * 0.025
	if object_active and object_kind == "complete":
		harbor_scale += sin(clampf(object_t / 0.38, 0.0, 1.0) * PI) * 0.28
	for ring in range(2):
		draw_circle(target_position, (24.0 + float(ring) * 6.0) * harbor_scale, Color("f3c76f", 0.11 - float(ring) * 0.025))
	_draw_arrow_go_texture(ARROW_GO_GAG_HARBOR_TEXTURE, target_position, 46.0 * harbor_scale, Color.WHITE)

	if object_active and object_kind in ["step", "waypoint", "complete"]:
		var event_position: Vector2 = arrow_go_object_fx.get("to", player_position)
		var event_grade := clampi(int(arrow_go_object_fx.get("grade", 1)), 1, 4)
		var event_peak := sin(clampf(object_t / 0.58, 0.0, 1.0) * PI)
		var event_fade := 1.0 - clampf((object_t - 0.56) / 0.44, 0.0, 1.0)
		for ring in range(event_grade):
			var ring_t := clampf((object_t - float(ring) * 0.055) / 0.78, 0.0, 1.0)
			if ring_t > 0.0:
				draw_arc(event_position, 11.0 + ring_t * (13.0 + float(ring) * 7.0), 0, TAU, 26, Color("ffe1a0", event_fade * (0.62 - float(ring) * 0.09)), 2.1, true)
		var ribbon_count := 4 + event_grade * 2
		for ribbon in range(ribbon_count):
			var angle := TAU * float(ribbon) / float(ribbon_count) + object_t * 0.24
			var ribbon_position := event_position + Vector2(cos(angle), sin(angle)) * (14.0 + object_t * (10.0 + event_grade * 4.0))
			var tangent := Vector2(-sin(angle), cos(angle))
			draw_line(ribbon_position - tangent * 2.8, ribbon_position + tangent * 2.8, Color(coral, event_fade * 0.88), 2.0, true)
		if object_kind == "waypoint":
			draw_circle(event_position, 10.0 + event_peak * 4.0, Color(brass, 0.26 * event_fade))
			draw_arc(event_position, 12.0 + event_peak * 6.0, 0, TAU, 20, Color(ivory, 0.78 * event_fade), 2.4, true)
		elif object_kind == "complete":
			for ray in range(12):
				var ray_angle := TAU * float(ray) / 12.0
				var ray_from := target_position + Vector2(cos(ray_angle), sin(ray_angle)) * (25.0 + event_peak * 2.0)
				var ray_to := target_position + Vector2(cos(ray_angle), sin(ray_angle)) * (39.0 + event_peak * 12.0)
				draw_line(ray_from, ray_to, Color("ffe7a8", event_fade * 0.82), 2.3, true)

	if object_active and object_kind in ["crosswind_reject", "edge_reject"]:
		var attempted := Vector2(arrow_go_object_fx.get("attempted", Vector2i.LEFT)).normalized()
		var side := Vector2(-attempted.y, attempted.x)
		var reject_fade := 1.0 - object_t
		for gust in range(3):
			var gust_offset := (float(gust) - 1.0) * 8.0
			var gust_center := player_position + attempted * (10.0 + object_t * 18.0) + side * gust_offset
			draw_arc(gust_center, 8.0 + float(gust) * 2.0, -PI * 0.68, PI * 0.32, 14, Color("ff8a8e", reject_fade * (0.82 - float(gust) * 0.14)), 2.2, true)
		draw_line(player_position - side * 13.0, player_position + side * 13.0, Color("ffd1d1", reject_fade * 0.72), 3.0, true)

	if not _arrow_go_motion_active():
		var local_arrow: Array = state["arrows"][player_cell.y][player_cell.x]
		var expected_direction := Vector2i(int(local_arrow[0]), int(local_arrow[1]))
		var courier_position := player_position + _arrow_go_reject_offset()
		draw_circle(courier_position + Vector2(1.5, 3.0), 18.0, Color("05030b", 0.34))
		_draw_arrow_go_texture(_arrow_go_courier_texture(expected_direction), courier_position, 43.0, Color.WHITE)

	_draw_status_badge("航线 %d 格" % _painted_count(), Vector2(54, 692), Color("d7b4fa"), true, 128)
	_draw_text("顺着每格风向，把纸翼信使送进星港", Vector2(54, 746), 12, Color("f5dfd1", 0.88))
	_draw_text("星港在右下角", Vector2(392, 715), 12, Color("f0c878", 0.84))

func _draw_arrow_go_texture(texture: Texture2D, center: Vector2, diameter: float, modulate: Color) -> void:
	if texture == null:
		return
	var texture_size := texture.get_size()
	var longest := maxf(texture_size.x, texture_size.y)
	if longest <= 0.0:
		return
	var draw_size := texture_size * (diameter / longest)
	draw_texture_rect(texture, Rect2(center - draw_size * 0.5, draw_size), false, modulate)

func _draw_arrow_go_vane(center: Vector2, direction: Vector2i, cell: float, visited: bool, current: bool) -> void:
	var heading := Vector2(direction).normalized()
	if heading == Vector2.ZERO:
		return
	var side := Vector2(-heading.y, heading.x)
	var tip := center + heading * cell * 0.255
	var shoulder := center + heading * cell * 0.035
	var tail := center - heading * cell * 0.205
	var points := PackedVector2Array([
		tip,
		shoulder + side * cell * 0.105,
		shoulder + side * cell * 0.052,
		tail + side * cell * 0.052,
		tail - side * cell * 0.052,
		shoulder - side * cell * 0.052,
		shoulder - side * cell * 0.105,
	])
	var shadow := PackedVector2Array()
	for point in points:
		shadow.append(point + Vector2(1.3, 1.8))
	draw_colored_polygon(shadow, Color("05030b", 0.58))
	var fin_color := Color("f3bd68") if visited else Color("fff0d1")
	if current:
		fin_color = Color("ffcb72")
	draw_colored_polygon(points, fin_color)
	draw_line(tail, shoulder, Color("74422f", 0.86), maxf(1.4, cell * 0.035), true)
	draw_circle(center - heading * cell * 0.08, cell * 0.055, Color("6b3d2c"))
	draw_circle(center - heading * cell * 0.08 - Vector2(0.6, 0.7), cell * 0.026, Color("ffe1a1"))
	if current:
		draw_arc(center, cell * (0.34 + sin(elapsed * 4.0) * 0.015), 0, TAU, 24, Color("ffd584", 0.66), 2.0, true)

func _arrow_go_courier_texture(direction: Vector2i) -> Texture2D:
	return ARROW_GO_GAG_COURIER_DOWN_TEXTURE if direction.y > 0 else ARROW_GO_GAG_COURIER_RIGHT_TEXTURE

func _arrow_go_motion_active() -> bool:
	if game_id != "arrow_go" or motion_kind != "path" or motion_duration <= 0.0:
		return false
	var age := elapsed - motion_started
	return age >= 0.0 and age < motion_duration

func _arrow_go_reject_offset() -> Vector2:
	var kind := str(arrow_go_object_fx.get("kind", ""))
	if kind not in ["crosswind_reject", "edge_reject"]:
		return Vector2.ZERO
	var age := elapsed - float(arrow_go_object_fx.get("started", -10.0))
	var duration := maxf(0.001, float(arrow_go_object_fx.get("duration", 0.0)))
	if age < 0.0 or age >= duration:
		return Vector2.ZERO
	var attempted := Vector2(arrow_go_object_fx.get("attempted", Vector2i.LEFT)).normalized()
	var side := Vector2(-attempted.y, attempted.x)
	var envelope := pow(1.0 - age / duration, 1.7)
	return -attempted * abs(sin(age * 70.0)) * 6.5 * envelope + side * sin(age * 46.0) * 2.8 * envelope

func _draw_amaze_go() -> void:
	var grid_size := int(state["size"])
	var cell := 430.0 / float(grid_size)
	var origin := Vector2(54, 236)
	var board_rect := Rect2(origin, Vector2(430, 430))
	var painted: Array = state["painted"]
	var blueprint := Color("0a3154")
	var blueprint_deep := Color("061d35")
	var cyan_ink := Color("bce9e4")
	var brass := Color("cda85f")
	var paper := Color("f3e5bc")

	_draw_section_heading("发条测绘局", "相邻格点击或方向键移动", Color("79cbd7"))
	_draw_panel(Rect2(origin - Vector2(14, 12), Vector2(458, 458)), Color("020c18", 0.48), Color.TRANSPARENT, 18, 0)
	_draw_panel(Rect2(origin - Vector2(10, 10), Vector2(450, 450)), blueprint_deep, Color(brass, 0.88), 14, 3)
	draw_rect(board_rect, blueprint)

	# The live board remains code-native so walls, visited cells and coordinates
	# can never disagree with the frozen rules. Generated art supplies the two
	# signature objects, not baked gameplay or text.
	for y in range(grid_size):
		for x in range(grid_size):
			var rect := Rect2(origin + Vector2(float(x) * cell, float(y) * cell), Vector2(cell, cell))
			var fill := Color("0d3a5e") if (x + y) % 2 == 0 else Color("0b3558")
			if bool(painted[y][x]):
				fill = Color("17607b") if (x + y) % 2 == 0 else Color("145773")
			draw_rect(rect.grow(-2.0), fill)
			draw_rect(rect.grow(-2.0), Color(cyan_ink, 0.07), false, 1.0)
			var register := rect.position + Vector2(8, 8)
			draw_line(register - Vector2(3, 0), register + Vector2(3, 0), Color(cyan_ink, 0.18), 1.0)
			draw_line(register - Vector2(0, 3), register + Vector2(0, 3), Color(cyan_ink, 0.18), 1.0)

	# Ordered presentation-only survey evidence. This is deliberately separate
	# from authoritative state.painted and is never consulted by input or rules.
	for route_index in range(1, amaze_go_route.size()):
		var previous: Vector2i = amaze_go_route[route_index - 1]
		var current: Vector2i = amaze_go_route[route_index]
		var from_position := _path_cell_center(previous.x, previous.y, grid_size)
		var to_position := _path_cell_center(current.x, current.y, grid_size)
		draw_line(from_position + Vector2(1.5, 2.5), to_position + Vector2(1.5, 2.5), Color("02101e", 0.58), 11.0, true)
		draw_line(from_position, to_position, Color(cyan_ink, 0.74), 6.0, true)
		draw_line(from_position, to_position, Color(paper, 0.58), 1.4, true)
	for route_index in range(amaze_go_route.size()):
		var route_node: Vector2i = amaze_go_route[route_index]
		var route_position := _path_cell_center(route_node.x, route_node.y, grid_size)
		draw_circle(route_position, 5.6, Color("09243b"))
		draw_circle(route_position, 3.4, Color("d48961" if route_index % 5 != 0 else "f2cc72"))
		draw_circle(route_position - Vector2(0.8, 1.0), 1.2, Color("fff1c7", 0.84))

	# Raised brass rulers make collision topology readable before input. Interior
	# segments are drawn once, while the outer frame also serves edge rejection.
	_draw_amaze_go_wall(board_rect.position, Vector2(board_rect.end.x, board_rect.position.y), brass)
	_draw_amaze_go_wall(Vector2(board_rect.position.x, board_rect.end.y), board_rect.end, brass)
	_draw_amaze_go_wall(board_rect.position, Vector2(board_rect.position.x, board_rect.end.y), brass)
	_draw_amaze_go_wall(Vector2(board_rect.end.x, board_rect.position.y), board_rect.end, brass)
	var walls: Dictionary = state.get("walls", {})
	for y in range(grid_size):
		for x in range(grid_size):
			if x < grid_size - 1 and bool(walls.get(_maze_edge_key(x, y, 1, 0), false)):
				var wall_x := origin.x + float(x + 1) * cell
				_draw_amaze_go_wall(Vector2(wall_x, origin.y + float(y) * cell), Vector2(wall_x, origin.y + float(y + 1) * cell), brass)
			if y < grid_size - 1 and bool(walls.get(_maze_edge_key(x, y, 0, 1), false)):
				var wall_y := origin.y + float(y + 1) * cell
				_draw_amaze_go_wall(Vector2(origin.x + float(x) * cell, wall_y), Vector2(origin.x + float(x + 1) * cell, wall_y), brass)

	var target: Array = state["target"]
	var player: Array = state["player"]
	var target_position := _path_cell_center(int(target[0]), int(target[1]), grid_size)
	var player_position := _path_cell_center(int(player[0]), int(player[1]), grid_size)
	var target_pulse := 1.0 + sin(elapsed * 2.6) * 0.035
	var object_kind := str(amaze_go_object_fx.get("kind", ""))
	var object_age := elapsed - float(amaze_go_object_fx.get("started", -10.0))
	var object_duration := maxf(0.001, float(amaze_go_object_fx.get("duration", 0.0)))
	var object_active := object_age >= 0.0 and object_age < object_duration
	var object_t := clampf(object_age / object_duration, 0.0, 1.0) if object_active else 1.0
	if object_active and object_kind == "complete":
		target_pulse += sin(clampf(object_t / 0.38, 0.0, 1.0) * PI) * 0.24
	for ring in range(2):
		draw_circle(target_position, (31.0 + float(ring) * 7.0) * target_pulse, Color("f0bd62", 0.10 - float(ring) * 0.025))
	_draw_amaze_go_texture(AMAZE_GO_GAG_BEACON_TEXTURE, target_position, 59.0 * target_pulse, Color.WHITE)

	if object_active and object_kind in ["step", "waypoint", "complete"]:
		var event_position: Vector2 = amaze_go_object_fx.get("to", player_position)
		var event_grade := clampi(int(amaze_go_object_fx.get("grade", 1)), 1, 4)
		var event_peak := sin(clampf(object_t / 0.62, 0.0, 1.0) * PI)
		var event_fade := 1.0 - clampf((object_t - 0.58) / 0.42, 0.0, 1.0)
		for ring in range(event_grade):
			var ring_t := clampf((object_t - float(ring) * 0.06) / 0.84, 0.0, 1.0)
			if ring_t > 0.0:
				draw_arc(event_position, 13.0 + ring_t * (16.0 + float(ring) * 7.0), 0, TAU, 28, Color("f5d287", event_fade * (0.62 - float(ring) * 0.09)), 2.3, true)
		var pin_count := 4 + event_grade * 2
		for pin in range(pin_count):
			var angle := TAU * float(pin) / float(pin_count) - PI * 0.5
			var pin_position := event_position + Vector2(cos(angle), sin(angle)) * (18.0 + object_t * (12.0 + event_grade * 4.0))
			draw_circle(pin_position, 1.8 + event_peak * 1.6, Color("d98b62", event_fade * 0.88))
		if object_kind == "complete":
			for ray in range(12):
				var ray_angle := TAU * float(ray) / 12.0
				var ray_from := target_position + Vector2(cos(ray_angle), sin(ray_angle)) * (36.0 + event_peak * 3.0)
				var ray_to := target_position + Vector2(cos(ray_angle), sin(ray_angle)) * (48.0 + event_peak * 10.0)
				draw_line(ray_from, ray_to, Color("ffe3a0", event_fade * 0.78), 2.2, true)

	if not _amaze_go_motion_active():
		var reject_offset := _amaze_go_reject_offset()
		var surveyor_position := player_position + reject_offset
		draw_circle(surveyor_position + Vector2(2, 4), 27.0, Color("020b13", 0.34))
		_draw_amaze_go_texture(AMAZE_GO_GAG_SURVEYOR_TEXTURE, surveyor_position, 60.0, Color.WHITE)
		_draw_amaze_go_heading(surveyor_position, amaze_go_facing, 29.0, 0.92)

	var surveyed_count := _painted_count()
	_draw_status_badge("测绘 %d 格" % surveyed_count, Vector2(54, 692), Color("79cbd7"), true, 128)
	_draw_text("发条测绘仪会把每一步钉进蓝图航路", Vector2(54, 746), 12, Color("e9e1c7", 0.86))
	_draw_text("黄铜航标在右下角", Vector2(374, 715), 12, Color("f3d58b", 0.82))

func _draw_amaze_go_texture(texture: Texture2D, center: Vector2, diameter: float, modulate: Color) -> void:
	if texture == null:
		return
	var texture_size := texture.get_size()
	var longest := maxf(texture_size.x, texture_size.y)
	if longest <= 0.0:
		return
	var draw_size := texture_size * (diameter / longest)
	draw_texture_rect(texture, Rect2(center - draw_size * 0.5, draw_size), false, modulate)

func _draw_amaze_go_heading(center: Vector2, direction: Vector2i, radius: float, alpha: float) -> void:
	var heading := Vector2(direction)
	if heading == Vector2.ZERO:
		heading = Vector2.RIGHT
	heading = heading.normalized()
	var start := center + heading * (radius * 0.68)
	var finish := center + heading * radius
	draw_line(start, finish, Color("fff0c0", alpha * 0.78), 4.4, true)
	draw_circle(finish, 4.2, Color("d56f58", alpha))
	draw_circle(finish - heading * 1.0, 1.5, Color("ffe5b5", alpha * 0.86))

func _draw_amaze_go_wall(from: Vector2, to: Vector2, brass: Color) -> void:
	var hot := false
	var age := elapsed - float(amaze_go_object_fx.get("started", -10.0))
	var duration := float(amaze_go_object_fx.get("duration", 0.0))
	if str(amaze_go_object_fx.get("kind", "")) in ["wall_reject", "edge_reject"] and age >= 0.0 and age < duration:
		var contact: Vector2 = amaze_go_object_fx.get("contact", Vector2(-1000, -1000))
		hot = contact.distance_to((from + to) * 0.5) < 5.0
	var wall_color := Color("f06d64") if hot else brass
	var glow := (1.0 - age / maxf(duration, 0.001)) if hot else 0.0
	draw_line(from + Vector2(2, 3), to + Vector2(2, 3), Color("020a12", 0.62), 9.0, true)
	if hot:
		draw_line(from, to, Color(wall_color, 0.20 + glow * 0.32), 13.0, true)
	draw_line(from, to, wall_color, 6.5, true)
	draw_line(from, to, Color("fff0bd", 0.68), 1.6, true)
	draw_circle(from, 4.2, Color("6f4927"))
	draw_circle(to, 4.2, Color("6f4927"))
	draw_circle(from - Vector2(0.7, 0.7), 1.5, Color("ffe3a0"))
	draw_circle(to - Vector2(0.7, 0.7), 1.5, Color("ffe3a0"))

func _amaze_go_motion_active() -> bool:
	if game_id != "amaze_go" or motion_kind != "path" or motion_duration <= 0.0:
		return false
	var age := elapsed - motion_started
	return age >= 0.0 and age < motion_duration

func _amaze_go_reject_offset() -> Vector2:
	var kind := str(amaze_go_object_fx.get("kind", ""))
	if kind not in ["wall_reject", "edge_reject"]:
		return Vector2.ZERO
	var age := elapsed - float(amaze_go_object_fx.get("started", -10.0))
	var duration := maxf(0.001, float(amaze_go_object_fx.get("duration", 0.0)))
	if age < 0.0 or age >= duration:
		return Vector2.ZERO
	var direction := Vector2(amaze_go_object_fx.get("direction", Vector2i.RIGHT)).normalized()
	var envelope := pow(1.0 - age / duration, 1.7)
	return -direction * abs(sin(age * 72.0)) * 8.0 * envelope

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
