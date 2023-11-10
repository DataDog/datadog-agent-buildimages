from invoke import task
from invoke.exceptions import Exit
import json
import os


@task
def check_pipeline_status(ctx):
    url = f"{os.environ['CI_API_V4_URL']}/projects/{os.environ['CI_PROJECT_ID']}/pipelines/{os.environ['CI_PIPELINE_ID']}/jobs?scope[]=failed"
    print(f'querying {url}')
    jobs = ctx.run(f"curl --header \"JOB-TOKEN: {os.environ['CI_JOB_TOKEN']}\" \"{url}\"", hide=True)
    jobsList = json.loads(jobs.stdout)
    if len(jobsList) > 0:
        print(jobsList)
        raise Exit("Trigger tests failed !")
    return True
