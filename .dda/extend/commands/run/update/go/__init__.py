# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

from typing import TYPE_CHECKING, TypeAlias

import click

from dda.cli.base import dynamic_command, pass_app

if TYPE_CHECKING:
    from dda.cli.application import Application

# a platform is an OS and an architecture
Platform: TypeAlias = tuple[str, str]

# list all platforms used in the repo
# store the platform names in the format expected by Go
# see https://go.dev/dl/ for the full list of platforms
PLATFORMS: list[Platform] = [
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


def _get_expected_sha256(version: str, base_url: str) -> list[tuple[Platform, str]]:
    """returns a map from platform to sha of the archive"""
    import httpx

    shas: list[tuple[Platform, str]] = []
    for os, arch in PLATFORMS:
        ext = _get_archive_extension(os)
        url = f"{base_url}/go{version}.{os}-{arch}.{ext}.sha256"
        res = httpx.get(url, follow_redirects=True)
        res.raise_for_status()

        # Handle both format "<sha256>" and "<sha256>..<filename>"
        sha_elts = res.text.strip().split("  ")
        if sha_elts == [] or len(sha_elts) > 2:
            message = f"The SHA256 of Go on {os}/{arch} has an unexpected format: '{res.text}'"
            raise ValueError(message)

        sha = sha_elts[0]
        if len(sha) != 64:
            message = f"The SHA256 of Go on {os}/{arch} has an unexpected format: '{sha}'"
            raise ValueError(message)
        shas.append(((os, arch), sha))
    return shas


def _get_go_upstream_sha256(version):
    return _get_expected_sha256(version, "https://dl.google.com/go/")


def _get_msgo_sha256(version, msgo_patch):
    return _get_expected_sha256(
        f"{version}-{msgo_patch}", "https://aka.ms/golang/release/latest"
    )


def _check_archive(app: Application, version: str, shas: list[tuple[Platform, str]], base_url: str):
    """checks that the archive sha is the same as the given one"""
    import hashlib

    import httpx

    for (os, arch), expected_sha in shas:
        ext = _get_archive_extension(os)
        url = f"{base_url}/go{version}.{os}-{arch}.{ext}"
        app.display(f"[check-archive] Fetching archive at {url}")
        # Using `curl` through `ctx.run` takes way too much time due to the archive being huge
        # use `requests` as a workaround
        req = httpx.get(url, follow_redirects=True)
        sha = hashlib.sha256(req.content).hexdigest()
        if sha != expected_sha:
            message = f"The SHA256 of Go on {os}/{arch} should be {expected_sha}, but got {sha}"
            raise ValueError(message)


def _display_shas(app: Application, shas: list[tuple[Platform, str]], toolchain: str):
    app.display(f"--- {toolchain} ---")
    for (os, arch), sha in shas:
        platform = f"[{os}/{arch}]"
        app.display(f"{platform: <15} {sha}")


@dynamic_command(
    short_help="Update Go",
    features=["http"],
)
@click.argument("version")
@click.option("--msgo-patch", default="1", help="The patch version of the Microsoft Go distribution")
@click.option("--check-archive", is_flag=True, help="Download Go archives and check the SHA256")
@pass_app
def cmd(app: Application, *, version: str, msgo_patch: str, check_archive: bool) -> None:
    """
    Update Go.
    """
    import re

    from utils.constants import PROJECT_ROOT

    if not re.match("[0-9]+.[0-9]+.[0-9]+", version):
        app.abort(
            f"The version {version} doesn't have an expected format, it should be 3 numbers separated with a dot."
        )

    shas = _get_go_upstream_sha256(version)
    msgo_shas = _get_msgo_sha256(version, msgo_patch)
    if check_archive:
        try:
            _check_archive(app, version, shas, "https://go.dev/dl")
            _check_archive(app, version, msgo_shas, "https://aka.ms/golang/release/latest")
        except Exception as e:
            app.abort(str(e))

    app.display(
        f"Please check that you see the same SHAs on https://go.dev/dl for go{version}:"
    )
    try:
        _display_shas(app, shas, "Upstream Go")
        _display_shas(app, msgo_shas, "Microsoft Go")
    except Exception as e:
        app.abort(str(e))

    with PROJECT_ROOT.joinpath("go.env").open("w", encoding="utf-8") as f:
        f.write(f"GO_VERSION={version}\n")
        f.write(f"MSGO_PATCH={msgo_patch}\n")
        for (os, arch), sha in shas:
            f.write(f"GO_SHA256_{os.upper()}_{arch.upper()}={sha}\n")
        for (os, arch), sha in msgo_shas:
            f.write(f"MSGO_SHA256_{os.upper()}_{arch.upper()}={sha}\n")
