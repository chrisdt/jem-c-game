"""Install the ZIP in real, disposable WordPress/MariaDB and exercise the game.

Requires Docker with wordpress:php8.3-apache and mariadb:11.4, Godot, Playwright
and Chromium. Never contacts or changes the live site. Game assets are read-only.
"""
from concurrent.futures import ThreadPoolExecutor
from http.cookiejar import CookieJar
from html import unescape
from html.parser import HTMLParser
import json
import os
from pathlib import Path
import secrets
import shutil
import socket
import subprocess
import tempfile
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urljoin
from urllib.request import Request, build_opener, ProxyHandler, HTTPCookieProcessor

ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = Path(os.environ.get("SCOUT_WP_ARTIFACTS", "/workspace/artifacts/wordpress-scores"))
DOCKER = ["docker", "--host=unix:///var/run/docker.sock"]


class FormParser(HTMLParser):
    def __init__(self, text):
        super().__init__()
        self.inputs, self.links = {}, []
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if tag == "input" and values.get("name"):
            self.inputs[values["name"]] = values.get("value", "")
        if tag == "a" and values.get("href"):
            self.links.append(unescape(values["href"]))


def run():
    from playwright.sync_api import sync_playwright
    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    prefix = "scout-wp-test-" + str(os.getpid())
    db, wp, volume, network = [prefix + suffix for suffix in ("-db", "-web", "-site", "-network")]

    def docker(*args, input=None, timeout=120):
        result = subprocess.run(DOCKER + list(args), input=input, capture_output=True, text=True, timeout=timeout)
        if result.returncode:
            raise RuntimeError("Docker operation failed: " + result.stderr[-2000:])
        return result.stdout

    with tempfile.TemporaryDirectory(prefix=prefix) as temporary:
        temporary = Path(temporary)
        game_files = temporary/"game"
        shutil.copytree(ROOT/"build/web",game_files)
        game_files.chmod(0o755)
        for path in game_files.rglob("*"): path.chmod(0o755 if path.is_dir() else 0o644)
        password = secrets.token_hex(20)
        db_env, wp_env = temporary / "db.env", temporary / "wp.env"
        db_env.write_text("MARIADB_ROOT_PASSWORD="+password+"\nMARIADB_DATABASE=wordpress\nMARIADB_USER=wordpress\nMARIADB_PASSWORD="+password+"\n")
        extra = "define('DISABLE_WP_CRON',true); define('AUTOMATIC_UPDATER_DISABLED',true); define('WP_HTTP_BLOCK_EXTERNAL',true); function wp_mail($to,$subject,$message,$headers='',$attachments=[]) { return false; }"
        wp_env.write_text("WORDPRESS_DB_HOST="+db+":3306\nWORDPRESS_DB_USER=wordpress\nWORDPRESS_DB_PASSWORD="+password+"\nWORDPRESS_DB_NAME=wordpress\nWORDPRESS_CONFIG_EXTRA="+extra+"\n")
        db_env.chmod(0o600)
        wp_env.chmod(0o600)
        with socket.socket() as sock:
            sock.bind(("127.0.0.1",0))
            port = sock.getsockname()[1]
        base = f"http://127.0.0.1:{port}"
        opener = build_opener(ProxyHandler({}), HTTPCookieProcessor(CookieJar()))

        def http(path, data=None, headers=None, method=None):
            request = Request(urljoin(base,path), data=data, headers=headers or {}, method=method)
            try: response = opener.open(request, timeout=30)
            except HTTPError as error: response = error
            return response.status, dict(response.headers), response.read().decode()

        def form(path, values):
            return http(path,urlencode(values).encode(),{"Content-Type":"application/x-www-form-urlencoded"})

        def api(body=None, path="/index.php?rest_route=/sunny-scout/v1/leaderboard", headers=None):
            data = json.dumps(body).encode() if body is not None else None
            code, head, raw = http(path,data,({"Content-Type":"application/json"} if data is not None else {}) | (headers or {}))
            return code, head, json.loads(raw)

        def php(code, data=None):
            # Credentials stay in wp-config.php; private fixture tokens go only
            # over stdin and are never printed or included in process arguments.
            return docker("exec","-i",wp,"php","-r","require '/var/www/html/wp-load.php'; "+code, input=json.dumps(data) if data is not None else None)

        def backdate(token):
            php("global $wpdb; $i=json_decode(stream_get_contents(STDIN),true); $k=Sunny_Scout_WordPress_Store::OPTION; $v=$wpdb->get_var($wpdb->prepare(\"SELECT option_value FROM {$wpdb->options} WHERE option_name=%s\",$k)); $s=json_decode($v,true); $s['runs'][$i['token']]['started_ms']-=120000; $wpdb->update($wpdb->options,['option_value'=>json_encode($s)],['option_name'=>$k]);", {"token":token})

        try:
            docker("network","create",network)
            docker("volume","create",volume)
            docker("run","-d","--name",db,"--network",network,"--env-file",str(db_env),"--tmpfs","/var/lib/mysql:rw,size=512m","mariadb:11.4")
            docker("run","-d","--name",wp,"--network",network,"--env-file",str(wp_env),"-p",f"127.0.0.1:{port}:80",
                   "--mount",f"type=volume,src={volume},dst=/var/www/html",
                   "--mount",f"type=bind,src={game_files},dst=/var/www/html/play,readonly", "wordpress:php8.3-apache")
            deadline = time.monotonic()+90
            while True:
                try:
                    code,_,text = http("/wp-admin/install.php")
                    if code==200 and "weblog_title" in text: break
                except (URLError,OSError): pass
                if time.monotonic()>deadline: raise RuntimeError("Disposable WordPress did not become ready")
                time.sleep(0.5)
            code,_,text = form("/wp-admin/install.php?step=2",{
                "weblog_title":"Sunny Scout Test", "user_name":"scoutadmin", "admin_password":password,
                "admin_password2":password,"admin_email":"test@example.invalid","pw_weak":"1","blog_public":"0","Submit":"Install WordPress"})
            assert code==200 and "Success!" in text, text[-1000:]
            http("/wp-login.php")
            code,_,text = form("/wp-login.php",{"log":"scoutadmin","pwd":password,"testcookie":"1","redirect_to":base+"/wp-admin/plugins.php"})
            assert code==200 and "plugins.php" in text
            _,_,text = http("/wp-admin/plugin-install.php?tab=upload")
            nonce = FormParser(text).inputs["_wpnonce"]
            archive = (ROOT/"build/sunny-scout-scores.zip").read_bytes()
            boundary = "scout" + secrets.token_hex(12)
            fields = {"_wpnonce":nonce,"_wp_http_referer":"/wp-admin/plugin-install.php?tab=upload","install-plugin-submit":"Install Now"}
            parts = []
            for name,value in fields.items():
                parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"\r\n\r\n{value}\r\n'.encode())
            parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="pluginzip"; filename="sunny-scout-scores.zip"\r\nContent-Type: application/zip\r\n\r\n'.encode()+archive+b"\r\n")
            parts.append(f"--{boundary}--\r\n".encode())
            code,_,text = http("/wp-admin/update.php?action=upload-plugin",b"".join(parts),{"Content-Type":"multipart/form-data; boundary="+boundary})
            links = [link for link in FormParser(text).links if "action=activate" in link and "sunny-scout-scores" in link]
            assert code==200 and links, text[-1500:]
            code,_,text = http(urljoin(base+'/wp-admin/',links[0]))
            (ARTIFACTS/"activation.html").write_text(text)
            assert code==200 and "Sunny Scout Scores is ready" in text, f"Activation response {code}; see activation.html"
            print("PASS: real WordPress upload ZIP and activate; automatic database setup",flush=True)

            code,_,admin = http("/wp-admin/tools.php?page=sunny-scout-scores")
            assert code==200 and "Score storage is ready" in admin and "/play/" in admin
            code,headers,game = http("/index.php?sunny_scout=play")
            (ARTIFACTS/"game-entry.html").write_text(game)
            assert code==200 and '<base href="'+base+'/play/">' in game and "scoutScoresEndpoint" in game, f"Game page {code}; see game-entry.html"
            assert api()[2]["scores"]==[]
            assert api({"action":"start","campaign":"other"})[0]==409
            assert api({"action":"start","campaign":"three-worlds-story-v1"},headers={"Origin":"https://elsewhere.invalid"})[0]==403
            assert api({"action":"start","campaign":"three-worlds-story-v1","large":"x"*5000})[0]==413
            started = api({"action":"start","campaign":"three-worlds-story-v1"})
            assert started[0]==200 and len(started[2]["token"])==48
            token = started[2]["token"]
            backdate(token)
            quests = ["rowan","bea","otis","mara","iris","finn","frost_pip","frost_nix","frost_tavi","frost_eira","ember_sol","ember_luma","ember_brasa","ember_orin"]
            complete = {"action":"complete","token":token,"quests":quests,"enemies":4,"recoveries":1}
            first = api(complete)
            assert first[0]==200 and first[2]["result"]["duration_ms"]>=120000
            assert api(complete)[2]==first[2]
            posted = api({"action":"submit","token":token,"nickname":"WordPressPilot"})
            assert posted[0]==200 and posted[2]["rank"]==1
            assert api({"action":"submit","token":token,"nickname":"Other"})[2]["nickname"]=="WordPressPilot"
            rest = "/index.php?rest_route=/sunny-scout/v1/leaderboard"
            board = api(path=rest)
            assert board[0]==200 and board[2]["scores"][0]["nickname"]=="WordPressPilot" and "no-store" in board[1].get("Cache-Control","")
            assert token not in json.dumps(board[2])
            with ThreadPoolExecutor(max_workers=8) as pool:
                starts = list(pool.map(lambda _: api({"action":"start","campaign":"three-worlds-story-v1"}),range(16)))
            tokens = [item[2].get("token") for item in starts]
            assert all(item[0]==200 for item in starts) and len(set(tokens))==16
            count = php("global $wpdb; $s=json_decode($wpdb->get_var($wpdb->prepare(\"SELECT option_value FROM {$wpdb->options} WHERE option_name=%s\",Sunny_Scout_WordPress_Store::OPTION)),true); echo count($s['runs']);")
            assert int(count)==17
            assert php("global $wpdb; echo $wpdb->get_var($wpdb->prepare(\"SELECT autoload FROM {$wpdb->options} WHERE option_name=%s\",Sunny_Scout_WordPress_Store::OPTION));").strip() in ("no","off")
            assert php("echo get_option('blogname');")=="Sunny Scout Test"
            print("PASS: real database API, origin/body validation, verified/idempotent finish and post, private/non-autoloaded storage, 16 concurrent starts without lost updates",flush=True)

            # Match the user's root-hosted game with read-only asset symlinks.
            # WordPress's existing index.php remains untouched and serves REST.
            docker("exec",wp,"php","-r","foreach(scandir('/var/www/html/play') as $name) { if(in_array($name,['.','..','api'],true)) continue; $to='/var/www/html/'.$name; if(file_exists($to)||is_link($to)) throw new RuntimeException('Fixture collision'); symlink('/var/www/html/play/'.$name,$to); }")
            assert '<base href="'+base+'/">' in http("/index.php?sunny_scout=play")[2]
            # The old compiled game still computes its original PHP URL; the
            # Play page adapter must send those calls to WordPress REST.
            with sync_playwright() as playwright:
                browser = playwright.chromium.launch(executable_path=os.environ.get("SCOUT_TEST_CHROMIUM","/usr/bin/chromium"),headless=True,args=["--no-sandbox","--enable-unsafe-swiftshader"])
                page = browser.new_page(viewport={"width":1280,"height":800})
                errors, responses = [], []
                page.on("pageerror",lambda error: errors.append(str(error)))
                page.on("console",lambda message: errors.append(message.text) if message.type=="error" or "SCRIPT ERROR" in message.text else None)
                page.on("response",lambda response: responses.append(response) if "leaderboard" in response.url else None)
                page.goto(base+"/index.php?sunny_scout=play",wait_until="domcontentloaded")
                page.locator("#status").wait_for(state="hidden",timeout=180000)
                page.mouse.click(824,663)
                page.wait_for_timeout(1500)
                assert any(response.status==200 and response.request.method=="GET" for response in responses)
                page.screenshot(path=str(ARTIFACTS/"browser-leaderboard.png"))
                page.mouse.click(624,662)
                page.wait_for_timeout(500)
                page.mouse.click(948,598)
                deadline = time.monotonic()+180
                while not any(response.status==200 and response.request.method=="POST" for response in responses) and time.monotonic()<deadline:
                    page.wait_for_timeout(300)
                assert any(response.status==200 and response.request.method=="POST" for response in responses)
                assert all("rest_route=" in response.url for response in responses), "Old browser scores were not redirected to WordPress REST"
                page.screenshot(path=str(ARTIFACTS/"browser-game.png"))
                assert not errors, errors
                browser.close()
            print("PASS: existing browser game and assets, welcome leaderboard and timed-run registration through plugin Play link",flush=True)

            ready,go = temporary/"godot-ready",temporary/"godot-go"
            with (ARTIFACTS/"godot.log").open("w") as log:
                env = os.environ | {"XDG_DATA_HOME":"/workspace/.runtime/data","XDG_CONFIG_HOME":"/workspace/.runtime/config","XDG_CACHE_HOME":"/workspace/.runtime/cache"}
                process = subprocess.Popen([os.environ.get("SCOUT_TEST_GODOT","godot"),"--headless","--path",str(ROOT),"--script","tests/wordpress_speedrun.gd","--",base+rest,str(ready),str(go)],env=env,stdout=log,stderr=subprocess.STDOUT)
                try:
                    deadline = time.monotonic()+100
                    while not ready.exists() and process.poll() is None and time.monotonic()<deadline: time.sleep(0.1)
                    assert ready.exists(), "Godot did not register with WordPress"
                    backdate(ready.read_text())
                    go.write_text("ready")
                    assert process.wait(timeout=100)==0
                finally:
                    if process.poll() is None: process.kill();process.wait()
            output = (ARTIFACTS/"godot.log").read_text()
            assert "PASS:" in output and "ERROR:" not in output, output
            print(output,flush=True)

            # Root-hosted assets are also detected without moving /play/ or
            # copying the game. This mirrors the user's current installation.
            code,_,game = http("/index.php?sunny_scout=play")
            assert code==200 and '<base href="'+base+'/">' in game
            code,_,admin = http("/wp-admin/tools.php?page=sunny-scout-scores")
            assert "Game files found: WordPress root" in admin
            # Preserve already-versioned base URLs instead of overriding them.
            docker("exec",wp,"rm","/var/www/html/index.html")
            html = '<html><head><base href="/play/releases/test/"></head><body>new Engine( index.pck</body></html>'
            docker("exec","-i",wp,"php","-r","file_put_contents('/var/www/html/index.html',stream_get_contents(STDIN));",input=html)
            assert http("/index.php?sunny_scout=play")[2].count("<base ")==1
            docker("exec",wp,"rm","/var/www/html/index.html")
            # Reactivation retains posted times; it does not reset the board.
            saved = api()[2]["scores"]
            php("Sunny_Scout_Scores_Plugin::activate();")
            assert api()[2]["scores"]==saved
            print("PASS: root and /play/ detection, versioned base preservation, activation idempotency and retained database times",flush=True)
            version = php("global $wp_version; echo $wp_version;")
            (ARTIFACTS/"report.json").write_text(json.dumps({"wordpress":version,"database":"MariaDB 11.4","zip_upload_activation":True,"read_only_game_assets":True,"concurrent_starts":16,"browser_errors":errors,"native_godot":True,"root_and_play_detection":True,"browser_game_location":"WordPress root","versioned_base_preserved":True},indent=2))
            print("PASS: install-and-activate WordPress plugin integration complete",flush=True)
        finally:
            logs = subprocess.run(DOCKER+["logs",wp],capture_output=True,text=True)
            (ARTIFACTS/"wordpress.log").write_text(logs.stdout+logs.stderr)
            for name in (wp,db):
                subprocess.run(DOCKER+["rm","-f",name],capture_output=True)
            subprocess.run(DOCKER+["volume","rm",volume],capture_output=True)
            subprocess.run(DOCKER+["network","rm",network],capture_output=True)


if __name__ == "__main__":
    run()
