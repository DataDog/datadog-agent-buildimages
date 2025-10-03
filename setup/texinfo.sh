#!/usr/bin/env bash

set -euxo pipefail

./autogen.sh

./configure

make -j$(nproc)

make install
