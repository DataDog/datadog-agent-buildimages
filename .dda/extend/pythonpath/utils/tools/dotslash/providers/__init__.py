# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

from typing import TYPE_CHECKING

import msgspec

if TYPE_CHECKING:
    from utils.tools.dotslash.providers.base import DotSlashProvider
    from utils.tools.dotslash.schema import DotSlashProviderConfig


def get_provider(config: DotSlashProviderConfig) -> DotSlashProvider:
    type_info = msgspec.inspect.type_info(type(config))
    match type_info.tag:
        case "http":
            from utils.tools.dotslash.providers.http import DotSlashHTTPProvider

            return DotSlashHTTPProvider(config)
        case "github-release":
            from utils.tools.dotslash.providers.github_release import DotSlashGitHubReleaseProvider

            return DotSlashGitHubReleaseProvider(config)
        case "s3":
            from utils.tools.dotslash.providers.s3 import DotSlashS3Provider

            return DotSlashS3Provider(config)
        case _:
            msg = f"Unknown provider type: {type_info.tag}"
            raise ValueError(msg)
