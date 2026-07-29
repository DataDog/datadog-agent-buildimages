#!/usr/bin/env bash

set -euo pipefail

HOST_ARCH="$1"
TARGET_ARCH="$2"

CONFIG=$(./toolchains/scripts/toolchain-config-path.sh "${HOST_ARCH}" "${TARGET_ARCH}")

HASH=$(git log -1 --format=%H -- \
    "${CONFIG}" \
    toolchains/crosstool-ng/ctng.patch \
    toolchains/crosstool-ng/ctng-version.env \
    toolchains/scripts/build-crosstool-ng-toolchain.sh)

if [[ -z "${HASH}" ]]; then
    echo "Could not resolve a toolchain hash: no matching commit found in git history for this recipe's files (shallow clone?)" >&2
    exit 1
fi

echo "${HASH}"
