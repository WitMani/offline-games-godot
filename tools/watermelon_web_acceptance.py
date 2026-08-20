#!/usr/bin/env python3
"""Real-browser acceptance probe for 2048 Balls physics and visible GAG art."""

from __future__ import annotations

import argparse
import json
import time
from pathlib import Path

from playwright.sync_api import TimeoutError as PlaywrightTimeoutError
from playwright.sync_api import sync_playwright


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("base_url")
    parser.add_argument("output_dir")
    parser.add_argument("--load-timeout-ms", type=int, default=60_000)
    args = parser.parse_args()

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    console_errors: list[str] = []
    page_errors: list[str] = []
    request_failures: list[str] = []
    responses: dict[str, dict[str, object]] = {}
    finished_requests: dict[str, int] = {}
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
        page = browser.new_page(viewport={"width": 540, "height": 960})
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
            lambda request: finished_requests.__setitem__(
                request.url, round((time.monotonic() - started_at) * 1000)
            ),
        )

        def remember_response(response) -> None:
            suffix = Path(response.url.split("?", 1)[0]).suffix.lower()
            if suffix in {".html", ".js", ".wasm", ".pck"}:
                responses[response.url] = {
                    "status": response.status,
                    "ok": response.ok,
                    "content_type": response.headers.get("content-type", ""),
                    "content_length": response.headers.get("content-length", ""),
                    "content_encoding": response.headers.get("content-encoding", ""),
                }

        page.on("response", remember_response)
        try:
            page.goto(
                args.base_url,
                wait_until="domcontentloaded",
                timeout=args.load_timeout_ms,
            )
            page.wait_for_function(
                "window.__gameAcceptance && "
                "window.__gameAcceptance.getState().ready === true",
                timeout=args.load_timeout_ms,
            )
        except PlaywrightTimeoutError as error:
            browser_state = page.evaluate(
                """() => {
                    const progress = document.getElementById('status-progress');
                    const notice = document.getElementById('status-notice');
                    return {
                        secure_context: window.isSecureContext,
                        document_ready_state: document.readyState,
                        engine_probe: window.__offlineGamesWebProbe || null,
                        acceptance_present: Boolean(window.__gameAcceptance),
                        progress: progress ? {
                            value: progress.value,
                            max: progress.max,
                            visible: getComputedStyle(progress).display !== 'none',
                        } : null,
                        notice: notice ? notice.innerText : '',
                    };
                }"""
            )
            page.screenshot(path=str(output_dir / "00-load-timeout.png"), full_page=True)
            timeout_report = {
                "observed_at_unix": int(time.time()),
                "base_url": args.base_url,
                "browser": "Google Chrome headless / SwiftShader WebGL2",
                "viewport": [540, 960],
                "load_timeout_ms": args.load_timeout_ms,
                "elapsed_ms": round((time.monotonic() - started_at) * 1000),
                "result": "TIMEOUT",
                "error": str(error),
                "browser_state": browser_state,
                "bundle_responses": responses,
                "finished_requests_ms": finished_requests,
                "console_errors": console_errors,
                "page_errors": page_errors,
                "request_failures": request_failures,
            }
            (output_dir / "web-acceptance-timeout.json").write_text(
                json.dumps(timeout_report, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            browser.close()
            print("WATERMELON_WEB_ACCEPTANCE=TIMEOUT")
            print(
                "WATERMELON_WEB_REPORT="
                f"{output_dir / 'web-acceptance-timeout.json'}"
            )
            return 2
        page.wait_for_timeout(800)
        home_state = page.evaluate("window.__gameAcceptance.getState()")
        secure_context = page.evaluate("window.isSecureContext")

        canvas = page.locator("canvas")
        box = canvas.bounding_box()
        if box is None:
            raise RuntimeError("Godot canvas did not expose a bounding box")

        # Catalog item three: left column, second row in the 540x960 design.
        page.mouse.click(box["x"] + 141, box["y"] + 521)
        page.wait_for_function(
            "window.__gameAcceptance.getState().game_id === 'watermelon'",
            timeout=15_000,
        )
        page.wait_for_timeout(900)
        entry_state = page.evaluate("window.__gameAcceptance.getState()")

        def release_at(x: float) -> None:
            page.mouse.move(box["x"] + 130, box["y"] + 500)
            page.mouse.down()
            page.mouse.move(box["x"] + x, box["y"] + 500, steps=8)
            page.mouse.up()

        release_at(337)
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.moves === 1",
            timeout=5_000,
        )
        page.wait_for_timeout(130)
        falling_state = page.evaluate("window.__gameAcceptance.getState()")
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.balls[0].position[1] > 640 && "
            "Math.abs(window.__gameAcceptance.getState().state.balls[0].velocity[1]) < 24",
            timeout=5_000,
        )
        settled_state = page.evaluate("window.__gameAcceptance.getState()")

        release_at(337)
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.moves === 2 && "
            "window.__gameAcceptance.getState().state.score >= 4 && "
            "window.__gameAcceptance.getState().state.highest_tier >= 2",
            timeout=8_000,
        )
        page.wait_for_timeout(160)
        merged_state = page.evaluate("window.__gameAcceptance.getState()")
        page.screenshot(path=str(output_dir / "10-web-merge.png"), full_page=True)

        page.keyboard.press("KeyR")
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.moves === 0 && "
            "window.__gameAcceptance.getState().state.balls.length === 0",
            timeout=5_000,
        )
        restart_state = page.evaluate("window.__gameAcceptance.getState()")
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
    entry = entry_state.get("state", {})
    falling = falling_state.get("state", {})
    merged = merged_state.get("state", {})
    restart = restart_state.get("state", {})
    first_falling_ball = falling.get("balls", [{}])[0]
    checks = {
        "secure_context": secure_context is True,
        "ready": bool(home_state.get("ready")),
        "catalog_14": home_state.get("catalog_size") == 14,
        "entry_free_physics_contract": "balls" in entry
        and "columns" not in entry
        and entry.get("target_value") == 256,
        "continuous_pointer_x": abs(first_falling_ball.get("position", [0])[0] - 337) < 2,
        "visible_falling_phase": 328 < first_falling_ball.get("position", [0, 0])[1] < 640,
        "settled_contact": settled_state.get("state", {}).get("balls", [{}])[0].get(
            "position", [0, 0]
        )[1]
        > 640,
        "equal_contact_merge": merged.get("moves") == 2
        and merged.get("score", 0) >= 4
        and merged.get("highest_tier", 0) >= 2
        and len(merged.get("balls", [])) == 1,
        "restart_preserves_best": restart.get("moves") == 0
        and restart.get("balls") == []
        and restart.get("best", 0) >= 4,
        "pck_loaded": bool(pck_responses)
        and all(details["ok"] for details in pck_responses.values()),
        "wasm_loaded": bool(wasm_responses)
        and all(details["ok"] for details in wasm_responses.values()),
        "runtime_errors_clear": not console_errors
        and not page_errors
        and not request_failures,
    }
    report = {
        "observed_at_unix": int(time.time()),
        "base_url": args.base_url,
        "browser": "Google Chrome headless / SwiftShader WebGL2",
        "viewport": [540, 960],
        "checks": checks,
        "result": "PASS" if all(checks.values()) else "FAIL",
        "bundle_responses": responses,
        "console_errors": console_errors,
        "page_errors": page_errors,
        "request_failures": request_failures,
        "entry_state": entry_state,
        "falling_state": falling_state,
        "settled_state": settled_state,
        "merged_state": merged_state,
        "restart_state": restart_state,
    }
    (output_dir / "web-acceptance.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"WATERMELON_WEB_ACCEPTANCE={report['result']}")
    print(f"WATERMELON_WEB_REPORT={output_dir / 'web-acceptance.json'}")
    return 0 if report["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
