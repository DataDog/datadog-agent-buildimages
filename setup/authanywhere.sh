#!/usr/bin/env bash
set -euxo pipefail

if [ "$(uname -m)" == "x86_64" ]; then
    authanywhere_arch="amd64"
elif [ "$(uname -m)" == "aarch64" ]; then
    authanywhere_arch="arm64"
else
    echo "Unsupported architecture to install authanywhere: $(uname -m)"
    exit 1
fi

# Install authanywhere for infra token management
curl -OL https://binaries.ddbuild.io/dd-source/authanywhere/v0.0.2/authanywhere-tar.tar.gz
tar -xf authanywhere-tar.tar.gz
mv "authanywhere-linux-$authanywhere_arch" /usr/local/bin/authanywhere
chmod +x /usr/local/bin/authanywhere
rm authanywhere-*
