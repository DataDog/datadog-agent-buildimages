# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

from abc import ABC, abstractmethod
from contextlib import contextmanager
from typing import TYPE_CHECKING, BinaryIO, Generator

if TYPE_CHECKING:
    from utils.tools.dotslash.schema import DotSlashProviderConfig


class DotSlashProvider(ABC):
    def __init__(self, config: DotSlashProviderConfig):
        self.__config = config

    @property
    def config(self) -> DotSlashProviderConfig:
        return self.__config

    @contextmanager
    @abstractmethod
    def artifact_stream(self) -> Generator[BinaryIO, None, None]:
        pass
