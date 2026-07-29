#!/usr/bin/env bash

set -euo pipefail

TOOLCHAIN_HASH=$(./toolchains/scripts/resolve-toolchain-hash.sh "${TOOLCHAIN_HOST_ARCH}" "${TOOLCHAIN_TARGET_ARCH}")
echo "Resolved toolchain hash: ${TOOLCHAIN_HASH}"

if CHANNEL=$(./toolchains/scripts/resolve-toolchain-channel.sh "${TOOLCHAIN_HOST_ARCH}" "${TOOLCHAIN_TARGET_ARCH}" "${TOOLCHAIN_HASH}"); then
    echo "Toolchain already published for this recipe under ${CHANNEL}/, nothing to do"
    exit 0
fi

echo "No existing artifact for this recipe, building"
./toolchains/scripts/build-crosstool-ng-toolchain.sh

export TOOLCHAIN_HASH
./toolchains/scripts/publish-toolchain.sh
