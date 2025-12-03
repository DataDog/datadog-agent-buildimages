#!/bin/bash

set -eo pipefail

tar -C /usr/local -xzf /tmp/go/go.tar.gz && rm -f /tmp/go/go.tar.gz
mkdir /usr/local/msgo && tar --strip-components=1 -C /usr/local/msgo/ -xzf /tmp/go/msgo.tar.gz && rm -f /tmp/go/msgo.tar.gz;

cat << EOF >> /root/.bashrc
if [ "\$DD_GO_TOOLCHAIN" = "msgo" ]; then
    export PATH="/usr/local/msgo/bin:\$PATH"
    export GOROOT="/usr/local/msgo"
else
    export PATH="/usr/local/go/bin:\$PATH"
    export GOROOT="/usr/local/go"
fi
EOF
