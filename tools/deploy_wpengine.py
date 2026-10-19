#!/usr/bin/env python3
"""Explicit, versioned Sunny Scout SFTP deployments confined to WordPress /play."""

import argparse
import base64
from contextlib import contextmanager
from dataclasses import dataclass
import getpass
import hashlib
import json
import os
from pathlib import Path
import posixpath
import re
import socket
import stat
import sys
import uuid

HOST = "sunnyscout.sftp.wpengine.com"
PORT = 2222
USER = "sunnyscout-git"
PUBLIC_URL = "https://playsunnyscout.com/play/"
REPO = Path(__file__).resolve().parents[1]
TOP_FILES = {
    "FONT_LICENSE.txt", "index.html", "index.js", "index.wasm", "index.pck",
    "index.png", "index.icon.png", "index.apple-touch-icon.png",
    "index.audio.worklet.js", "index.audio.position.worklet.js",
}
CHUNKS = {
    "earth_chunks": "copper_hollow crystal_depths pinewood quarry ridge willow",
    "frost_chunks": "aurora_shelf blue_echo deep_prism frozen_basin glacier_crown prism_pass",
    "ember_chunks": "dune_sea magma_vault obsidian_rise redrock_arches sunfire_cavern sunken_oasis",
}
MARKER = 'name="sunny-scout-release"'


@dataclass(frozen=True)
class Asset:
    name: str
    source: Path
    size: int
    digest: str


def digest_stream(stream):
    result = hashlib.sha256()
    for block in iter(lambda: stream.read(1024 * 1024), b""):
        result.update(block)
    return result.hexdigest()


def collect_assets(directory):
    directory = Path(directory).resolve()
    files = {}
    for path in directory.rglob("*"):
        if path.is_symlink():
            raise ValueError(f"Symlinks are not build assets: {path.name}")
        if path.is_file() and path.suffix != ".import":
            files[path.relative_to(directory).as_posix()] = path
    # A direct Godot export keeps the font notice in the source assets folder.
    if "FONT_LICENSE.txt" not in files and directory == (REPO / "build/web").resolve():
        files["FONT_LICENSE.txt"] = REPO / "assets/ui/FONT_LICENSE.txt"
    expected = TOP_FILES | {
        f"{folder}/{name}.jpg" for folder, names in CHUNKS.items() for name in names.split()
    }
    artwork = {name for name in files if re.fullmatch(r"scout-(backdrop-[a-f0-9]+\.jpg|logo-[a-f0-9]+\.png)", name)}
    if len(artwork) != 2 or not any(name.startswith("scout-backdrop-") for name in artwork):
        raise ValueError("Build needs one hashed loading illustration and one logo")
    expected |= artwork
    if set(files) != expected:
        raise ValueError(f"Incomplete/unexpected build: missing {sorted(expected-files.keys())}; extra {sorted(files.keys()-expected)}")
    assets = []
    for name, path in sorted(files.items()):
        if not path.is_file() or path.stat().st_size == 0:
            raise ValueError(f"Empty/missing build asset: {name}")
        with path.open("rb") as stream:
            assets.append(Asset(name, path, path.stat().st_size, digest_stream(stream)))
    html = files["index.html"].read_text()
    match = re.search(r"const config = (\{[^\n]+\});", html)
    if not match or "window.scoutLoading" not in html:
        raise ValueError("Not the Sunny Scout Web export")
    config = json.loads(match.group(1))
    for name in ["index.pck", "index.wasm"]:
        if config.get("fileSizes", {}).get(name) != files[name].stat().st_size:
            raise ValueError(f"HTML/runtime size mismatch: {name}; export the whole build again")
    if re.search(r"<base\b", html, re.I):
        raise ValueError("Build already has a base URL; use the original browser export")
    return assets


def release_id(assets):
    inventory = "\n".join(f"{asset.name} {asset.digest}" for asset in assets)
    return hashlib.sha256(inventory.encode()).hexdigest()[:20]


def entry_html(assets, release):
    asset = next(asset for asset in assets if asset.name == "index.html")
    data = asset.source.read_bytes()
    if hashlib.sha256(data).hexdigest() != asset.digest:
        raise ValueError("Build HTML changed after validation")
    html = data.decode()
    if not re.fullmatch(r"[a-f0-9]{20}", release):
        raise ValueError("Invalid release ID")
    head = (f'<head>\n\t<base href="/play/releases/{release}/">'
            f'\n\t<meta {MARKER} content="{release}">')
    html, count = re.subn(r"<head>", lambda _: head, html, count=1, flags=re.I)
    if count != 1:
        raise ValueError("Export has no HTML head")
    return html.encode()


def exists(sftp, path):
    try:
        return sftp.lstat(path)
    except FileNotFoundError:
        return None


def require_directory(sftp, path, create=False):
    info = exists(sftp, path)
    if info is None and create:
        sftp.mkdir(path)
        info = sftp.lstat(path)
    if info is None or not stat.S_ISDIR(info.st_mode):
        raise ValueError(f"Expected a real directory, not a link: {path}")


def web_root(sftp, override=None):
    candidates = [override] if override else [sftp.normalize("."), "/sites/sunnyscout", "/public_html", "/htdocs"]
    for path in dict.fromkeys(candidates):
        if not path or not path.startswith("/") or ".." in path.split("/"):
            continue
        try:
            require_directory(sftp, path)
            for name in ["wp-admin", "wp-content", "wp-includes"]:
                require_directory(sftp, posixpath.join(path, name))
            return path.rstrip("/") or "/"
        except (ValueError, FileNotFoundError):
            continue
    raise ValueError("Could not verify the WordPress web root; set WPE_WEB_ROOT to its SFTP path")


def read_optional(sftp, path):
    info = exists(sftp, path)
    if info is None:
        return None
    if not stat.S_ISREG(info.st_mode) or info.st_size > 2 * 1024 * 1024:
        raise ValueError(f"Not a regular game entry file: {path}")
    with sftp.open(path, "rb") as stream:
        return stream.read()


def inspect_target(sftp, root):
    target = posixpath.join(root, "play")
    if exists(sftp, target):
        require_directory(sftp, target)
    current = read_optional(sftp, target + "/index.html")
    if current and MARKER.encode() not in current and b"window.scoutLoading" not in current:
        raise ValueError("Existing /play/index.html is not recognized as Sunny Scout; nothing changed")
    return target, current


def atomic_write(sftp, destination, data):
    temporary = destination + "." + uuid.uuid4().hex + ".tmp"
    try:
        with sftp.open(temporary, "wb") as stream:
            stream.write(data)
        with sftp.open(temporary, "rb") as stream:
            if stream.read() != data:
                raise ValueError("Game entry verification failed before activation")
        # Fail closed if the server cannot replace an entry atomically.
        sftp.posix_rename(temporary, destination)
    finally:
        if exists(sftp, temporary):
            sftp.remove(temporary)


def verify_asset(sftp, path, asset):
    info = sftp.lstat(path)
    if not stat.S_ISREG(info.st_mode) or info.st_size != asset.size:
        raise ValueError(f"Remote size/type mismatch: {asset.name}")
    with sftp.open(path, "rb") as stream:
        if digest_stream(stream) != asset.digest:
            raise ValueError(f"Remote SHA-256 mismatch: {asset.name}")


def deploy(sftp, root, assets):
    target, current = inspect_target(sftp, root)
    release = release_id(assets)
    require_directory(sftp, target, create=True)
    releases = target + "/releases"
    require_directory(sftp, releases, create=True)
    destination = releases + "/" + release
    staged = destination + ".upload-" + uuid.uuid4().hex
    if not exists(sftp, destination):
        require_directory(sftp, staged, create=True)
        for folder in CHUNKS:
            require_directory(sftp, staged + "/" + folder, create=True)
        for asset in assets:
            remote = staged + "/" + asset.name
            sftp.put(str(asset.source), remote, confirm=True)
            verify_asset(sftp, remote, asset)
            print(f"Verified {asset.name}")
        sftp.rename(staged, destination)
    else:
        require_directory(sftp, destination)
        for asset in assets:
            verify_asset(sftp, destination + "/" + asset.name, asset)
    new_entry = entry_html(assets, release)
    if current == new_entry:
        print("This complete release is already active")
        return release
    if current is not None:
        atomic_write(sftp, target + "/.previous-index.html", current)
    atomic_write(sftp, target + "/index.html", new_entry)
    return release


def rollback(sftp, root):
    target, current = inspect_target(sftp, root)
    previous = read_optional(sftp, target + "/.previous-index.html")
    if not current or not previous or MARKER.encode() not in previous:
        raise ValueError("No previous versioned game entry is available to restore")
    match = re.search(rb'content="([a-f0-9]{20})"', previous)
    if match is None:
        raise ValueError("Previous entry has no valid release")
    require_directory(sftp, target + "/releases/" + match.group(1).decode())
    atomic_write(sftp, target + "/index.html", previous)
    print("Restored the previous game entry")


@contextmanager
def connect(host_key_only=False):
    import paramiko
    if host_key_only:
        with socket.create_connection((HOST, PORT), timeout=20) as sock:
            transport = paramiko.Transport(sock)
            try:
                transport.start_client(timeout=20)
                key = transport.get_remote_server_key()
                print(f"[{HOST}]:{PORT} {key.get_name()} {key.get_base64()}")
                fingerprint = base64.b64encode(hashlib.sha256(key.asbytes()).digest()).decode().rstrip("=")
                print(f"SSH host fingerprint: SHA256:{fingerprint}", file=sys.stderr)
                yield None
            finally:
                transport.close()
        return
    client = paramiko.SSHClient()
    client.load_system_host_keys()
    known = REPO / ".deploy/known_hosts"
    if known.exists():
        client.load_host_keys(str(known))
    supplied_key = os.environ.get("WPE_SFTP_KNOWN_HOSTS", "")
    for line in supplied_key.splitlines():
        if line.strip() and not line.startswith("#"):
            entry = paramiko.hostkeys.HostKeyEntry.from_line(line)
            if entry is None:
                raise ValueError("Malformed WPE_SFTP_KNOWN_HOSTS")
            for hostname in entry.hostnames:
                client.get_host_keys().add(hostname, entry.key.get_name(), entry.key)
    password = os.environ.get("WPE_SFTP_PASSWORD")
    if not password:
        if not sys.stdin.isatty():
            raise ValueError("Set WPE_SFTP_PASSWORD as a secret; credentials are never saved in the repository")
        password = getpass.getpass("WP Engine SFTP password: ")
    try:
        client.connect(HOST, port=PORT, username=USER, password=password,
                       look_for_keys=False, allow_agent=False, timeout=20,
                       auth_timeout=20, banner_timeout=20)
        with client.open_sftp() as sftp:
            sftp.get_channel().settimeout(120)
            yield sftp
    finally:
        client.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("operation", choices=["plan", "host-key", "check", "deploy", "rollback"])
    parser.add_argument("--build-dir", type=Path, default=REPO / "build/web")
    args = parser.parse_args()
    if args.operation == "host-key":
        with connect(host_key_only=True):
            return
    assets = collect_assets(args.build_dir) if args.operation != "rollback" else None
    if assets:
        print(f"Validated {len(assets)} assets ({sum(asset.size for asset in assets):,} bytes), release {release_id(assets)}")
    if args.operation == "plan":
        print(f"No connection or upload. Destination: {PUBLIC_URL}")
        return
    with connect() as sftp:
        root = web_root(sftp, os.environ.get("WPE_WEB_ROOT"))
        target, _ = inspect_target(sftp, root)
        print(f"Verified WordPress web root: {root}; game directory: {target}")
        if args.operation == "check":
            print("Read-only connection check passed; no directories or game files changed")
        elif args.operation == "deploy":
            release = deploy(sftp, root, assets)
            print(f"Activated {PUBLIC_URL} (release {release})")
        else:
            rollback(sftp, root)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        # Never print connection internals or environment/credential values.
        print(f"Deployment stopped: {type(error).__name__}: {error}", file=sys.stderr)
        sys.exit(1)
