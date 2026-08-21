#!/usr/bin/env python3
"""Real-browser Solitaire v3 acceptance against one clean fingerprinted bundle."""

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


SNAPSHOT_KEY = "offline-games-solitaire-v3"
VIEWPORT = {"width": 540, "height": 960}
IMPORTANT_SUFFIXES = {".html", ".js", ".wasm", ".pck"}
CARD_BACK_PATH = b"assets/art/cards/solitaire_card_back_gag_v1.webp"
SETTLE_SFX_PATH = b"assets/audio/cards/solitaire_card_settle_gag_v1.ogg"
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
    """Static handler with isolation, immutable fingerprints and byte ranges."""

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


def summarize(snapshot: dict) -> dict:
    state = snapshot.get("state", {})
    tableau = state.get("tableau", [])
    foundations = state.get("foundations", [])
    return {
        "screen": snapshot.get("screen"),
        "game_id": snapshot.get("game_id"),
        "status": state.get("status"),
        "stock_count": len(state.get("stock", [])),
        "waste_count": len(state.get("waste", [])),
        "waste_top": state.get("waste", [None])[-1] if state.get("waste") else None,
        "tableau": [
            [{"card": entry.get("card"), "face_up": entry.get("face_up")} for entry in pile]
            for pile in tableau
        ],
        "foundation_counts": [len(pile) for pile in foundations],
        "foundation_total": state.get("foundation_total"),
        "score": state.get("score"),
        "moves": state.get("moves"),
        "recycles_used": state.get("recycles_used"),
        "selection": state.get("selection"),
        "recovered": state.get("recovered"),
        "reduced_effects": state.get("reduced_effects"),
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


def open_solitaire(page) -> dict:
    box = canvas_box(page)
    # Catalog index seven: right card, fourth row.
    page.mouse.click(*point(box, 399, 657))
    page.wait_for_function(
        "window.__gameAcceptance.getState().game_id === 'solitaire'",
        timeout=10_000,
    )
    page.wait_for_timeout(160)
    return current_state(page)


def reload_and_open(page, timeout_ms: int) -> dict:
    page.reload(wait_until="domcontentloaded", timeout=timeout_ms)
    wait_ready(page, timeout_ms)
    return open_solitaire(page)


def write_snapshot(page, snapshot: dict) -> None:
    payload = json.dumps(snapshot, ensure_ascii=False, separators=(",", ":"))
    page.evaluate(
        "([key, payload]) => window.localStorage.setItem(key, payload)",
        [SNAPSHOT_KEY, payload],
    )


def card_id(rank: int, suit: int) -> int:
    return suit * 13 + rank - 1


def fixture(base_state: dict, piles: list[list[dict]]) -> dict:
    result = copy.deepcopy(base_state)
    used = {int(entry["card"]) for pile in piles for entry in pile}
    result.update(
        {
            "schema": "solitaire-state/v1",
            "game_id": "solitaire",
            "stock": [card for card in range(52) if card not in used],
            "waste": [],
            "tableau": copy.deepcopy(piles) + [[] for _ in range(7 - len(piles))],
            "foundations": [[], [], [], []],
            "foundation_total": 0,
            "score": 0,
            "moves": 0,
            "recycles_used": 0,
            "status": "playing",
            "screen": "game",
        }
    )
    return result


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
    pck_bytes = pck_files[0].read_bytes()

    handler = functools.partial(BundleRequestHandler, directory=str(bundle_dir))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    base_url = f"http://127.0.0.1:{server.server_port}"
    started_at = time.monotonic()
    responses: dict[str, dict[str, object]] = {}
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
            context = browser.new_context(viewport=VIEWPORT)
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
                    responses[response.url] = {
                        "status": response.status,
                        "ok": response.ok,
                        "content_type": response.headers.get("content-type", ""),
                        "content_length": response.headers.get("content-length", ""),
                        "cache_control": response.headers.get("cache-control", ""),
                        "accept_ranges": response.headers.get("accept-ranges", ""),
                        "coop": response.headers.get("cross-origin-opener-policy", ""),
                        "coep": response.headers.get("cross-origin-embedder-policy", ""),
                    }

            page.on("response", remember_response)
            page.goto(
                f"{base_url}/index.html?release=clean-{args.source_commit[:12]}",
                wait_until="domcontentloaded",
                timeout=args.load_timeout_ms,
            )
            wait_ready(page, args.load_timeout_ms)
            secure_context = page.evaluate("window.isSecureContext")
            home_state = current_state(page)
            entry_state = open_solitaire(page)
            page.wait_for_timeout(450)
            page.screenshot(path=str(output_dir / "00-opening-stable.png"), full_page=True)

            box = canvas_box(page)
            page.evaluate("window.__vibrateCalls = []")
            page.mouse.click(*point(box, 74, 306))
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.moves === 1 && "
                "window.__gameAcceptance.getState().state.stock.length === 23 && "
                "window.__gameAcceptance.getState().state.waste.length === 1",
                timeout=5_000,
            )
            page.wait_for_timeout(180)
            draw_state = current_state(page)
            draw_vibrate_calls = page.evaluate("window.__vibrateCalls.slice()")
            page.screenshot(path=str(output_dir / "10-real-draw.png"), full_page=True)

            reload_state = reload_and_open(page, args.load_timeout_ms)
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.recovered === true && "
                "window.__gameAcceptance.getState().state.moves === 1 && "
                "window.__gameAcceptance.getState().state.stock.length === 23 && "
                "window.__gameAcceptance.getState().state.waste.length === 1",
                timeout=5_000,
            )
            reload_state = current_state(page)
            page.screenshot(path=str(output_dir / "11-reload-recovered.png"), full_page=True)

            legal_fixture = fixture(
                reload_state["state"],
                [
                    [{"card": card_id(9, 3), "face_up": True}],
                    [{"card": card_id(10, 2), "face_up": True}],
                ],
            )
            write_snapshot(page, legal_fixture)
            legal_entry = reload_and_open(page, args.load_timeout_ms)
            box = canvas_box(page)
            page.evaluate("window.__vibrateCalls = []")
            page.mouse.click(*point(box, 63, 448))
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.selection.kind === 'tableau' && "
                "window.__gameAcceptance.getState().state.selection.column === 0",
                timeout=5_000,
            )
            page.mouse.click(*point(box, 131, 448))
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.moves === 1 && "
                "window.__gameAcceptance.getState().state.score === 5 && "
                "window.__gameAcceptance.getState().state.tableau[0].length === 0 && "
                "window.__gameAcceptance.getState().state.tableau[1].length === 2",
                timeout=5_000,
            )
            page.wait_for_timeout(180)
            legal_after = current_state(page)
            legal_vibrate_calls = page.evaluate("window.__vibrateCalls.slice()")
            page.screenshot(path=str(output_dir / "20-real-legal-move.png"), full_page=True)

            reject_fixture = fixture(
                legal_after["state"],
                [
                    [{"card": card_id(9, 2), "face_up": True}],
                    [{"card": card_id(10, 0), "face_up": True}],
                ],
            )
            write_snapshot(page, reject_fixture)
            reject_entry = reload_and_open(page, args.load_timeout_ms)
            box = canvas_box(page)
            page.evaluate("window.__vibrateCalls = []")
            page.mouse.click(*point(box, 63, 448))
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.selection.kind === 'tableau'",
                timeout=5_000,
            )
            page.mouse.click(*point(box, 131, 448))
            page.wait_for_timeout(180)
            reject_after = current_state(page)
            reject_vibrate_calls = page.evaluate("window.__vibrateCalls.slice()")
            page.screenshot(path=str(output_dir / "30-real-reject.png"), full_page=True)

            page.keyboard.press("KeyR")
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.moves === 0 && "
                "window.__gameAcceptance.getState().state.stock.length === 24 && "
                "window.__gameAcceptance.getState().state.waste.length === 0 && "
                "window.__gameAcceptance.getState().state.recovered === false",
                timeout=5_000,
            )
            restart_state = current_state(page)
            restart_snapshot_present = page.evaluate(
                "key => window.localStorage.getItem(key) !== null", SNAPSHOT_KEY
            )
            page.screenshot(path=str(output_dir / "40-real-restart.png"), full_page=True)

            pck_url = f"{base_url}/{pck_files[0].name}"
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

            reduced_context = browser.new_context(viewport=VIEWPORT, reduced_motion="reduce")
            reduced_context.add_init_script(VIBRATION_SPY)
            reduced_page = reduced_context.new_page()
            reduced_page.goto(
                f"{base_url}/index.html?release=reduced-{args.source_commit[:12]}",
                wait_until="domcontentloaded",
                timeout=args.load_timeout_ms,
            )
            wait_ready(reduced_page, args.load_timeout_ms)
            reduced_entry = open_solitaire(reduced_page)
            reduced_box = canvas_box(reduced_page)
            reduced_page.evaluate("window.__vibrateCalls = []")
            reduced_page.mouse.click(*point(reduced_box, 74, 306))
            reduced_page.wait_for_function(
                "window.__gameAcceptance.getState().state.moves === 1",
                timeout=5_000,
            )
            reduced_after = current_state(reduced_page)
            reduced_vibrate_calls = reduced_page.evaluate("window.__vibrateCalls.slice()")
            reduced_page.screenshot(path=str(output_dir / "50-reduced-draw.png"), full_page=True)
            reduced_context.close()

            context.close()
            browser.close()

        pck_responses = {
            url: details
            for url, details in responses.items()
            if url.split("?", 1)[0].endswith(".pck")
        }
        wasm_responses = {
            url: details
            for url, details in responses.items()
            if url.split("?", 1)[0].endswith(".wasm")
        }
        main_bundle_headers = list(responses.values())
        reject_before_summary = summarize(reject_entry)
        reject_after_summary = summarize(reject_after)
        checks = {
            "secure_context": secure_context is True,
            "ready_and_catalog_14": home_state.get("ready") is True
            and home_state.get("catalog_size") == 14,
            "solitaire_entry": entry_state.get("game_id") == "solitaire"
            and entry_state["state"].get("status") == "playing"
            and len(entry_state["state"].get("stock", [])) == 24,
            "real_mouse_draw": len(draw_state["state"].get("stock", [])) == 23
            and len(draw_state["state"].get("waste", [])) == 1
            and draw_state["state"].get("moves") == 1,
            "normal_draw_haptic_route_called": len(draw_vibrate_calls) > 0,
            "reload_recovery": reload_state["state"].get("recovered") is True
            and reload_state["state"].get("moves") == 1
            and reload_state["state"].get("waste") == draw_state["state"].get("waste"),
            "legal_fixture_recovered": legal_entry["state"].get("recovered") is True,
            "real_legal_stack_move": legal_after["state"].get("moves") == 1
            and legal_after["state"].get("score") == 5
            and legal_after["state"].get("tableau", [[], []])[0] == []
            and len(legal_after["state"].get("tableau", [[], []])[1]) == 2,
            "legal_move_haptic_route_called": len(legal_vibrate_calls) > 0,
            "reject_fixture_recovered": reject_entry["state"].get("recovered") is True,
            "real_legal_reject_atomic": reject_before_summary["moves"] == reject_after_summary["moves"] == 0
            and reject_before_summary["score"] == reject_after_summary["score"] == 0
            and reject_before_summary["tableau"] == reject_after_summary["tableau"],
            "reject_haptic_route_called": len(reject_vibrate_calls) > 0,
            "real_keyboard_restart": restart_state["state"].get("moves") == 0
            and len(restart_state["state"].get("stock", [])) == 24
            and restart_state["state"].get("waste") == []
            and restart_state["state"].get("recovered") is False,
            "restart_snapshot_written": restart_snapshot_present is True,
            "reduced_effects_detected": reduced_entry["state"].get("reduced_effects") is True
            and reduced_after["state"].get("reduced_effects") is True,
            "reduced_draw_rules_identical": len(reduced_after["state"].get("stock", [])) == 23
            and len(reduced_after["state"].get("waste", [])) == 1
            and reduced_after["state"].get("moves") == 1,
            "reduced_haptic_suppressed": reduced_vibrate_calls == [],
            "pck_contains_runtime_gag_paths": CARD_BACK_PATH in pck_bytes
            and SETTLE_SFX_PATH in pck_bytes,
            "pck_loaded": bool(pck_responses)
            and all(details["ok"] for details in pck_responses.values()),
            "wasm_loaded": bool(wasm_responses)
            and all(details["ok"] for details in wasm_responses.values()),
            "headers_complete": bool(main_bundle_headers)
            and all(
                details["content_length"]
                and details["accept_ranges"] == "bytes"
                and details["coop"] == "same-origin"
                and details["coep"] == "require-corp"
                for details in main_bundle_headers
            ),
            "browser_range_transfer": range_probe.get("status") == 206
            and range_probe.get("bytes") == 1024
            and str(range_probe.get("content_range", "")).startswith("bytes 0-1023/"),
            "runtime_errors_clear": not console_errors
            and not page_errors
            and not request_failures,
        }
        report = {
            "schema": "offline-games.solitaire-fidelity-v3.web-acceptance.v1",
            "observed_at_unix": int(time.time()),
            "source_commit": args.source_commit,
            "base_url": base_url,
            "browser": "Google Chrome headless / SwiftShader WebGL2",
            "viewport": [540, 960],
            "checks": checks,
            "result": "PASS" if all(checks.values()) else "FAIL",
            "bundle": {
                "pck": {
                    "name": pck_files[0].name,
                    "bytes": pck_files[0].stat().st_size,
                    "sha256": sha256(pck_files[0]),
                },
                "wasm": {
                    "name": wasm_files[0].name,
                    "bytes": wasm_files[0].stat().st_size,
                    "sha256": sha256(wasm_files[0]),
                },
            },
            "bundle_responses": responses,
            "finished_requests_ms": finished_requests_ms,
            "range_probe": range_probe,
            "actions": {
                "entry": summarize(entry_state),
                "draw": summarize(draw_state),
                "draw_vibrate_calls": draw_vibrate_calls,
                "reload_recovery": summarize(reload_state),
                "fixture_boundary": "Fixtures are complete strict solitaire-state/v1 snapshots injected only through the product localStorage recovery boundary. The browser still performs real pointer selection, placement/rejection, persistence and keyboard restart.",
                "legal_entry": summarize(legal_entry),
                "legal_after": summarize(legal_after),
                "legal_vibrate_calls": legal_vibrate_calls,
                "reject_entry": reject_before_summary,
                "reject_after": reject_after_summary,
                "reject_vibrate_calls": reject_vibrate_calls,
                "restart": summarize(restart_state),
                "reduced_entry": summarize(reduced_entry),
                "reduced_after": summarize(reduced_after),
                "reduced_vibrate_calls": reduced_vibrate_calls,
            },
            "console_errors": console_errors,
            "page_errors": page_errors,
            "request_failures": request_failures,
        }
        report_path = output_dir / "web-acceptance.json"
        report_path.write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"SOLITAIRE_V3_WEB_ACCEPTANCE={report['result']}")
        print(f"SOLITAIRE_V3_WEB_REPORT={report_path}")
        return 0 if report["result"] == "PASS" else 1
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)


if __name__ == "__main__":
    raise SystemExit(main())
