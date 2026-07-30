#!/usr/bin/env bash

set -euo pipefail

HOST_ARCH="$1"
TARGET_ARCH="$2"

CONFIG="toolchains/crosstool-ng/${HOST_ARCH}/config-${TARGET_ARCH}-unknown-gnu-linux"

if [[ ! -f "${CONFIG}" ]]; then
    echo "No crosstool-ng config found for host=${HOST_ARCH} target=${TARGET_ARCH}: ${CONFIG}" >&2
    exit 1
fi

echo "${CONFIG}"
