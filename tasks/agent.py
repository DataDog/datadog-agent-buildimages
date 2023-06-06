from invoke import task
import json
from collections import OrderedDict

@task
def get_agent_version(ctx):

    with open("release.json", "r") as release_json_stream:
        version = json.load(release_json_stream)
    return version['agent_version']

@task
def clone(ctx, destination_folder):
    version = get_agent_version(ctx)
    print(f"Cloning {version} branch of the agent repository in {destination_folder} ")
    ctx.run(f"git clone -b {version} https://github.com/DataDog/datadog-agent {destination_folder}")
