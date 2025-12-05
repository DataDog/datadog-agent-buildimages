#!/usr/bin/env bash

set -euxo pipefail

mkdir /tmp/texinfo
cd /tmp/texinfo
git clone https://gnu.googlesource.com/texinfo

cd texinfo
git reset --hard 60d3edc4b74b4e1e5ef55e53de394d3b65506c47

./autogen.sh

./configure

make -j$(nproc)

make install

rm -r /tmp/texinfo
