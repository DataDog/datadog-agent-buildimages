# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

from os.path import normpath
from tempfile import SpooledTemporaryFile
from typing import TYPE_CHECKING, BinaryIO

from binary import BinaryUnits
from msgspec import Struct

from utils.tools.dotslash.hash import get_hasher
from utils.tools.dotslash.providers import get_provider

if TYPE_CHECKING:
    from utils.tools.dotslash.schema import DotSlashArtifactConfig

BUFFER_SIZE = 256 * BinaryUnits.KB


class UncompressedArtifactMetadata(Struct):
    size: int
    path: str
    path_exists: bool


class ArtifactMetadata(Struct):
    digest: str
    size: int
    uncompressed: UncompressedArtifactMetadata


class DotSlashArtifact:
    def __init__(self, config: DotSlashArtifactConfig):
        self.__config = config

    @property
    def config(self) -> DotSlashArtifactConfig:
        return self.__config

    def read_metadata(self, *, provider_index: int) -> ArtifactMetadata:
        provider_config = self.__config.providers[provider_index]
        provider = get_provider(provider_config)
        hasher = get_hasher(self.__config.hash)
        size = 0
        with provider.artifact_stream() as stream, SpooledTemporaryFile() as temp_file:
            while chunk := stream.read(BUFFER_SIZE):
                temp_file.write(chunk)
                hasher.update(chunk)
                size += len(chunk)

            temp_file.seek(0)

            match self.__config.format:
                case "plain":
                    uncompressed = _read_plain(fileobj=temp_file, path=self.__config.path)
                case "tar":
                    uncompressed = _read_tar(fileobj=temp_file, path=self.__config.path, mode="r:")
                case "tar.gz":
                    uncompressed = _read_tar(fileobj=temp_file, path=self.__config.path, mode="r:gz")
                case "tar.bz2":
                    uncompressed = _read_tar(fileobj=temp_file, path=self.__config.path, mode="r:bz2")
                case "tar.xz":
                    uncompressed = _read_tar(fileobj=temp_file, path=self.__config.path, mode="r:xz")
                case "tar.zst":
                    uncompressed = _read_tar(fileobj=temp_file, path=self.__config.path, mode="r:zst")
                case "zip":
                    uncompressed = _read_zip(fileobj=temp_file, path=self.__config.path)
                case _:
                    msg = f"Unknown artifact format: {self.__config.format}"
                    raise ValueError(msg)

            return ArtifactMetadata(digest=hasher.hexdigest(), size=size, uncompressed=uncompressed)


def _read_tar(*, fileobj: BinaryIO, path: str, mode: str) -> UncompressedArtifactMetadata:
    import tarfile

    size = 0
    found = False
    with tarfile.open(fileobj=fileobj, mode=mode) as tf:
        for member in tf:
            size += member.size
            if _normalize_path(member.name) == path:
                found = True

    return UncompressedArtifactMetadata(size=size, path=path, path_exists=found)


def _read_zip(*, fileobj: BinaryIO, path: str) -> UncompressedArtifactMetadata:
    import zipfile

    size = 0
    found = False
    with zipfile.ZipFile(fileobj) as zf:
        for member in zf.infolist():
            size += member.file_size
            if _normalize_path(member.filename) == path:
                found = True
                break

    return UncompressedArtifactMetadata(size=size, path=path, path_exists=found)


def _read_plain(*, fileobj: BinaryIO, path: str) -> UncompressedArtifactMetadata:
    import os

    size = os.fstat(fileobj.fileno()).st_size
    return UncompressedArtifactMetadata(size=size, path=path, path_exists=True)


def _normalize_path(path: str) -> str:
    return normpath(path).replace("\\", "/")
