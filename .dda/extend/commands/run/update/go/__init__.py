# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

from collections import OrderedDict, defaultdict
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

# Platforms used in the bakefile - only a subset are currently supported
# The rest are used only for building legacy images
BAKEFILE_PLATFORMS: list[Platform] = [
    ("linux", "amd64"),
    ("linux", "arm64"),
]


def _get_archive_extension(os: str) -> str:
    """returns the extension of the archive for the given os"""
    if os == "windows":
        return "zip"
    return "tar.gz"


def _get_expected_sha256(version: str, base_url: str) -> OrderedDict[Platform, str]:
    """returns a map from platform to sha of the archive"""
    import httpx

    shas: OrderedDict[Platform, str] = OrderedDict()
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
        shas[(os, arch)] = sha

    return shas


def _get_go_upstream_sha256(version) -> OrderedDict[Platform, str]:
    """Get SHA256 checksums for Go version from go.dev/dl API"""
    import httpx

    # Fetch the JSON data from go.dev/dl API
    url = "https://go.dev/dl/?mode=json"
    res = httpx.get(url, follow_redirects=True)
    res.raise_for_status()

    releases = res.json()

    # Find the matching version
    target_version = f"go{version}"
    matching_release = None
    for release in releases:
        if release["version"] == target_version:
            matching_release = release
            break
    else:
        raise ValueError(f"Go version {target_version} not found in releases")

    # Extract SHA256 for each platform
    shas: OrderedDict[Platform, str] = OrderedDict()
    for os, arch in PLATFORMS:
        # Find the matching file for this platform
        matching_file = None
        for file_info in matching_release["files"]:
            # Only consider archive files (tar.gz or zip)
            if file_info.get("kind") != "archive":
                continue
            if file_info["os"] == os and file_info["arch"] == arch:
                matching_file = file_info
                break
        else:
            raise ValueError(f"No archive found for Go {target_version} on {os}/{arch}")

        sha = matching_file["sha256"]
        if len(sha) != 64:
            raise ValueError(f"Invalid SHA256 format for Go {target_version} on {os}/{arch}: '{sha}'")

        shas[(os, arch)] = sha

    return shas


def _get_msgo_sha256(version, msgo_patch) -> OrderedDict[Platform, str]:
    return _get_expected_sha256(f"{version}-{msgo_patch}", "https://aka.ms/golang/release/latest")


def _check_archive(app: Application, version: str, shas: OrderedDict[Platform, str], base_url: str):
    """checks that the archive sha is the same as the given one"""
    import hashlib

    import httpx

    for (os, arch), expected_sha in shas.items():
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


def _update_go_env(
    app: Application,
    version: str,
    msgo_patch: str,
    shas: OrderedDict[Platform, str],
    msgo_shas: OrderedDict[Platform, str],
):
    from utils.constants import PROJECT_ROOT

    with PROJECT_ROOT.joinpath("go.env").open("w", encoding="utf-8") as f:
        f.write(f"GO_VERSION={version}\n")
        f.write(f"MSGO_PATCH={msgo_patch}\n")
        for (os, arch), sha in shas.items():
            f.write(f"GO_SHA256_{os.upper()}_{arch.upper()}={sha}\n")
        for (os, arch), sha in msgo_shas.items():
            f.write(f"MSGO_SHA256_{os.upper()}_{arch.upper()}={sha}\n")


def _update_bakefile_override(
    app: Application,
    version: str,
    msgo_patch: str,
    shas: OrderedDict[Platform, str],
    msgo_shas: OrderedDict[Platform, str],
):
    import json

    from utils.constants import PROJECT_ROOT

    bakefile_data = {
        "variable": {
            "go_versions": {"default": {"GO_VERSION": version, "MSGO_PATCH": msgo_patch}},
        }
    }

    for os, arch in BAKEFILE_PLATFORMS:
        bakefile_data["variable"][f"go_checksums_{arch}"] = {
            "default": {"GO_SHA256": shas[(os, arch)], "MSGO_SHA256": msgo_shas[(os, arch)]}
        }

    with PROJECT_ROOT.joinpath("docker-bake.override.json").open("w", encoding="utf-8") as f:
        json.dump(bakefile_data, f, indent=2)
        f.write("\n")


def _display_shas(app: Application, shas: dict[Platform, str], toolchain: str):
    app.display(f"--- {toolchain} ---")
    for os, arch in PLATFORMS:
        sha = shas[(os, arch)]
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

    app.display(f"Please check that you see the same SHAs on https://go.dev/dl for go{version}:")
    try:
        _display_shas(app, shas, "Upstream Go")
        _display_shas(app, msgo_shas, "Microsoft Go")
    except Exception as e:
        app.abort(str(e))

    _update_go_env(app, version, msgo_patch, shas, msgo_shas)
    _update_bakefile_override(app, version, msgo_patch, shas, msgo_shas)
