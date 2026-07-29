#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

HOST_ARCH="$1"
TARGET_ARCH="$2"

CONFIGS=(toolchains/crosstool-ng/${HOST_ARCH}/config-${TARGET_ARCH}-unknown-gnu-linux-glibc*)

if [[ ${#CONFIGS[@]} -ne 1 ]]; then
    echo "Expected exactly one crosstool-ng config for host=${HOST_ARCH} target=${TARGET_ARCH}, found: ${CONFIGS[*]:-none}" >&2
    exit 1
fi

echo "${CONFIGS[0]}"
