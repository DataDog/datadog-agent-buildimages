#!/bin/bash

set -ex

# Install gimme to get go1.15
curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
chmod +x /bin/gimme
eval $(gimme 1.15.11)

# Install gcc 4.9 (needed to compile go, as it introduces -fdiagnostics-color which is required
# to compile go)
apt-get update && apt-get install -y gcc-4.9-backport

git clone https://go.googlesource.com/go goroot && cd goroot
git checkout go$GO_VERSION
cd src 

# Use the bundled clang + go 1.15.11 to build the target go version
CC=/usr/lib/gcc-4.9-backport/bin/gcc ./all.bash

# Update PATH to include the built go binaries
echo 'export PATH="/goroot/bin:$PATH"' >> /root/.bashrc
