#!/usr/bin/env python3
"""Fresh-browser acceptance for the 2248 v4 mechanics and presentation paths."""

from __future__ import annotations

import argparse
import json
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
VIEWPORT = {"width": 540, "height": 960}
LOAD_BUDGET_MS = 15_000


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


def model_core(public_state: dict[str, Any]) -> dict[str, Any]:
    model = public_state.get("merge2248", {})
    return {
        key: model.get(key)
        for key in (
            "board",
            "board_encoding",
            "score",
            "score_label",
            "all_time",
            "all_time_label",
            "moves",
            "status",
            "mode",
            "height",
            "can_undo",
        )
    }


def choose_equal_pair(board: list[list[int]]) -> tuple[tuple[int, int], tuple[int, int]]:
    height = len(board)
    width = len(board[0])
    for y in range(height):
        for x in range(width):
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    if dx == 0 and dy == 0:
                        continue
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < width and 0 <= ny < height:
                        if int(board[y][x]) == int(board[ny][nx]):
                            return (x, y), (nx, ny)
    raise RuntimeError("The guaranteed opening pair was not present")


def design_point(box: dict[str, float], x: float, y: float) -> tuple[float, float]:
    return (
        box["x"] + x * box["width"] / 540.0,
        box["y"] + y * box["height"] / 960.0,
    )


def cell_point(
    box: dict[str, float], cell: tuple[int, int], height: int
) -> tuple[float, float]:
    x, y = cell
    return design_point(
        box,
        50.0 + (x + 0.5) * 440.0 / 5.0,
        224.0 + (y + 0.5) * 640.0 / float(height),
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
    responses: dict[str, dict[str, object]] = {}
    finished_requests_ms: dict[str, int] = {}

    def observe(page: Any, label: str, navigation_started: list[float]) -> None:
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
        page.on(
            "requestfinished",
            lambda request: finished_requests_ms.__setitem__(
                f"{label}: {request.url}",
                round((time.monotonic() - navigation_started[0]) * 1000),
            ),
        )

        def remember(response: Any) -> None:
            suffix = Path(response.url.split("?", 1)[0]).suffix.lower()
            if suffix in {".html", ".js", ".wasm", ".pck"}:
                responses[f"{label}: {response.url}"] = {
                    "status": response.status,
                    "ok": response.ok,
                    "content_type": response.headers.get("content-type", ""),
                    "content_length": response.headers.get("content-length", ""),
                    "content_encoding": response.headers.get("content-encoding", ""),
                    "cache_control": response.headers.get("cache-control", ""),
                }

        page.on("response", remember)

    def wait_ready(page: Any, navigation_started: list[float]) -> int:
        navigation_started[0] = time.monotonic()
        page.goto(args.base_url, wait_until="domcontentloaded", timeout=args.load_timeout_ms)
        page.wait_for_function(
            "window.__gameAcceptance && window.__gameAcceptance.getState().ready === true",
            timeout=args.load_timeout_ms,
        )
        return round((time.monotonic() - navigation_started[0]) * 1000)

    def canvas_box(page: Any) -> dict[str, float]:
        box = page.locator("canvas").bounding_box()
        if box is None:
            raise RuntimeError("Godot canvas did not expose a bounding box")
        return box

    def open_merge2248(page: Any, box: dict[str, float]) -> dict[str, Any]:
        # First catalog cartridge: left column, first row.
        px, py = design_point(box, 141, 453)
        page.mouse.click(px, py)
        page.wait_for_function(
            "window.__gameAcceptance.getState().game_id === 'merge2248'",
            timeout=15_000,
        )
        page.wait_for_timeout(300)
        return page.evaluate("window.__gameAcceptance.getState()")

    def perform_drag(
        page: Any, box: dict[str, float], public_state: dict[str, Any]
    ) -> tuple[dict[str, Any], dict[str, Any]]:
        board = public_state["board"]
        start, end = choose_equal_pair(board)
        start_point = cell_point(box, start, len(board))
        end_point = cell_point(box, end, len(board))
        before_moves = int(public_state["moves"])
        page.mouse.move(*start_point)
        page.mouse.down()
        page.mouse.move(*end_point, steps=8)
        page.mouse.up()
        page.wait_for_function(
            f"window.__gameAcceptance.getState().state.moves === {before_moves + 1}",
            timeout=5_000,
        )
        page.wait_for_timeout(180)
        return (
            {"start": list(start), "end": list(end), "power": int(board[start[1]][start[0]])},
            page.evaluate("window.__gameAcceptance.getState()"),
        )

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(
            headless=True,
            executable_path="/usr/bin/google-chrome",
            args=CHROME_ARGS,
        )

        normal_context = browser.new_context(viewport=VIEWPORT)
        install_vibration_probe(normal_context)
        normal_page = normal_context.new_page()
        normal_started = [time.monotonic()]
        observe(normal_page, "normal", normal_started)
        normal_ready_ms = wait_ready(normal_page, normal_started)
        normal_secure = normal_page.evaluate("window.isSecureContext")
        normal_box = canvas_box(normal_page)
        home_state = normal_page.evaluate("window.__gameAcceptance.getState()")
        entry = open_merge2248(normal_page, normal_box)
        pair, moved = perform_drag(normal_page, normal_box, entry["state"])
        normal_vibrations = normal_page.evaluate("window.__vibrationCalls")
        normal_page.screenshot(path=str(output_dir / "10-normal-after-drag.png"), full_page=True)

        normal_page.keyboard.press("KeyU")
        normal_page.wait_for_function(
            "window.__gameAcceptance.getState().state.moves === 0 && "
            "window.__gameAcceptance.getState().state.can_undo === false",
            timeout=5_000,
        )
        undone = normal_page.evaluate("window.__gameAcceptance.getState()")
        _, replayed = perform_drag(normal_page, normal_box, undone["state"])
        normal_page.wait_for_timeout(1_800)
        expected_recovery = model_core(replayed["state"])

        normal_started[0] = time.monotonic()
        normal_page.reload(wait_until="domcontentloaded", timeout=args.load_timeout_ms)
        normal_page.wait_for_function(
            "window.__gameAcceptance && window.__gameAcceptance.getState().ready === true",
            timeout=args.load_timeout_ms,
        )
        reload_box = canvas_box(normal_page)
        recovered = open_merge2248(normal_page, reload_box)
        normal_page.screenshot(path=str(output_dir / "20-recovered.png"), full_page=True)

        normal_page.keyboard.press("KeyR")
        normal_page.wait_for_function(
            "window.__gameAcceptance.getState().state.moves === 0 && "
            "window.__gameAcceptance.getState().state.score === '0'",
            timeout=5_000,
        )
        restarted = normal_page.evaluate("window.__gameAcceptance.getState()")
        normal_page.keyboard.press("KeyM")
        normal_page.wait_for_function(
            "window.__gameAcceptance.getState().state.mode === 'hard' && "
            "window.__gameAcceptance.getState().state.board.length === 6",
            timeout=5_000,
        )
        hard_mode = normal_page.evaluate("window.__gameAcceptance.getState()")
        normal_page.screenshot(path=str(output_dir / "30-hard-mode-cjk.png"), full_page=True)
        normal_probe = normal_page.evaluate("window.__offlineGamesWebProbe")
        normal_context.close()

        reduced_context = browser.new_context(viewport=VIEWPORT, reduced_motion="reduce")
        install_vibration_probe(reduced_context)
        reduced_page = reduced_context.new_page()
        reduced_started = [time.monotonic()]
        observe(reduced_page, "reduced", reduced_started)
        reduced_ready_ms = wait_ready(reduced_page, reduced_started)
        reduced_secure = reduced_page.evaluate("window.isSecureContext")
        reduced_box = canvas_box(reduced_page)
        reduced_entry = open_merge2248(reduced_page, reduced_box)
        reduced_pair, reduced_moved = perform_drag(
            reduced_page, reduced_box, reduced_entry["state"]
        )
        reduced_vibrations = reduced_page.evaluate("window.__vibrationCalls")
        reduced_probe = reduced_page.evaluate("window.__offlineGamesWebProbe")
        reduced_page.screenshot(
            path=str(output_dir / "40-reduced-motion.png"), full_page=True
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
    entry_state = entry["state"]
    moved_state = moved["state"]
    undone_state = undone["state"]
    replayed_state = replayed["state"]
    recovered_state = recovered["state"]
    restarted_state = restarted["state"]
    hard_state = hard_mode["state"]
    reduced_entry_state = reduced_entry["state"]
    reduced_after_state = reduced_moved["state"]
    checks = {
        "secure_context": normal_secure is True and reduced_secure is True,
        "ready_budget": normal_ready_ms <= LOAD_BUDGET_MS
        and reduced_ready_ms <= LOAD_BUDGET_MS,
        "catalog_14": home_state.get("catalog_size") == 14,
        "entry_contract": len(entry_state.get("board", [])) == 8
        and all(len(row) == 5 for row in entry_state["board"])
        and entry_state.get("mode") == "easy"
        and entry_state.get("mode_evidence_verified") is True
        and entry_state.get("score") == "0"
        and entry_state.get("moves") == 0
        and entry_state.get("can_undo") is False
        and entry_state.get("reduced_effects") is False
        and entry_state.get("merge2248", {}).get("board_encoding")
        == "power_of_two_exponents",
        "normal_real_drag": moved_state.get("moves") == 1
        and moved_state.get("score") != "0"
        and moved_state.get("board") != entry_state.get("board")
        and moved_state.get("can_undo") is True,
        "normal_haptic_routed": len(normal_vibrations) >= 3,
        "undo_exact_rule_state": undone_state.get("board") == entry_state.get("board")
        and undone_state.get("score") == "0"
        and undone_state.get("moves") == 0
        and undone_state.get("can_undo") is False
        and int(undone_state.get("all_time", "0"))
        >= int(moved_state.get("score", "0")),
        "undo_rng_replay_exact": model_core(replayed_state) == model_core(moved_state),
        "reload_recovery": model_core(recovered_state) == expected_recovery,
        "restart_contract": restarted_state.get("score") == "0"
        and restarted_state.get("moves") == 0
        and restarted_state.get("mode") == "easy"
        and int(restarted_state.get("all_time", "0"))
        >= int(moved_state.get("score", "0")),
        "hard_mode_contract": hard_state.get("mode") == "hard"
        and hard_state.get("mode_evidence_verified") is True
        and len(hard_state.get("board", [])) == 6
        and all(len(row) == 5 for row in hard_state.get("board", [])),
        "reduced_preference_detected": reduced_entry_state.get("reduced_effects") is True,
        "reduced_rule_consequence": model_core(reduced_after_state)
        == model_core(moved_state)
        and reduced_pair == pair,
        "reduced_haptic_suppressed": reduced_vibrations == [],
        "fingerprinted_pck_loaded": bool(pck_responses)
        and all(details["ok"] for details in pck_responses.values()),
        "fingerprinted_wasm_loaded": bool(wasm_responses)
        and all(details["ok"] for details in wasm_responses.values()),
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
        "viewport": list(VIEWPORT.values()),
        "load_budget_ms": LOAD_BUDGET_MS,
        "normal_ready_ms": normal_ready_ms,
        "reduced_ready_ms": reduced_ready_ms,
        "checks": checks,
        "result": "PASS" if all(checks.values()) else "FAIL",
        "bundle_responses": responses,
        "finished_requests_ms": finished_requests_ms,
        "console_errors": console_errors,
        "page_errors": page_errors,
        "request_failures": request_failures,
        "normal_probe": normal_probe,
        "reduced_probe": reduced_probe,
        "normal_pair": pair,
        "normal_vibration_calls": normal_vibrations,
        "entry_state": entry,
        "moved_state": moved,
        "undone_state": undone,
        "replayed_state": replayed,
        "recovered_state": recovered,
        "restart_state": restarted,
        "hard_mode_state": hard_mode,
        "reduced_pair": reduced_pair,
        "reduced_vibration_calls": reduced_vibrations,
        "reduced_entry_state": reduced_entry,
        "reduced_moved_state": reduced_moved,
    }
    report_path = output_dir / "web-acceptance.json"
    report_path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"MERGE2248_WEB_ACCEPTANCE={report['result']}")
    print(f"MERGE2248_WEB_REPORT={report_path}")
    return 0 if report["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
