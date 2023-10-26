from invoke import task
import os

@task
def trigger_child_pipeline(ctx, variable):
    CI_JOB_TOKEN = os.getenv("CI_JOB_TOKEN")
    if not CI_JOB_TOKEN:
        print("CI_JOB_TOKEN environment variable is undefined and required.")
        return

    forms = ""
    for key in variable.split(","):
        env_value = os.getenv(key)
        if env_value:
            forms += f"--form variables[{key}]={env_value} "
    forms += "--form token=${CI_JOB_TOKEN} "
    forms += "--form ref=main "
    trigger_cmd = "curl --request POST {forms} https://gitlab.ddbuild.io/api/v4/projects/1856/trigger/pipeline"
    ctx.run(trigger_cmd)

