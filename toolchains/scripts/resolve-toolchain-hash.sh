#!/usr/bin/env bash

set -euo pipefail

HOST_ARCH="$1"
TARGET_ARCH="$2"

CONFIG=$(./toolchains/scripts/toolchain-config-path.sh "${HOST_ARCH}" "${TARGET_ARCH}")

cat \
    "${CONFIG}" \
    toolchains/crosstool-ng/ctng.patch \
    toolchains/crosstool-ng/ctng-version.env \
    toolchains/scripts/build-crosstool-ng-toolchain.sh \
    | sha256sum | cut -d' ' -f1
