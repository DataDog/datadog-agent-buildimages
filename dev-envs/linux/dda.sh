#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
    GO_ARCH="x86_64"; \
    elif [ "$ARCH" = "arm64" ]; then \
    GO_ARCH="aarch64"; \
    fi && \
    curl -fsSL --retry 4 "https://github.com/DataDog/datadog-agent-dev/releases/download/${DDA_VERSION}/dda-${GO_ARCH}-unknown-linux-gnu.tar.gz" \
    | tar -xzf - -C /usr/local/bin && \
    chmod +x /usr/local/bin/dda

dda self telemetry disable
dda config set update.mode check
dda self dep sync -f mcp
