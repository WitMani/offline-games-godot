#!/usr/bin/env python3
"""Read-only manifest/provenance gate for an unencrypted Godot 4 PCK.

The Web release presets in this repository use an unencrypted format-v3 pack.
This utility reads only the directory table; it never extracts or rewrites pack
contents. It is intentionally small enough for release evidence to record the
exact parser and checks that were used.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import struct
from pathlib import Path


HEADER = struct.Struct("<4sIIIIIQQ")
ENTRY_TAIL = struct.Struct("<QQ16sI")
MAGIC = b"GDPC"
ENCRYPTED_DIRECTORY_FLAG = 1


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_manifest(path: Path) -> dict[str, object]:
    pack_size = path.stat().st_size
    with path.open("rb") as handle:
        header_bytes = handle.read(HEADER.size)
        if len(header_bytes) != HEADER.size:
            raise ValueError("truncated PCK header")
        (
            magic,
            pack_format,
            engine_major,
            engine_minor,
            engine_patch,
            flags,
            file_base,
            directory_offset,
        ) = HEADER.unpack(header_bytes)
        if magic != MAGIC:
            raise ValueError(f"unexpected PCK magic: {magic!r}")
        if flags & ENCRYPTED_DIRECTORY_FLAG:
            raise ValueError("encrypted PCK directories are not supported")
        if directory_offset >= pack_size:
            raise ValueError("PCK directory offset is outside the file")
        handle.seek(directory_offset)
        count_bytes = handle.read(4)
        if len(count_bytes) != 4:
            raise ValueError("truncated PCK directory count")
        file_count = struct.unpack("<I", count_bytes)[0]
        if file_count > 1_000_000:
            raise ValueError(f"implausible PCK file count: {file_count}")
        entries: list[dict[str, object]] = []
        for index in range(file_count):
            length_bytes = handle.read(4)
            if len(length_bytes) != 4:
                raise ValueError(f"truncated path length at entry {index}")
            path_length = struct.unpack("<I", length_bytes)[0]
            if path_length == 0 or path_length > 1 << 20:
                raise ValueError(f"invalid path length at entry {index}")
            raw_path = handle.read(path_length)
            tail = handle.read(ENTRY_TAIL.size)
            if len(raw_path) != path_length or len(tail) != ENTRY_TAIL.size:
                raise ValueError(f"truncated directory entry {index}")
            offset, size, md5, entry_flags = ENTRY_TAIL.unpack(tail)
            name = raw_path.rstrip(b"\x00").decode("utf-8")
            if offset + size > directory_offset:
                raise ValueError(f"entry payload overlaps directory: {name}")
            entries.append(
                {
                    "path": name,
                    "offset": offset,
                    "size": size,
                    "md5": md5.hex(),
                    "flags": entry_flags,
                }
            )
    return {
        "pck": str(path.resolve()),
        "sha256": sha256(path),
        "bytes": pack_size,
        "pack_format": pack_format,
        "engine": [engine_major, engine_minor, engine_patch],
        "flags": flags,
        "file_base": file_base,
        "directory_offset": directory_offset,
        "file_count": file_count,
        "entries": entries,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("pck", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--require", action="append", default=[])
    parser.add_argument("--forbid-regex", action="append", default=[])
    args = parser.parse_args()

    report = read_manifest(args.pck)
    paths = [str(entry["path"]) for entry in report["entries"]]
    required = {
        token: [path for path in paths if token in path] for token in args.require
    }
    forbidden = {
        pattern: [path for path in paths if re.search(pattern, path, re.IGNORECASE)]
        for pattern in args.forbid_regex
    }
    checks = {
        "all_required_present": all(required.values()),
        "all_forbidden_absent": all(not matches for matches in forbidden.values()),
    }
    report["checks"] = checks
    report["required_matches"] = required
    report["forbidden_matches"] = forbidden
    report["result"] = "PASS" if all(checks.values()) else "FAIL"
    encoded = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded, encoding="utf-8")
    else:
        print(encoded, end="")
    print(f"PCK_MANIFEST_RESULT={report['result']}")
    print(f"PCK_MANIFEST_FILES={report['file_count']}")
    return 0 if report["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
