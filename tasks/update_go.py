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
    # weirdly, the stored sha256 for round versions don't have a ".0" in the version
    # while the archives have the ".0" suffix
    version = version.removesuffix(".0")

    shas: List[Tuple[Platform, str]] = []
    for os, arch in PLATFORMS:
        ext = _get_archive_extension(os)
        url = f"https://storage.googleapis.com/golang/go{version}.{os}-{arch}.{ext}.sha256"
        res = requests.get(url)
        res.raise_for_status()

        sha = res.text.strip()
        if len(sha) != 64:
            raise exceptions.Exit(f"The SHA256 of Go on {os}/{arch} has an unexpected format: '{sha}'")
        shas.append(((os, arch), sha))
    return shas


def _check_archive(version: str, shas: List[Tuple[Platform, str]]):
    """checks that the archive sha is the same as the given one"""
    for (os, arch), expected_sha in shas:
        ext = _get_archive_extension(os)
        url = f"https://go.dev/dl/go{version}.{os}-{arch}.{ext}"
        print(f"[check-archive] Fetching archive at {url}", file=sys.stderr)
        # Using `curl` through `ctx.run` takes way too much time due to the archive being huge
        # use `requests` as a workaround
        req = requests.get(url)
        sha = hashlib.sha256(req.content).hexdigest()
        if sha != expected_sha:
            raise exceptions.Exit(f"The SHA256 of Go on {os}/{arch} should be {expected_sha}, but got {sha}")


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

    shas = _get_expected_sha256(version)
    if check_archive:
        _check_archive(version, shas)

    print(f"Please check that you see the same SHAs on https://go.dev/dl for go{version}:")
    for (os, arch), sha in shas:
        platform = f"[{os}/{arch}]"
        print(f"{platform : <15} {sha}")

    with open("go.env", "w") as writer:
        print(f"GO_VERSION={version}", file=writer)
        for (os, arch), sha in shas:
            print(f"GO_SHA256_{os.upper()}_{arch.upper()}={sha}", file=writer)
