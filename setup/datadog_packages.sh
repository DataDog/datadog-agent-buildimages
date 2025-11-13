#!/usr/bin/env bash

# This installs datadog-package binary from the datadog-packages repo

DATADOG_PACKAGES_VERSION=bb430d549b551c0aeb466f3f38470971dabdef2c

# Go env might be set only here
[ -f /root/.bashrc ] && . /root/.bashrc

set -euo pipefail

if [ -n "$CI_JOB_TOKEN" ]; then
    # git config --global url."https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.ddbuild.io/DataDog/".insteadOf "https://github.com/DataDog/"

    cat > /tmp/gitconfig <<EOF
[url "https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.ddbuild.io/DataDog/"]
    insteadOf = https://github.com/DataDog/
EOF

    export GIT_CONFIG_GLOBAL=/dev/null
    export GIT_CONFIG_SYSTEM=/dev/null
    export GIT_CONFIG=/tmp/gitconfig
    go env -w GOPRIVATE="github.com/DataDog/*"
fi
# export PATH="$PATH:$(go env GOPATH)/bin"
go install github.com/DataDog/datadog-packages/cmd/datadog-package@$DATADOG_PACKAGES_VERSION

rm -f /tmp/gitconfig
