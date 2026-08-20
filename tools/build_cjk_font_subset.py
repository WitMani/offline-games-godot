#!/usr/bin/env python3
"""Build and gate the shipped Noto Sans CJK subset.

The character contract is the union of shipped text sources and GB2312 level 1,
which covers runtime-created Chinese feedback that cannot be found statically.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE_FONT = ROOT / "tools/vendor/fonts/NotoSansCJKsc-Regular.otf"
OUTPUT_FONT = ROOT / "assets/fonts/NotoSansCJKsc-Subset.otf"
TEXT_SUFFIXES = {".gd", ".json", ".tscn", ".tres", ".cfg", ".godot"}
EXCLUDED_PARTS = {".git", ".godot", "build", "dist", "node_modules", "vendor"}
# U+21BB only appears as an input-normalization token in _add_button; it is
# removed before UI_FONT receives the label and belongs to the symbol role.
NON_UI_CODEPOINTS = {0x21BB}


def scanned_codepoints() -> set[int]:
    codepoints: set[int] = set(range(0x20, 0x7F))
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        if any(part in EXCLUDED_PARTS for part in path.relative_to(ROOT).parts):
            continue
        codepoints.update(
            ord(character)
            for character in path.read_text("utf-8")
            if ord(character) >= 0x20 and ord(character) != 0x7F
        )
    return codepoints - NON_UI_CODEPOINTS


def gb2312_level_one_codepoints() -> set[int]:
    codepoints: set[int] = set()
    # GB2312 rows 16–55 are the 3,755 level-one Hanzi. Decode via the standard
    # library so the fallback is reproducible and never maintained by hand.
    for row in range(16, 56):
        for column in range(1, 95):
            encoded = bytes((row + 0xA0, column + 0xA0))
            try:
                decoded = encoded.decode("gb2312")
            except UnicodeDecodeError:
                continue
            codepoints.update(ord(character) for character in decoded)
    return codepoints


def required_codepoints() -> set[int]:
    return scanned_codepoints() | gb2312_level_one_codepoints()


def covered_codepoints(path: Path) -> set[int]:
    font = TTFont(path, lazy=True)
    try:
        covered: set[int] = set()
        for table in font["cmap"].tables:
            covered.update(table.cmap)
        return covered
    finally:
        font.close()


def gate(required: set[int]) -> int:
    if not OUTPUT_FONT.exists():
        print(f"FONT_SUBSET_GATE=FAIL missing:{OUTPUT_FONT}")
        return 1
    missing = sorted(required - covered_codepoints(OUTPUT_FONT))
    if missing:
        preview = ",".join(f"U+{value:04X}" for value in missing[:24])
        print(f"FONT_SUBSET_GATE=FAIL missing={len(missing)} {preview}")
        return 1
    print(f"FONT_SUBSET_GATE=PASS required={len(required)} bytes={OUTPUT_FONT.stat().st_size}")
    return 0


def build(required: set[int]) -> None:
    if not SOURCE_FONT.exists():
        raise FileNotFoundError(f"full source font is missing: {SOURCE_FONT}")
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.name_legacy = True
    options.name_languages = ["*"]
    options.notdef_glyph = True
    options.notdef_outline = True
    options.recommended_glyphs = True
    options.recalc_timestamp = False
    font = subset.load_font(str(SOURCE_FONT), options, lazy=False)
    font.recalcTimestamp = False
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(unicodes=sorted(required))
    subsetter.subset(font)
    temporary = OUTPUT_FONT.with_suffix(".otf.tmp")
    subset.save_font(font, str(temporary), options)
    temporary.replace(OUTPUT_FONT)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="gate without rebuilding")
    args = parser.parse_args()
    required = required_codepoints()
    if not args.check:
        build(required)
    return gate(required)


if __name__ == "__main__":
    sys.exit(main())
