#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

umask 0002

# Match env-vars.sh / finalize seed path so MCP and settings land under XDG config defaults.
export CLAUDE_CONFIG_DIR="${DD_BUILD_CONFIG_ROOT}/claude"
mkdir -p "${CLAUDE_CONFIG_DIR}"

cat <<'EOF' > "${CLAUDE_CONFIG_DIR}/settings.json"
{
  "apiKeyHelper": "ddtool auth token rapid-ai-platform --datacenter us1.ddbuild.io",
  "extraKnownMarketplaces": {
    "datadog": {
      "source": {
        "source": "github",
        "repo": "DataDog/claude-marketplace"
      }
    }
  },
  "env": {
    "ANTHROPIC_BASE_URL": "https://ai-gateway.us1.ddbuild.io",
    "ANTHROPIC_CUSTOM_HEADERS": "source: claude-code\norg-id: 2\nprovider: anthropic\nclaude-code: true",
    "CLAUDE_CODE_API_KEY_HELPER_TTL_MS": 7200000
  }
}
EOF

# `claude` comes from tools.sh (DotSlash). Add MCP servers for the image here, for example:

claude mcp add -s user --transport http "datadog" "https://mcp.datadoghq.com/api/unstable/mcp-server/mcp?toolsets=all"


claude mcp add -s user --transport http "ddci-mcp-prod" \
  'https://ddci-mcp.mcp.us1.ddbuild.io/internal/mcp'

claude mcp add datadog-google-workspace -s user --transport http https://google-workspace-mcp-server-834963730936.us-central1.run.app/mcp

claude mcp add --transport http -s user atlassian https://mcp.atlassian.com/v1/mcp

claude mcp add --transport http --client-id 1601185624273.8899143856786 --callback-port 3118 slack https://mcp.slack.com/mcp
