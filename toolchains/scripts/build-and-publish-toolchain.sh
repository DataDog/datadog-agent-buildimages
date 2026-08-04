#!/usr/bin/env bash

set -euo pipefail

source ./toolchains/scripts/lib.sh

TOOLCHAIN_HASH=$(resolve_toolchain_hash "${TOOLCHAIN_HOST_ARCH}" "${TOOLCHAIN_TARGET_ARCH}")
echo "Resolved toolchain hash: ${TOOLCHAIN_HASH}"

CHANNEL=$(resolve_toolchain_channel "${TOOLCHAIN_HOST_ARCH}" "${TOOLCHAIN_TARGET_ARCH}" "${TOOLCHAIN_HASH}")
if [[ -n "${CHANNEL}" ]]; then
    KEY=$(toolchain_artifact_key "${TOOLCHAIN_HOST_ARCH}" "${TOOLCHAIN_TARGET_ARCH}" "${TOOLCHAIN_HASH}" "${CHANNEL}")
    echo "Toolchain already published for this recipe under ${CHANNEL}/, nothing to do"
    echo "Toolchain: https://dd-agent-build-artifacts.s3.amazonaws.com/${KEY}"
    exit 0
fi

echo "No existing artifact for this recipe, building"
./toolchains/scripts/build-crosstool-ng-toolchain.sh

export TOOLCHAIN_HASH
./toolchains/scripts/publish-toolchain.sh
