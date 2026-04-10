#!/bin/bash

set -eo pipefail

tar -C /usr/local -xzf /tmp/go/go.tar.gz && rm /tmp/go/go.tar.gz
mkdir /usr/local/msgo && tar --strip-components=1 -C /usr/local/msgo/ -xzf /tmp/go/msgo.tar.gz && rm /tmp/go/msgo.tar.gz;

cat << EOF >> /root/.bashrc
if [ "\$DD_GO_TOOLCHAIN" = "msgo" ]; then
    export PATH="/usr/local/msgo/bin:\$PATH"
    export GOROOT="/usr/local/msgo"
else
    export PATH="/usr/local/go/bin:\$PATH"
    export GOROOT="/usr/local/go"
fi
EOF

# Disable telemetry for standard Go. The Microsoft Go toolchain has its own
# telemetry mechanism which is disabled with an environment variable later.
/usr/local/go/bin/go telemetry off

# Remove unnecessary content like Go's test suite and versioned API documentation.
rm -rf \
    /usr/local/go/test \
    /usr/local/go/api \
    /usr/local/go/doc \
    /usr/local/go/misc
