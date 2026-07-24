#!/usr/bin/env bash

set -euo pipefail

HOST_ARCH="$1"
TARGET_ARCH="$2"
TOOLCHAIN_HASH="$3"
CHANNEL="$4"

KEY=$(./toolchains/scripts/toolchain-artifact-key.sh "${HOST_ARCH}" "${TARGET_ARCH}" "${TOOLCHAIN_HASH}" "${CHANNEL}")

curl -sSf "https://dd-agent-build-artifacts.s3.amazonaws.com/${KEY}.sha256"
