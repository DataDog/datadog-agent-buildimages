#!/usr/bin/env bash

set -euo pipefail

source ./toolchains/scripts/lib.sh

HOST_ARCH="$1"
TARGET_ARCH="$2"
DEST="$3"

HASH=$(resolve_toolchain_hash "${HOST_ARCH}" "${TARGET_ARCH}")
CHANNEL=$(resolve_toolchain_channel "${HOST_ARCH}" "${TARGET_ARCH}" "${HASH}")
if [[ -z "${CHANNEL}" ]]; then
    echo "No published toolchain for host=${HOST_ARCH} target=${TARGET_ARCH} (hash=${HASH})" >&2
    exit 1
fi
KEY=$(toolchain_artifact_key "${HOST_ARCH}" "${TARGET_ARCH}" "${HASH}" "${CHANNEL}")
TARBALL=$(mktemp)

if [[ "${TARGET_ARCH}" == "aix" ]]; then
    CHECKSUM_SRI=$(curl --retry 10 -sSf "https://mass-read.us1.ddbuild.io/internal/v1/api/artifact/${KEY}" | grep -o '"checksum_sri":"[^"]*"' | cut -d'"' -f4)
    curl --retry 10 -sSfL "https://mass-read.us1.ddbuild.io/internal/artifact/${KEY}" -o "${TARBALL}"
    ACTUAL_SRI="sha256-$(openssl dgst -sha256 -binary "${TARBALL}" | openssl base64 -A)"
    [[ "${ACTUAL_SRI}" == "${CHECKSUM_SRI}" ]] || { echo "Checksum mismatch for ${KEY}: expected ${CHECKSUM_SRI}, got ${ACTUAL_SRI}" >&2; exit 1; }
else
    S3_BASE_URL="https://dd-agent-build-artifacts.s3.amazonaws.com"
    CHECKSUM=$(curl --retry 10 -sSf "${S3_BASE_URL}/${KEY}.sha256")
    CHECKSUM="${CHECKSUM#sha256:}"
    curl --retry 10 -sSf "${S3_BASE_URL}/${KEY}" -o "${TARBALL}"
    echo "${CHECKSUM}  ${TARBALL}" | sha256sum -c -
fi

mkdir -p "${DEST}"
tar xf "${TARBALL}" -C "${DEST}"
rm "${TARBALL}"
