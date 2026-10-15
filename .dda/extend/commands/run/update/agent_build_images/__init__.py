# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

from typing import TYPE_CHECKING

import click

from dda.cli.base import dynamic_command, pass_app

if TYPE_CHECKING:
    from dda.cli.application import Application

REPO_NAME = "DataDog/datadog-agent"
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

    # Second-dispatch path: full flow is added in the next commit.
    app.abort(
        "Second-dispatch flow (no --test-version) is not implemented yet. "
        "This will be added in a follow-up commit."
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
