#!/bin/bash
set -e

# Build x64 image
docker build \
  --build-arg ARCH=x64 \
  --build-arg CROSS_ARCH=arm64 \
  --build-arg GLIBC_VERSION=2.17 \
  --build-arg CROSS_GLIBC_VERSION=2.23 \
  --build-arg RUSTC_SHA256="0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db" \
  --build-arg RUSTUP_SHA256="0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db" \
  --build-arg VAULT_CHECKSUM="a0c0449e640c8be5dcf7b7b093d5884f6a85406dbb86bbad0ea06becad5aaab8" \
  --build-arg VAULT_FILENAME="vault_${VAULT_VERSION}_linux_amd64.zip" \
  --build-arg CI_UPLOADER_SHA="4e56d449e6396ae4c7356f07fc5372a28999aacb012d4343a3b8a9389123aa38" \
  -t datadog-agent-buildimages:linux-glibc-2.17-x64 \
  -f linux-glibc/Dockerfile .

# Build arm64 image
docker build \
  --build-arg ARCH=arm64 \
  --build-arg CROSS_ARCH=x64 \
  --build-arg GLIBC_VERSION=2.23 \
  --build-arg CROSS_GLIBC_VERSION=2.17 \
  --build-arg RUSTC_SHA256="673e336c81c65e6b16dcdede33f4cc9ed0f08bde1dbe7a935f113605292dc800" \
  --build-arg RUSTUP_SHA256="673e336c81c65e6b16dcdede33f4cc9ed0f08bde1dbe7a935f113605292dc800" \
  --build-arg VAULT_CHECKSUM="1cdfd33e218ef145dbc3d71ac4164b89e453ff81b780ed178274bc1ba070e6e9" \
  --build-arg VAULT_FILENAME="vault_${VAULT_VERSION}_linux_arm64.zip" \
  --build-arg CI_UPLOADER_SHA="90ee346ea639e2d70a45b70e2d1491e5749099665df06a2e6d80ddc9fd90fe0c" \
  -t datadog-agent-buildimages:linux-glibc-2.23-arm64 \
  -f linux-glibc/Dockerfile . 