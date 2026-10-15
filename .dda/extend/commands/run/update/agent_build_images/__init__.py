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

    Second dispatch (no --test-version): will append a signed commit to the existing PR
    branch via GraphQL createCommitOnBranch, update the PR body, and post a bot comment.
    (Second-dispatch flow is added in a follow-up commit; this commit only wires the
    new options.)

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
