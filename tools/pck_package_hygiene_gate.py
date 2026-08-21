#!/usr/bin/env python3
"""Reject production provenance and author-environment metadata in a Godot 4 PCK."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
from pathlib import Path


FORBIDDEN_PATH_FRAGMENTS = (
    "asset-ledger.json",
    "private-evidence",
    "source-master",
    "masters/",
    "docs/",
    "tools/",
)

FORBIDDEN_PAYLOAD_MARKERS = (
    "/home/",
    ".codex/generated_images",
    "source_delivery",
    "private-evidence",
    "source-master",
    "AI_generated_assets",
    "Bearer ",
    "OPENAI_API_KEY",
    "FAL_KEY",
)


def pck_paths(payload: bytes) -> list[str]:
    if payload[:4] != b"GDPC":
        raise ValueError("not a Godot PCK")
    pack_format = struct.unpack_from("<I", payload, 4)[0]
    if pack_format != 3:
        raise ValueError(f"unsupported PCK format {pack_format}; expected 3")
    directory_offset = struct.unpack_from("<Q", payload, 32)[0]
    if directory_offset >= len(payload):
        raise ValueError("PCK directory offset is outside the file")
    position = directory_offset
    count = struct.unpack_from("<I", payload, position)[0]
    position += 4
    result: list[str] = []
    for _index in range(count):
        path_length = struct.unpack_from("<I", payload, position)[0]
        position += 4
        raw_path = payload[position : position + path_length]
        position += (path_length + 3) & ~3
        result.append(raw_path.rstrip(b"\0").decode("utf-8"))
        position += 8 + 8 + 16 + 4
    if position != len(payload):
        raise ValueError(
            f"PCK directory ended at {position}, file length is {len(payload)}"
        )
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("pck", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    pck = args.pck.resolve()
    payload = pck.read_bytes()
    paths = pck_paths(payload)
    forbidden_paths = sorted(
        path
        for path in paths
        if any(fragment in path for fragment in FORBIDDEN_PATH_FRAGMENTS)
    )
    payload_markers = {
        marker: marker.encode("utf-8") in payload
        for marker in FORBIDDEN_PAYLOAD_MARKERS
    }
    checks = {
        "fingerprint_matches_filename": (
            f".{hashlib.sha256(payload).hexdigest()[:12]}.pck" in pck.name
        ),
        "forbidden_paths_absent": not forbidden_paths,
        "forbidden_payload_markers_absent": not any(payload_markers.values()),
    }
    result = "PASS" if all(checks.values()) else "FAIL"
    report = {
        "schema": "offline-games/pck-package-hygiene/v1",
        "pck": {
            "path": str(pck),
            "bytes": len(payload),
            "sha256": hashlib.sha256(payload).hexdigest(),
            "entries": len(paths),
        },
        "checks": checks,
        "forbidden_paths": forbidden_paths,
        "forbidden_payload_markers": payload_markers,
        "result": result,
    }
    rendered = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")
    print(f"PCK_PACKAGE_HYGIENE={result}")
    print(rendered, end="")
    return 0 if result == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
