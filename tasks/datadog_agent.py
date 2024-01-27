import base64
import os
from typing import Optional

from invoke.context import Context
from invoke.exceptions import Exit
from invoke.tasks import task

REPO_NAME = "DataDog/datadog-agent"
# Workflow ID can be found in https://api.github.com/repos/DataDog/datadog-agent/actions/workflows
WORKFLOW_ID = 80540190


@task(
    help={
        "images_id": "The ID of the buildimages",
        "branch": "The branch on which to update the buildimages ID",
        "go_version": """The version of Go to use for the buildimages.
Uses the GO_VERSION environment variable if not provided""",
        "ref": """The ref to trigger the workflow on.
If the branch given in the 'branch' argument doesn't exist, it will be created from that ref.""",
        "test_version": "Whether the images_id was generated on a dev branch",
    }
)
def update_datadog_agent_buildimages(
    _: Context,
    images_id: str,
    branch: str,
    go_version: Optional[str] = None,
    ref: str = "main",
    test_version: bool = False,
):
    """
    Triggers a workflow in the datadog-agent repository to update the buildimages ID and Go version.
    """
    import github

    if go_version is None:
        go_version_env = os.environ.get("GO_VERSION")
        if go_version_env is None:
            raise Exit("Either the '--go-version' argument or the GO_VERSION environment variable has to be provided")
        go_version = go_version_env

    # get the installation auth token
    app_auth = github.Auth.AppAuth(
        os.environ["GITHUB_APP_ID"], base64.b64decode(os.environ["GITHUB_KEY_B64"]).decode("ascii")
    )
    installation_id = os.environ["GITHUB_INSTALLATION_ID"]
    inst_auth = app_auth.get_installation_auth(
        int(installation_id),
        token_permissions={"contents": "write"},
    )

    gh = github.Github(auth=inst_auth)
    repo = gh.get_repo(REPO_NAME)
    wf = repo.get_workflow(WORKFLOW_ID)

    res = wf.create_dispatch(
        ref=ref,
        inputs={
            "images_id": images_id,
            "branch": branch,
            "test_version": test_version,
            "go_version": go_version,
        },
    )
    if not res:
        raise Exit("Failed to trigger the workflow")
