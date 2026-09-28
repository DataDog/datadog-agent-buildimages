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
if [[ "${TOOLCHAIN_TARGET_ARCH}" == "aix" ]]; then
    ./toolchains/scripts/build-aix-toolchain.sh
else
    ./toolchains/scripts/build-crosstool-ng-toolchain.sh
fi

export TOOLCHAIN_HASH
./toolchains/scripts/publish-toolchain.sh
