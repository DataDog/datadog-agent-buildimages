#!/usr/bin/env bash

# This installs datadog-package binary from the datadog-packages repo

DATADOG_PACKAGES_VERSION=bb430d549b551c0aeb466f3f38470971dabdef2c

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

# Make sure to delete the source code after installing since the repo is private
rm -rf /go/pkg/mod/github.com/\!data\!dog/datadog-packages*
