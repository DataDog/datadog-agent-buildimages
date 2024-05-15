#!/bin/bash

set -eo pipefail

CODECOV_VERSION=0.6.1

# Determine the Architecture to install the Codecov uploader.
if [[ -z "${DD_TARGET_ARCH}" ]]; then
  echo "DD_TARGET_ARCH environment variable is not set. The Codecov x64 uploader will be installed by default."
  CODECOV_ARCH="linux"
else
  case $DD_TARGET_ARCH in
    aarch64|armhf)
      CODECOV_ARCH="aarch64"
      ;;
    x64)
      CODECOV_ARCH="linux"
      ;;
    *)
      echo "Invalid DD_TARGET_ARCH value: ${DD_TARGET_ARCH}"
      echo "The DD_TARGET_ARCH values supported by the Codecov setup are: aarch64, x64"
      exit 1
      ;;
  esac
fi

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
