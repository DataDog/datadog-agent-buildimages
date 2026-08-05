#!/usr/bin/env bash

set -euo pipefail

source ./toolchains/scripts/lib.sh

HOST_ARCH="$1"
TARGET_ARCH="$2"
DEST="$3"

S3_BASE_URL="https://dd-agent-build-artifacts.s3.amazonaws.com"

HASH=$(resolve_toolchain_hash "${HOST_ARCH}" "${TARGET_ARCH}")
CHANNEL=$(resolve_toolchain_channel "${HOST_ARCH}" "${TARGET_ARCH}" "${HASH}")
if [[ -z "${CHANNEL}" ]]; then
    echo "No published toolchain for host=${HOST_ARCH} target=${TARGET_ARCH} (hash=${HASH})" >&2
    exit 1
fi
KEY=$(toolchain_artifact_key "${HOST_ARCH}" "${TARGET_ARCH}" "${HASH}" "${CHANNEL}")
CHECKSUM=$(curl --retry 10 -sSf "${S3_BASE_URL}/${KEY}.sha256")
CHECKSUM="${CHECKSUM#sha256:}"

TARBALL=$(mktemp)
curl --retry 10 -sSf "${S3_BASE_URL}/${KEY}" -o "${TARBALL}"
echo "${CHECKSUM}  ${TARBALL}" | sha256sum -c -

mkdir -p "${DEST}"
tar xf "${TARBALL}" -C "${DEST}"
rm "${TARBALL}"
