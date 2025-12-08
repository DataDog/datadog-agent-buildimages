# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

from typing import TYPE_CHECKING, get_args

import click

from dda.cli.base import dynamic_command, pass_app

if TYPE_CHECKING:
    from rich.table import Table

    from dda.cli.application import Application


@dynamic_command(
    short_help="Display tool information",
)
@click.option(
    "--json",
    "as_json",
    is_flag=True,
    help="Output information in JSON format",
)
@pass_app
def cmd(app: Application, *, as_json: bool) -> None:
    """
    Display tool information.
    """
    import msgspec
    from rich.live import Live
    from utils.constants import TOOL_CONFIG_DIR
    from utils.tools.dotslash.schema import (
        ExtendedDotSlashToolConfig,
        SupportedPlatforms,
        SupportedHashAlgorithms,
        SupportedArtifactFormats,
        SupportedProviders,
    )

    supported_platforms = get_args(SupportedPlatforms)
    supported_hash_algorithms = get_args(SupportedHashAlgorithms)
    supported_artifact_formats = get_args(SupportedArtifactFormats)
    supported_providers = get_args(SupportedProviders)
    platforms: dict[str, dict[str, int | dict[str, int]]] = {
        platform: {
            "artifacts": {"defined": 0, "sources": 0},
            "sizes": {"compressed": 0, "uncompressed": 0},
            "providers": dict.fromkeys(supported_providers, 0),
            "formats": dict.fromkeys(supported_artifact_formats, 0),
            "hash_algorithms": dict.fromkeys(supported_hash_algorithms, 0),
        }
        for platform in supported_platforms
    }
    with Live(auto_refresh=not as_json) as live:
        for config_file in TOOL_CONFIG_DIR.glob("*.json"):
            tool = msgspec.json.decode(config_file.read_bytes(), type=ExtendedDotSlashToolConfig)
            for platform_key, artifact_config in tool.platforms.items():
                platform = platforms[platform_key]
                platform["artifacts"]["defined"] += 1
                platform["artifacts"]["sources"] += len(artifact_config.providers)
                platform["sizes"]["compressed"] += artifact_config.size
                if tool.extra_metadata:
                    platform["sizes"]["uncompressed"] += tool.extra_metadata.platforms[platform_key].uncompressed_size
                platform["formats"][artifact_config.format] += 1
                platform["hash_algorithms"][artifact_config.hash] += 1
                for provider in artifact_config.providers:
                    provider_type = msgspec.inspect.type_info(type(provider)).tag
                    platform["providers"][provider_type] += 1

            if not as_json:
                live.update(generate_table(platforms))

    if as_json:
        app.display(msgspec.json.encode(platforms, order="sorted").decode())


def generate_table(platforms: dict[str, dict[str, int | dict[str, int]]]) -> Table:
    from binary import convert_units
    from rich.table import Table

    table = Table()
    table.add_column("Platform")
    table.add_column("Artifacts")
    table.add_column("Size")
    table.add_column("Providers")
    table.add_column("Artifact Formats")
    table.add_column("Hash Algorithms")

    for platform, data in platforms.items():
        if not any(data["artifacts"].values()):
            continue

        row = [platform]
        artifacts_table = Table(show_header=False)
        for artifact_type, artifact_type_count in data["artifacts"].items():
            if artifact_type_count:
                artifacts_table.add_row(artifact_type, str(artifact_type_count))
        row.append(artifacts_table)

        size_table = Table(show_header=False)
        for size_type, size_bytes in data["sizes"].items():
            if size_bytes:
                size, unit = convert_units(size_bytes)
                size_table.add_row(size_type, f"{size:.2f} {unit}")
        row.append(size_table)

        provider_table = Table(show_header=False)
        for provider_type, provider_type_count in data["providers"].items():
            if provider_type_count:
                provider_table.add_row(provider_type, str(provider_type_count))
        row.append(provider_table)

        format_table = Table(show_header=False)
        for artifact_format, artifact_format_count in data["formats"].items():
            if artifact_format_count:
                format_table.add_row(artifact_format, str(artifact_format_count))
        row.append(format_table)

        hash_table = Table(show_header=False)
        for hash_algorithm, hash_algorithm_count in data["hash_algorithms"].items():
            if hash_algorithm_count:
                hash_table.add_row(hash_algorithm, str(hash_algorithm_count))
        row.append(hash_table)

        table.add_row(*row)

    return table
