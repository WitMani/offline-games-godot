#!/usr/bin/env python3
"""Real-browser acceptance for Amaze v3 mechanics, GAG art and Web recovery."""

from __future__ import annotations

import argparse
import json
import re
import time
from pathlib import Path
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from playwright.sync_api import Browser, Page, Response, sync_playwright


WATCHED_SUFFIXES = {".html", ".js", ".wasm", ".pck"}


def with_query(url: str, **values: str) -> str:
    parts = urlsplit(url)
    query = dict(parse_qsl(parts.query, keep_blank_values=True))
    query.update(values)
    return urlunsplit((parts.scheme, parts.netloc, parts.path, urlencode(query), parts.fragment))


def install_vibration_probe(page: Page) -> None:
    page.add_init_script(
        """
        window.__nativeVibrateCalls = [];
        try {
          Object.defineProperty(Navigator.prototype, 'vibrate', {
            configurable: true,
            value: function(payload) {
              window.__nativeVibrateCalls.push(JSON.parse(JSON.stringify(payload)));
              return true;
            }
          });
        } catch (error) {
          navigator.vibrate = function(payload) {
            window.__nativeVibrateCalls.push(JSON.parse(JSON.stringify(payload)));
            return true;
          };
        }
        """
    )


def wait_ready(page: Page) -> None:
    page.wait_for_function(
        "window.__gameAcceptance && window.__gameAcceptance.getState().ready === true",
        timeout=60_000,
    )
    page.wait_for_timeout(500)


def browser_features(page: Page) -> dict[str, object]:
    return page.evaluate(
        """
        (() => {
          let storage = false;
          try {
            const key = '__amazeAcceptanceStorageProbe';
            localStorage.setItem(key, '1');
            storage = localStorage.getItem(key) === '1';
            localStorage.removeItem(key);
          } catch (error) {}
          const probe = document.createElement('canvas');
          return {
            secure_context: window.isSecureContext,
            webassembly: typeof WebAssembly === 'object',
            webgl2: Boolean(probe.getContext('webgl2')),
            local_storage: storage,
            cross_origin_isolated: window.crossOriginIsolated,
            shared_array_buffer: typeof SharedArrayBuffer !== 'undefined',
            service_worker_controller: Boolean(
              navigator.serviceWorker && navigator.serviceWorker.controller
            )
          };
        })()
        """
    )


def open_amaze(page: Page) -> dict[str, object]:
    canvas = page.locator("canvas")
    box = canvas.bounding_box()
    if box is None:
        raise RuntimeError("Godot canvas did not expose a bounding box")
    page.mouse.click(box["x"] + 400, box["y"] + 858)
    page.wait_for_function(
        "window.__gameAcceptance.getState().game_id === 'amaze'",
        timeout=15_000,
    )
    page.wait_for_timeout(180)
    return page.evaluate("window.__gameAcceptance.getState()")


def pointer_swipe(page: Page, start: tuple[float, float], end: tuple[float, float]) -> None:
    box = page.locator("canvas").bounding_box()
    if box is None:
        raise RuntimeError("Godot canvas disappeared")
    page.mouse.move(box["x"] + start[0], box["y"] + start[1])
    page.mouse.down()
    page.mouse.move(box["x"] + end[0], box["y"] + end[1], steps=7)
    page.mouse.up()


def resource_entries(page: Page) -> list[dict[str, object]]:
    return page.evaluate(
        "performance.getEntriesByType('resource').map(e => ({name:e.name, "
        "transferSize:e.transferSize, encodedBodySize:e.encodedBodySize, "
        "decodedBodySize:e.decodedBodySize}))"
    )


def collect_transfer(
    response: Response, performance_entries: list[dict[str, object]]
) -> dict[str, object]:
    # The entry URL may be normalized with an HTTP redirect. Playwright does
    # not expose redirect bodies, while binary resources must remain readable
    # so we can prove their complete transfer.
    try:
        body = response.body()
        body_available = True
    except Exception as error:  # Playwright raises for body-less redirects.
        body = b""
        body_available = False
        body_error = str(error)
    matching_entry = next(
        (entry for entry in performance_entries if entry.get("name") == response.url),
        {},
    )
    expected = int(response.headers.get("content-length", "0") or 0)
    encoded = int(matching_entry.get("encodedBodySize", 0) or 0)
    response_body_full = response.ok and body_available and len(body) > 0 and (
        expected == 0 or len(body) == expected
    )
    performance_full = response.ok and expected > 0 and encoded == expected
    return {
        "status": response.status,
        "ok": response.ok,
        "content_type": response.headers.get("content-type", ""),
        "content_length": response.headers.get("content-length", ""),
        "headers": {
            name: response.headers.get(name, "")
            for name in (
                "content-type",
                "content-length",
                "cache-control",
                "accept-ranges",
                "last-modified",
                "cross-origin-opener-policy",
                "cross-origin-embedder-policy",
            )
        },
        "body_bytes": len(body),
        "body_available": body_available,
        "body_error": body_error if not body_available else "",
        "performance_entry": matching_entry,
        "full_transfer_proof": "response_body"
        if response_body_full
        else ("performance_encoded_body" if performance_full else "none"),
        "full_transfer": response_body_full or performance_full,
    }


def exercise_normal(
    browser: Browser,
    base_url: str,
    output_dir: Path,
    console_errors: list[str],
    page_errors: list[str],
) -> dict[str, object]:
    context = browser.new_context(viewport={"width": 540, "height": 960})
    page = context.new_page()
    install_vibration_probe(page)
    responses: dict[str, Response] = {}
    page.on(
        "console",
        lambda message: console_errors.append(message.text)
        if message.type == "error"
        else None,
    )
    page.on("pageerror", lambda error: page_errors.append(str(error)))

    def remember_response(response: Response) -> None:
        suffix = Path(response.url.split("?", 1)[0]).suffix.lower()
        if response.request.resource_type == "document" or suffix in WATCHED_SUFFIXES:
            responses[response.url] = response

    page.on("response", remember_response)
    page.goto(
        with_query(base_url, audit="amaze-v3-clean"),
        wait_until="domcontentloaded",
        timeout=60_000,
    )
    wait_ready(page)
    feature_probe = browser_features(page)
    home_state = page.evaluate("window.__gameAcceptance.getState()")
    entry_state = open_amaze(page)

    # Real pointer long roll, then a real keyboard revisit across painted cells.
    pointer_swipe(page, (97, 623), (97, 470))
    page.wait_for_function(
        "window.__gameAcceptance.getState().state.moves === 1",
        timeout=5_000,
    )
    pointer_long_state = page.evaluate("window.__gameAcceptance.getState()")
    page.keyboard.press("ArrowDown")
    page.wait_for_function(
        "window.__gameAcceptance.getState().state.moves === 2",
        timeout=5_000,
    )
    keyboard_revisit_state = page.evaluate("window.__gameAcceptance.getState()")

    # Restart must recover the same topology before the full loop is replayed.
    page.keyboard.press("KeyR")
    page.wait_for_function(
        "window.__gameAcceptance.getState().state.moves === 0 && "
        "window.__gameAcceptance.getState().state.player[1] === 4",
        timeout=5_000,
    )
    restart_state = page.evaluate("window.__gameAcceptance.getState()")
    page.keyboard.press("ArrowUp")
    page.wait_for_function(
        "window.__gameAcceptance.getState().state.moves === 1",
        timeout=5_000,
    )
    page.keyboard.press("ArrowRight")
    page.wait_for_function(
        "window.__gameAcceptance.getState().state.status === 'won'",
        timeout=5_000,
    )
    page.wait_for_timeout(1_050)
    complete_state = page.evaluate("window.__gameAcceptance.getState()")
    normal_vibration_calls = page.evaluate("window.__nativeVibrateCalls")
    page.screenshot(path=str(output_dir / "web-complete.png"), full_page=True)
    # Read binary bodies before reload. Chromium may evict a large WASM body
    # from the inspector cache once the document is navigated away from.
    initial_performance_entries = resource_entries(page)
    initial_transfers = {
        url: collect_transfer(response, initial_performance_entries)
        for url, response in responses.items()
    }
    responses.clear()

    # Reload starts at the catalog, then opening Amaze must restore the won state
    # from its replay-validated checkpoint. No private test hook is used.
    page.reload(wait_until="domcontentloaded", timeout=60_000)
    wait_ready(page)
    reload_home_state = page.evaluate("window.__gameAcceptance.getState()")
    reloaded_state = open_amaze(page)
    page.wait_for_function(
        "window.__gameAcceptance.getState().amaze_checkpoint_restored === true && "
        "window.__gameAcceptance.getState().state.status === 'won'",
        timeout=5_000,
    )
    reloaded_state = page.evaluate("window.__gameAcceptance.getState()")
    page.screenshot(path=str(output_dir / "web-reloaded.png"), full_page=True)
    page.keyboard.press("KeyR")
    page.wait_for_function(
        "window.__gameAcceptance.getState().state.status === 'playing' && "
        "window.__gameAcceptance.getState().state.moves === 0",
        timeout=5_000,
    )
    recovered_restart_state = page.evaluate("window.__gameAcceptance.getState()")
    web_probe = page.evaluate("window.__offlineGamesWebProbe || {}")
    performance_entries = resource_entries(page)
    result = {
        "home_state": home_state,
        "entry_state": entry_state,
        "pointer_long_state": pointer_long_state,
        "keyboard_revisit_state": keyboard_revisit_state,
        "restart_state": restart_state,
        "complete_state": complete_state,
        "reload_home_state": reload_home_state,
        "reloaded_state": reloaded_state,
        "recovered_restart_state": recovered_restart_state,
        "normal_vibration_calls": normal_vibration_calls,
        "web_probe": web_probe,
        "browser_features": feature_probe,
        "performance_entries_after_reload": performance_entries,
        "initial_transfers": initial_transfers,
        "reload_transfers": {
            url: collect_transfer(response, performance_entries)
            for url, response in responses.items()
        },
    }
    context.close()
    return result


def exercise_reduced(browser: Browser, base_url: str, output_dir: Path) -> dict[str, object]:
    context = browser.new_context(viewport={"width": 540, "height": 960})
    page = context.new_page()
    install_vibration_probe(page)
    page.goto(
        with_query(
            base_url,
            reduced_effects="1",
            audit="amaze-v3-reduced",
        ),
        wait_until="domcontentloaded",
        timeout=60_000,
    )
    wait_ready(page)
    entry_state = open_amaze(page)
    pointer_swipe(page, (97, 623), (97, 470))
    page.wait_for_function(
        "window.__gameAcceptance.getState().state.moves === 1",
        timeout=5_000,
    )
    page.wait_for_timeout(180)
    action_state = page.evaluate("window.__gameAcceptance.getState()")
    vibration_calls = page.evaluate("window.__nativeVibrateCalls")
    bridge_haptics = page.evaluate("window.__offlineGamesHaptics")
    page.screenshot(path=str(output_dir / "web-reduced.png"), full_page=True)
    context.close()
    return {
        "entry_state": entry_state,
        "action_state": action_state,
        "native_vibration_calls": vibration_calls,
        "bridge_haptics": bridge_haptics,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("base_url")
    parser.add_argument("output_dir")
    args = parser.parse_args()
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    console_errors: list[str] = []
    page_errors: list[str] = []

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
        normal = exercise_normal(
            browser, args.base_url, output_dir, console_errors, page_errors
        )
        reduced = exercise_reduced(browser, args.base_url, output_dir)
        browser.close()

    transfers = normal["initial_transfers"]

    pck_transfers = {
        url: details for url, details in transfers.items() if url.split("?", 1)[0].endswith(".pck")
    }
    wasm_transfers = {
        url: details for url, details in transfers.items() if url.split("?", 1)[0].endswith(".wasm")
    }
    entry = normal["entry_state"]
    pointer = normal["pointer_long_state"]
    revisit = normal["keyboard_revisit_state"]
    complete = normal["complete_state"]
    reloaded = normal["reloaded_state"]
    reduced_action = reduced["action_state"]
    features = normal["browser_features"]
    fingerprint_pattern = re.compile(r"index\.[0-9a-f]{12}\.(?:js|wasm|pck)$")
    fingerprinted_urls = [
        url
        for url in transfers
        if fingerprint_pattern.fullmatch(Path(urlsplit(url).path).name)
    ]
    reload_documents = [
        details
        for url, details in normal["reload_transfers"].items()
        if Path(urlsplit(url).path).suffix.lower() in {"", ".html"}
    ]
    checks = {
        "ready": bool(normal["home_state"].get("ready")),
        "catalog_14": normal["home_state"].get("catalog_size") == 14,
        "secure_context": features.get("secure_context") is True,
        "webassembly_available": features.get("webassembly") is True,
        "webgl2_available": features.get("webgl2") is True,
        "local_storage_available": features.get("local_storage") is True,
        "fingerprinted_bundle": len(fingerprinted_urls) == 3
        and {Path(urlsplit(url).path).suffix.lower() for url in fingerprinted_urls}
        == {".js", ".wasm", ".pck"},
        "entrypoint_revalidated": bool(reload_documents)
        and all(details["status"] in (200, 304) for details in reload_documents),
        "entry_model": entry.get("state", {}).get("rules_version") == "amaze-stage0-v2",
        "gag_signature_declared": entry.get("presentation", {}).get("signature_visible")
        == "stable_player_pod"
        and entry.get("presentation", {}).get("gag_assets")
        == [
            "res://assets/art/catalog/path_games/gag/amaze_paint_pod_gag_v2.png",
            "res://assets/audio/catalog/path_games/gag/amaze_wet_corridor_roll_gag_v2.ogg",
        ],
        "pointer_long_roll": pointer.get("state", {}).get("last_traversal")
        == [[0, 3], [0, 2], [0, 1], [0, 0]],
        "keyboard_revisit": revisit.get("state", {}).get("player") == [0, 4]
        and revisit.get("state", {}).get("painted_count") == 5
        and revisit.get("state", {}).get("moves") == 2,
        "restart": normal["restart_state"].get("state", {}).get("moves") == 0
        and normal["restart_state"].get("state", {}).get("painted_count") == 1,
        "completion": complete.get("state", {}).get("status") == "won"
        and complete.get("state", {}).get("painted_count") == 9,
        "reload_recovery": reloaded.get("amaze_checkpoint_restored") is True
        and reloaded.get("state", {}).get("status") == "won"
        and reloaded.get("state", {}).get("moves") == 2,
        "post_reload_restart": normal["recovered_restart_state"].get("state", {}).get("status")
        == "playing"
        and normal["recovered_restart_state"].get("state", {}).get("moves") == 0,
        "normal_haptic_emitted": complete.get("effects", {}).get("haptic_emitted", 0) > 0
        and len(normal["normal_vibration_calls"]) > 0,
        "reduced_requested": reduced["entry_state"].get("effects", {}).get("reduced") is True,
        "reduced_state_settled": reduced_action.get("state", {}).get("player") == [0, 0]
        and reduced_action.get("state", {}).get("painted_count") == 5,
        "reduced_haptic_suppressed": reduced_action.get("effects", {}).get("haptic_emitted") == 0
        and reduced_action.get("effects", {}).get("haptic_suppressed", 0) > 0
        and not reduced["native_vibration_calls"],
        "pck_full_transfer": bool(pck_transfers)
        and all(details["full_transfer"] for details in pck_transfers.values()),
        "wasm_full_transfer": bool(wasm_transfers)
        and all(details["full_transfer"] for details in wasm_transfers.values()),
        "runtime_error_clear": not normal["web_probe"].get("error"),
        "console_error_clear": not console_errors and not page_errors,
    }
    report = {
        "observed_at_unix": int(time.time()),
        "base_url": args.base_url,
        "checks": checks,
        "result": "PASS" if all(checks.values()) else "FAIL",
        "bundle_transfers": transfers,
        "console_errors": console_errors,
        "page_errors": page_errors,
        "normal": normal,
        "reduced": reduced,
    }
    (output_dir / "web-acceptance.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"AMAZE_WEB_ACCEPTANCE={report['result']}")
    print(f"AMAZE_WEB_REPORT={output_dir / 'web-acceptance.json'}")
    return 0 if report["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
