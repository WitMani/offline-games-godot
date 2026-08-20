# Noto Sans CJK SC source

`NotoSansCJKsc-Regular.otf` is the rebuild source for the much smaller font in
`assets/fonts/NotoSansCJKsc-Subset.otf`. The `.gdignore` keeps the 15.7 MB source
out of Godot imports and Web exports; `tools/build_cjk_font_subset.py` is the
only production consumer.

The face is Noto Sans CJK SC Regular, distributed under SIL Open Font License
1.1. The license is preserved in `OFL-NotoSansCJK.txt` beside the source font.

Rebuild and gate:

```bash
python3 tools/build_cjk_font_subset.py
python3 tools/build_cjk_font_subset.py --check
```
