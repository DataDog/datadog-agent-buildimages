from invoke import task
from invoke.exceptions import Exit
import json

@task
def check_pipeline_status(ctx):
    jobs = ctx.run("curl --header \"JOB-TOKEN: $CI_JOB_TOKEN\" \"https://gitlab.ddbuild.io/api/v4/projects/291/pipelines/${CI_PIPELINE_ID}/jobs?scope[]=failed\"",hide=True)
    jobsList = json.loads(jobs.stdout)
    if len(jobsList) > 0:
        raise Exit("Trigger tests failed !")
    return True
