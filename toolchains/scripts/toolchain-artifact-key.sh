#!/usr/bin/env bash

set -euo pipefail

HOST_ARCH="$1"
TARGET_ARCH="$2"
TOOLCHAIN_HASH="$3"
CHANNEL="$4"

echo "toolchains/${CHANNEL}/${TOOLCHAIN_HASH}/${HOST_ARCH}/${TARGET_ARCH}-unknown-linux-gnu-gcc.tar.xz"
