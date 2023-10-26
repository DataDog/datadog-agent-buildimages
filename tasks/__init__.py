"""
Invoke entrypoint, import here all the tasks we want to make available
"""
import os

from invoke import Collection

from . import agent
from .update_go import update_go
from .pipeline import trigger_child_pipeline
# the root namespace
ns = Collection()

# add single tasks to the root

ns.add_collection(agent)
ns.add_task(update_go)
ns.add_task(trigger_child_pipeline)
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
