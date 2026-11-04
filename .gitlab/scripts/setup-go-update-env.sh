#!/usr/bin/env bash
# Env setup for Go-update GitLab jobs that call `dda run update agent-build-images`. Source from the repo root.

set -o pipefail
source /root/.bashrc

# Only GO_VERSION is used downstream.
GO_VERSION=$(awk -F= '/^GO_VERSION=/ {print $2}' go.env)
export GO_VERSION

# Install dda (version pinned in dda.env).
DDA_VERSION=$(grep DDA_VERSION dda.env | awk -F= '/^DDA_VERSION=/ {print $2}')
export DDA_VERSION
pip install "dda==${DDA_VERSION}"
dda -v self dep sync -f legacy-build

GITHUB_TOKEN=$(cat token.txt)
export GITHUB_TOKEN
