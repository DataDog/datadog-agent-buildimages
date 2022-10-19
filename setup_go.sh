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

git clone --branch "go$GO_VERSION" --depth 1 https://go.googlesource.com/go goroot && cd goroot/src

./all.bash

# Update PATH to include the built go binaries
echo 'export PATH="/goroot/bin:$PATH"' >> /root/.bashrc

# Remove gimme
rm -rf $HOME/.gimme
rm /bin/gimme