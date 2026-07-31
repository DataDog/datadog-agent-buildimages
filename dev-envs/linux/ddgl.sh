#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# Set up an isolated installation so the XDG_DATA_HOME directory can be used
# exclusively for user-installed tools and persisted as a named volume
export UV_PYTHON_INSTALL_DIR="${DD_BUILD_INSTALL_ROOT}/dda/base"
export UV_TOOL_DIR="${DD_BUILD_INSTALL_ROOT}/dda/venv"
export UV_TOOL_BIN_DIR="/usr/local/bin"

DDGL_VERSION=v0.2.0

(
    umask 0002
    uv tool install "git+https://github.com/DataDog/ddgl-cli.git@${DDGL_VERSION}"
)

ddgl_config_dir="${DD_BUILD_CONFIG_ROOT}/ddgl"
mkdir -p "${ddgl_config_dir}"

cat <<'EOF' > "${ddgl_config_dir}/config.toml"
gitlab_url="https://gitlab.ddbuild.io"
github_fallback = true
token_command = ["ddtool", "auth", "token", "gitlab", "--datacenter", "us1.ddbuild.io"]
EOF
