#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

umask 0002

codex_config_dir="${DD_BUILD_CONFIG_ROOT}/codex"
mkdir -p "${codex_config_dir}"

cat <<'EOF' > "${codex_config_dir}/config.toml"
[mcp_servers.atlassian]
url = "https://mcp.atlassian.com/v1/mcp"

[mcp_servers.google-workspace]
url = "https://google-workspace-mcp-server-834963730936.us-central1.run.app/mcp"

[mcp_servers.ddci]
url = "https://ddci-mcp.mcp.us1.ddbuild.io/internal/mcp"
EOF
