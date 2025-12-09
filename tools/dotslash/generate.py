# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from platform import machine


def eprint(message: str):
    print(message, file=sys.stderr)


def exit_with(message: str):
    eprint(message)
    sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Generate DotSlash files from tool configuration"
    )
    parser.add_argument(
        "--config-dir",
        type=Path,
        required=True,
        help="Path to the directory containing tool configuration",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        required=True,
        help="Path to the directory for generated DotSlash files",
    )
    parser.add_argument(
        "--tools",
        type=str,
        help="A comma-separated list of tools to generate",
    )
    parser.add_argument(
        "--tools-file",
        type=Path,
        help="The path to a file containing a newline-separated list of tools to generate",
    )
    parser.add_argument(
        "--ignore-unavailable",
        action="store_true",
        help="Continue even if some tools are not available for the current platform",
    )

    args = parser.parse_args()

    if not (args.tools or args.tools_file):
        exit_with("Either --tools or --tools-file must be specified")

    if args.tools and args.tools_file:
        exit_with("Only one of --tools or --tools-file can be specified")

    if not args.config_dir.is_dir():
        exit_with(f"Configuration directory not found: {args.config_dir}")

    arch = machine().lower()
    match sys.platform, arch:
        case "linux", "aarch64":
            platform = "linux-aarch64"
        case "linux", "x86_64":
            platform = "linux-x86_64"
        case "windows", "arm64":
            platform = "windows-aarch64"
        case "windows", "amd64":
            platform = "windows-x86_64"
        case "macos", "arm64":
            platform = "macos-aarch64"
        case "macos", "x86_64":
            platform = "macos-x86_64"
        case _:
            exit_with(f"Unsupported platform/architecture: {sys.platform} {arch}")

    eprint(f"Generating DotSlash files for platform: {platform}")

    args.output_dir.mkdir(parents=True, exist_ok=True)
    generated_tools: set[str] = set()

    if args.tools:
        selected_tools = set(args.tools.split(","))
    elif args.tools_file:
        selected_tools = set(
            tool_name
            for line in args.tools_file.read_text(encoding="utf-8").splitlines()
            if not line.startswith("#") and (tool_name := line.strip())
        )
    else:
        selected_tools = set(
            entry.stem
            for entry in args.config_dir.iterdir()
            if entry.name.endswith(".json")
        )

    unavailable_tools = []
    for tool_name in sorted(selected_tools):
        tool_config_file = args.config_dir / f"{tool_name}.json"
        if not tool_config_file.is_file() or not tool_config_file.name.endswith(".json"):
            exit_with(f"Tool configuration not found: {tool_config_file}")

        tool_config = json.loads(tool_config_file.read_text(encoding="utf-8"))
        if platform not in tool_config["platforms"]:
            unavailable_tools.append(tool_name)
            continue

        eprint(f"Tool: {tool_name}")

        dotslash_file = args.output_dir / tool_name
        dotslash_file.write_text(
            "\n".join((
                "#!/usr/bin/env dotslash",
                json.dumps(
                    {
                        "name": tool_name,
                        "platforms": {
                            platform: tool_config["platforms"][platform]
                        },
                    },
                    separators=(",", ":"),
                )
            )),
            encoding="utf-8",
        )
        if sys.platform != "windows":
            dotslash_file.chmod(0o755)

        generated_tools.add(tool_name)

    eprint(f"Generated DotSlash files: {len(generated_tools)}")
    if unavailable_tools:
        msg = "Unavailable tools:"
        for tool_name in unavailable_tools:
            msg += f"\n  {tool_name}"

        if args.ignore_unavailable:
            eprint(msg)
        else:
            exit_with(msg)

if __name__ == "__main__":
    main()
