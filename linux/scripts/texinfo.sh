#!/bin/bash

set -ex

./autogen.sh

./configure

make -j$(ncproc)

make install
