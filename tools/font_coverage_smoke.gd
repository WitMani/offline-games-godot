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
	"木作合成 · 8", "木牌滑动归位", "木牌归位", "金纹里程碑 · 32", "大师雕版 · 2048", "连合 2 次 · +8", "合成 32 · +32", "2 连合", "这一侧已经锁住", "继续冲击更高数字", "柠檬落箱", "橙子落箱", "苹果落箱", "葡萄落箱", "西瓜落箱",
	"西瓜合成 · +50", "葡萄连携 · +90", "果箱满了", "红笔修正", "轻轻擦去", "落笔正确", "九宫完成", "逻辑完成", "猫爪确认", "猫爪盖章", "整册完成",
	"新牌入场", "牌库重整", "归位 · +25", "牌列衔接", "暮色翻牌", "仍被压住", "连牌 ×8", "点数不相邻",
	"玉牌抬起", "同纹共鸣 · +50", "纹样不同", "牌阵清空 · 玉成", "玉阵完成", "玩具俱乐部", "移开上层并收集三枚同图案", "剩余 21 枚 · 可选 7 枚", "被上层遮住", "上层方块尚未移开", "叶片入槽", "月片入槽", "莓片入槽", "星片入槽", "花片入槽", "贝片入槽", "晶片入槽", "三枚缝合 · +100", "上层清开 · 新方块露出", "槽位吃紧 · 余 2 格", "只余一格 · 谨慎落片", "槽位绷满 · 本局结束", "织毯完成 · 清盘", "织毯完成", "先移开上层 · 集齐三枚消除 · 七格满则结束",
	"逆着箭流", "蓝图有墙", "已到边界", "颜料铺开", "箭流推进", "蓝图点亮", "轨迹 ×10", "全域完成",
	"彩漆工坊", "滑动到底 · 让轨道吸满颜色", "滚动颜料舱，经过的每格都会依次吸满彩漆", "前方受阻", "长廊涂色", "短廊涂色", "重访通道", "只差 1 格", "彩漆封版", "轨道全满",
]
const MEOWDOKU_V3_COPY := [
	"猫咪领地", "每行一猫", "每列一猫", "同色一猫", "标记为排除格", "擦去排除标记",
	"抱回这只猫", "找到猫咪", "这里没有猫", "失去一颗心", "爱心用尽", "全员到齐",
	"单击选格或标记", "双击放猫", "题面提示猫", "重开再试一次", "已恢复猫咪手账",
]
const SNAKES_FEEDBACK_COPY := [
	"Snakes", "蛇群竞技", "自由转向、冲刺截击，争夺竞技场第一名",
	"收盒", "再来", "你", "抢豆", "我的位次", "排行榜", "体量",
	"新的第一名", "位次 ↑ 1", "彩豆散开！", "抢食 +4.0", "还吃不动！",
	"指向任意方向 · 按住右下冲刺", "撞到了！", "最终位次",
	"撞到竞技场边缘", "和游蛇撞了个满怀", "撞到其他游蛇",
	"点右上角“再来”回到蛇群", "冲刺",
]
const SYMBOL_COPY := ["♥♠◆♣"]
const TILE_NUMBER_COPY := ["0123456789"]
const ARROW_GO_V3_COPY := [
	"动物箭阵", "点整支箭头 · 按自身方向移出", "剩余 12 支",
	"先移走无遮挡的箭，逐层露出中央动物", "方向键选箭 · 回车移出", "低特效",
	"顺势移出", "转折移出", "遮挡松开", "动物快出现了", "全部清空 · 动物现身",
	"箭阵锁死", "去路被挡", "这支可以移出", "已标出一支可移箭", "前方有箭挡住",
]

var failures: Array[String] = []


func _init() -> void:
	_check_font(UI_FONT, MERGE_FEEDBACK_COPY, "merge_feedback_ui")
	# These strings are drawn by CatalogArtDirector with DISPLAY_FONT, which is
	# assigned to this same CJK resource in main.gd. Gate the live role, not just
	# an arbitrary fallback font that happens to contain the glyphs.
	_check_font(UI_FONT, CATALOG_EVENT_COPY, "catalog_event_display")
	_check_font(UI_FONT, MEOWDOKU_V3_COPY, "meowdoku_v3_ui_cjk")
	_check_font(UI_FONT, SNAKES_FEEDBACK_COPY, "snakes_live_ui")
	_check_font(NUMBER_FONT, [NUMBER_COPY], "number_font")
	_check_font(TILE_NUMBER_FONT, TILE_NUMBER_COPY, "tile_number_font")
	_check_font(SYMBOL_FONT, SYMBOL_COPY, "symbol_font")
	_check_font(UI_FONT, ARROW_GO_V3_COPY, "arrow_go_v3_ui_cjk")
	print("FONT_COVERAGE_SMOKE=%d" % (MERGE_FEEDBACK_COPY.size() + CATALOG_EVENT_COPY.size() + MEOWDOKU_V3_COPY.size() + SNAKES_FEEDBACK_COPY.size() + TILE_NUMBER_COPY.size() + SYMBOL_COPY.size() + ARROW_GO_V3_COPY.size() + 1))
	print("FONT_COVERAGE_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _check_font(font: Font, samples: Array, role: String) -> void:
	for sample in samples:
		var text := str(sample)
		for index in range(text.length()):
			var codepoint := text.unicode_at(index)
			if not font.has_char(codepoint):
				failures.append("%s:U+%04X" % [role, codepoint])
