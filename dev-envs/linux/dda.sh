#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# Set up an isolated installation so the XDG_DATA_HOME directory can be used
# exclusively for user-installed tools and persisted as a named volume
export UV_PYTHON_INSTALL_DIR="${DD_BUILD_INSTALL_ROOT}/dda/base"
export UV_TOOL_DIR="${DD_BUILD_INSTALL_ROOT}/dda/venv"
export UV_TOOL_BIN_DIR="/usr/local/bin"

uv tool install "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}"

dda self telemetry disable
dda config set update.mode check
dda self dep sync -f mcp

# TODO: Remove this once dda stops writing configuration with restrictive mode (0600).
chmod g+rw "${DD_BUILD_DATA_ROOT}/dd-agent-dev/config.toml" || true
