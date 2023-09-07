import hashlib
import sys
from typing import Dict, Optional, Set, Tuple, Type
from invoke import task, Context, exceptions
import re
import requests

# a platform is an OS and an architecture
Platform = Type[Tuple[str, str]]

# list all platforms used in the repo
# store the platform names in the format expected by Go
# the variables in the Dockerfiles should be stored in uppercased variables
# see https://go.dev/dl/ for the full list of platforms
PLATFORMS: Set[Platform] = {
    ("linux", "amd64"),
    ("linux", "arm64"),
    ("linux", "armv6l"),
    ("windows", "amd64"),
}

# list of Dockerfiles where we want to replace Go version and sha variables
DOCKERFILES: Set[str] = {
    "./circleci/Dockerfile",
    "./deb-arm/Dockerfile",
    "./deb-x64/Dockerfile",
    "./rpm-arm64/Dockerfile",
    "./rpm-armhf/Dockerfile",
    "./rpm-x64/Dockerfile",
    "./suse-x64/Dockerfile",
    "./system-probe_arm64/Dockerfile",
    "./system-probe_x64/Dockerfile",
}


# returns a map from a pattern to what it should be replaced with, for dockerfiles
def _get_dockerfile_patterns(version: str, shas: Dict[Platform, str]) -> Dict[re.Pattern, str]:
    patterns: Dict[re.Pattern, str] = {
        re.compile("^ARG GO_VERSION=[.0-9]+$", flags=re.MULTILINE): f"ARG GO_VERSION={version}",
    }
    for (os, arch), sha in shas.items():
        varname = f"GO_SHA256_{os.upper()}_{arch.upper()}"
        pattern = re.compile(f"^ARG {varname}=[a-z0-9]+$", flags=re.MULTILINE)
        replace = f"ARG {varname}={sha}"

        patterns[pattern] = replace

    return patterns


# returns a map from a pattern to what it should be replaced with, for windows file
def _get_windows_patterns(version: str, shas: Dict[Platform, str]) -> Dict[re.Pattern, str]:
    patterns: Dict[re.Pattern, str] = {
        re.compile('^    "GO_VERSION"="[.0-9]+";$', flags=re.MULTILINE): f'    "GO_VERSION"="{version}";',
    }
    for (os, arch), sha in shas.items():
        varname = f"GO_SHA256_{os.upper()}_{arch.upper()}"
        pattern = re.compile(f'^    "{varname}"="[a-z0-9]+";$', flags=re.MULTILINE)
        replace = f'    "{varname}"="{sha}";'

        patterns[pattern] = replace

    return patterns


# returns the extension of the archive for the given os
def _get_archive_extension(os: str) -> str:
    if os == "windows":
        return "zip"
    return "tar.gz"


# returns a map from platform to sha of the archive
def _get_expected_sha256(version: str) -> Dict[Platform, str]:
    # weirdly, the stored sha256 for round versions don't have a ".0" in the version
    # while the archives have the ".0" suffix
    version = version.removesuffix(".0")

    shas: Dict[Platform, str] = {}
    for os, arch in PLATFORMS:
        ext = _get_archive_extension(os)
        url = f"https://storage.googleapis.com/golang/go{version}.{os}-{arch}.{ext}.sha256"
        res = requests.get(url)
        sha = res.text.strip()
        if len(sha) != 64:
            raise exceptions.Exit(f"The SHA256 of Go on {os}/{arch} has an unexpected format: '{sha}'")
        shas[(os, arch)] = sha
    return shas


# checks that the archive sha is the same as the given one
def _check_archive(version: str, shas: Dict[Platform, str]):
    for (os, arch), expected_sha in shas.items():
        ext = _get_archive_extension(os)
        url = f"https://go.dev/dl/go{version}.{os}-{arch}.{ext}"
        print(f"[check-archive] Fetching archive at {url}", file=sys.stderr)
        # Using `curl` through `ctx.run` takes way too much time due to the archive being huge
        # use `requests` as a workaround
        req = requests.get(url)
        sha = hashlib.sha256(req.content).hexdigest()
        if sha != expected_sha:
            raise exceptions.Exit(f"The SHA256 of Go on {os}/{arch} should be {expected_sha}, but got {sha}")


# replace patterns in a file
def _handle_file(path: str, patterns: Dict[re.Pattern, str]):
    with open(path, "r") as reader:
        content: str = reader.read()

    for pattern, replace in patterns.items():
        content = re.sub(pattern, replace, content)

    with open(path, "w") as writer:
        writer.write(content)


@task(
    help={
        "version": "The version of Go to use.",
        "check_archive": "If specified, download archive and check the SHA256.",
    }
)
def update_go(ctx: Context, version: str, check_archive: Optional[bool] = False):
    if not re.match("[0-9]+.[0-9]+.[0-9]+", version):
        raise exceptions.Exit(
            "The version doesn't have an expected format, it should be 3 numbers separated with a dot."
        )

    shas = _get_expected_sha256(version)
    if check_archive:
        _check_archive(version, shas)

    print(f"Please check that you see the same SHAs on https://go.dev/dl for go{version}:")
    for (os, arch), sha in shas.items():
        platform = f"[{os}/{arch}]"
        print(f"{platform : <15} {sha}")

    # handle Dockerfiles
    dockerfile_patterns = _get_dockerfile_patterns(version, shas)
    for path in DOCKERFILES:
        _handle_file(path, dockerfile_patterns)

    # handle `./windows/versions.ps1` file
    windows_patterns = _get_windows_patterns(version, shas)
    _handle_file("./windows/versions.ps1", windows_patterns)
