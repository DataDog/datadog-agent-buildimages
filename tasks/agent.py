from invoke import task
import json

@task
def version(ctx):
    with open("release.json", "r") as release_json_stream:
        version = json.load(release_json_stream)
    print(version['agent_version'])
    return version['agent_version']
