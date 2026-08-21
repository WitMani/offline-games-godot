#!/usr/bin/env python3
"""Real-Chrome acceptance for the fingerprinted Tile Club v3 Web pack."""

from __future__ import annotations

import argparse
import json
import time
from pathlib import Path
from urllib.parse import urljoin, urlparse

from playwright.sync_api import TimeoutError as PlaywrightTimeoutError
from playwright.sync_api import sync_playwright


DESIGN_WIDTH = 540.0
DESIGN_HEIGHT = 960.0
TILECLUB_CARD_CENTER = (141.0, 793.0)
NEXT_LEVEL_CENTER = (270.0, 842.0)
LEVEL_SOLUTIONS = {
    0: [2, 0, 1, 5, 3, 4, 8, 6, 7, 11, 9, 10],
    1: [2, 0, 1, 5, 3, 4, 8, 6, 7, 11, 9, 10, 14, 12, 13, 17, 15, 16],
}
LEVEL_TWO_DISTINCT_TOPS = [2, 5, 8, 11, 14, 17, 20]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("base_url")
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--expected-pck", required=True)
    parser.add_argument("--expected-pck-sha256", required=True)
    parser.add_argument("--expected-pck-bytes", type=int, required=True)
    parser.add_argument("--expected-wasm-sha256", required=True)
    parser.add_argument("--load-timeout-ms", type=int, default=90_000)
    args = parser.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)
    console_errors: list[str] = []
    page_errors: list[str] = []
    request_failures: list[str] = []
    responses: dict[str, dict[str, object]] = {}
    response_objects: dict[str, object] = {}
    bundle_body_hashes: dict[str, dict[str, object]] = {}
    bundle_range_probes: dict[str, dict[str, object]] = {}
    finished_requests_ms: dict[str, int] = {}
    started_at = time.monotonic()

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
        context = browser.new_context(
            viewport={"width": 540, "height": 960}, has_touch=True
        )
        page = context.new_page()
        page.on(
            "console",
            lambda message: console_errors.append(message.text)
            if message.type == "error"
            else None,
        )
        page.on("pageerror", lambda error: page_errors.append(str(error)))
        page.on("requestfailed", lambda request: request_failures.append(request.url))
        page.on(
            "requestfinished",
            lambda request: finished_requests_ms.__setitem__(
                request.url, round((time.monotonic() - started_at) * 1000)
            ),
        )

        def remember_response(response) -> None:
            response_path = urlparse(response.url).path
            suffix = Path(response_path).suffix.lower()
            if suffix not in {".html", ".js", ".wasm", ".pck"} and not response_path.endswith("/"):
                return
            responses[response.url] = {
                "status": response.status,
                "ok": response.ok,
                "content_type": response.headers.get("content-type", ""),
                "content_length": response.headers.get("content-length", ""),
                "accept_ranges": response.headers.get("accept-ranges", ""),
                "cache_control": response.headers.get("cache-control", ""),
                "content_range": response.headers.get("content-range", ""),
                "cross_origin_embedder_policy": response.headers.get(
                    "cross-origin-embedder-policy", ""
                ),
                "cross_origin_opener_policy": response.headers.get(
                    "cross-origin-opener-policy", ""
                ),
            }
            response_objects[response.url] = response

        page.on("response", remember_response)

        def acceptance_state() -> dict[str, object]:
            return page.evaluate("window.__gameAcceptance.getState()")

        def wait_ready(timeout: int | None = None) -> None:
            page.wait_for_function(
                "window.__gameAcceptance && "
                "window.__gameAcceptance.getState().ready === true",
                timeout=timeout or args.load_timeout_ms,
            )

        def canvas_box() -> dict[str, float]:
            box = page.locator("canvas").bounding_box()
            if box is None:
                raise RuntimeError("Godot canvas did not expose a bounding box")
            return box

        def screen_point(x: float, y: float) -> tuple[float, float]:
            box = canvas_box()
            return (
                box["x"] + x / DESIGN_WIDTH * box["width"],
                box["y"] + y / DESIGN_HEIGHT * box["height"],
            )

        def mouse_design_click(x: float, y: float) -> None:
            page.mouse.click(*screen_point(x, y))

        def open_tileclub() -> None:
            mouse_design_click(*TILECLUB_CARD_CENTER)
            page.wait_for_function(
                "window.__gameAcceptance.getState().game_id === 'tileclub'",
                timeout=15_000,
            )
            page.wait_for_timeout(160)

        def tile_center(tile_id: int) -> tuple[float, float]:
            snapshot = acceptance_state()["state"]
            tile = next(
                item for item in snapshot["tiles"] if int(item["id"]) == tile_id
            )
            x0, y0, width, height = [float(value) for value in snapshot["bounds"]]
            scale = min(456.0 / width, 430.0 / height, 108.0)
            return (
                270.0 + (float(tile["x"]) - (x0 + width * 0.5)) * scale,
                441.0 + (float(tile["y"]) - (y0 + height * 0.5)) * scale,
            )

        def wait_moves(expected: int) -> None:
            page.wait_for_function(
                "expected => window.__gameAcceptance.getState().state.moves === expected",
                arg=expected,
                timeout=8_000,
            )

        def mouse_collect(tile_id: int, expected_moves: int) -> None:
            mouse_design_click(*tile_center(tile_id))
            wait_moves(expected_moves)

        def complete_level(level: int) -> dict[str, object]:
            for expected_moves, tile_id in enumerate(LEVEL_SOLUTIONS[level], 1):
                mouse_collect(tile_id, expected_moves)
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.status === 'won'",
                timeout=8_000,
            )
            return acceptance_state()

        try:
            page.goto(
                args.base_url, wait_until="domcontentloaded", timeout=args.load_timeout_ms
            )
            wait_ready()
        except PlaywrightTimeoutError as error:
            page.screenshot(
                path=str(args.output_dir / "00-load-timeout.png"), full_page=True
            )
            timeout_report = {
                "base_url": args.base_url,
                "result": "TIMEOUT",
                "error": str(error),
                "responses": responses,
                "console_errors": console_errors,
                "page_errors": page_errors,
                "request_failures": request_failures,
            }
            (args.output_dir / "web-acceptance-timeout.json").write_text(
                json.dumps(timeout_report, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            browser.close()
            print("TILECLUB_WEB_ACCEPTANCE=TIMEOUT")
            return 2

        page.wait_for_timeout(500)
        # Perform an explicit no-store browser fetch and hash every received byte
        # inside the secure page. Chrome may evict the engine's original large
        # response from its inspector cache, so Response.body() is not evidence.
        immutable_urls = [
            url
            for url in response_objects
            if Path(url.split("?", 1)[0]).suffix.lower() in {".pck", ".wasm"}
        ]
        bundle_body_hashes = page.evaluate(
            """async urls => {
                const result = {};
                for (const url of urls) {
                    const response = await fetch(url, {cache: 'no-store'});
                    const bytes = await response.arrayBuffer();
                    const digest = await crypto.subtle.digest('SHA-256', bytes);
                    result[url] = {
                        status: response.status,
                        bytes: bytes.byteLength,
                        sha256: Array.from(new Uint8Array(digest))
                            .map(value => value.toString(16).padStart(2, '0'))
                            .join(''),
                    };
                }
                return result;
            }""",
            immutable_urls,
        )
        bundle_range_probes = page.evaluate(
            """async urls => {
                const result = {};
                for (const url of urls) {
                    const response = await fetch(url, {
                        cache: 'no-store',
                        headers: {Range: 'bytes=1048576-2097151'},
                    });
                    const bytes = await response.arrayBuffer();
                    const digest = await crypto.subtle.digest('SHA-256', bytes);
                    result[url] = {
                        status: response.status,
                        bytes: bytes.byteLength,
                        sha256: Array.from(new Uint8Array(digest))
                            .map(value => value.toString(16).padStart(2, '0'))
                            .join(''),
                        accept_ranges: response.headers.get('accept-ranges') || '',
                        content_range: response.headers.get('content-range') || '',
                        content_type: response.headers.get('content-type') || '',
                    };
                }
                return result;
            }""",
            immutable_urls,
        )
        entrypoint_contract = page.evaluate(
            """async () => {
                const response = await fetch(
                    new URL(`index.html?acceptance_contract=${Date.now()}`, location.href),
                    {cache: 'no-store'}
                );
                const html = await response.text();
                const capture = pattern => (html.match(pattern) || ['', ''])[1];
                return {
                    status: response.status,
                    content_type: response.headers.get('content-type') || '',
                    cache_control: response.headers.get('cache-control') || '',
                    main_pack: capture(/"mainPack":"([^"]+)"/),
                    executable: capture(/"executable":"([^"]+)"/),
                    script: capture(/<script src="([^"]+[.]js)"><[/]script>/),
                    includes_expected_pack_size: html.includes(
                        `"${%s}":${%d}`
                    ),
                };
            }""" % (json.dumps(args.expected_pck), args.expected_pck_bytes)
        )
        home_state = acceptance_state()
        secure_context = page.evaluate("window.isSecureContext")
        open_tileclub()
        entry_state = acceptance_state()
        page.screenshot(path=str(args.output_dir / "00-entry.png"), full_page=True)

        # Real mouse, touch and keyboard inputs make one complete triple.
        mouse_collect(2, 1)
        mouse_state = acceptance_state()
        touch_x, touch_y = screen_point(*tile_center(0))
        page.touchscreen.tap(touch_x, touch_y)
        wait_moves(2)
        touch_state = acceptance_state()
        page.keyboard.press("Enter")
        wait_moves(3)
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.matches === 1 && "
            "window.__gameAcceptance.getState().state.score === 100",
            timeout=8_000,
        )
        triple_state = acceptance_state()
        page.wait_for_timeout(180)
        page.screenshot(path=str(args.output_dir / "10-triple.png"), full_page=True)

        # Reload, re-enter, and prove the replay-validated checkpoint restores.
        page.reload(wait_until="domcontentloaded", timeout=args.load_timeout_ms)
        wait_ready()
        open_tileclub()
        recovery_state = acceptance_state()
        page.screenshot(path=str(args.output_dir / "20-recovered.png"), full_page=True)

        page.keyboard.press("KeyR")
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.moves === 0 && "
            "window.__gameAcceptance.getState().state.active_count === 12 && "
            "window.__gameAcceptance.getState().state.tray.length === 0",
            timeout=8_000,
        )
        restart_state = acceptance_state()

        # Complete two full loops through legal pointer actions, then exercise
        # the deterministic seven-distinct full-tray failure on level three.
        level_zero_complete = complete_level(0)
        page.wait_for_timeout(900)
        page.screenshot(
            path=str(args.output_dir / "30-level-complete.png"), full_page=True
        )
        mouse_design_click(*NEXT_LEVEL_CENTER)
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.level_index === 1 && "
            "window.__gameAcceptance.getState().state.moves === 0",
            timeout=8_000,
        )
        level_one_complete = complete_level(1)
        mouse_design_click(*NEXT_LEVEL_CENTER)
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.level_index === 2 && "
            "window.__gameAcceptance.getState().state.moves === 0",
            timeout=8_000,
        )
        for expected_moves, tile_id in enumerate(LEVEL_TWO_DISTINCT_TOPS, 1):
            mouse_collect(tile_id, expected_moves)
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.status === 'over' && "
            "window.__gameAcceptance.getState().state.tray.length === 7",
            timeout=8_000,
        )
        failure_state = acceptance_state()
        page.wait_for_timeout(900)
        page.screenshot(path=str(args.output_dir / "40-full-tray.png"), full_page=True)

        # Remove the terminal checkpoint before validating the URL/media-query
        # low-effects branch in a fresh page lifecycle.
        page.evaluate(
            "localStorage.removeItem('offline-games.tileclub.checkpoint.v3')"
        )
        reduced_url = urljoin(args.base_url, "?reduced_effects=1")
        page.goto(
            reduced_url,
            wait_until="domcontentloaded",
            timeout=args.load_timeout_ms,
        )
        wait_ready()
        open_tileclub()
        # Godot Web may also persist user:// through IndexedDB, independently
        # of localStorage. If that durable checkpoint is terminal, restart its
        # current deterministic fixture before the low-effects action.
        if acceptance_state()["state"].get("status") != "playing":
            page.keyboard.press("KeyR")
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.status === 'playing' && "
                "window.__gameAcceptance.getState().state.moves === 0",
                timeout=8_000,
            )
        reduced_entry_state = acceptance_state()
        mouse_collect(2, 1)
        reduced_state = acceptance_state()
        page.wait_for_timeout(80)
        page.screenshot(path=str(args.output_dir / "50-reduced.png"), full_page=True)
        page.reload(wait_until="domcontentloaded", timeout=args.load_timeout_ms)
        wait_ready()
        open_tileclub()
        reduced_recovery_state = acceptance_state()

        browser.close()

    pck_bodies = {
        url: details
        for url, details in bundle_body_hashes.items()
        if url.split("?", 1)[0].endswith(".pck")
    }
    wasm_bodies = {
        url: details
        for url, details in bundle_body_hashes.items()
        if url.split("?", 1)[0].endswith(".wasm")
    }
    pck_ranges = {
        url: details
        for url, details in bundle_range_probes.items()
        if url.split("?", 1)[0].endswith(".pck")
    }
    wasm_ranges = {
        url: details
        for url, details in bundle_range_probes.items()
        if url.split("?", 1)[0].endswith(".wasm")
    }
    expected_executable = next(
        (
            Path(url.split("?", 1)[0]).name.removesuffix(".wasm")
            for url, details in wasm_bodies.items()
            if details["sha256"] == args.expected_wasm_sha256
        ),
        "",
    )
    entrypoint_responses = [
        details
        for url, details in responses.items()
        if urlparse(url).path.endswith("/")
        or urlparse(url).path.endswith("/index.html")
    ]
    pck_responses = [
        details
        for url, details in responses.items()
        if Path(urlparse(url).path).name == args.expected_pck
        and details["status"] == 200
    ]
    wasm_responses = [
        details
        for url, details in responses.items()
        if urlparse(url).path.endswith(".wasm") and details["status"] == 200
    ]
    entry = entry_state["state"]
    mouse = mouse_state["state"]
    touch = touch_state["state"]
    triple = triple_state["state"]
    recovery = recovery_state["state"]
    restart = restart_state["state"]
    level0 = level_zero_complete["state"]
    level1 = level_one_complete["state"]
    failure = failure_state["state"]
    reduced = reduced_state["state"]
    reduced_entry = reduced_entry_state["state"]
    reduced_presentation = reduced_state["presentation"]
    reduced_recovery = reduced_recovery_state["state"]
    checks = {
        "secure_context": secure_context is True,
        "ready_and_catalog_14": bool(home_state.get("ready"))
        and home_state.get("catalog_size") == 14,
        "entry_layered_contract": entry.get("rules_version") == "tileclub-stage0-v1"
        and entry.get("active_count") == 12
        and len(entry.get("selectable_ids", [])) == 4
        and entry_state.get("presentation", {}).get("stable_visible_instances") == 12,
        "mouse_collect": mouse.get("moves") == 1
        and mouse.get("tray") == [1]
        and mouse.get("active_count") == 11,
        "touch_collect": touch.get("moves") == 2
        and touch.get("tray") == [1, 1]
        and touch.get("active_count") == 10,
        "keyboard_triple": triple.get("moves") == 3
        and triple.get("matches") == 1
        and triple.get("score") == 100
        and triple.get("tray") == [],
        "checkpoint_reload_recovery": recovery.get("moves") == 3
        and recovery.get("score") == 100
        and recovery_state.get("presentation", {}).get("checkpoint_restored") is True,
        "restart": restart.get("moves") == 0
        and restart.get("active_count") == 12
        and restart.get("tray") == [],
        "full_loop_level_zero": level0.get("status") == "won"
        and level0.get("active_count") == 0
        and level0.get("tray") == [],
        "full_loop_level_one": level1.get("status") == "won"
        and level1.get("active_count") == 0
        and level1.get("tray") == [],
        "full_tray_failure": failure.get("status") == "over"
        and failure.get("moves") == 7
        and len(failure.get("tray", [])) == 7,
        "reduced_authoritative_state": reduced.get("moves") == 1
        and reduced.get("active_count") == reduced_entry.get("active_count") - 1
        and reduced.get("tray") == [1],
        "reduced_spatial_haptic_suppression": reduced_presentation.get(
            "reduced_effects"
        )
        is True
        and reduced_presentation.get("motion_active") is False
        and reduced_presentation.get("impact_active") is False
        and reduced_presentation.get("object_fx_active") is False
        and reduced_presentation.get("shake_offset") == [0.0, 0.0]
        and reduced_presentation.get("haptic_suppressed_count", 0) >= 1,
        "reduced_reload_recovery": reduced_recovery.get("moves") == 1
        and reduced_recovery_state.get("presentation", {}).get(
            "checkpoint_restored"
        )
        is True
        and reduced_recovery_state.get("presentation", {}).get(
            "reduced_effects"
        )
        is True,
        "fingerprinted_pck_full_transfer": any(
            Path(url.split("?", 1)[0]).name == args.expected_pck
            and details["bytes"] == args.expected_pck_bytes
            and details["sha256"] == args.expected_pck_sha256
            for url, details in pck_bodies.items()
        ),
        "fingerprinted_wasm_full_transfer": any(
            details["sha256"] == args.expected_wasm_sha256
            for details in wasm_bodies.values()
        ),
        "fingerprinted_entrypoint_contract": entrypoint_contract.get(
            "status"
        )
        == 200
        and entrypoint_contract.get("main_pack") == args.expected_pck
        and bool(expected_executable)
        and entrypoint_contract.get("executable") == expected_executable
        and entrypoint_contract.get("script") == f"{expected_executable}.js"
        and entrypoint_contract.get("includes_expected_pack_size") is True,
        "transport_content_and_cache_headers": bool(entrypoint_responses)
        and all(
            str(details["content_type"]).startswith("text/html")
            and "no-cache" in str(details["cache_control"])
            and details["cross_origin_embedder_policy"] == "require-corp"
            and details["cross_origin_opener_policy"] == "same-origin"
            for details in entrypoint_responses
            if details["status"] in {200, 304}
        )
        and bool(pck_responses)
        and all(
            details["content_type"] == "application/octet-stream"
            and details["accept_ranges"] == "bytes"
            and "immutable" in str(details["cache_control"])
            for details in pck_responses
        )
        and bool(wasm_responses)
        and all(
            details["content_type"] == "application/wasm"
            and details["accept_ranges"] == "bytes"
            and "immutable" in str(details["cache_control"])
            for details in wasm_responses
        ),
        "pck_and_wasm_range_transfer": bool(pck_ranges)
        and bool(wasm_ranges)
        and all(
            details["status"] == 206
            and details["bytes"] == 1_048_576
            and details["accept_ranges"] == "bytes"
            and str(details["content_range"]).startswith(
                "bytes 1048576-2097151/"
            )
            for details in [*pck_ranges.values(), *wasm_ranges.values()]
        ),
        "runtime_errors_clear": not console_errors
        and not page_errors
        and not request_failures
        and all(details["status"] in {200, 206, 304} for details in responses.values()),
    }
    report = {
        "observed_at_unix": int(time.time()),
        "base_url": args.base_url,
        "reduced_url": urljoin(args.base_url, "?reduced_effects=1"),
        "browser": "Google Chrome headless / SwiftShader WebGL2",
        "viewport": [540, 960],
        "checks": checks,
        "result": "PASS" if all(checks.values()) else "FAIL",
        "bundle_responses": responses,
        "bundle_body_hashes": bundle_body_hashes,
        "bundle_range_probes": bundle_range_probes,
        "entrypoint_contract": entrypoint_contract,
        "finished_requests_ms": finished_requests_ms,
        "console_errors": console_errors,
        "page_errors": page_errors,
        "request_failures": request_failures,
        "entry_state": entry_state,
        "mouse_state": mouse_state,
        "touch_state": touch_state,
        "triple_state": triple_state,
        "recovery_state": recovery_state,
        "restart_state": restart_state,
        "level_zero_complete_state": level_zero_complete,
        "level_one_complete_state": level_one_complete,
        "failure_state": failure_state,
        "reduced_entry_state": reduced_entry_state,
        "reduced_state": reduced_state,
        "reduced_recovery_state": reduced_recovery_state,
    }
    report_path = args.output_dir / "web-acceptance.json"
    report_path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"TILECLUB_WEB_ACCEPTANCE={report['result']}")
    print(f"TILECLUB_WEB_REPORT={report_path}")
    return 0 if report["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
