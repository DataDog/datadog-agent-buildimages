# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

import os
from typing import TYPE_CHECKING

import click

from dda.cli.base import dynamic_command, pass_app

if TYPE_CHECKING:
    from rich.table import Table

    from dda.cli.application import Application

    from utils.tools.dotslash.artifact import ArtifactMetadata, DotSlashArtifact
    from utils.tools.dotslash.schema import DotSlashArtifactMetadata


@dynamic_command(
    short_help="Validate tool configuration",
    features=["http"],
    dependencies=["blake3>=1.0.8"],
)
@click.option(
    "--integrity",
    is_flag=True,
    help="Include checks for artifact integrity",
)
@click.option(
    "--fix",
    is_flag=True,
    help="Fix errors in tool configuration",
)
@click.option(
    "--force",
    "-f",
    is_flag=True,
    help="Whether to trust providers for integrity fixes",
)
@pass_app
def cmd(app: Application, *, integrity: bool, fix: bool, force: bool) -> None:
    """
    Validate tool configuration.
    """
    from collections import defaultdict
    from concurrent.futures import ThreadPoolExecutor, as_completed

    from msgspec import json
    from rich.live import Live

    from utils.constants import PROJECT_ROOT, TOOL_CONFIG_DIR
    from utils.tools.dotslash.artifact import DotSlashArtifact
    from utils.tools.dotslash.schema import ExtendedDotSlashToolConfig

    if fix and integrity and not force:
        app.display_error("Run with --force to trust providers for integrity fixes")
        app.abort()

    integrity_checks = []

    errors = 0
    tools_processed = 0
    for config_file in TOOL_CONFIG_DIR.glob("*.json"):
        tools_processed += 1
        config_text = config_file.read_text(encoding="utf-8")
        try:
            tool = json.decode(config_text, type=ExtendedDotSlashToolConfig)
        except Exception as e:
            app.display_error(f"{config_file.relative_to(PROJECT_ROOT)} is not valid: {e}")
            errors += 1
            continue

        formatted_schema = construct_tool_config(tool)
        if formatted_schema != config_text:
            errors += 1
            if fix:
                config_file.write_text(formatted_schema, encoding="utf-8")
                app.display_success(f"Formatted {config_file.relative_to(PROJECT_ROOT)}")
                errors -= 1
            else:
                app.display_error(f"{config_file.relative_to(PROJECT_ROOT)} is not formatted correctly")
                continue

        if integrity:
            for platform, artifact_config in tool.platforms.items():
                artifact = DotSlashArtifact(artifact_config)
                for i in range(len(artifact_config.providers)):
                    integrity_checks.append((
                        tool.name,
                        platform,
                        tool.extra_metadata.platforms[platform] if tool.extra_metadata else None,
                        artifact,
                        i,
                    ))

    if errors:
        if not fix:
            app.display_error("Run with --fix to fix the issues")

        app.abort()

    if not integrity:
        app.display_success(f"Validated tool schemas: {tools_processed}")
        return

    platform_artifacts: defaultdict[str, int] = defaultdict(int)
    pending_fixes: dict[str, dict[str, dict[int, ArtifactMetadata]]] = defaultdict(
        lambda: defaultdict(lambda: defaultdict(int)),
    )
    failed_tools: dict[str, dict[str, dict[int, list[str]]]] = defaultdict(
        lambda: defaultdict(lambda: defaultdict(list)),
    )
    with (
        Live(auto_refresh=False) as live,
        ThreadPoolExecutor(max_workers=min(len(integrity_checks), (os.cpu_count() or 8) * 4)) as executor,
    ):
        futures = {
            executor.submit(check_integrity, *integrity_check): integrity_check
            for integrity_check in integrity_checks
        }
        try:
            for future in as_completed(list(futures)):
                try:
                    metadata, errors, tool_name, platform, artifact_index = future.result()
                except Exception as e:
                    tool_name, platform, _, artifact_index = futures[future]
                    failed_tools[tool_name][platform][artifact_index] = [str(e)]
                else:
                    if errors:
                        if fix:
                            pending_fixes[tool_name][platform][artifact_index] = metadata
                        else:
                            failed_tools[tool_name][platform][artifact_index] = errors

                platform_artifacts[platform] += 1
                live.update(generate_table(platform_artifacts), refresh=True)
        except KeyboardInterrupt:
            live.stop()
            app.display_warning("Canceling integrity checks...")
            for future in futures:
                future.cancel()
            app.abort()

    check_failed_tools(app, failed_tools)

    if pending_fixes:
        for tool_name, platforms in sorted(pending_fixes.items()):
            for platform, artifacts in sorted(platforms.items()):
                metadata_fields = defaultdict(lambda: defaultdict(set))
                for artifact_index, metadata in artifacts.items():
                    metadata_fields["digest"][metadata.digest].add(artifact_index)
                    metadata_fields["size"][metadata.size].add(artifact_index)
                    metadata_fields["uncompressed_size"][metadata.uncompressed.size].add(artifact_index)
                    if not metadata.uncompressed.path_exists:
                        failed_tools[tool_name][platform][artifact_index].append(
                            f"Missing path: {metadata.uncompressed.path}"
                        )

                for field, artifact_values in metadata_fields.items():
                    if len(artifact_values) > 1:
                        for metadata_value, artifact_indices in artifact_values.items():
                            for artifact_index in artifact_indices:
                                failed_tools[tool_name][platform][artifact_index].append(
                                    f"Metadata mismatch: {field} ({metadata_value})"
                                )

        check_failed_tools(app, failed_tools)

        for tool_name, platforms in sorted(pending_fixes.items()):
            config_file = TOOL_CONFIG_DIR.joinpath(f"{tool_name}.json")
            config_text = config_file.read_text(encoding="utf-8")
            tool = json.decode(config_text)
            for platform, artifacts in sorted(platforms.items()):
                for artifact_index, metadata in artifacts.items():
                    tool["platforms"][platform]["digest"] = metadata.digest
                    tool["platforms"][platform]["size"] = metadata.size
                    tool.setdefault("__extra_metadata", {}).setdefault("platforms", {}).setdefault(platform, {})["uncompressed_size"] = metadata.uncompressed.size

            config_file.write_text(construct_tool_config(tool), encoding="utf-8")
            app.display_success(f"Fixed {config_file.relative_to(PROJECT_ROOT)}")


def check_integrity(
    tool_name: str,
    platform: str,
    expected_metadata: DotSlashArtifactMetadata | None,
    artifact: DotSlashArtifact,
    provider_index: int,
) -> tuple[ArtifactMetadata, list[str], str, str, int]:
    metadata = artifact.read_metadata(provider_index=provider_index)

    errors = []
    if not metadata.uncompressed.path_exists:
        errors.append(f"Missing path: {artifact.config.path}")

    if metadata.digest != artifact.config.digest:
        errors.extend((
            "Digest mismatch:",
            f"  Expected: {artifact.config.digest}",
            f"  Actual: {metadata.digest}",
        ))

    if metadata.size != artifact.config.size:
        errors.extend((
            "Size mismatch:",
            f"  Expected: {artifact.config.size}",
            f"  Actual: {metadata.size}",
        ))

    if expected_metadata is None:
        errors.append("Missing __extra_metadata")
    elif metadata.uncompressed.size != expected_metadata.uncompressed_size:
        errors.extend((
            "Uncompressed size mismatch:",
            f"  Expected: {expected_metadata.uncompressed_size}",
            f"  Actual: {metadata.uncompressed.size}",
        ))

    return (metadata, errors, tool_name, platform, provider_index)


def generate_table(platform_artifacts: dict[str, int]) -> Table:
    from rich.table import Table

    table = Table()
    table.add_column("Platform")
    table.add_column("Artifacts")

    sorted_systems = ("linux", "windows", "macos")
    for platform, count in sorted(
        platform_artifacts.items(),
        key=lambda p: (sorted_systems.index(p[0].split("-")[0]), p),
    ):
        table.add_row(platform, f"{count}")

    return table


def check_failed_tools(app: Application, failed_tools: dict[str, dict[str, dict[int, list[str]]]]) -> None:
    if not failed_tools:
        return

    app.display_error("Failed tools:")
    for tool_name, platforms in sorted(failed_tools.items()):
        app.display_error(f"  {tool_name}:")
        for platform, artifacts in sorted(platforms.items()):
            app.display_error(f"    {platform}:")
            for artifact_index, errors in sorted(artifacts.items()):
                app.display_error(f"      Artifact #{artifact_index + 1}:")
                for error in errors:
                    app.display_error(f"        {error}")

    app.abort()


def construct_tool_config(config) -> str:
    from msgspec import json

    return f"{json.format(json.encode(config, order='sorted')).decode()}\n"
