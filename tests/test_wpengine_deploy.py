"""Exercise upload integrity and failure recovery against an isolated filesystem."""

from contextlib import contextmanager, redirect_stdout
import io
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch
from urllib.parse import urljoin

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import deploy_wpengine as deploy


class LocalSFTP:
    """Only SFTP filesystem primitives; writes are recorded for scope checks."""

    def __init__(self, root):
        self.root = root
        self.writes = []
        self.fail_upload = None
        self.corrupt_upload = None
        self.fail_activation = False

    def local(self, remote):
        return self.root / remote.lstrip("/")

    def normalize(self, path):
        return "/" if path == "." else path

    def lstat(self, path):
        return self.local(path).lstat()

    def mkdir(self, path):
        self.writes.append(path)
        self.local(path).mkdir()

    def open(self, path, mode):
        if "w" in mode:
            self.writes.append(path)
        return self.local(path).open(mode)

    def put(self, source, target, confirm):
        self.writes.append(target)
        if self.fail_upload and target.endswith(self.fail_upload):
            raise OSError("Injected interrupted upload")
        shutil.copyfile(source, self.local(target))
        if self.corrupt_upload and target.endswith(self.corrupt_upload):
            content = self.local(target).read_bytes()
            self.local(target).write_bytes(bytes([content[0] ^ 1]) + content[1:])

    def rename(self, source, target):
        self.writes.extend([source, target])
        self.local(source).rename(self.local(target))

    def posix_rename(self, source, target):
        if self.fail_activation and target == "/play/index.html":
            raise OSError("Injected atomic rename failure")
        self.writes.extend([source, target])
        self.local(source).replace(self.local(target))

    def remove(self, path):
        self.writes.append(path)
        self.local(path).unlink()


class DeploymentTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.remote = self.root / "server"
        self.remote.mkdir()
        for name in ["wp-admin", "wp-content", "wp-includes"]:
            (self.remote / name).mkdir()
        (self.remote / "index.php").write_text("existing WordPress entry")
        self.sftp = LocalSFTP(self.remote)
        self.build = self.root / "build"
        self.build.mkdir()
        for name in deploy.TOP_FILES - {"index.html"}:
            (self.build / name).write_bytes(b"fixture")
        for folder, names in deploy.CHUNKS.items():
            (self.build / folder).mkdir()
            for name in names.split():
                (self.build / folder / (name + ".jpg")).write_bytes(b"painted scenery")
        (self.build / "scout-backdrop-123abc.jpg").write_bytes(b"loading illustration")
        (self.build / "scout-logo-456def.png").write_bytes(b"logo")
        config = {"executable": "index", "fileSizes": {"index.pck": 7, "index.wasm": 7}}
        (self.build / "index.html").write_text(
            '<html><head><title>Sunny Scout</title></head><body><script src="index.js"></script>'
            '<script>window.scoutLoading = {};\nconst config = ' + json.dumps(config) + ';</script></body></html>'
        )

    def upload(self):
        with redirect_stdout(io.StringIO()):
            return deploy.deploy(self.sftp, deploy.web_root(self.sftp), deploy.collect_assets(self.build))

    def current(self):
        return (self.remote / "play/index.html").read_bytes()

    def change_build(self):
        (self.build / "index.pck").write_bytes(b"changed")

    def test_full_release_activation_and_rollback_keep_wordpress_and_old_assets(self):
        first = self.upload()
        first_entry = self.current()
        self.assertIn(f'/play/releases/{first}/'.encode(), first_entry)
        assets = deploy.collect_assets(self.build)
        self.assertEqual(len(assets), 30)
        for asset in assets:
            self.assertEqual((self.remote / "play/releases" / first / asset.name).read_bytes(), asset.source.read_bytes())
            self.assertTrue(urljoin(f"{deploy.PUBLIC_URL}releases/{first}/", asset.name).startswith(deploy.PUBLIC_URL + "releases/"))
        self.change_build()
        second = self.upload()
        self.assertNotEqual(first, second)
        self.assertEqual((self.remote / "play/.previous-index.html").read_bytes(), first_entry)
        with redirect_stdout(io.StringIO()):
            deploy.rollback(self.sftp, "/")
        self.assertEqual(self.current(), first_entry)
        self.assertTrue((self.remote / "play/releases" / second / "index.pck").exists())
        self.assertEqual((self.remote / "index.php").read_text(), "existing WordPress entry")
        self.assertTrue(all(path.startswith("/play/") or path == "/play" for path in self.sftp.writes))

    def test_upload_interruption_and_corruption_leave_active_entry_unchanged(self):
        self.upload()
        original = self.current()
        self.change_build()
        self.sftp.fail_upload = "/index.pck"
        with self.assertRaisesRegex(OSError, "interrupted"):
            self.upload()
        self.assertEqual(self.current(), original)
        self.sftp.fail_upload = None
        self.sftp.corrupt_upload = "/index.pck"
        with self.assertRaisesRegex(ValueError, "SHA-256"):
            self.upload()
        self.assertEqual(self.current(), original)

    def test_repeated_deploy_does_not_replace_rollback_with_the_same_release(self):
        self.upload()
        first = self.current()
        self.change_build()
        self.upload()
        current = self.current()
        self.sftp.writes.clear()
        self.upload()
        self.assertEqual(self.current(), current)
        self.assertEqual((self.remote / "play/.previous-index.html").read_bytes(), first)
        self.assertEqual(self.sftp.writes, [])

    def test_atomic_activation_failure_preserves_current_and_cleans_temp_entry(self):
        self.upload()
        original = self.current()
        self.change_build()
        self.sftp.fail_activation = True
        with self.assertRaisesRegex(OSError, "rename failure"):
            self.upload()
        self.assertEqual(self.current(), original)
        self.assertFalse(list((self.remote / "play").glob("index.html.*.tmp")))

    def test_wrong_root_symlink_and_unrecognized_index_are_rejected_before_writes(self):
        with self.assertRaisesRegex(ValueError, "web root"):
            deploy.web_root(self.sftp, "/wp-content")
        (self.remote / "play").symlink_to(self.remote / "wp-content", target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "real directory"):
            self.upload()
        (self.remote / "play").unlink()
        (self.remote / "play").mkdir()
        (self.remote / "play/index.html").write_text("an unrelated existing page")
        with self.assertRaisesRegex(ValueError, "not recognized"):
            self.upload()
        self.assertEqual(self.sftp.writes, [])

    def test_incomplete_mixed_and_symlinked_builds_are_rejected(self):
        chunk = self.build / "earth_chunks/pinewood.jpg"
        chunk.unlink()
        with self.assertRaisesRegex(ValueError, "missing"):
            deploy.collect_assets(self.build)
        chunk.symlink_to(self.build / "index.pck")
        with self.assertRaisesRegex(ValueError, "Symlinks"):
            deploy.collect_assets(self.build)
        chunk.unlink()
        chunk.write_bytes(b"scenery")
        (self.build / "index.pck").write_bytes(b"another-sized-export")
        with self.assertRaisesRegex(ValueError, "size mismatch"):
            deploy.collect_assets(self.build)

    def test_check_is_read_only_even_when_play_directory_is_missing(self):
        @contextmanager
        def connection():
            yield self.sftp

        with patch.object(deploy, "connect", connection), patch.object(sys, "argv", ["deploy", "check", "--build-dir", str(self.build)]), redirect_stdout(io.StringIO()):
            deploy.main()
        self.assertEqual(self.sftp.writes, [])
        self.assertFalse((self.remote / "play").exists())

    def test_changed_html_after_validation_cannot_activate(self):
        assets = deploy.collect_assets(self.build)
        (self.build / "index.html").write_text("changed after validation")
        with self.assertRaisesRegex(ValueError, "changed after validation"):
            deploy.entry_html(assets, deploy.release_id(assets))


if __name__ == "__main__":
    unittest.main()
