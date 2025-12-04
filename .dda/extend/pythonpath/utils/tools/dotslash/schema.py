from __future__ import annotations

from typing import Annotated, Literal

from msgspec import Meta, Struct, field

SupportedPlatforms = Literal[
    "linux-aarch64",
    "linux-x86_64",
    "windows-aarch64",
    "windows-x86_64",
    "macos-aarch64",
    "macos-x86_64",
]
SupportedProviders = Literal[
    "http",
    "github-release",
    "s3",
]
SupportedArtifactFormats = Literal[
    "plain",
    "bz2",
    "gz",
    "tar",
    "tar.bz2",
    "tar.gz",
    "tar.xz",
    "tar.zst",
    "xz",
    "zip",
    "zst",
]
SupportedHashAlgorithms = Literal[
    "blake3",
    "sha256",
]


class DotSlashProviderConfig(Struct, tag_field="type", omit_defaults=True, kw_only=True):
    weight: Annotated[int, Meta(gt=0)] = 1


class DotSlashHTTPProviderConfig(DotSlashProviderConfig, tag="http"):
    url: Annotated[str, Meta(min_length=1)]


class DotSlashGitHubReleaseProviderConfig(DotSlashProviderConfig, tag="github-release"):
    repo: Annotated[str, Meta(min_length=1)]
    tag: Annotated[str, Meta(min_length=1)]
    name: Annotated[str, Meta(min_length=1)]


class DotSlashS3ProviderConfig(DotSlashProviderConfig, tag="s3"):
    repo: Annotated[str, Meta(min_length=1)]
    key: Annotated[str, Meta(min_length=1)]
    region: Annotated[str, Meta(min_length=1)]


class DotSlashArtifactConfig(Struct, omit_defaults=True):
    size: Annotated[int, Meta(gt=0)]
    hash: SupportedHashAlgorithms
    digest: Annotated[str, Meta(min_length=64, max_length=64)]
    path: Annotated[str, Meta(min_length=1)]
    providers: list[
        DotSlashHTTPProviderConfig
        | DotSlashGitHubReleaseProviderConfig
        | DotSlashS3ProviderConfig
    ]
    format: SupportedArtifactFormats = "plain"
    arg0: Literal["dotslash-file", "underlying-executable"] = "dotslash-file"
    readonly: bool = True
    providers_order: Literal["sequential", "weighted-random"] = "sequential"


class DotSlashToolConfig(Struct):
    name: Annotated[str, Meta(min_length=1)]
    platforms: dict[SupportedPlatforms, DotSlashArtifactConfig]


class DotSlashArtifactMetadata(Struct):
    uncompressed_size: int


class DotSlashToolMetadata(Struct):
    platforms: dict[SupportedPlatforms, DotSlashArtifactMetadata]


class ExtendedDotSlashToolConfig(DotSlashToolConfig, omit_defaults=True):
    extra_metadata: DotSlashToolMetadata | None = field(default=None, name="__extra_metadata")
