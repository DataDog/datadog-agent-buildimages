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
@click.argument("branch")
@click.option(
    "--go-version",
    help="The version of Go to use for the buildimages. Can also be specified via the GO_VERSION environment variable.",
    envvar="GO_VERSION",
    required=True,
)
@click.option("--ref", default="main", help="The ref to trigger the workflow on")
@click.option("--test-version", is_flag=True, help="Whether the images_id was generated on a dev branch")
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
    token: str,
) -> None:
    """
    Update Agent Build Images.
    """
    import github

    gh = github.Github(login_or_token=token)
    repo = gh.get_repo(REPO_NAME)
    wf = repo.get_workflow(WORKFLOW_ID)

    res = wf.create_dispatch(
        ref=ref,
        inputs={
            "images_id": images_id,
            "branch": branch,
            "test_version": test_version,
            "go_version": go_version,
            "include_otel_modules": False,
        },
    )
    if not res:
        app.abort("Failed to trigger the workflow")
