extends SceneTree

const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Subset.otf")
const NUMBER_FONT: Font = preload("res://assets/fonts/DejaVuSans.ttf")

const MERGE_FEEDBACK_COPY := [
	"轻甜 ×2  +4",
	"连携 ×3  +8",
	"超连携 ×5  +16",
	"传奇配方 ×8  +32",
	"传奇配方 ×8 · +32 → 32",
	"松开 · 熬成 64",
]
const NUMBER_COPY := "0123456789+-×"

var failures: Array[String] = []


func _init() -> void:
	_check_font(UI_FONT, MERGE_FEEDBACK_COPY, "merge_feedback_ui")
	_check_font(NUMBER_FONT, [NUMBER_COPY], "number_font")
	print("FONT_COVERAGE_SMOKE=%d" % (MERGE_FEEDBACK_COPY.size() + 1))
	print("FONT_COVERAGE_RESULT=%s" % ("PASS" if failures.is_empty() else "FAIL " + ",".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _check_font(font: Font, samples: Array, role: String) -> void:
	for sample in samples:
		var text := str(sample)
		for index in range(text.length()):
			var codepoint := text.unicode_at(index)
			if not font.has_char(codepoint):
				failures.append("%s:U+%04X" % [role, codepoint])
