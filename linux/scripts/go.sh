#!/bin/bash

set -eo pipefail

tar -C /usr/local -xzf /tmp/go/go.tar.gz && rm /tmp/go/go.tar.gz

# Disable telemetry for standard Go.
/usr/local/go/bin/go telemetry off

# Remove unnecessary content like Go's test suite and versioned API documentation.
rm -rf \
    /usr/local/go/test \
    /usr/local/go/api \
    /usr/local/go/doc \
    /usr/local/go/misc
