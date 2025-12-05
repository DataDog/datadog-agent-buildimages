#!/usr/bin/env bash

set -euxo pipefail

cd /build

wget https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/crosstool-ng-${CTNG_VERSION}.tar.xz
gpg --keyserver keyserver.ubuntu.com --recv-keys 1F30EF2E

wget https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/crosstool-ng-${CTNG_VERSION}.tar.xz.sig
gpg --verify crosstool-ng-${CTNG_VERSION}.tar.xz.sig

tar xf crosstool-ng-${CTNG_VERSION}.tar.xz
cd crosstool-ng-${CTNG_VERSION}
patch -p1 < /root/ctng.patch

./configure --enable-local && make -j$(nproc)
export CT_ALLOW_BUILD_AS_ROOT_SURE=yes
./ct-ng upgradeconfig
./ct-ng build

mkdir -p /opt/toolchains/
mv /root/x-tools/${ARCH}-unknown-linux-gnu/ /opt/toolchains/${ARCH}
mv .config-${CROSS_ARCH} .config
./ct-ng upgradeconfig
./ct-ng build
mv /root/x-tools/${CROSS_ARCH}-unknown-linux-gnu/ /opt/toolchains/${CROSS_ARCH}

rm -rf /build
