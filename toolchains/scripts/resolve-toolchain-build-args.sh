#!/usr/bin/env bash

set -euo pipefail

HOST_ARCH="$1"
TARGET_ARCH="$2"

if [[ "${HOST_ARCH}" == "${TARGET_ARCH}" ]]; then
    PREFIX="NATIVE"
else
    PREFIX="CROSS"
fi

HASH=$(./toolchains/scripts/resolve-toolchain-hash.sh "${HOST_ARCH}" "${TARGET_ARCH}")
CHANNEL=$(./toolchains/scripts/resolve-toolchain-channel.sh "${HOST_ARCH}" "${TARGET_ARCH}" "${HASH}")

echo "export ${PREFIX}_TOOLCHAIN_KEY=$(./toolchains/scripts/toolchain-artifact-key.sh "${HOST_ARCH}" "${TARGET_ARCH}" "${HASH}" "${CHANNEL}")"
echo "export ${PREFIX}_TOOLCHAIN_CHECKSUM=$(./toolchains/scripts/toolchain-artifact-checksum.sh "${HOST_ARCH}" "${TARGET_ARCH}" "${HASH}" "${CHANNEL}")"
