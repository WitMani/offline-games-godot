#!/usr/bin/env python3
"""Fresh-browser acceptance for the frozen Classic 2048 Web candidate."""

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


def occupied(board: list[list[int]]) -> int:
    return sum(1 for row in board for value in row if int(value) > 0)


def snapshot_core(state: dict[str, Any]) -> dict[str, Any]:
    model = state.get("merge2048", {})
    return {
        key: model.get(key)
        for key in (
            "board",
            "score",
            "best",
            "moves",
            "won",
            "over",
            "keep_playing",
            "status",
            "rng_state",
        )
    }


def choose_swipe(state: dict[str, Any]) -> tuple[str, int]:
    board = state["board"]
    if any(int(board[y][x]) > 0 and x < 3 for y in range(4) for x in range(4)):
        return "right", 92
    return "left", -92


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

    def open_merge2048(page: Any, box: dict[str, float]) -> dict[str, Any]:
        page.mouse.click(box["x"] + 400, box["y"] + 453)
        page.wait_for_function(
            "window.__gameAcceptance.getState().game_id === 'merge2048'",
            timeout=15_000,
        )
        page.wait_for_timeout(250)
        return page.evaluate("window.__gameAcceptance.getState()")

    def perform_pointer_move(
        page: Any, box: dict[str, float], state: dict[str, Any]
    ) -> tuple[str, dict[str, Any]]:
        direction, delta_x = choose_swipe(state)
        before_moves = int(state["moves"])
        page.mouse.move(box["x"] + 270, box["y"] + 500)
        page.mouse.down()
        page.mouse.move(box["x"] + 270 + delta_x, box["y"] + 500, steps=8)
        page.mouse.up()
        page.wait_for_function(
            f"window.__gameAcceptance.getState().state.moves === {before_moves + 1}",
            timeout=5_000,
        )
        page.wait_for_timeout(170)
        return direction, page.evaluate("window.__gameAcceptance.getState()")

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
            viewport={"width": 540, "height": 960}, service_workers="block"
        )
        install_vibration_probe(normal_context)
        page = normal_context.new_page()
        observe(page, "normal")
        ready_ms = wait_ready(page)
        page.wait_for_timeout(500)
        home_state = page.evaluate("window.__gameAcceptance.getState()")
        secure_context = page.evaluate("window.isSecureContext")
        cross_origin_isolated = page.evaluate("window.crossOriginIsolated")
        normal_resource_timing = resource_timing(page)
        box = canvas_box(page)
        entry_state = open_merge2048(page, box)
        normal_direction, moved_state = perform_pointer_move(
            page, box, entry_state["state"]
        )
        normal_vibration_calls = page.evaluate("window.__vibrationCalls")
        normal_probe = page.evaluate("window.__offlineGamesWebProbe")
        page.screenshot(path=str(output_dir / "10-web-after-swipe.png"), full_page=True)

        expected_recovery = snapshot_core(moved_state["state"])
        page.wait_for_timeout(1_500)
        page.reload(wait_until="domcontentloaded", timeout=args.load_timeout_ms)
        page.wait_for_function(
            "window.__gameAcceptance && window.__gameAcceptance.getState().ready === true",
            timeout=args.load_timeout_ms,
        )
        page.wait_for_timeout(500)
        recovered_state = open_merge2048(page, canvas_box(page))
        recovered_core = snapshot_core(recovered_state["state"])
        page.screenshot(path=str(output_dir / "20-web-recovered.png"), full_page=True)
        page.keyboard.press("KeyR")
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.moves === 0 && "
            "window.__gameAcceptance.getState().state.score === 0",
            timeout=5_000,
        )
        restart_state = page.evaluate("window.__gameAcceptance.getState()")
        normal_context.close()

        reduced_context = browser.new_context(
            viewport={"width": 540, "height": 960},
            reduced_motion="reduce",
            service_workers="block",
        )
        install_vibration_probe(reduced_context)
        reduced_page = reduced_context.new_page()
        observe(reduced_page, "reduced")
        reduced_ready_ms = wait_ready(reduced_page)
        reduced_box = canvas_box(reduced_page)
        reduced_entry = open_merge2048(reduced_page, reduced_box)
        reduced_direction, reduced_moved = perform_pointer_move(
            reduced_page, reduced_box, reduced_entry["state"]
        )
        reduced_vibration_calls = reduced_page.evaluate("window.__vibrationCalls")
        reduced_probe = reduced_page.evaluate("window.__offlineGamesWebProbe")
        reduced_page.screenshot(
            path=str(output_dir / "30-web-reduced-motion.png"), full_page=True
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
    moved = moved_state["state"]
    restarted = restart_state["state"]
    reduced_entry_state = reduced_entry["state"]
    reduced_after = reduced_moved["state"]
    checks = {
        "secure_context": secure_context is True,
        "cross_origin_isolated": cross_origin_isolated is True,
        "ready": bool(home_state.get("ready")),
        "catalog_14": home_state.get("catalog_size") == 14,
        "entry_contract": len(entry.get("board", [])) == 4
        and occupied(entry["board"]) == 2
        and entry.get("target") == 2048
        and entry.get("score") == 0
        and entry.get("moves") == 0,
        "pointer_swipe": moved.get("moves") == 1
        and moved.get("board") != entry.get("board")
        and normal_direction in {"left", "right"},
        "normal_haptic_routed": len(normal_vibration_calls) > 0,
        "active_run_exact_recovery": recovered_core == expected_recovery,
        "restart_contract": restarted.get("moves") == 0
        and restarted.get("score") == 0
        and occupied(restarted.get("board", [])) == 2
        and restarted.get("best", 0) >= moved.get("best", 0),
        "reduced_preference_detected": reduced_entry_state.get("reduced_effects")
        is True,
        "reduced_rule_consequence": reduced_after.get("moves") == 1
        and reduced_after.get("board") != reduced_entry_state.get("board")
        and reduced_direction in {"left", "right"},
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
        "observed_at_unix": int(time.time()),
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
        "normal_direction": normal_direction,
        "normal_vibration_calls": normal_vibration_calls,
        "entry_state": entry_state,
        "moved_state": moved_state,
        "recovered_state": recovered_state,
        "restart_state": restart_state,
        "reduced_direction": reduced_direction,
        "reduced_vibration_calls": reduced_vibration_calls,
        "reduced_entry_state": reduced_entry,
        "reduced_moved_state": reduced_moved,
    }
    report_path = output_dir / "web-acceptance.json"
    report_path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"MERGE2048_WEB_ACCEPTANCE={report['result']}")
    print(f"MERGE2048_WEB_REPORT={report_path}")
    return 0 if report["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
