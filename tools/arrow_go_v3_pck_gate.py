#!/usr/bin/env python3
"""Inspect a Godot 4 PCK directory and enforce Arrow GO v3 archive policy."""

from __future__ import annotations

import argparse
import struct
from pathlib import Path


REQUIRED_FRAGMENTS = (
    ".godot/exported/",
    ".godot/imported/arrow_go_fox_center_gag_v3.png-",
    ".godot/imported/arrow_go_arrow_escape_gag_v3.ogg-",
    ".godot/imported/arrow_go_fox_reveal_gag_v3.ogg-",
    ".godot/imported/NotoSansCJKsc-Subset.otf-",
    "assets/art/catalog/path_games/gag/arrow_go_fox_center_gag_v3.png.import",
    "assets/audio/catalog/path_games/gag/arrow_go_arrow_escape_gag_v3.ogg.import",
    "assets/audio/catalog/path_games/gag/arrow_go_fox_reveal_gag_v3.ogg.import",
    "assets/fonts/NotoSansCJKsc-Subset.otf.import",
)

FORBIDDEN_FRAGMENTS = (
    "arrow_go_wind_plate_gag_v1",
    "arrow_go_courier_right_gag_v1",
    "arrow_go_courier_down_gag_v1",
    "arrow_go_harbor_gag_v1",
    "arrow_go_kite_step_gag_v1",
    "arrow_go_harbor_dock_gag_v1",
    "NotoSansCJKsc-Regular",
    "AI_generated_assets",
    "generated_images__20260821_084539_FAL.ai",
    "masters/",
    "docs/",
    "tools/",
)


def pck_paths(path: Path) -> list[str]:
    data = path.read_bytes()
    if data[:4] != b"GDPC":
        raise ValueError("not a Godot PCK")
    pack_format = struct.unpack_from("<I", data, 4)[0]
    if pack_format != 3:
        raise ValueError(f"unsupported PCK format {pack_format}; expected 3")
    directory_offset = struct.unpack_from("<Q", data, 32)[0]
    position = directory_offset
    count = struct.unpack_from("<I", data, position)[0]
    position += 4
    result: list[str] = []
    for _index in range(count):
        path_length = struct.unpack_from("<I", data, position)[0]
        position += 4
        raw_path = data[position : position + path_length]
        position += (path_length + 3) & ~3
        result.append(raw_path.rstrip(b"\0").decode("utf-8"))
        # file offset, size, MD5 and flags
        position += 8 + 8 + 16 + 4
    if position != len(data):
        raise ValueError(
            f"PCK directory ended at {position}, file length is {len(data)}"
        )
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("pck", type=Path)
    parser.add_argument("--ledger", type=Path)
    args = parser.parse_args()

    paths = pck_paths(args.pck)
    missing = [
        fragment
        for fragment in REQUIRED_FRAGMENTS
        if not any(fragment in path for path in paths)
    ]
    forbidden = [
        f"{fragment}:{path}"
        for fragment in FORBIDDEN_FRAGMENTS
        for path in paths
        if fragment in path
    ]
    if args.ledger:
        args.ledger.parent.mkdir(parents=True, exist_ok=True)
        args.ledger.write_text("\n".join(paths) + "\n", encoding="utf-8")

    failures = [*(f"missing:{item}" for item in missing), *forbidden]
    print(f"ARROW_GO_V3_PCK_ENTRIES={len(paths)}")
    print(f"ARROW_GO_V3_PCK_REQUIRED={len(REQUIRED_FRAGMENTS)}")
    print(f"ARROW_GO_V3_PCK_FORBIDDEN={len(FORBIDDEN_FRAGMENTS)}")
    print(
        "ARROW_GO_V3_PCK_RESULT="
        + ("PASS" if not failures else "FAIL " + ",".join(failures))
    )
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
