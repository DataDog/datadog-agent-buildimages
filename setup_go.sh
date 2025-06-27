#!/bin/bash

set -eo pipefail

case $DD_TARGET_ARCH in
"x64")
    GO_SHA256="${GO_SHA256_LINUX_AMD64}"
    MSGO_SHA256="${MSGO_SHA256_LINUX_AMD64}"
    GOARCH="amd64"
    ;;
"aarch64")
    GO_SHA256="${GO_SHA256_LINUX_ARM64}"
    MSGO_SHA256="${MSGO_SHA256_LINUX_ARM64}"
    GOARCH="arm64"
    ;;
"armhf")
    GO_SHA256="${GO_SHA256_LINUX_ARMV6L}"
    MSGO_SHA256="${MSGO_SHA256_LINUX_ARMV6L}"
    GOARCH="armv6l"
    ;;
*)
    echo "Unknown or unsupported architecture ${DD_TARGET_ARCH}"
    exit -1
esac

echo "Installing upstream Go"
curl -sL -o /tmp/golang.tar.gz https://go.dev/dl/go${GO_VERSION}.linux-${GOARCH}.tar.gz
echo "$GO_SHA256  /tmp/golang.tar.gz" | sha256sum --check
tar -C /usr/local -xzf /tmp/golang.tar.gz && rm -f /tmp/golang.tar.gz
/usr/local/go/bin/go install golang.org/dl/go1.25rc1@latest && /go/bin/go1.25rc1 download && mv /go/bin/go1.25rc1 /usr/local/go/bin/go

echo "Installing Microsoft Go"
curl -SL -o /tmp/golang.tar.gz https://aka.ms/golang/release/latest/go${GO_VERSION}-${MSGO_PATCH}.linux-${GOARCH}.tar.gz
echo "$MSGO_SHA256  /tmp/golang.tar.gz" | sha256sum --check
mkdir /usr/local/msgo && tar --strip-components=1 -C /usr/local/msgo/ -xzf /tmp/golang.tar.gz && rm -f /tmp/golang.tar.gz;

cat << EOF >> /root/.bashrc
if [ "\$DD_GO_TOOLCHAIN" = "msgo" ]; then
    export PATH="/usr/local/msgo/bin:\$PATH"
    export GOROOT="/usr/local/msgo"
else
    export PATH="/usr/local/go/bin:\$PATH"
    export GOROOT="/usr/local/go"
fi
EOF
