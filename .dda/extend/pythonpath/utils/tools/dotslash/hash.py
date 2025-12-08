# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from hashlib import _Hash

    from utils.tools.dotslash.schema import SupportedHashAlgorithms


def get_hasher(algorithm: SupportedHashAlgorithms) -> _Hash:
    match algorithm:
        case "blake3":
            from blake3 import blake3

            return blake3()
        case "sha256":
            from hashlib import sha256

            return sha256()
        case _:
            msg = f"Unknown hash algorithm: {algorithm}"
            raise ValueError(msg)
