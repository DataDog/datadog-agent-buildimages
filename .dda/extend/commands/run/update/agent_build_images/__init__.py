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
    help="The version of Go to use for the buildimages. Can also be specified via the GO_VERSION environment variable. "
    "Used only on the first-dispatch path (--test-version); ignored otherwise.",
    envvar="GO_VERSION",
    required=True,
)
@click.option(
    "--ref",
    default="main",
    help="The ref to trigger the workflow on. Used only on the first-dispatch path (--test-version); ignored otherwise.",
)
@click.option("--test-version", is_flag=True, help="Whether the images_id was generated on a dev branch")
@click.option(
    "--merge-sha",
    default=None,
    envvar="CI_COMMIT_SHA",
    help="SHA of the buildimages merge commit this run is for. Used to find its originating PR and derive "
    "the matching `buildimages/<ref>` branch in datadog-agent when `branch` is not passed explicitly. "
    "Defaults to $CI_COMMIT_SHA.",
)
@click.option(
    "--dry-run",
    is_flag=True,
    default=False,
    help="On the second-dispatch path, execute everything except the three mutating API calls "
    "(append commit, edit PR body, post comment). Prints what WOULD be sent to logs.",
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
    dry_run: bool,
    token: str,
) -> None:
    """
    Update Agent Build Images.

    First dispatch (--test-version): dispatches buildimages-update.yml so peter-evans
    creates the draft datadog-agent PR. Requires an explicit `branch` argument.

    Second dispatch (no --test-version): shallow+sparse clones datadog-agent at the PR
    branch, runs `dda inv -- buildimages.update --no-test` to let the canonical logic
    rewrite the gitlab config, and appends a signed commit to the branch via GraphQL
    createCommitOnBranch. Then updates the PR body (replace test tag with final tag)
    and posts a bot comment summarising the swap.

    --ref and --go-version are only used on the first-dispatch path.
    """
    if test_version:
        if not branch:
            app.abort("--test-version requires an explicit branch argument.")
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
        dry_run=dry_run,
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
    dry_run: bool,
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
                "git", "-C", str(repo_dir), "sparse-checkout", "set",
                # Both yaml names kept for forward-compat with datadog-agent#57527
                # which moves buildimage variables from .gitlab-ci.yml to gitlab-source.yml.
                ".gitlab-ci.yml", "gitlab-source.yml",
                "tasks", ".dda", "pyproject.toml",
            ],
            check=True,
        )

        app.display_info("Capturing current (test) image tag...")
        old_tag = subprocess.run(
            ["dda", "inv", "--", "buildimages.get-tag"],
            cwd=repo_dir, check=True, capture_output=True, text=True,
        ).stdout.strip()
        app.display_info(f"Current tag: {old_tag}")

        app.display_info(f"Rewriting via dda to final tag: {images_id}")
        subprocess.run(
            ["dda", "inv", "--", "-e", "buildimages.update",
             "--tag", images_id, "--no-test"],
            cwd=repo_dir, check=True,
        )

        modified = subprocess.run(
            ["git", "-C", str(repo_dir), "diff", "--name-only", "--diff-filter=AM"],
            check=True, capture_output=True, text=True,
        ).stdout.splitlines()
        if not modified:
            app.display_info("dda produced no changes; nothing to append.")
            return
        app.display_info(f"Modified files: {', '.join(modified)}")

        additions = [
            {"path": p, "contents": base64.b64encode((repo_dir / p).read_bytes()).decode()}
            for p in modified
        ]
        head_oid = subprocess.run(
            [
                "git", "-C", str(repo_dir),
                "-c", f"http.extraHeader=Authorization: Bearer {token}",
                "ls-remote", "origin", f"refs/heads/{branch}",
            ],
            check=True, capture_output=True, text=True,
        ).stdout.split()[0]
        app.display_info(f"Branch head OID: {head_oid[:8]}")

    app.display_info(f"Appending commit to {branch}...")
    commit_url = _create_commit_on_branch(
        token=token,
        branch=branch,
        expected_head_oid=head_oid,
        message=f"Update buildimages ID to {images_id}",
        additions=additions,
        dry_run=dry_run,
    )
    if commit_url:
        app.display_info(f"Commit appended: {commit_url}")

    app.display_info(f"Resolving open PR for {branch}...")
    pr_number = _resolve_pr_number(token=token, branch=branch)
    app.display_info(f"PR #{pr_number}")

    app.display_info(f"Updating PR body (replace {old_tag} -> {images_id})...")
    _update_pr_body(
        token=token, pr_number=pr_number, old_tag=old_tag, new_tag=images_id, dry_run=dry_run,
    )

    app.display_info(f"Posting bot comment on PR #{pr_number}...")
    _post_pr_comment(
        token=token,
        pr_number=pr_number,
        dry_run=dry_run,
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
    dry_run: bool,
) -> str | None:
    if dry_run:
        summary = {
            "repo": REPO_NAME,
            "branch": branch,
            "expected_head_oid": expected_head_oid,
            "message": message,
            "files": [
                {"path": a["path"], "bytes": len(base64.b64decode(a["contents"]))}
                for a in additions
            ],
        }
        print(f"[DRY-RUN] createCommitOnBranch would be called with: {summary}")
        return None
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
    dry_run: bool,
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
    if dry_run:
        import difflib
        diff = "\n".join(
            difflib.unified_diff(body.splitlines(), new_body.splitlines(), lineterm="", n=2)
        )
        print(f"[DRY-RUN] PR body would be updated. Diff:\n{diff}")
        return
    r = requests.patch(
        f"https://api.github.com/repos/{REPO_NAME}/pulls/{pr_number}",
        headers=_gh_headers(token),
        json={"body": new_body},
        timeout=30,
    )
    r.raise_for_status()


def _post_pr_comment(*, token: str, pr_number: int, body: str, dry_run: bool) -> None:
    if dry_run:
        print(f"[DRY-RUN] Comment would be posted on PR #{pr_number}:\n{body}")
        return
    r = requests.post(
        f"https://api.github.com/repos/{REPO_NAME}/issues/{pr_number}/comments",
        headers=_gh_headers(token),
        json={"body": body},
        timeout=30,
    )
    r.raise_for_status()
