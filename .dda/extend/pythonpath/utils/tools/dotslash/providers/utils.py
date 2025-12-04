# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

import subprocess
from contextlib import contextmanager
from typing import Any, BinaryIO, Generator


@contextmanager
def subprocess_stream(cmd: list[str], **kwargs: Any) -> Generator[BinaryIO, None, None]:
    with subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs) as process:
        try:
            yield process.stdout
        finally:
            process.wait()
            if process.returncode != 0:
                raise subprocess.CalledProcessError(process.returncode, cmd, stderr=process.stderr)
