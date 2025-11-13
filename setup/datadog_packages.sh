#!/usr/bin/env bash

# This installs datadog-package binary from the datadog-packages repo

DATADOG_PACKAGES_VERSION=bb430d549b551c0aeb466f3f38470971dabdef2c

# Go env might be set only here
[ -f /root/.bashrc ] && . /root/.bashrc

set -euo pipefail

if [ -n "$CI_JOB_TOKEN" ]; then
    export GIT_CONFIG_COUNT=1
    export GIT_CONFIG_KEY_0=url."https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.ddbuild.io/DataDog/".insteadOf
    export GIT_CONFIG_VALUE_0="https://github.com/DataDog/"
    go env -w GOPRIVATE="github.com/DataDog/*"
fi
export PATH="$PATH:$(go env GOPATH)/bin"
go install github.com/DataDog/datadog-packages/cmd/datadog-package@$DATADOG_PACKAGES_VERSION
