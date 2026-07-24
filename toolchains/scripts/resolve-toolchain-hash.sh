#!/usr/bin/env bash

set -euo pipefail

HOST_ARCH="$1"
TARGET_ARCH="$2"
TARGET_GLIBC_VERSION="$3"

git log -1 --format=%H -- \
    "toolchains/crosstool-ng/${HOST_ARCH}/config-${TARGET_ARCH}-unknown-gnu-linux-glibc${TARGET_GLIBC_VERSION}" \
    toolchains/crosstool-ng/ctng.patch \
    toolchains/crosstool-ng/ctng-version.env \
    toolchains/scripts/build-crosstool-ng-toolchain.sh
