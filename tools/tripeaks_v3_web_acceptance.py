#!/usr/bin/env python3
"""Real Chrome acceptance for one clean fingerprinted TriPeaks v3 bundle."""

from __future__ import annotations

import argparse
import copy
import functools
import hashlib
import http.server
import json
import mimetypes
import os
import re
import threading
import time
from pathlib import Path
from typing import BinaryIO

from playwright.sync_api import sync_playwright


SNAPSHOT_KEY = "offline-games-tripeaks-v3"
VIEWPORT = {"width": 540, "height": 960}
IMPORTANT_SUFFIXES = {".html", ".js", ".wasm", ".pck"}
CARD_BACK_PATH = b"assets/art/cards/tripeaks_card_back_gag_v1.webp"
STREAK_SFX_PATH = b"assets/audio/cards/tripeaks_streak_peak_gag_v1.ogg"
VIBRATION_SPY = r"""
(() => {
  window.__vibrateCalls = [];
  const spy = value => { window.__vibrateCalls.push(value); return true; };
  try {
    Object.defineProperty(navigator, 'vibrate', {configurable: true, value: spy});
  } catch (_) {
    navigator.vibrate = spy;
  }
})();
"""


class BundleRequestHandler(http.server.SimpleHTTPRequestHandler):
    """Static server with isolation, immutable fingerprints and byte ranges."""

    protocol_version = "HTTP/1.1"

    def __init__(self, *args, directory: str, **kwargs) -> None:
        self._range: tuple[int, int] | None = None
        super().__init__(*args, directory=directory, **kwargs)

    def log_message(self, _format: str, *_args: object) -> None:
        return

    def end_headers(self) -> None:
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        self.send_header("Accept-Ranges", "bytes")
        if re.search(r"\.[0-9a-f]{12}\.", self.path):
            self.send_header("Cache-Control", "public, max-age=31536000, immutable")
        else:
            self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def send_head(self) -> BinaryIO | None:
        path = Path(self.translate_path(self.path))
        if path.is_dir():
            path = path / "index.html"
        try:
            source = path.open("rb")
        except OSError:
            self.send_error(404, "File not found")
            return None
        stat = os.fstat(source.fileno())
        size = stat.st_size
        content_type = mimetypes.guess_type(str(path))[0] or "application/octet-stream"
        range_header = self.headers.get("Range", "")
        match = re.fullmatch(r"bytes=(\d*)-(\d*)", range_header)
        if range_header and match is None:
            source.close()
            self.send_error(416, "Invalid byte range")
            return None
        if match is not None:
            start_text, end_text = match.groups()
            if not start_text and not end_text:
                source.close()
                self.send_error(416, "Invalid byte range")
                return None
            if start_text:
                start = int(start_text)
                end = int(end_text) if end_text else size - 1
            else:
                suffix_length = int(end_text)
                start = max(0, size - suffix_length)
                end = size - 1
            if start >= size or start > end:
                source.close()
                self.send_response(416)
                self.send_header("Content-Range", f"bytes */{size}")
                self.send_header("Content-Length", "0")
                self.end_headers()
                return None
            end = min(end, size - 1)
            self._range = (start, end)
            self.send_response(206)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
            self.send_header("Content-Length", str(end - start + 1))
            self.send_header("Last-Modified", self.date_time_string(stat.st_mtime))
            self.end_headers()
            source.seek(start)
            return source
        self._range = None
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(size))
        self.send_header("Last-Modified", self.date_time_string(stat.st_mtime))
        self.end_headers()
        return source

    def copyfile(self, source: BinaryIO, outputfile: BinaryIO) -> None:
        if self._range is None:
            super().copyfile(source, outputfile)
            return
        start, end = self._range
        remaining = end - start + 1
        while remaining > 0:
            chunk = source.read(min(64 * 1024, remaining))
            if not chunk:
                break
            outputfile.write(chunk)
            remaining -= len(chunk)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def current_state(page) -> dict:
    return page.evaluate("window.__gameAcceptance.getState()")


def model_summary(snapshot: dict) -> dict:
    state = snapshot.get("state", {})
    return {
        "schema": state.get("schema"),
        "status": state.get("status"),
        "seed": state.get("seed"),
        "wrap_ace_king": state.get("wrap_ace_king"),
        "tableau": state.get("tableau", []),
        "removed": state.get("removed", []),
        "stock": state.get("stock", []),
        "waste": state.get("waste", []),
        "score": state.get("score"),
        "moves": state.get("moves"),
        "streak": state.get("streak"),
        "remaining": state.get("remaining"),
    }


def summarize(snapshot: dict) -> dict:
    state = snapshot.get("state", {})
    return {
        "screen": snapshot.get("screen"),
        "game_id": snapshot.get("game_id"),
        "status": state.get("status"),
        "stock_count": len(state.get("stock", [])),
        "waste_count": len(state.get("waste", [])),
        "waste_top": state.get("waste", [None])[-1] if state.get("waste") else None,
        "tableau": state.get("tableau", []),
        "score": state.get("score"),
        "moves": state.get("moves"),
        "streak": state.get("streak"),
        "remaining": state.get("remaining"),
        "peak_count": state.get("peak_count"),
        "exposed_slots": state.get("exposed_slots", []),
        "legal_slots": state.get("legal_slots", []),
        "focus_slot": state.get("focus_slot"),
        "recovered": state.get("recovered"),
        "reduced_effects": state.get("reduced_effects"),
        "haptic_emissions": state.get("haptic_emissions"),
    }


def canvas_box(page) -> dict[str, float]:
    box = page.locator("canvas").bounding_box()
    if box is None:
        raise RuntimeError("Godot canvas did not expose a bounding box")
    return box


def point(box: dict[str, float], x: float, y: float) -> tuple[float, float]:
    return (
        box["x"] + x / 540.0 * box["width"],
        box["y"] + y / 960.0 * box["height"],
    )


def wait_ready(page, timeout_ms: int) -> None:
    page.wait_for_function(
        "window.__gameAcceptance && window.__gameAcceptance.getState().ready === true",
        timeout=timeout_ms,
    )


def open_tripeaks(page) -> dict:
    box = canvas_box(page)
    # Catalog index eight: left card, fifth row.
    page.mouse.click(*point(box, 141, 725))
    page.wait_for_function(
        "window.__gameAcceptance.getState().game_id === 'tripeaks'",
        timeout=10_000,
    )
    page.wait_for_timeout(180)
    return current_state(page)


def reload_and_open(page, timeout_ms: int) -> dict:
    page.reload(wait_until="domcontentloaded", timeout=timeout_ms)
    wait_ready(page, timeout_ms)
    return open_tripeaks(page)


def write_snapshot(page, snapshot: dict) -> None:
    payload = json.dumps(snapshot, ensure_ascii=False, separators=(",", ":"))
    page.evaluate(
        "([key, payload]) => window.localStorage.setItem(key, payload)",
        [SNAPSHOT_KEY, payload],
    )


def card_id(rank: int, suit: int = 0) -> int:
    return suit * 13 + rank - 1


def fixture(
    base_state: dict,
    active_slots: dict[int, int],
    waste_top: int,
    stock_cards: list[int] | None = None,
    streak: int = 0,
) -> dict:
    stock_cards = list(stock_cards or [])
    result = copy.deepcopy(base_state)
    tableau = [int(active_slots.get(slot, -1)) for slot in range(28)]
    used = {card for card in tableau if card >= 0}
    used.add(waste_top)
    used.update(stock_cards)
    waste = [card for card in range(52) if card not in used] + [waste_top]
    removed = [slot for slot, card in enumerate(tableau) if card < 0]
    result.update(
        {
            "schema": "tripeaks-state/v3",
            "game_id": "tripeaks",
            "wrap_ace_king": True,
            "tableau": tableau,
            "removed": removed,
            "stock": stock_cards,
            "waste": waste,
            "score": len(removed) * 30,
            "moves": len(waste) - 1,
            "streak": streak,
            "status": "playing",
            "remaining": len(active_slots),
        }
    )
    return result


def reset_with_key(page) -> dict:
    page.keyboard.press("KeyR")
    page.wait_for_function(
        "window.__gameAcceptance.getState().state.moves === 0 && "
        "window.__gameAcceptance.getState().state.stock.length === 23 && "
        "window.__gameAcceptance.getState().state.waste.length === 1 && "
        "window.__gameAcceptance.getState().state.recovered === false",
        timeout=5_000,
    )
    return current_state(page)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("bundle_dir")
    parser.add_argument("output_dir")
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--load-timeout-ms", type=int, default=60_000)
    args = parser.parse_args()

    bundle_dir = Path(args.bundle_dir).resolve()
    output_dir = Path(args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    pck_files = list(bundle_dir.glob("*.pck"))
    wasm_files = list(bundle_dir.glob("*.wasm"))
    if len(pck_files) != 1 or len(wasm_files) != 1:
        raise RuntimeError("expected exactly one fingerprinted PCK and WASM")
    pck_file = pck_files[0]
    wasm_file = wasm_files[0]
    pck_bytes = pck_file.read_bytes()
    pck_sha256 = sha256(pck_file)

    handler = functools.partial(BundleRequestHandler, directory=str(bundle_dir))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    base_url = f"http://127.0.0.1:{server.server_port}"
    started_at = time.monotonic()
    responses: list[dict[str, object]] = []
    finished_requests_ms: dict[str, int] = {}
    console_errors: list[str] = []
    page_errors: list[str] = []
    request_failures: list[dict[str, object]] = []

    try:
        with sync_playwright() as playwright:
            browser = playwright.chromium.launch(
                headless=True,
                executable_path="/usr/bin/google-chrome",
                args=[
                    "--enable-unsafe-swiftshader",
                    "--use-angle=swiftshader",
                    "--use-gl=angle",
                    "--enable-webgl",
                    "--ignore-gpu-blocklist",
                ],
            )
            context = browser.new_context(viewport=VIEWPORT, has_touch=True)
            context.add_init_script(VIBRATION_SPY)
            page = context.new_page()
            page.on(
                "console",
                lambda message: console_errors.append(message.text)
                if message.type == "error"
                else None,
            )
            page.on("pageerror", lambda error: page_errors.append(str(error)))
            page.on(
                "requestfailed",
                lambda request: request_failures.append(
                    {"url": request.url, "failure": request.failure}
                ),
            )
            page.on(
                "requestfinished",
                lambda request: finished_requests_ms.__setitem__(
                    request.url, round((time.monotonic() - started_at) * 1000)
                ),
            )

            def remember_response(response) -> None:
                suffix = Path(response.url.split("?", 1)[0]).suffix.lower()
                if suffix in IMPORTANT_SUFFIXES:
                    responses.append(
                        {
                            "url": response.url,
                            "status": response.status,
                            "ok": response.ok,
                            "content_type": response.headers.get("content-type", ""),
                            "content_length": response.headers.get("content-length", ""),
                            "cache_control": response.headers.get("cache-control", ""),
                            "accept_ranges": response.headers.get("accept-ranges", ""),
                            "coop": response.headers.get("cross-origin-opener-policy", ""),
                            "coep": response.headers.get("cross-origin-embedder-policy", ""),
                        }
                    )

            page.on("response", remember_response)
            page.goto(
                f"{base_url}/index.html?release=clean-{args.source_commit[:12]}",
                wait_until="domcontentloaded",
                timeout=args.load_timeout_ms,
            )
            wait_ready(page, args.load_timeout_ms)
            secure_context = page.evaluate("window.isSecureContext")
            cross_origin_isolated = page.evaluate("window.crossOriginIsolated")
            user_agent = page.evaluate("navigator.userAgent")
            home_state = current_state(page)
            entry_state = open_tripeaks(page)
            page.wait_for_timeout(450)
            page.screenshot(path=str(output_dir / "00-opening-stable.png"), full_page=True)

            # Real mouse stock draw.
            box = canvas_box(page)
            page.evaluate("window.__vibrateCalls = []")
            page.mouse.click(*point(box, 157, 735))
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.moves === 1 && "
                "window.__gameAcceptance.getState().state.stock.length === 22 && "
                "window.__gameAcceptance.getState().state.waste.length === 2",
                timeout=5_000,
            )
            mouse_draw = current_state(page)
            mouse_draw_haptics = page.evaluate("window.__vibrateCalls.slice()")
            page.screenshot(path=str(output_dir / "10-mouse-stock.png"), full_page=True)

            # Strict product recovery after a real action.
            reload_state = reload_and_open(page, args.load_timeout_ms)
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.recovered === true && "
                "window.__gameAcceptance.getState().state.moves === 1 && "
                "window.__gameAcceptance.getState().state.stock.length === 22",
                timeout=5_000,
            )
            reload_state = current_state(page)
            page.screenshot(path=str(output_dir / "11-reload-recovered.png"), full_page=True)

            # Keyboard and touch stock parity from the same deterministic restart.
            keyboard_restart = reset_with_key(page)
            page.keyboard.press("KeyM")
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.moves === 1", timeout=5_000
            )
            keyboard_draw = current_state(page)
            reset_with_key(page)
            box = canvas_box(page)
            page.touchscreen.tap(*point(box, 157, 735))
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.moves === 1", timeout=5_000
            )
            touch_draw = current_state(page)

            # Strict legal fixture: slot 18 is adjacent and reveals exact slot 9.
            legal_fixture = fixture(
                entry_state["state"],
                {
                    0: card_id(12, 3),
                    3: card_id(11, 2),
                    9: card_id(7, 1),
                    18: card_id(6, 0),
                },
                card_id(5, 2),
                [card_id(2, 3)],
                streak=2,
            )
            write_snapshot(page, legal_fixture)
            legal_entry = reload_and_open(page, args.load_timeout_ms)
            box = canvas_box(page)
            page.evaluate("window.__vibrateCalls = []")
            page.mouse.click(*point(box, 49, 472))
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.tableau[18] === -1 && "
                "window.__gameAcceptance.getState().state.streak === 3 && "
                "window.__gameAcceptance.getState().state.exposed_slots.includes(9)",
                timeout=5_000,
            )
            legal_mouse = current_state(page)
            legal_mouse_haptics = page.evaluate("window.__vibrateCalls.slice()")
            page.wait_for_timeout(180)
            page.screenshot(path=str(output_dir / "20-mouse-legal-reveal.png"), full_page=True)

            write_snapshot(page, legal_fixture)
            legal_keyboard_entry = reload_and_open(page, args.load_timeout_ms)
            page.keyboard.press("Enter")
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.tableau[18] === -1",
                timeout=5_000,
            )
            legal_keyboard = current_state(page)

            write_snapshot(page, legal_fixture)
            legal_touch_entry = reload_and_open(page, args.load_timeout_ms)
            box = canvas_box(page)
            page.touchscreen.tap(*point(box, 49, 472))
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.tableau[18] === -1",
                timeout=5_000,
            )
            legal_touch = current_state(page)

            # Rank and locked rejection use real pointer/touch and remain atomic.
            reject_fixture = fixture(
                entry_state["state"],
                {
                    0: card_id(12, 3),
                    3: card_id(11, 2),
                    9: card_id(10, 1),
                    18: card_id(9, 0),
                },
                card_id(5, 2),
                [card_id(2, 3)],
                streak=3,
            )
            write_snapshot(page, reject_fixture)
            rank_entry = reload_and_open(page, args.load_timeout_ms)
            rank_before = model_summary(rank_entry)
            box = canvas_box(page)
            page.evaluate("window.__vibrateCalls = []")
            page.mouse.click(*point(box, 49, 472))
            page.wait_for_timeout(220)
            rank_after_state = current_state(page)
            rank_after = model_summary(rank_after_state)
            rank_haptics = page.evaluate("window.__vibrateCalls.slice()")
            page.screenshot(path=str(output_dir / "30-mouse-rank-reject.png"), full_page=True)

            write_snapshot(page, reject_fixture)
            locked_entry = reload_and_open(page, args.load_timeout_ms)
            locked_before = model_summary(locked_entry)
            box = canvas_box(page)
            page.evaluate("window.__vibrateCalls = []")
            page.touchscreen.tap(*point(box, 122.5, 262))
            page.wait_for_timeout(220)
            locked_after_state = current_state(page)
            locked_after = model_summary(locked_after_state)
            locked_haptics = page.evaluate("window.__vibrateCalls.slice()")
            page.screenshot(path=str(output_dir / "31-touch-locked-reject.png"), full_page=True)

            # Real restart button resets the deterministic deal and recovery flag.
            box = canvas_box(page)
            page.mouse.click(*point(box, 486, 48))
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.moves === 0 && "
                "window.__gameAcceptance.getState().state.stock.length === 23 && "
                "window.__gameAcceptance.getState().state.waste.length === 1 && "
                "window.__gameAcceptance.getState().state.recovered === false",
                timeout=5_000,
            )
            pointer_restart = current_state(page)
            page.screenshot(path=str(output_dir / "40-pointer-restart.png"), full_page=True)

            pck_url = f"{base_url}/{pck_file.name}"
            range_probe = page.evaluate(
                """async url => {
                    const response = await fetch(url, {cache: 'no-store', headers: {Range: 'bytes=0-1023'}});
                    const payload = await response.arrayBuffer();
                    return {
                        status: response.status,
                        bytes: payload.byteLength,
                        content_range: response.headers.get('content-range'),
                        accept_ranges: response.headers.get('accept-ranges'),
                        coop: response.headers.get('cross-origin-opener-policy'),
                        coep: response.headers.get('cross-origin-embedder-policy'),
                    };
                }""",
                pck_url,
            )
            full_transfer_probe = page.evaluate(
                """async url => {
                    const response = await fetch(url, {cache: 'no-store'});
                    const payload = await response.arrayBuffer();
                    const digest = await crypto.subtle.digest('SHA-256', payload);
                    const hash = [...new Uint8Array(digest)].map(value => value.toString(16).padStart(2, '0')).join('');
                    return {
                        status: response.status,
                        bytes: payload.byteLength,
                        sha256: hash,
                        content_length: response.headers.get('content-length'),
                        accept_ranges: response.headers.get('accept-ranges'),
                    };
                }""",
                pck_url,
            )

            reduced_context = browser.new_context(
                viewport=VIEWPORT, has_touch=True, reduced_motion="reduce"
            )
            reduced_context.add_init_script(VIBRATION_SPY)
            reduced_page = reduced_context.new_page()
            reduced_page.goto(
                f"{base_url}/index.html?release=reduced-{args.source_commit[:12]}",
                wait_until="domcontentloaded",
                timeout=args.load_timeout_ms,
            )
            wait_ready(reduced_page, args.load_timeout_ms)
            reduced_initial = open_tripeaks(reduced_page)
            reduced_fixture = fixture(
                reduced_initial["state"],
                {
                    0: card_id(12, 3),
                    3: card_id(11, 2),
                    9: card_id(7, 1),
                    18: card_id(6, 0),
                },
                card_id(5, 2),
                [card_id(2, 3)],
                streak=2,
            )
            write_snapshot(reduced_page, reduced_fixture)
            reduced_entry = reload_and_open(reduced_page, args.load_timeout_ms)
            reduced_box = canvas_box(reduced_page)
            reduced_page.evaluate("window.__vibrateCalls = []")
            reduced_page.touchscreen.tap(*point(reduced_box, 49, 472))
            reduced_page.wait_for_function(
                "window.__gameAcceptance.getState().state.tableau[18] === -1",
                timeout=5_000,
            )
            reduced_after = current_state(reduced_page)
            reduced_haptics = reduced_page.evaluate("window.__vibrateCalls.slice()")
            reduced_page.wait_for_timeout(180)
            reduced_page.screenshot(path=str(output_dir / "50-reduced-legal.png"), full_page=True)
            reduced_context.close()

            context.close()
            browser.close()

        pck_responses = [
            details for details in responses if str(details["url"]).split("?", 1)[0].endswith(".pck")
        ]
        wasm_responses = [
            details for details in responses if str(details["url"]).split("?", 1)[0].endswith(".wasm")
        ]
        initial_bundle_responses = [
            details for details in responses
            if details["status"] == 200
            and Path(str(details["url"]).split("?", 1)[0]).suffix.lower() in IMPORTANT_SUFFIXES
        ]
        fresh_model = model_summary(entry_state)
        checks = {
            "secure_context": secure_context is True,
            "cross_origin_isolated": cross_origin_isolated is True,
            "ready_and_catalog_14": home_state.get("ready") is True
            and home_state.get("catalog_size") == 14,
            "tripeaks_entry_52_card_partition": entry_state.get("game_id") == "tripeaks"
            and len(fresh_model["tableau"]) == 28
            and len(fresh_model["stock"]) == 23
            and len(fresh_model["waste"]) == 1
            and len({card for card in fresh_model["tableau"] + fresh_model["stock"] + fresh_model["waste"]}) == 52,
            "real_mouse_stock": len(mouse_draw["state"]["stock"]) == 22
            and len(mouse_draw["state"]["waste"]) == 2
            and mouse_draw["state"]["moves"] == 1,
            "mouse_stock_haptic_route": len(mouse_draw_haptics) > 0,
            "strict_reload_recovery": reload_state["state"].get("recovered") is True
            and model_summary(reload_state) == model_summary(mouse_draw),
            "keyboard_restart_fresh": keyboard_restart["state"].get("recovered") is False
            and keyboard_restart["state"].get("moves") == 0,
            "stock_mouse_touch_keyboard_parity": model_summary(mouse_draw)
            == model_summary(keyboard_draw)
            == model_summary(touch_draw),
            "strict_legal_fixture_recovered": legal_entry["state"].get("recovered") is True
            and legal_keyboard_entry["state"].get("recovered") is True
            and legal_touch_entry["state"].get("recovered") is True,
            "real_legal_clear_and_reveal": legal_mouse["state"]["tableau"][18] == -1
            and legal_mouse["state"]["waste"][-1] == card_id(6, 0)
            and 9 in legal_mouse["state"]["exposed_slots"]
            and legal_mouse["state"]["streak"] == 3
            and legal_mouse["state"]["score"] == legal_entry["state"]["score"] + 30,
            "legal_mouse_touch_keyboard_parity": model_summary(legal_mouse)
            == model_summary(legal_keyboard)
            == model_summary(legal_touch),
            "legal_haptic_route": len(legal_mouse_haptics) > 0,
            "rank_reject_atomic": rank_before == rank_after and len(rank_haptics) > 0,
            "locked_reject_atomic_touch": locked_before == locked_after
            and len(locked_haptics) > 0,
            "real_pointer_restart": model_summary(pointer_restart) == fresh_model
            and pointer_restart["state"].get("recovered") is False,
            "reduced_effects_detected": reduced_entry["state"].get("reduced_effects") is True
            and reduced_after["state"].get("reduced_effects") is True,
            "reduced_rules_identical": model_summary(reduced_after)
            == model_summary(legal_mouse),
            "reduced_haptic_suppressed": reduced_haptics == [],
            "pck_contains_runtime_gag_paths": CARD_BACK_PATH in pck_bytes
            and STREAK_SFX_PATH in pck_bytes,
            "pck_loaded": any(details["status"] == 200 and details["ok"] for details in pck_responses),
            "wasm_loaded": any(details["status"] == 200 and details["ok"] for details in wasm_responses),
            "headers_complete": bool(initial_bundle_responses)
            and all(
                details["content_length"]
                and details["accept_ranges"] == "bytes"
                and details["coop"] == "same-origin"
                and details["coep"] == "require-corp"
                for details in initial_bundle_responses
            ),
            "browser_range_transfer": range_probe.get("status") == 206
            and range_probe.get("bytes") == 1024
            and str(range_probe.get("content_range", "")).startswith("bytes 0-1023/"),
            "browser_full_pck_transfer": full_transfer_probe.get("status") == 200
            and full_transfer_probe.get("bytes") == pck_file.stat().st_size
            and full_transfer_probe.get("sha256") == pck_sha256,
            "runtime_errors_clear": not console_errors
            and not page_errors
            and not request_failures,
        }
        report = {
            "schema": "offline-games.tripeaks-fidelity-v3.web-acceptance.v1",
            "observed_at_unix": int(time.time()),
            "source_commit": args.source_commit,
            "base_url": base_url,
            "browser": "Google Chrome headless / SwiftShader WebGL2",
            "user_agent": user_agent,
            "viewport": [540, 960],
            "checks": checks,
            "result": "PASS" if all(checks.values()) else "FAIL",
            "bundle": {
                "pck": {"name": pck_file.name, "bytes": pck_file.stat().st_size, "sha256": pck_sha256},
                "wasm": {"name": wasm_file.name, "bytes": wasm_file.stat().st_size, "sha256": sha256(wasm_file)},
            },
            "bundle_responses": responses,
            "finished_requests_ms": finished_requests_ms,
            "range_probe": range_probe,
            "full_transfer_probe": full_transfer_probe,
            "actions": {
                "entry": summarize(entry_state),
                "mouse_stock": summarize(mouse_draw),
                "mouse_stock_haptics": mouse_draw_haptics,
                "reload_recovery": summarize(reload_state),
                "keyboard_restart": summarize(keyboard_restart),
                "keyboard_stock": summarize(keyboard_draw),
                "touch_stock": summarize(touch_draw),
                "fixture_boundary": "Complete strict tripeaks-state/v3 snapshots are injected only through the product localStorage recovery boundary; Chrome then performs real mouse, touch and keyboard actions.",
                "legal_entry": summarize(legal_entry),
                "legal_mouse": summarize(legal_mouse),
                "legal_mouse_haptics": legal_mouse_haptics,
                "legal_keyboard": summarize(legal_keyboard),
                "legal_touch": summarize(legal_touch),
                "rank_entry": summarize(rank_entry),
                "rank_after": summarize(rank_after_state),
                "rank_haptics": rank_haptics,
                "locked_entry": summarize(locked_entry),
                "locked_after": summarize(locked_after_state),
                "locked_haptics": locked_haptics,
                "pointer_restart": summarize(pointer_restart),
                "reduced_entry": summarize(reduced_entry),
                "reduced_after": summarize(reduced_after),
                "reduced_haptics": reduced_haptics,
            },
            "console_errors": console_errors,
            "page_errors": page_errors,
            "request_failures": request_failures,
        }
        report_path = output_dir / "web-acceptance.json"
        report_path.write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        print(f"TRIPEAKS_V3_WEB_ACCEPTANCE={report['result']}")
        print(f"TRIPEAKS_V3_WEB_REPORT={report_path}")
        return 0 if report["result"] == "PASS" else 1
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)


if __name__ == "__main__":
    raise SystemExit(main())
