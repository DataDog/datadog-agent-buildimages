#!/bin/bash

CLANG_VERSION=8.0.0

curl -LO http://releases.llvm.org/${CLANG_VERSION}/llvm-${CLANG_VERSION}.src.tar.xz
tar -xf llvm-${CLANG_VERSION}.src.tar.xz
curl -LO http://releases.llvm.org/${CLANG_VERSION}/cfe-${CLANG_VERSION}.src.tar.xz
tar -xf cfe-${CLANG_VERSION}.src.tar.xz
mv cfe-${CLANG_VERSION}.src/ clang
cd llvm-${CLANG_VERSION}.src
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=release -DLLVM_ENABLE_PROJECTS=clang -DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=ON -DCMAKE_INSTALL_PREFIX=/opt/clang ..
make -j2
make install
tar cJf clang+llvm-${CLANG_VERSION}-$(uname -p)-linux.tar.xz /opt/clang
