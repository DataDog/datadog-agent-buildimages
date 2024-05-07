#!/bin/bash

set -euo pipefail

CODECOV_VERSION=0.6.1

# Integrity checking the uploader
curl https://keybase.io/codecovsecurity/pgp_keys.asc | gpg --no-default-keyring --keyring trustedkeys.gpg --import
curl -Os https://uploader.codecov.io/v${CODECOV_VERSION}/linux/codecov
curl -Os https://uploader.codecov.io/v${CODECOV_VERSION}/linux/codecov.SHA256SUM
curl -Os https://uploader.codecov.io/v${CODECOV_VERSION}/linux/codecov.SHA256SUM.sig
gpgv codecov.SHA256SUM.sig codecov.SHA256SUM
shasum -a 256 -c codecov.SHA256SUM
rm codecov.SHA256SUM.sig codecov.SHA256SUM

# Install the uploader
mv codecov /usr/local/bin/codecov
chmod +x /usr/local/bin/codecov
