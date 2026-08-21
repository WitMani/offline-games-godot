extends SceneTree

const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const NUMBER_FONT: Font = preload("res://assets/fonts/DejaVuSans.ttf")
const TILE_NUMBER_FONT: Font = preload("res://assets/fonts/RobotoMedium-Numbers.ttf")
const SYMBOL_FONT: Font = preload("res://assets/fonts/Unifont.otf")

const MERGE_FEEDBACK_COPY := [
	"轻甜 ×2  +4",
	"连携 ×3  +8",
	"超连携 ×5  +16",
	"传奇配方 ×8  +32",
	"传奇配方 ×8 · +32 → 32",
	"松开 · 熬成 64",
	"难度 · 简单",
	"难度 · 困难",
	"撤销",
	"已撤销上一份配方",
	"暂无可撤销配方",
	"难度切换 · 困难",
	"历史 224,575P · 简单",
]
const NUMBER_COPY := "0123456789+-×"
const CATALOG_EVENT_COPY := [
	"木作合成 · +2048", "木牌滑动归位", "木牌归位", "金纹连携 · +32", "大师雕版 · +128", "这一侧已经锁住", "柠檬落箱", "橙子落箱", "苹果落箱", "葡萄落箱", "西瓜落箱",
	"西瓜合成 · +50", "葡萄连携 · +90", "果箱满了", "红笔修正", "轻轻擦去", "落笔正确", "九宫完成", "逻辑完成", "猫爪确认", "猫爪盖章", "整册完成",
	"新牌入场", "牌库重整", "归位 · +25", "牌列衔接", "暮色翻牌", "仍被压住", "连牌 ×8", "点数不相邻",
	"玉牌抬起", "同纹共鸣 · +50", "纹样不同", "牌阵清空 · 玉成", "玉阵完成", "叶片入槽", "月片入槽", "莓片入槽", "星片入槽", "花片入槽", "贝片入槽", "晶片入槽", "三枚缝合 · +100", "槽位吃紧 · 余 2 格", "只余一格 · 谨慎落片", "槽位绷满 · 本局结束", "织毯完成 · 清盘", "织毯完成",
	"逆着箭流", "蓝图有墙", "已到边界", "颜料铺开", "箭流推进", "蓝图点亮", "轨迹 ×10", "全域完成",
]
const SYMBOL_COPY := ["♥♠◆♣"]
const TILE_NUMBER_COPY := ["0123456789"]

var failures: Array[String] = []


func _init() -> void:
	_check_font(UI_FONT, MERGE_FEEDBACK_COPY, "merge_feedback_ui")
	# These strings are drawn by CatalogArtDirector with DISPLAY_FONT, which is
	# assigned to this same CJK resource in main.gd. Gate the live role, not just
	# an arbitrary fallback font that happens to contain the glyphs.
	_check_font(UI_FONT, CATALOG_EVENT_COPY, "catalog_event_display")
	_check_font(NUMBER_FONT, [NUMBER_COPY], "number_font")
	_check_font(TILE_NUMBER_FONT, TILE_NUMBER_COPY, "tile_number_font")
	_check_font(SYMBOL_FONT, SYMBOL_COPY, "symbol_font")
	print("FONT_COVERAGE_SMOKE=%d" % (MERGE_FEEDBACK_COPY.size() + CATALOG_EVENT_COPY.size() + TILE_NUMBER_COPY.size() + SYMBOL_COPY.size() + 1))
	print("FONT_COVERAGE_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _check_font(font: Font, samples: Array, role: String) -> void:
	for sample in samples:
		var text := str(sample)
		for index in range(text.length()):
			var codepoint := text.unicode_at(index)
			if not font.has_char(codepoint):
				failures.append("%s:U+%04X" % [role, codepoint])
