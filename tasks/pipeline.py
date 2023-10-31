from invoke import task
from invoke.exceptions import Exit
from invoke.context import Context
import time
import os
import json


def _trigger_pipeline(ctx: Context, variable, job_token):
    forms = ""
    for key in variable.split(","):
        env_value = os.getenv(key)
        if env_value:
            forms += f"--form variables[{key}]={env_value} "
    forms += f"--form token={job_token} "
    forms += "--form ref=main "
    trigger_cmd = f"curl --request POST {forms} https://gitlab.ddbuild.io/api/v4/projects/1856/trigger/pipeline"
    output = ctx.run(trigger_cmd)
    if output.exited != 0:
        raise Exit("An error occurred while creating the pipeline", code=1)
    return json.loads(output.stdout)


def _get_pipeline_status(ctx: Context, pipeline_id, job_token):
    get_status_cmd = f"curl --header \"PRIVATE-TOKEN: {job_token}\" https://gitlab.ddbuild.io/api/v4/projects/1856/pipelines/{pipeline_id}"
    output = ctx.run(get_status_cmd)
    if output.exited != 0:
        raise Exit("An error occurred while creating the pipeline", code=1)
    return json.loads(output.stdout)["status"]


@task
def trigger_child_pipeline(ctx: Context, variable):
    CI_JOB_TOKEN = os.getenv("CI_JOB_TOKEN")
    GITLAB_TOKEN = os.getenv("GITLAB_TOKEN")
    if not CI_JOB_TOKEN or not GITLAB_TOKEN:
        print("CI_JOB_TOKEN and GITLAB_TOKEN environment variable is undefined and required.")
        return
    metadata = _trigger_pipeline(ctx, variable, CI_JOB_TOKEN)
    pipeline_status = _get_pipeline_status(ctx, metadata["id"], GITLAB_TOKEN)
    while pipeline_status not in ["success", "failed", "canceled", "skipped"]:
        print(f"Current status : {pipeline_status}...")
        time.sleep(15)
        pipeline_status = _get_pipeline_status(ctx, metadata["id"], GITLAB_TOKEN)
    print(f"Pipeline {metadata['id']} ended with {pipeline_status} status.")
    if pipeline_status != "success":
        raise Exit(
            f"Pipeline {metadata['id']} failed. Please look at {metadata['web_url']} for more details.",
            code=1,
        )
