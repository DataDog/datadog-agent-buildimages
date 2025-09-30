# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

from typing import TYPE_CHECKING

import click

from dda.cli.base import dynamic_command, pass_app

if TYPE_CHECKING:
    from dda.cli.application import Application
    from dda.utils.fs import Path


def apply_build_args(env_file: Path, build_args: list[str]) -> None:
    with env_file.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            build_args.extend(("--build-arg", line))


@dynamic_command(short_help="Build the images", context_settings={"ignore_unknown_options": True})
@click.argument("relative_path")
@click.argument("tag")
@click.argument("args", nargs=-1)
@pass_app
def cmd(app: Application, *, relative_path: str, tag: str, args: tuple[str, ...]) -> None:
    """
    Build the images using the proper environment variables. The Linux image accepts the
    path to a variant directory like `linux/x64` rather than the directory containing the
    Dockerfile.

    Example usage:

    ```
    dda run build linux/arm64 datadog/agent-buildimages-linux:dev
    ```
    """
    import os

    from dda.utils.fs import Path

    arch = os.environ.get("ARCH")
    if not arch:
        import platform

        arch = platform.machine().lower()
        if arch == "amd64":
            arch = "x86_64"
        elif arch == "arm64":
            arch = "aarch64"
    dd_arch = os.environ.get("DD_TARGET_ARCH", "x64" if arch == "x86_64" else arch)

    build_args = ["build"]
    extra_args = ["--build-arg", f"ARCH={arch}", "--build-arg", f"DD_TARGET_ARCH={dd_arch}"]

    # Apply build args from the global environment files
    for entry in Path.cwd().glob("*.env"):
        apply_build_args(entry, extra_args)

    relative_path = os.path.normpath(relative_path)
    root_dir = relative_path.split(os.path.sep)[0]

    # Allow targeting the variant directory like `linux/arm64`
    linux_variants = {os.path.join("linux", entry.name) for entry in Path("linux").iterdir() if entry.is_dir()}
    if relative_path in linux_variants:
        apply_build_args(Path(relative_path, "build.env"), extra_args)
        relative_path = "linux"

    # Non-developer environment images expect to be built in the root directory
    if root_dir == "dev-envs":
        build_args.append(relative_path)
    else:
        build_args.append(".")
        build_args.extend(("-f", os.path.join(relative_path, "Dockerfile")))

    build_args.extend(("--tag", tag))
    build_args.extend(extra_args)
    build_args.extend(args)

    process = app.tools.docker.attach(build_args, check=False)
    app.abort(code=process.returncode)
