#!/bin/bash

set -ex

# Install gimme to get go1.15.11
curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
chmod +x /bin/gimme
eval $(gimme 1.15.11)

# Install gcc 4.9 (needed to compile go, as it introduces -fdiagnostics-color which is required
# in the post-compilation steps of go)
# We don't add it to the PATH so that it's not used in the Agent / rtloader builds
apt-get update && apt-get install -y gcc-4.9-backport

git clone --branch go$GO_VERSION --depth 1 https://go.googlesource.com/go goroot && cd goroot
cd src 

# Use gcc 4.9 + go1.15.11 to build the target go version
CC=/usr/lib/gcc-4.9-backport/bin/gcc ./all.bash

# Remove gcc 4.9 after building go
apt-get remove -y gcc-4.9-backport

# HACK: cgo tries to look for gcc in the same place that CC
# pointed to when go was compiled. By default, this is fine (since CC=gcc),
# but here since CC is more specific, cgo will try to find gcc
# in /usr/lib/gcc-4.9-backport/bin/gcc
mkdir -p /usr/lib/gcc-4.9-backport/bin
ln -s $(which gcc) /usr/lib/gcc-4.9-backport/bin/gcc

# Update PATH to include the built go binaries
echo 'export PATH="/goroot/bin:$PATH"' >> /root/.bashrc
