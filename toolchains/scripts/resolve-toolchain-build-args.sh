#!/usr/bin/env bash

set -euo pipefail

source ./toolchains/scripts/lib.sh

HOST_ARCH="$1"
TARGET_ARCH="$2"

if [[ "${HOST_ARCH}" == "${TARGET_ARCH}" ]]; then
    PREFIX="NATIVE"
else
    PREFIX="CROSS"
fi

HASH=$(resolve_toolchain_hash "${HOST_ARCH}" "${TARGET_ARCH}")
CHANNEL=$(resolve_toolchain_channel "${HOST_ARCH}" "${TARGET_ARCH}" "${HASH}")
KEY=$(toolchain_artifact_key "${HOST_ARCH}" "${TARGET_ARCH}" "${HASH}" "${CHANNEL}")

echo "export ${PREFIX}_TOOLCHAIN_KEY=${KEY}"
echo "export ${PREFIX}_TOOLCHAIN_CHECKSUM=$(curl -sSf "https://dd-agent-build-artifacts.s3.amazonaws.com/${KEY}.sha256")"
