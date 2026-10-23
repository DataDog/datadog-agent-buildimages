# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

import base64
import os
import subprocess
import tempfile
from pathlib import Path
from typing import TYPE_CHECKING

import click
import requests

from dda.cli.base import dynamic_command, pass_app

if TYPE_CHECKING:
    from dda.cli.application import Application

# Target datadog-agent repo. Overridable via DDA_BUILDIMAGES_TARGET_REPO=owner/repo
# so the whole flow can be exercised end-to-end against a scratch fork.
REPO_NAME = os.environ.get("DDA_BUILDIMAGES_TARGET_REPO", "DataDog/datadog-agent")
# Workflow ID can be found in https://api.github.com/repos/DataDog/datadog-agent/actions/workflows
WORKFLOW_ID = 80540190


@dynamic_command(
    short_help="Update Agent Build Images",
    features=["github"],
)
@click.argument("images_id")
@click.argument("branch", required=False, default="")
@click.option(
    "--go-version",
    help="Go version for the buildimages (also $GO_VERSION). Required for --test-version only.",
    envvar="GO_VERSION",
    default="",
)
@click.option(
    "--ref",
    default="main",
    help="Ref to trigger the workflow on. Used only when --test-version is set.",
)
@click.option(
    "--test-version",
    is_flag=True,
    help="Open a draft datadog-agent PR with test image tags (via peter-evans).",
)
@click.option(
    "--merge-sha",
    default=None,
    envvar="CI_COMMIT_SHA",
    help="Buildimages commit SHA (also $CI_COMMIT_SHA). Resolves the datadog-agent branch "
    "where the Go-update PR is open, when `branch` is empty.",
)
@click.option(
    "--token",
    help="""
    Token for use with the GitHub API. Needs the permission to trigger workflows on `datadog-agent`.
    If running locally, you can use `ddtool auth github token` to get a token.
    Can also be specified via the GITHUB_TOKEN environment variable.
    """,
    envvar="GITHUB_TOKEN",
    required=True,
)
@pass_app
def cmd(
    app: Application,
    *,
    images_id: str,
    branch: str,
    go_version: str,
    ref: str,
    test_version: bool,
    merge_sha: str | None,
    token: str,
) -> None:
    """
    Update Agent Build Images.

    Three call patterns:

    1. Open PR with test image tags
       dda run update agent-build-images <images_id> <branch> --ref <ref> --test-version
       Opens a draft datadog-agent PR with peter-evans, pointing at test image tags.

    2. Update open PR with final image tags (production)
       dda run update agent-build-images <images_id>
       Appends a signed commit to the open datadog-agent PR via GraphQL
       createCommitOnBranch, edits the PR body, posts a bot comment. The target
       branch is derived from $CI_COMMIT_SHA via --merge-sha.

    3. Update test PR with final image tags
       dda run update agent-build-images <images_id> <branch>
       Used for e2e validation on test runs. Same as case 2 but points at an
       explicit <branch> instead of resolving via --merge-sha.
    """
    if test_version:
        if not branch:
            app.abort("--test-version requires an explicit branch argument.")
        if not go_version:
            app.abort("--test-version requires --go-version (or $GO_VERSION).")
        _dispatch_workflow(
            app=app,
            token=token,
            images_id=images_id,
            branch=branch,
            go_version=go_version,
            ref=ref,
        )
        return

    # Second-dispatch: append a signed commit to the existing PR branch.
    resolved_branch = branch or _resolve_pr_branch_from_merge_sha(token=token, merge_sha=merge_sha)
    app.display_info(f"Second-dispatch target branch: {resolved_branch}")
    _update_pr_with_final_image_tags(
        app=app,
        token=token,
        images_id=images_id,
        branch=resolved_branch,
    )


def _dispatch_workflow(
    *,
    app: Application,
    token: str,
    images_id: str,
    branch: str,
    go_version: str,
    ref: str,
) -> None:
    """Trigger the buildimages-update.yml workflow in datadog-agent."""
    import github

    gh = github.Github(login_or_token=token)
    repo = gh.get_repo(REPO_NAME)
    wf = repo.get_workflow(WORKFLOW_ID)

    res = wf.create_dispatch(
        ref=ref,
        inputs={
            "images_id": images_id,
            "branch": branch,
            "test_version": True,
            "go_version": go_version,
            "include_otel_modules": False,
        },
    )
    if not res:
        app.abort("Failed to trigger the workflow")


def _resolve_pr_branch_from_merge_sha(*, token: str, merge_sha: str | None) -> str:
    """
    Resolve `buildimages/<head_ref>` from the merge commit's originating PR.

    The lookup goes against DataDog/datadog-agent-buildimages (the merge happened
    there), not REPO_NAME. Testers who want to bypass this lookup should pass
    `branch` explicitly on the command line.
    """
    if not merge_sha:
        raise RuntimeError(
            "--merge-sha (or $CI_COMMIT_SHA) is required when `branch` is not given."
        )
    r = requests.get(
        f"https://api.github.com/repos/DataDog/datadog-agent-buildimages/commits/{merge_sha}/pulls",
        headers=_gh_headers(token),
        timeout=30,
    )
    r.raise_for_status()
    head_ref = next(
        (p["head"]["ref"] for p in r.json() if p.get("merge_commit_sha") == merge_sha),
        None,
    )
    if not head_ref:
        raise RuntimeError(f"No merged PR found for commit {merge_sha}")
    return f"buildimages/{head_ref}"


def _update_pr_with_final_image_tags(
    *,
    app: Application,
    token: str,
    images_id: str,
    branch: str,
) -> None:
    """
    Shallow+sparse clone datadog-agent at `branch`, run `dda inv -- buildimages.update`,
    then append a signed commit via createCommitOnBranch, edit the PR body, post a
    bot comment.
    """
    with tempfile.TemporaryDirectory(prefix="datadog-agent-sparse-") as tmp:
        repo_dir = Path(tmp) / "datadog-agent"
        app.display_info(f"Cloning {REPO_NAME} at {branch} (sparse)...")
        # Header-based auth; -c scopes to this invocation so the token never persists
        # in .git/config on the runner.
        subprocess.run(
            [
                "git",
                "-c", f"http.extraHeader=Authorization: Bearer {token}",
                "clone",
                "--filter=blob:none", "--depth", "1", "--sparse",
                "--branch", branch,
                f"https://github.com/{REPO_NAME}.git",
                str(repo_dir),
            ],
            check=True,
        )
        subprocess.run(
            [
                "git", "-C", str(repo_dir), "sparse-checkout", "set", "--no-cone",
                # --no-cone so file paths work (cone mode rejects them).
                # gitlab-source.yml covers datadog-agent#57527.
                "/.gitlab-ci.yml", "/gitlab-source.yml", "/pyproject.toml",
                "/tasks", "/.dda",
            ],
            check=True,
        )

        app.display_info("Capturing current (test) image tag...")
        raw = subprocess.run(
            ["dda", "inv", "--", "buildimages.get-tag"],
            cwd=repo_dir, check=True, capture_output=True, text=True,
        ).stdout
        # Last non-empty line is the autoprinted tag; guard against stdout noise.
        old_tag = next((l.strip() for l in reversed(raw.splitlines()) if l.strip()), "")
        if not old_tag.startswith("v"):
            app.abort(f"Unexpected get-tag output; last line was {old_tag!r}\nFull stdout:\n{raw}")
        app.display_info(f"Current tag: {old_tag}")

        app.display_info(f"Rewriting via dda to final tag: {images_id}")
        # --windows mirrors the first-dispatch (update-go hardcodes windows=True),
        # so Windows image tags get promoted alongside Linux.
        subprocess.run(
            ["dda", "inv", "--", "-e", "buildimages.update",
             "--tag", images_id, "--no-test", "--windows"],
            cwd=repo_dir, check=True,
        )

        modified = subprocess.run(
            ["git", "-C", str(repo_dir), "diff", "--name-only", "--diff-filter=AM"],
            check=True, capture_output=True, text=True,
        ).stdout.splitlines()
        additions: list[dict[str, str]] = []
        if modified:
            app.display_info(f"Modified files: {', '.join(modified)}")
            additions = [
                {"path": p, "contents": base64.b64encode((repo_dir / p).read_bytes()).decode()}
                for p in modified
            ]
        # Use the cloned HEAD so any concurrent push to the branch triggers an
        # expectedHeadOid mismatch instead of silently overwriting.
        head_oid = subprocess.run(
            ["git", "-C", str(repo_dir), "rev-parse", "HEAD"],
            check=True, capture_output=True, text=True,
        ).stdout.strip()
        app.display_info(f"Branch head OID: {head_oid[:8]}")

    if not additions:
        app.abort(
            "Branch is already at the final tag. If this is a retry after a partial "
            "failure, reconcile the PR body and comment manually."
        )

    app.display_info(f"Appending commit to {branch}...")
    commit_url = _create_commit_on_branch(
        token=token,
        branch=branch,
        expected_head_oid=head_oid,
        message=f"Update buildimages ID to {images_id}",
        additions=additions,
    )
    app.display_info(f"Commit appended: {commit_url}")

    app.display_info(f"Resolving open PR for {branch}...")
    pr_number = _resolve_pr_number(token=token, branch=branch)
    app.display_info(f"PR #{pr_number}")

    app.display_info(f"Updating PR body (replace {old_tag} -> {images_id})...")
    _update_pr_body(
        token=token, pr_number=pr_number, old_tag=old_tag, new_tag=images_id,
    )

    app.display_info(f"Posting bot comment on PR #{pr_number}...")
    _post_pr_comment(
        token=token,
        pr_number=pr_number,
        body=f"Automated bot updated test image tag to final image tag: "
             f"`{old_tag}` → `{images_id}`.",
    )


def _gh_headers(token: str) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
    }


def _create_commit_on_branch(
    *,
    token: str,
    branch: str,
    expected_head_oid: str,
    message: str,
    additions: list[dict[str, str]],
) -> str:
    query = """
    mutation ($repo: String!, $branch: String!, $oid: GitObjectID!, $msg: String!, $additions: [FileAddition!]!) {
      createCommitOnBranch(input: {
        branch: { repositoryNameWithOwner: $repo, branchName: $branch },
        expectedHeadOid: $oid,
        message: { headline: $msg },
        fileChanges: { additions: $additions }
      }) { commit { url } }
    }
    """
    r = requests.post(
        "https://api.github.com/graphql",
        headers=_gh_headers(token),
        json={
            "query": query,
            "variables": {
                "repo": REPO_NAME,
                "branch": branch,
                "oid": expected_head_oid,
                "msg": message,
                "additions": additions,
            },
        },
        timeout=30,
    )
    r.raise_for_status()
    data = r.json()
    if "errors" in data:
        raise RuntimeError(f"createCommitOnBranch failed: {data['errors']}")
    return data["data"]["createCommitOnBranch"]["commit"]["url"]


def _resolve_pr_number(*, token: str, branch: str) -> int:
    owner = REPO_NAME.split("/")[0]
    r = requests.get(
        f"https://api.github.com/repos/{REPO_NAME}/pulls",
        headers=_gh_headers(token),
        params={"head": f"{owner}:{branch}", "state": "open"},
        timeout=30,
    )
    r.raise_for_status()
    prs = r.json()
    if not prs:
        raise RuntimeError(f"No open PR found on branch {branch}")
    return prs[0]["number"]


def _update_pr_body(
    *,
    token: str,
    pr_number: int,
    old_tag: str,
    new_tag: str,
) -> None:
    r = requests.get(
        f"https://api.github.com/repos/{REPO_NAME}/pulls/{pr_number}",
        headers=_gh_headers(token),
        timeout=30,
    )
    r.raise_for_status()
    body = r.json().get("body") or ""
    new_body = body.replace(old_tag, new_tag).replace("(test version)", "(final version)")
    if new_body == body:
        print("PR body unchanged; skipping edit.")
        return
    r = requests.patch(
        f"https://api.github.com/repos/{REPO_NAME}/pulls/{pr_number}",
        headers=_gh_headers(token),
        json={"body": new_body},
        timeout=30,
    )
    r.raise_for_status()


def _post_pr_comment(*, token: str, pr_number: int, body: str) -> None:
    r = requests.post(
        f"https://api.github.com/repos/{REPO_NAME}/issues/{pr_number}/comments",
        headers=_gh_headers(token),
        json={"body": body},
        timeout=30,
    )
    r.raise_for_status()
