# SPDX-FileCopyrightText: 2026-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

from typing import TYPE_CHECKING

from dda.cli.base import dynamic_command, pass_app

if TYPE_CHECKING:
    from dda.cli.application import Application


@dynamic_command(
    short_help="Update dda",
    features=["http"],
)
@pass_app
def cmd(app: Application) -> None:
    """
    Pin dda to the latest released version.
    """
    import re

    import httpx

    from utils.constants import PROJECT_ROOT

    res = httpx.get(
        "https://api.github.com/repos/DataDog/datadog-agent-dev/releases/latest", follow_redirects=True
    )
    res.raise_for_status()
    latest = res.json()["tag_name"]

    # Match only the version value, leaving surrounding indentation and quoting untouched.
    # Operate on bytes so line endings are preserved verbatim, without newline translation.
    pattern = re.compile(rb'(?P<prefix>DDA_VERSION[ \t]*=[ \t]*"?)(?P<version>[^"\r\n]+)')

    updated = False
    for name in ("dda.env", "docker-bake.hcl"):
        env_file = PROJECT_ROOT / name
        contents = env_file.read_bytes()

        new_contents, replacements = pattern.subn(lambda m: m["prefix"] + latest.encode(), contents)
        if not replacements:
            app.abort(f"No DDA_VERSION entry found in {name}")
        if new_contents != contents:
            env_file.write_bytes(new_contents)
            updated = True

    if updated:
        app.display_success(f"Updated dda to {latest}")
    else:
        app.display_info(f"dda is already pinned to the latest version {latest}")
