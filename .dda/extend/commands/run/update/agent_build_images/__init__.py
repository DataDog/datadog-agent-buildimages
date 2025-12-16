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
@click.option("--go-version", help="The version of Go to use for the buildimages")
@click.option("--ref", default="main", help="The ref to trigger the workflow on")
@click.option("--test-version", is_flag=True, help="Whether the images_id was generated on a dev branch")
@click.option("--token", help="The token to use for the GitHub API", envvar="GITHUB_TOKEN")
@pass_app
def cmd(
    app: Application,
    *,
    images_id: str,
    branch: str,
    go_version: str | None,
    ref: str,
    test_version: bool,
    token: str | None,
) -> None:
    """
    Update Agent Build Images.
    """
    import os

    import github

    if go_version is None:
        go_version = os.environ.get("GO_VERSION")
        if go_version is None:
            app.abort("Either the '--go-version' argument or the GO_VERSION environment variable has to be provided")

    # get the installation auth token
    if token is None:
        app.abort(
            "The '--token' argument or the GITHUB_TOKEN environment variable has to be provided. If running locally, you can use `ddtool auth github` to get a token."
        )

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
