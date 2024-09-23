import hashlib
import re
import sys
from typing import List, Optional, Tuple

import requests
from invoke import exceptions
from invoke.context import Context
from invoke.tasks import task

# a platform is an OS and an architecture
Platform = Tuple[str, str]

# list all platforms used in the repo
# store the platform names in the format expected by Go
# see https://go.dev/dl/ for the full list of platforms
PLATFORMS: List[Platform] = [
    ("linux", "amd64"),
    ("linux", "arm64"),
    ("linux", "armv6l"),
    ("windows", "amd64"),
]


def _get_archive_extension(os: str) -> str:
    """returns the extension of the archive for the given os"""
    if os == "windows":
        return "zip"
    return "tar.gz"


def _get_expected_sha256(version: str) -> List[Tuple[Platform, str]]:
    """returns a map from platform to sha of the archive"""

    shas: List[Tuple[Platform, str]] = []
    for os, arch in PLATFORMS:
        ext = _get_archive_extension(os)
        url = f"https://storage.googleapis.com/golang/go{version}.{os}-{arch}.{ext}.sha256"
        res = requests.get(url)
        res.raise_for_status()

        sha = res.text.strip()
        if len(sha) != 64:
            raise exceptions.Exit(
                f"The SHA256 of Go on {os}/{arch} has an unexpected format: '{sha}'"
            )
        shas.append(((os, arch), sha))
    return shas


def _check_archive(version: str, shas: List[Tuple[Platform, str]], base_url: str):
    """checks that the archive sha is the same as the given one"""
    for (os, arch), expected_sha in shas:
        ext = _get_archive_extension(os)
        url = f"{base_url}/go{version}.{os}-{arch}.{ext}"
        print(f"[check-archive] Fetching archive at {url}", file=sys.stderr)
        # Using `curl` through `ctx.run` takes way too much time due to the archive being huge
        # use `requests` as a workaround
        req = requests.get(url)
        sha = hashlib.sha256(req.content).hexdigest()
        if sha != expected_sha:
            raise exceptions.Exit(
                f"The SHA256 of Go on {os}/{arch} should be {expected_sha}, but got {sha}"
            )

def _get_expected_msgo_sha256(version):

    def _fetch_msgo_assets(version):
        url = f"https://aka.ms/golang/release/latest/go{version}-1.assets.json"
        # Send request and get json

        res = requests.get(url, timeout=5)
        res.raise_for_status()
        return res.json()

    def _get_msgo_sha256(version, assets):
        shas = []
        for data in assets["arches"]:
            if "env" in data:
                env = data["env"]
                arch = env["GOARCH"] if "GOARM" not in env else "armv6l"
                shas.append(((env["GOOS"], arch), data["sha256"]))
        return shas

    assets = _fetch_msgo_assets(version)
    shas = _get_msgo_sha256(version, assets)
    return shas


def _display_shas(shas: List[Tuple[Platform, str]], toolchain: str):
    print(f"--- {toolchain} ---")
    for (os, arch), sha in shas:
        platform = f"[{os}/{arch}]"
        print(f"{platform : <15} {sha}")

@task(
    help={
        "version": "The version of Go to use.",
        "check_archive": "If specified, download Go archives and check the SHA256.",
    }
)
def update_go(_: Context, version: str, check_archive: Optional[bool] = False):
    """
    Update Go versions and SHA256 of Go archives.
    """

    if not re.match("[0-9]+.[0-9]+.[0-9]+", version):
        raise exceptions.Exit(
            f"The version {version} doesn't have an expected format, it should be 3 numbers separated with a dot."
        )

    msgo_shas = _get_expected_msgo_sha256(version)
    shas = _get_expected_sha256(version)
    if check_archive:
        _check_archive(version, shas, "https://go.dev/dl")
        _check_archive(version, msgo_shas, "https://aka.ms/golang/release/latest")

    print(
        f"Please check that you see the same SHAs on https://go.dev/dl for go{version}:"
    )

    _display_shas(shas, "Upstream Go")
    _display_shas(msgo_shas, "Microsoft Go")

    with open("go.env", "w") as writer:
        print(f"GO_VERSION={version}", file=writer)
        for (os, arch), sha in shas:
            print(f"GO_SHA256_{os.upper()}_{arch.upper()}={sha}", file=writer)
        for (os, arch), sha in msgo_shas:
            print(f"MSGO_SHA256_{os.upper()}_{arch.upper()}={sha}", file=writer)