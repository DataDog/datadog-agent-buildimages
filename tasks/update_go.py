import hashlib
import json
import os
import re
import subprocess
import sys
import time
import yaml
from typing import Dict, Optional, Set, Tuple, Type

import requests
from invoke import Context, exceptions, task
from .utils import create_branch_and_push_changes, checkout_latest_main, local_uncommited_changes_exist, dd_repo_temp_cwd

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
# hardcode the number of expected matches so that we can warn if we get something else
DOCKERFILES: Dict[str, int] = {
    "./circleci/Dockerfile": 2,
    "./deb-arm/Dockerfile": 3,
    "./deb-x64/Dockerfile": 1,
    "./rpm-arm64/Dockerfile": 2,
    "./rpm-armhf/Dockerfile": 2,
    "./rpm-x64/Dockerfile": 2,
    "./suse-x64/Dockerfile": 2,
    "./system-probe_arm64/Dockerfile": 2,
    "./system-probe_x64/Dockerfile": 2,
}


def _get_dockerfile_patterns(version: str, shas: Dict[Platform, str]) -> Dict[re.Pattern, str]:
    """returns a map from a pattern to what it should be replaced with, for dockerfiles"""
    patterns: Dict[re.Pattern, str] = {
        re.compile("^(ARG GO_VERSION=)[.0-9]+$", flags=re.MULTILINE): rf"\g<1>{version}",
    }
    for (os, arch), sha in shas.items():
        varname = f"GO_SHA256_{os.upper()}_{arch.upper()}"
        pattern = re.compile(f"^(ARG {varname}=)[a-z0-9]+$", flags=re.MULTILINE)
        replace = rf"\g<1>{sha}"

        patterns[pattern] = replace

    return patterns


def _get_windows_patterns(version: str, shas: Dict[Platform, str]) -> Dict[re.Pattern, str]:
    """returns a map from a pattern to what it should be replaced with, for windows file"""
    sha = shas[("windows", "amd64")]
    return {
        re.compile(r'^(\s*"GO_VERSION"=")[.0-9]+(";)$', flags=re.MULTILINE): rf"\g<1>{version}\g<2>",
        re.compile(r'^(\s*"GO_SHA256_WINDOWS_AMD64"=")[a-z0-9]+(";)$', flags=re.MULTILINE): rf"\g<1>{sha}\g<2>",
    }


def _get_archive_extension(os: str) -> str:
    """returns the extension of the archive for the given os"""
    if os == "windows":
        return "zip"
    return "tar.gz"


def _get_expected_sha256(version: str) -> Dict[Platform, str]:
    """returns a map from platform to sha of the archive"""
    # weirdly, the stored sha256 for round versions don't have a ".0" in the version
    # while the archives have the ".0" suffix
    version = version.removesuffix(".0")

    shas: Dict[Platform, str] = {}
    for os, arch in PLATFORMS:
        ext = _get_archive_extension(os)
        url = f"https://storage.googleapis.com/golang/go{version}.{os}-{arch}.{ext}.sha256"
        res = requests.get(url)
        res.raise_for_status()

        sha = res.text.strip()
        if len(sha) != 64:
            raise exceptions.Exit(f"The SHA256 of Go on {os}/{arch} has an unexpected format: '{sha}'")
        shas[(os, arch)] = sha
    return shas


def _check_archive(version: str, shas: Dict[Platform, str]):
    """checks that the archive sha is the same as the given one"""
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


def _handle_file(path: str, patterns: Dict[re.Pattern, str], expected_match: int = 1, warn: bool = False):
    """replace patterns in a file"""
    with open(path, "r") as reader:
        content: str = reader.read()

    nb_match = 0
    for pattern, replace in patterns.items():
        content, nb = re.subn(pattern, replace, content)
        nb_match += nb

    if nb_match != expected_match:
        msg = f"{path}: {pattern.pattern}: expected {expected_match} matches but got {nb_match}"
        if warn:
            print(f"WARNING: {msg}")
        else:
            raise exceptions.Exit(msg)

    with open(path, "w") as writer:
        writer.write(content)

def _check_appgate():
    return

# maybe this could be done with yq but it removes a lot of the formatting
# https://github.com/mikefarah/yq/issues/515
def _add_wait_for_tests(branch: str):
    import re
    trigger = """project: DataDog/datadog-agent"""
    # load bearing yaml whitespace :sigh:
    with_branch = f"""{trigger}
    branch: {branch}"""
    with open(".gitlab-ci.yml", "r") as f:
        contents = f.read()
    contents = re.sub(trigger, with_branch, contents, count=1)
    with open(".gitlab-ci.yml", "w") as f:
        f.write(contents)

# TODO: not sure how to run this before merging
def _remove_wait_for_tests(branch: str):
    import re
    with_branch = f"""project: DataDog/datadog-agent
    branch: .*"""
    with open(".gitlab-ci.yml", "r") as f:
        contents = f.read()
    contents = re.sub(with_branch, "project: DataDog/datadog-agent", contents, count=1)
    with open(".gitlab-ci.yml", "w") as f:
        f.write(contents)

def _update_and_create_pr(gover):
    # TODO: check that appgate is turned on so that gitlab.ddbuild.io is reachable
    repo = "datadog-agent-buildimages"
    branch = f"update-go-{gover}"
    with dd_repo_temp_cwd(repo):
        if local_uncommited_changes_exist(repo):
            raise "Uncommited changes exist in datadog-agent-buildimages repo. Exiting."
        checkout_latest_main(repo)
        _add_wait_for_tests(f"update-go-{gover}")
        _update_images(gover)
        if local_uncommited_changes_exist(repo):
            create_branch_and_push_changes(
                repo,
                branch,
                f"Update Go version to {gover} for datadog agent buildimages",
            )
        else:
            raise f"Updating buildimages to {gover} changed nothing. Exiting."

        # gitlab job takes a bit to start up
        # GIT_COMMIT_SHORT_SHA used in gitlab is first 8 characters of commit SHA
        short_sha = subprocess.check_output(["git", "rev-parse", "--short=8", "@"])
        tries = 5
        for i in range(tries):
            try:
                status = subprocess.check_output(["curl", f"https://api.github.com/repos/DataDog/datadog-agent-buildimages/commits/{short_sha}/status"])
                build_id = re.findall("\"https://gitlab.ddbuild.io/datadog/datadog-agent-buildimages/builds/(\d+)\"", status)[0]
            except IndexError as e:
                if i < tries:
                    time.sleep(20)
                    continue
                else:
                    raise "Exhausted retries waiting for gitlab job to start."
            break

        # XXX: is it OK to require the user create a gitlab access token?
        res = requests.get(f"https://gitlab.ddbuild.io/api/v4/projects/291/jobs/{build_id}", headers={"PRIVATE-TOKEN": os.environ["GITLAB_ACCESS_TOKEN"]})
        pipeline_id = json.loads(res)["pipeline"]["id"]
        image_tag = f"v{pipeline_id}-{short_sha}_test_only"
        _create_agent_pr(gover, image_tag)

    create_pr_link = f"https://github.com/DataDog/mortar-terraform/compare/{branch}?expand=1"
    print(f"Opening link to create an associated PR for the updated images: {create_pr_link}")
    subprocess.run(["open", create_pr_link])


def _create_agent_pr(gover, image_tag):
    repo = "datadog-agent"
    with dd_repo_temp_cwd(repo):
        if local_uncommited_changes_exist(repo):
            raise "Uncommited changes exist in datadog-agent repo. Exiting."
        checkout_latest_main(repo)
        subprocess.check_call('invoke', 'update-go', gover, image_tag)
        if local_uncommited_changes_exist(repo):
            create_branch_and_push_changes(
                repo,
                f"update-go-{gover}",
                f"Update Go version to {gover} and buildimages to {image_tag} for datadog agent",
            )
        else:
            raise f"Task 'update-go' for version:{gover} and image:{image_tag} changed nothing. Exiting."
    return

def _update_images(version: str, check_archive: Optional[bool] = False, warn: Optional[bool] = False):
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
    for (os, arch), sha in shas.items():
        platform = f"[{os}/{arch}]"
        print(f"{platform : <15} {sha}")

    # handle Dockerfiles
    dockerfile_patterns = _get_dockerfile_patterns(version, shas)
    for path, nb_match in DOCKERFILES.items():
        _handle_file(path, dockerfile_patterns, nb_match, warn)

    # handle `./windows/versions.ps1` file
    windows_patterns = _get_windows_patterns(version, shas)
    _handle_file("./windows/versions.ps1", windows_patterns, 2, warn)

@task(
    help={
        "version": "The version of Go to use.",
        "check_archive": "If specified, download archive and check the SHA256.",
        "warn": "Don't exit in case of matching error, just warn.",
    }
)
def update_go(ctx: Context, version: str, check_archive: Optional[bool] = False, warn: Optional[bool] = False):
    _update_and_create_pr(version)
