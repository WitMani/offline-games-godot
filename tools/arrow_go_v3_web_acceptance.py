#!/usr/bin/env python3
"""Real Chrome acceptance for the Arrow GO v3 fingerprinted Web bundle."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import time
import urllib.request
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
DESIGN_SIZE = (540.0, 960.0)
HOME_ARROW = (141.0, 861.0)
ARROW_A = (316.8, 451.0)
ARROW_B = (460.1, 403.2)
RESTART = (486.0, 48.0)


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


def canvas_box(page: Any) -> dict[str, float]:
    box = page.locator("canvas").bounding_box()
    if box is None:
        raise RuntimeError("Godot canvas did not expose a bounding box")
    return box


def screen_point(box: dict[str, float], design_point: tuple[float, float]) -> tuple[float, float]:
    return (
        box["x"] + design_point[0] * box["width"] / DESIGN_SIZE[0],
        box["y"] + design_point[1] * box["height"] / DESIGN_SIZE[1],
    )


def mouse_tap(page: Any, box: dict[str, float], point: tuple[float, float]) -> None:
    x, y = screen_point(box, point)
    page.mouse.click(x, y)


def touch_tap(page: Any, point: tuple[float, float]) -> None:
    box = canvas_box(page)
    x, y = screen_point(box, point)
    session = page.context.new_cdp_session(page)
    session.send(
        "Input.dispatchTouchEvent",
        {
            "type": "touchStart",
            "touchPoints": [
                {"x": x, "y": y, "radiusX": 2, "radiusY": 2, "force": 1}
            ],
        },
    )
    session.send("Input.dispatchTouchEvent", {"type": "touchEnd", "touchPoints": []})


def wait_ready(page: Any, base_url: str, timeout_ms: int) -> int:
    started = time.monotonic()
    page.goto(base_url, wait_until="domcontentloaded", timeout=timeout_ms)
    page.wait_for_function(
        "window.__gameAcceptance && window.__gameAcceptance.getState().ready === true",
        timeout=timeout_ms,
    )
    return round((time.monotonic() - started) * 1000)


def open_arrow(page: Any, input_kind: str) -> dict[str, Any]:
    if input_kind == "touch":
        touch_tap(page, HOME_ARROW)
    else:
        mouse_tap(page, canvas_box(page), HOME_ARROW)
    page.wait_for_function(
        "window.__gameAcceptance.getState().game_id === 'arrow_go'", timeout=15_000
    )
    page.wait_for_timeout(250)
    return page.evaluate("window.__gameAcceptance.getState()")


def state(page: Any) -> dict[str, Any]:
    return page.evaluate("window.__gameAcceptance.getState()")


def wait_event(page: Any, kind: str, moves: int) -> dict[str, Any]:
    page.wait_for_function(
        "([kind, moves]) => { const s=window.__gameAcceptance.getState().state; "
        "return s.moves===moves && s.last_event && s.last_event.kind===kind; }",
        arg=[kind, moves],
        timeout=5_000,
    )
    page.wait_for_timeout(120)
    return state(page)


def full_and_range_probe(base_url: str, bundle_dir: Path) -> dict[str, Any]:
    pck = next(bundle_dir.glob("index.*.pck"))
    pck_url = base_url.rstrip("/") + "/" + pck.name
    full_request = urllib.request.Request(
        pck_url, headers={"Accept-Encoding": "identity"}
    )
    with urllib.request.urlopen(full_request, timeout=60) as response:
        full_body = response.read()
        full_status = response.status
        full_headers = dict(response.headers.items())
    range_request = urllib.request.Request(
        pck_url,
        headers={"Accept-Encoding": "identity", "Range": "bytes=0-1023"},
    )
    with urllib.request.urlopen(range_request, timeout=30) as response:
        range_body = response.read()
        range_status = response.status
        range_headers = dict(response.headers.items())
    local_sha = hashlib.sha256(pck.read_bytes()).hexdigest()
    transfer_sha = hashlib.sha256(full_body).hexdigest()
    return {
        "url": pck_url,
        "expected_bytes": pck.stat().st_size,
        "expected_sha256": local_sha,
        "full": {
            "status": full_status,
            "bytes": len(full_body),
            "sha256": transfer_sha,
            "headers": full_headers,
        },
        "range": {
            "status": range_status,
            "bytes": len(range_body),
            "sha256": hashlib.sha256(range_body).hexdigest(),
            "headers": range_headers,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("base_url")
    parser.add_argument("bundle_dir", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--load-timeout-ms", type=int, default=90_000)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

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
            lambda request: request_failures.append(f"{label}: {request.url}"),
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
            if FINGERPRINTED.search(response["url"]):
                request_id = event["requestId"]
                request_ids[request_id] = response["url"]
                cdp_transfers[f"{label}: {response['url']}"] = {
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
            headless=True, executable_path="/usr/bin/google-chrome", args=CHROME_ARGS
        )

        normal_context = browser.new_context(
            viewport={"width": 540, "height": 960}, service_workers="block"
        )
        install_vibration_probe(normal_context)
        normal = normal_context.new_page()
        observe(normal, "pointer")
        pointer_ready_ms = wait_ready(normal, args.base_url, args.load_timeout_ms)
        normal.wait_for_timeout(400)
        home_state = state(normal)
        secure_context = normal.evaluate("window.isSecureContext")
        cross_origin_isolated = normal.evaluate("window.crossOriginIsolated")
        normal_timing = resource_timing(normal)
        pointer_entry = open_arrow(normal, "pointer")
        normal.wait_for_timeout(900)
        normal.screenshot(path=str(args.output_dir / "10-web-stable.png"), full_page=True)
        normal_box = canvas_box(normal)
        mouse_tap(normal, normal_box, ARROW_A)
        pointer_reject = wait_event(normal, "blocked", 0)
        normal.screenshot(path=str(args.output_dir / "11-web-pointer-reject.png"), full_page=True)
        mouse_tap(normal, normal_box, ARROW_B)
        pointer_legal = wait_event(normal, "turn_escape", 1)
        normal.screenshot(path=str(args.output_dir / "12-web-pointer-legal.png"), full_page=True)
        pointer_vibration = normal.evaluate("window.__vibrationCalls")
        expected_recovery = pointer_legal
        normal.reload(wait_until="domcontentloaded", timeout=args.load_timeout_ms)
        normal.wait_for_function(
            "window.__gameAcceptance && window.__gameAcceptance.getState().ready === true",
            timeout=args.load_timeout_ms,
        )
        normal.wait_for_timeout(300)
        pointer_recovered = open_arrow(normal, "pointer")
        mouse_tap(normal, canvas_box(normal), RESTART)
        normal.wait_for_function(
            "window.__gameAcceptance.getState().state.moves === 0 && "
            "window.__gameAcceptance.getState().state.remaining === 12",
            timeout=5_000,
        )
        pointer_restart = state(normal)
        normal_probe = normal.evaluate("window.__offlineGamesWebProbe")
        normal_context.close()

        touch_context = browser.new_context(
            viewport={"width": 540, "height": 960},
            has_touch=True,
            is_mobile=True,
            service_workers="block",
        )
        install_vibration_probe(touch_context)
        touch = touch_context.new_page()
        observe(touch, "touch")
        touch_ready_ms = wait_ready(touch, args.base_url, args.load_timeout_ms)
        touch_entry = open_arrow(touch, "touch")
        touch_tap(touch, ARROW_A)
        touch_reject = wait_event(touch, "blocked", 0)
        touch_tap(touch, ARROW_B)
        touch_legal = wait_event(touch, "turn_escape", 1)
        touch_vibration = touch.evaluate("window.__vibrationCalls")
        touch.screenshot(path=str(args.output_dir / "20-web-touch-legal.png"), full_page=True)
        touch_probe = touch.evaluate("window.__offlineGamesWebProbe")
        touch_context.close()

        keyboard_context = browser.new_context(
            viewport={"width": 540, "height": 960}, service_workers="block"
        )
        install_vibration_probe(keyboard_context)
        keyboard = keyboard_context.new_page()
        observe(keyboard, "keyboard")
        keyboard_ready_ms = wait_ready(keyboard, args.base_url, args.load_timeout_ms)
        keyboard_entry = open_arrow(keyboard, "pointer")
        keyboard.keyboard.press("Enter")
        keyboard_reject = wait_event(keyboard, "blocked", 0)
        keyboard.keyboard.press("ArrowRight")
        keyboard.wait_for_function(
            "window.__gameAcceptance.getState().state.focus_id === 'b'", timeout=5_000
        )
        keyboard.keyboard.press("Enter")
        keyboard_legal = wait_event(keyboard, "turn_escape", 1)
        keyboard_vibration = keyboard.evaluate("window.__vibrationCalls")
        keyboard.screenshot(path=str(args.output_dir / "30-web-keyboard-legal.png"), full_page=True)
        keyboard_probe = keyboard.evaluate("window.__offlineGamesWebProbe")
        keyboard_context.close()

        reduced_context = browser.new_context(
            viewport={"width": 540, "height": 960},
            reduced_motion="reduce",
            service_workers="block",
        )
        install_vibration_probe(reduced_context)
        reduced = reduced_context.new_page()
        observe(reduced, "reduced")
        reduced_ready_ms = wait_ready(reduced, args.base_url, args.load_timeout_ms)
        reduced_entry = open_arrow(reduced, "pointer")
        mouse_tap(reduced, canvas_box(reduced), ARROW_B)
        reduced_legal = wait_event(reduced, "turn_escape", 1)
        reduced_vibration = reduced.evaluate("window.__vibrationCalls")
        reduced.screenshot(path=str(args.output_dir / "40-web-reduced.png"), full_page=True)
        reduced_probe = reduced.evaluate("window.__offlineGamesWebProbe")
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
    full_range = full_and_range_probe(args.base_url, args.bundle_dir)

    def authority(observed: dict[str, Any]) -> dict[str, Any]:
        model = observed["state"]
        return {
            key: model.get(key)
            for key in ("removed_ids", "remaining", "moves", "score", "status")
        }

    probes = [normal_probe, touch_probe, keyboard_probe, reduced_probe]
    checks = {
        "secure_context": secure_context is True,
        "cross_origin_isolated": cross_origin_isolated is True,
        "ready_catalog": bool(home_state.get("ready"))
        and home_state.get("catalog_size") == 14,
        "entry_contract": pointer_entry["state"].get("remaining") == 12
        and pointer_entry["state"].get("legal_ids") == ["b", "d", "k"],
        "pointer_reject_atomic": authority(pointer_reject)
        == authority(pointer_entry),
        "pointer_legal": pointer_legal["state"].get("removed_ids") == ["b"]
        and pointer_legal["state"].get("moves") == 1,
        "pointer_haptic_routed": len(pointer_vibration) >= 2,
        "reload_recovery": authority(pointer_recovered)
        == authority(expected_recovery),
        "restart_contract": pointer_restart["state"].get("moves") == 0
        and pointer_restart["state"].get("remaining") == 12
        and pointer_restart["state"].get("removed_ids") == [],
        "touch_reject_atomic": authority(touch_reject) == authority(touch_entry),
        "touch_legal": touch_legal["state"].get("removed_ids") == ["b"]
        and touch_legal["state"].get("moves") == 1
        and len(touch_vibration) >= 2,
        "keyboard_reject_atomic": authority(keyboard_reject)
        == authority(keyboard_entry),
        "keyboard_legal": keyboard_legal["state"].get("removed_ids") == ["b"]
        and keyboard_legal["state"].get("moves") == 1
        and len(keyboard_vibration) >= 2,
        "reduced_detected": reduced_entry["state"].get("reduced_effects") is True,
        "reduced_authority": reduced_legal["state"].get("removed_ids") == ["b"]
        and reduced_legal["state"].get("moves") == 1,
        "reduced_haptic_suppressed": reduced_vibration == [],
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
        "compressed_runtime_headers": all(
            details["content_encoding"] in {"gzip", "zstd", "br"}
            for details in pck_responses.values()
        )
        and all(
            details["content_encoding"] in {"gzip", "zstd", "br"}
            for details in wasm_responses.values()
        ),
        "empty_cache_transfer_measured": all(
            transfer.get("encoded_data_length", 0) > 0
            and not transfer.get("from_disk_cache")
            and not transfer.get("from_service_worker")
            for transfer in cdp_transfers.values()
        ),
        "full_transfer_exact": full_range["full"]["status"] == 200
        and full_range["full"]["bytes"] == full_range["expected_bytes"]
        and full_range["full"]["sha256"] == full_range["expected_sha256"],
        "byte_range_exact": full_range["range"]["status"] == 206
        and full_range["range"]["bytes"] == 1024
        and full_range["range"]["headers"].get("Content-Range", "").startswith(
            "bytes 0-1023/"
        ),
        "runtime_errors_clear": all(not probe.get("error") for probe in probes)
        and not console_errors
        and not page_errors
        and not request_failures,
    }
    report = {
        "observed_at_unix": int(time.time()),
        "base_url": args.base_url,
        "bundle_dir": str(args.bundle_dir.resolve()),
        "browser": "Google Chrome headless / SwiftShader WebGL2",
        "viewport": [540, 960],
        "ready_ms": {
            "pointer": pointer_ready_ms,
            "touch": touch_ready_ms,
            "keyboard": keyboard_ready_ms,
            "reduced": reduced_ready_ms,
        },
        "checks": checks,
        "result": "PASS" if all(checks.values()) else "FAIL",
        "bundle_responses": responses,
        "cdp_transfers": cdp_transfers,
        "normal_empty_cache_resource_timing": normal_timing,
        "full_and_range_probe": full_range,
        "console_errors": console_errors,
        "page_errors": page_errors,
        "request_failures": request_failures,
        "engine_probes": {
            "pointer": normal_probe,
            "touch": touch_probe,
            "keyboard": keyboard_probe,
            "reduced": reduced_probe,
        },
        "vibration_calls": {
            "pointer": pointer_vibration,
            "touch": touch_vibration,
            "keyboard": keyboard_vibration,
            "reduced": reduced_vibration,
        },
        "states": {
            "pointer_entry": pointer_entry,
            "pointer_reject": pointer_reject,
            "pointer_legal": pointer_legal,
            "pointer_recovered": pointer_recovered,
            "pointer_restart": pointer_restart,
            "touch_reject": touch_reject,
            "touch_legal": touch_legal,
            "keyboard_reject": keyboard_reject,
            "keyboard_legal": keyboard_legal,
            "reduced_entry": reduced_entry,
            "reduced_legal": reduced_legal,
        },
    }
    report_path = args.output_dir / "web-acceptance.json"
    report_path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"ARROW_GO_V3_WEB_ACCEPTANCE={report['result']}")
    print(f"ARROW_GO_V3_WEB_REPORT={report_path}")
    return 0 if report["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
