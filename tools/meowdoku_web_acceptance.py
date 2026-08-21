#!/usr/bin/env python3
"""Real Chrome probe for Meowdoku input, recovery, full loop, and Web bundle."""

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
        context = browser.new_context(viewport={"width": 540, "height": 960})
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
            lambda request: finished_requests.__setitem__(
                request.url, round((time.monotonic() - started_at) * 1000)
            ),
        )

        def remember_response(response) -> None:
            suffix = Path(response.url.split("?", 1)[0]).suffix.lower()
            if suffix in {".html", ".js", ".wasm", ".pck"}:
                # Preserve the cold-load response. A later reload may be a
                # valid conditional 304, but it must not hide the original
                # transferred byte count and MIME/header evidence.
                responses.setdefault(response.url, {
                    "status": response.status,
                    "ok": response.ok,
                    "content_type": response.headers.get("content-type", ""),
                    "content_length": response.headers.get("content-length", ""),
                    "content_encoding": response.headers.get("content-encoding", ""),
                    "cache_control": response.headers.get("cache-control", ""),
                    "cross_origin_opener_policy": response.headers.get(
                        "cross-origin-opener-policy", ""
                    ),
                    "cross_origin_embedder_policy": response.headers.get(
                        "cross-origin-embedder-policy", ""
                    ),
                })

        page.on("response", remember_response)

        def wait_ready() -> None:
            page.wait_for_function(
                "window.__gameAcceptance && "
                "window.__gameAcceptance.getState().ready === true",
                timeout=args.load_timeout_ms,
            )

        try:
            page.goto(
                args.base_url,
                wait_until="domcontentloaded",
                timeout=args.load_timeout_ms,
            )
            wait_ready()
        except PlaywrightTimeoutError as error:
            page.screenshot(path=str(output_dir / "00-load-timeout.png"), full_page=True)
            report = {
                "result": "TIMEOUT",
                "base_url": args.base_url,
                "error": str(error),
                "bundle_responses": responses,
                "console_errors": console_errors,
                "page_errors": page_errors,
                "request_failures": request_failures,
            }
            (output_dir / "web-acceptance-timeout.json").write_text(
                json.dumps(report, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            browser.close()
            print("MEOWDOKU_WEB_ACCEPTANCE=TIMEOUT")
            return 2

        page.evaluate(
            "window.localStorage.removeItem('offline-games.meowdoku.v3.checkpoint')"
        )
        home_state = page.evaluate("window.__gameAcceptance.getState()")
        secure_context = page.evaluate("window.isSecureContext")
        webassembly = page.evaluate("typeof WebAssembly === 'object'")

        def canvas_box() -> dict[str, float]:
            box = page.locator("canvas").bounding_box()
            if box is None:
                raise RuntimeError("Godot canvas did not expose a bounding box")
            return box

        def open_meowdoku() -> None:
            box = canvas_box()
            # Catalog item four: right column, second row.
            page.mouse.click(box["x"] + 399, box["y"] + 521)
            page.wait_for_function(
                "window.__gameAcceptance.getState().game_id === 'meowdoku'",
                timeout=15_000,
            )
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.puzzle_id === 'notebook_5'",
                timeout=5_000,
            )

        def cell_point(x: int, y: int) -> tuple[float, float]:
            box = canvas_box()
            cell = 444.0 / 5.0
            return (
                box["x"] + 48.0 + (x + 0.5) * cell,
                box["y"] + 244.0 + (y + 0.5) * cell,
            )

        def double_cell(x: int, y: int) -> None:
            px, py = cell_point(x, y)
            page.mouse.dblclick(px, py, delay=70)

        open_meowdoku()
        page.wait_for_timeout(500)
        entry_state = page.evaluate("window.__gameAcceptance.getState()")

        # Pointer single-action selection followed by same-cell mark.
        center = cell_point(2, 2)
        page.mouse.click(*center)
        page.wait_for_function(
            "JSON.stringify(window.__gameAcceptance.getState().state.selected) === '[2,2]'",
            timeout=5_000,
        )
        selected_state = page.evaluate("window.__gameAcceptance.getState()")
        # Cross the platform double-click window so this remains a second
        # deliberate single action, rather than the documented cat gesture.
        page.wait_for_timeout(650)
        page.mouse.click(*center)
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.manual_marks.some(c => c[0] === 2 && c[1] === 2)",
            timeout=5_000,
        )
        marked_state = page.evaluate("window.__gameAcceptance.getState()")
        page.keyboard.press("Delete")
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.manual_marks.length === 0",
            timeout=5_000,
        )

        # Real double pointer action places the first solution cat at (4, 0).
        double_cell(4, 0)
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.placed === 1",
            timeout=5_000,
        )
        page.wait_for_timeout(100)
        placed_state = page.evaluate("window.__gameAcceptance.getState()")
        page.screenshot(path=str(output_dir / "10-web-cat-impact.png"), full_page=True)

        # Reload, reopen, and prove the localStorage-backed checkpoint recovered.
        page.reload(wait_until="domcontentloaded", timeout=args.load_timeout_ms)
        wait_ready()
        open_meowdoku()
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.placed === 1",
            timeout=8_000,
        )
        recovered_state = page.evaluate("window.__gameAcceptance.getState()")

        # Common keyboard restart path clears the recovered state.
        page.keyboard.press("KeyR")
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.placed === 0 && "
            "window.__gameAcceptance.getState().state.hearts === 3",
            timeout=5_000,
        )
        restarted_state = page.evaluate("window.__gameAcceptance.getState()")

        # Three wrong double-actions at (0, 0) exhaust hearts and lock play.
        for expected_hearts in (2, 1, 0):
            double_cell(0, 0)
            page.wait_for_function(
                f"window.__gameAcceptance.getState().state.hearts === {expected_hearts}",
                timeout=5_000,
            )
        lost_state = page.evaluate("window.__gameAcceptance.getState()")
        page.wait_for_timeout(950)
        page.screenshot(path=str(output_dir / "20-web-loss.png"), full_page=True)

        page.keyboard.press("KeyR")
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.status === 'playing' && "
            "window.__gameAcceptance.getState().state.hearts === 3",
            timeout=5_000,
        )

        # Finish the deterministic authored fixture through real pointer actions.
        for index, (x, y) in enumerate(((4, 0), (2, 1), (0, 2), (3, 3), (1, 4)), 1):
            double_cell(x, y)
            page.wait_for_function(
                f"window.__gameAcceptance.getState().state.placed === {index}",
                timeout=5_000,
            )
        page.wait_for_function(
            "window.__gameAcceptance.getState().state.status === 'won'",
            timeout=5_000,
        )
        completed_state = page.evaluate("window.__gameAcceptance.getState()")
        page.wait_for_timeout(950)
        page.screenshot(path=str(output_dir / "30-web-complete.png"), full_page=True)
        canvas_count = page.locator("canvas").count()
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
    selected = selected_state.get("state", {})
    marked = marked_state.get("state", {})
    placed = placed_state.get("state", {})
    recovered = recovered_state.get("state", {})
    restarted = restarted_state.get("state", {})
    lost = lost_state.get("state", {})
    completed = completed_state.get("state", {})
    checks = {
        "secure_context": secure_context is True,
        "webassembly": webassembly is True,
        "single_canvas": canvas_count == 1,
        "ready": bool(home_state.get("ready")),
        "catalog_14": home_state.get("catalog_size") == 14,
        "entry_region_contract": entry.get("puzzle_id") == "notebook_5"
        and entry.get("size") == 5
        and entry.get("required") == 5
        and "board" not in entry
        and "solution" not in entry,
        "pointer_selection": selected.get("selected") == [2, 2]
        and selected.get("placed") == 0,
        "pointer_mark_and_keyboard_erase": [2, 2] in marked.get("manual_marks", []),
        "double_action_cat": placed.get("placed") == 1
        and [4, 0] in placed.get("cats", []),
        "reload_recovery": recovered.get("placed") == 1
        and [4, 0] in recovered.get("cats", []),
        "restart": restarted.get("placed") == 0
        and restarted.get("hearts") == 3
        and restarted.get("status") == "playing",
        "failure_loop": lost.get("hearts") == 0
        and lost.get("status") == "lost"
        and lost.get("placed") == 0
        and lost.get("moves") == 0
        and lost.get("manual_marks") == [],
        "completion_loop": completed.get("status") == "won"
        and completed.get("placed") == completed.get("required") == 5,
        "pck_loaded": bool(pck_responses)
        and all(details["ok"] for details in pck_responses.values()),
        "wasm_loaded": bool(wasm_responses)
        and all(details["ok"] for details in wasm_responses.values()),
        "pck_transfer_recorded": all(
            url in finished_requests and bool(details.get("content_length"))
            for url, details in pck_responses.items()
        ),
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
        "finished_requests_ms": finished_requests,
        "console_errors": console_errors,
        "page_errors": page_errors,
        "request_failures": request_failures,
        "entry_state": entry_state,
        "selected_state": selected_state,
        "marked_state": marked_state,
        "placed_state": placed_state,
        "recovered_state": recovered_state,
        "restarted_state": restarted_state,
        "lost_state": lost_state,
        "completed_state": completed_state,
    }
    report_path = output_dir / "web-acceptance.json"
    report_path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"MEOWDOKU_WEB_ACCEPTANCE={report['result']}")
    print(f"MEOWDOKU_WEB_REPORT={report_path}")
    return 0 if report["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
