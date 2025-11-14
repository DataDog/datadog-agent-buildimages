#!/usr/bin/env bash

# This installs datadog-package binary from the datadog-packages repo

# Fetch build environment variables
. /mnt/build.env

# Go env might be set only here
[ -f /root/.bashrc ] && . /root/.bashrc

set -euo pipefail

if [ -n "$CI_JOB_TOKEN" ]; then
    git config --global url."https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.ddbuild.io/DataDog/".insteadOf "https://github.com/DataDog/"
    go env -w GOPRIVATE="github.com/DataDog/*"
fi
go install github.com/DataDog/datadog-packages/cmd/datadog-package@$DATADOG_PACKAGES_VERSION

if [ -n "$CI_JOB_TOKEN" ]; then
    git config --global --unset url."https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.ddbuild.io/DataDog/".insteadOf
fi
