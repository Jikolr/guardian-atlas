"""Offline publication safety checks; no credentials or network are used."""

import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import publish_hero_illustrations as publisher


class FakeGitHub:
    def __init__(self, draft=True, existing=None):
        self.release = {"id": 1, "draft": draft, "tag_name": "hero-illustrations-3.57.0", "html_url": "https://github.com/Jikolr/guardian-atlas/releases/tag/hero-illustrations-3.57.0"}
        self.assets = dict(existing or {})
        self.uploads, self.changes = [], []
        self.corrupt_upload = False

    def api(self, path, method="GET", body=None):
        if path == "/user":
            return {"login": "Jikolr"}
        if "/releases/tags/" in path:
            return dict(self.release)
        if method == "PATCH":
            self.changes.append((method, body))
            self.release.update(body)
            return dict(self.release)
        raise AssertionError("Unexpected API operation: " + method + " " + path)

    def list_assets(self, base, release_id):
        return dict(self.assets)

    def valid_asset(self, remote, asset):
        return remote.get("sha256") == asset.sha256 and remote.get("bytes") == asset.size

    def upload(self, release, asset):
        self.uploads.append(asset.name)
        result = {"sha256": "bad" if self.corrupt_upload else asset.sha256, "bytes": asset.size}
        self.assets[asset.name] = result
        return result


class PublicationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="hero-publication-test-")
        self.folder = Path(self.temporary.name)
        self.manifest = {"version": "3.57.0", "releaseTag": "hero-illustrations-3.57.0", "repo": "Jikolr/guardian-atlas", "assets": []}
        for name, data in [("hero.png", b"first verified image"), ("effects.png", b"second verified image")]:
            (self.folder / name).write_bytes(data)
            self.manifest["assets"].append({"name": name, "path": name, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()})
        self.save_manifest()

    def tearDown(self):
        self.temporary.cleanup()

    def save_manifest(self):
        (self.folder / "release-manifest.json").write_text(json.dumps(self.manifest), encoding="utf-8")

    def publish_with(self, remote):
        manifest, assets = publisher.verify_prepared(self.folder)
        with patch.object(publisher, "credential", return_value="test-token"), patch.object(publisher, "GitHub", return_value=remote):
            return publisher.publish(self.folder, manifest, assets, "Jikolr", "node")

    def test_local_hash_mismatch_stops_preparation(self):
        (self.folder / "hero.png").write_bytes(b"changed")
        with self.assertRaisesRegex(RuntimeError, "differs"):
            publisher.verify_prepared(self.folder)

    def test_manifest_cannot_escape_its_folder(self):
        self.manifest["assets"][0]["path"] = str((self.folder / "hero.png").resolve())
        self.save_manifest()
        with self.assertRaisesRegex(RuntimeError, "relative"):
            publisher.verify_prepared(self.folder)

    def test_duplicate_names_are_rejected(self):
        self.manifest["assets"].append(self.manifest["assets"][0])
        self.save_manifest()
        with self.assertRaisesRegex(RuntimeError, "repeats"):
            publisher.verify_prepared(self.folder)

    def test_asset_count_limit_is_checked_before_hashing(self):
        self.manifest["assets"] = [self.manifest["assets"][0]] * 1001
        self.save_manifest()
        with patch.object(publisher, "hash_file", side_effect=AssertionError("Should not hash")):
            with self.assertRaisesRegex(RuntimeError, "at most 1000"):
                publisher.verify_prepared(self.folder)

    def test_asset_size_limit_is_checked_before_hashing(self):
        self.manifest["assets"][0]["bytes"] = 2 * 1024 * 1024 * 1024
        self.save_manifest()
        with patch.object(publisher, "hash_file", side_effect=AssertionError("Should not hash")):
            with self.assertRaisesRegex(RuntimeError, "smaller than 2 GiB"):
                publisher.verify_prepared(self.folder)

    def test_late_conflict_is_detected_before_uploading_anything(self):
        remote = FakeGitHub(existing={"effects.png": {"sha256": "different", "bytes": 21}})
        with self.assertRaisesRegex(RuntimeError, "not overwritten"):
            self.publish_with(remote)
        self.assertEqual(remote.uploads, [])
        self.assertEqual(remote.changes, [])
        self.assertFalse((self.folder / "publication.json").exists())

    def test_successful_publish_verifies_and_is_idempotent(self):
        remote = FakeGitHub()
        result = self.publish_with(remote)
        self.assertTrue(result["releasePublished"])
        self.assertEqual(remote.uploads, ["hero.png", "effects.png"])
        self.assertEqual(remote.changes, [("PATCH", {"draft": False})])
        self.assertTrue(json.loads((self.folder / "publication.json").read_text())["verified"])
        self.publish_with(remote)
        self.assertEqual(len(remote.uploads), 2)
        self.assertEqual(len(remote.changes), 1)

    def test_bad_upload_does_not_publish(self):
        remote = FakeGitHub()
        remote.corrupt_upload = True
        with self.assertRaisesRegex(RuntimeError, "did not verify"):
            self.publish_with(remote)
        self.assertTrue(remote.release["draft"])
        self.assertEqual(remote.changes, [])
        self.assertFalse((self.folder / "publication.json").exists())

    def test_missing_published_asset_is_not_added(self):
        remote = FakeGitHub(draft=False)
        with self.assertRaisesRegex(RuntimeError, "refusing to change"):
            self.publish_with(remote)
        self.assertEqual(remote.uploads, [])
        self.assertEqual(remote.changes, [])

    def test_wrong_account_is_rejected_before_release_lookup(self):
        remote = FakeGitHub()
        original = remote.api
        remote.api = lambda path, method="GET", body=None: {"login": "different-account"} if path == "/user" else original(path, method, body)
        with self.assertRaisesRegex(RuntimeError, "different account"):
            self.publish_with(remote)
        self.assertEqual(remote.uploads, [])


if __name__ == "__main__":
    unittest.main()
