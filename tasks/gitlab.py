import yaml
import os
from invoke import task

@task
def generate_test(_):
    with open(".gitlab/trigger_template.yml") as f:
        trigger_template = yaml.safe_load(f)
    version = f"v{os.environ['CI_PIPELINE_ID']}-{os.environ['CI_COMMIT_SHORT_SHA']}"    

    for file in os.listdir(os.environ["CI_PROJECT_DIR"]):
        if file.startswith("built"):
            print(f"Adding {file} to the trigger template")
            image = file.removeprefix("built_").removesuffix(".txt").replace("_", "").replace("-", "").casefold()
            for variable, value in trigger_template["variables"].items():
                if variable.replace("_", "").replace("-", "").casefold()["key"] == image:
                    variable["value"] = version
                    break
    print(f"triggering with {trigger_template}")
    with open("datadog-agent-trigger-gitlab-ci.yml", "w") as f:
        yaml.dump(trigger_template, f)
