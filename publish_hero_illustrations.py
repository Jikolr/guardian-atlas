"""Verify prepared hero artwork; publish its GitHub release only with --publish.

The release folder contains release-manifest.json with version, releaseTag, repo
and assets [{name, path, bytes, sha256}]. Paths are relative to that folder.
This command never replaces a conflicting remote asset or changes the website.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import http.client
import json
import mimetypes
import os
from pathlib import Path
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request


CHUNK = 4 * 1024 * 1024
API = "https://api.github.com"
MAX_ASSETS = 1000
MAX_ASSET_BYTES = 2 * 1024 * 1024 * 1024


@dataclass(frozen=True)
class Asset:
    name: str
    path: Path
    size: int
    sha256: str
    mtime_ns: int

    def unchanged(self) -> bool:
        stat = self.path.stat()
        return stat.st_size == self.size and stat.st_mtime_ns == self.mtime_ns


def hash_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(CHUNK), b""):
            digest.update(block)
    return digest.hexdigest()


def verify_prepared(folder: Path) -> tuple[dict, list[Asset]]:
    folder = folder.resolve(strict=True)
    manifest = json.loads((folder / "release-manifest.json").read_text(encoding="utf-8-sig"))
    repo, version, tag = manifest.get("repo"), manifest.get("version"), manifest.get("releaseTag")
    if not isinstance(repo, str) or not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repo):
        raise RuntimeError("The manifest has an invalid GitHub repository.")
    if not isinstance(version, str) or not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise RuntimeError("The manifest must identify a game version such as 3.57.0.")
    if tag != "hero-illustrations-" + version:
        raise RuntimeError("The manifest release tag does not match its game version.")
    entries = manifest.get("assets")
    if not isinstance(entries, list) or not entries:
        raise RuntimeError("The manifest contains no release assets.")
    if len(entries) > MAX_ASSETS:
        raise RuntimeError("A release may contain at most 1000 assets; split this collection before publishing.")
    names, assets = set(), []
    for row in entries:
        name = row.get("name")
        if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,254}", name):
            raise RuntimeError("The manifest contains an unsafe release asset name.")
        if name.casefold() in names:
            raise RuntimeError("The manifest repeats an asset name: " + name)
        names.add(name.casefold())
        relative = row.get("path", name)
        if not isinstance(relative, str) or Path(relative).is_absolute():
            raise RuntimeError("Asset path must be relative to the release folder: " + name)
        path = (folder / relative).resolve(strict=True)
        if not path.is_relative_to(folder) or not path.is_file():
            raise RuntimeError("Asset path escapes the release folder or is not a file: " + name)
        size, sha256 = row.get("bytes"), row.get("sha256")
        if type(size) is not int or size < 0 or not isinstance(sha256, str) or not re.fullmatch(r"[0-9a-f]{64}", sha256):
            raise RuntimeError("Invalid byte count or SHA-256 for " + name)
        if size >= MAX_ASSET_BYTES:
            raise RuntimeError("Release assets must be smaller than 2 GiB: " + name)
        before = path.stat()
        if before.st_size != size or hash_file(path) != sha256:
            raise RuntimeError("Prepared asset differs from its manifest: " + name)
        after = path.stat()
        if after.st_size != before.st_size or after.st_mtime_ns != before.st_mtime_ns:
            raise RuntimeError("Prepared asset changed while verifying it: " + name)
        assets.append(Asset(name, path, size, sha256, after.st_mtime_ns))
    return manifest, assets


def credential(account: str, node: str) -> str:
    # Read only the requested account through the existing credential providers.
    environment = dict(os.environ, GIT_TERMINAL_PROMPT="0", GCM_INTERACTIVE="Never")
    result = subprocess.run(
        ["git", "-c", "credential.interactive=never", "credential", "fill"],
        input="protocol=https\nhost=github.com\nusername=" + account + "\n\n",
        text=True, capture_output=True, env=environment, timeout=20,
    )
    values = dict(line.split("=", 1) for line in result.stdout.splitlines() if "=" in line)
    if values.get("password"):
        return values["password"]
    desktop = Path(os.environ.get("LOCALAPPDATA", "")) / "GitHubDesktop"
    providers = list(desktop.glob("app-*/resources/app/keytar.node"))
    providers.sort(key=lambda path: tuple(int(n) for n in re.findall(r"\d+", path.parents[2].name)), reverse=True)
    if providers:
        script = (
            "const k=require(process.argv[1]);"
            "k.getPassword('GitHub - https://api.github.com',process.argv[2])"
            ".then(p=>{if(p)process.stdout.write(p);else process.exitCode=1})"
            ".catch(()=>process.exitCode=1)"
        )
        result = subprocess.run([node, "-e", script, str(providers[0]), account], capture_output=True, text=True, timeout=20)
        if result.returncode == 0 and re.fullmatch(r"[A-Za-z0-9_]+", result.stdout):
            return result.stdout
    raise RuntimeError("GitHub credentials are unavailable for the requested account.")


class GitHub:
    def __init__(self, token: str):
        self.token = token
        self.headers = {"Accept": "application/vnd.github+json", "User-Agent": "Guardian-Atlas-Hero-Illustrations", "X-GitHub-Api-Version": "2022-11-28"}

    def request(self, url: str, *, method="GET", body=None, accept=None):
        headers = {**self.headers}
        if accept:
            headers["Accept"] = accept
        data = None
        if body is not None:
            data = json.dumps(body).encode("utf-8")
            headers["Content-Type"] = "application/json"
        request = urllib.request.Request(url, data=data, method=method, headers=headers)
        # A signed binary download may redirect to the asset CDN. Do not forward the account token.
        request.add_unredirected_header("Authorization", "Bearer " + self.token)
        return urllib.request.urlopen(request, timeout=60)

    def api(self, path: str, method="GET", body=None):
        with self.request(API + path, method=method, body=body) as response:
            return None if response.status == 204 else json.load(response)

    def list_assets(self, base: str, release_id: int) -> dict:
        result, page = {}, 1
        while True:
            chunk = self.api(base + "/releases/" + str(release_id) + "/assets?per_page=100&page=" + str(page))
            for item in chunk:
                if item["name"] in result:
                    raise RuntimeError("The release has duplicate asset names.")
                result[item["name"]] = item
            if len(chunk) < 100:
                return result
            page += 1

    def valid_asset(self, remote: dict, asset: Asset) -> bool:
        if remote.get("name") != asset.name or remote.get("size") != asset.size or remote.get("state") != "uploaded":
            return False
        if remote.get("digest"):
            return remote["digest"].lower() == "sha256:" + asset.sha256
        # Older API responses omit digest; hash the authenticated binary response instead.
        url = remote.get("url", "")
        if urllib.parse.urlsplit(url).netloc != "api.github.com" or not url.startswith(API + "/repos/"):
            raise RuntimeError("Unexpected release asset API URL.")
        digest, count = hashlib.sha256(), 0
        with self.request(url, accept="application/octet-stream") as response:
            for block in iter(lambda: response.read(CHUNK), b""):
                count += len(block)
                digest.update(block)
        return count == asset.size and digest.hexdigest() == asset.sha256

    def upload(self, release: dict, asset: Asset) -> dict:
        if not asset.unchanged():
            raise RuntimeError("Prepared asset changed after verification: " + asset.name)
        url = urllib.parse.urlsplit(release["upload_url"].split("{", 1)[0])
        if url.scheme != "https" or url.netloc != "uploads.github.com" or not url.path.startswith("/repos/"):
            raise RuntimeError("Unexpected GitHub upload URL.")
        connection = http.client.HTTPSConnection(url.netloc, timeout=180)
        try:
            connection.putrequest("POST", url.path + "?" + urllib.parse.urlencode({"name": asset.name}))
            headers = {**self.headers, "Authorization": "Bearer " + self.token, "Content-Length": str(asset.size), "Content-Type": mimetypes.guess_type(asset.name)[0] or "application/octet-stream"}
            for key, value in headers.items():
                connection.putheader(key, value)
            connection.endheaders()
            digest, count = hashlib.sha256(), 0
            with asset.path.open("rb") as stream:
                for block in iter(lambda: stream.read(CHUNK), b""):
                    digest.update(block)
                    count += len(block)
                    connection.send(block)
            response = connection.getresponse()
            body, status = response.read(), response.status
            if count != asset.size or digest.hexdigest() != asset.sha256 or not asset.unchanged():
                raise RuntimeError("Asset changed during upload; release remains a draft: " + asset.name)
            if status != 201:
                raise RuntimeError("Upload returned HTTP " + str(status) + " for " + asset.name + ". Retry to inspect and resume the draft.")
            return json.loads(body)
        finally:
            connection.close()


def find_release(github: GitHub, base: str, tag: str):
    try:
        return github.api(base + "/releases/tags/" + urllib.parse.quote(tag, safe=""))
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise
    matches, page = [], 1
    while True:
        releases = github.api(base + "/releases?per_page=100&page=" + str(page))
        matches.extend(release for release in releases if release.get("tag_name") == tag)
        if len(releases) < 100:
            break
        page += 1
    if len(matches) > 1:
        raise RuntimeError("Multiple releases use this tag; resolve the ambiguity before publishing.")
    return matches[0] if matches else None


def publish(folder: Path, manifest: dict, assets: list[Asset], account: str, node: str) -> dict:
    github = GitHub(credential(account, node))
    identity = github.api("/user")
    if str(identity.get("login", "")).casefold() != account.casefold():
        raise RuntimeError("The available credential belongs to a different account; no release was changed.")
    base, tag = "/repos/" + manifest["repo"], manifest["releaseTag"]
    release = find_release(github, base, tag)
    if not release:
        body_path = folder / "RELEASE.md"
        body = body_path.read_text(encoding="utf-8-sig") if body_path.is_file() else (
            "Original Guardian Tales hero illustrations from game version " + manifest["version"]
            + ". Character artwork and supported effect variants are supplied as transparent PNGs."
            + "\n\nAll " + str(len(assets)) + " assets were verified against the prepared SHA-256 manifest."
        )
        release = github.api(base + "/releases", "POST", {"tag_name": tag, "target_commitish": manifest.get("targetCommitish", "main"), "name": manifest.get("releaseName", "Guardian Tales hero illustrations — " + manifest["version"]), "body": body, "draft": True, "prerelease": False})
        print("Created draft", release["html_url"], flush=True)
    else:
        print("Inspecting existing release", release["html_url"], flush=True)
    existing = github.list_assets(base, release["id"])
    # Check all conflicts before uploading anything, even when the conflict is late in the manifest.
    for asset in assets:
        if asset.name in existing and not github.valid_asset(existing[asset.name], asset):
            raise RuntimeError("Existing release asset differs or is incomplete; it was not overwritten: " + asset.name)
    missing = [asset for asset in assets if asset.name not in existing]
    if missing and not release.get("draft"):
        raise RuntimeError("The published release is incomplete; refusing to change it.")
    for index, asset in enumerate(missing, 1):
        print("Uploading", index, "/", len(missing), asset.name, flush=True)
        remote = github.upload(release, asset)
        if not github.valid_asset(remote, asset):
            raise RuntimeError("Uploaded asset did not verify; release remains a draft: " + asset.name)
    print("Verifying all remote assets before publication…", flush=True)
    remote_assets = github.list_assets(base, release["id"])
    for asset in assets:
        if not asset.unchanged() or asset.name not in remote_assets or not github.valid_asset(remote_assets[asset.name], asset):
            raise RuntimeError("Final release verification failed: " + asset.name)
    if release.get("draft"):
        release = github.api(base + "/releases/" + str(release["id"]), "PATCH", {"draft": False})
    if release.get("draft"):
        raise RuntimeError("GitHub did not confirm publication.")
    result = {"url": release["html_url"], "id": release["id"], "tag": tag, "repo": manifest["repo"], "version": manifest["version"], "assets": len(assets), "bytes": sum(asset.size for asset in assets), "verified": True, "releasePublished": True}
    (folder / "publication.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release-dir", "--release", dest="release_dir", type=Path, required=True, help="Prepared folder containing release-manifest.json")
    parser.add_argument("--desktop-account", default="Jikolr", help="Existing GitHub account to use; checked against /user (default: Jikolr)")
    parser.add_argument("--node", default="node", help="Node executable for GitHub Desktop's existing credential provider")
    parser.add_argument("--publish", action="store_true", help="Upload, verify and publish the prepared release")
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9-]+", args.desktop_account):
        parser.error("Invalid GitHub account name")
    folder = args.release_dir.resolve(strict=True)
    manifest, assets = verify_prepared(folder)
    print("Verified prepared hero artwork:", manifest["version"], len(assets), "assets,", sum(asset.size for asset in assets), "bytes", flush=True)
    if not args.publish:
        print("No remote changes made. Supply --publish to upload and publish this verified collection.", flush=True)
        return
    result = publish(folder, manifest, assets, args.desktop_account, args.node)
    print("PUBLISHED", result["url"], flush=True)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        # Do not echo credential-provider output or raw HTTP responses.
        detail = str(error) if isinstance(error, RuntimeError) else "Inspect the prepared files and release state before retrying."
        print("Publication stopped:", type(error).__name__, detail, file=sys.stderr, flush=True)
        raise SystemExit(1)
