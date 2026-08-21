#!/usr/bin/env python3
"""Real-browser acceptance for the isolated Sudoku v3 candidate."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import time
import urllib.request
from pathlib import Path

from playwright.sync_api import TimeoutError as PlaywrightTimeoutError
from playwright.sync_api import sync_playwright


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def bundle_manifest(bundle_dir: Path) -> dict[str, object]:
    html = (bundle_dir / "index.html").read_text("utf-8")
    match = re.search(r"const GODOT_CONFIG = (\{.*?\});", html, re.S)
    if match is None:
        raise RuntimeError("fingerprinted index.html has no GODOT_CONFIG")
    config = json.loads(match.group(1))
    pack = str(config["mainPack"])
    executable = str(config["executable"])
    required = [
        "index.html",
        f"{executable}.js",
        f"{executable}.wasm",
        pack,
    ]
    missing = [name for name in required if not (bundle_dir / name).is_file()]
    if missing:
        raise RuntimeError(f"bundle is incomplete: {missing}")
    return {
        "executable": executable,
        "main_pack": pack,
        "required_files": {
            name: {
                "bytes": (bundle_dir / name).stat().st_size,
                "sha256": sha256(bundle_dir / name),
            }
            for name in required
        },
    }


def range_probe(url: str) -> dict[str, object]:
    request = urllib.request.Request(
        url,
        headers={"Range": "bytes=0-1", "Accept-Encoding": "identity"},
    )
    started = time.monotonic()
    with urllib.request.urlopen(request, timeout=30) as response:
        payload = response.read()
        return {
            "url": url,
            "status": response.status,
            "bytes": len(payload),
            "content_range": response.headers.get("Content-Range", ""),
            "accept_ranges": response.headers.get("Accept-Ranges", ""),
            "cache_control": response.headers.get("Cache-Control", ""),
            "elapsed_ms": round((time.monotonic() - started) * 1000),
        }


def first_editable(given: list[list[int]], excluded: set[tuple[int, int]] | None = None) -> tuple[int, int]:
    excluded = excluded or set()
    for y, row in enumerate(given):
        for x, value in enumerate(row):
            if value == 0 and (x, y) not in excluded:
                return x, y
    raise RuntimeError("Sudoku puzzle has no editable cell")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("base_url")
    parser.add_argument("bundle_dir", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--load-timeout-ms", type=int, default=90_000)
    args = parser.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)
    manifest = bundle_manifest(args.bundle_dir.resolve())
    console_errors: list[str] = []
    page_errors: list[str] = []
    request_failures: list[str] = []
    responses: dict[str, dict[str, object]] = {}
    finished_requests_ms: dict[str, int] = {}
    started_at = time.monotonic()

    def remember_response(response) -> None:
        clean_url = response.url.split("?", 1)[0]
        base_url = args.base_url.split("?", 1)[0].rstrip("/")
        suffix = Path(clean_url).suffix.lower()
        if suffix in {".html", ".js", ".wasm", ".pck"} or clean_url.rstrip("/") == base_url:
            responses[response.url] = {
                "status": response.status,
                "ok": response.ok,
                "content_type": response.headers.get("content-type", ""),
                "content_length": response.headers.get("content-length", ""),
                "content_encoding": response.headers.get("content-encoding", ""),
                "cache_control": response.headers.get("cache-control", ""),
                "cross_origin_opener_policy": response.headers.get("cross-origin-opener-policy", ""),
                "cross_origin_embedder_policy": response.headers.get("cross-origin-embedder-policy", ""),
            }

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
        page.on("console", lambda message: console_errors.append(message.text) if message.type == "error" else None)
        page.on("pageerror", lambda error: page_errors.append(str(error)))
        page.on("requestfailed", lambda request: request_failures.append(request.url))
        page.on(
            "requestfinished",
            lambda request: finished_requests_ms.__setitem__(
                request.url, round((time.monotonic() - started_at) * 1000)
            ),
        )
        page.on("response", remember_response)

        try:
            page.goto(f"{args.base_url}?audit=sudoku-v3", wait_until="domcontentloaded", timeout=args.load_timeout_ms)
            page.wait_for_function(
                "window.__gameAcceptance && window.__gameAcceptance.getState().ready === true",
                timeout=args.load_timeout_ms,
            )
        except PlaywrightTimeoutError as error:
            page.screenshot(path=str(args.output_dir / "00-load-timeout.png"), full_page=True)
            report = {
                "result": "TIMEOUT",
                "error": str(error),
                "browser_state": page.evaluate(
                    "() => ({ready:document.readyState, probe:window.__offlineGamesWebProbe||null, acceptance:Boolean(window.__gameAcceptance)})"
                ),
                "responses": responses,
                "console_errors": console_errors,
                "page_errors": page_errors,
                "request_failures": request_failures,
            }
            (args.output_dir / "local-web-acceptance.json").write_text(
                json.dumps(report, ensure_ascii=False, indent=2) + "\n",
                "utf-8",
            )
            browser.close()
            print("SUDOKU_WEB_ACCEPTANCE=TIMEOUT")
            return 2

        page.wait_for_timeout(700)
        home_state = page.evaluate("window.__gameAcceptance.getState()")
        secure_context = page.evaluate("window.isSecureContext")
        browser_features = page.evaluate(
            "() => ({webassembly:typeof WebAssembly==='object', webgl2:Boolean(document.createElement('canvas').getContext('webgl2')), local_storage:Boolean(window.localStorage)})"
        )
        canvas = page.locator("canvas")
        box = canvas.bounding_box()
        if box is None:
            raise RuntimeError("Godot canvas has no bounding box")

        def click_design(x: float, y: float) -> None:
            page.mouse.click(
                box["x"] + x * box["width"] / 540.0,
                box["y"] + y * box["height"] / 960.0,
            )

        def open_sudoku() -> dict[str, object]:
            click_design(141, 589)
            page.wait_for_function(
                "window.__gameAcceptance.getState().game_id === 'sudoku'",
                timeout=15_000,
            )
            page.wait_for_timeout(260)
            return page.evaluate("window.__gameAcceptance.getState()")

        def click_cell(cell: tuple[int, int]) -> None:
            x, y = cell
            click_design(47 + (x + 0.5) * 49.5, 236 + (y + 0.5) * 49.5)

        def click_digit(value: int) -> None:
            click_design(30 + (value - 1) * 53 + 23.5, 810)

        entry_state = open_sudoku()
        entry = entry_state["state"]
        fingerprint = entry["puzzle_fingerprint"]
        correct_cell = first_editable(entry["given"])
        cx, cy = correct_cell
        correct_value = int(entry["solution"][cy][cx])
        click_cell(correct_cell)
        click_digit(correct_value)
        page.wait_for_function(
            "([x,y,v]) => { const s=window.__gameAcceptance.getState().state; return s.board[y][x]===v && s.moves===1; }",
            arg=[cx, cy, correct_value],
            timeout=5_000,
        )
        correct_state = page.evaluate("window.__gameAcceptance.getState()")
        page.screenshot(path=str(args.output_dir / "01-correct.png"), full_page=True)

        wrong_cell = first_editable(entry["given"], {correct_cell})
        wx, wy = wrong_cell
        wrong_value = int(entry["solution"][wy][wx]) % 9 + 1
        click_cell(wrong_cell)
        click_digit(wrong_value)
        page.wait_for_function(
            "([x,y,v]) => { const s=window.__gameAcceptance.getState().state; return s.board[y][x]===v && s.wrong[y][x]===true && s.mistakes===1 && s.moves===2; }",
            arg=[wx, wy, wrong_value],
            timeout=5_000,
        )
        page.wait_for_timeout(720)
        wrong_state = page.evaluate("window.__gameAcceptance.getState()")
        page.screenshot(path=str(args.output_dir / "02-wrong-persistent.png"), full_page=True)

        page.reload(wait_until="domcontentloaded", timeout=args.load_timeout_ms)
        page.wait_for_function(
            "window.__gameAcceptance && window.__gameAcceptance.getState().ready === true",
            timeout=args.load_timeout_ms,
        )
        page.wait_for_timeout(220)
        recovered_state = open_sudoku()
        page.screenshot(path=str(args.output_dir / "03-recovered.png"), full_page=True)

        page.keyboard.press("KeyR")
        page.wait_for_function(
            "() => { const s=window.__gameAcceptance.getState().state; return s.moves===0 && s.mistakes===0 && JSON.stringify(s.board)===JSON.stringify(s.given); }",
            timeout=5_000,
        )
        restart_state = page.evaluate("window.__gameAcceptance.getState()")
        page.screenshot(path=str(args.output_dir / "04-restarted.png"), full_page=True)

        page.reload(wait_until="domcontentloaded", timeout=args.load_timeout_ms)
        page.wait_for_function(
            "window.__gameAcceptance && window.__gameAcceptance.getState().ready === true",
            timeout=args.load_timeout_ms,
        )
        page.wait_for_timeout(220)
        restarted_reload_state = open_sudoku()

        context.close()

        reduced_context = browser.new_context(
            viewport={"width": 540, "height": 960},
            reduced_motion="reduce",
        )
        reduced_page = reduced_context.new_page()
        reduced_page.goto(f"{args.base_url}?audit=sudoku-v3-reduced", wait_until="domcontentloaded", timeout=args.load_timeout_ms)
        reduced_page.wait_for_function(
            "window.__gameAcceptance && window.__gameAcceptance.getState().ready === true",
            timeout=args.load_timeout_ms,
        )
        reduced_canvas = reduced_page.locator("canvas")
        reduced_box = reduced_canvas.bounding_box()
        if reduced_box is None:
            raise RuntimeError("reduced-motion canvas has no bounding box")
        reduced_page.mouse.click(
            reduced_box["x"] + 141 * reduced_box["width"] / 540.0,
            reduced_box["y"] + 589 * reduced_box["height"] / 960.0,
        )
        reduced_page.wait_for_function(
            "window.__gameAcceptance.getState().game_id === 'sudoku' && window.__gameAcceptance.getState().state.reduced_effects === true",
            timeout=15_000,
        )
        reduced_state = reduced_page.evaluate("window.__gameAcceptance.getState()")
        reduced_page.screenshot(path=str(args.output_dir / "05-reduced-motion.png"), full_page=True)
        reduced_context.close()
        browser.close()

    pack_name = str(manifest["main_pack"])
    wasm_name = f"{manifest['executable']}.wasm"
    pack_url = f"{args.base_url.rstrip('/')}/{pack_name}"
    wasm_url = f"{args.base_url.rstrip('/')}/{wasm_name}"
    range_results = {
        "pck": range_probe(pack_url),
        "wasm": range_probe(wasm_url),
    }
    pck_responses = [details for url, details in responses.items() if url.split("?", 1)[0].endswith(".pck")]
    wasm_responses = [details for url, details in responses.items() if url.split("?", 1)[0].endswith(".wasm")]
    html_responses = [details for url, details in responses.items() if url.split("?", 1)[0].endswith("/") or url.split("?", 1)[0].endswith(".html")]

    correct = correct_state["state"]
    wrong = wrong_state["state"]
    recovered = recovered_state["state"]
    restarted = restart_state["state"]
    restarted_reload = restarted_reload_state["state"]
    checks = {
        "secure_context": secure_context is True,
        "ready": bool(home_state.get("ready")),
        "catalog_14": home_state.get("catalog_size") == 14,
        "browser_features": all(browser_features.values()),
        "unique_puzzle_exposed": entry.get("puzzle_fingerprint") == fingerprint and len(entry.get("given", [])) == 9,
        "correct_action": correct["board"][cy][cx] == correct_value and correct["moves"] == 1 and correct["mistakes"] == 0,
        "wrong_retained": wrong["board"][wy][wx] == wrong_value and wrong["wrong"][wy][wx] is True and wrong["mistakes"] == 1,
        "reload_recovery": recovered["board"] == wrong["board"] and recovered["moves"] == 2 and recovered["mistakes"] == 1,
        "restart": restarted["board"] == restarted["given"] and restarted["moves"] == 0 and restarted["mistakes"] == 0,
        "restart_reload": restarted_reload["board"] == restarted_reload["given"] and restarted_reload["puzzle_fingerprint"] == fingerprint,
        "reduced_motion": reduced_state["state"].get("reduced_effects") is True,
        "pck_loaded": bool(pck_responses) and all(item["ok"] for item in pck_responses),
        "wasm_loaded": bool(wasm_responses) and all(item["ok"] for item in wasm_responses),
        "entry_revalidates": bool(html_responses) and all("no-cache" in str(item["cache_control"]) for item in html_responses),
        "immutable_assets": all("immutable" in str(item["cache_control"]) for item in pck_responses + wasm_responses),
        "range_support": all(item["status"] == 206 and item["bytes"] == 2 and item["content_range"].startswith("bytes 0-1/") for item in range_results.values()),
        "full_transfers_finished": any(url.split("?", 1)[0].endswith(pack_name) for url in finished_requests_ms) and any(url.split("?", 1)[0].endswith(wasm_name) for url in finished_requests_ms),
        "runtime_errors_clear": not console_errors and not page_errors and not request_failures,
    }
    report = {
        "schema": "sudoku-v3-local-web-acceptance/v1",
        "observed_at_unix": int(time.time()),
        "base_url": args.base_url,
        "browser": "Google Chrome headless / SwiftShader WebGL2",
        "viewport": [540, 960],
        "source_commit": "2b03aca37bbc8410cf4a0d11124ba1ebd3abec94",
        "bundle_manifest": manifest,
        "checks": checks,
        "result": "PASS" if all(checks.values()) else "FAIL",
        "bundle_responses": responses,
        "finished_requests_ms": finished_requests_ms,
        "range_probes": range_results,
        "browser_features": browser_features,
        "entry_state": entry_state,
        "correct_action": {"cell": [cx, cy], "value": correct_value, "state": correct_state},
        "wrong_action": {"cell": [wx, wy], "value": wrong_value, "state": wrong_state},
        "recovered_state": recovered_state,
        "restart_state": restart_state,
        "restarted_reload_state": restarted_reload_state,
        "reduced_motion_state": reduced_state,
        "console_errors": console_errors,
        "page_errors": page_errors,
        "request_failures": request_failures,
    }
    (args.output_dir / "local-web-acceptance.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n",
        "utf-8",
    )
    print(f"SUDOKU_WEB_ACCEPTANCE={report['result']}")
    print(f"SUDOKU_WEB_REPORT={args.output_dir / 'local-web-acceptance.json'}")
    return 0 if report["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
