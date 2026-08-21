#!/usr/bin/env python3
"""Real-browser Snakes v3 acceptance against one local fingerprinted bundle."""

from __future__ import annotations

import argparse
import copy
import functools
import hashlib
import http.server
import json
import math
import mimetypes
import os
import re
import threading
import time
from pathlib import Path
from typing import BinaryIO

from playwright.sync_api import sync_playwright


SNAPSHOT_KEY = "offline-games-snakes-v3"
VIEWPORT = {"width": 540, "height": 960}
IMPORTANT_SUFFIXES = {".html", ".js", ".wasm", ".pck"}
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
    """Static handler with production-relevant isolation and byte-range headers."""

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
    player = state.get("player", {})
    snakes = state.get("snakes", [])
    return {
        "screen": snapshot.get("screen"),
        "game_id": snapshot.get("game_id"),
        "status": state.get("status"),
        "phase": state.get("phase"),
        "terminal_reason": state.get("terminal_reason"),
        "tick": state.get("tick"),
        "mass": state.get("mass"),
        "rank": state.get("rank"),
        "recovered": state.get("recovered"),
        "reduced_effects": state.get("reduced_effects"),
        "pellet_count": len(state.get("pellets", [])),
        "snake_count": len(snakes),
        "live_snake_count": sum(1 for snake in snakes if snake.get("alive")),
        "player": {
            "alive": player.get("alive"),
            "position": player.get("position"),
            "heading": player.get("heading"),
            "mass": player.get("mass"),
            "boosting": player.get("boosting"),
        },
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


def open_snakes(page) -> dict:
    box = canvas_box(page)
    # Catalog index six: left card, fourth row.
    page.mouse.click(*point(box, 141, 657))
    page.wait_for_function(
        "window.__gameAcceptance.getState().game_id === 'snake_io'",
        timeout=10_000,
    )
    page.wait_for_timeout(160)
    return current_state(page)


def reload_and_open(page, timeout_ms: int) -> dict:
    page.reload(wait_until="domcontentloaded", timeout=timeout_ms)
    wait_ready(page, timeout_ms)
    return open_snakes(page)


def write_snapshot(page, snapshot: dict) -> None:
    payload = json.dumps(snapshot, ensure_ascii=False, separators=(",", ":"))
    page.evaluate(
        "([key, payload]) => window.localStorage.setItem(key, payload)",
        [SNAPSHOT_KEY, payload],
    )


def snapshot_payload(state: dict) -> dict:
    payload = copy.deepcopy(state)
    payload["game_id"] = "snake_io"
    payload["screen"] = "game"
    payload["shell_tick"] = int(payload.get("shell_tick", payload.get("tick", 0)))
    return payload


def collect_fixture(state: dict) -> dict:
    fixture = snapshot_payload(state)
    player = fixture["snakes"][0]
    x, y = player["position"]
    heading = float(player["heading"])
    pellet_id = max(10_001, int(fixture.get("next_pellet_id", 1)))
    fixture["pellets"] = [
        {
            "id": pellet_id,
            "position": [x + math.cos(heading) * 34.0, y + math.sin(heading) * 34.0],
            "value": 4.5,
            "palette": 1,
            "source": "ambient",
            "born_at": float(fixture["elapsed"]),
        }
    ]
    fixture["target_pellet_count"] = 1
    fixture["next_pellet_id"] = pellet_id + 1
    fixture["player"] = copy.deepcopy(player)
    fixture["mass"] = float(player["mass"])
    return fixture


def isolated_action_fixture(state: dict) -> dict:
    fixture = snapshot_payload(state)
    for snake in fixture["snakes"]:
        snake["invulnerable"] = 10.0
        snake["boost_requested"] = False
        snake["boosting"] = False
        snake["boost_shed_clock"] = 0.0
        snake["state"] = "relaxed"
        if snake.get("is_bot"):
            snake["speed_scale"] = 0.0
            snake["desired_point"] = list(snake["position"])
    fixture["player"] = copy.deepcopy(fixture["snakes"][0])
    fixture["mass"] = float(fixture["player"]["mass"])
    fixture["player_boost_requested"] = False
    fixture["pellets"] = []
    fixture["target_pellet_count"] = 0
    return fixture


def boundary_death_fixture(state: dict) -> dict:
    fixture = snapshot_payload(state)
    arena_radius = float(fixture.get("arena_radius", 920.0))
    player = fixture["snakes"][0]
    position_x = arena_radius - 25.0
    segment_count = len(player["segments"])
    player.update(
        {
            "position": [position_x, 0.0],
            "previous_position": [position_x, 0.0],
            "desired_point": [position_x + 300.0, 0.0],
            "heading": 0.0,
            "segments": [[position_x - index * 14.0, 0.0] for index in range(segment_count)],
            "boost_requested": False,
            "boosting": False,
            "boost_shed_clock": 0.0,
            "speed_scale": 1.0,
            "invulnerable": 0.0,
            "state": "relaxed",
        }
    )
    bot_count = max(1, len(fixture["snakes"]) - 1)
    for index, bot in enumerate(fixture["snakes"][1:], start=1):
        angle = (index - 1) / bot_count * math.tau
        x = math.cos(angle) * 520.0
        y = math.sin(angle) * 520.0
        heading = angle + math.pi
        count = len(bot["segments"])
        bot.update(
            {
                "position": [x, y],
                "previous_position": [x, y],
                "desired_point": [x, y],
                "heading": heading,
                "segments": [
                    [x - math.cos(heading) * step * 14.0, y - math.sin(heading) * step * 14.0]
                    for step in range(count)
                ],
                "boost_requested": False,
                "boosting": False,
                "boost_shed_clock": 0.0,
                "speed_scale": 0.0,
                "invulnerable": 10.0,
                "state": "relaxed",
            }
        )
    fixture["player"] = copy.deepcopy(player)
    fixture["mass"] = float(player["mass"])
    fixture["player_aim"] = [position_x + 400.0, 0.0]
    fixture["player_boost_requested"] = False
    fixture["pellets"] = []
    fixture["target_pellet_count"] = 0
    return fixture


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("bundle_dir")
    parser.add_argument("output_dir")
    parser.add_argument("--load-timeout-ms", type=int, default=60_000)
    args = parser.parse_args()

    bundle_dir = Path(args.bundle_dir).resolve()
    output_dir = Path(args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    pck_files = list(bundle_dir.glob("*.pck"))
    wasm_files = list(bundle_dir.glob("*.wasm"))
    if len(pck_files) != 1 or len(wasm_files) != 1:
        raise RuntimeError("expected exactly one fingerprinted PCK and WASM")

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
            page.goto(f"{base_url}/index.html?release=clean-4fa7bd1", wait_until="domcontentloaded", timeout=args.load_timeout_ms)
            wait_ready(page, args.load_timeout_ms)
            secure_context = page.evaluate("window.isSecureContext")
            home_state = current_state(page)
            entry_state = open_snakes(page)
            page.wait_for_timeout(450)
            page.screenshot(path=str(output_dir / "00-stable.png"), full_page=True)

            page.keyboard.press("KeyR")
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.status === 'playing' && "
                "Math.abs(window.__gameAcceptance.getState().state.mass - 38) < 0.01 && "
                "window.__gameAcceptance.getState().state.recovered === false",
                timeout=5_000,
            )
            write_snapshot(page, isolated_action_fixture(current_state(page)["state"]))
            action_entry = reload_and_open(page, args.load_timeout_ms)
            box = canvas_box(page)
            steer_before = current_state(page)
            page.mouse.move(*point(box, 270, 493))
            page.mouse.down()
            page.mouse.move(*point(box, 270, 286))
            page.wait_for_function(
                "before => window.__gameAcceptance.getState().state.status === 'playing' && "
                "Math.abs(window.__gameAcceptance.getState().state.player.heading - before) > 0.08",
                arg=float(steer_before["state"]["player"]["heading"]),
                timeout=5_000,
            )
            steer_during = current_state(page)
            page.mouse.up()
            page.wait_for_timeout(40)
            steer_after = current_state(page)
            page.screenshot(path=str(output_dir / "10-steer.png"), full_page=True)

            page.keyboard.press("KeyR")
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.status === 'playing' && "
                "Math.abs(window.__gameAcceptance.getState().state.mass - 38) < 0.01",
                timeout=5_000,
            )
            write_snapshot(page, isolated_action_fixture(current_state(page)["state"]))
            boost_action_entry = reload_and_open(page, args.load_timeout_ms)
            boost_before = current_state(page)
            page.evaluate("window.__vibrateCalls = []")
            page.keyboard.down("Shift")
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.player.boosting === true",
                timeout=5_000,
            )
            page.wait_for_timeout(260)
            boost_during = current_state(page)
            normal_vibrate_calls = page.evaluate("window.__vibrateCalls.slice()")
            page.screenshot(path=str(output_dir / "11-boost.png"), full_page=True)
            page.keyboard.up("Shift")
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.player.boosting === false",
                timeout=5_000,
            )
            boost_after = current_state(page)

            page.keyboard.press("KeyR")
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.status === 'playing' && "
                "Math.abs(window.__gameAcceptance.getState().state.mass - 38) < 0.01",
                timeout=5_000,
            )
            fresh_state = current_state(page)
            collect_mass_before = float(fresh_state["state"]["mass"])
            write_snapshot(page, collect_fixture(fresh_state["state"]))
            collect_entry = reload_and_open(page, args.load_timeout_ms)
            page.wait_for_function(
                "before => window.__gameAcceptance.getState().state.mass > before + 4",
                arg=collect_mass_before,
                timeout=5_000,
            )
            collect_after = current_state(page)
            page.screenshot(path=str(output_dir / "20-collect-after-reload.png"), full_page=True)
            persisted_after_collect = page.evaluate(
                "key => JSON.parse(window.localStorage.getItem(key))", SNAPSHOT_KEY
            )
            recovery_state = reload_and_open(page, args.load_timeout_ms)
            page.wait_for_function(
                "before => window.__gameAcceptance.getState().state.recovered === true && "
                "window.__gameAcceptance.getState().state.mass > before + 4",
                arg=collect_mass_before,
                timeout=5_000,
            )
            recovery_state = current_state(page)

            write_snapshot(page, boundary_death_fixture(recovery_state["state"]))
            death_entry = reload_and_open(page, args.load_timeout_ms)
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.status === 'over'",
                timeout=5_000,
            )
            page.wait_for_timeout(780)
            death_state = current_state(page)
            death_snapshot_cleared = page.evaluate(
                "key => window.localStorage.getItem(key) === null", SNAPSHOT_KEY
            )
            page.screenshot(path=str(output_dir / "30-death-terminal.png"), full_page=True)

            page.keyboard.press("KeyR")
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.status === 'playing' && "
                "Math.abs(window.__gameAcceptance.getState().state.mass - 38) < 0.01 && "
                "window.__gameAcceptance.getState().state.recovered === false",
                timeout=5_000,
            )
            restart_state = current_state(page)
            restart_snapshot_present = page.evaluate(
                "key => window.localStorage.getItem(key) !== null", SNAPSHOT_KEY
            )
            restart_reload_state = reload_and_open(page, args.load_timeout_ms)
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.recovered === true",
                timeout=5_000,
            )
            restart_reload_state = current_state(page)
            page.screenshot(path=str(output_dir / "31-restart-reload.png"), full_page=True)

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
            reduced_page.goto(f"{base_url}/index.html?release=reduced-4fa7bd1", wait_until="domcontentloaded", timeout=args.load_timeout_ms)
            wait_ready(reduced_page, args.load_timeout_ms)
            reduced_entry = open_snakes(reduced_page)
            reduced_page.keyboard.down("Shift")
            reduced_page.wait_for_function(
                "window.__gameAcceptance.getState().state.player.boosting === true",
                timeout=5_000,
            )
            reduced_page.wait_for_timeout(260)
            reduced_boost = current_state(reduced_page)
            reduced_vibrate_calls = reduced_page.evaluate("window.__vibrateCalls.slice()")
            reduced_page.keyboard.up("Shift")
            reduced_page.screenshot(path=str(output_dir / "40-reduced-effects.png"), full_page=True)
            reduced_context.close()

            context.close()
            browser.close()

        def player_position(snapshot: dict) -> tuple[float, float]:
            position = snapshot["state"]["player"]["position"]
            return float(position[0]), float(position[1])

        def distance(first: tuple[float, float], second: tuple[float, float]) -> float:
            return math.hypot(second[0] - first[0], second[1] - first[1])

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
        checks = {
            "secure_context": secure_context is True,
            "catalog_14": home_state.get("catalog_size") == 14,
            "snakes_entry": entry_state.get("game_id") == "snake_io" and entry_state["state"].get("status") == "playing",
            "real_pointer_steer": steer_before["state"].get("status") == "playing" and steer_during["state"].get("status") == "playing" and steer_after["state"].get("status") == "playing" and abs(float(steer_during["state"]["player"]["heading"]) - float(steer_before["state"]["player"]["heading"])) > 0.08 and distance(player_position(steer_before), player_position(steer_after)) > 5.0,
            "real_keyboard_boost": boost_before["state"].get("status") == "playing" and boost_during["state"].get("status") == "playing" and boost_after["state"].get("status") == "playing" and boost_during["state"]["player"].get("boosting") is True and boost_after["state"]["player"].get("boosting") is False and float(boost_during["state"]["mass"]) < float(boost_before["state"]["mass"]) and distance(player_position(boost_before), player_position(boost_after)) > 20.0,
            "normal_haptic_route_called": len(normal_vibrate_calls) > 0,
            "fixture_reload_recovered": collect_entry["state"].get("recovered") is True,
            "real_collect_after_reload": float(collect_after["state"]["mass"]) > collect_mass_before + 4.0,
            "collect_persisted": float(persisted_after_collect.get("mass", 0.0)) > collect_mass_before + 4.0,
            "second_reload_preserved_run": recovery_state["state"].get("recovered") is True and float(recovery_state["state"]["mass"]) > collect_mass_before + 4.0,
            "real_boundary_death": death_entry["state"].get("recovered") is True and death_state["state"].get("status") == "over" and death_state["state"].get("terminal_reason") == "boundary",
            "death_clears_snapshot": death_snapshot_cleared is True,
            "real_restart": restart_state["state"].get("status") == "playing" and restart_state["state"].get("recovered") is False and abs(float(restart_state["state"]["mass"]) - 38.0) < 0.01,
            "restart_persisted": restart_snapshot_present is True,
            "restart_reload_recovered": restart_reload_state["state"].get("recovered") is True and abs(float(restart_reload_state["state"]["mass"]) - 38.0) < 0.01,
            "reduced_effects_detected": reduced_entry["state"].get("reduced_effects") is True and reduced_boost["state"].get("reduced_effects") is True,
            "reduced_haptic_suppressed": reduced_vibrate_calls == [],
            "pck_loaded": bool(pck_responses) and all(details["ok"] for details in pck_responses.values()),
            "wasm_loaded": bool(wasm_responses) and all(details["ok"] for details in wasm_responses.values()),
            "headers_complete": bool(main_bundle_headers) and all(details["content_length"] and details["accept_ranges"] == "bytes" and details["coop"] == "same-origin" and details["coep"] == "require-corp" for details in main_bundle_headers),
            "browser_range_transfer": range_probe.get("status") == 206 and range_probe.get("bytes") == 1024 and str(range_probe.get("content_range", "")).startswith("bytes 0-1023/"),
            "runtime_errors_clear": not console_errors and not page_errors and not request_failures,
        }
        report = {
            "schema": "offline-games.snakes-fidelity-v3.web-acceptance.v1",
            "observed_at_unix": int(time.time()),
            "source_commit": "4fa7bd1c8d17dde483a5d98251ea75ff72a1b5d1",
            "base_url": base_url,
            "browser": "Google Chrome headless / SwiftShader WebGL2",
            "viewport": [540, 960],
            "checks": checks,
            "result": "PASS" if all(checks.values()) else "FAIL",
            "bundle": {
                "pck": {"name": pck_files[0].name, "bytes": pck_files[0].stat().st_size, "sha256": sha256(pck_files[0])},
                "wasm": {"name": wasm_files[0].name, "bytes": wasm_files[0].stat().st_size, "sha256": sha256(wasm_files[0])},
            },
            "bundle_responses": responses,
            "finished_requests_ms": finished_requests_ms,
            "range_probe": range_probe,
            "actions": {
                "action_fixture_boundary": "legal live recovery snapshot sets all snakes invulnerable, freezes bots and removes pellets; pointer and keyboard events plus player movement/heading/boost/mass remain runtime-owned",
                "action_entry": summarize(action_entry),
                "steer": {"before": summarize(steer_before), "during": summarize(steer_during), "after": summarize(steer_after)},
                "boost_action_entry": summarize(boost_action_entry),
                "boost": {"before": summarize(boost_before), "during": summarize(boost_during), "after": summarize(boost_after), "vibrate_calls": normal_vibrate_calls},
                "collect_fixture_boundary": "fixture only places one legal ambient pellet 34 world units ahead; actual restore, movement, pickup, growth and persistence are runtime-owned",
                "collect_entry": summarize(collect_entry),
                "collect_after": summarize(collect_after),
                "recovery_after_second_reload": summarize(recovery_state),
                "death_fixture_boundary": "fixture only places a live input-neutral player near the arena edge and isolates bots; actual boundary collision, death, snapshot clearing and terminal are runtime-owned",
                "death_entry": summarize(death_entry),
                "death": summarize(death_state),
                "restart": summarize(restart_state),
                "restart_reload": summarize(restart_reload_state),
                "reduced_entry": summarize(reduced_entry),
                "reduced_boost": summarize(reduced_boost),
                "reduced_vibrate_calls": reduced_vibrate_calls,
            },
            "console_errors": console_errors,
            "page_errors": page_errors,
            "request_failures": request_failures,
        }
        report_path = output_dir / "web-acceptance.json"
        report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"SNAKES_WEB_ACCEPTANCE={report['result']}")
        print(f"SNAKES_WEB_REPORT={report_path}")
        return 0 if report["result"] == "PASS" else 1
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)


if __name__ == "__main__":
    raise SystemExit(main())
