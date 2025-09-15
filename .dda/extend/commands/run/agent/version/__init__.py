# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

from typing import TYPE_CHECKING

from dda.cli.base import dynamic_command, pass_app

if TYPE_CHECKING:
    from dda.cli.application import Application
    from dda.utils.fs import Path


@dynamic_command(short_help="Display the Agent version")
@pass_app
def cmd(app: Application) -> None:
    """
    Display the Agent version.
    """
    import json

    from utils.constants import PROJECT_ROOT

    release_file: Path = PROJECT_ROOT / "release.json"
    data = json.loads(release_file.read_text())

    app.display(data["agent_version"])
