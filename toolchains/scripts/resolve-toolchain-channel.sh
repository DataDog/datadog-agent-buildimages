#!/usr/bin/env bash

set -euo pipefail

HOST_ARCH="$1"
TARGET_ARCH="$2"
TOOLCHAIN_HASH="$3"

s3_artifact_exists() {
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" --head "https://dd-agent-build-artifacts.s3.amazonaws.com/$1")
    [[ "${status}" == "200" ]]
}

# main/ is always trusted, even off the default branch: a PR that doesn't touch the
# recipe should reuse the canonical artifact instead of rebuilding it. branches/ is
# only trusted for the branch that published it in the first place, since it's never
# checked while on the default branch.
MAIN_KEY=$(./toolchains/scripts/toolchain-artifact-key.sh "${HOST_ARCH}" "${TARGET_ARCH}" "${TOOLCHAIN_HASH}" main)
if s3_artifact_exists "${MAIN_KEY}"; then
    echo "main"
    exit 0
fi

if [[ "${CI_COMMIT_BRANCH:-}" != "${CI_DEFAULT_BRANCH:-}" ]]; then
    BRANCH_KEY=$(./toolchains/scripts/toolchain-artifact-key.sh "${HOST_ARCH}" "${TARGET_ARCH}" "${TOOLCHAIN_HASH}" branches)
    if s3_artifact_exists "${BRANCH_KEY}"; then
        echo "branches"
        exit 0
    fi
fi

exit 1
