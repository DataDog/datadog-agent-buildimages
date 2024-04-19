import yaml
import re
import os
import requests
import fnmatch
from invoke import task, Exit
from collections import UserList

@task
def control(ctx):
    gl = _load_gitlab_config()
    build_jobs = [job for job in gl.keys() if job.startswith("build")]
    jobs = get_jobs(os.environ["CI_PIPELINE_ID"])
    for job in expected_jobs(ctx, gl, build_jobs):
        print(f"Checking job {job}")
        job_info = next((j for j in jobs if j["name"] == job), None)
        if job_info and job_info["status"] != "success":
            Exit(f"Job {job} failed and is required", 1)
    print("All required jobs passed")

class ReferenceTag(yaml.YAMLObject):
    """
    Custom yaml tag to handle references in gitlab-ci configuration
    """
    yaml_tag = "!reference"
    
    def __init__(self, references):
        self.references = references

    @classmethod
    def from_yaml(cls, loader, node):
        return UserList(loader.construct_sequence(node))

    @classmethod
    def to_yaml(cls, dumper, data):
        return dumper.represent_sequence(cls.yaml_tag, data.data, flow_style=True)

def expected_jobs(ctx, gl, build_jobs):
    modified_files = _get_modified_files(ctx, "main")
    print("modified", modified_files)
    for job in build_jobs:
        change_paths = []
        for rule in gl[job]["rules"]:
            if "changes" in rule:
                change_paths += rule["changes"]["paths"]
        # print(f"in job {job} with changes {change_paths}")
        for path in change_paths:
            for file in modified_files:
                if re.match(fnmatch.translate(path), file):
                    yield job

def _get_modified_files(ctx, base):
    last_main_commit = ctx.run(f"git merge-base HEAD origin/{base}", hide=True).stdout
    modified_files = ctx.run(f"git diff --name-only --no-renames {last_main_commit}", hide=True).stdout.splitlines()
    return modified_files

def _load_gitlab_config():
    yaml.SafeLoader.add_constructor(ReferenceTag.yaml_tag, ReferenceTag.from_yaml)
    with open(".gitlab-ci.yml") as f:
        return yaml.safe_load(f)

def get_jobs(pipeline):
    headers = {"PRIVATE-TOKEN": os.environ["GITLAB_TOKEN"]}
    url = f"https://gitlab.ddbuild.io/api/v4/projects/291/pipelines/{pipeline}/jobs?per_page=100"
    return requests.get(url, headers=headers).json()