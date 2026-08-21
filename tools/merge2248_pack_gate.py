#!/usr/bin/env python3
"""Byte-marker gate for the fingerprinted 2248 Web pack shipping boundary."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


RUNTIME_ASSETS = [
    "res://assets/art/merge2248/gag/candy_wrapped_gag_v3.png",
    "res://assets/art/merge2248/gag/candy_tart_gag_v3.png",
    "res://assets/art/merge2248/gag/candy_lozenge_gag_v3.png",
    "res://assets/art/merge2248/gag/candy_flower_gag_v3.png",
    "res://assets/art/merge2248/gag/caramel_cream_burst_gag_v3.png",
    "res://assets/audio/merge2248/gag/candy_merge_gag_v3.ogg",
    "res://assets/audio/merge2248/gag/recipe_mastery_gag_v3.ogg",
]
FORBIDDEN_MARKERS = [
    "generated_images__20260821_004833_FAL.ai.png",
    "generated_images__20260821_005009_FAL.ai.png",
    "token_q0_runtime_source.png",
    "token_q1_runtime_source.png",
    "token_q2_runtime_source.png",
    "token_q3_runtime_source.png",
    "merge_burst_runtime_source.png",
    "merge2248_candy_merge_02_master.wav",
    "merge2248_recipe_mastery_02_master.wav",
    "private-evidence/offline-games/merge2248",
    "docs/audit/merge2248-fidelity-v4",
]
REQUIRED_FONT = "res://assets/fonts/NotoSansCJKsc-Subset.otf"
FORBIDDEN_FONTS = ["NotoSansCJKsc-Regular", "NotoSansCJKsc-VF", "SourceHanSans"]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("pck")
    parser.add_argument("--output")
    args = parser.parse_args()

    pck = Path(args.pck).resolve()
    payload = pck.read_bytes()
    digest = hashlib.sha256(payload).hexdigest()
    runtime_presence = {
        marker: marker.encode("utf-8") in payload for marker in RUNTIME_ASSETS
    }
    import_presence = {
        f"{marker.removeprefix('res://')}.import":
        f"{marker.removeprefix('res://')}.import".encode("utf-8") in payload
        for marker in RUNTIME_ASSETS
    }
    forbidden_presence = {
        marker: marker.encode("utf-8") in payload for marker in FORBIDDEN_MARKERS
    }
    forbidden_font_presence = {
        marker: marker.encode("utf-8") in payload for marker in FORBIDDEN_FONTS
    }
    fingerprint_matches = f".{digest[:12]}.pck" in pck.name
    checks = {
        "fingerprint_matches_sha256": fingerprint_matches,
        "seven_runtime_derivatives_present": all(runtime_presence.values()),
        "seven_import_records_present": all(import_presence.values()),
        "source_masters_private_evidence_absent": not any(forbidden_presence.values()),
        "cjk_subset_present": REQUIRED_FONT.encode("utf-8") in payload,
        "full_cjk_fonts_absent": not any(forbidden_font_presence.values()),
    }
    report = {
        "schema": "offline-games/merge2248-pack-gate/v1",
        "path": str(pck),
        "bytes": len(payload),
        "sha256": digest,
        "checks": checks,
        "runtime_presence": runtime_presence,
        "import_presence": import_presence,
        "forbidden_presence": forbidden_presence,
        "required_font": REQUIRED_FONT,
        "forbidden_font_presence": forbidden_font_presence,
        "method": "explicit UTF-8 resource-path byte markers in the Godot PCK",
        "result": "PASS" if all(checks.values()) else "FAIL",
    }
    rendered = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        output = Path(args.output)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(rendered, encoding="utf-8")
    print(f"MERGE2248_PACK_GATE={report['result']}")
    print(rendered, end="")
    return 0 if report["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
