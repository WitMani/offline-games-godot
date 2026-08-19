#!/usr/bin/env python3
"""Give Godot Web engine and pack files independent content-addressed names."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

ENGINE_SUFFIXES = (
    ".js",
    ".wasm",
    ".audio.worklet.js",
    ".audio.position.worklet.js",
    ".worker.js",
)
TOKEN_LENGTH = 12
FINGERPRINTED = re.compile(r"^index\.[0-9a-f]{12}\.")


def digest(path: Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            hasher.update(chunk)
    return hasher.hexdigest()[:TOKEN_LENGTH]


def fingerprint(root: Path, check_only: bool = False) -> int:
    index_html = root / "index.html"
    wasm = root / "index.wasm"
    pack = root / "index.pck"
    if not index_html.is_file():
        raise SystemExit(f"missing Web entry point: {index_html}")
    if any(FINGERPRINTED.match(path.name) for path in root.iterdir()) and not wasm.exists():
        print("bundle is already fingerprinted")
        return 0
    for required in (wasm, pack):
        if not required.is_file():
            raise SystemExit(f"incomplete Godot Web bundle: missing {required.name}")

    engine_token = digest(wasm)
    pack_token = digest(pack)
    print(f"engine={engine_token} pack={pack_token}")
    if check_only:
        return 0

    renames: dict[str, str] = {}
    for suffix in ENGINE_SUFFIXES:
        source = root / f"index{suffix}"
        if source.is_file():
            target = root / f"index.{engine_token}{suffix}"
            source.rename(target)
            renames[source.name] = target.name
    pack_target = root / f"index.{pack_token}.pck"
    pack.rename(pack_target)
    renames[pack.name] = pack_target.name

    text = index_html.read_text(encoding="utf-8")
    text = text.replace('<script src="index.js"', f'<script src="{renames["index.js"]}"')
    match = re.search(r"const GODOT_CONFIG = (\{.*?\});", text, re.S)
    if match is None:
        raise SystemExit("index.html does not contain GODOT_CONFIG")
    config = json.loads(match.group(1))
    config["executable"] = f"index.{engine_token}"
    config["mainPack"] = pack_target.name
    if isinstance(config.get("fileSizes"), dict):
        config["fileSizes"] = {
            renames.get(name, name): size for name, size in config["fileSizes"].items()
        }
    encoded = json.dumps(config, separators=(",", ":"), ensure_ascii=False)
    index_html.write_text(text[: match.start(1)] + encoded + text[match.end(1) :], encoding="utf-8")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    return fingerprint(args.root.resolve(), args.check)


if __name__ == "__main__":
    raise SystemExit(main())
