#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

umask 0002

# Match env-vars.sh / finalize seed path so MCP and settings land under XDG config defaults.
export CLAUDE_CONFIG_DIR="${DD_BUILD_CONFIG_ROOT}/claude"
mkdir -p "${CLAUDE_CONFIG_DIR}"

# `claude` comes from tools.sh (DotSlash). Add MCP servers for the image here, for example:
claude mcp add -s user --transport http "ddci-mcp-prod" \
  'https://ddci-mcp.mcp.us1.ddbuild.io/internal/mcp'

claude mcp add datadog-google-workspace -s user --transport http https://google-workspace-mcp-server-834963730936.us-central1.run.app/mcp

claude mcp add --transport http -s user atlassian https://mcp.atlassian.com/v1/mcp

