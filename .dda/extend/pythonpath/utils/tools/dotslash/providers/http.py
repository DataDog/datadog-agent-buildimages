# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

from contextlib import contextmanager
from typing import BinaryIO, Generator
from urllib.request import urlopen

from utils.tools.dotslash.providers.base import DotSlashProvider


class DotSlashHTTPProvider(DotSlashProvider):
    @contextmanager
    def artifact_stream(self) -> Generator[BinaryIO, None, None]:
        with urlopen(self.config.url) as resp:
            yield resp
