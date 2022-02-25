#!/bin/bash

CLANG_VERSION=8.0.0

curl -LO https://releases.llvm.org/${CLANG_VERSION}/llvm-${CLANG_VERSION}.src.tar.xz
echo "8872be1b12c61450cacc82b3d153eab02be2546ef34fa3580ed14137bb26224c  llvm-${CLANG_VERSION}.src.tar.xz" | sha256sum --check
tar -xf llvm-${CLANG_VERSION}.src.tar.xz
curl -LO https://releases.llvm.org/${CLANG_VERSION}/cfe-${CLANG_VERSION}.src.tar.xz
echo "084c115aab0084e63b23eee8c233abb6739c399e29966eaeccfc6e088e0b736b  llvm-${CLANG_VERSION}.src.tar.xz" | sha256sum --check
tar -xf cfe-${CLANG_VERSION}.src.tar.xz
mv cfe-${CLANG_VERSION}.src/ clang
cd llvm-${CLANG_VERSION}.src
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=release -DLLVM_ENABLE_PROJECTS=clang -DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=ON -DCMAKE_INSTALL_PREFIX=/opt/clang ..
make -j2
make install
tar cJf clang+llvm-${CLANG_VERSION}-$(uname -p)-linux.tar.xz /opt/clang
