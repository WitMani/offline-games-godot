#!/usr/bin/env python3
"""Clean-bundle Chrome acceptance for the Amaze GO v3 candidate."""

from __future__ import annotations

import argparse
import functools
import hashlib
import json
import mimetypes
import re
import shutil
import threading
import time
import urllib.request
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

from playwright.sync_api import TimeoutError as PlaywrightTimeoutError
from playwright.sync_api import sync_playwright


DESIGN_SIZE = (540.0, 960.0)
FINGERPRINTED = re.compile(r"^index\.[0-9a-f]{12}\.")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


class IntegrityHandler(SimpleHTTPRequestHandler):
    """Static handler with Godot isolation headers and single-range support."""

    protocol_version = "HTTP/1.1"

    def log_message(self, _format: str, *args: object) -> None:
        return

    def end_headers(self) -> None:
        name = Path(urlsplit(self.path).path).name
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Accept-Ranges", "bytes")
        if FINGERPRINTED.match(name):
            self.send_header("Cache-Control", "public, max-age=31536000, immutable")
        else:
            self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def send_head(self):  # type: ignore[no-untyped-def]
        path = Path(self.translate_path(self.path))
        if path.is_dir():
            path = path / "index.html"
        try:
            handle = path.open("rb")
        except OSError:
            self.send_error(HTTPStatus.NOT_FOUND, "File not found")
            return None
        size = path.stat().st_size
        self._byte_range: tuple[int, int] | None = None
        range_header = self.headers.get("Range", "")
        if range_header:
            match = re.fullmatch(r"bytes=(\d*)-(\d*)", range_header.strip())
            if match is None or (not match.group(1) and not match.group(2)):
                handle.close()
                self.send_error(HTTPStatus.REQUESTED_RANGE_NOT_SATISFIABLE)
                return None
            if match.group(1):
                start = int(match.group(1))
                end = int(match.group(2)) if match.group(2) else size - 1
            else:
                suffix = int(match.group(2))
                start = max(0, size - suffix)
                end = size - 1
            end = min(end, size - 1)
            if start > end or start >= size:
                handle.close()
                self.send_response(HTTPStatus.REQUESTED_RANGE_NOT_SATISFIABLE)
                self.send_header("Content-Range", f"bytes */{size}")
                self.send_header("Content-Length", "0")
                self.end_headers()
                return None
            self._byte_range = (start, end)
            self.send_response(HTTPStatus.PARTIAL_CONTENT)
            self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
            self.send_header("Content-Length", str(end - start + 1))
        else:
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-Length", str(size))
        self.send_header("Content-Type", self.guess_type(str(path)))
        self.send_header("Last-Modified", self.date_time_string(path.stat().st_mtime))
        self.end_headers()
        return handle

    def copyfile(self, source, outputfile) -> None:  # type: ignore[no-untyped-def]
        byte_range = getattr(self, "_byte_range", None)
        if byte_range is None:
            shutil.copyfileobj(source, outputfile)
            return
        start, end = byte_range
        source.seek(start)
        remaining = end - start + 1
        while remaining > 0:
            chunk = source.read(min(64 * 1024, remaining))
            if not chunk:
                break
            outputfile.write(chunk)
            remaining -= len(chunk)


def headers_dict(response) -> dict[str, str]:  # type: ignore[no-untyped-def]
    return {key.lower(): value for key, value in response.headers.items()}


def probe_http(base_url: str, pck: Path, wasm: Path) -> dict[str, object]:
    assets: dict[str, object] = {}
    for path in [Path("index.html"), pck, wasm]:
        request = urllib.request.Request(f"{base_url}/{path.name}", method="HEAD")
        with urllib.request.urlopen(request, timeout=20) as response:
            assets[path.name] = {"status": response.status, "headers": headers_dict(response)}

    request = urllib.request.Request(
        f"{base_url}/{pck.name}", headers={"Range": "bytes=0-1023"}
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        payload = response.read()
        range_probe = {
            "status": response.status,
            "bytes": len(payload),
            "content_range": response.headers.get("Content-Range", ""),
            "matches_file_prefix": payload == pck.read_bytes()[:1024],
        }

    digest = hashlib.sha256()
    full_bytes = 0
    with urllib.request.urlopen(f"{base_url}/{pck.name}", timeout=30) as response:
        full_headers = headers_dict(response)
        for chunk in iter(lambda: response.read(1 << 20), b""):
            digest.update(chunk)
            full_bytes += len(chunk)
        full_probe = {
            "status": response.status,
            "bytes": full_bytes,
            "sha256": digest.hexdigest(),
            "headers": full_headers,
        }
    return {"head": assets, "range": range_probe, "full_pck": full_probe}


def slim_state(exposed: dict[str, object]) -> dict[str, object]:
    state = exposed.get("state", {})
    if not isinstance(state, dict):
        state = {}
    return {
        "screen": exposed.get("screen"),
        "game_id": exposed.get("game_id"),
        "schema": state.get("schema"),
        "status": state.get("status"),
        "remaining": state.get("remaining"),
        "removed_ids": state.get("removed_ids"),
        "hearts": state.get("hearts"),
        "mistakes": state.get("mistakes"),
        "moves": state.get("moves"),
        "score": state.get("score"),
        "focus_id": state.get("focus_id"),
        "hint_id": state.get("hint_id"),
        "reduced_effects": state.get("reduced_effects"),
        "gag_visible_roles": state.get("gag_visible_roles"),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("bundle_dir", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--load-timeout-ms", type=int, default=60_000)
    args = parser.parse_args()

    bundle_dir = args.bundle_dir.resolve()
    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    pcks = sorted(bundle_dir.glob("index.*.pck"))
    wasms = sorted(bundle_dir.glob("index.*.wasm"))
    if len(pcks) != 1 or len(wasms) != 1:
        raise SystemExit("expected one fingerprinted PCK and one fingerprinted WASM")
    pck, wasm = pcks[0], wasms[0]
    html = bundle_dir / "index.html"

    mimetypes.add_type("application/wasm", ".wasm")
    mimetypes.add_type("application/octet-stream", ".pck")
    handler = functools.partial(IntegrityHandler, directory=str(bundle_dir))
    server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
    server_thread = threading.Thread(target=server.serve_forever, daemon=True)
    server_thread.start()
    base_url = f"http://127.0.0.1:{server.server_port}"
    release_url = f"{base_url}/index.html?release={args.source_commit[:12]}"
    reduced_url = f"{release_url}&reduced=1"

    console_errors: list[str] = []
    page_errors: list[str] = []
    request_failures: list[str] = []
    responses: dict[str, dict[str, object]] = {}
    states: dict[str, dict[str, object]] = {}
    started_at = time.monotonic()
    try:
        http_probe = probe_http(base_url, pck, wasm)
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

            def remember_response(response) -> None:  # type: ignore[no-untyped-def]
                suffix = Path(response.url.split("?", 1)[0]).suffix.lower()
                if suffix in {".html", ".js", ".wasm", ".pck"}:
                    responses[response.url] = {
                        "status": response.status,
                        "ok": response.ok,
                        "content_type": response.headers.get("content-type", ""),
                        "content_length": response.headers.get("content-length", ""),
                        "cache_control": response.headers.get("cache-control", ""),
                        "coop": response.headers.get("cross-origin-opener-policy", ""),
                        "coep": response.headers.get("cross-origin-embedder-policy", ""),
                    }

            page.on("response", remember_response)

            def wait_ready() -> None:
                page.wait_for_function(
                    "window.__gameAcceptance && window.__gameAcceptance.getState().ready === true",
                    timeout=args.load_timeout_ms,
                )

            def design_click(design_x: float, design_y: float) -> None:
                box = page.locator("canvas").bounding_box()
                if box is None:
                    raise RuntimeError("Godot canvas has no bounding box")
                page.mouse.click(
                    box["x"] + design_x * box["width"] / DESIGN_SIZE[0],
                    box["y"] + design_y * box["height"] / DESIGN_SIZE[1],
                )

            def open_amaze_go() -> None:
                design_click(399, 793)
                page.wait_for_function(
                    "window.__gameAcceptance.getState().game_id === 'amaze_go' && "
                    "window.__gameAcceptance.getState().state.remaining !== undefined",
                    timeout=15_000,
                )
                page.wait_for_timeout(350)

            try:
                page.goto(release_url, wait_until="domcontentloaded", timeout=args.load_timeout_ms)
                wait_ready()
            except PlaywrightTimeoutError:
                page.screenshot(path=str(output_dir / "00-load-timeout.png"), full_page=True)
                raise
            ready_seconds = time.monotonic() - started_at
            page.wait_for_timeout(350)
            states["home"] = slim_state(page.evaluate("window.__gameAcceptance.getState()"))
            open_amaze_go()
            states["entry"] = slim_state(page.evaluate("window.__gameAcceptance.getState()"))
            page.screenshot(path=str(output_dir / "01-stable.png"), full_page=True)

            # Pointer rejection: a0's forward ray is initially blocked by a1.
            design_click(179.4, 289.8)
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.hearts === 2 && "
                "window.__gameAcceptance.getState().state.moves === 1",
                timeout=5_000,
            )
            states["pointer_reject"] = slim_state(page.evaluate("window.__gameAcceptance.getState()"))
            page.screenshot(path=str(output_dir / "02-pointer-reject.png"), full_page=True)

            # Pointer legal extraction: a1 exits upward and opens a0's lane.
            design_click(358.6, 253.9)
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.removed_ids.includes('a1') && "
                "window.__gameAcceptance.getState().state.remaining === 11",
                timeout=5_000,
            )
            states["pointer_legal"] = slim_state(page.evaluate("window.__gameAcceptance.getState()"))
            page.screenshot(path=str(output_dir / "03-pointer-legal.png"), full_page=True)

            # Normal restart, then keyboard reject from focused a0 and legal a1 via H + Enter.
            # Use the documented R shortcut here so a focused toolbar Control
            # cannot also consume the later Enter action.
            page.keyboard.press("r")
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.moves === 0 && "
                "window.__gameAcceptance.getState().state.remaining === 12",
                timeout=5_000,
            )
            states["restart_normal"] = slim_state(page.evaluate("window.__gameAcceptance.getState()"))
            page.keyboard.press("Enter")
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.hearts === 2 && "
                "window.__gameAcceptance.getState().state.moves === 1",
                timeout=5_000,
            )
            states["keyboard_reject"] = slim_state(page.evaluate("window.__gameAcceptance.getState()"))
            page.keyboard.press("h")
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.hint_id === 'a1'",
                timeout=5_000,
            )
            # Let the Web input bridge commit the hint/focus state before the
            # next discrete keyboard action.  Back-to-back synthetic key
            # events can otherwise land in one rendered frame even though a
            # real key-up/key-down sequence cannot.
            page.wait_for_timeout(180)
            page.keyboard.press("Enter")
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.removed_ids.includes('a1') && "
                "window.__gameAcceptance.getState().state.moves === 2",
                timeout=5_000,
            )
            states["keyboard_legal"] = slim_state(page.evaluate("window.__gameAcceptance.getState()"))
            page.screenshot(path=str(output_dir / "04-keyboard-loop.png"), full_page=True)
            page.wait_for_timeout(650)

            # Reload to home, reopen the cartridge, and verify strict model recovery.
            page.reload(wait_until="domcontentloaded", timeout=args.load_timeout_ms)
            wait_ready()
            page.wait_for_function(
                "window.__gameAcceptance.getState().screen === 'home'", timeout=5_000
            )
            open_amaze_go()
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.removed_ids.includes('a1') && "
                "window.__gameAcceptance.getState().state.hearts === 2 && "
                "window.__gameAcceptance.getState().state.moves === 2",
                timeout=10_000,
            )
            states["reload_recovered"] = slim_state(page.evaluate("window.__gameAcceptance.getState()"))
            page.screenshot(path=str(output_dir / "05-reload-recovered.png"), full_page=True)

            page.keyboard.press("r")
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.moves === 0 && "
                "window.__gameAcceptance.getState().state.remaining === 12",
                timeout=5_000,
            )
            # Web persistence reaches IndexedDB asynchronously.  Verify the
            # reset through a real reload before beginning the reduced-motion
            # pass so the two gates cannot accidentally share stale progress.
            page.wait_for_timeout(1_500)
            page.reload(wait_until="domcontentloaded", timeout=args.load_timeout_ms)
            wait_ready()
            open_amaze_go()
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.moves === 0 && "
                "window.__gameAcceptance.getState().state.remaining === 12",
                timeout=10_000,
            )
            states["reset_recovered"] = slim_state(
                page.evaluate("window.__gameAcceptance.getState()")
            )

            # Same origin and persisted reset; query/OS reduced mode is detected before entry.
            page.goto(reduced_url, wait_until="domcontentloaded", timeout=args.load_timeout_ms)
            wait_ready()
            open_amaze_go()
            reduced_environment = page.evaluate(
                """() => ({
                    href: window.location.href,
                    reduced_param: new URLSearchParams(window.location.search).get('reduced'),
                    media_reduce: Boolean(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches),
                    published_reduced: window.__gameAcceptance.getState().state.reduced_effects,
                    published_remaining: window.__gameAcceptance.getState().state.remaining,
                    published_moves: window.__gameAcceptance.getState().state.moves,
                })"""
            )
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.reduced_effects === true && "
                "window.__gameAcceptance.getState().state.remaining === 12",
                timeout=10_000,
            )
            states["reduced_entry"] = slim_state(page.evaluate("window.__gameAcceptance.getState()"))
            page.screenshot(path=str(output_dir / "06-reduced-entry.png"), full_page=True)
            design_click(358.6, 253.9)
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.reduced_effects === true && "
                "window.__gameAcceptance.getState().state.removed_ids.includes('a1')",
                timeout=5_000,
            )
            states["reduced_legal"] = slim_state(page.evaluate("window.__gameAcceptance.getState()"))
            page.screenshot(path=str(output_dir / "07-reduced-legal.png"), full_page=True)
            design_click(486, 48)
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.reduced_effects === true && "
                "window.__gameAcceptance.getState().state.remaining === 12 && "
                "window.__gameAcceptance.getState().state.moves === 0",
                timeout=5_000,
            )
            states["reduced_restart"] = slim_state(page.evaluate("window.__gameAcceptance.getState()"))
            page.screenshot(path=str(output_dir / "08-reduced-restart.png"), full_page=True)

            browser_probe = page.evaluate(
                """() => ({
                    secure_context: window.isSecureContext,
                    webassembly: typeof WebAssembly === 'object',
                    canvas_count: document.querySelectorAll('canvas').length,
                    engine_probe: window.__offlineGamesWebProbe || null,
                })"""
            )
            browser.close()
    finally:
        server.shutdown()
        server.server_close()
        server_thread.join(timeout=5)

    pck_head = http_probe["head"][pck.name]
    wasm_head = http_probe["head"][wasm.name]
    full_pck = http_probe["full_pck"]
    range_pck = http_probe["range"]
    checks = {
        "ready_home": states["home"]["screen"] == "home",
        "secure_context": browser_probe["secure_context"] is True,
        "webassembly": browser_probe["webassembly"] is True,
        "one_canvas": browser_probe["canvas_count"] == 1,
        "engine_probe_clear": not browser_probe["engine_probe"].get("error"),
        "entry_v3": states["entry"]["schema"] == "amaze-go-model/v1"
        and states["entry"]["remaining"] == 12
        and states["entry"]["gag_visible_roles"]
        == ["surveyor_clearance_station", "beacon_progress_seal"],
        "pointer_reject": states["pointer_reject"]["removed_ids"] == []
        and states["pointer_reject"]["hearts"] == 2
        and states["pointer_reject"]["moves"] == 1,
        "pointer_legal": states["pointer_legal"]["removed_ids"] == ["a1"]
        and states["pointer_legal"]["remaining"] == 11,
        "restart_normal": states["restart_normal"]["removed_ids"] == []
        and states["restart_normal"]["moves"] == 0,
        "keyboard_reject": states["keyboard_reject"]["removed_ids"] == []
        and states["keyboard_reject"]["hearts"] == 2,
        "keyboard_legal": states["keyboard_legal"]["removed_ids"] == ["a1"]
        and states["keyboard_legal"]["moves"] == 2,
        "reload_recovery": states["reload_recovered"]["removed_ids"] == ["a1"]
        and states["reload_recovered"]["hearts"] == 2
        and states["reload_recovered"]["moves"] == 2,
        "reset_recovery": states["reset_recovered"]["removed_ids"] == []
        and states["reset_recovered"]["hearts"] == 3
        and states["reset_recovered"]["moves"] == 0,
        "reduced_entry": states["reduced_entry"]["reduced_effects"] is True
        and states["reduced_entry"]["remaining"] == 12,
        "reduced_legal": states["reduced_legal"]["reduced_effects"] is True
        and states["reduced_legal"]["removed_ids"] == ["a1"],
        "reduced_restart": states["reduced_restart"]["reduced_effects"] is True
        and states["reduced_restart"]["removed_ids"] == []
        and states["reduced_restart"]["moves"] == 0,
        "coop_coep": pck_head["headers"].get("cross-origin-opener-policy") == "same-origin"
        and pck_head["headers"].get("cross-origin-embedder-policy") == "require-corp",
        "immutable_fingerprinted_assets": "immutable"
        in pck_head["headers"].get("cache-control", "")
        and "immutable" in wasm_head["headers"].get("cache-control", ""),
        "range_206": range_pck["status"] == 206
        and range_pck["bytes"] == 1024
        and range_pck["matches_file_prefix"] is True,
        "full_pck_transfer": full_pck["status"] == 200
        and full_pck["bytes"] == pck.stat().st_size
        and full_pck["sha256"] == sha256(pck),
        "runtime_errors_clear": not console_errors and not page_errors and not request_failures,
    }
    screenshots = {
        path.name: {"sha256": sha256(path), "bytes": path.stat().st_size}
        for path in sorted(output_dir.glob("*.png"))
    }
    report = {
        "schema": "offline-games-local-web-acceptance/v3",
        "observed_at_unix": int(time.time()),
        "source": f"clean git archive of implementation commit {args.source_commit}",
        "url": release_url,
        "reduced_url": reduced_url,
        "browser": "Google Chrome headless / SwiftShader WebGL2",
        "viewport": [540, 960],
        "ready_seconds": round(ready_seconds, 3),
        "checks": checks,
        "result": "PASS" if all(checks.values()) else "FAIL",
        "bundle": {
            "html": {"name": html.name, "sha256": sha256(html), "bytes": html.stat().st_size},
            "pck": {"name": pck.name, "sha256": sha256(pck), "bytes": pck.stat().st_size},
            "engine": {"name": wasm.name, "sha256": sha256(wasm), "bytes": wasm.stat().st_size},
        },
        "browser_probe": browser_probe,
        "reduced_environment": reduced_environment,
        "browser_responses": responses,
        "http_integrity": http_probe,
        "states": states,
        "console_errors": console_errors,
        "page_errors": page_errors,
        "request_failures": request_failures,
        "screenshots": screenshots,
        "claim_boundary": "Local clean-bundle acceptance only; not deployed and not a target-binary parity claim.",
    }
    report_path = output_dir / "local-web-acceptance.json"
    report_path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"AMAZE_GO_WEB_ACCEPTANCE={report['result']}")
    print(f"AMAZE_GO_WEB_REPORT={report_path}")
    return 0 if report["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
