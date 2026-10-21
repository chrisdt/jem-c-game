"""Browser smoke test against an exported build and disposable PHP score file.

Requires Playwright and Chromium; never contacts or updates the live website.
Export Web first. SCOUT_TEST_PHP / SCOUT_TEST_CHROMIUM select local executables.
"""
from pathlib import Path
import os
import socket
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]


def run():
    from playwright.sync_api import sync_playwright
    with tempfile.TemporaryDirectory(prefix="scout-browser-") as temporary:
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
        env = os.environ | {"SUNNY_SCOUT_DATA_DIR": temporary + "/data"}
        with (Path(temporary) / "php.log").open("w") as log:
            server = subprocess.Popen([
                os.environ.get("SCOUT_TEST_PHP", "php"), "-n", "-S",
                f"127.0.0.1:{port}", "-t", str(ROOT / "build/web")
            ], env=env, stdout=log, stderr=subprocess.STDOUT)
            try:
                time.sleep(0.3)
                with sync_playwright() as playwright:
                    browser = playwright.chromium.launch(
                        executable_path=os.environ.get("SCOUT_TEST_CHROMIUM", "/usr/bin/chromium"),
                        headless=True, args=["--no-sandbox", "--enable-unsafe-swiftshader"])
                    try:
                        page = browser.new_page(viewport={"width": 1280, "height": 800})
                        errors, replies = [], []
                        page.on("pageerror", lambda error: errors.append(str(error)))
                        page.on("console", lambda message: errors.append(message.text) if message.type == "error" else None)
                        # Do not await response bodies inside event callbacks.
                        page.on("response", lambda response: replies.append((response.request.method, response.status)) if "leaderboard.php" in response.url else None)
                        page.goto(f"http://127.0.0.1:{port}/", wait_until="domcontentloaded")
                        page.locator("#status").wait_for(state="hidden", timeout=180000)
                        page.mouse.click(824, 663)  # Welcome: Best times.
                        deadline = time.monotonic() + 20
                        while not replies and time.monotonic() < deadline:
                            page.wait_for_timeout(250)
                        assert ("GET", 200) in replies, "Welcome scoreboard failed"
                        page.wait_for_timeout(2000)
                        page.mouse.click(624, 662)  # Back.
                        page.wait_for_timeout(2000)
                        page.mouse.click(948, 598)  # Start speedrun.
                        deadline = time.monotonic() + 180
                        while ("POST", 200) not in replies and time.monotonic() < deadline:
                            page.wait_for_timeout(500)
                        assert ("POST", 200) in replies, "World startup failed to register a timed run"
                        page.mouse.click(120, 193)  # HUD timer opens the board.
                        deadline = time.monotonic() + 20
                        while replies.count(("GET", 200)) < 2 and time.monotonic() < deadline:
                            page.wait_for_timeout(250)
                        assert replies.count(("GET", 200)) >= 2, "In-game scoreboard failed"
                        assert not errors, errors
                        assert (Path(temporary) / "data/scores.php").is_file()
                        print("PASS: production Web welcome board, world-painted timer registration and in-game board against PHP")
                    finally:
                        browser.close()
            finally:
                server.terminate()
                server.wait(timeout=10)


if __name__ == "__main__":
    run()
