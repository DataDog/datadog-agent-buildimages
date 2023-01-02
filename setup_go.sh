#!/bin/bash

set -ex

# Installs go from source: https://golang.org/doc/install/source#go14 using the first documented option
# (building go with a previous binary release of go).
# Note: the official go build uses the fourth option (bootstrap the build using go1.4), but according to the documentation
# this shouldn't make a difference.

# Upgrade bison 
curl -sL -O https://ftp.gnu.org/gnu/bison/bison-${BISON_VERSION}.tar.gz
echo "${BISON_SHA256}  ./bison-${BISON_VERSION}.tar.gz" | sha256sum --check
tar -zxvf ./bison-${BISON_VERSION}.tar.gz
cd bison-${BISON_VERSION}
./configure --prefix=/usr/local/bison && make && make install
cd -

export PATH=/usr/local/bison/bin:$PATH

# Upgrade binutils
curl -sL -O https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz
echo "${BINUTILS_SHA256}  ./binutils-${BINUTILS_VERSION}.tar.gz" | sha256sum --check
tar -zxvf ./binutils-${BINUTILS_VERSION}.tar.gz
cd binutils-${BINUTILS_VERSION}
./configure --prefix=/usr/local/binutils && make && make install
cd -

export PATH=/usr/local/binutils/bin:$PATH

# Install gimme to get go1.15.11
curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/v1.5.5/gimme
# Check sha256sum, fail otherwise
echo "3d565d57ec28edb14be9e540cd3e628607ec5b791e78224c47250d36ce4aedf2  /bin/gimme" | sha256sum --check
chmod +x /bin/gimme
eval "$(gimme 1.18.9)"

git clone --branch "go$GO_VERSION" --depth 1 https://go.googlesource.com/go goroot && cd goroot/src

./all.bash

# Update PATH to include the built go binaries
echo 'export PATH="/goroot/bin:$PATH"' >> /root/.bashrc

# Remove gimme
rm -rf $HOME/.gimme
rm /bin/gimme
