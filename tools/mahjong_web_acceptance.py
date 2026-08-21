#!/usr/bin/env python3
"""Clean-bundle Chrome acceptance for the Vita Mahjong v3 candidate."""

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
        content_type = self.guess_type(str(path))
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
        self.send_header("Content-Type", content_type)
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
            assets[path.name] = {
                "status": response.status,
                "headers": headers_dict(response),
            }

    range_request = urllib.request.Request(
        f"{base_url}/{pck.name}", headers={"Range": "bytes=0-1023"}
    )
    with urllib.request.urlopen(range_request, timeout=20) as response:
        range_payload = response.read()
        range_probe = {
            "status": response.status,
            "bytes": len(range_payload),
            "content_range": response.headers.get("Content-Range", ""),
            "matches_file_prefix": range_payload == pck.read_bytes()[:1024],
        }

    full_digest = hashlib.sha256()
    full_bytes = 0
    with urllib.request.urlopen(f"{base_url}/{pck.name}", timeout=30) as response:
        full_headers = headers_dict(response)
        while True:
            chunk = response.read(1 << 20)
            if not chunk:
                break
            full_digest.update(chunk)
            full_bytes += len(chunk)
        full_probe = {
            "status": response.status,
            "bytes": full_bytes,
            "sha256": full_digest.hexdigest(),
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
        "status": state.get("status"),
        "remaining": state.get("remaining"),
        "removed": state.get("removed"),
        "selected": state.get("selected"),
        "moves": state.get("moves"),
        "score": state.get("score"),
        "blocked_attempts": state.get("blocked_attempts"),
        "reduced_effects": state.get("reduced_effects"),
        "mahjong_schema": state.get("mahjong_schema"),
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

    console_errors: list[str] = []
    page_errors: list[str] = []
    request_failures: list[str] = []
    responses: dict[str, dict[str, object]] = {}
    started_at = time.monotonic()
    states: dict[str, dict[str, object]] = {}
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
            try:
                page.goto(
                    release_url,
                    wait_until="domcontentloaded",
                    timeout=args.load_timeout_ms,
                )
                page.wait_for_function(
                    "window.__gameAcceptance && window.__gameAcceptance.getState().ready === true",
                    timeout=args.load_timeout_ms,
                )
            except PlaywrightTimeoutError:
                page.screenshot(path=str(output_dir / "00-load-timeout.png"), full_page=True)
                raise
            ready_seconds = time.monotonic() - started_at
            page.wait_for_timeout(500)
            home = page.evaluate("window.__gameAcceptance.getState()")
            states["home"] = slim_state(home)
            canvas = page.locator("canvas")
            box = canvas.bounding_box()
            if box is None:
                raise RuntimeError("Godot canvas has no bounding box")

            def point(design_x: float, design_y: float) -> tuple[float, float]:
                return (
                    box["x"] + design_x * box["width"] / DESIGN_SIZE[0],
                    box["y"] + design_y * box["height"] / DESIGN_SIZE[1],
                )

            def click(design_x: float, design_y: float) -> None:
                page.mouse.click(*point(design_x, design_y))

            # Catalog index 9: right column, fifth row.
            click(399, 725)
            page.wait_for_function(
                "window.__gameAcceptance.getState().game_id === 'mahjong' && "
                "window.__gameAcceptance.getState().state.remaining === 36",
                timeout=15_000,
            )
            page.wait_for_timeout(500)
            entry = page.evaluate("window.__gameAcceptance.getState()")
            states["entry"] = slim_state(entry)
            page.screenshot(path=str(output_dir / "01-stable.png"), full_page=True)

            # Base tile 2 is visible at its upper half but still rule-blocked.
            click(232, 309)
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.blocked_attempts === 1",
                timeout=5_000,
            )
            blocked = page.evaluate("window.__gameAcceptance.getState()")
            states["blocked"] = slim_state(blocked)
            page.screenshot(path=str(output_dir / "02-blocked.png"), full_page=True)

            # The two layer-2 cap tiles (indices 32 and 33) form a legal pair.
            click(204, 401)
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.selected === 32",
                timeout=5_000,
            )
            selected = page.evaluate("window.__gameAcceptance.getState()")
            states["selected"] = slim_state(selected)
            page.screenshot(path=str(output_dir / "03-selected.png"), full_page=True)
            click(276, 401)
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.moves === 1 && "
                "window.__gameAcceptance.getState().state.remaining === 34",
                timeout=5_000,
            )
            pair = page.evaluate("window.__gameAcceptance.getState()")
            states["pair"] = slim_state(pair)
            page.screenshot(path=str(output_dir / "04-pair.png"), full_page=True)

            page.reload(wait_until="domcontentloaded", timeout=args.load_timeout_ms)
            page.wait_for_function(
                "window.__gameAcceptance && "
                "window.__gameAcceptance.getState().game_id === 'mahjong' && "
                "window.__gameAcceptance.getState().state.moves === 1",
                timeout=args.load_timeout_ms,
            )
            page.wait_for_timeout(400)
            recovered = page.evaluate("window.__gameAcceptance.getState()")
            states["recovered"] = slim_state(recovered)
            page.screenshot(path=str(output_dir / "05-recovered.png"), full_page=True)
            box = page.locator("canvas").bounding_box()
            if box is None:
                raise RuntimeError("Godot canvas missing after reload")

            click(453, 835)
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.reduced_effects === true",
                timeout=5_000,
            )
            reduced = page.evaluate("window.__gameAcceptance.getState()")
            states["reduced"] = slim_state(reduced)
            page.screenshot(path=str(output_dir / "06-reduced.png"), full_page=True)

            click(486, 48)
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.moves === 0 && "
                "window.__gameAcceptance.getState().state.remaining === 36",
                timeout=5_000,
            )
            page.wait_for_timeout(350)
            restarted = page.evaluate("window.__gameAcceptance.getState()")
            states["restarted"] = slim_state(restarted)
            page.screenshot(path=str(output_dir / "07-restarted.png"), full_page=True)

            click(204, 401)
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.selected === 32",
                timeout=5_000,
            )
            click(276, 401)
            page.wait_for_function(
                "window.__gameAcceptance.getState().state.moves === 1 && "
                "window.__gameAcceptance.getState().state.reduced_effects === true",
                timeout=5_000,
            )
            reduced_pair = page.evaluate("window.__gameAcceptance.getState()")
            states["reduced_pair"] = slim_state(reduced_pair)
            page.screenshot(path=str(output_dir / "08-reduced-pair.png"), full_page=True)

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
        "entry_v3": states["entry"]["mahjong_schema"] == 3
        and states["entry"]["remaining"] == 36,
        "blocked_reject_nonmutating": states["blocked"]["blocked_attempts"] == 1
        and states["blocked"]["removed"] == []
        and states["blocked"]["selected"] == -1,
        "real_selection": states["selected"]["selected"] == 32,
        "real_pair": states["pair"]["removed"] == [32, 33]
        and states["pair"]["moves"] == 1
        and states["pair"]["score"] == 50,
        "reload_recovery": states["recovered"]["removed"] == [32, 33]
        and states["recovered"]["moves"] == 1,
        "reduced_toggle": states["reduced"]["reduced_effects"] is True,
        "restart": states["restarted"]["removed"] == []
        and states["restarted"]["moves"] == 0
        and states["restarted"]["remaining"] == 36,
        "reduced_persists_and_pairs": states["reduced_pair"]["reduced_effects"] is True
        and states["reduced_pair"]["removed"] == [32, 33]
        and states["reduced_pair"]["moves"] == 1,
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
        "runtime_errors_clear": not console_errors
        and not page_errors
        and not request_failures,
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
    print(f"MAHJONG_WEB_ACCEPTANCE={report['result']}")
    print(f"MAHJONG_WEB_REPORT={report_path}")
    return 0 if report["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
