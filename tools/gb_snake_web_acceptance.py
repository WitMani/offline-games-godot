#!/usr/bin/env python3
"""Fresh-browser acceptance for the frozen 79_SNAKE2 Web candidate."""

from __future__ import annotations

import argparse
import json
import re
import time
from pathlib import Path
from typing import Any

from playwright.sync_api import sync_playwright


CHROME_ARGS = [
    "--enable-unsafe-swiftshader",
    "--use-angle=swiftshader",
    "--use-gl=angle",
    "--enable-webgl",
    "--ignore-gpu-blocklist",
]
FINGERPRINTED = re.compile(r"/index\.[0-9a-f]{12}\.(?:js|wasm|pck)$")
STORAGE_KEY = "offline-games:snake-gb:v3"
VIEWPORT = {"width": 540, "height": 960}


def snake_state(page: Any) -> dict[str, Any]:
    return page.evaluate("window.__gameAcceptance.getState().state")


def vector(value: Any) -> list[int]:
    return [int(value[0]), int(value[1])]


def canvas_point(box: dict[str, float], x: float, y: float) -> tuple[float, float]:
    return (
        box["x"] + x * box["width"] / 540.0,
        box["y"] + y * box["height"] / 960.0,
    )


def core_snapshot(state: dict[str, Any]) -> dict[str, Any]:
    return {
        key: state.get(key)
        for key in (
            "segments",
            "direction",
            "turn_queue",
            "foods",
            "score",
            "moves",
            "pending_growth",
            "status",
            "terminal_reason",
            "rng_state",
        )
    }


def forward_clearance(state: dict[str, Any]) -> int:
    head = vector(state["segments"][0])
    direction = vector(state["direction"])
    if direction == [1, 0]:
        return int(state["width"]) - 1 - head[0]
    if direction == [-1, 0]:
        return head[0]
    if direction == [0, 1]:
        return int(state["height"]) - 1 - head[1]
    return head[1]


def install_vibration_probe(context: Any) -> None:
    context.add_init_script(
        """
        window.__vibrationCalls = [];
        try {
          Object.defineProperty(navigator, 'vibrate', {
            configurable: true,
            value: function(pattern) {
              window.__vibrationCalls.push(pattern);
              return true;
            }
          });
        } catch (_) {
          navigator.vibrate = function(pattern) {
            window.__vibrationCalls.push(pattern);
            return true;
          };
        }
        """
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("base_url")
    parser.add_argument("output_dir")
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--load-timeout-ms", type=int, default=90_000)
    args = parser.parse_args()

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    console_errors: list[str] = []
    page_errors: list[str] = []
    request_failures: list[str] = []
    responses: dict[str, dict[str, Any]] = {}
    cdp_transfers: dict[str, dict[str, Any]] = {}

    def observe(page: Any, label: str) -> None:
        page.on(
            "console",
            lambda message: console_errors.append(f"{label}: {message.text}")
            if message.type == "error"
            else None,
        )
        page.on("pageerror", lambda error: page_errors.append(f"{label}: {error}"))
        page.on(
            "requestfailed",
            lambda request: request_failures.append(
                f"{label}: {request.failure}: {request.url}"
            ),
        )

        def remember(response: Any) -> None:
            suffix = Path(response.url.split("?", 1)[0]).suffix.lower()
            if response.request.resource_type != "document" and suffix not in {
                ".js",
                ".wasm",
                ".pck",
            }:
                return
            headers = response.headers
            responses[f"{label}: {response.url}"] = {
                "status": response.status,
                "ok": response.ok,
                "resource_type": response.request.resource_type,
                "content_type": headers.get("content-type", ""),
                "content_length": headers.get("content-length", ""),
                "content_encoding": headers.get("content-encoding", ""),
                "cache_control": headers.get("cache-control", ""),
                "accept_ranges": headers.get("accept-ranges", ""),
                "cross_origin_opener_policy": headers.get(
                    "cross-origin-opener-policy", ""
                ),
                "cross_origin_embedder_policy": headers.get(
                    "cross-origin-embedder-policy", ""
                ),
            }

        page.on("response", remember)
        session = page.context.new_cdp_session(page)
        session.send("Network.enable")
        session.send("Network.setCacheDisabled", {"cacheDisabled": True})
        request_ids: dict[str, str] = {}

        def response_received(event: dict[str, Any]) -> None:
            response = event["response"]
            url = response["url"]
            if FINGERPRINTED.search(url):
                request_id = event["requestId"]
                request_ids[request_id] = url
                cdp_transfers[f"{label}: {url}"] = {
                    "status": response["status"],
                    "mime_type": response.get("mimeType", ""),
                    "protocol": response.get("protocol", ""),
                    "from_disk_cache": response.get("fromDiskCache", False),
                    "from_service_worker": response.get("fromServiceWorker", False),
                }

        def loading_finished(event: dict[str, Any]) -> None:
            request_id = event["requestId"]
            if request_id in request_ids:
                cdp_transfers[f"{label}: {request_ids[request_id]}"][
                    "encoded_data_length"
                ] = event.get("encodedDataLength", 0)

        session.on("Network.responseReceived", response_received)
        session.on("Network.loadingFinished", loading_finished)

    def wait_ready(page: Any) -> int:
        started = time.monotonic()
        page.goto(args.base_url, wait_until="domcontentloaded", timeout=args.load_timeout_ms)
        page.wait_for_function(
            "window.__gameAcceptance && "
            "window.__gameAcceptance.getState().ready === true",
            timeout=args.load_timeout_ms,
        )
        return round((time.monotonic() - started) * 1000)

    def canvas_box(page: Any) -> dict[str, float]:
        box = page.locator("canvas").bounding_box()
        if box is None:
            raise RuntimeError("Godot canvas did not expose a bounding box")
        return box

    def open_snake(page: Any, box: dict[str, float]) -> dict[str, Any]:
        # Catalog index 5: row 2, column 1, inside its real transparent Button.
        x, y = canvas_point(box, 399, 589)
        page.mouse.click(x, y)
        page.wait_for_function(
            "window.__gameAcceptance.getState().game_id === 'snake_classic'",
            timeout=15_000,
        )
        page.wait_for_timeout(60)
        return page.evaluate("window.__gameAcceptance.getState()")

    def wait_direction(page: Any, expected: list[int]) -> dict[str, Any]:
        page.wait_for_function(
            "expected => { const s=window.__gameAcceptance.getState().state; "
            "return s.status==='playing' && s.direction && "
            "s.direction[0]===expected[0] && s.direction[1]===expected[1]; }",
            arg=expected,
            timeout=5_000,
        )
        return snake_state(page)

    def wait_moves(page: Any, minimum: int) -> dict[str, Any]:
        page.wait_for_function(
            "minimum => { const s=window.__gameAcceptance.getState().state; "
            "return s.status==='playing' && Number(s.moves)>=minimum; }",
            arg=minimum,
            timeout=5_000,
        )
        return snake_state(page)

    def resource_timing(page: Any) -> list[dict[str, Any]]:
        return page.evaluate(
            r"""() => performance.getEntriesByType('resource')
              .filter(e => /index\.[0-9a-f]{12}\.(js|wasm|pck)$/.test(e.name))
              .map(e => ({name:e.name, initiator_type:e.initiatorType,
                          transfer_size:e.transferSize,
                          encoded_body_size:e.encodedBodySize,
                          decoded_body_size:e.decodedBodySize,
                          duration_ms:e.duration}))"""
        )

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(
            headless=True,
            executable_path="/usr/bin/google-chrome",
            args=CHROME_ARGS,
        )
        normal_context = browser.new_context(
            viewport=VIEWPORT, has_touch=True, service_workers="block"
        )
        install_vibration_probe(normal_context)
        page = normal_context.new_page()
        observe(page, "normal")
        ready_ms = wait_ready(page)
        secure_context = page.evaluate("window.isSecureContext")
        cross_origin_isolated = page.evaluate("window.crossOriginIsolated")
        normal_resource_timing = resource_timing(page)
        box = canvas_box(page)
        entry_state = open_snake(page, box)
        page.screenshot(path=str(output_dir / "10-entry.png"), full_page=True)

        dpad_before = snake_state(page)
        dpad_x, dpad_y = canvas_point(box, 159, 581)
        page.mouse.click(dpad_x, dpad_y)
        dpad_after = wait_direction(page, [0, -1])

        keyboard_before = dpad_after
        page.keyboard.press("ArrowLeft")
        keyboard_after = wait_direction(page, [-1, 0])

        touch_before = keyboard_after
        session = normal_context.new_cdp_session(page)
        touch_x, touch_y = canvas_point(box, 300, 390)
        touch_end_y = touch_y + 72
        session.send(
            "Input.dispatchTouchEvent",
            {
                "type": "touchStart",
                "touchPoints": [{"x": touch_x, "y": touch_y, "id": 41}],
            },
        )
        session.send(
            "Input.dispatchTouchEvent",
            {
                "type": "touchMove",
                "touchPoints": [{"x": touch_x, "y": touch_end_y, "id": 41}],
            },
        )
        page.wait_for_function(
            "() => { const s=window.__gameAcceptance.getState().state; "
            "const queued=(s.turn_queue||[]).some(v=>v[0]===0&&v[1]===1); "
            "return queued || (s.direction&&s.direction[0]===0&&s.direction[1]===1); }",
            timeout=3_000,
        )
        touch_before_release = snake_state(page)
        session.send(
            "Input.dispatchTouchEvent", {"type": "touchEnd", "touchPoints": []}
        )
        touch_after = wait_direction(page, [0, 1])
        input_vibration_calls = page.evaluate("window.__vibrationCalls.slice()")
        page.screenshot(path=str(output_dir / "20-after-inputs.png"), full_page=True)

        # Keep the endless run safely inside a 3x3 loop until an active-run
        # snapshot (not merely the entry snapshot) has reached localStorage.
        persisted_snapshot: dict[str, Any] | None = None
        leg_directions = [
            ("ArrowRight", [1, 0]),
            ("ArrowUp", [0, -1]),
            ("ArrowLeft", [-1, 0]),
            ("ArrowDown", [0, 1]),
        ]
        minimum_persisted_moves = int(entry_state["state"]["moves"]) + 3
        for leg in range(8):
            key, expected = leg_directions[leg % len(leg_directions)]
            page.keyboard.press(key)
            directed = wait_direction(page, expected)
            wait_moves(page, int(directed["moves"]) + 2)
            raw = page.evaluate(
                "key => localStorage.getItem(key) || ''", STORAGE_KEY
            )
            if raw:
                candidate = json.loads(raw)
                if (
                    candidate.get("status") == "playing"
                    and int(candidate.get("moves", 0)) >= minimum_persisted_moves
                    and forward_clearance(candidate) >= 6
                ):
                    persisted_snapshot = candidate
                    break
        if persisted_snapshot is None:
            raise RuntimeError("active GB Snake run was not persisted before timeout")
        persisted_core = core_snapshot(persisted_snapshot)

        page.reload(wait_until="domcontentloaded", timeout=args.load_timeout_ms)
        page.wait_for_function(
            "window.__gameAcceptance && window.__gameAcceptance.getState().ready === true",
            timeout=args.load_timeout_ms,
        )
        recovered_state = open_snake(page, canvas_box(page))
        recovered_core = core_snapshot(recovered_state["state"])
        page.screenshot(path=str(output_dir / "30-recovered.png"), full_page=True)

        restart_before = snake_state(page)
        restart_x, restart_y = canvas_point(canvas_box(page), 484, 43)
        page.mouse.click(restart_x, restart_y)
        page.wait_for_function(
            "() => { const s=window.__gameAcceptance.getState().state; "
            "return s.status==='playing' && s.score===4 && s.segments && "
            "s.segments.length===4 && Number(s.moves)<=1; }",
            timeout=5_000,
        )
        restart_after = snake_state(page)
        restart_storage = page.evaluate(
            "key => localStorage.getItem(key) || ''", STORAGE_KEY
        )
        page.screenshot(path=str(output_dir / "40-restarted.png"), full_page=True)
        normal_vibration_calls = page.evaluate("window.__vibrationCalls")
        normal_probe = page.evaluate("window.__offlineGamesWebProbe")
        normal_context.close()

        reduced_context = browser.new_context(
            viewport=VIEWPORT,
            has_touch=True,
            reduced_motion="reduce",
            service_workers="block",
        )
        install_vibration_probe(reduced_context)
        reduced_page = reduced_context.new_page()
        observe(reduced_page, "reduced")
        reduced_ready_ms = wait_ready(reduced_page)
        reduced_match_media = reduced_page.evaluate(
            "matchMedia('(prefers-reduced-motion: reduce)').matches"
        )
        reduced_box = canvas_box(reduced_page)
        reduced_entry = open_snake(reduced_page, reduced_box)
        reduced_x, reduced_y = canvas_point(reduced_box, 159, 581)
        reduced_page.mouse.click(reduced_x, reduced_y)
        reduced_after = wait_direction(reduced_page, [0, -1])
        reduced_vibration_calls = reduced_page.evaluate("window.__vibrationCalls")
        reduced_probe = reduced_page.evaluate("window.__offlineGamesWebProbe")
        reduced_page.screenshot(
            path=str(output_dir / "50-reduced-motion.png"), full_page=True
        )
        reduced_context.close()
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
    document_responses = {
        url: details
        for url, details in responses.items()
        if details["resource_type"] == "document"
    }
    initial_timings = {
        Path(item["name"].split("?", 1)[0]).suffix: item
        for item in normal_resource_timing
    }
    entry = entry_state["state"]
    recovered = recovered_state["state"]
    persisted_head = vector(persisted_snapshot["segments"][0])
    touch_observed_before_release = (
        vector(touch_before_release.get("direction", [9, 9])) == [0, 1]
        or [0, 1]
        in [vector(item) for item in touch_before_release.get("turn_queue", [])]
    )
    checks = {
        "source_commit_supplied": bool(re.fullmatch(r"[0-9a-f]{40}", args.source_commit)),
        "secure_context": secure_context is True,
        "cross_origin_isolated": cross_origin_isolated is True,
        "entry_contract": entry.get("width") == 15
        and entry.get("height") == 23
        and entry.get("score") == 4
        and len(entry.get("segments", [])) == 4
        and len(entry.get("foods", [])) == 2
        and entry.get("foods", [None, None])[0] != entry.get("foods", [None, None])[1]
        and entry.get("endless") is True
        and "target_length" not in entry
        and entry.get("status") == "playing",
        "dpad_turn": vector(dpad_after.get("direction", [])) == [0, -1]
        and int(dpad_after.get("moves", 0)) >= int(dpad_before.get("moves", 0)),
        "keyboard_turn": vector(keyboard_after.get("direction", [])) == [-1, 0]
        and int(keyboard_after.get("moves", 0)) >= int(keyboard_before.get("moves", 0)),
        "touch_swipe_before_release": touch_observed_before_release,
        "touch_turn_consequence": vector(touch_after.get("direction", [])) == [0, 1]
        and int(touch_after.get("moves", 0)) >= int(touch_before.get("moves", 0)),
        "normal_haptic_routed": len(input_vibration_calls) >= 3,
        "active_run_saved": int(persisted_snapshot.get("moves", 0))
        >= minimum_persisted_moves
        and persisted_snapshot.get("status") == "playing",
        "reload_recovery": recovered.get("status") == "playing"
        and int(recovered.get("moves", -1)) >= int(persisted_snapshot.get("moves", 0))
        and int(recovered.get("moves", -1)) <= int(persisted_snapshot.get("moves", 0)) + 3
        and int(recovered.get("score", 0)) >= int(persisted_snapshot.get("score", 0))
        and len(recovered.get("segments", [])) >= len(persisted_snapshot.get("segments", []))
        and persisted_head in [vector(item) for item in recovered.get("segments", [])],
        "hardware_restart": restart_after.get("status") == "playing"
        and restart_after.get("score") == 4
        and len(restart_after.get("segments", [])) == 4
        and int(restart_after.get("moves", 9)) <= 1
        and restart_storage == "",
        "reduced_preference_detected": reduced_match_media is True,
        "reduced_input_consequence": vector(reduced_after.get("direction", []))
        == [0, -1]
        and reduced_after.get("status") == "playing",
        "reduced_haptic_suppressed": reduced_vibration_calls == [],
        "fingerprinted_runtime": bool(pck_responses)
        and bool(wasm_responses)
        and all(FINGERPRINTED.search(url) for url in pck_responses | wasm_responses),
        "runtime_assets_loaded": all(
            details["ok"] for details in pck_responses.values()
        )
        and all(details["ok"] for details in wasm_responses.values()),
        "isolation_headers": bool(document_responses)
        and all(
            details["cross_origin_opener_policy"] == "same-origin"
            and details["cross_origin_embedder_policy"] == "require-corp"
            for details in document_responses.values()
        ),
        "immutable_runtime_headers": all(
            "immutable" in details["cache_control"]
            for details in pck_responses.values()
        )
        and all(
            "immutable" in details["cache_control"]
            for details in wasm_responses.values()
        ),
        "byte_range_headers": all(
            details["accept_ranges"] == "bytes" for details in pck_responses.values()
        )
        and all(
            details["accept_ranges"] == "bytes" for details in wasm_responses.values()
        ),
        "compressed_runtime_headers": all(
            details["content_encoding"] in {"gzip", "zstd", "br"}
            for details in pck_responses.values()
        )
        and all(
            details["content_encoding"] in {"gzip", "zstd", "br"}
            for details in wasm_responses.values()
        ),
        "empty_cache_transfer_measured": all(
            initial_timings.get(suffix, {}).get("transfer_size", 0) > 0
            for suffix in (".pck", ".wasm")
        ),
        "compressed_body_smaller": all(
            initial_timings.get(suffix, {}).get("encoded_body_size", 0)
            < initial_timings.get(suffix, {}).get("decoded_body_size", 0)
            for suffix in (".pck", ".wasm")
        ),
        "runtime_errors_clear": not normal_probe.get("error")
        and not reduced_probe.get("error")
        and not console_errors
        and not page_errors
        and not request_failures,
    }
    report = {
        "schema": "offline-games.gb-snake-web-acceptance.v3",
        "observed_at_unix": int(time.time()),
        "source_commit": args.source_commit,
        "base_url": args.base_url,
        "browser": "Google Chrome headless / SwiftShader WebGL2",
        "viewport": [540, 960],
        "ready_ms": ready_ms,
        "reduced_ready_ms": reduced_ready_ms,
        "checks": checks,
        "result": "PASS" if all(checks.values()) else "FAIL",
        "bundle_responses": responses,
        "cdp_transfers": cdp_transfers,
        "normal_empty_cache_resource_timing": normal_resource_timing,
        "console_errors": console_errors,
        "page_errors": page_errors,
        "request_failures": request_failures,
        "normal_probe": normal_probe,
        "reduced_probe": reduced_probe,
        "entry_state": entry_state,
        "dpad": {"before": dpad_before, "after": dpad_after},
        "keyboard": {"before": keyboard_before, "after": keyboard_after},
        "touch": {
            "before": touch_before,
            "before_release": touch_before_release,
            "after_release": touch_after,
        },
        "persistence": {
            "storage_key": STORAGE_KEY,
            "saved": persisted_core,
            "recovered": recovered_core,
        },
        "restart": {"before": restart_before, "after": restart_after},
        "normal_vibration_calls": normal_vibration_calls,
        "input_vibration_calls_before_reload": input_vibration_calls,
        "reduced": {
            "match_media": reduced_match_media,
            "entry": reduced_entry,
            "after": reduced_after,
            "vibration_calls": reduced_vibration_calls,
        },
    }
    report_path = output_dir / "web-acceptance.json"
    report_path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"GB_SNAKE_WEB_ACCEPTANCE={report['result']}")
    print(f"GB_SNAKE_WEB_REPORT={report_path}")
    return 0 if report["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
