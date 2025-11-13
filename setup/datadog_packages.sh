#!/usr/bin/env bash

# Go env might be set only here
[ -f /root/.bashrc ] && . /root/.bashrc

set -euo pipefail

DATADOG_PACKAGES_VERSION=bb430d549b551c0aeb466f3f38470971dabdef2c

if [ -n "$CI_JOB_TOKEN" ]; then
    git config --global url."https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.ddbuild.io/DataDog/".insteadOf "https://github.com/DataDog/"
    go env -w GOPRIVATE="github.com/DataDog/*"
fi
export PATH="$PATH:$(go env GOPATH)/bin"
go install github.com/DataDog/datadog-packages/cmd/datadog-package@$DATADOG_PACKAGES_VERSION
