#!/bin/bash

CMAKE_VERSION=3.14.4

curl -sL -O https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz
tar xf cmake-${CMAKE_VERSION}.tar.gz
cd cmake-${CMAKE_VERSION}
./bootstrap --prefix=/opt/cmake
make -j2
make install
source /etc/os-release
tar cJf cmake-${CMAKE_VERSION}-${ID}-$(uname -p).tar.xz /opt/cmake
