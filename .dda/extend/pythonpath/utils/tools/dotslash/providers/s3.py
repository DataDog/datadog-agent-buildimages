# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

from contextlib import contextmanager
from typing import BinaryIO, Generator

from utils.tools.dotslash.providers.base import DotSlashProvider
from utils.tools.dotslash.providers.utils import subprocess_stream


class DotSlashS3Provider(DotSlashProvider):
    @contextmanager
    def artifact_stream(self) -> Generator[BinaryIO, None, None]:
        cmd = [
            "aws",
            "s3",
            "cp",
            "--region",
            self.config.region,
            f"s3://{self.config.repo}/{self.config.key}",
            "-",
        ]
        with subprocess_stream(cmd) as process:
            yield process
