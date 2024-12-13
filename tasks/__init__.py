"""
Invoke entrypoint, import here all the tasks we want to make available
"""
import os

from invoke import Collection

from tasks import agent, gitlab
from tasks.datadog_agent import update_datadog_agent_buildimages
from tasks.update_go import update_go

# the root namespace
ns = Collection()

# add single tasks to the root

ns.add_collection(agent)
ns.add_collection(gitlab)
ns.add_task(update_go)
ns.add_task(update_datadog_agent_buildimages)
ns.configure(
    {
        "run": {
            # workaround waiting for a fix being merged on Invoke,
            # see https://github.com/pyinvoke/invoke/pull/407
            "shell": os.environ.get("COMSPEC", os.environ.get("SHELL")),
            # this should stay, set the encoding explicitly so invoke doesn't
            # freak out if a command outputs unicode chars.
            "encoding": "utf-8",
        }
    }
)
