#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

uv tool install "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}"

dda self telemetry disable
dda config set update.mode check
dda self dep sync -f mcp
