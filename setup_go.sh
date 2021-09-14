#!/bin/bash

set -ex

# Installs go from source: https://golang.org/doc/install/source#go14 using the first documented option
# (building go with a previous binary release of go).
# Note: the official go build uses the fourth option (bootstrap the build using go1.4), but according to the documentation
# this shouldn't make a difference.

# Install gimme to get go1.15.11
curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/v1.5.4/gimme
# Check sha256sum, fail otherwise
echo "03b295636d4e22870b6f6e9bc06a71d65311ae90d3d48cbc7071f82dd5837fbc  /bin/gimme" | sha256sum --check
chmod +x /bin/gimme
eval "$(gimme 1.15.11)"

# Install gcc 4.9 (needed to compile go, as it introduces -fdiagnostics-color which is required
# in the post-compilation steps of go).
# Note: this doesn't replace the existing gcc (4.7.2), gcc 4.9 is installed in
# /usr/lib/gcc-4.9-backport/bin.
apt-get update && apt-get install -y gcc-4.9-backport

git clone --branch "go$GO_VERSION" --depth 1 https://go.googlesource.com/go goroot && cd goroot/src

# Use gcc 4.9 + go1.15.11 to build the target go version
# HACK: cgo tries to look for gcc in the same place that CC
# pointed to when go was compiled. By default, CC=gcc.
# We don't want to keep gcc 4.9 after building go, so we temporarily
# change the PATH so that "gcc" is the gcc 4.9 we installed.
# Then, when cgo is used, it will use "gcc" which will be gcc 4.7.
export PATH="/usr/lib/gcc-4.9-backport/bin:$PATH"
./all.bash

# Remove gcc 4.9 after building go
apt-get remove -y gcc-4.9-backport

# Update PATH to include the built go binaries
echo 'export PATH="/goroot/bin:$PATH"' >> /root/.bashrc
