#!/bin/bash

set -euo pipefail

CODECOV_VERSION=0.6.1

# Check if the architecture was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <architecture>"
  echo "Example: $0 arm64"
  exit 1
fi

ARCH=$1

case $ARCH in
  arm64)
    CODECOV_ARCH="aarch64"
    ;;
  amd64)
    CODECOV_ARCH="linux"
    ;;
  *)
    echo "Invalid architecture: $ARCH"
    echo "Supported architectures are: arm64, amd64"
    exit 1
    ;;
esac

# Integrity checking the uploader
curl https://keybase.io/codecovsecurity/pgp_keys.asc | gpg --no-default-keyring --keyring trustedkeys.gpg --import
curl -Os https://uploader.codecov.io/v${CODECOV_VERSION}/${CODECOV_ARCH}/codecov
curl -Os https://uploader.codecov.io/v${CODECOV_VERSION}/${CODECOV_ARCH}/codecov.SHA256SUM
curl -Os https://uploader.codecov.io/v${CODECOV_VERSION}/${CODECOV_ARCH}/codecov.SHA256SUM.sig
gpgv codecov.SHA256SUM.sig codecov.SHA256SUM
shasum -a 256 -c codecov.SHA256SUM
rm codecov.SHA256SUM.sig codecov.SHA256SUM

# Install the uploader
mv codecov /usr/local/bin/codecov
chmod +x /usr/local/bin/codecov
