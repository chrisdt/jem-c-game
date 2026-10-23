"""Exercise the Web shell's fullscreen controls without downloading the game."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import os
import threading
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
SHELL = (ROOT / 'web/loading.html').read_text()
for key, value in {'$GODOT_PROJECT_NAME': 'Sunny Scout', '$GODOT_HEAD_INCLUDE': '',
                   '$GODOT_URL': 'engine-stub.js', '$GODOT_CONFIG': '{}',
                   '$GODOT_THREADS_ENABLED': 'false'}.items():
    SHELL = SHELL.replace(key, value)
ENGINE = """window.Engine = class {
 static getMissingFeatures() { return []; }
 startGame() { window.dispatchEvent(new Event('scout-startup-ready')); return Promise.resolve(); }
};"""

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = ENGINE if self.path == '/engine-stub.js' else SHELL if self.path == '/' else ''
        self.send_response(200 if body else 404)
        self.send_header('Content-Type', 'text/javascript' if self.path.endswith('.js') else 'text/html')
        self.end_headers()
        self.wfile.write(body.encode())
    def log_message(self, *_):
        pass


def main():
    server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(executable_path=os.environ.get('SCOUT_TEST_CHROMIUM', '/usr/bin/chromium'),
                                        headless=True, args=['--no-sandbox'])
            context = browser.new_context(viewport={'width': 844, 'height': 390}, is_mobile=True, has_touch=True)
            errors = []
            def page_with(script=''):
                page = context.new_page()
                page.on('pageerror', lambda error: errors.append(str(error)))
                if script:
                    page.add_init_script(script)
                page.goto(f'http://127.0.0.1:{server.server_port}/')
                page.locator('#status').wait_for(state='hidden')
                return page

            page = page_with()
            button = page.get_by_role('button', name='Full screen', exact=True)
            assert button.bounding_box()['width'] >= 44
            button.tap()
            page.wait_for_function('document.fullscreenElement === document.documentElement')
            page.get_by_role('button', name='Exit full screen').tap()
            page.wait_for_function('!document.fullscreenElement')
            assert page.locator('#fullscreen').get_attribute('aria-pressed') == 'false'
            page.close()
            print('PASS: real mobile touch enters/exits browser fullscreen and updates its label')

            page = page_with("""Object.defineProperty(document, 'fullscreenEnabled', {value: false});
                Object.defineProperty(document, 'webkitFullscreenEnabled', {value: false});
                Object.defineProperty(navigator, 'platform', {value: 'MacIntel'});
                Object.defineProperty(navigator, 'maxTouchPoints', {value: 5});""")
            page.get_by_role('button', name='Full screen', exact=True).tap()
            dialog = page.get_by_role('dialog')
            dialog.wait_for(state='visible')
            assert 'Add to Home Screen' in dialog.inner_text()
            assert 'Open as Web App' in dialog.inner_text()
            page.get_by_role('button', name='Got it').tap()
            assert not dialog.is_visible()
            page.close()
            print('PASS: unsupported iOS browser offers Home Screen instructions and a working close button')

            page = page_with("Element.prototype.requestFullscreen = () => Promise.reject(new Error('Denied'));")
            page.get_by_role('button', name='Full screen', exact=True).tap()
            assert 'did not allow full screen' in page.get_by_role('dialog').inner_text()
            assert page.locator('#fullscreen').get_attribute('aria-pressed') == 'false'
            page.close()
            print('PASS: denied request explains how to retry without claiming fullscreen succeeded')

            page = page_with("""Element.prototype.requestFullscreen = undefined;
                Element.prototype.webkitRequestFullscreen = function() {
                    Object.defineProperty(document, 'webkitFullscreenElement', {configurable:true, value:this});
                    document.dispatchEvent(new Event('webkitfullscreenchange'));
                };
                document.webkitExitFullscreen = function() {
                    Object.defineProperty(document, 'webkitFullscreenElement', {configurable:true, value:null});
                    document.dispatchEvent(new Event('webkitfullscreenchange'));
                };""")
            page.get_by_role('button', name='Full screen', exact=True).tap()
            page.get_by_role('button', name='Exit full screen').tap()
            assert page.locator('#fullscreen').get_attribute('aria-pressed') == 'false'
            page.close()

            page = page_with("Object.defineProperty(navigator, 'standalone', {value:true});")
            assert not page.locator('#fullscreen').is_visible()
            assert page.locator('meta[name="apple-mobile-web-app-capable"]').get_attribute('content') == 'yes'
            page.close()
            assert not errors, errors
            browser.close()
            print('PASS: prefixed Safari API and already-installed Home Screen mode; no browser script errors')
    finally:
        server.shutdown()
        server.server_close()

if __name__ == '__main__':
    main()
